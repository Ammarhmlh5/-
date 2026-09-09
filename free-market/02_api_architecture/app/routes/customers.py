"""
Customers Routes - مسارات العملاء
"""
from flask import Blueprint, current_app, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Customer, Branch, CustomerIntegrationCredential
from ..database import db
from ..services.channel_guard import require_any_channel_scope, require_channel_scope
from ..services.customer_key_service import issue_customer_key, revoke_customer_keys, rotate_customer_key
from ..services.customer_sync_service import CustomerSyncError, sync_customer

bp = Blueprint('customers', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_customers():
    """الحصول على قائمة العملاء"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    branch_id = request.args.get('branch_id')
    is_active = request.args.get('is_active', type=bool)
    search = request.args.get('search')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = Customer.query
    if claims.get('actor_type') == 'CUSTOMER':
        query = query.filter_by(id=claims.get('customer_id'))
    
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    if search:
        query = query.filter(
            db.or_(
                Customer.name.ilike(f'%{search}%'),
                Customer.name_ar.ilike(f'%{search}%'),
                Customer.phone.ilike(f'%{search}%'),
                Customer.email.ilike(f'%{search}%')
            )
        )
    
    # Paginate
    pagination = db.paginate(
        query.order_by(Customer.name),
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'items': [c.to_dict() for c in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/<customer_id>', methods=['GET'])
@jwt_required()
def get_customer(customer_id):
    """الحصول على عميل محدد"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    customer = Customer.query.get(customer_id)
    
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    if claims.get('actor_type') == 'CUSTOMER' and claims.get('customer_id') != customer_id:
        return jsonify({'error': 'Access denied'}), 403
    
    return jsonify(customer.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_customer():
    """إنشاء عميل جديد"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:create')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    # Validate required fields
    if 'name' not in data:
        return jsonify({'error': 'name is required'}), 400
    
    # Check if email exists
    if data.get('email'):
        existing = Customer.query.filter_by(email=data['email']).first()
        if existing:
            return jsonify({'error': 'Email already exists'}), 400
    
    # Create customer
    customer = Customer(
        name=data['name'],
        name_ar=data.get('name_ar'),
        name_en=data.get('name_en'),
        phone=data.get('phone'),
        email=data.get('email'),
        address=data.get('address'),
        address_ar=data.get('address_ar'),
        country=data.get('country'),
        city=data.get('city'),
        tax_number=data.get('tax_number'),
        credit_limit=data.get('credit_limit', 0),
        branch_id=data.get('branch_id') or claims.get('branch_id')
    )
    
    db.session.add(customer)
    db.session.commit()

    try:
        if current_app.config.get('APP_ENV') != 'testing':
            sync_customer(customer)
    except CustomerSyncError as error:
        return jsonify({
            'error': 'Customer saved locally but ERPNext synchronization failed',
            'details': str(error),
            'customer': customer.to_dict()
        }), 502

    try:
        credential, integration_key = issue_customer_key(customer, claims.get('sub'))
    except ValueError as error:
        return jsonify({'error': str(error), 'customer': customer.to_dict()}), 409
    
    return jsonify({
        'message': 'Customer created successfully',
        'customer': customer.to_dict(),
        'integration_key': integration_key,
        'integration_key_metadata': credential.to_dict(),
        'integration_key_warning': 'Store this key now. It will not be shown again.'
    }), 201


@bp.route('/<customer_id>', methods=['PUT'])
@jwt_required()
def update_customer(customer_id):
    """تحديث عميل"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:update')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    data = request.get_json()
    
    # Update fields
    if 'name' in data:
        customer.name = data['name']
    if 'name_ar' in data:
        customer.name_ar = data['name_ar']
    if 'name_en' in data:
        customer.name_en = data['name_en']
    if 'phone' in data:
        customer.phone = data['phone']
    if 'email' in data:
        existing = Customer.query.filter(
            Customer.email == data['email'],
            Customer.id != customer_id
        ).first()
        if existing:
            return jsonify({'error': 'Email already exists'}), 400
        customer.email = data['email']
    if 'address' in data:
        customer.address = data['address']
    if 'address_ar' in data:
        customer.address_ar = data['address_ar']
    if 'country' in data:
        customer.country = data['country']
    if 'city' in data:
        customer.city = data['city']
    if 'tax_number' in data:
        customer.tax_number = data['tax_number']
    if 'credit_limit' in data:
        customer.credit_limit = data['credit_limit']
    if 'branch_id' in data:
        customer.branch_id = data['branch_id']
    if 'is_active' in data:
        customer.is_active = data['is_active']
    
    db.session.commit()

    try:
        if current_app.config.get('APP_ENV') != 'testing':
            sync_customer(customer)
    except CustomerSyncError as error:
        return jsonify({
            'error': 'Customer updated locally but ERPNext synchronization failed',
            'details': str(error),
            'customer': customer.to_dict()
        }), 502
    
    return jsonify({
        'message': 'Customer updated successfully',
        'customer': customer.to_dict()
    }), 200


@bp.route('/<customer_id>', methods=['DELETE'])
@jwt_required()
def delete_customer(customer_id):
    """حذف عميل"""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:delete')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    # Check for shipments
    if customer.shipments.count() > 0:
        # Soft delete
        customer.is_active = False
        db.session.commit()
        return jsonify({'message': 'Customer deactivated (has related shipments)'}), 200
    
    db.session.delete(customer)
    db.session.commit()
    
    return jsonify({'message': 'Customer deleted successfully'}), 200


@bp.route('/<customer_id>/integration-key', methods=['POST'])
@jwt_required()
def create_customer_integration_key(customer_id):
    """إصدار مفتاح تشغيل محلي للعميل دون منحه مفتاح ERPNext."""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:key:create')
    except PermissionError:
        return jsonify({'error': 'Access denied'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Manager access required'}), 403

    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    data = request.get_json(silent=True) or {}
    try:
        credential, integration_key = issue_customer_key(
            customer, claims.get('sub'), data.get('scopes'),
            int(data.get('expires_in_days', 365))
        )
    except ValueError as error:
        return jsonify({'error': str(error)}), 409
    return jsonify({
        'customer_id': customer.id,
        'integration_key': integration_key,
        'integration_key_metadata': credential.to_dict(),
        'integration_key_warning': 'Store this key now. It will not be shown again.'
    }), 201


@bp.route('/<customer_id>/integration-key/rotate', methods=['POST'])
@jwt_required()
def rotate_customer_integration_key(customer_id):
    """تدوير مفتاح العميل وإبطال المفتاح السابق فورًا."""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:key:rotate')
    except PermissionError:
        return jsonify({'error': 'Access denied'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Manager access required'}), 403
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    data = request.get_json(silent=True) or {}
    try:
        credential, integration_key = rotate_customer_key(
            customer, claims.get('sub'), int(data.get('expires_in_days', 365))
        )
    except ValueError as error:
        return jsonify({'error': str(error)}), 400
    return jsonify({
        'customer_id': customer.id,
        'integration_key': integration_key,
        'integration_key_metadata': credential.to_dict(),
        'integration_key_warning': 'Store this key now. It will not be shown again.'
    }), 201


@bp.route('/<customer_id>/integration-key', methods=['GET'])
@jwt_required()
def customer_integration_key_status(customer_id):
    """عرض حالة مفتاح العميل دون عرض السر."""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:key:read')
    except PermissionError:
        return jsonify({'error': 'Access denied'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Manager access required'}), 403
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    keys = customer.integration_credentials.order_by(
        CustomerIntegrationCredential.created_at.desc()
    ).all()
    return jsonify({'customer_id': customer.id, 'keys': [key.to_dict() for key in keys]}), 200


@bp.route('/<customer_id>/integration-key/revoke', methods=['POST'])
@jwt_required()
def revoke_customer_integration_key(customer_id):
    """إبطال مفاتيح العميل النشطة فورًا."""
    claims = get_jwt()
    try:
        require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:key:revoke')
    except PermissionError:
        return jsonify({'error': 'Access denied'}), 403
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Manager access required'}), 403
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    revoked = revoke_customer_keys(customer)
    return jsonify({'customer_id': customer.id, 'revoked_count': revoked}), 200


@bp.route('/<customer_id>/shipments', methods=['GET'])
@jwt_required()
def get_customer_shipments(customer_id):
    """الحصول على شحنات العميل"""
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    shipments = customer.shipments.order_by(db.desc('created_at')).all()
    
    return jsonify([s.to_dict() for s in shipments]), 200


@bp.route('/<customer_id>/invoices', methods=['GET'])
@jwt_required()
def get_customer_invoices(customer_id):
    """الحصول على فواتير العميل"""
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    from ..models import Invoice
    invoices = Invoice.query.filter_by(customer_id=customer_id).order_by(Invoice.invoice_date.desc()).all()
    
    return jsonify([i.to_dict() for i in invoices]), 200