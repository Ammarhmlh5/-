"""
ApiKeys - إدارة مفاتيح المورد التشغيلية (محفوظة كهاش)
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_access_claims, require_role
from ..models import MarketApiKey, Supplier
from ..schemas import ApiKeyCreate
from ..services import key_service
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/api-keys", tags=["api-keys"])


@router.post("", status_code=201)
def create_key(body: ApiKeyCreate, claims=Depends(get_current_access_claims),
               db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    supplier_id = None
    if body.owner_type in ("TENANT", "EMPLOYEE"):
        from ..models import SupplierUser

        if body.owner_type == "TENANT":
            supplier = db.get(Supplier, body.owner_id)
            if not supplier:
                raise HTTPException(status_code=404, detail="Supplier not found")
            supplier_id = supplier.supplier_id
        else:
            employee = db.get(SupplierUser, body.owner_id)
            if not employee:
                raise HTTPException(status_code=404, detail="Employee not found")
            supplier_id = employee.supplier_id
    key, raw = key_service.create_api_key(
        db, supplier_id=supplier_id, owner_type=body.owner_type,
        owner_id=body.owner_id, scopes=body.scopes, created_by=claims["sub"],
        expires_in_days=body.expires_in_days,
    )
    response = key.to_dict()
    response["secret"] = raw
    response["warning"] = "Store this secret now. It will not be shown again."
    return response


@router.get("")
def list_keys(claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    keys = db.execute(select(MarketApiKey).order_by(MarketApiKey.created_at.desc())).scalars().all()
    return [k.to_dict() for k in keys]


@router.post("/{key_id}/rotate")
def rotate_key(key_id: str, claims=Depends(get_current_access_claims),
               db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    key = db.get(MarketApiKey, key_id)
    if not key:
        raise HTTPException(status_code=404, detail="Key not found")
    new_key, raw = key_service.rotate_key(db, key, created_by=claims["sub"])
    write_audit(db, request_id=new_request_id(), operation="ROTATE_KEY", result="SUCCESS",
                tenant_id=key.supplier_id, actor_key_id=key.key_id, actor_id=claims["sub"])
    response = new_key.to_dict()
    response["secret"] = raw
    response["warning"] = "Store this secret now. It will not be shown again."
    return response


@router.post("/{key_id}/revoke")
def revoke_key(key_id: str, claims=Depends(get_current_access_claims),
               db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    key = db.get(MarketApiKey, key_id)
    if not key:
        raise HTTPException(status_code=404, detail="Key not found")
    key_service.revoke_key(db, key, revoked_by=claims["sub"])
    write_audit(db, request_id=new_request_id(), operation="REVOKE_KEY", result="SUCCESS",
                tenant_id=key.supplier_id, actor_key_id=key.key_id, actor_id=claims["sub"])
    return {"message": "Key revoked", "key_id": key.key_id}
