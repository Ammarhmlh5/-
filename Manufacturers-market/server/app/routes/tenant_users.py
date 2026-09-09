"""
TenantUsers - إدارة موظفي المورد وحساباتهم التشغيلية المحلية
"""
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_access_claims, require_role
from ..models import Supplier, SupplierUser
from ..schemas import SupplierUserCreate
from ..security import hash_password
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/tenant-users", tags=["supplier-users"])


@router.post("", status_code=201)
def create_supplier_user(body: SupplierUserCreate,
                         claims=Depends(get_current_access_claims),
                         db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    supplier = db.get(Supplier, body.supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    if db.execute(select(SupplierUser).where(SupplierUser.username == body.username)).scalars().first():
        raise HTTPException(status_code=409, detail="Username already exists")
    if db.execute(select(SupplierUser).where(SupplierUser.email == body.email)).scalars().first():
        raise HTTPException(status_code=409, detail="Email already exists")

    user = SupplierUser(
        supplier_id=body.supplier_id,
        username=body.username,
        email=body.email,
        password_hash=hash_password(body.password),
        full_name=body.full_name,
        role=body.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    write_audit(db, request_id=new_request_id(), operation="CREATE_TENANT_USER", result="SUCCESS",
                tenant_id=body.supplier_id, actor_id=claims["sub"])
    return user.to_dict()


@router.get("/supplier/{supplier_id}")
def list_supplier_users(supplier_id: str, claims=Depends(get_current_access_claims),
                        db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    users = db.execute(select(SupplierUser).where(
        SupplierUser.supplier_id == supplier_id)).scalars().all()
    return [u.to_dict() for u in users]


@router.post("/{user_id}/deactivate")
def deactivate_user(user_id: str, claims=Depends(get_current_access_claims),
                    db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    user = db.get(SupplierUser, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    return {"message": "User deactivated", "user_id": user_id}
