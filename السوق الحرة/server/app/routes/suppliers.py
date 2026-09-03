"""
Suppliers - إدارة الموردين الصينيين واعتمادهم
"""
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_access_claims, require_role
from ..models import MarketProvisioningJob, Supplier
from ..schemas import SupplierCreate, SupplierUpdate
from ..services import tenant_service
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/suppliers", tags=["suppliers"])


@router.get("")
def list_suppliers(claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER", "MARKET_OPERATOR"})
    suppliers = db.execute(select(Supplier).order_by(Supplier.created_at.desc())).scalars().all()
    return [s.to_dict() for s in suppliers]


@router.post("", status_code=201)
def create_supplier(body: SupplierCreate, claims=Depends(get_current_access_claims),
                    db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    if body.contract_reference:
        existing = db.execute(select(Supplier).where(
            Supplier.contract_reference == body.contract_reference)).scalars().first()
        if existing:
            raise HTTPException(status_code=409, detail="Contract reference already exists")
    supplier = tenant_service.create_supplier(db, body.model_dump(), created_by=claims["sub"])
    write_audit(db, request_id=new_request_id(), operation="CREATE_SUPPLIER", result="SUCCESS",
                tenant_id=supplier.supplier_id, actor_id=claims["sub"])
    return {"supplier": supplier.to_dict(),
            "message": "Supplier created. Awaiting provisioning approval."}


@router.get("/{supplier_id}")
def get_supplier(supplier_id: str, claims=Depends(get_current_access_claims),
                 db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER", "MARKET_OPERATOR"})
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier.to_dict()


@router.put("/{supplier_id}")
def update_supplier(supplier_id: str, body: SupplierUpdate,
                    claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(supplier, field, value)
    db.commit()
    db.refresh(supplier)
    return supplier.to_dict()


@router.post("/{supplier_id}/provision")
def provision_supplier(supplier_id: str, claims=Depends(get_current_access_claims),
                       db: Session = Depends(get_db)):
    """Approve supplier and create ERPNext Supplier enum via the OP-03 gateway."""
    require_role(claims, {"ADMIN"})
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    if supplier.erpnext_supplier_id:
        raise HTTPException(status_code=409, detail="Supplier already provisioned")

    idempotency_key = f"prov-{supplier_id}"
    job = tenant_service.get_or_create_job(db, supplier_id, idempotency_key)

    from ..config import get_config
    config = get_config()
    erp_id = None
    if config.APP_ENV != "testing" and config.MARKET_ERP_KEY and config.MARKET_ERP_SECRET:
        from ..services.erpnext_client import ErpNextError, create_supplier
        try:
            erp_id = create_supplier(supplier.to_dict())
        except ErpNextError as error:
            tenant_service.fail_provisioning(db, job, "ERPNEXT_PROVISION_FAILED")
            raise HTTPException(status_code=502, detail=str(error))
    elif config.MARKET_ERP_KEY:
        # Development fallback only; production must provide the server-side secret.
        erp_id = f"SUP-{supplier_id[:8].upper()}"
    else:
        raise HTTPException(status_code=503, detail="ERPNext integration credentials are not configured")

    tenant_service.complete_provisioning(db, job, supplier, erp_id)
    write_audit(db, request_id=new_request_id(), operation="SUPPLIER_PROVISION", result="SUCCESS",
                tenant_id=supplier.supplier_id, actor_id=claims["sub"])
    return {"message": "Supplier provisioned", "erpnext_supplier_id": erp_id}
