"""Create and synchronize shipping payments with ERPNext."""
from datetime import datetime

import requests
from flask import current_app

from ..database import db
from ..models import Payment


class PaymentSyncError(Exception):
    """Raised when ERPNext rejects a payment entry."""


def sync_payment(payment: Payment) -> Payment:
    if payment.erpnext_payment_id:
        return payment

    url = current_app.config.get('ERPNEXT_URL', '').rstrip('/')
    api_key = current_app.config.get('ERPNEXT_API_KEY')
    api_secret = current_app.config.get('ERPNEXT_API_SECRET')
    if not url or not api_key or not api_secret:
        return _failed(payment, 'ERPNext credentials are not configured')

    customer = payment.customer
    customer_account = customer.erpnext_customer_id if customer else None
    if payment.payment_type == 'received' and not customer_account:
        return _failed(payment, 'Customer is not synchronized with ERPNext')

    config = current_app.config
    payload = {
        'payment_type': 'Receive' if payment.payment_type == 'received' else 'Pay',
        'party_type': 'Customer' if payment.payment_type == 'received' else 'Supplier',
        'party': customer_account if payment.payment_type == 'received' else payment.supplier_id,
        'company': config.get('ERPNEXT_COMPANY', 'Shipping Company'),
        'paid_amount': float(payment.amount),
        'received_amount': float(payment.amount),
        'source_exchange_rate': float(payment.exchange_rate or 1),
        'target_exchange_rate': 1,
        'posting_date': payment.payment_date.isoformat(),
        'reference_no': payment.reference_number or payment.payment_number,
        'mode_of_payment': payment.payment_method,
    }
    if payment.invoice and payment.invoice.erpnext_invoice_id:
        payload['references'] = [{
            'reference_doctype': 'Sales Invoice' if payment.invoice.invoice_type == 'sales' else 'Purchase Invoice',
            'reference_name': payment.invoice.erpnext_invoice_id,
            'allocated_amount': float(payment.amount),
        }]

    try:
        response = requests.post(
            f'{url}/api/resource/Payment Entry',
            headers={
                'Authorization': f'token {api_key}:{api_secret}',
                'Content-Type': 'application/json',
            },
            json=payload,
            timeout=15,
        )
    except requests.RequestException as error:
        return _failed(payment, 'ERPNext connection failed', error)

    if response.status_code not in (200, 201):
        return _failed(payment, f'ERPNext returned HTTP {response.status_code}')

    erpnext_payment_id = (response.json().get('data') or {}).get('name')
    if not erpnext_payment_id:
        return _failed(payment, 'ERPNext returned no payment identifier')

    payment.erpnext_payment_id = erpnext_payment_id
    payment.erpnext_sync_status = 'SYNCED'
    payment.erpnext_sync_error = None
    payment.erpnext_synced_at = datetime.utcnow()
    payment.status = 'completed'
    _apply_invoice_payment(payment)
    db.session.commit()
    db.session.refresh(payment)
    return payment


def _apply_invoice_payment(payment: Payment):
    if not payment.invoice:
        return
    invoice = payment.invoice
    invoice.paid_amount = (invoice.paid_amount or 0) + payment.amount
    if invoice.paid_amount >= invoice.total_amount:
        invoice.status = 'paid'


def _failed(payment: Payment, message: str, cause=None):
    payment.erpnext_sync_status = 'FAILED'
    payment.erpnext_sync_error = message
    db.session.commit()
    if cause:
        raise PaymentSyncError(message) from cause
    raise PaymentSyncError(message)
