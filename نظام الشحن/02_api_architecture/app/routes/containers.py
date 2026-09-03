"""
Containers Routes - مسارات الحاويات
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Container, Shipment
from ..database import db

bp = Blueprint('containers', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_containers():
    """الحصول على قائمة الحاويات"""
    shipment_id = request.args.get('shipment_id')
    container_type = request.args.get('container_type')
    status = request.args.get('status')
    search = request.args.get('search')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = Container.query
    
    if shipment_id:
        query = query.filter_by(shipment_id=shipment_id)
    if container_type:
        query = query.filter_by(container_type=container_type)
    if status:
        query = query.filter_by(status=status)
    if search:
        query = query.filter(
            db.or_(
                Container.container_number.ilike(f'%{search}%'),
                Container.seal_number.ilike(f'%{search}%')
            )
        )
    
    pagination = db.paginate(
        query.order_by(Container.created_at.desc()),
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'items': [c.to_dict() for c in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/types', methods=['GET'])
@jwt_required()
def get_container_types():
    """الحصول على أنواع الحاويات"""
    types = [
        {'code': '20GP', 'name': '20ft General Purpose', 'name_ar': 'حاوية 20 قدم عامة'},
        {'code': '40GP', 'name': '40ft General Purpose', 'name_ar': 'حاوية 40 قدم عامة'},
        {'code': '40HC', 'name': '40ft High Cube', 'name_ar': 'حاوية 40 قدم عالية'},
        {'code': '45HC', 'name': '45ft High Cube', 'name_ar': 'حاوية 45 قدم عالية'},
        {'code': '20OT', 'name': '20ft Open Top', 'name_ar': 'حاوية 20 قدم مكشوفة'},
        {'code': '40OT', 'name': '40ft Open Top', 'name_ar': 'حاوية 40 قدم مكشوفة'},
        {'code': '20RF', 'name': '20ft Reefer', 'name_ar': 'حاوية 20 قدم مبردة'},
        {'code': '40RF', 'name': '40ft Reefer', 'name_ar': 'حاوية 40 قدم مبردة'}
    ]
    return jsonify(types), 200


@bp.route('/<container_id>', methods=['GET'])
@jwt_required()
def get_container(container_id):
    """الحصول على حاوية محددة"""
    container = Container.query.get(container_id)
    
    if not container:
        return jsonify({'error': 'Container not found'}), 404
    
    data = container.to_dict()
    data['shipment'] = container.shipment.to_dict() if container.shipment else None
    data['tracking_events'] = [e.to_dict() for e in container.tracking_events.order_by('event_date').all()]
    
    return jsonify(data), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_container():
    """إنشاء حاوية"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    required = ['shipment_id', 'container_number', 'container_type']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Verify shipment exists
    shipment = Shipment.query.get(data['shipment_id'])
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    # Check if container number exists in this shipment
    existing = Container.query.filter_by(
        shipment_id=data['shipment_id'],
        container_number=data['container_number']
    ).first()
    if existing:
        return jsonify({'error': 'Container number already exists in this shipment'}), 400
    
    container = Container(
        shipment_id=data['shipment_id'],
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
        'message': 'Container created successfully',
        'container': container.to_dict()
    }), 201


@bp.route('/<container_id>', methods=['PUT'])
@jwt_required()
def update_container(container_id):
    """تحديث حاوية"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    container = Container.query.get(container_id)
    if not container:
        return jsonify({'error': 'Container not found'}), 404
    
    data = request.get_json()
    
    if 'container_number' in data:
        # Check uniqueness
        existing = Container.query.filter(
            Container.shipment_id == container.shipment_id,
            Container.container_number == data['container_number'],
            Container.id != container_id
        ).first()
        if existing:
            return jsonify({'error': 'Container number already exists'}), 400
        container.container_number = data['container_number']
    
    if 'container_type' in data:
        container.container_type = data['container_type']
    if 'seal_number' in data:
        container.seal_number = data['seal_number']
    if 'weight' in data:
        container.weight = data['weight']
    if 'volume' in data:
        container.volume = data['volume']
    if 'package_count' in data:
        container.package_count = data['package_count']
    if 'description' in data:
        container.description = data['description']
    if 'status' in data:
        container.status = data['status']
    if 'tracking_data' in data:
        container.tracking_data = data['tracking_data']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Container updated successfully',
        'container': container.to_dict()
    }), 200


@bp.route('/<container_id>', methods=['DELETE'])
@jwt_required()
def delete_container(container_id):
    """حذف حاوية"""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    container = Container.query.get(container_id)
    if not container:
        return jsonify({'error': 'Container not found'}), 404
    
    # Check for tracking events
    if container.tracking_events.count() > 0:
        return jsonify({'error': 'Cannot delete container with tracking events'}), 400
    
    db.session.delete(container)
    db.session.commit()
    
    return jsonify({'message': 'Container deleted successfully'}), 200


@bp.route('/<container_id>/tracking', methods=['GET'])
@jwt_required()
def get_container_tracking(container_id):
    """الحصول على تتبع الحاوية"""
    container = Container.query.get(container_id)
    if not container:
        return jsonify({'error': 'Container not found'}), 404
    
    events = container.tracking_events.order_by('event_date').all()
    
    return jsonify([e.to_dict() for e in events]), 200