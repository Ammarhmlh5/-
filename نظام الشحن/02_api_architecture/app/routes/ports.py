"""
Ports Routes - مسارات الموانئ
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from ..models import Port
from ..database import db

bp = Blueprint('ports', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_ports():
    """الحصول على قائمة الموانئ"""
    country = request.args.get('country')
    is_active = request.args.get('is_active', type=bool)
    search = request.args.get('search')
    
    query = Port.query
    
    if country:
        query = query.filter_by(country=country)
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    if search:
        query = query.filter(
            db.or_(
                Port.name.ilike(f'%{search}%'),
                Port.name_ar.ilike(f'%{search}%'),
                Port.code.ilike(f'%{search}%')
            )
        )
    
    ports = query.order_by(Port.name).all()
    
    return jsonify([p.to_dict() for p in ports]), 200


@bp.route('/countries', methods=['GET'])
@jwt_required()
def get_countries():
    """الحصول على قائمة الدول"""
    countries = db.session.query(Port.country).distinct().all()
    return jsonify([c[0] for c in countries]), 200


@bp.route('/<port_id>', methods=['GET'])
@jwt_required()
def get_port(port_id):
    """الحصول على ميناء محدد"""
    port = Port.query.get(port_id)
    
    if not port:
        return jsonify({'error': 'Port not found'}), 404
    
    return jsonify(port.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_port():
    """إنشاء ميناء جديد"""
    data = request.get_json()
    
    required = ['name', 'country']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    port = Port(
        name=data['name'],
        name_ar=data.get('name_ar'),
        code=data.get('code'),
        country=data['country'],
        city=data.get('city')
    )
    
    db.session.add(port)
    db.session.commit()
    
    return jsonify({
        'message': 'Port created successfully',
        'port': port.to_dict()
    }), 201


@bp.route('/<port_id>', methods=['PUT'])
@jwt_required()
def update_port(port_id):
    """تحديث ميناء"""
    port = Port.query.get(port_id)
    if not port:
        return jsonify({'error': 'Port not found'}), 404
    
    data = request.get_json()
    
    if 'name' in data:
        port.name = data['name']
    if 'name_ar' in data:
        port.name_ar = data['name_ar']
    if 'code' in data:
        port.code = data['code']
    if 'country' in data:
        port.country = data['country']
    if 'city' in data:
        port.city = data['city']
    if 'is_active' in data:
        port.is_active = data['is_active']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Port updated successfully',
        'port': port.to_dict()
    }), 200


@bp.route('/<port_id>', methods=['DELETE'])
@jwt_required()
def delete_port(port_id):
    """حذف ميناء"""
    port = Port.query.get(port_id)
    if not port:
        return jsonify({'error': 'Port not found'}), 404
    
    # Soft delete
    port.is_active = False
    db.session.commit()
    
    return jsonify({'message': 'Port deactivated successfully'}), 200