"""
ERPNext Integration Routes - مسارات ربط ERPNext
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import (
    Shipment, Customer, Invoice, Payment, IntegrationWebhookEvent,
    IntegrationOutbox, IntegrationAudit,
)
from ..database import db
from ..services.channel_guard import require_channel_scope
from ..services.financial_outbox import enqueue_financial_command
import requests
from datetime import datetime
import json
import hashlib
import hmac

bp = Blueprint('erpnext', __name__)


@bp.route('/integration/financial-command', methods=['POST'])
def enqueue_market_financial_command():
    """Receive a signed market command and persist it for asynchronous ERPNext delivery."""
    from flask import current_app
    expected_key = current_app.config.get('MARKET_INTEGRATION_KEY', '')
    provided_key = request.headers.get('X-Integration-Key', '')
    if not expected_key or not hmac.compare_digest(provided_key, expected_key):
        return jsonify({'error': 'Invalid integration credentials'}), 401

    data = request.get_json(silent=True) or {}
    required = ('command_type', 'source_type', 'source_id', 'payload')
    if any(not data.get(field) for field in required):
        return jsonify({'error': 'command_type, source_type, source_id and payload are required'}), 400

    outbox = enqueue_financial_command(
        data['command_type'], data['source_type'], data['source_id'], data['payload']
    )
    db.session.commit()
    return jsonify({
        'outbox_id': outbox.id,
        'status': outbox.status,
        'idempotency_key': outbox.idempotency_key,
    }), 202


def _require_admin(claims, operation):
    try:
        require_channel_scope(claims, 'ADMIN', operation)
    except PermissionError:
        return jsonify({'error': 'Access denied: ADMIN channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    return None


def _valid_erpnext_webhook(payload: bytes) -> bool:
    from flask import current_app
    secret = current_app.config.get('ERPNEXT_WEBHOOK_SECRET', '')
    signature = request.headers.get('X-Frappe-Signature', '')
    if not secret or not signature:
        return False
    expected = hmac.new(secret.encode('utf-8'), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


@bp.route('/webhooks', methods=['POST'])
def erpnext_webhook():
    """استقبال أحداث ERPNext الموقعة وتسجيلها للتنفيذ المحلي."""
    payload = request.get_data()
    if not _valid_erpnext_webhook(payload):
        return jsonify({'error': 'Invalid webhook signature'}), 401

    data = request.get_json(silent=True) or {}
    event = request.headers.get('X-Frappe-Webhook-Event') or data.get('event')
    request_id = request.headers.get('X-Request-ID')
    if not event or not request_id:
        return jsonify({'error': 'event and X-Request-ID are required'}), 400

    existing = IntegrationWebhookEvent.query.filter_by(request_id=request_id).first()
    if existing:
        return jsonify({'accepted': True, 'duplicate': True, 'request_id': request_id}), 202

    db.session.add(IntegrationWebhookEvent(
        request_id=request_id,
        event=event,
        payload_hash=hashlib.sha256(payload).hexdigest(),
        source_ip=request.remote_addr,
    ))
    db.session.commit()

    return jsonify({'accepted': True, 'event': event, 'request_id': request_id}), 202


def get_erpnext_config():
    """Get ERPNext configuration from environment"""
    from flask import current_app
    return {
        'url': current_app.config.get('ERPNEXT_URL', 'http://localhost:8000'),
        'api_key': current_app.config.get('ERPNEXT_API_KEY'),
        'api_secret': current_app.config.get('ERPNEXT_API_SECRET'),
        'doctype_prefix': current_app.config.get('ERPNEXT_DOCTYPE_PREFIX', 'Shipping-')
    }


def make_erpnext_request(method, endpoint, data=None):
    """Make request to ERPNext API"""
    config = get_erpnext_config()
    
    if not config['api_key'] or not config['api_secret']:
        return None, 'ERPNext API credentials not configured'
    
    url = f"{config['url']}/api/resource/{endpoint}"
    headers = {
        'Authorization': f"token {config['api_key']}:{config['api_secret']}",
        'Content-Type': 'application/json'
    }
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, params=data)
        elif method == 'POST':
            response = requests.post(url, headers=headers, json=data)
        elif method == 'PUT':
            response = requests.put(url, headers=headers, json=data)
        elif method == 'DELETE':
            response = requests.delete(url, headers=headers)
        else:
            return None, f'Unsupported method: {method}'
        
        if response.status_code in [200, 201]:
            return response.json(), None
        else:
            return None, f'ERPNext error: {response.status_code} - {response.text}'
    
    except Exception as e:
        return None, f'Connection error: {str(e)}'


@bp.route('/test-connection', methods=['GET'])
@jwt_required()
def test_connection():
    """اختبار الاتصال بـ ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'ADMIN', 'erpnext:test_connection')
    except PermissionError:
        return jsonify({'error': 'Access denied: ADMIN channel required'}), 403

    config = get_erpnext_config()
    
    if not config['api_key'] or not config['api_secret']:
        return jsonify({
            'connected': False,
            'message': 'ERPNext API credentials not configured'
        }), 400
    
    # Try to get system info
    result, error = make_erpnext_request('GET', 'System Manager')
    
    if error:
        return jsonify({
            'connected': False,
            'message': error
        }), 500
    
    return jsonify({
        'connected': True,
        'message': 'Successfully connected to ERPNext',
        'url': config['url']
    }), 200


@bp.route('/sync-customer', methods=['POST'])
@jwt_required()
def sync_customer():
    """مزامنة عميل مع ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'customer:sync')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    data = request.get_json()
    customer_id = data.get('customer_id')
    
    if not customer_id:
        return jsonify({'error': 'customer_id is required'}), 400
    
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    # Prepare customer data for ERPNext
    erpnext_customer = {
        'customer_name': customer.name,
        'customer_type': 'Company',
        'customer_group': 'Commercial',
        'territory': customer.country or 'All Territories',
        'email_id': customer.email,
        'phone': customer.phone,
        'address_html': customer.address,
        'tax_id': customer.tax_number
    }
    
    command_type = 'UPDATE_CUSTOMER' if customer.erpnext_customer_id else 'CREATE_CUSTOMER'
    outbox = enqueue_financial_command(command_type, 'CUSTOMER', customer.id, {
        'doctype': 'Customer',
        'erpnext_document_name': customer.erpnext_customer_id,
        **erpnext_customer,
    })
    customer.erpnext_sync_status = 'PENDING'
    db.session.commit()

    return jsonify({
        'message': 'Customer queued for ERPNext synchronization',
        'customer_id': customer.id,
        'integration': {
            'outbox_id': outbox.id,
            'status': outbox.status,
            'idempotency_key': outbox.idempotency_key,
        }
    }), 202


@bp.route('/create-sales-invoice', methods=['POST'])
@jwt_required()
def create_sales_invoice():
    """إنشاء فاتورة مبيعات في ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:invoice')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    shipment_id = data.get('shipment_id')
    
    if not shipment_id:
        return jsonify({'error': 'shipment_id is required'}), 400
    
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    if not shipment.customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    config = get_erpnext_config()
    
    # Get branch cost center and warehouse
    branch = shipment.branch
    
    # Prepare invoice data
    invoice_data = {
        'customer': shipment.customer.erpnext_customer_id or shipment.customer.name,
        'due_date': datetime.now().date().isoformat(),
        'company': 'Shipping Company',  # Configure this
        'cost_center': branch.cost_center_id if branch else None,
        'warehouse': branch.warehouse_id if branch else None,
        'items': [{
            'item_code': 'SHIPPING_SERVICE',  # Create this item in ERPNext
            'item_name': f"Shipping - {shipment.shipment_number}",
            'qty': 1,
            'rate': float(shipment.selling_price),
            'amount': float(shipment.selling_price),
            'cost_center': branch.cost_center_id if branch else None
        }],
        'shipping_system_ref': shipment.shipment_number
    }
    
    invoice = Invoice(
        shipment_id=shipment_id,
        customer_id=shipment.customer_id,
        amount=shipment.selling_price,
        total_amount=shipment.selling_price,
        currency=shipment.currency,
        status='draft',
        cost_center_id=branch.cost_center_id if branch else None,
        warehouse_id=branch.warehouse_id if branch else None,
    )
    db.session.add(invoice)
    db.session.flush()
    outbox = enqueue_financial_command(
        'SALES_INVOICE', 'SHIPMENT', shipment.id,
        {'doctype': 'Sales Invoice', 'invoice_id': str(invoice.id), **invoice_data},
    )
    db.session.commit()
    
    return jsonify({
        'message': 'Sales invoice queued for ERPNext',
        'invoice_id': invoice.id,
        'integration': {
            'outbox_id': outbox.id,
            'status': outbox.status,
            'idempotency_key': outbox.idempotency_key,
        }
    }), 201


@bp.route('/create-payment', methods=['POST'])
@jwt_required()
def create_payment_entry():
    """إنشاء سجل دفعة في ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'payment:entry')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    payment_id = data.get('payment_id')
    
    if not payment_id:
        return jsonify({'error': 'payment_id is required'}), 400
    
    payment = Payment.query.get(payment_id)
    if not payment:
        return jsonify({'error': 'Payment not found'}), 404
    
    # Prepare a financial command; a worker will create the ERPNext entry.
    payment_data = {
        'payment_type': 'Receive' if payment.payment_type == 'received' else 'Pay',
        'party_type': 'Customer' if payment.payment_type == 'received' else 'Supplier',
        'party': payment.customer.erpnext_customer_id if payment.customer else payment.supplier_id,
        'company': 'Shipping Company',
        'paid_amount': float(payment.amount),
        'received_amount': float(payment.amount),
        'source_exchange_rate': float(payment.exchange_rate),
        'target_exchange_rate': 1,
        'payment_date': payment.payment_date.isoformat() if payment.payment_date else datetime.now().date().isoformat(),
        'references': [{
            'reference_doctype': 'Sales Invoice' if payment.payment_type == 'received' else 'Purchase Invoice',
            'reference_name': payment.invoice.erpnext_invoice_id if payment.invoice else None,
            'allocated_amount': float(payment.amount)
        }] if payment.invoice else [],
        'shipping_system_ref': payment.payment_number
    }
    
    outbox = enqueue_financial_command(
        'PAYMENT_ENTRY', 'PAYMENT', payment.id,
        {'doctype': 'Payment Entry', 'payment_id': str(payment.id), **payment_data},
    )
    payment.erpnext_sync_status = 'PENDING'
    db.session.commit()
    
    return jsonify({
        'message': 'Payment entry queued for ERPNext',
        'payment_id': payment.id,
        'integration': {
            'outbox_id': outbox.id,
            'status': outbox.status,
            'idempotency_key': outbox.idempotency_key,
        }
    }), 201


@bp.route('/outbox', methods=['GET'])
@jwt_required()
def list_outbox():
    """عرض حالة أوامر التكامل دون كشف الأسرار أو بيانات الاعتماد."""
    denied = _require_admin(get_jwt(), 'erpnext:outbox_read')
    if denied:
        return denied

    status = request.args.get('status')
    query = IntegrationOutbox.query.order_by(IntegrationOutbox.created_at.desc())
    if status:
        query = query.filter_by(status=status.upper())
    items = query.limit(min(request.args.get('limit', 50, type=int), 200)).all()
    return jsonify({
        'items': [{
            'id': item.id,
            'command_type': item.command_type,
            'source_type': item.source_type,
            'source_id': item.source_id,
            'status': item.status,
            'attempt_count': item.attempt_count,
            'next_attempt_at': item.next_attempt_at.isoformat() if item.next_attempt_at else None,
            'erp_document_name': item.erp_document_name,
            'last_error': item.last_error,
            'created_at': item.created_at.isoformat() if item.created_at else None,
        } for item in items]
    }), 200


@bp.route('/outbox/<outbox_id>/retry', methods=['POST'])
@jwt_required()
def retry_outbox(outbox_id):
    """إعادة أمر فاشل إلى الطابور دون إرساله داخل طلب HTTP."""
    denied = _require_admin(get_jwt(), 'erpnext:outbox_retry')
    if denied:
        return denied

    command = db.session.get(IntegrationOutbox, outbox_id)
    if not command:
        return jsonify({'error': 'Outbox command not found'}), 404
    if command.status == 'DONE':
        return jsonify({'error': 'Outbox command already completed'}), 409

    command.status = 'PENDING'
    command.next_attempt_at = None
    command.last_error = None
    db.session.add(IntegrationAudit(
        outbox_id=command.id,
        action='MANUAL_RETRY',
        attempt=command.attempt_count,
        actor_reference=str(get_jwt().get('sub', 'admin')),
    ))
    db.session.commit()
    return jsonify({'message': 'Outbox command requeued', 'outbox_id': command.id}), 202


@bp.route('/sync', methods=['POST'])
@jwt_required()
def full_sync():
    """مزامنة شاملة مع ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'ADMIN', 'erpnext:sync_all')
    except PermissionError:
        return jsonify({'error': 'Access denied: ADMIN channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    results = {
        'customers_synced': 0,
        'invoices_pending': 0,
        'errors': []
    }
    
    # Sync customers without ERPNext ID
    customers = Customer.query.filter(Customer.erpnext_customer_id == None).all()
    for customer in customers:
        try:
            erpnext_customer = {
                'customer_name': customer.name,
                'customer_type': 'Company',
                'territory': customer.country or 'All Territories',
                'email_id': customer.email,
                'phone': customer.phone
            }
            outbox = enqueue_financial_command(
                'CREATE_CUSTOMER', 'CUSTOMER', customer.id,
                {'doctype': 'Customer', **erpnext_customer},
            )
            customer.erpnext_sync_status = 'PENDING'
            results['customers_synced'] += 1
        except Exception as e:
            results['errors'].append(f"Customer {customer.name}: {str(e)}")
    
    # Sync pending invoices
    invoices = Invoice.query.filter(Invoice.status == 'draft').all()
    for invoice in invoices:
        try:
            if invoice.shipment:
                results['invoices_pending'] += 1
        except Exception as e:
            results['errors'].append(f"Invoice {invoice.id}: {str(e)}")
    
    db.session.commit()
    
    return jsonify({
        'message': 'Sync completed',
        'results': results
    }), 200


@bp.route('/get-invoice-status/<erpnext_invoice_id>', methods=['GET'])
@jwt_required()
def get_invoice_status(erpnext_invoice_id):
    """الحصول على حالة الفاتورة من ERPNext"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'invoice:status')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    result, error = make_erpnext_request('GET', f'Sales Invoice/{erpnext_invoice_id}')
    
    if error:
        return jsonify({'error': error}), 500
    
    if result and result.get('data'):
        data = result['data']
        return jsonify({
            'invoice_id': erpnext_invoice_id,
            'status': data.get('docstatus'),
            'outstanding_amount': data.get('outstanding_amount'),
            'paid_amount': data.get('paid_amount'),
            'total': data.get('total')
        }), 200
    
    return jsonify({'error': 'Invoice not found'}), 404