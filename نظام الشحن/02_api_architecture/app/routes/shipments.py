"""
Shipments Routes - مسارات الشحنات
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Shipment, Customer, Branch, Container, ShipmentItem
from ..database import db
from ..services.channel_guard import require_channel_scope
from datetime import datetime
import uuid

bp = Blueprint('shipments', __name__)


def generate_shipment_number(branch_code):
    """Generate unique shipment number"""
    year = datetime.now().year
    # Get last shipment number for this branch and year
    prefix = f"SHIP-{branch_code}-{year}-"
    last_shipment = Shipment.query.filter(
        Shipment.shipment_number.like(f"{prefix}%")
    ).order_by(Shipment.shipment_number.desc()).first()
    
    if last_shipment:
        last_num = int(last_shipment.shipment_number.split('-')[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    
    return f"{prefix}{new_num:04d}"


@bp.route('', methods=['GET'])
@jwt_required()
def get_shipments():
    """الحصول على قائمة الشحنات"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    branch_id = request.args.get('branch_id')
    customer_id = request.args.get('customer_id')
    status = request.args.get('status')
    search = request.args.get('search')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = Shipment.query
    
    # Filter by user's branch if not admin/manager
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager'] and claims.get('branch_id'):
        query = query.filter_by(branch_id=claims.get('branch_id'))
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    if status:
        query = query.filter_by(status=status)
    if search:
        query = query.filter(
            db.or_(
                Shipment.shipment_number.ilike(f'%{search}%'),
                Shipment.vessel_name.ilike(f'%{search}%'),
                Shipment.container_number.ilike(f'%{search}%')
            )
        )
    
    # Order by date descending
    query = query.order_by(Shipment.created_at.desc())
    
    # Paginate
    pagination = db.paginate(query, page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'items': [s.to_dict() for s in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/stats', methods=['GET'])
@jwt_required()
def get_shipment_stats():
    """إحصائيات الشحنات"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    branch_id = request.args.get('branch_id')
    
    query = Shipment.query
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    total = query.count()
    pending = query.filter_by(status='pending').count()
    loaded = query.filter_by(status='loaded').count()
    in_transit = query.filter_by(status='in_transit').count()
    customs = query.filter_by(status='customs').count()
    delivered = query.filter_by(status='delivered').count()
    
    return jsonify({
        'total': total,
        'pending': pending,
        'loaded': loaded,
        'in_transit': in_transit,
        'customs': customs,
        'delivered': delivered
    }), 200


@bp.route('/<shipment_id>', methods=['GET'])
@jwt_required()
def get_shipment(shipment_id):
    """الحصول على شحنة محددة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:read')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    shipment = Shipment.query.get(shipment_id)
    
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    # Get related data
    data = shipment.to_dict()
    data['containers'] = [c.to_dict() for c in shipment.containers.all()]
    data['items'] = [i.to_dict() for i in shipment.items.all()]
    
    return jsonify(data), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_shipment():
    """إنشاء شحنة جديدة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:create')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    # Validate required fields
    required = ['customer_id', 'branch_id']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Verify customer exists
    customer = Customer.query.get(data['customer_id'])
    if not customer:
        return jsonify({'error': 'Customer not found'}), 404
    
    # Verify branch exists
    branch = Branch.query.get(data['branch_id'])
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    # Generate shipment number
    shipment_number = generate_shipment_number(branch.code)
    
    # Create shipment
    shipment = Shipment(
        shipment_number=shipment_number,
        branch_id=data['branch_id'],
        customer_id=data['customer_id'],
        origin_port=data.get('origin_port'),
        destination_port=data.get('destination_port'),
        vessel_name=data.get('vessel_name'),
        voyage_number=data.get('voyage_number'),
        order_date=datetime.strptime(data['order_date'], '%Y-%m-%d').date() if data.get('order_date') else None,
        departure_date=datetime.fromisoformat(data['departure_date']) if data.get('departure_date') else None,
        expected_arrival=datetime.fromisoformat(data['expected_arrival']) if data.get('expected_arrival') else None,
        total_cost=data.get('total_cost', 0),
        selling_price=data.get('selling_price', 0),
        currency=data.get('currency', 'USD'),
        description=data.get('description'),
        notes=data.get('notes'),
        status=data.get('status', 'pending'),
        created_by=claims.get('sub')
    )
    
    db.session.add(shipment)
    db.session.commit()
    
    # Add items if provided
    if data.get('items'):
        for item_data in data['items']:
            item = ShipmentItem(
                shipment_id=shipment.id,
                item_name=item_data.get('item_name'),
                item_name_ar=item_data.get('item_name_ar'),
                item_code=item_data.get('item_code'),
                quantity=item_data.get('quantity', 1),
                unit=item_data.get('unit'),
                unit_price=item_data.get('unit_price'),
                total_price=item_data.get('total_price'),
                weight=item_data.get('weight'),
                volume=item_data.get('volume'),
                description=item_data.get('description')
            )
            db.session.add(item)
        db.session.commit()
    
    return jsonify({
        'message': 'Shipment created successfully',
        'shipment': shipment.to_dict()
    }), 201


@bp.route('/<shipment_id>', methods=['PUT'])
@jwt_required()
def update_shipment(shipment_id):
    """تحديث شحنة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:update')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    data = request.get_json()
    
    # Update fields
    if 'origin_port' in data:
        shipment.origin_port = data['origin_port']
    if 'destination_port' in data:
        shipment.destination_port = data['destination_port']
    if 'vessel_name' in data:
        shipment.vessel_name = data['vessel_name']
    if 'voyage_number' in data:
        shipment.voyage_number = data['voyage_number']
    if 'order_date' in data:
        shipment.order_date = datetime.strptime(data['order_date'], '%Y-%m-%d').date() if data['order_date'] else None
    if 'departure_date' in data:
        shipment.departure_date = datetime.fromisoformat(data['departure_date']) if data['departure_date'] else None
    if 'expected_arrival' in data:
        shipment.expected_arrival = datetime.fromisoformat(data['expected_arrival']) if data['expected_arrival'] else None
    if 'actual_arrival' in data:
        shipment.actual_arrival = datetime.fromisoformat(data['actual_arrival']) if data['actual_arrival'] else None
    if 'delivery_date' in data:
        shipment.delivery_date = datetime.fromisoformat(data['delivery_date']) if data['delivery_date'] else None
    if 'total_cost' in data:
        shipment.total_cost = data['total_cost']
    if 'selling_price' in data:
        shipment.selling_price = data['selling_price']
    if 'currency' in data:
        shipment.currency = data['currency']
    if 'status' in data:
        shipment.status = data['status']
    if 'description' in data:
        shipment.description = data['description']
    if 'notes' in data:
        shipment.notes = data['notes']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Shipment updated successfully',
        'shipment': shipment.to_dict()
    }), 200


@bp.route('/<shipment_id>', methods=['DELETE'])
@jwt_required()
def delete_shipment(shipment_id):
    """حذف شحنة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:delete')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    # Only allow delete if status is pending
    if shipment.status != 'pending':
        return jsonify({'error': 'Can only delete pending shipments'}), 400
    
    db.session.delete(shipment)
    db.session.commit()
    
    return jsonify({'message': 'Shipment deleted successfully'}), 200


@bp.route('/<shipment_id>/status', methods=['PUT'])
@jwt_required()
def update_shipment_status(shipment_id):
    """تحديث حالة الشحنة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:status')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    data = request.get_json()
    new_status = data.get('status')
    
    if not new_status:
        return jsonify({'error': 'status is required'}), 400
    
    valid_statuses = ['pending', 'loaded', 'in_transit', 'customs', 'delivered', 'cancelled']
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400
    
    old_status = shipment.status
    shipment.status = new_status
    
    # Set dates based on status
    if new_status == 'delivered' and not shipment.delivery_date:
        shipment.delivery_date = datetime.utcnow()
    elif new_status == 'in_transit' and not shipment.departure_date:
        shipment.departure_date = datetime.utcnow()
    
    db.session.commit()
    
    return jsonify({
        'message': f'Shipment status updated from {old_status} to {new_status}',
        'shipment': shipment.to_dict()
    }), 200


@bp.route('/<shipment_id>/containers', methods=['GET'])
@jwt_required()
def get_shipment_containers(shipment_id):
    """الحصول على حاويات الشحنة"""
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    containers = shipment.containers.all()
    
    return jsonify([c.to_dict() for c in containers]), 200


@bp.route('/<shipment_id>/containers', methods=['POST'])
@jwt_required()
def add_container(shipment_id):
    """إضافة حاوية للشحنة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:container')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    data = request.get_json()
    
    if not data.get('container_number') or not data.get('container_type'):
        return jsonify({'error': 'container_number and container_type are required'}), 400
    
    container = Container(
        shipment_id=shipment_id,
        container_number=data['container_number'],
        container_type=data['container_type'],
        seal_number=data.get('seal_number'),
        weight=data.get('weight'),
        volume=data.get('volume'),
        package_count=data.get('package_count', 0),
        description=data.get('description'),
        status=data.get('status', 'loading')
    )
    
    db.session.add(container)
    db.session.commit()
    
    return jsonify({
        'message': 'Container added successfully',
        'container': container.to_dict()
    }), 201


@bp.route('/<shipment_id>/invoice', methods=['POST'])
@jwt_required()
def link_invoice(shipment_id):
    """ربط فاتورة بالشحنة"""
    claims = get_jwt()
    try:
        require_channel_scope(claims, 'SHIPPING', 'shipment:invoice')
    except PermissionError:
        return jsonify({'error': 'Access denied: SHIPPING channel required'}), 403

    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    data = request.get_json()
    erpnext_invoice_id = data.get('erpnext_invoice_id')
    
    if not erpnext_invoice_id:
        return jsonify({'error': 'erpnext_invoice_id is required'}), 400
    
    shipment.erpnext_sales_invoice_id = erpnext_invoice_id
    db.session.commit()
    
    return jsonify({
        'message': 'Invoice linked successfully',
        'shipment': shipment.to_dict()
    }), 200