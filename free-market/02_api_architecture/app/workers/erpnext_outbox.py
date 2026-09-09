"""Deliver financial outbox commands to ERPNext outside request handlers."""
from datetime import datetime, timedelta

import requests
from flask import current_app

from ..database import db
from ..models import Customer, IntegrationAudit, IntegrationOutbox, Invoice, Payment

MAX_ATTEMPTS = 5


def drain_outbox(limit=20):
    """Process ready commands and return a small execution summary."""
    now = datetime.utcnow()
    commands = (
        IntegrationOutbox.query
        .filter(IntegrationOutbox.status.in_(('PENDING', 'FAILED')))
        .filter((IntegrationOutbox.next_attempt_at.is_(None)) | (IntegrationOutbox.next_attempt_at <= now))
        .order_by(IntegrationOutbox.created_at.asc())
        .limit(limit)
        .all()
    )

    results = {'processed': 0, 'done': 0, 'failed': 0, 'dead': 0}
    for command in commands:
        result = process_outbox_item(command)
        results['processed'] += 1
        results[result] += 1
    return results


def process_outbox_item(command):
    """Send one command and return ``done``, ``failed`` or ``dead``."""
    if command.status == 'DONE':
        return 'done'

    command.status = 'PROCESSING'
    command.attempt_count += 1
    db.session.commit()

    try:
        response = _send_to_erpnext(command)
    except requests.RequestException as error:
        return _record_failure(command, str(error), retryable=True)

    if response.status_code in (200, 201):
        data = response.json().get('data') or {}
        command.status = 'DONE'
        command.erp_document_name = data.get('name')
        command.last_error = None
        command.next_attempt_at = None
        _record_audit(command, 'SENT', response.status_code, response.text[:1000])
        _apply_success_reference(command)
        _notify_source_callback(command)
        db.session.commit()
        return 'done'

    retryable = response.status_code >= 500
    return _record_failure(
        command,
        f'ERPNext returned HTTP {response.status_code}: {response.text[:500]}',
        retryable=retryable,
        http_status=response.status_code,
    )


def _send_to_erpnext(command):
    payload = {
        key: value for key, value in (command.payload or {}).items()
        if key not in {'callback_url', 'payment_id', 'invoice_id'}
    }
    url = current_app.config.get('ERPNEXT_URL', '').rstrip('/')
    api_key = current_app.config.get('ERPNEXT_API_KEY')
    api_secret = current_app.config.get('ERPNEXT_API_SECRET')
    if not url or not api_key or not api_secret:
        raise requests.RequestException('ERPNext credentials are not configured')

    method = requests.put if command.command_type == 'UPDATE_CUSTOMER' else requests.post
    endpoint = payload['doctype']
    if command.command_type == 'UPDATE_CUSTOMER' and payload.get('erpnext_document_name'):
        endpoint = f'{endpoint}/{payload["erpnext_document_name"]}'

    response = method(
        f'{url}/api/resource/{endpoint}',
        headers={
            'Authorization': f'token {api_key}:{api_secret}',
            'Content-Type': 'application/json',
            'X-Idempotency-Key': command.idempotency_key,
        },
        json=payload,
        timeout=15,
    )
    return response


def _record_failure(command, message, retryable, http_status=None):
    command.last_error = message
    if retryable and command.attempt_count < MAX_ATTEMPTS:
        command.status = 'FAILED'
        command.next_attempt_at = datetime.utcnow() + timedelta(seconds=2 ** command.attempt_count)
        result = 'failed'
        action = 'RETRY'
    else:
        command.status = 'DEAD'
        command.next_attempt_at = None
        result = 'dead'
        action = 'DEADLETTER'

    _record_audit(command, action, http_status, message)
    db.session.commit()
    return result


def _record_audit(command, action, http_status=None, summary=None):
    db.session.add(IntegrationAudit(
        outbox_id=command.id,
        action=action,
        attempt=command.attempt_count,
        http_status=http_status,
        response_summary=summary,
        actor_reference=command.source_id,
    ))


def _apply_success_reference(command):
    document_name = command.erp_document_name
    if not document_name:
        return

    source = db.session.get(
        {'PAYMENT': Payment, 'CUSTOMER': Customer, 'INVOICE': Invoice}.get(command.source_type),
        command.source_id,
    ) if command.source_type in {'PAYMENT', 'CUSTOMER', 'INVOICE'} else None
    if not source:
        return

    if command.source_type == 'PAYMENT':
        source.erpnext_payment_id = document_name
        source.erpnext_sync_status = 'SYNCED'
        source.status = 'completed'
    elif command.source_type == 'CUSTOMER':
        source.erpnext_customer_id = document_name
        source.erpnext_sync_status = 'SYNCED'
        source.erpnext_sync_error = None
        source.erpnext_synced_at = datetime.utcnow()
    elif command.source_type == 'INVOICE':
        source.erpnext_invoice_id = document_name
        source.status = 'submitted'


def _notify_source_callback(command):
    callback_url = (command.payload or {}).get('callback_url')
    if not callback_url or command.source_type not in {'SUPPLIER', 'ORDER'}:
        return
    integration_key = current_app.config.get('MARKET_INTEGRATION_KEY', '')
    if not integration_key:
        return
    try:
        requests.post(
            callback_url,
            headers={'X-Integration-Key': integration_key},
            json={
                'source_type': command.source_type,
                'source_id': command.source_id,
                'erp_document_name': command.erp_document_name,
                'outbox_id': command.id,
                'status': command.status,
            },
            timeout=15,
        )
    except requests.RequestException:
        _record_audit(command, 'CALLBACK_FAILED', None, 'Source callback failed')