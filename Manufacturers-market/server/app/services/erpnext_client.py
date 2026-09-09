"""OP-03 integration client for asynchronous ERPNext financial commands."""
import httpx

from ..config import get_config


class ErpNextError(Exception):
    """Raised when ERPNext rejects or cannot process an integration request."""


def _enqueue(command_type: str, source_type: str, source_id: str, payload: dict) -> dict:
    config = get_config()
    if not config.OP03_GATEWAY_URL or not config.MARKET_ERP_KEY:
        raise ErpNextError("OP-03 integration credentials are not configured")
    try:
        response = httpx.post(
            f"{config.OP03_GATEWAY_URL.rstrip('/')}/api/erpnext/integration/financial-command",
            json={
                "command_type": command_type,
                "source_type": source_type,
                "source_id": source_id,
                "payload": {**payload, "callback_url": config.OP03_CALLBACK_URL},
            },
            headers={"X-Integration-Key": config.MARKET_ERP_KEY},
            timeout=15.0,
        )
    except httpx.HTTPError as exc:
        raise ErpNextError("ERPNext connection failed") from exc

    if response.status_code != 202:
        raise ErpNextError(f"OP-03 rejected command ({response.status_code})")
    return response.json()


def queue_supplier(supplier: dict) -> dict:
    return _enqueue("CREATE_SUPPLIER", "SUPPLIER", supplier["supplier_id"], {
        "doctype": "Supplier",
        "supplier_name": supplier["legal_name"],
        "supplier_type": "Company",
        "supplier_group": "All Supplier Groups",
        "country": "China",
        "supplier_details": supplier.get("company_name_en") or supplier.get("company_name_zh"),
    })


def queue_sales_order(order: dict) -> dict:
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

    return _enqueue("CREATE_SALES_ORDER", "ORDER", order["order_id"], {
        "doctype": "Sales Order",
        **payload,
    })