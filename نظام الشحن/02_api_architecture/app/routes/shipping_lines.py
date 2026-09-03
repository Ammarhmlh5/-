"""
Shipping Lines Routes - مسارات شركات الشحن
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from ..models import ShippingLine
from ..database import db

bp = Blueprint('shipping_lines', __name__)


@bp.route('', methods=['GET'])
@jwt_required()
def get_shipping_lines():
    """الحصول على قائمة شركات الشحن"""
    is_active = request.args.get('is_active', type=bool)
    search = request.args.get('search')
    
    query = ShippingLine.query
    
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    if search:
        query = query.filter(
            db.or_(
                ShippingLine.name.ilike(f'%{search}%'),
                ShippingLine.name_ar.ilike(f'%{search}%'),
                ShippingLine.code.ilike(f'%{search}%')
            )
        )
    
    lines = query.order_by(ShippingLine.name).all()
    
    return jsonify([l.to_dict() for l in lines]), 200


@bp.route('/<line_id>', methods=['GET'])
@jwt_required()
def get_shipping_line(line_id):
    """الحصول على شركة شحن محددة"""
    line = ShippingLine.query.get(line_id)
    
    if not line:
        return jsonify({'error': 'Shipping line not found'}), 404
    
    return jsonify(line.to_dict()), 200


@bp.route('', methods=['POST'])
@jwt_required()
def create_shipping_line():
    """إنشاء شركة شحن جديدة"""
    data = request.get_json()
    
    required = ['name']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    line = ShippingLine(
        name=data['name'],
        name_ar=data.get('name_ar'),
        code=data.get('code'),
        api_endpoint=data.get('api_endpoint'),
        tracking_url_template=data.get('tracking_url_template'),
        notes=data.get('notes')
    )
    
    db.session.add(line)
    db.session.commit()
    
    return jsonify({
        'message': 'Shipping line created successfully',
        'line': line.to_dict()
    }), 201


@bp.route('/<line_id>', methods=['PUT'])
@jwt_required()
def update_shipping_line(line_id):
    """تحديث شركة شحن"""
    line = ShippingLine.query.get(line_id)
    if not line:
        return jsonify({'error': 'Shipping line not found'}), 404
    
    data = request.get_json()
    
    if 'name' in data:
        line.name = data['name']
    if 'name_ar' in data:
        line.name_ar = data['name_ar']
    if 'code' in data:
        line.code = data['code']
    if 'api_endpoint' in data:
        line.api_endpoint = data['api_endpoint']
    if 'tracking_url_template' in data:
        line.tracking_url_template = data['tracking_url_template']
    if 'notes' in data:
        line.notes = data['notes']
    if 'is_active' in data:
        line.is_active = data['is_active']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Shipping line updated successfully',
        'line': line.to_dict()
    }), 200


@bp.route('/<line_id>', methods=['DELETE'])
@jwt_required()
def delete_shipping_line(line_id):
    """حذف شركة شحن"""
    line = ShippingLine.query.get(line_id)
    if not line:
        return jsonify({'error': 'Shipping line not found'}), 404
    
    # Soft delete
    line.is_active = False
    db.session.commit()
    
    return jsonify({'message': 'Shipping line deactivated successfully'}), 200


@bp.route('/<line_id>/track', methods=['GET'])
@jwt_required()
def get_tracking_url(line_id):
    """الحصول على رابط تتبع شركة الشحن"""
    line = ShippingLine.query.get(line_id)
    
    if not line:
        return jsonify({'error': 'Shipping line not found'}), 404
    
    container_number = request.args.get('container_number')
    
    if not container_number:
        return jsonify({'error': 'container_number is required'}), 400
    
    if not line.tracking_url_template:
        return jsonify({'error': 'Tracking URL not configured'}), 400
    
    # Generate tracking URL
    tracking_url = line.tracking_url_template.replace('{container_no}', container_number)
    
    return jsonify({
        'tracking_url': tracking_url,
        'carrier': line.name
    }), 200