"""Server-side ERPNext client used until the OP-03 gateway is available."""
import httpx

from ..config import get_config


class ErpNextError(Exception):
    """Raised when ERPNext rejects or cannot process an integration request."""


def create_supplier(supplier: dict) -> str:
    config = get_config()
    if not config.MARKET_ERP_KEY or not config.MARKET_ERP_SECRET:
        raise ErpNextError("ERPNext integration credentials are not configured")

    payload = {
        "supplier_name": supplier["legal_name"],
        "supplier_type": "Company",
        "supplier_group": "All Supplier Groups",
        "country": "China",
        "supplier_details": supplier.get("company_name_en") or supplier.get("company_name_zh"),
    }
    headers = {
        "Authorization": f"token {config.MARKET_ERP_KEY}:{config.MARKET_ERP_SECRET}",
        "Content-Type": "application/json",
    }
    try:
        response = httpx.post(
            f"{config.ERPNEXT_URL.rstrip('/')}/api/resource/Supplier",
            json=payload,
            headers=headers,
            timeout=15.0,
        )
    except httpx.HTTPError as exc:
        raise ErpNextError("ERPNext connection failed") from exc

    if response.status_code not in (200, 201):
        raise ErpNextError(f"ERPNext rejected supplier ({response.status_code})")
    data = response.json().get("data") or {}
    supplier_id = data.get("name")
    if not supplier_id:
        raise ErpNextError("ERPNext returned no supplier identifier")
    return supplier_id


def create_sales_order(order: dict) -> str:
    config = get_config()
    if not config.MARKET_ERP_KEY or not config.MARKET_ERP_SECRET:
        raise ErpNextError("ERPNext integration credentials are not configured")

    payload = {
        "customer": order.get("erp_customer_code"),
        "transaction_date": order["created_at"][:10],
        "currency": order.get("currency", "USD"),
        "po_no": order["order_reference"],
        "items": [
            {
                "item_code": item["sku"],
                "qty": item["qty"],
                "rate": item["unit_rate_usd"],
                "warehouse": item.get("warehouse"),
            }
            for item in order.get("items", [])
        ],
    }
    if not payload["customer"]:
        raise ErpNextError("ERPNext customer code is required")

    headers = {
        "Authorization": f"token {config.MARKET_ERP_KEY}:{config.MARKET_ERP_SECRET}",
        "Content-Type": "application/json",
    }
    try:
        response = httpx.post(
            f"{config.ERPNEXT_URL.rstrip('/')}/api/resource/Sales Order",
            json=payload,
            headers=headers,
            timeout=15.0,
        )
    except httpx.HTTPError as exc:
        raise ErpNextError("ERPNext connection failed") from exc

    if response.status_code not in (200, 201):
        raise ErpNextError(f"ERPNext rejected sales order ({response.status_code})")
    order_id = (response.json().get("data") or {}).get("name")
    if not order_id:
        raise ErpNextError("ERPNext returned no sales order identifier")
    return order_id