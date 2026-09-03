# OP-01: Server Plan — Curated B2B Marketplace

**Operation:** OP-01 | **Workstream A** | **Phase 2 (Weeks 4-6)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the FastAPI server instance, REST endpoints, service modules, and background tasks that power the curated B2B marketplace for China (vendors) and Yemen (merchants).

---

## 2. Service Architecture

A dedicated FastAPI instance (`marketplace_service`) separated from logistics tracking and ERPNext.

```
FastAPI Marketplace Instance :8000
├── routes/
│   ├── suppliers.py        (vendor CRUD)
│   ├── catalog.py          (SKU catalog browse/manage)
│   ├── orders.py           (order placement & checkout)
│   └── auth.py             (JWT login / role scopes)
├── services/
│   ├── currency.py         (CNY → USD markup engine)
│   ├── catalog_service.py  (stock & pricing logic)
│   └── order_service.py    (order lifecycle)
├── models/                 (SQLAlchemy ORM)
├── workers/
│   └── price_refresh.py    (Celery: daily FX table update)
└── config.py
```

---

## 3. REST Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/auth/login` | Public | JWT token issuance |
| `GET` | `/api/suppliers` | vendor/admin | List verified suppliers |
| `POST` | `/api/suppliers` | admin | Register China supplier |
| `PUT` | `/api/suppliers/{id}` | vendor | Update own supplier profile |
| `GET` | `/api/catalog` | merchant | Browse catalog w/ computed USD |
| `GET` | `/api/catalog/{sku}` | merchant | Product detail |
| `POST` | `/api/catalog` | vendor | Create/update SKU entry |
| `PUT` | `/api/catalog/{sku}/stock` | vendor | Update live stock count |
| `POST` | `/api/orders` | merchant | Create order (DRAFT) |
| `GET` | `/api/orders/{reference}` | merchant/vendor | Order status |
| `POST` | `/api/orders/{reference}/checkout` | merchant | Confirm & pay → OP-03 |

---

## 4. Service Modules

### 4.1 `currency.py` — Currency Conversion Engine

```python
def compute_unit_rate_usd(factory_price_cny: Decimal,
                          handling_fee_usd: Decimal,
                          fx_rate: Decimal) -> Decimal:
    return factory_price_cny * fx_rate + handling_fee_usd
```

- Ingests daily factory wholesale rates (CNY)
- Fetches FX table from Redis cache (updated daily by worker)
- Renders final inclusive pricing in USD to merchants

### 4.2 `catalog_service.py`

- Read-through Redis caching layer to minimize DB queries
- Inventory validation against `available_stock`
- Prevents overselling beyond confirmed vendor stock

### 4.3 `order_service.py`

- Order lifecycle: `DRAFT → CONFIRMED → PAID → CANCELLED`
- On `PAID`, emits event to OP-03 bus (Sales Order payload)

---

## 5. Background Tasks (Celery)

| Worker | Schedule | Function |
|--------|----------|----------|
| `price_refresh` | Daily @ 00:30 UTC | Refresh CNY→USD FX table in Redis |
| `catalog_snapshot` | Hourly | Rebuild hot catalog read cache |

**Celery Config:**
```python
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/1"
```

---

## 6. Error Handling

| Error | HTTP | Handling |
|-------|------|----------|
| Invalid SKU | 404 | Return not found |
| Insufficient stock | 409 | Conflict — notify vendor |
| Currency unavailable | 503 | Fall back to cached FX rate |
| Duplicate order ref | 409 | Idempotent replay check |

---

## 7. Deployment Runbook (Phase 2)

1. Provision marketplace PostgreSQL instance (`shipping_marketplace`)
2. Apply DB schema (`database_plan.md`)
3. Deploy FastAPI instance on `:8000`
4. Start Celery workers + Redis broker
5. Point vendor portal (China) and merchant UI (Yemen) at endpoints
6. Run integration smoke tests against endpoints (TDD)

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
