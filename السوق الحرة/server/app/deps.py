"""
Dependencies - اعتماديات FastAPI للمصادقة وفحص الملكية
"""
from fastapi import Depends, HTTPException, Request
from sqlalchemy.orm import Session

from .database import get_db
from .models import Supplier, SupplierUser, MarketApiKey
from .security import decode_token


class AuthError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.message = message
        self.code = code


def get_current_access_claims(request: Request):
    """Parse the Bearer JWT (issued by /api/market/auth/login)."""
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization required")
    token = auth[7:]
    try:
        return decode_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


def require_role(claims: dict, roles: set[str]):
    if claims.get("role") not in roles:
        raise HTTPException(status_code=403, detail="Access denied for this role")


def get_api_key_record(request: Request, db: Session = Depends(get_db)) -> MarketApiKey:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization required")
    raw = auth[7:]
    from .services.key_service import lookup_key, validate_key
    try:
        return validate_key(db, raw)
    except Exception as exc:
        raise HTTPException(status_code=401, detail=str(exc.message))
