"""
Invoices Routes - مسارات الفواتير
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Invoice, Shipment, Customer
from ..database import db
from ..services.channel_guard import require_any_channel_scope
from datetime import datetime

bp = Blueprint('invoices', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_invoices():
    """الحصول على قائمة الفواتير"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    shipment_id = request.args.get('shipment_id')
    customer_id = request.args.get('customer_id')
    invoice_type = request.args.get('invoice_type')
    status = request.args.get('status')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = Invoice.query
    
    if shipment_id:
        query = query.filter_by(shipment_id=shipment_id)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    if invoice_type:
        query = query.filter_by(invoice_type=invoice_type)
    if status:
        query = query.filter_by(status=status)
    
    pagination = db.paginate(
        query.order_by(Invoice.invoice_date.desc()),
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'items': [i.to_dict() for i in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/stats', methods=['GET'])
@jwt_required()
def get_invoice_stats():
    """إحصائيات الفواتير"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    invoice_type = request.args.get('invoice_type')
    
    query = Invoice.query
    if invoice_type:
        query = query.filter_by(invoice_type=invoice_type)
    
    total = query.count()
    draft = query.filter_by(status='draft').count()
    submitted = query.filter_by(status='submitted').count()
    paid = query.filter_by(status='paid').count()
    
    # Calculate totals
    from sqlalchemy import func
    total_amount = query.with_entities(func.sum(Invoice.total_amount)).scalar() or 0
    paid_amount = query.with_entities(func.sum(Invoice.paid_amount)).scalar() or 0
    
    return jsonify({
        'total': total,
        'draft': draft,
        'submitted': submitted,
        'paid': paid,
        'total_amount': float(total_amount),
        'paid_amount': float(paid_amount),
        'outstanding': float(total_amount) - float(paid_amount)
    }), 200


@bp.route('/<invoice_id>', methods=['GET'])
@jwt_required()
def get_invoice(invoice_id):
    """الحصول على فاتورة محددة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    invoice = Invoice.query.get(invoice_id)
    
    if not invoice:
        return jsonify({'error': 'Invoice not found'}), 404
    
    data = invoice.to_dict()
    # Add related data
    if invoice.shipment:
        data['shipment'] = invoice.shipment.to_dict()
    if invoice.customer:
        data['customer'] = invoice.customer.to_dict()
    data['payments'] = [p.to_dict() for p in invoice.payments.all()]
    
    return jsonify(data), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_invoice():
    """إنشاء فاتورة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:create')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    required = ['invoice_type', 'amount']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    invoice = Invoice(
        shipment_id=data.get('shipment_id'),
        invoice_type=data['invoice_type'],
        invoice_number=data.get('invoice_number'),
        invoice_date=datetime.strptime(data['invoice_date'], '%Y-%m-%d').date() if data.get('invoice_date') else None,
        customer_id=data.get('customer_id'),
        supplier_id=data.get('supplier_id'),
        amount=data['amount'],
        tax_amount=data.get('tax_amount', 0),
        discount_amount=data.get('discount_amount', 0),
        total_amount=data.get('total_amount', data['amount']),
        currency=data.get('currency', 'USD'),
        status=data.get('status', 'draft'),
        cost_center_id=data.get('cost_center_id'),
        warehouse_id=data.get('warehouse_id'),
        due_date=datetime.strptime(data['due_date'], '%Y-%m-%d').date() if data.get('due_date') else None,
        notes=data.get('notes')
    )
    
    db.session.add(invoice)
    db.session.commit()
    
    return jsonify({
        'message': 'Invoice created successfully',
        'invoice': invoice.to_dict()
    }), 201


@bp.route('/<invoice_id>', methods=['PUT'])
@jwt_required()
def update_invoice(invoice_id):
    """تحديث فاتورة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:update')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    invoice = Invoice.query.get(invoice_id)
    if not invoice:
        return jsonify({'error': 'Invoice not found'}), 404
    
    # Cannot update submitted or paid invoices
    if invoice.status in ['submitted', 'paid']:
        return jsonify({'error': 'Cannot update submitted or paid invoices'}), 400
    
    data = request.get_json()
    
    if 'invoice_number' in data:
        invoice.invoice_number = data['invoice_number']
    if 'invoice_date' in data:
        invoice.invoice_date = datetime.strptime(data['invoice_date'], '%Y-%m-%d').date() if data['invoice_date'] else None
    if 'amount' in data:
        invoice.amount = data['amount']
    if 'tax_amount' in data:
        invoice.tax_amount = data['tax_amount']
    if 'discount_amount' in data:
        invoice.discount_amount = data['discount_amount']
    if 'total_amount' in data:
        invoice.total_amount = data['total_amount']
    if 'currency' in data:
        invoice.currency = data['currency']
    if 'status' in data:
        invoice.status = data['status']
    if 'due_date' in data:
        invoice.due_date = datetime.strptime(data['due_date'], '%Y-%m-%d').date() if data['due_date'] else None
    if 'notes' in data:
        invoice.notes = data['notes']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Invoice updated successfully',
        'invoice': invoice.to_dict()
    }), 200


@bp.route('/<invoice_id>', methods=['DELETE'])
@jwt_required()
def delete_invoice(invoice_id):
    """حذف فاتورة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:delete')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    invoice = Invoice.query.get(invoice_id)
    if not invoice:
        return jsonify({'error': 'Invoice not found'}), 404
    
    # Can only delete draft invoices
    if invoice.status != 'draft':
        return jsonify({'error': 'Can only delete draft invoices'}), 400
    
    db.session.delete(invoice)
    db.session.commit()
    
    return jsonify({'message': 'Invoice deleted successfully'}), 200


@bp.route('/<invoice_id>/payments', methods=['GET'])
@jwt_required()
def get_invoice_payments(invoice_id):
    """الحصول على مدفوعات الفاتورة"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'invoice:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    invoice = Invoice.query.get(invoice_id)
    if not invoice:
        return jsonify({'error': 'Invoice not found'}), 404
    
    payments = invoice.payments.all()
    
    return jsonify([p.to_dict() for p in payments]), 200