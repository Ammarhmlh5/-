"""Signed inbound webhook endpoints from ERPNext."""
import hashlib
import hmac
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_config
from ..database import get_db
from ..models import MarketAuditLog, MarketOrder, Supplier

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


@router.post("/op03", status_code=202)
async def op03_callback(
    request: Request,
    x_integration_key: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    """Receive the final ERPNext document reference from the OP-03 worker."""
    config = get_config()
    if not config.MARKET_ERP_KEY or not x_integration_key or not hmac.compare_digest(
        config.MARKET_ERP_KEY, x_integration_key
    ):
        raise HTTPException(status_code=401, detail="Invalid integration credentials")

    data = await request.json()
    source_type = data.get("source_type")
    source_id = data.get("source_id")
    document_name = data.get("erp_document_name")
    if not source_type or not source_id or not document_name:
        raise HTTPException(status_code=400, detail="Invalid OP-03 callback")

    if source_type == "SUPPLIER":
        supplier = db.get(Supplier, source_id)
        if supplier:
            supplier.erpnext_supplier_id = document_name
            supplier.status = "ACTIVE"
    elif source_type == "ORDER":
        order = db.get(MarketOrder, source_id)
        if order:
            order.erpnext_sales_order_id = document_name

    db.add(MarketAuditLog(
        request_id=uuid.uuid4(),
        channel="MARKET",
        operation=f"OP03_CALLBACK:{source_type}",
        result="SUCCESS",
        tenant_id=source_id if source_type == "SUPPLIER" else None,
    ))
    db.commit()
    return {"accepted": True, "source_type": source_type, "source_id": source_id}


@router.post("/erpnext", status_code=202)
async def erpnext_webhook(
    request: Request,
    x_frappe_signature: str | None = Header(default=None),
    x_frappe_webhook_event: str | None = Header(default=None),
    x_request_id: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    payload = await request.body()
    secret = get_config().ERPNEXT_WEBHOOK_SECRET
    if not secret or not x_frappe_signature:
        raise HTTPException(status_code=401, detail="Invalid webhook signature")
    expected = hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, x_frappe_signature):
        raise HTTPException(status_code=401, detail="Invalid webhook signature")
    if not x_frappe_webhook_event or not x_request_id:
        raise HTTPException(status_code=400, detail="event and X-Request-ID are required")

    try:
        request_uuid = uuid.UUID(x_request_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="X-Request-ID must be a UUID") from exc

    existing = db.execute(
        select(MarketAuditLog).where(MarketAuditLog.request_id == request_uuid)
    ).scalars().first()
    if existing:
        return {"accepted": True, "duplicate": True, "request_id": x_request_id}

    db.add(MarketAuditLog(
        request_id=request_uuid,
        channel="MARKET",
        operation=f"ERPNext_WEBHOOK:{x_frappe_webhook_event}",
        result="ACCEPTED",
    ))
    db.commit()
    return {
        "accepted": True,
        "event": x_frappe_webhook_event,
        "request_id": x_request_id,
    }