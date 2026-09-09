from flask import Blueprint, request, jsonify
from app import db
from models import Customer

bp = Blueprint('customers', __name__, url_prefix='/api/customers')

@bp.route('/', methods=['GET'])
def get_customers():
    customers = Customer.query.all()
    return jsonify([c.to_dict() for c in customers])

@bp.route('/<int:id>', methods=['GET'])
def get_customer(id):
    customer = Customer.query.get_or_404(id)
    return jsonify(customer.to_dict())

@bp.route('/', methods=['POST'])
def create_customer():
    data = request.get_json()
    
    # Check if email already exists
    existing = Customer.query.filter_by(email=data.get('email')).first()
    if existing:
        return jsonify({'error': 'البريد الإلكتروني مسجل بالفعل'}), 400
    
    customer = Customer(
        name=data.get('name'),
        email=data.get('email'),
        phone=data.get('phone'),
        address=data.get('address')
    )
    
    db.session.add(customer)
    db.session.commit()
    
    return jsonify(customer.to_dict()), 201

@bp.route('/<int:id>', methods=['PUT'])
def update_customer(id):
    customer = Customer.query.get_or_404(id)
    data = request.get_json()
    
    customer.name = data.get('name', customer.name)
    customer.email = data.get('email', customer.email)
    customer.phone = data.get('phone', customer.phone)
    customer.address = data.get('address', customer.address)
    
    db.session.commit()
    
    return jsonify(customer.to_dict())

@bp.route('/<int:id>', methods=['DELETE'])
def delete_customer(id):
    customer = Customer.query.get_or_404(id)
    db.session.delete(customer)
    db.session.commit()
    
    return jsonify({'message': 'تم حذف العميل بنجاح'})