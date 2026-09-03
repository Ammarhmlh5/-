# OP-01: Database Plan — Curated B2B Marketplace

**Operation:** OP-01 | **Workstream A** | **Phase 2 (Weeks 4-6)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md) | Master: [PROJECT_PLAN.md](../../PROJECT_PLAN.md)

---

## 1. Purpose

Defines the independent PostgreSQL (with PostGIS) database schema that powers the curated B2B marketplace. This database is **structurally isolated** from ERPNext and the logistics tracking database. It handles client (Yemen) interactions and vendor (China) stock/catalog entries only.

---

## 2. Isolation & Security

- Dedicated PostgreSQL database: `shipping_marketplace`
- **Zero** direct read/write to ERPNext core
- All financial outbound traffic flows to OP-03 integration bus
- PostGIS required for geospatial supplier/location data

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

### 3.3 `marketplace_orders` — Client Orders

```sql
CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    erp_customer_code VARCHAR(100) NOT NULL,   -- binds to ERPNext Customer
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

**Purpose:** Line-level detail enabling precise ERPNext `Sales Order` item arrays.

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
China Vendor (contract)                 Yemen Client (merchant)
        │                                       │
        ▼                                       ▼
  suppliers_china                       marketplace_catalog browse
        │                                       │
        └──────────► marketplace_orders ◄───────┘
                          │
                    order_items
                          │
                    w/ computed USD
                          ▼
              OP-03 Integration Bus
              → ERPNext Sales Order
```

---

## 6. Migration Strategy

- Schema versioning via SQLAlchemy Alembic (planned in `backend/models/`)
- Initial schema: `01_database_setup/create_tables.sql` (aligned tables `shipments_items`, `customers`)
- PostGIS extension installed via `01_database_setup/docker-compose.yml`

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
