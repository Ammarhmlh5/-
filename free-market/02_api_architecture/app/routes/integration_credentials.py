"""Administrative integration credential lifecycle endpoints."""
import uuid

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt, get_jwt_identity, jwt_required

from ..models import IntegrationCredential, IntegrationKeyEvent
from ..services.credential_service import CHANNELS, create_credential, revoke_credential, rotate_credential

bp = Blueprint('integration_credentials', __name__)


def require_admin():
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    return None


def request_id():
    return request.headers.get('X-Request-ID', str(uuid.uuid4()))


@bp.route('/channels/<channel_code>/credentials', methods=['POST'])
@jwt_required()
def create_channel_credential(channel_code):
    denied = require_admin()
    if denied:
        return denied
    channel_code = channel_code.upper()
    data = request.get_json(silent=True) or {}
    try:
        credential, secret = create_credential(
            channel_code=channel_code,
            actor_id=get_jwt_identity(),
            owner_type=data.get('owner_type', 'SYSTEM'),
            owner_id=data.get('owner_id'),
            scopes=data.get('scopes'),
            expires_in_days=int(data.get('expires_in_days', 90)),
            environment=data.get('environment', 'development')
        )
    except (TypeError, ValueError) as error:
        return jsonify({'error': str(error)}), 400
    response = credential.to_dict()
    response['secret'] = secret
    response['warning'] = 'Store this secret now. It will not be shown again.'
    return jsonify(response), 201


@bp.route('/credentials', methods=['GET'])
@jwt_required()
def list_credentials():
    denied = require_admin()
    if denied:
        return denied
    channel_code = request.args.get('channel', '').upper()
    query = IntegrationCredential.query
    if channel_code:
        if channel_code not in CHANNELS:
            return jsonify({'error': 'Unsupported integration channel'}), 400
        query = query.join(IntegrationCredential.channel).filter_by(channel_code=channel_code)
    return jsonify([credential.to_dict() for credential in query.order_by(IntegrationCredential.created_at.desc()).all()]), 200


@bp.route('/credentials/<credential_id>/rotate', methods=['POST'])
@jwt_required()
def rotate_channel_credential(credential_id):
    denied = require_admin()
    if denied:
        return denied
    credential = IntegrationCredential.query.get(credential_id)
    if not credential:
        return jsonify({'error': 'Credential not found'}), 404
    data = request.get_json(silent=True) or {}
    try:
        new_credential, secret = rotate_credential(
            credential, get_jwt_identity(), int(data.get('expires_in_days', 90))
        )
    except (TypeError, ValueError) as error:
        return jsonify({'error': str(error)}), 400
    response = new_credential.to_dict()
    response['secret'] = secret
    response['warning'] = 'Store this secret now. It will not be shown again.'
    return jsonify(response), 201


@bp.route('/credentials/<credential_id>/revoke', methods=['POST'])
@jwt_required()
def revoke_channel_credential(credential_id):
    denied = require_admin()
    if denied:
        return denied
    credential = IntegrationCredential.query.get(credential_id)
    if not credential:
        return jsonify({'error': 'Credential not found'}), 404
    data = request.get_json(silent=True) or {}
    revoke_credential(credential, get_jwt_identity(), data.get('reason_code', 'ADMIN_REQUEST'))
    return jsonify({'message': 'Credential revoked', 'credential': credential.to_dict()}), 200


@bp.route('/credentials/<credential_id>/events', methods=['GET'])
@jwt_required()
def credential_events(credential_id):
    denied = require_admin()
    if denied:
        return denied
    if not IntegrationCredential.query.get(credential_id):
        return jsonify({'error': 'Credential not found'}), 404
    events = IntegrationKeyEvent.query.filter_by(credential_id=credential_id).order_by(
        IntegrationKeyEvent.created_at.desc()
    ).all()
    return jsonify([event.to_dict() for event in events]), 200
