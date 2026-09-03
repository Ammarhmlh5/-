# OP-01: Architecture — Curated B2B Marketplace

**Operation:** OP-01 | **Workstream A** | **Phase 2 (Weeks 4-6)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Component Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         CHINA VENDOR HUB (web)                          │
│                       (contracted suppliers portal)                      │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │ HTTPS + JWT
┌───────────────────────────────────▼──────────────────────────────────────┐
│                    ✦ OP-01 MARKETPLACE SERVICE (FastAPI :8000) ✦        │
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
                 │   Redis Cache / FX      │          │  Marketplace DB       │
                 │   (currency table)      │          │  shipping_marketplace │
                 └─────────────┬───────────┘          │  + PostGIS            │
                               │                      │  suppliers_china      │
                               │                      │  marketplace_catalog  │
                               │                      │  marketplace_orders   │
                               │                      │  order_items          │
                               │                      └───────────────────────┘
┌──────────────────────────────┴──────────────────────────────────────────────┐
│                     OPERATIONS PLAN BUS (OP-03)                             │
│   Electromarks → Sales Order → ERPNext Cost Center / Customer               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow Narrative

1. **China vendor** authenticates via JWT, manages `suppliers_china` and `marketplace_catalog` (SKU, stock, CNY factory price).
2. **Yemen merchant** browses `marketplace_catalog`; the server renders each item with **computed USD** (markup engine) — never cached stale prices.
3. On **checkout**, `marketplace_orders` + `order_items` are persisted in `DRAFT`.
4. On **payment verify**, status → `PAID` and the order is emitted to **OP-03** (Sales Order payload).
5. All financial data leaves the marketplace DB only via the OP-03 bus — the marketplace never contacts ERPNext directly.

---

## 3. Security Boundaries

| Boundary | Enforcement |
|----------|-------------|
| Marketplace DB → ERPNext | **Blocked** outright |
| Vendor vs Merchant scopes | JWT role claims (`vendor`, `merchant`, `admin`) |
| PII (client data) | Stored locally, never duplicated into ERPNext |
| FX/pricing tampering | USD computed server-side; FX locked from Redis |

---

## 4. Failure Handling Design

- **Currency source down** → serve cached FX rate (last 24h), log warning.
- **Marketplace DB down** → read-only catalog from Redis; order placement queues.
- **OP-03 down at checkout** → order remains `CONFIRMED`, re-emitted on bus recovery (Idempotency key prevents duplicates).

---

## 5. Frontend Bindings

| Frontend | Role | Objects |
|----------|------|---------|
| `china_app/` | Vendor portal | Suppliers, catalog, stock, QC image upload |
| `yemen_app/` | Client app | Browse catalog, place orders, RTL Arabic |

---

## 6. Out-of-Scope (Deferred to Other Ops)

- Vessel/container tracking → **OP-02**
- Financial ledger commit → **OP-03**

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
