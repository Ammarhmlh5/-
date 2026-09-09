"""Create durable financial commands without calling ERPNext from request handlers."""
import hashlib
import json

from ..database import db
from ..models import IntegrationAudit, IntegrationOutbox


def enqueue_financial_command(command_type, source_type, source_id, payload):
    """Persist one idempotent financial command and return its outbox record."""
    canonical_payload = json.dumps(payload, sort_keys=True, separators=(',', ':'), default=str)
    idempotency_key = hashlib.sha256(
        f'{command_type}|{source_type}|{source_id}|{canonical_payload}'.encode('utf-8')
    ).hexdigest()

    existing = IntegrationOutbox.query.filter_by(idempotency_key=idempotency_key).first()
    if existing:
        return existing

    outbox = IntegrationOutbox(
        idempotency_key=idempotency_key,
        command_type=command_type,
        source_type=source_type,
        source_id=str(source_id),
        payload=payload,
    )
    db.session.add(outbox)
    db.session.flush()
    db.session.add(IntegrationAudit(
        outbox_id=outbox.id,
        action='ENQUEUED',
        attempt=0,
        actor_reference=str(source_id),
    ))
    return outbox