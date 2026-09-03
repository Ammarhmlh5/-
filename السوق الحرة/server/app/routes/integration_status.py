"""
IntegrationStatus - حالة الربط دون كشف أي سر
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_access_claims, require_role
from ..models import MarketErpCredential, MarketProvisioningJob
from ..services.tenant_service import supplier_status

router = APIRouter(prefix="/integration", tags=["integration"])


@router.get("/suppliers/{supplier_id}")
def integration_status(supplier_id: str, claims=Depends(get_current_access_claims),
                       db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    return supplier_status(db, supplier_id)


@router.post("/jobs/{job_id}/retry")
def retry_job(job_id: str, claims=Depends(get_current_access_claims),
              db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN"})
    job = db.get(MarketProvisioningJob, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    job.status = "PENDING"
    job.last_error_code = None
    db.commit()
    return {"message": "Job queued for retry", "job_id": job_id, "status": "PENDING"}
