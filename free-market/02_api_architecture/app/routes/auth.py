"""
Authentication Routes - مسارات تسجيل الدخول والصلاحيات
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, jwt_required, get_jwt_identity
)
from ..models import User, Branch
from ..database import db
from ..services.channel_guard import derive_default_integration_claims
from ..services.customer_key_service import validate_customer_key
import bcrypt

bp = Blueprint('auth', __name__)


@bp.route('/login', methods=['POST'])
def login():
    """تسجيل دخول - Login"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'error': 'Username and password are required'}), 400
    
    # Find user
    user = User.query.filter_by(username=username).first()
    
    if not user or not user.is_active:
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Check password
    if not bcrypt.checkpw(password.encode('utf-8'), user.password_hash.encode('utf-8')):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Update last login
    from datetime import datetime
    user.last_login = datetime.utcnow()
    db.session.commit()
    
    # Create token
    permissions = user.permissions if isinstance(user.permissions, dict) else {}
    integration_channel, integration_scopes = derive_default_integration_claims(user.role, permissions)

    additional_claims = {
        'role': user.role,
        'branch_id': user.branch_id,
        'permissions': permissions,
        'integration_channel': integration_channel,
        'integration_scopes': integration_scopes
    }
    access_token = create_access_token(
        identity=user.id,
        additional_claims=additional_claims
    )
    
    return jsonify({
        'access_token': access_token,
        'user': user.to_dict()
    }), 200


@bp.route('/customer-key', methods=['POST'])
def customer_key_login():
    """تسجيل دخول العميل بمفتاحه المحلي المحدود."""
    data = request.get_json(silent=True) or {}
    raw_key = data.get('integration_key')
    if not raw_key:
        return jsonify({'error': 'integration_key is required'}), 400
    try:
        credential = validate_customer_key(raw_key)
    except ValueError as error:
        return jsonify({'error': str(error)}), 401
    customer = credential.customer
    if not customer.is_active:
        return jsonify({'error': 'Customer is inactive'}), 403
    token = create_access_token(
        identity=customer.id,
        additional_claims={
            'actor_type': 'CUSTOMER',
            'customer_id': customer.id,
            'integration_channel': 'SHIPPING',
            'integration_scopes': credential.scopes or [],
        }
    )
    return jsonify({'access_token': token, 'customer': customer.to_dict()}), 200


@bp.route('/register', methods=['POST'])
@jwt_required()
def register():
    """تسجيل مستخدم جديد - Register new user (Admin only)"""
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)
    
    if current_user.role != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    data = request.get_json()
    
    # Validate required fields
    required = ['username', 'email', 'password', 'full_name', 'role']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    # Check if username or email exists
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Username already exists'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already exists'}), 400
    
    # Hash password
    password_hash = bcrypt.hashpw(
        data['password'].encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')
    
    # Create user
    user = User(
        username=data['username'],
        email=data['email'],
        password_hash=password_hash,
        full_name=data.get('full_name'),
        full_name_ar=data.get('full_name_ar'),
        phone=data.get('phone'),
        branch_id=data.get('branch_id'),
        role=data.get('role', 'operator'),
        permissions=data.get('permissions', {})
    )
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify({
        'message': 'User created successfully',
        'user': user.to_dict()
    }), 201


@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """الحصول على بيانات المستخدم الحالي"""
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200


@bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """تغيير كلمة المرور"""
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'error': 'Current and new password are required'}), 400
    
    # Verify current password
    if not bcrypt.checkpw(current_password.encode('utf-8'), user.password_hash.encode('utf-8')):
        return jsonify({'error': 'Current password is incorrect'}), 400
    
    # Update password
    user.password_hash = bcrypt.hashpw(
        new_password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')
    
    db.session.commit()
    
    return jsonify({'message': 'Password changed successfully'}), 200


@bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    """الحصول على قائمة المستخدمين"""
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)
    
    if current_user.role not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    # Filter by branch if not admin
    branch_id = request.args.get('branch_id')
    
    query = User.query
    if current_user.role == 'manager' and current_user.branch_id:
        query = query.filter_by(branch_id=current_user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    users = query.all()
    
    return jsonify([user.to_dict() for user in users]), 200


@bp.route('/users/<user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    """الحصول على مستخدم محدد"""
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)
    
    if current_user.role not in ['admin', 'manager']:
        return jsonify({'error': 'Access denied'}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200


@bp.route('/users/<user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    """تحديث مستخدم"""
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)
    
    # Users can update their own profile, admin can update anyone
    if current_user.id != user_id and current_user.role != 'admin':
        return jsonify({'error': 'Access denied'}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    data = request.get_json()
    
    # Update fields
    if 'full_name' in data:
        user.full_name = data['full_name']
    if 'full_name_ar' in data:
        user.full_name_ar = data['full_name_ar']
    if 'phone' in data:
        user.phone = data['phone']
    if 'email' in data:
        # Check if new email is taken
        if User.query.filter(User.email == data['email'], User.id != user_id).first():
            return jsonify({'error': 'Email already exists'}), 400
        user.email = data['email']
    
    # Only admin can change role and branch
    if current_user.role == 'admin':
        if 'role' in data:
            user.role = data['role']
        if 'branch_id' in data:
            user.branch_id = data['branch_id']
        if 'is_active' in data:
            user.is_active = data['is_active']
        if 'permissions' in data:
            user.permissions = data['permissions']
    
    db.session.commit()
    
    return jsonify({
        'message': 'User updated successfully',
        'user': user.to_dict()
    }), 200


@bp.route('/users/<user_id>', methods=['DELETE'])
@jwt_required()
def delete_user(user_id):
    """حذف مستخدم"""
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)
    
    if current_user.role != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    # Cannot delete yourself
    if user.id == current_user_id:
        return jsonify({'error': 'Cannot delete your own account'}), 400
    
    # Soft delete - deactivate
    user.is_active = False
    db.session.commit()
    
    return jsonify({'message': 'User deactivated successfully'}), 200