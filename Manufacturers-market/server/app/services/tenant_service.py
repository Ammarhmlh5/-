"""
Tenant - اعتماد المورد وربطه بـ ERPNext عبر قناة OP-03
"""
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_config
from ..models import MarketErpCredential, MarketProvisioningJob, Supplier
from ..security import fingerprint, generate_api_key

config = get_config()


class ProvisioningError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.message = message
        self.code = code


def create_supplier(db: Session, data: dict, created_by: str) -> Supplier:
    supplier = Supplier(
        legal_name=data["legal_name"],
        company_name_en=data.get("company_name_en"),
        company_name_zh=data.get("company_name_zh"),
        contact_phone=data.get("contact_phone"),
        contract_reference=data.get("contract_reference"),
        settlement_currency=data.get("settlement_currency", "CNY"),
        status="PENDING",
        created_by=created_by,
    )
    db.add(supplier)
    db.flush()

    job = MarketProvisioningJob(
        supplier_id=supplier.supplier_id,
        operation="SUPPLIER_PROVISION",
        idempotency_key=f"prov-{supplier.supplier_id}",
        status="PENDING",
    )
    db.add(job)
    db.commit()
    db.refresh(supplier)
    return supplier


def get_or_create_job(db: Session, supplier_id: str, idempotency_key: str,
                      operation: str = "SUPPLIER_PROVISION") -> MarketProvisioningJob:
    job = db.execute(
        select(MarketProvisioningJob).where(MarketProvisioningJob.idempotency_key == idempotency_key)
    ).scalars().first()
    if job:
        return job
    job = MarketProvisioningJob(
        supplier_id=supplier_id,
        operation=operation,
        idempotency_key=idempotency_key,
        status="PENDING",
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


def complete_provisioning(db: Session, job: MarketProvisioningJob, supplier: Supplier,
                          erpnext_supplier_id: str) -> MarketErpCredential:
    """Mark the provisioning job SUCCESS, link the ERPNext id and create the credential ref."""
    job.status = "SUCCESS"
    job.completed_at = datetime.utcnow()
    supplier.erpnext_supplier_id = erpnext_supplier_id
    supplier.status = "ACTIVE"

    raw, _, key_hash = generate_api_key()
    credential = MarketErpCredential(
        supplier_id=supplier.supplier_id,
        channel="MARKET",
        erpnext_entity_type="Supplier",
        erpnext_entity_id=erpnext_supplier_id,
        secret_ref=f"secret-manager:/market/erp/{supplier.supplier_id}",
        key_fingerprint=fingerprint(raw),
        status="READY",
        allowed_operations=["create_sales_order", "create_supplier"],
    )
    db.add(credential)
    db.commit()
    db.refresh(supplier)
    return credential


def fail_provisioning(db: Session, job: MarketProvisioningJob, error_code: str):
    job.status = "FAILED"
    job.attempt_count += 1
    job.last_error_code = error_code
    job.next_attempt_at = datetime.utcnow()
    db.commit()


def supplier_status(db: Session, supplier_id: str) -> dict:
    job = db.execute(
        select(MarketProvisioningJob)
        .where(MarketProvisioningJob.supplier_id == supplier_id)
        .order_by(MarketProvisioningJob.created_at.desc())
        .limit(1)
    ).scalars().first()
    cred = db.execute(
        select(MarketErpCredential).where(MarketErpCredential.supplier_id == supplier_id)
    ).scalars().first()
    return {
        "supplier_id": supplier_id,
        "status": job.status if job else "PENDING",
        "attempt_count": job.attempt_count if job else 0,
        "last_error_code": job.last_error_code if job else None,
        "erpnext_supplier_id": cred.erpnext_entity_id if cred else None,
        "credential_status": cred.status if cred else None,
    }
