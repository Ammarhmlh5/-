"""Secure generation and lifecycle helpers for integration credentials."""
import hashlib
import secrets
import uuid
from datetime import datetime, timedelta

from ..database import db
from ..models import IntegrationChannel, IntegrationCredential, IntegrationKeyEvent

CHANNELS = {
    'ADMIN': ('ADMIN_ERP_KEY', ['*']),
    'MARKET': ('MARKET_ERP_KEY', ['market:*']),
    'SHIPPING': ('SHIPPING_ERP_KEY', ['shipping:*'])
}


def fingerprint(secret):
    return hashlib.sha256(secret.encode('utf-8')).hexdigest()


def secret_hash(secret):
    return hashlib.sha512(secret.encode('utf-8')).hexdigest()


def get_or_create_channel(channel_code):
    channel = IntegrationChannel.query.filter_by(channel_code=channel_code).first()
    if channel:
        return channel
    channel = IntegrationChannel(channel_code=channel_code)
    db.session.add(channel)
    db.session.flush()
    return channel


def create_credential(channel_code, actor_id, owner_type='SYSTEM', owner_id=None,
                      scopes=None, expires_in_days=90, environment='development'):
    if channel_code not in CHANNELS:
        raise ValueError('Unsupported integration channel')
    if expires_in_days < 1 or expires_in_days > 3650:
        raise ValueError('expires_in_days must be between 1 and 3650')

    secret = secrets.token_urlsafe(48)
    channel = get_or_create_channel(channel_code)
    credential = IntegrationCredential(
        channel_id=channel.id,
        owner_type=owner_type,
        owner_id=owner_id,
        secret_ref=f'secret://integration/{channel_code.lower()}/{uuid.uuid4()}',
        key_fingerprint=fingerprint(secret),
        secret_hash=secret_hash(secret),
        scopes=scopes if scopes is not None else CHANNELS[channel_code][1],
        environment=environment,
        created_by=str(actor_id),
        expires_at=datetime.utcnow() + timedelta(days=expires_in_days),
        activated_at=datetime.utcnow()
    )
    db.session.add(credential)
    db.session.flush()
    channel.current_credential_id = credential.id
    db.session.add(IntegrationKeyEvent(
        credential_id=credential.id,
        channel_code=channel_code,
        actor_id=str(actor_id),
        action='CREATE',
        request_id=str(uuid.uuid4()),
        result='SUCCESS'
    ))
    db.session.commit()
    return credential, secret


def revoke_credential(credential, actor_id, reason_code='ADMIN_REQUEST'):
    if credential.status == 'REVOKED':
        return False
    credential.status = 'REVOKED'
    credential.revoked_by = str(actor_id)
    credential.revoked_at = datetime.utcnow()
    db.session.add(IntegrationKeyEvent(
        credential_id=credential.id,
        channel_code=credential.channel.channel_code,
        actor_id=str(actor_id),
        action='REVOKE',
        request_id=str(uuid.uuid4()),
        result='SUCCESS',
        reason_code=reason_code
    ))
    if credential.channel.current_credential_id == credential.id:
        credential.channel.status = 'DISABLED'
        credential.channel.current_credential_id = None
    db.session.commit()
    return True


def rotate_credential(old_credential, actor_id, expires_in_days=90):
    new_credential, secret = create_credential(
        old_credential.channel.channel_code,
        actor_id,
        old_credential.owner_type,
        old_credential.owner_id,
        old_credential.scopes,
        expires_in_days,
        old_credential.environment
    )
    channel = old_credential.channel
    channel.previous_credential_id = old_credential.id
    old_credential.status = 'GRACE_PERIOD'
    db.session.add(IntegrationKeyEvent(
        credential_id=old_credential.id,
        channel_code=channel.channel_code,
        actor_id=str(actor_id),
        action='ROTATE',
        request_id=str(uuid.uuid4()),
        result='SUCCESS'
    ))
    db.session.commit()
    return new_credential, secret
