"""
Keys - إدارة المفاتيح التشغيلية (محفوظة كهاش) والتحقق منها
"""
from datetime import datetime, timedelta

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from ..models import MarketApiKey, Supplier
from ..security import fingerprint, generate_api_key


class KeyError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.message = message
        self.code = code


def create_api_key(db: Session, supplier_id: str | None, owner_type: str, owner_id: str,
                   scopes: list[str] | None = None, created_by: str | None = None,
                   expires_in_days: int | None = None) -> tuple[MarketApiKey, str]:
    raw, fp, key_hash = generate_api_key()
    key = MarketApiKey(
        supplier_id=supplier_id,
        owner_type=owner_type,
        owner_id=owner_id,
        key_fingerprint=fp,
        key_hash=key_hash,
        scopes=scopes or [],
        status="ACTIVE",
        expires_at=datetime.utcnow() + timedelta(days=expires_in_days) if expires_in_days else None,
        created_by=created_by,
    )
    db.add(key)
    db.commit()
    db.refresh(key)
    return key, raw


def lookup_key(db: Session, raw_key: str) -> MarketApiKey | None:
    fp = fingerprint(raw_key)
    return db.execute(select(MarketApiKey).where(MarketApiKey.key_fingerprint == fp)).scalars().first()


def validate_key(db: Session, raw_key: str, require_scope: str | None = None) -> MarketApiKey:
    key = lookup_key(db, raw_key)
    if not key:
        raise KeyError("Invalid API key", "INVALID_KEY")
    if key.status != "ACTIVE":
        raise KeyError("API key is not active", "KEY_REVOKED")
    if key.expires_at and key.expires_at < datetime.utcnow():
        raise KeyError("API key has expired", "KEY_EXPIRED")
    if require_scope and require_scope not in (key.scopes or []):
        raise KeyError("API key missing required scope", "SCOPE_DENIED")
    key.last_used_at = datetime.utcnow()
    db.commit()
    return key


def revoke_key(db: Session, key: MarketApiKey, revoked_by: str = None):
    key.status = "REVOKED"
    key.revoked_by = revoked_by
    key.revoked_at = datetime.utcnow()
    db.commit()


def rotate_key(db: Session, key: MarketApiKey, created_by: str = None) -> tuple[MarketApiKey, str]:
    revoke_key(db, key, revoked_by=created_by)
    scopes = key.scopes or []
    expires = int((key.expires_at - datetime.utcnow()).days) if key.expires_at else None
    new_key, raw = create_api_key(
        db,
        supplier_id=key.supplier_id,
        owner_type=key.owner_type,
        owner_id=key.owner_id,
        scopes=scopes,
        created_by=created_by,
        expires_in_days=max(expires, 1) if expires else None,
    )
    return new_key, raw
