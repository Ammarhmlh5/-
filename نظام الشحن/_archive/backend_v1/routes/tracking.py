from flask import Blueprint, request, jsonify
from app import db
from models import Shipment, TrackingEvent

bp = Blueprint('tracking', __name__, url_prefix='/api/tracking')

@bp.route('/shipment/<int:shipment_id>', methods=['GET'])
def get_shipment_tracking(shipment_id):
    shipment = Shipment.query.get_or_404(shipment_id)
    events = TrackingEvent.query.filter_by(shipment_id=shipment_id).order_by(TrackingEvent.timestamp.desc()).all()
    
    return jsonify({
        'shipment': shipment.to_dict(),
        'events': [e.to_dict() for e in events]
    })

@bp.route('/events', methods=['POST'])
def add_tracking_event():
    data = request.get_json()
    
    shipment = Shipment.query.get(data.get('shipment_id'))
    if not shipment:
        return jsonify({'error': 'الشحنة غير موجودة'}), 404
    
    event = TrackingEvent(
        shipment_id=data['shipment_id'],
        status=data.get('status'),
        location=data.get('location'),
        description=data.get('description')
    )
    
    # Update shipment status
    shipment.status = data.get('status')
    
    db.session.add(event)
    db.session.commit()
    
    return jsonify(event.to_dict()), 201

@bp.route('/events/<int:id>', methods=['GET'])
def get_tracking_event(id):
    event = TrackingEvent.query.get_or_404(id)
    return jsonify(event.to_dict())