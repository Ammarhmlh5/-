"""
Catalog - منطق الكتالوج والمخزون والتسعير
"""
from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import Product, ProductChangeLog, Supplier
from .currency import compute_unit_rate_usd, get_fx_rate


class CatalogError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.message = message
        self.code = code


def _log_change(db: Session, product: Product, action: str, actor_id, old=None, new=None):
    db.add(ProductChangeLog(
        product_id=product.product_id,
        supplier_id=product.supplier_id,
        action=action,
        actor_id=actor_id,
        old_values=old or {},
        new_values=new or {},
    ))


def ensure_supplier_active(db: Session, supplier_id: str) -> Supplier:
    supplier = db.execute(select(Supplier).where(Supplier.supplier_id == supplier_id)).scalars().first()
    if not supplier:
        raise CatalogError("Supplier not found", "SUPPLIER_NOT_FOUND")
    if supplier.status != "ACTIVE":
        raise CatalogError("Supplier is not active", "SUPPLIER_INACTIVE")
    return supplier


def get_product(db: Session, product_id: str) -> Product:
    product = db.execute(select(Product).where(Product.product_id == product_id)).scalars().first()
    if not product:
        raise CatalogError("Product not found", "PRODUCT_NOT_FOUND")
    return product


def render_pricing(db: Session, product: Product) -> dict:
    """Compute the final USD unit rate at render-time (never cached stale)."""
    fx = get_fx_rate(db)
    unit_usd = compute_unit_rate_usd(product.factory_price_cny, product.handling_fee_usd, fx)
    return {
        "unit_rate_usd": float(unit_usd),
        "fx_cny_to_usd": float(fx),
    }


def to_catalog_dict(db: Session, product: Product) -> dict:
    data = product.to_dict()
    if product.is_published and product.status == "ACTIVE":
        data["pricing"] = render_pricing(db, product)
    else:
        data["pricing"] = None
    return data


def update_stock(db: Session, product: Product, new_stock: int, actor_id) -> Product:
    old = product.available_stock
    product.available_stock = new_stock
    product.updated_at = datetime.utcnow()
    _log_change(db, product, "UPDATE_STOCK", actor_id, old={"available_stock": old},
                new={"available_stock": new_stock})
    return product


def update_price(db: Session, product: Product, factory_price_cny=None, handling_fee_usd=None,
                 actor_id=None) -> Product:
    old = {"factory_price_cny": float(product.factory_price_cny) if product.factory_price_cny else 0,
           "handling_fee_usd": float(product.handling_fee_usd) if product.handling_fee_usd else 0}
    if factory_price_cny is not None:
        product.factory_price_cny = Decimal(str(factory_price_cny))
    if handling_fee_usd is not None:
        product.handling_fee_usd = Decimal(str(handling_fee_usd))
    product.updated_at = datetime.utcnow()
    new = {"factory_price_cny": float(product.factory_price_cny),
           "handling_fee_usd": float(product.handling_fee_usd)}
    _log_change(db, product, "UPDATE_PRICE", actor_id, old=old, new=new)
    return product


def publish(db: Session, product: Product, is_published: bool, actor_id) -> Product:
    old = product.is_published
    product.is_published = is_published
    product.status = "ACTIVE" if is_published else product.status
    product.updated_at = datetime.utcnow()
    _log_change(db, product, "PUBLISH", actor_id, old={"is_published": old},
                new={"is_published": is_published})
    return product
