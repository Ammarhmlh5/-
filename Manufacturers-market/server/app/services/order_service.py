"""
Order - دورة حياة الطلبات وفحص المخزون والتأكيد
"""
from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import MarketOrder, OrderItem, Product
from .catalog_service import CatalogError, ensure_supplier_active, get_product
from .currency import compute_unit_rate_usd, get_fx_rate


class OrderError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.message = message
        self.code = code


def next_order_reference(db: Session) -> str:
    count = db.execute(select(MarketOrder)).scalars().all().__len__()
    from datetime import date
    return f"MKT-{date.today().year}-{count + 1:04d}"


def create_draft_order(db: Session, customer_user_id: str, items: list[dict]) -> MarketOrder:
    order = MarketOrder(
        order_reference=next_order_reference(db),
        customer_user_id=customer_user_id,
        status="DRAFT",
        currency="USD",
    )
    db.add(order)
    db.flush()

    total = Decimal("0")
    fx = get_fx_rate(db)
    for item in items:
        product = get_product(db, item["product_id"])
        ensure_supplier_active(db, product.supplier_id)
        if product.status != "ACTIVE" or not product.is_published:
            raise OrderError(f"Product is not available: {product.sku}", "PRODUCT_UNAVAILABLE")
        qty = int(item["qty"])
        if product.available_stock < qty:
            raise OrderError(f"Insufficient stock for SKU {product.sku}", "INSUFFICIENT_STOCK")
        unit_usd = compute_unit_rate_usd(product.factory_price_cny, product.handling_fee_usd, fx)
        total += unit_usd * qty
        db.add(OrderItem(
            order_id=order.order_id,
            product_id=product.product_id,
            sku=product.sku,
            qty=qty,
            unit_rate_cny=product.factory_price_cny,
            handling_fee_usd=product.handling_fee_usd,
            fx_rate_used=fx,
            unit_rate_usd=unit_usd,
        ))
    order.total_usd = total.quantize(Decimal("0.01"))
    order.fx_rate_used = fx
    db.commit()
    db.refresh(order)
    return order


def confirm_order(db: Session, order: MarketOrder, erp_customer_code: str) -> MarketOrder:
    if order.status != "DRAFT":
        raise OrderError("Only draft orders can be confirmed", "INVALID_STATUS")
    # Re-validate stock and availability at confirmation time
    for item in order.items:
        product = get_product(db, item.product_id)
        ensure_supplier_active(db, product.supplier_id)
        if product.status != "ACTIVE" or not product.is_published:
            raise OrderError(f"Product is not available: {product.sku}", "PRODUCT_UNAVAILABLE")
        if product.available_stock < item.qty:
            raise OrderError(f"Insufficient stock for SKU {product.sku}", "INSUFFICIENT_STOCK")
    from ..config import get_config
    if not erp_customer_code and get_config().APP_ENV != "testing":
        raise OrderError("ERPNext customer code is required", "ERP_CUSTOMER_REQUIRED")

    if get_config().APP_ENV != "testing":
        from .erpnext_client import ErpNextError, queue_sales_order
        try:
            order.erp_customer_code = erp_customer_code
            queue_sales_order(order.to_dict())
        except ErpNextError as error:
            raise OrderError(str(error), "ERPNEXT_ORDER_FAILED")

    order.status = "CONFIRMED"
    order.erp_customer_code = erp_customer_code
    order.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(order)
    return order


def mark_paid(db: Session, order: MarketOrder) -> MarketOrder:
    if order.status != "CONFIRMED":
        raise OrderError("Only confirmed orders can be paid", "INVALID_STATUS")
    # Deduct reserved stock on payment
    for item in order.items:
        product = get_product(db, item.product_id)
        product.available_stock -= item.qty
        product.updated_at = datetime.utcnow()
    order.status = "PAID"
    order.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(order)
    return order


def cancel_order(db: Session, order: MarketOrder) -> MarketOrder:
    if order.status in ("PAID",):
        raise OrderError("Paid orders cannot be cancelled", "INVALID_STATUS")
    order.status = "CANCELLED"
    order.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(order)
    return order
