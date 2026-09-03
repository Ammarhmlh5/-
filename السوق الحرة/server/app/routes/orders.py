"""
Orders - طلبات العملاء: إنشاء واستدعاء التأكيد والدفع
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_access_claims
from ..models import MarketOrder, Product
from ..schemas import OrderCreate
from ..services import order_service
from ..services.catalog_service import CatalogError
from ..services.order_service import OrderError

router = APIRouter(prefix="/orders", tags=["orders"])


def _get_order(db: Session, reference: str) -> MarketOrder:
    order = db.execute(select(MarketOrder).where(
        MarketOrder.order_reference == reference)).scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@router.post("", status_code=201)
def create_order(body: OrderCreate, claims=Depends(get_current_access_claims),
                 db: Session = Depends(get_db)):
    customer_user_id = claims["sub"]
    # Resolve each item's product id by SKU
    items = []
    for input_item in body.items:
        product = db.execute(select(Product).where(Product.sku == input_item.sku)).scalars().first()
        if not product:
            raise HTTPException(status_code=404, detail=f"SKU not found: {input_item.sku}")
        items.append({"product_id": product.product_id, "qty": input_item.qty})
    try:
        order = order_service.create_draft_order(db, customer_user_id, items)
    except (CatalogError, OrderError) as exc:
        raise HTTPException(status_code=409, detail=exc.message)
    return order.to_dict()


@router.get("/my")
def my_orders(claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    orders = db.execute(select(MarketOrder).where(
        MarketOrder.customer_user_id == claims["sub"]).order_by(
        MarketOrder.created_at.desc())).scalars().all()
    return [o.to_dict() for o in orders]


@router.get("/{reference}")
def get_order(reference: str, claims=Depends(get_current_access_claims),
              db: Session = Depends(get_db)):
    order = _get_order(db, reference)
    if order.customer_user_id != claims["sub"]:
        raise HTTPException(status_code=403, detail="Access denied to this order")
    return order.to_dict()


@router.post("/{reference}/confirm")
def confirm_order(reference: str, claims=Depends(get_current_access_claims),
                  db: Session = Depends(get_db)):
    order = _get_order(db, reference)
    if order.customer_user_id != claims["sub"]:
        raise HTTPException(status_code=403, detail="Access denied to this order")
    erp_customer_code = claims.get("erp_customer_code")
    try:
        order = order_service.confirm_order(db, order, erp_customer_code=erp_customer_code)
    except OrderError as exc:
        raise HTTPException(status_code=409, detail=exc.message)
    return order.to_dict()


@router.post("/{reference}/pay")
def pay_order(reference: str, claims=Depends(get_current_access_claims),
              db: Session = Depends(get_db)):
    order = _get_order(db, reference)
    if order.customer_user_id != claims["sub"]:
        raise HTTPException(status_code=403, detail="Access denied to this order")
    try:
        order = order_service.mark_paid(db, order)
    except OrderError as exc:
        raise HTTPException(status_code=409, detail=exc.message)
    # In production, emitting to OP-03 (Sales Order) occurs here via integration dispatcher.
    return order.to_dict()


@router.post("/{reference}/cancel")
def cancel_order(reference: str, claims=Depends(get_current_access_claims),
                 db: Session = Depends(get_db)):
    order = _get_order(db, reference)
    if order.customer_user_id != claims["sub"]:
        raise HTTPException(status_code=403, detail="Access denied to this order")
    try:
        order = order_service.cancel_order(db, order)
    except OrderError as exc:
        raise HTTPException(status_code=409, detail=exc.message)
    return order.to_dict()
