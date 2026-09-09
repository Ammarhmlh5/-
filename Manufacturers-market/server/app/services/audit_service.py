"""
Audit - تسجيل أحداث التكامل للتدقيق دون تسجيل الأسرار
"""
from sqlalchemy.orm import Session

from ..models import MarketAuditLog


def write_audit(db: Session, *, request_id: str, operation: str, result: str,
                tenant_id: str | None = None, actor_id: str | None = None,
                actor_key_id: str | None = None, channel: str | None = "MARKET",
                credential_id: str | None = None, reason_code: str | None = None,
                source_ip: str | None = None):
    entry = MarketAuditLog(
        request_id=request_id,
        tenant_id=tenant_id,
        actor_id=actor_id,
        actor_key_id=actor_key_id,
        channel=channel,
        credential_id=credential_id,
        operation=operation,
        result=result,
        reason_code=reason_code,
        source_ip=source_ip,
    )
    db.add(entry)
    db.commit()
    return entry
