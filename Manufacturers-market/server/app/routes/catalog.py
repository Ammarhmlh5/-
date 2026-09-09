"""
Catalog - الكتالوج: دخول المورد، المراجعة، النشر، والتصفح للعميل
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_api_key_record, get_current_access_claims, require_role
from ..models import CatalogCategory, MarketApiKey, Product, Supplier
from ..schemas import CategoryCreate, ProductCreate, ProductPublish, ProductUpdate, StockUpdate
from ..services import catalog_service
from ..services.catalog_service import CatalogError
from ..services.audit_service import write_audit
from ..security import new_request_id

router = APIRouter(prefix="/catalog", tags=["catalog"])


def _set_product_categories(db: Session, product: Product, category_ids: list[str]):
    categories = db.execute(select(CatalogCategory).where(
        CatalogCategory.category_id.in_(category_ids),
        CatalogCategory.supplier_id == product.supplier_id,
    )).scalars().all() if category_ids else []
    if len(categories) != len(set(category_ids)):
        raise HTTPException(status_code=400, detail="All categories must belong to the product supplier")
    product.categories = categories


@router.get("/categories")
def list_categories(supplier_id: str | None = None,
                    claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    query = select(CatalogCategory).order_by(CatalogCategory.name.asc())
    if supplier_id:
        query = query.where(CatalogCategory.supplier_id == supplier_id)
    return [category.to_dict() for category in db.execute(query).scalars().all()]


@router.post("/categories", status_code=201)
def create_category(body: CategoryCreate,
                    api_key: MarketApiKey = Depends(get_api_key_record),
                    db: Session = Depends(get_db)):
    if api_key.owner_type in ("TENANT", "EMPLOYEE") and api_key.supplier_id != body.supplier_id:
        raise HTTPException(status_code=403, detail="Cannot create category for another supplier")
    supplier = db.get(Supplier, body.supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    existing = db.execute(select(CatalogCategory).where(
        CatalogCategory.supplier_id == body.supplier_id,
        CatalogCategory.name == body.name,
    )).scalars().first()
    if existing:
        raise HTTPException(status_code=409, detail="Category already exists")
    category = CatalogCategory(supplier_id=body.supplier_id, name=body.name)
    db.add(category)
    db.commit()
    db.refresh(category)
    return category.to_dict()


@router.delete("/categories/{category_id}")
def delete_category(category_id: str, claims=Depends(get_current_access_claims), db: Session = Depends(get_db)):
    require_role(claims, {"ADMIN", "MARKET_MANAGER"})
    category = db.get(CatalogCategory, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(category)
    db.commit()
    return {"message": "Category deleted"}


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
        image_urls=body.image_urls,
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
    db.flush()
    _set_product_categories(db, product, body.category_ids)
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
    category_ids = data.pop("category_ids", None)
    price_fields = {}
    for key, value in data.items():
        if key in ("title_ar", "title_en", "description", "image_urls"):
            setattr(product, key, value)
        elif key in ("factory_price_cny", "handling_fee_usd"):
            price_fields[key] = value
        else:
            setattr(product, key, value)
    if price_fields:
        catalog_service.update_price(db, product, price_fields.get("factory_price_cny"),
                                     price_fields.get("handling_fee_usd"), actor_id=api_key.owner_id)
    if category_ids is not None:
        _set_product_categories(db, product, category_ids)
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
