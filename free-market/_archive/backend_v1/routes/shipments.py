from flask import Blueprint, request, jsonify
from app import db
from models import Shipment, Customer
from datetime import datetime
import uuid

bp = Blueprint('shipments', __name__, url_prefix='/api/shipments')

@bp.route('/', methods=['GET'])
def get_shipments():
    shipments = Shipment.query.all()
    return jsonify([s.to_dict() for s in shipments])

@bp.route('/<int:id>', methods=['GET'])
def get_shipment(id):
    shipment = Shipment.query.get_or_404(id)
    return jsonify(shipment.to_dict())

@bp.route('/', methods=['POST'])
def create_shipment():
    data = request.get_json()
    
    # Validate customer exists
    customer = Customer.query.get(data.get('customer_id'))
    if not customer:
        return jsonify({'error': 'العميل غير موجود'}), 404
    
    # Generate unique tracking number
    tracking_number = f"SH-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    
    shipment = Shipment(
        tracking_number=tracking_number,
        customer_id=data['customer_id'],
        status=data.get('status', 'pending'),
        origin=data.get('origin'),
        destination=data.get('destination'),
        weight=data.get('weight'),
        dimensions=data.get('dimensions'),
        shipping_cost=data.get('shipping_cost')
    )
    
    db.session.add(shipment)
    db.session.commit()
    
    return jsonify(shipment.to_dict()), 201

@bp.route('/<int:id>', methods=['PUT'])
def update_shipment(id):
    shipment = Shipment.query.get_or_404(id)
    data = request.get_json()
    
    shipment.status = data.get('status', shipment.status)
    shipment.origin = data.get('origin', shipment.origin)
    shipment.destination = data.get('destination', shipment.destination)
    shipment.weight = data.get('weight', shipment.weight)
    shipment.dimensions = data.get('dimensions', shipment.dimensions)
    shipment.shipping_cost = data.get('shipping_cost', shipment.shipping_cost)
    
    db.session.commit()
    
    return jsonify(shipment.to_dict())

@bp.route('/<int:id>', methods=['DELETE'])
def delete_shipment(id):
    shipment = Shipment.query.get_or_404(id)
    db.session.delete(shipment)
    db.session.commit()
    
    return jsonify({'message': 'تم حذف الشحنة بنجاح'})

@bp.route('/tracking/<tracking_number>', methods=['GET'])
def track_shipment(tracking_number):
    shipment = Shipment.query.filter_by(tracking_number=tracking_number).first()
    if not shipment:
        return jsonify({'error': 'الشحنة غير موجودة'}), 404
    
    return jsonify(shipment.to_dict())