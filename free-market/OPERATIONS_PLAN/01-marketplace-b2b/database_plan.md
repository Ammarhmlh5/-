# OP-01: Database Plan — Supplier Catalog & Sourcing Operations

**Operation:** OP-01 | **Workstream A** | **Phase 2 (Weeks 4-6)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md) | Master: [PROJECT_PLAN.md](../../PROJECT_PLAN.md)

---

## 1. Purpose

Defines the independent PostgreSQL database for supplier operations, catalog data, pricing, stock and sourcing requests. It is **structurally isolated** from ERPNext, the customer/order database and the logistics database. Customer-facing APIs consume approved data through a backend service or read model; no client application reads this database directly.

---

## 2. Isolation & Security

- Dedicated PostgreSQL database: `shipping_catalog`
- **Zero** direct read/write to ERPNext core
- Financial events flow to OP-03 only after an operational approval rule is satisfied
- Product images and documents are stored in object storage; PostgreSQL stores metadata and object keys
- Supplier and catalog records are tenant-scoped and never prove customer ownership

---

## 3. Tables Specification

### 3.1 `suppliers_china` — China Verified Suppliers Registry

```sql
-- Enable Geospatial PostGIS Extensions
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE suppliers_china (
    supplier_id SERIAL PRIMARY KEY,
    company_name_en VARCHAR(255) NOT NULL,
    company_name_zh VARCHAR(255),
    contact_phone VARCHAR(50),
    contract_reference VARCHAR(100) UNIQUE,
    settlement_currency VARCHAR(3) DEFAULT 'CNY',
    is_active BOOLEAN DEFAULT TRUE,
    geo_location GEOMETRY(Point, 4326),      -- PostGIS factory coordinates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose:** Contracted Chinese vendors manage live stock catalogs natively.

**Indexes:**
```sql
CREATE INDEX idx_suppliers_active ON suppliers_china(is_active);
CREATE INDEX idx_suppliers_currency ON suppliers_china(settlement_currency);
CREATE INDEX idx_suppliers_geo ON suppliers_china USING GIST(geo_location);
```

### 3.2 `marketplace_catalog` — Central Product Catalog

```sql
CREATE TABLE marketplace_catalog (
    product_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers_china(supplier_id),
    sku VARCHAR(100) UNIQUE NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    factory_price_cny DECIMAL(12,2) NOT NULL,
    handling_fee_usd DECIMAL(10,2) DEFAULT 0.00,
    volume_cbm DECIMAL(10,4) NOT NULL,      -- cubic meters per unit
    weight_kg DECIMAL(10,2) NOT NULL,
    available_stock INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose:** Strict SKU collection mapped to contracted factories. Final USD pricing is **computed at render-time** via the markup engine (server-side), never stored — preventing stale prices.

**Indexes:**
```sql
CREATE INDEX idx_catalog_supplier ON marketplace_catalog(supplier_id);
CREATE INDEX idx_catalog_sku ON marketplace_catalog(sku);
CREATE INDEX idx_catalog_stock ON marketplace_catalog(available_stock) WHERE available_stock > 0;
```

### 3.3 `supplier_product_versions` — Auditable Product Changes

Price, weight, volume and descriptive changes must remain auditable. A published product version is immutable and is referenced by an accepted quote or order snapshot.

### 3.4 `supplier_stock_movements` — Stock Audit

Append-only receipts, reservations, adjustments and releases. `available_stock` is a projection, not the historical source of truth.

### 3.5 `sourcing_requests` — Internal Sourcing Work

Requests for products not found in the published catalog. The customer/order service owns the customer request and stores only a stable reference here; supplier quotes remain in the sourcing context.

### 3.6 `supplier_quotes` — Supplier Offers

Stores supplier offers, validity, currency, lead time and approval state. A customer-facing quote must contain a pricing snapshot, not a live catalog price.

### 3.7 Integration references

This database stores `erpnext_supplier_id` only after the supplier is approved and synchronized. It does not store invoices, payments or ledger balances.

### 3.8 `marketplace_orders` — Migration-only Reference

```sql
CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    customer_order_id UUID NOT NULL,            -- stable reference to customer/order service
    order_reference VARCHAR(120) UNIQUE NOT NULL,
    status VARCHAR(30) DEFAULT 'DRAFT',        -- DRAFT, CONFIRMED, PAID, CANCELLED
    currency VARCHAR(3) DEFAULT 'USD',
    total_usd DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3.4 `order_items` — Order Line Items

```sql
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES marketplace_orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES marketplace_catalog(product_id),
    sku VARCHAR(100) NOT NULL,
    qty INT NOT NULL,
    unit_rate_usd DECIMAL(12,2) NOT NULL,      -- computed by markup engine
    warehouse VARCHAR(100)                     -- ERPNext warehouse target
);
```

**Purpose:** Migration compatibility only. Final financial payloads are generated by OP-03 from an approved order and its immutable pricing snapshot.

---

## 4. Currency & Markup Engine (CNY → USD)

Rendered pricing is computed server-side at read time, never persisted in the catalog:

```
unit_rate_usd = factory_price_cny * fx_rate_to_usd + handling_fee_usd
```

| Input | Source |
|-------|--------|
| `factory_price_cny` | `marketplace_catalog.factory_price_cny` |
| `fx_rate_to_usd` | Daily FX table (updated at point-of-collection) |
| `handling_fee_usd` | `marketplace_catalog.handling_fee_usd` |

**Design Note:** Storing computed USD would risk stale pricing under currency fluctuation. Computing at render-time keeps the ledger consistent with ERPNext rules that enforce USD/CNY base transaction handling.

---

## 5. Data Flow

```
China Vendor (contract)                 Customer/Order Service
        │                                       │
        ▼                                       ▼
    suppliers_china                       approved catalog read model
        │                                       │
          └──────────► sourcing_requests / supplier_quotes
                            │
                     approved pricing snapshot
                            ▼
                     Customer/Order Service
                            │ financial event
                            ▼
                     OP-03 Integration Bus → ERPNext
```

---

## 6. Migration Strategy

- Schema versioning via SQLAlchemy Alembic (planned in `backend/models/`)
- Initial schema: `01_database_setup/create_tables.sql` (aligned tables `shipments_items`, `customers`)
- PostGIS extension installed via `01_database_setup/docker-compose.yml`

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
