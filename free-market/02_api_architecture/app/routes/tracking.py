"""
Tracking Routes - مسارات تتبع الحاويات
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import TrackingEvent, Container, Shipment
from ..database import db
from datetime import datetime

bp = Blueprint('tracking', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_tracking_events():
    """الحصول على قائمة أحداث التتبع"""
    container_id = request.args.get('container_id')
    shipment_id = request.args.get('shipment_id')
    event_type = request.args.get('event_type')
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = TrackingEvent.query
    
    if container_id:
        query = query.filter_by(container_id=container_id)
    if shipment_id:
        query = query.filter_by(shipment_id=shipment_id)
    if event_type:
        query = query.filter_by(event_type=event_type)
    
    pagination = db.paginate(
        query.order_by(TrackingEvent.event_date.desc()),
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'items': [e.to_dict() for e in pagination.items],
        'total': pagination.total,
        'page': page,
        'per_page': per_page,
        'pages': pagination.pages
    }), 200


@bp.route('/event-types', methods=['GET'])
@jwt_required()
def get_event_types():
    """الحصول على أنواع أحداث التتبع"""
    types = [
        {'code': 'departure', 'name': 'Departure', 'name_ar': 'مغادرة'},
        {'code': 'in_transit', 'name': 'In Transit', 'name_ar': 'في الطريق'},
        {'code': 'arrival', 'name': 'Arrival', 'name_ar': 'وصول'},
        {'code': 'customs', 'name': 'Customs Clearance', 'name_ar': 'تخليص جمركي'},
        {'code': 'delivery', 'name': 'Delivery', 'name_ar': 'تسليم'},
        {'code': 'delay', 'name': 'Delay', 'name_ar': 'تأخير'},
        {'code': 'inspection', 'name': 'Inspection', 'name_ar': 'فحص'},
        {'code': 'damage', 'name': 'Damage Reported', 'name_ar': 'تلف'}
    ]
    return jsonify(types), 200


@bp.route('/<event_id>', methods=['GET'])
@jwt_required()
def get_tracking_event(event_id):
    """الحصول على حدث تتبع محدد"""
    event = TrackingEvent.query.get(event_id)
    
    if not event:
        return jsonify({'error': 'Tracking event not found'}), 404
    
    return jsonify(event.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_tracking_event():
    """إنشاء حدث تتبع جديد"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager', 'operator']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    required = ['container_id', 'event_type', 'event_date']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Verify container exists
    container = Container.query.get(data['container_id'])
    if not container:
        return jsonify({'error': 'Container not found'}), 404
    
    # Parse event_date
    if isinstance(data['event_date'], str):
        try:
            event_date = datetime.fromisoformat(data['event_date'].replace('Z', '+00:00'))
        except:
            try:
                event_date = datetime.strptime(data['event_date'], '%Y-%m-%d %H:%M:%S')
            except:
                return jsonify({'error': 'Invalid date format'}), 400
    else:
        event_date = data['event_date']
    
    # Create tracking event
    event = TrackingEvent(
        container_id=data['container_id'],
        shipment_id=container.shipment_id,
        event_type=data['event_type'],
        event_date=event_date,
        location=data.get('location'),
        port_code=data.get('port_code'),
        country=data.get('country'),
        description=data.get('description'),
        source=data.get('source', 'manual'),
        reference_number=data.get('reference_number'),
        latitude=data.get('latitude'),
        longitude=data.get('longitude')
    )
    
    db.session.add(event)
    
    # Update container status
    container.status = data['event_type']
    if data.get('tracking_data'):
        container.tracking_data = data['tracking_data']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Tracking event created successfully',
        'event': event.to_dict()
    }), 201


@bp.route('/<event_id>', methods=['PUT'])
@jwt_required()
def update_tracking_event(event_id):
    """تحديث حدث تتبع"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    event = TrackingEvent.query.get(event_id)
    if not event:
        return jsonify({'error': 'Tracking event not found'}), 404
    
    data = request.get_json()
    
    if 'event_type' in data:
        event.event_type = data['event_type']
    if 'event_date' in data:
        if isinstance(data['event_date'], str):
            event.event_date = datetime.fromisoformat(data['event_date'].replace('Z', '+00:00'))
        else:
            event.event_date = data['event_date']
    if 'location' in data:
        event.location = data['location']
    if 'port_code' in data:
        event.port_code = data['port_code']
    if 'country' in data:
        event.country = data['country']
    if 'description' in data:
        event.description = data['description']
    if 'reference_number' in data:
        event.reference_number = data['reference_number']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Tracking event updated successfully',
        'event': event.to_dict()
    }), 200


@bp.route('/<event_id>', methods=['DELETE'])
@jwt_required()
def delete_tracking_event(event_id):
    """حذف حدث تتبع"""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    event = TrackingEvent.query.get(event_id)
    if not event:
        return jsonify({'error': 'Tracking event not found'}), 404
    
    db.session.delete(event)
    db.session.commit()
    
    return jsonify({'message': 'Tracking event deleted successfully'}), 200


@bp.route('/shipment/<shipment_id>/timeline', methods=['GET'])
@jwt_required()
def get_shipment_timeline(shipment_id):
    """الحصول على timeline الشحنة"""
    shipment = Shipment.query.get(shipment_id)
    if not shipment:
        return jsonify({'error': 'Shipment not found'}), 404
    
    # Get all containers and their tracking events
    containers = shipment.containers.all()
    
    timeline = []
    for container in containers:
        events = container.tracking_events.order_by(TrackingEvent.event_date).all()
        for event in events:
            timeline.append({
                'id': event.id,
                'container_number': container.container_number,
                'container_type': container.container_type,
                'event_type': event.event_type,
                'event_date': event.event_date.isoformat() if event.event_date else None,
                'location': event.location,
                'description': event.description,
                'source': event.source
            })
    
    # Sort by date
    timeline.sort(key=lambda x: x['event_date'] or '')
    
    return jsonify(timeline), 200