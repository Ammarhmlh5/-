"""
ERPNext Integration Routes - مسارات ربط ERPNext
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Shipment, Customer, Invoice, Payment, IntegrationWebhookEvent
from ..database import db
from ..services.channel_guard import require_channel_scope
import requests
from datetime import datetime
import json
import hashlib
import hmac

bp = Blueprint('erpnext', __name__)


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
    
    config = get_erpnext_config()
    
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
    
    if customer.erpnext_customer_id:
        # Update existing
        endpoint = f"Customer/{customer.erpnext_customer_id}"
        result, error = make_erpnext_request('PUT', endpoint, erpnext_customer)
    else:
        # Create new
        endpoint = "Customer"
        result, error = make_erpnext_request('POST', endpoint, erpnext_customer)
    
    if error:
        return jsonify({'error': error}), 500
    
    # Save ERPNext customer ID
    if not customer.erpnext_customer_id and result.get('data'):
        customer.erpnext_customer_id = result['data'].get('name')
        db.session.commit()
    
    return jsonify({
        'message': 'Customer synced successfully',
        'erpnext_customer_id': customer.erpnext_customer_id or result.get('data', {}).get('name')
    }), 200


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
    
    result, error = make_erpnext_request('POST', 'Sales Invoice', invoice_data)
    
    if error:
        return jsonify({'error': error}), 500
    
    # Save invoice reference in shipment
    if result.get('data'):
        erpnext_invoice_id = result['data'].get('name')
        shipment.erpnext_sales_invoice_id = erpnext_invoice_id
        
        # Create invoice record in our system
        invoice = Invoice(
            shipment_id=shipment_id,
            erpnext_invoice_id=erpnext_invoice_id,
            invoice_type='sales',
            invoice_number=erpnext_invoice_id,
            customer_id=shipment.customer_id,
            amount=shipment.selling_price,
            total_amount=shipment.selling_price,
            currency=shipment.currency,
            status='submitted',
            cost_center_id=branch.cost_center_id if branch else None,
            warehouse_id=branch.warehouse_id if branch else None,
            erpnext_link=f"{config['url']}/app/sales-invoice/{erpnext_invoice_id}"
        )
        db.session.add(invoice)
        db.session.commit()
    
    return jsonify({
        'message': 'Sales invoice created successfully',
        'erpnext_invoice_id': erpnext_invoice_id,
        'link': f"{config['url']}/app/sales-invoice/{erpnext_invoice_id}"
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
    
    config = get_erpnext_config()
    
    # Prepare payment data
    payment_data = {
        'payment_type': 'Receive' if payment.payment_type == 'received' else 'Pay',
        'party_type': 'Customer' if payment.payment_type == 'received' else 'Supplier',
        'party': payment.customer.name if payment.customer else None,
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
    
    result, error = make_erpnext_request('POST', 'Payment Entry', payment_data)
    
    if error:
        return jsonify({'error': error}), 500
    
    # Save payment reference
    if result.get('data'):
        erpnext_payment_id = result['data'].get('name')
        payment.erpnext_payment_id = erpnext_payment_id
        payment.status = 'completed'
        payment.erpnext_link = f"{config['url']}/app/payment-entry/{erpnext_payment_id}"
        db.session.commit()
    
    return jsonify({
        'message': 'Payment entry created successfully',
        'erpnext_payment_id': erpnext_payment_id,
        'link': f"{config['url']}/app/payment-entry/{erpnext_payment_id}"
    }), 201


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
        'invoices_synced': 0,
        'errors': []
    }
    
    # Sync customers without ERPNext ID
    customers = Customer.query.filter(Customer.erpnext_customer_id == None).all()
    for customer in customers:
        try:
            # Create in ERPNext
            erpnext_customer = {
                'customer_name': customer.name,
                'customer_type': 'Company',
                'territory': customer.country or 'All Territories',
                'email_id': customer.email,
                'phone': customer.phone
            }
            result, error = make_erpnext_request('POST', 'Customer', erpnext_customer)
            if result and result.get('data'):
                customer.erpnext_customer_id = result['data'].get('name')
                db.session.commit()
                results['customers_synced'] += 1
        except Exception as e:
            results['errors'].append(f"Customer {customer.name}: {str(e)}")
    
    # Sync pending invoices
    invoices = Invoice.query.filter(Invoice.status == 'draft').all()
    for invoice in invoices:
        try:
            if invoice.shipment:
                invoice.status = 'submitted'
                results['invoices_synced'] += 1
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