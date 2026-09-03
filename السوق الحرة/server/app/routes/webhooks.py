"""Signed inbound webhook endpoints from ERPNext."""
import hashlib
import hmac
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_config
from ..database import get_db
from ..models import MarketAuditLog

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


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