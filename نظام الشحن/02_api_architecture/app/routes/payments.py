"""
Payments Routes - مسارات المدفوعات
"""
from flask import Blueprint, current_app, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Payment, Invoice, Customer, Branch
from ..database import db
from ..services.channel_guard import require_any_channel_scope
from ..services.payment_sync_service import PaymentSyncError, sync_payment
from datetime import datetime

bp = Blueprint('payments', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_payments():
    """الحصول على قائمة المدفوعات"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    invoice_id = request.args.get('invoice_id')
    customer_id = request.args.get('customer_id')
    payment_type = request.args.get('payment_type')
    status = request.args.get('status')
    branch_id = request.args.get('branch_id')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = Payment.query
    
    # Filter by branch if not admin
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager'] and claims.get('branch_id'):
        query = query.filter_by(branch_id=claims.get('branch_id'))
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    if invoice_id:
        query = query.filter_by(invoice_id=invoice_id)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    if payment_type:
        query = query.filter_by(payment_type=payment_type)
    if status:
        query = query.filter_by(status=status)
    
    pagination = db.paginate(
        query.order_by(Payment.payment_date.desc()),
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'items': [p.to_dict() for p in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/stats', methods=['GET'])
@jwt_required()
def get_payment_stats():
    """إحصائيات المدفوعات"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    branch_id = request.args.get('branch_id')
    payment_type = request.args.get('payment_type')
    
    query = Payment.query
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if payment_type:
        query = query.filter_by(payment_type=payment_type)
    
    total = query.count()
    pending = query.filter_by(status='pending').count()
    completed = query.filter_by(status='completed').count()
    failed = query.filter_by(status='failed').count()
    
    from sqlalchemy import func
    total_amount = query.with_entities(func.sum(Payment.amount)).scalar() or 0
    
    return jsonify({
        'total': total,
        'pending': pending,
        'completed': completed,
        'failed': failed,
        'total_amount': float(total_amount)
    }), 200


@bp.route('/<payment_id>', methods=['GET'])
@jwt_required()
def get_payment(payment_id):
    """الحصول على دفعة محددة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    payment = Payment.query.get(payment_id)
    
    if not payment:
        return jsonify({'error': 'Payment not found'}), 404
    
    data = payment.to_dict()
    # Add related data
    if payment.invoice:
        data['invoice'] = payment.invoice.to_dict()
    if payment.customer:
        data['customer'] = payment.customer.to_dict()
    
    return jsonify(data), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_payment():
    """إنشاء دفعة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:create')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    required = ['payment_type', 'payment_date', 'amount']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Parse payment date
    if isinstance(data['payment_date'], str):
        payment_date = datetime.strptime(data['payment_date'], '%Y-%m-%d').date()
    else:
        payment_date = data['payment_date']
    
    linked_invoice = Invoice.query.get(data['invoice_id']) if data.get('invoice_id') else None
    if data.get('invoice_id') and not linked_invoice:
        return jsonify({'error': 'Invoice not found'}), 404

    payment = Payment(
        invoice_id=data.get('invoice_id'),
        payment_type=data['payment_type'],
        payment_number=data.get('payment_number'),
        payment_date=payment_date,
        customer_id=data.get('customer_id') or (linked_invoice.customer_id if linked_invoice else None),
        supplier_id=data.get('supplier_id'),
        branch_id=data.get('branch_id') or claims.get('branch_id'),
        amount=data['amount'],
        currency=data.get('currency', 'USD'),
        exchange_rate=data.get('exchange_rate', 1),
        payment_method=data.get('payment_method'),
        reference_number=data.get('reference_number'),
        status=data.get('status', 'pending'),
        notes=data.get('notes')
    )
    
    db.session.add(payment)
    db.session.commit()

    if current_app.config.get('APP_ENV') != 'testing':
        try:
            sync_payment(payment)
        except PaymentSyncError as error:
            return jsonify({
                'error': 'Payment saved locally but ERPNext synchronization failed',
                'details': str(error),
                'payment': payment.to_dict(),
            }), 502
    
    return jsonify({
        'message': 'Payment created successfully',
        'payment': payment.to_dict()
    }), 201


@bp.route('/<payment_id>', methods=['PUT'])
@jwt_required()
def update_payment(payment_id):
    """تحديث دفعة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:update')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    payment = Payment.query.get(payment_id)
    if not payment:
        return jsonify({'error': 'Payment not found'}), 404
    
    # Cannot update completed payments
    if payment.status == 'completed':
        return jsonify({'error': 'Cannot update completed payments'}), 400
    
    data = request.get_json()
    
    if 'payment_date' in data:
        if isinstance(data['payment_date'], str):
            payment.payment_date = datetime.strptime(data['payment_date'], '%Y-%m-%d').date()
        else:
            payment.payment_date = data['payment_date']
    if 'amount' in data:
        old_amount = payment.amount
        payment.amount = data['amount']
        # Update invoice if linked
        if payment.invoice_id and old_amount != data['amount']:
            invoice = payment.invoice
            invoice.paid_amount = (invoice.paid_amount or 0) - old_amount + data['amount']
    if 'currency' in data:
        payment.currency = data['currency']
    if 'exchange_rate' in data:
        payment.exchange_rate = data['exchange_rate']
    if 'payment_method' in data:
        payment.payment_method = data['payment_method']
    if 'reference_number' in data:
        payment.reference_number = data['reference_number']
    if 'status' in data:
        payment.status = data['status']
    if 'notes' in data:
        payment.notes = data['notes']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Payment updated successfully',
        'payment': payment.to_dict()
    }), 200


@bp.route('/<payment_id>', methods=['DELETE'])
@jwt_required()
def delete_payment(payment_id):
    """حذف دفعة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'payment:delete')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    payment = Payment.query.get(payment_id)
    if not payment:
        return jsonify({'error': 'Payment not found'}), 404
    
    # Can only delete pending payments
    if payment.status != 'pending':
        return jsonify({'error': 'Can only delete pending payments'}), 400
    
    # Update invoice if linked
    if payment.invoice_id:
        invoice = payment.invoice
        if invoice:
            invoice.paid_amount = (invoice.paid_amount or 0) - payment.amount
            if invoice.paid_amount < invoice.total_amount:
                invoice.status = 'submitted'
    
    db.session.delete(payment)
    db.session.commit()
    
    return jsonify({'message': 'Payment deleted successfully'}), 200