"""
Smoke tests - اختبار تشغيلي لخادم السوق الحرة
Run: python -m pytest server/tests -v
"""
import os

os.environ["TEST_DATABASE_URL"] = "postgresql+psycopg://market_user:marketpass2026@localhost:5543/shipping_marketplace_test"
os.environ["APP_ENV"] = "testing"
os.environ["JWT_SECRET_KEY"] = "test-secret"
os.environ["MARKET_ERP_KEY"] = "test-market-erp-key"

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base


@pytest.fixture(autouse=True)
def reset_test_database():
    """Keep each smoke test independent on the dedicated test database."""
    Base.metadata.drop_all(bind=app.state.engine)
    Base.metadata.create_all(bind=app.state.engine)


@pytest.fixture()
def client():
    with TestClient(app) as c:
        yield c


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "healthy"


def _login_admin(client):
    resp = client.post("/api/market/auth/login", json={
        "identity": "admin",
        "password": "Admin123!",
    })
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["actor_type"] == "MARKET_STAFF"
    assert "access_token" in body
    return body["access_token"]


def _admin_headers(client) -> dict:
    token = _login_admin(client)
    return {"Authorization": f"Bearer {token}"}


def test_login_admin(client):
    assert _login_admin(client)


def test_full_supplier_flow(client):
    h = _admin_headers(client)

    # 1. create supplier
    resp = client.post("/api/market/suppliers", json={
        "legal_name": "Shenzhen Tech Manufacturing Co.",
        "contract_reference": "CN-2026-0001",
        "settlement_currency": "CNY",
    }, headers=h)
    assert resp.status_code in (200, 201), resp.text
    supplier = resp.json()["supplier"]
    sid = supplier["supplier_id"]
    assert supplier["status"] == "PENDING"

    # 2. create supplier employee
    resp = client.post("/api/market/tenant-users", json={
        "supplier_id": sid,
        "username": "supplier_operator",
        "email": "op@supplier.cn",
        "password": "supplierpass123",
        "full_name": "China Operator",
    }, headers=h)
    assert resp.status_code == 201, resp.text
    employee_id = resp.json()["user_id"]

    # 3. create a tenant API key
    resp = client.post("/api/market/api-keys", json={
        "owner_type": "EMPLOYEE",
        "owner_id": employee_id,
        "scopes": ["catalog:write", "stock:write"],
    }, headers=h)
    assert resp.status_code == 201, resp.text
    direct_key = resp.json()["secret"]

    # 3b. supplier creates a catalog category
    resp = client.post("/api/market/catalog/categories", json={
        "supplier_id": sid,
        "name": "Electronics",
    }, headers={"Authorization": f"Bearer {direct_key}"})
    assert resp.status_code == 201, resp.text
    category_id = resp.json()["category_id"]

    # 4. provision supplier (needs MARKET_ERP_KEY set)
    if os.environ.get("MARKET_ERP_KEY"):
        resp = client.post(f"/api/market/suppliers/{sid}/provision", headers=h)
        assert resp.status_code == 200, resp.text

    # 5. supplier creates a product with their API key
    kh = {"Authorization": f"Bearer {direct_key}"}
    resp = client.post("/api/market/catalog", json={
        "supplier_id": sid,
        "sku": "SKU-TEST-001",
        "title_ar": "منتج تجريبي",
        "factory_price_cny": 100.0,
        "handling_fee_usd": 2.0,
        "available_stock": 50,
        "category_ids": [category_id],
        "image_urls": ["https://cdn.example.test/products/SKU-TEST-001/main.jpg"],
    }, headers=kh)
    assert resp.status_code == 201, resp.text
    product = resp.json()
    pid = product["product_id"]
    assert product["status"] == "DRAFT"
    assert product["is_published"] is False
    assert product["categories"][0]["category_id"] == category_id
    assert product["image_urls"][0].endswith("main.jpg")

    # 6. publish product (market manager)
    resp = client.post(f"/api/market/catalog/{pid}/publish", json={"is_published": True}, headers=h)
    assert resp.status_code == 200, resp.text

    # 7. browse catalog with computed USD price
    resp = client.get("/api/market/catalog", headers=h)
    assert resp.status_code == 200, resp.text
    found = [p for p in resp.json() if p["sku"] == "SKU-TEST-001"]
    assert found, "product not in published catalog"
    assert found[0]["pricing"] is not None
    assert found[0]["pricing"]["unit_rate_usd"] > 0

    # 8. place an order
    resp = client.post("/api/market/orders", json={
        "items": [{"sku": "SKU-TEST-001", "qty": 2}]
    }, headers=h)
    assert resp.status_code == 201, resp.text
    order = resp.json()
    ref = order["order_reference"]
    assert order["status"] == "DRAFT"

    # 9. confirm and pay
    resp = client.post(f"/api/market/orders/{ref}/confirm", headers=h)
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "CONFIRMED"
    resp = client.post(f"/api/market/orders/{ref}/pay", headers=h)
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "PAID"

    resp = client.post("/api/market/webhooks/op03", json={
        "source_type": "ORDER",
        "source_id": order["order_id"],
        "erp_document_name": "SAL-ORDER-TEST-001",
        "outbox_id": "outbox-order-test",
        "status": "DONE",
    }, headers={"X-Integration-Key": "test-market-erp-key"})
    assert resp.status_code == 202, resp.text

    resp = client.get(f"/api/market/orders/{ref}", headers=h)
    assert resp.status_code == 200, resp.text
    assert resp.json()["erpnext_sales_order_id"] == "SAL-ORDER-TEST-001"

    # 10. stock deducted
    resp = client.get("/api/market/catalog", headers=h)
    found = [p for p in resp.json() if p["sku"] == "SKU-TEST-001"][0]
    assert found["available_stock"] == 48


def test_tenant_isolation(client):
    """A supplier's API key must not access another supplier's product."""
    h = _admin_headers(client)

    resp = client.post("/api/market/suppliers", json={
        "legal_name": "Supplier A", "contract_reference": "ISO-A",
    }, headers=h)
    sid_a = resp.json()["supplier"]["supplier_id"]
    resp = client.post("/api/market/suppliers", json={
        "legal_name": "Supplier B", "contract_reference": "ISO-B",
    }, headers=h)
    sid_b = resp.json()["supplier"]["supplier_id"]

    resp = client.post("/api/market/tenant-users", json={
        "supplier_id": sid_a, "username": "op_a", "email": "a@x.cn", "password": "pass1234",
    }, headers=h)
    emp_a = resp.json()["user_id"]
    resp = client.post("/api/market/api-keys", json={
        "owner_type": "EMPLOYEE", "owner_id": emp_a, "scopes": ["catalog:write"],
    }, headers=h)
    key_a = resp.json()["secret"]

    # Supplier A creates a product
    resp = client.post("/api/market/catalog", json={
        "supplier_id": sid_a, "sku": "SKU-A", "title_ar": "A",
        "factory_price_cny": 10, "available_stock": 5,
    }, headers={"Authorization": f"Bearer {key_a}"})
    pid_a = resp.json()["product_id"]

    # Supplier B tries to update Supplier A's product -> must be 403
    resp = client.post("/api/market/suppliers", json={
        "legal_name": "Supplier B2", "contract_reference": "ISO-B2",
    }, headers=h)
    sid_b2 = resp.json()["supplier"]["supplier_id"]
    resp = client.post("/api/market/tenant-users", json={
        "supplier_id": sid_b2, "username": "op_b2", "email": "b2@x.cn", "password": "pass1234",
    }, headers=h)
    emp_b2 = resp.json()["user_id"]
    resp = client.post("/api/market/api-keys", json={
        "owner_type": "EMPLOYEE", "owner_id": emp_b2, "scopes": ["catalog:write"],
    }, headers=h)
    key_b2 = resp.json()["secret"]

    resp = client.put(f"/api/market/catalog/{pid_a}", json={"available_stock": 99},
                      headers={"Authorization": f"Bearer {key_b2}"})
    assert resp.status_code == 403, resp.text


def test_op03_supplier_callback_updates_mapping(client):
    headers = _admin_headers(client)
    resp = client.post("/api/market/suppliers", json={
        "legal_name": "Callback Supplier",
        "contract_reference": "CALLBACK-001",
    }, headers=headers)
    assert resp.status_code == 201, resp.text
    supplier_id = resp.json()["supplier"]["supplier_id"]

    resp = client.post("/api/market/webhooks/op03", json={
        "source_type": "SUPPLIER",
        "source_id": supplier_id,
        "erp_document_name": "SUP-CALLBACK-001",
        "outbox_id": "outbox-test",
        "status": "DONE",
    }, headers={"X-Integration-Key": "test-market-erp-key"})
    assert resp.status_code == 202, resp.text

    resp = client.get(f"/api/market/suppliers/{supplier_id}", headers=headers)
    assert resp.status_code == 200, resp.text
    assert resp.json()["erpnext_supplier_id"] == "SUP-CALLBACK-001"
    assert resp.json()["status"] == "ACTIVE"
