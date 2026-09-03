"""
Warehouses Routes - مسارات المستودعات
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Warehouse, Branch
from ..database import db

bp = Blueprint('warehouses', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_warehouses():
    """الحصول على قائمة المستودعات"""
    branch_id = request.args.get('branch_id')
    is_active = request.args.get('is_active', type=bool)
    parent_id = request.args.get('parent_id')
    
    query = Warehouse.query
    
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    if parent_id:
        query = query.filter_by(parent_warehouse_id=parent_id)
    elif not parent_id and not branch_id:
        # Get root warehouses (no parent)
        query = query.filter_by(parent_warehouse_id=None)
    
    warehouses = query.order_by(Warehouse.name).all()
    
    return jsonify([w.to_dict() for w in warehouses]), 200


@bp.route('/<warehouse_id>', methods=['GET'])
@jwt_required()
def get_warehouse(warehouse_id):
    """الحصول على مستودع محدد"""
    warehouse = Warehouse.query.get(warehouse_id)
    
    if not warehouse:
        return jsonify({'error': 'Warehouse not found'}), 404
    
    return jsonify(warehouse.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_warehouse():
    """إنشاء مستودع جديد"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    data = request.get_json()
    
    # Validate required fields
    required = ['name', 'branch_id']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Verify branch exists
    branch = Branch.query.get(data['branch_id'])
    if not branch:
        return jsonify({'error': 'Branch not found'}), 404
    
    # Verify parent warehouse if provided
    if data.get('parent_warehouse_id'):
        parent = Warehouse.query.get(data['parent_warehouse_id'])
        if not parent:
            return jsonify({'error': 'Parent warehouse not found'}), 404
        if parent.branch_id != data['branch_id']:
            return jsonify({'error': 'Parent warehouse must be in the same branch'}), 400
    
    # Create warehouse
    warehouse = Warehouse(
        name=data['name'],
        branch_id=data['branch_id'],
        erpnext_warehouse_id=data.get('erpnext_warehouse_id'),
        parent_warehouse_id=data.get('parent_warehouse_id'),
        location=data.get('location')
    )
    
    db.session.add(warehouse)
    db.session.commit()
    
    return jsonify({
        'message': 'Warehouse created successfully',
        'warehouse': warehouse.to_dict()
    }), 201


@bp.route('/<warehouse_id>', methods=['PUT'])
@jwt_required()
def update_warehouse(warehouse_id):
    """تحديث مستودع"""
    claims = get_jwt()
    if claims.get('role') not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    warehouse = Warehouse.query.get(warehouse_id)
    if not warehouse:
        return jsonify({'error': 'Warehouse not found'}), 404
    
    data = request.get_json()
    
    # Update fields
    if 'name' in data:
        warehouse.name = data['name']
    if 'erpnext_warehouse_id' in data:
        warehouse.erpnext_warehouse_id = data['erpnext_warehouse_id']
    if 'location' in data:
        warehouse.location = data['location']
    if 'is_active' in data:
        warehouse.is_active = data['is_active']
    if 'parent_warehouse_id' in data:
        if data['parent_warehouse_id']:
            parent = Warehouse.query.get(data['parent_warehouse_id'])
            if not parent:
                return jsonify({'error': 'Parent warehouse not found'}), 404
            if parent.branch_id != warehouse.branch_id:
                return jsonify({'error': 'Parent warehouse must be in the same branch'}), 400
        warehouse.parent_warehouse_id = data['parent_warehouse_id']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Warehouse updated successfully',
        'warehouse': warehouse.to_dict()
    }), 200


@bp.route('/<warehouse_id>', methods=['DELETE'])
@jwt_required()
def delete_warehouse(warehouse_id):
    """حذف مستودع"""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    warehouse = Warehouse.query.get(warehouse_id)
    if not warehouse:
        return jsonify({'error': 'Warehouse not found'}), 404
    
    # Check for children
    if warehouse.children.count() > 0:
        return jsonify({'error': 'Cannot delete warehouse with child warehouses'}), 400
    
    # Check for shipments
    # In a real app, you'd check if there are shipments in this warehouse
    
    db.session.delete(warehouse)
    db.session.commit()
    
    return jsonify({'message': 'Warehouse deleted successfully'}), 200


@bp.route('/<warehouse_id>/children', methods=['GET'])
@jwt_required()
def get_warehouse_children(warehouse_id):
    """الحصول على المستودعات الفرعية"""
    warehouse = Warehouse.query.get(warehouse_id)
    if not warehouse:
        return jsonify({'error': 'Warehouse not found'}), 404
    
    children = warehouse.children.all()
    
    return jsonify([c.to_dict() for c in children]), 200