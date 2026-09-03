"""
Catalog - الكتالوج: دخول المورد، المراجعة، النشر، والتصفح للعميل
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_api_key_record, get_current_access_claims, require_role
from ..models import MarketApiKey, Product, Supplier
from ..schemas import ProductCreate, ProductPublish, ProductUpdate, StockUpdate
from ..services import catalog_service
from ..services.catalog_service import CatalogError
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("")
def browse_catalog(supplier_id: str | None = None,
                   claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    """Merchant-facing browse: published, active products only with computed USD."""
    query = select(Product).where(Product.is_published.is_(True), Product.status == "ACTIVE")
    if supplier_id:
        query = query.where(Product.supplier_id == supplier_id)
    products = db.execute(query.order_by(Product.created_at.desc())).scalars().all()
    return [catalog_service.to_catalog_dict(db, p) for p in products]


@router.get("/all")
def list_all_products(claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    """Internal listing (market staff / suppliers)."""
    products = db.execute(select(Product).order_by(Product.created_at.desc())).scalars().all()
    return [catalog_service.to_catalog_dict(db, p) for p in products]


@router.get("/{product_id}")
def product_detail(product_id: str, db: Session = Depends(get_db),
                   claims=Depends(get_current_access_claims)):
    try:
        product = catalog_service.get_product(db, product_id)
    except CatalogError as exc:
        raise HTTPException(status_code=404, detail=exc.message)
    if not (product.is_published and product.status == "ACTIVE"):
        raise HTTPException(status_code=404, detail="Product not available")
    return catalog_service.to_catalog_dict(db, product)


@router.post("", status_code=201)
def create_product(body: ProductCreate, api_key: MarketApiKey = Depends(get_api_key_record),
                   db: Session = Depends(get_db)):
    """Supplier (or market staff) creates a SKU entry. Stored as DRAFT until reviewed."""
    supplier_id = body.supplier_id
    if api_key.owner_type in ("TENANT", "EMPLOYEE"):
        supplier_id = api_key.supplier_id  # ownership derived from the key, never from body
    if api_key.owner_type in ("TENANT", "EMPLOYEE", "SYSTEM") and api_key.supplier_id != body.supplier_id:
        raise HTTPException(status_code=403, detail="Cannot create product for another supplier")

    if db.execute(select(Product).where(Product.sku == body.sku)).scalars().first():
        raise HTTPException(status_code=409, detail="SKU already exists")

    product = Product(
        supplier_id=supplier_id,
        sku=body.sku,
        title_ar=body.title_ar,
        title_en=body.title_en,
        description=body.description,
        factory_price_cny=body.factory_price_cny,
        handling_fee_usd=body.handling_fee_usd,
        volume_cbm=body.volume_cbm,
        weight_kg=body.weight_kg,
        available_stock=body.available_stock,
        status="DRAFT",
        is_published=False,
        created_by=api_key.owner_id,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    write_audit(db, request_id=new_request_id(), operation="CREATE_PRODUCT", result="SUCCESS",
                tenant_id=product.supplier_id, actor_id=api_key.owner_id)
    return product.to_dict()


@router.put("/{product_id}")
def update_product(product_id: str, body: ProductUpdate,
                   api_key=Depends(get_api_key_record), db: Session = Depends(get_db)):
    try:
        product = catalog_service.get_product(db, product_id)
    except CatalogError as exc:
        raise HTTPException(status_code=404, detail=exc.message)
    # vendor may only update own products
    if api_key.owner_type in ("TENANT", "EMPLOYEE") and api_key.supplier_id != product.supplier_id:
        raise HTTPException(status_code=403, detail="Access denied to this product")

    data = body.model_dump(exclude_unset=True)
    price_fields = {}
    for key, value in data.items():
        if key in ("title_ar", "title_en", "description"):
            setattr(product, key, value)
        elif key in ("factory_price_cny", "handling_fee_usd"):
            price_fields[key] = value
        else:
            setattr(product, key, value)
    if price_fields:
        catalog_service.update_price(db, product, price_fields.get("factory_price_cny"),
                                     price_fields.get("handling_fee_usd"), actor_id=api_key.owner_id)
    db.commit()
    db.refresh(product)
    return product.to_dict()


@router.put("/{product_id}/stock")
def update_stock(product_id: str, body: StockUpdate,
                 api_key=Depends(get_api_key_record), db: Session = Depends(get_db)):
    try:
        product = catalog_service.get_product(db, product_id)
    except CatalogError as exc:
        raise HTTPException(status_code=404, detail=exc.message)
    if api_key.owner_type in ("TENANT", "EMPLOYEE") and api_key.supplier_id != product.supplier_id:
        raise HTTPException(status_code=403, detail="Access denied to this product")
    product = catalog_service.update_stock(db, product, body.available_stock, api_key.owner_id)
    db.commit()
    db.refresh(product)
    return product.to_dict()


@router.post("/{product_id}/publish")
def publish_product(product_id: str, body: ProductPublish,
                    claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    """Market staff publish/review gate before the product is visible to clients."""
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    try:
        product = catalog_service.get_product(db, product_id)
    except CatalogError as exc:
        raise HTTPException(status_code=404, detail=exc.message)
    catalog_service.publish(db, product, body.is_published, claims["sub"])
    db.commit()
    db.refresh(product)
    return product.to_dict()
