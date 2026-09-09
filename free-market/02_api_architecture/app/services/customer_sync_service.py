"""Automatic customer synchronization between shipping DB and ERPNext."""
from datetime import datetime

import requests
from flask import current_app

from ..database import db
from ..models import Customer


class CustomerSyncError(Exception):
    """Raised when ERPNext cannot create or update a customer."""


def _erpnext_payload(customer: Customer) -> dict:
    return {
        'customer_name': customer.name,
        'customer_type': 'Company',
        'customer_group': 'Commercial',
        'territory': customer.country or 'All Territories',
        'email_id': customer.email,
        'phone': customer.phone,
        'address_html': customer.address,
        'tax_id': customer.tax_number,
    }


def sync_customer(customer: Customer) -> Customer:
    """Create or update the matching ERPNext Customer and persist sync state."""
    url = current_app.config.get('ERPNEXT_URL', '').rstrip('/')
    api_key = current_app.config.get('ERPNEXT_API_KEY')
    api_secret = current_app.config.get('ERPNEXT_API_SECRET')
    if not url or not api_key or not api_secret:
        customer.erpnext_sync_status = 'FAILED'
        customer.erpnext_sync_error = 'ERPNext credentials are not configured'
        db.session.commit()
        raise CustomerSyncError(customer.erpnext_sync_error)

    endpoint = f"Customer/{customer.erpnext_customer_id}" if customer.erpnext_customer_id else 'Customer'
    method = requests.put if customer.erpnext_customer_id else requests.post
    try:
        response = method(
            f'{url}/api/resource/{endpoint}',
            headers={
                'Authorization': f'token {api_key}:{api_secret}',
                'Content-Type': 'application/json',
            },
            json=_erpnext_payload(customer),
            timeout=15,
        )
    except requests.RequestException as error:
        customer.erpnext_sync_status = 'FAILED'
        customer.erpnext_sync_error = 'ERPNext connection failed'
        db.session.commit()
        raise CustomerSyncError(customer.erpnext_sync_error) from error

    if response.status_code not in (200, 201):
        customer.erpnext_sync_status = 'FAILED'
        customer.erpnext_sync_error = f'ERPNext returned HTTP {response.status_code}'
        db.session.commit()
        raise CustomerSyncError(customer.erpnext_sync_error)

    erp_customer_id = (response.json().get('data') or {}).get('name')
    if not erp_customer_id:
        customer.erpnext_sync_status = 'FAILED'
        customer.erpnext_sync_error = 'ERPNext returned no customer identifier'
        db.session.commit()
        raise CustomerSyncError(customer.erpnext_sync_error)

    customer.erpnext_customer_id = erp_customer_id
    customer.erpnext_sync_status = 'SYNCED'
    customer.erpnext_sync_error = None
    customer.erpnext_synced_at = datetime.utcnow()
    db.session.commit()
    db.session.refresh(customer)
    return customer
