"""
Branches Routes - مسارات الفروع (مكاتب China و Yemen)
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Branch, Warehouse, User
from ..database import db

bp = Blueprint('branches', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_branches():
    """الحصول على قائمة الفروع"""
    is_active = request.args.get('is_active', type=bool)
    
    query = Branch.query
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    
    branches = query.order_by(Branch.name).all()
    
    return jsonify([branch.to_dict() for branch in branches]), 200


@bp.route('/<branch_id>', methods=['GET'])
@jwt_required()
def get_branch(branch_id):
    """الحصول على فرع محدد"""
    branch = Branch.query.get(branch_id)
    
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    return jsonify(branch.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_branch():
    """إنشاء فرع جديد"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    # Validate required fields
    required = ['name', 'code', 'country']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Check if code exists
    if Branch.query.filter_by(code=data['code']).first():
        return jsonify({'error': 'Branch code already exists'}), 400
    
    # Create branch
    branch = Branch(
        name=data['name'],
        code=data['code'].upper(),
        country=data['country'],
        cost_center_id=data.get('cost_center_id'),
        warehouse_id=data.get('warehouse_id'),
        address=data.get('address'),
        phone=data.get('phone'),
        email=data.get('email')
    )
    
    db.session.add(branch)
    db.session.commit()
    
    return jsonify({
        'message': 'Branch created successfully',
        'branch': branch.to_dict()
    }), 201


@bp.route('/<branch_id>', methods=['PUT'])
@jwt_required()
def update_branch(branch_id):
    """تحديث فرع"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    branch = Branch.query.get(branch_id)
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    data = request.get_json()
    
    # Update fields
    if 'name' in data:
        branch.name = data['name']
    if 'code' in data:
        # Check if new code is taken
        existing = Branch.query.filter(Branch.code == data['code'], Branch.id != branch_id).first()
        if existing:
            return jsonify({'error': 'Branch code already exists'}), 400
        branch.code = data['code'].upper()
    if 'country' in data:
        branch.country = data['country']
    if 'cost_center_id' in data:
        branch.cost_center_id = data['cost_center_id']
    if 'warehouse_id' in data:
        branch.warehouse_id = data['warehouse_id']
    if 'address' in data:
        branch.address = data['address']
    if 'phone' in data:
        branch.phone = data['phone']
    if 'email' in data:
        branch.email = data['email']
    if 'is_active' in data:
        branch.is_active = data['is_active']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Branch updated successfully',
        'branch': branch.to_dict()
    }), 200


@bp.route('/<branch_id>', methods=['DELETE'])
@jwt_required()
def delete_branch(branch_id):
    """حذف فرع"""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    branch = Branch.query.get(branch_id)
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    # Check if there are related records
    if branch.shipments.count() > 0 or branch.users.count() > 0:
        # Soft delete
        branch.is_active = False
        db.session.commit()
        return jsonify({'message': 'Branch deactivated (has related records)'}), 200
    
    # Hard delete
    db.session.delete(branch)
    db.session.commit()
    
    return jsonify({'message': 'Branch deleted successfully'}), 200


@bp.route('/<branch_id>/warehouses', methods=['GET'])
@jwt_required()
def get_branch_warehouses(branch_id):
    """الحصول على مستودعات الفرع"""
    branch = Branch.query.get(branch_id)
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    warehouses = Warehouse.query.filter_by(branch_id=branch_id).all()
    
    return jsonify([w.to_dict() for w in warehouses]), 200


@bp.route('/<branch_id>/users', methods=['GET'])
@jwt_required()
def get_branch_users(branch_id):
    """الحصول على مستخدمي الفرع"""
    branch = Branch.query.get(branch_id)
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    users = User.query.filter_by(branch_id=branch_id).all()
    
    return jsonify([u.to_dict() for u in users]), 200


@bp.route('/<branch_id>/stats', methods=['GET'])
@jwt_required()
def get_branch_stats():
    """إحصائيات الفرع"""
    branch_id = request.args.get('branch_id')
    
    if not branch_id:
        return jsonify({'error': 'branch_id is required'}), 400
    
    branch = Branch.query.get(branch_id)
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    # Get stats
    from ..models import Shipment, Customer
    
    total_shipments = Shipment.query.filter_by(branch_id=branch_id).count()
    pending_shipments = Shipment.query.filter_by(branch_id=branch_id, status='pending').count()
    in_transit = Shipment.query.filter_by(branch_id=branch_id, status='in_transit').count()
    delivered = Shipment.query.filter_by(branch_id=branch_id, status='delivered').count()
    total_customers = Customer.query.filter_by(branch_id=branch_id).count()
    
    return jsonify({
        'branch_id': branch_id,
        'branch_name': branch.name,
        'shipments': {
            'total': total_shipments,
            'pending': pending_shipments,
            'in_transit': in_transit,
            'delivered': delivered
        },
        'customers': {
            'total': total_customers
        }
    }), 200