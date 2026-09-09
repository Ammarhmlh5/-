"""
Security - توليد JWT والتحقق وكلمات المرور
"""
import hashlib
import hmac
import secrets
import uuid
from datetime import datetime, timedelta

import bcrypt
import jwt

from .config import get_config

config = get_config()

ALGORITHM = config.JWT_ALGORITHM
SECRET_KEY = config.JWT_SECRET_KEY
ACCESS_TOKEN_EXPIRES = config.JWT_ACCESS_TOKEN_EXPIRES


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def check_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except ValueError:
        return False


def create_access_token(identity: str, additional_claims: dict | None = None) -> str:
    now = datetime.utcnow()
    payload = {
        "sub": identity,
        "iat": now,
        "exp": now + ACCESS_TOKEN_EXPIRES,
    }
    if additional_claims:
        payload.update(additional_claims)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])


def generate_api_key() -> tuple[str, str, str]:
    """Return (raw_key, fingerprint, hash). The raw key is shown once only."""
    raw = "mk_" + secrets.token_urlsafe(32)
    fingerprint = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    key_hash = fingerprint  # key_hash is the digest used for lookup; no plaintext stored
    return raw, fingerprint, key_hash


def fingerprint(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def constant_time_equal(a: str, b: str) -> bool:
    return hmac.compare_digest(a, b)


def new_request_id() -> str:
    return str(uuid.uuid4())
