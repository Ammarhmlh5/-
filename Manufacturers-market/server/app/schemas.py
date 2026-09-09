"""
Schemas - نماذج Pydantic للتحقق من المدخلات والمخرجات
"""
from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    identity: str
    password: str


class SupplierCreate(BaseModel):
    legal_name: str = Field(min_length=1, max_length=200)
    company_name_en: Optional[str] = None
    company_name_zh: Optional[str] = None
    contact_phone: Optional[str] = None
    contract_reference: Optional[str] = None
    settlement_currency: str = "CNY"


class SupplierUpdate(BaseModel):
    legal_name: Optional[str] = None
    company_name_en: Optional[str] = None
    company_name_zh: Optional[str] = None
    contact_phone: Optional[str] = None
    contract_reference: Optional[str] = None
    settlement_currency: Optional[str] = None
    status: Optional[str] = None


class SupplierUserCreate(BaseModel):
    supplier_id: str
    username: str = Field(min_length=3, max_length=50)
    email: str
    password: str = Field(min_length=6)
    full_name: Optional[str] = None
    role: str = "SUPPLIER_OPERATOR"


class ProductCreate(BaseModel):
    supplier_id: str
    sku: str
    title_ar: str
    title_en: Optional[str] = None
    description: Optional[str] = None
    image_urls: list[str] = []
    factory_price_cny: float = Field(gt=0)
    handling_fee_usd: float = 0
    volume_cbm: float = 0
    weight_kg: float = 0
    available_stock: int = 0
    category_ids: list[str] = []


class ProductUpdate(BaseModel):
    title_ar: Optional[str] = None
    title_en: Optional[str] = None
    description: Optional[str] = None
    image_urls: Optional[list[str]] = None
    factory_price_cny: Optional[float] = None
    handling_fee_usd: Optional[float] = None
    volume_cbm: Optional[float] = None
    weight_kg: Optional[float] = None
    category_ids: Optional[list[str]] = None


class CategoryCreate(BaseModel):
    supplier_id: str
    name: str = Field(min_length=1, max_length=100)


class StockUpdate(BaseModel):
    available_stock: int


class ProductPublish(BaseModel):
    is_published: bool


class OrderItemInput(BaseModel):
    sku: str
    qty: int = Field(gt=0)


class OrderCreate(BaseModel):
    items: list[OrderItemInput]


class ApiKeyCreate(BaseModel):
    owner_type: str = "EMPLOYEE"  # SYSTEM, TENANT, EMPLOYEE
    owner_id: str
    scopes: list[str] = []
    expires_in_days: Optional[int] = None


class ModelConfig(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class MessageResponse(BaseModel):
    message: str
