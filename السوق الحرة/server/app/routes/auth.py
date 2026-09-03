"""
Auth - تسجيل دخول موظفي السوق وموظفي الموردين
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select, or_
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Supplier, SupplierUser
from ..schemas import LoginRequest
from ..security import check_password, create_access_token
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login")
def login(body: LoginRequest, db: Session = Depends(get_db)):
    """Login for both market staff and supplier employees (role via identity)."""
    identity = body.identity.strip()
    user = db.execute(
        select(SupplierUser).where(
            or_(SupplierUser.username == identity, SupplierUser.email == identity)
        )
    ).scalars().first()

    # A user record exists -> supplier/employee login
    if user is not None:
        if not user.is_active:
            raise HTTPException(status_code=401, detail="Account is inactive")
        if not check_password(body.password, user.password_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        supplier = db.get(Supplier, user.supplier_id)
        token = create_access_token(identity=user.user_id, additional_claims={
            "actor_type": "SUPPLIER_EMPLOYEE",
            "role": user.role,
            "supplier_id": user.supplier_id,
        })
        write_audit(db, request_id=new_request_id(), operation="AUTH_LOGIN",
                    result="SUCCESS", tenant_id=user.supplier_id, actor_id=user.user_id)
        return {"access_token": token, "actor_type": "SUPPLIER_EMPLOYEE", "user": user.to_dict()}

    # Otherwise treat as a market operator (seeded by bootstrap)
    from ..models import MarketOperator
    operator = db.execute(
        select(MarketOperator).where(
            or_(MarketOperator.username == identity, MarketOperator.email == identity)
        )
    ).scalars().first()
    if not operator or not operator.is_active:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not check_password(body.password, operator.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(identity=operator.operator_id, additional_claims={
        "actor_type": "MARKET_STAFF",
        "role": operator.role,
    })
    write_audit(db, request_id=new_request_id(), operation="AUTH_LOGIN",
                result="SUCCESS", actor_id=operator.operator_id)
    return {"access_token": token, "actor_type": "MARKET_STAFF", "user": operator.to_dict()}
