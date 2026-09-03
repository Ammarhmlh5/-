"""
Models - نماذج قاعدة بيانات السوق الحرة
"""
import uuid
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    UUID,
)
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import INET

from .database import Base

CNY = "CNY"
USD = "USD"


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.utcnow()


class Supplier(Base):
    """مورد صيني متعاقد (كيان السوق المالك للبيانات)"""

    __tablename__ = "suppliers"

    supplier_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    legal_name = Column(String(200), nullable=False)
    company_name_en = Column(String(255))
    company_name_zh = Column(String(255))
    contact_phone = Column(String(50))
    contract_reference = Column(String(100), unique=True)
    settlement_currency = Column(String(3), default=CNY)

    # status: PENDING, ACTIVE, SUSPENDED, CLOSED
    status = Column(String(20), default="PENDING")
    erpnext_supplier_id = Column(String(140), unique=True)

    created_by = Column(UUID(as_uuid=False))
    created_at = Column(DateTime, default=_now, nullable=False)
    updated_at = Column(DateTime, default=_now, onupdate=_now, nullable=False)

    users = relationship("SupplierUser", back_populates="supplier")
    products = relationship("Product", back_populates="supplier")
    api_keys = relationship("MarketApiKey", back_populates="supplier")

    def to_dict(self):
        return {
            "supplier_id": self.supplier_id,
            "legal_name": self.legal_name,
            "company_name_en": self.company_name_en,
            "company_name_zh": self.company_name_zh,
            "contact_phone": self.contact_phone,
            "contract_reference": self.contract_reference,
            "settlement_currency": self.settlement_currency,
            "status": self.status,
            "erpnext_supplier_id": self.erpnext_supplier_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class SupplierUser(Base):
    """موظف/عامل مورد — حساب تشغيلي محلي فقط (لا ينشئ مستخدم ERPNext)"""
    __tablename__ = "supplier_users"

    user_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    supplier_id = Column(UUID(as_uuid=False), ForeignKey("suppliers.supplier_id"), nullable=False)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(120))
    role = Column(String(30), default="SUPPLIER_OPERATOR")

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=_now, nullable=False)

    supplier = relationship("Supplier", back_populates="users")

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "supplier_id": self.supplier_id,
            "username": self.username,
            "email": self.email,
            "full_name": self.full_name,
            "role": self.role,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class MarketOperator(Base):
    """موظف شركة السوق — admins/مديرو السوق"""

    __tablename__ = "market_operators"

    operator_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(120))
    role = Column(String(30), default="MARKET_OPERATOR")  # ADMIN, MARKET_MANAGER, etc.
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=_now, nullable=False)

    def to_dict(self):
        return {
            "operator_id": self.operator_id,
            "username": self.username,
            "email": self.email,
            "full_name": self.full_name,
            "role": self.role,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class Product(Base):
    """منتج في الكتالوج — سعر المصنع باليوان، والسعر النهائي يُحسب وقت العرض"""

    __tablename__ = "marketplace_catalog"

    product_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    supplier_id = Column(UUID(as_uuid=False), ForeignKey("suppliers.supplier_id"), nullable=False)
    sku = Column(String(100), nullable=False)
    title_ar = Column(String(255), nullable=False)
    title_en = Column(String(255))
    description = Column(Text)

    factory_price_cny = Column(Numeric(12, 2), nullable=False)
    handling_fee_usd = Column(Numeric(10, 2), default=0)

    volume_cbm = Column(Numeric(10, 4), default=0)
    weight_kg = Column(Numeric(10, 2), default=0)
    available_stock = Column(Integer, default=0)

    # status: DRAFT, ACTIVE, INACTIVE
    status = Column(String(20), default="DRAFT")
    is_published = Column(Boolean, default=False)

    created_by = Column(UUID(as_uuid=False))
    created_at = Column(DateTime, default=_now, nullable=False)
    updated_at = Column(DateTime, default=_now, onupdate=_now, nullable=False)

    __table_args__ = (UniqueConstraint("sku", name="uq_product_sku"),)

    supplier = relationship("Supplier", back_populates="products")
    order_items = relationship("OrderItem", back_populates="product")

    def to_dict(self):
        return {
            "product_id": self.product_id,
            "supplier_id": self.supplier_id,
            "sku": self.sku,
            "title_ar": self.title_ar,
            "title_en": self.title_en,
            "description": self.description,
            "factory_price_cny": float(self.factory_price_cny) if self.factory_price_cny else 0,
            "handling_fee_usd": float(self.handling_fee_usd) if self.handling_fee_usd else 0,
            "volume_cbm": float(self.volume_cbm) if self.volume_cbm else 0,
            "weight_kg": float(self.weight_kg) if self.weight_kg else 0,
            "available_stock": self.available_stock,
            "status": self.status,
            "is_published": self.is_published,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class MarketOrder(Base):
    """طلب عميل — دورة الحياة DRAFT -> CONFIRMED -> PAID -> CANCELLED"""

    __tablename__ = "marketplace_orders"

    order_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    order_reference = Column(String(120), unique=True, nullable=False)
    customer_user_id = Column(UUID(as_uuid=False), nullable=False)
    erp_customer_code = Column(String(100))
    erpnext_sales_order_id = Column(String(140), unique=True)

    # status: DRAFT, CONFIRMED, PAID, CANCELLED
    status = Column(String(30), default="DRAFT")
    currency = Column(String(3), default=USD)
    total_usd = Column(Numeric(15, 2), default=0)
    fx_rate_used = Column(Numeric(10, 6))

    notes = Column(Text)
    created_at = Column(DateTime, default=_now, nullable=False)
    updated_at = Column(DateTime, default=_now, onupdate=_now, nullable=False)

    items = relationship(
        "OrderItem", back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )

    def to_dict(self):
        return {
            "order_id": self.order_id,
            "order_reference": self.order_reference,
            "customer_user_id": self.customer_user_id,
            "erp_customer_code": self.erp_customer_code,
            "erpnext_sales_order_id": self.erpnext_sales_order_id,
            "status": self.status,
            "currency": self.currency,
            "total_usd": float(self.total_usd) if self.total_usd else 0,
            "fx_rate_used": float(self.fx_rate_used) if self.fx_rate_used else None,
            "items": [item.to_dict() for item in self.items],
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class OrderItem(Base):
    """بند طلب — يحفظ السعر المُستخدم وقت التأكيد للتدقيق"""

    __tablename__ = "order_items"

    order_item_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    order_id = Column(UUID(as_uuid=False), ForeignKey("marketplace_orders.order_id"), nullable=False)
    product_id = Column(UUID(as_uuid=False), ForeignKey("marketplace_catalog.product_id"), nullable=False)
    sku = Column(String(100), nullable=False)
    qty = Column(Integer, nullable=False)
    unit_rate_cny = Column(Numeric(12, 2), nullable=False)
    handling_fee_usd = Column(Numeric(10, 2), default=0)
    fx_rate_used = Column(Numeric(10, 6))
    unit_rate_usd = Column(Numeric(12, 2), nullable=False)
    warehouse = Column(String(100))

    order = relationship("MarketOrder", back_populates="items")
    product = relationship("Product", back_populates="order_items")

    def to_dict(self):
        return {
            "order_item_id": self.order_item_id,
            "product_id": self.product_id,
            "sku": self.sku,
            "qty": self.qty,
            "unit_rate_cny": float(self.unit_rate_cny) if self.unit_rate_cny else 0,
            "handling_fee_usd": float(self.handling_fee_usd) if self.handling_fee_usd else 0,
            "fx_rate_used": float(self.fx_rate_used) if self.fx_rate_used else None,
            "unit_rate_usd": float(self.unit_rate_usd) if self.unit_rate_usd else 0,
            "line_total_usd": round(
                (float(self.unit_rate_usd) if self.unit_rate_usd else 0) * int(self.qty or 0),
                2,
            ),
            "warehouse": self.warehouse,
        }


class MarketApiKey(Base):
    """مفتاح تشغيلي محلي — محفوظ كهاش، لا يمنح اتصالاً بـ ERPNext"""

    __tablename__ = "market_api_keys"

    key_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    supplier_id = Column(UUID(as_uuid=False), ForeignKey("suppliers.supplier_id"))
    owner_type = Column(String(20), nullable=False)  # SYSTEM, TENANT, EMPLOYEE
    owner_id = Column(UUID(as_uuid=False), nullable=False)
    key_fingerprint = Column(String(64), unique=True, nullable=False)
    key_hash = Column(Text, nullable=False)
    scopes = Column(JSON, default=list)
    # status: ACTIVE, REVOKED
    status = Column(String(20), default="ACTIVE")
    expires_at = Column(DateTime)
    last_used_at = Column(DateTime)
    created_by = Column(UUID(as_uuid=False))
    revoked_by = Column(UUID(as_uuid=False))
    revoked_at = Column(DateTime)
    created_at = Column(DateTime, default=_now, nullable=False)

    supplier = relationship("Supplier", back_populates="api_keys")

    def to_dict(self):
        return {
            "key_id": self.key_id,
            "supplier_id": self.supplier_id,
            "owner_type": self.owner_type,
            "owner_id": self.owner_id,
            "key_fingerprint": self.key_fingerprint,
            "scopes": self.scopes or [],
            "status": self.status,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "last_used_at": self.last_used_at.isoformat() if self.last_used_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class MarketErpCredential(Base):
    """مرجع اعتماد محاسبي — يحفظ المرجع والبصمة فقط، لا السر"""

    __tablename__ = "market_erp_credentials"

    credential_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    supplier_id = Column(UUID(as_uuid=False), unique=True, nullable=False)
    channel = Column(String(20), default="MARKET")
    erpnext_entity_type = Column(String(30), default="Supplier")
    erpnext_entity_id = Column(String(140), unique=True, nullable=False)
    secret_ref = Column(String(300), nullable=False)
    key_fingerprint = Column(String(64), unique=True, nullable=False)
    # status: PROVISIONING, READY, FAILED
    status = Column(String(20), default="PROVISIONING")
    allowed_operations = Column(JSON, default=list)
    expires_at = Column(DateTime)
    rotated_at = Column(DateTime)
    created_at = Column(DateTime, default=_now, nullable=False)


class MarketProvisioningJob(Base):
    """مهمة اعتماد/ربط — تكرار آمن عبر مفتاح idempotent"""

    __tablename__ = "market_provisioning_jobs"

    job_id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    supplier_id = Column(UUID(as_uuid=False), nullable=False)
    operation = Column(String(40), nullable=False)
    idempotency_key = Column(String(140), unique=True, nullable=False)
    # status: PENDING, SUCCESS, FAILED
    status = Column(String(20), default="PENDING")
    attempt_count = Column(Integer, default=0)
    last_error_code = Column(String(80))
    next_attempt_at = Column(DateTime)
    completed_at = Column(DateTime)
    created_at = Column(DateTime, default=_now, nullable=False)


class FxRate(Base):
    """سعر صرف يومي — اليوان مقابل الدولار"""

    __tablename__ = "fx_rates"

    id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    base_currency = Column(String(3), default=CNY)
    quote_currency = Column(String(3), default=USD)
    rate = Column(Numeric(12, 6), nullable=False)
    effective_date = Column(String(10), nullable=False)
    source = Column(String(30), default="manual")
    created_at = Column(DateTime, default=_now, nullable=False)

    __table_args__ = (
        UniqueConstraint("base_currency", "quote_currency", "effective_date", name="uq_fx_day"),
    )


class ProductChangeLog(Base):
    """سجل تغييرات الأسعار والمخزون والمنتجات للتدقيق"""

    __tablename__ = "product_change_logs"

    id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    product_id = Column(UUID(as_uuid=False), nullable=False)
    supplier_id = Column(UUID(as_uuid=False), nullable=False)
    action = Column(String(40), nullable=False)  # CREATE, UPDATE_STOCK, UPDATE_PRICE, PUBLISH
    actor_id = Column(UUID(as_uuid=False))
    old_values = Column(JSON)
    new_values = Column(JSON)
    created_at = Column(DateTime, default=_now, nullable=False)


class MarketAuditLog(Base):
    """سجل تدقيق التكامل — يمنع تسجيل الأسرار"""

    __tablename__ = "market_audit_logs"

    id = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    request_id = Column(UUID(as_uuid=False), nullable=False)
    tenant_id = Column(UUID(as_uuid=False))
    actor_id = Column(UUID(as_uuid=False))
    actor_key_id = Column(UUID(as_uuid=False), ForeignKey("market_api_keys.key_id"))
    channel = Column(String(20))
    credential_id = Column(UUID(as_uuid=False), ForeignKey("market_erp_credentials.credential_id"))
    operation = Column(String(60))
    result = Column(String(20))
    reason_code = Column(String(80))
    source_ip = Column(INET())
    created_at = Column(DateTime, default=_now, nullable=False)
