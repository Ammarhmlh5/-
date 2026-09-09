"""Lifecycle management for customer-local integration keys."""
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from ..database import db
from ..models import Customer, CustomerIntegrationCredential


DEFAULT_SCOPES = ['customer:read', 'shipment:read', 'invoice:read', 'payment:read']
ALLOWED_SCOPES = set(DEFAULT_SCOPES)


def issue_customer_key(customer: Customer, actor_id: str, scopes=None, expires_in_days=365):
    active = customer.integration_credentials.filter_by(status='ACTIVE').first()
    if active:
        raise ValueError('Customer already has an active integration key')
    if expires_in_days < 1 or expires_in_days > 3650:
        raise ValueError('expires_in_days must be between 1 and 3650')
    requested_scopes = scopes or DEFAULT_SCOPES
    invalid_scopes = set(requested_scopes) - ALLOWED_SCOPES
    if invalid_scopes:
        raise ValueError(f'Unsupported customer scopes: {", ".join(sorted(invalid_scopes))}')

    raw_key = 'cust_' + secrets.token_urlsafe(48)
    credential = CustomerIntegrationCredential(
        customer_id=customer.id,
        key_fingerprint=hashlib.sha256(raw_key.encode()).hexdigest(),
        key_hash=hashlib.sha512(raw_key.encode()).hexdigest(),
        scopes=requested_scopes,
        expires_at=datetime.utcnow() + timedelta(days=expires_in_days),
        created_by=str(actor_id),
    )
    db.session.add(credential)
    db.session.commit()
    return credential, raw_key


def rotate_customer_key(customer: Customer, actor_id: str, expires_in_days=365):
    for credential in customer.integration_credentials.filter_by(status='ACTIVE').all():
        credential.status = 'REVOKED'
        credential.revoked_at = datetime.utcnow()
    db.session.commit()
    return issue_customer_key(customer, actor_id, expires_in_days=expires_in_days)


def revoke_customer_keys(customer: Customer):
    revoked = 0
    for credential in customer.integration_credentials.filter_by(status='ACTIVE').all():
        credential.status = 'REVOKED'
        credential.revoked_at = datetime.utcnow()
        revoked += 1
    db.session.commit()
    return revoked


def validate_customer_key(raw_key: str):
    fingerprint = hashlib.sha256(raw_key.encode()).hexdigest()
    credential = CustomerIntegrationCredential.query.filter_by(
        key_fingerprint=fingerprint
    ).first()
    if not credential or credential.status != 'ACTIVE':
        raise ValueError('Invalid or inactive customer integration key')
    if credential.expires_at and credential.expires_at < datetime.now(timezone.utc):
        credential.status = 'EXPIRED'
        db.session.commit()
        raise ValueError('Customer integration key has expired')
    if not hmac.compare_digest(credential.key_hash, hashlib.sha512(raw_key.encode()).hexdigest()):
        raise ValueError('Invalid or inactive customer integration key')
    credential.last_used_at = datetime.utcnow()
    db.session.commit()
    return credential