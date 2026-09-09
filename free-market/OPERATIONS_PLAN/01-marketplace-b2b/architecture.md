# OP-01: Architecture — Supplier Catalog & Sourcing Operations

**Operation:** OP-01 | **Workstream A** | **Phase 2 (Weeks 4-6)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Component Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       CHINA SUPPLIER PORTAL (web)                       │
│                       (contracted suppliers portal)                      │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │ HTTPS + JWT
┌───────────────────────────────────▼──────────────────────────────────────┐
│                 ✦ OP-01 CATALOG SERVICE (FastAPI :8000) ✦              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Auth (JWT)  │  │ Supplier API │  │  Catalog API │  │  Orders API  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │                 │          │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  │
│  │  services/   │  │   services/  │  │  services/   │  │  services/   │  │
│  │  currency.py │  │  supplier.py │  │ catalog_svc  │  │  order_svc   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────┬───────┘  │
└──────────────────────────────┬───────────────────────────────────┬────────┘
                               │                                   │
                 ┌─────────────▼───────────┐          ┌────────────▼──────────┐
                 │   Redis Cache / FX      │          │  Catalog DB            │
                 │   (currency table)      │          │  shipping_catalog      │
                 └─────────────┬───────────┘          │  + PostGIS            │
                               │                      │  suppliers_china      │
                               │                      │  marketplace_catalog  │
                               │                      │  supplier_quotes       │
                               │                      │  supplier_quotes      │
                               │                      └───────────────────────┘
┌──────────────────────────────┴──────────────────────────────────────────────┐
│                     OPERATIONS PLAN BUS (OP-03)                             │
│   Electromarks → Sales Order → ERPNext Cost Center / Customer               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow Narrative

1. **China supplier** authenticates via JWT and manages its own catalog, stock and sourcing responses.
2. The catalog service publishes approved products to a customer read model; clients never connect to the catalog DB.
3. Customer orders and payments are owned by the customer/order service, not OP-01.
4. An approved order or supplier payable becomes a financial command for OP-03; OP-01 never contacts ERPNext directly.

---

## 3. Security Boundaries

| Boundary | Enforcement |
|----------|-------------|
| Marketplace DB → ERPNext | **Blocked** outright |
| Vendor vs Merchant scopes | JWT role claims (`vendor`, `merchant`, `admin`) |
| PII (client data) | Owned by customer/order service; not stored in catalog DB |
| FX/pricing tampering | USD computed server-side; FX locked from Redis |

---

## 4. Failure Handling Design

- **Currency source down** → serve cached FX rate (last 24h), log warning.
- **Catalog DB down** → read-only approved catalog from the customer read model; sourcing writes queue for recovery.
- **OP-03 down** → the owning customer/order or logistics record remains operationally pending and the financial command is retried through the outbox.

---

## 5. Frontend Bindings

| Frontend | Role | Objects |
|----------|------|---------|
| `china_app/` | Supplier/staff portal | Suppliers, catalog, stock, QC image upload |
| `yemen_app/` | Client app | Browse approved read model, place orders through customer API |

---

## 6. Out-of-Scope (Deferred to Other Ops)

- Vessel/container tracking → **OP-02**
- Financial ledger commit → **OP-03**

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
