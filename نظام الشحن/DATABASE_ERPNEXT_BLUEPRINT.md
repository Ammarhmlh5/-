# Database Schema & ERPNext Integration Blueprint

**Technical Specification Document for Unified Cross-Border Logistics and B2B Marketplace System**

---

**Prepared For:** Engineering and Development Team  
**Architecture Pattern:** Decoupled Microservices / Async API Gateway  
**Primary Stack:** Python (FastAPI), PostgreSQL (PostGIS), Flutter, ERPNext v15  
**Date:** September 2026  
**Version:** 1.0.0

---

## 1. Data Isolation & Security Principles

To secure sensitive financial entities and safeguard core enterprise operations within ERPNext, the platform enforces strict structural boundary decoupling. The B2B Marketplace and Logistics Tracking Service run as separate system containers backed by their own operational production databases (PostgreSQL with PostGIS extension). Direct read/write access from external applications to the core ERP database is fundamentally blocked. All asynchronous communications, transactional flows, and inventory balance records traverse an orchestration proxy over a cryptographically secured REST API connection gateway leveraging JSON Web Tokens (JWT).

### Isolation Layers

```
┌──────────────────────────────────────────────────────────────┐
│                   ERPNext Financial Core  (Sensitive)       │
│   Sales Orders, Purchase Invoices, Ledger, Cost Centers      │
└──────────────────────────▲───────────────────────────────────┘
                           │  HTTPS + JWT (Outbound only)
┌──────────────────────────┴───────────────────────────────────┐
│              Async Integration Bus (Celery + Redis)          │
│   Idempotency Guardrails, Retry/Backoff, Payload Buffering   │
└──────────────────────────▲───────────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────────┐
│            Operations Databases (PostgreSQL + PostGIS)       │
│   Marketplace DB   │   Logistics Tracking DB                 │
│   (suppliers,      │   (containers, AIS telemetry,           │
│    catalog, orders)│    cargo shipments)                     │
└──────────────────────────────────────────────────────────────┘
```

**Security Guarantees:**
- Zero direct marketplace/tracking DB execution on ERPNext database layers
- All outbound financial payloads validated, signed, and transmitted over TLS
- JWT-authenticated proxy with role-based scopes
- Idempotency keys prevent duplicate ledger entries

---

## 2. Production Database Schema (PostgreSQL)

Execute the following relational data definition script to initialize the independent tracking & marketplace service schema:

### 2.1 Enable Geospatial PostGIS Extensions for Ocean Freight Tracking

```sql
-- Enable Geospatial PostGIS Extensions for Ocean Freight Tracking
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 2.2 China Verified Suppliers Registry Table

```sql
-- 1. China Verified Suppliers Registry Table
CREATE TABLE suppliers_china (
    supplier_id SERIAL PRIMARY KEY,
    company_name_en VARCHAR(255) NOT NULL,
    company_name_zh VARCHAR(255),
    contact_phone VARCHAR(50),
    contract_reference VARCHAR(100) UNIQUE,
    settlement_currency VARCHAR(3) DEFAULT 'CNY',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

| Column | Type | Description |
|--------|------|-------------|
| `supplier_id` | SERIAL PK | Primary key |
| `company_name_en` | VARCHAR(255) | English legal name |
| `company_name_zh` | VARCHAR(255) | Chinese legal name |
| `contact_phone` | VARCHAR(50) | Direct contact |
| `contract_reference` | VARCHAR(100) UNIQUE | Signed contract ID |
| `settlement_currency` | VARCHAR(3) | Default `CNY` (Chinese Yuan) |
| `is_active` | BOOLEAN | Contract status flag |
| `created_at` | TIMESTAMP | Registry timestamp |

### 2.3 Marketplace B2B Central Product Catalog

```sql
-- 2. Marketplace B2B Central Product Catalog
CREATE TABLE marketplace_catalog (
    product_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers_china(supplier_id),
    sku VARCHAR(100) UNIQUE NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    factory_price_cny DECIMAL(12,2) NOT NULL,
    handling_fee_usd DECIMAL(10,2) DEFAULT 0.00,
    volume_cbm DECIMAL(10,4) NOT NULL, -- Volume cubic meters per item unit
    weight_kg DECIMAL(10,2) NOT NULL,
    available_stock INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

| Column | Type | Description |
|--------|------|-------------|
| `product_id` | SERIAL PK | Primary key |
| `supplier_id` | FK → suppliers | Contracted factory owner |
| `sku` | VARCHAR(100) UNIQUE | Strict SKU variant mapping |
| `title_ar` | VARCHAR(255) | Arabic catalog title |
| `title_en` | VARCHAR(255) | English catalog title |
| `factory_price_cny` | DECIMAL(12,2) | Wholesale rate in CNY |
| `handling_fee_usd` | DECIMAL(10,2) | Fixed USD handling surcharge |
| `volume_cbm` | DECIMAL(10,4) | Cubic meters per unit |
| `weight_kg` | DECIMAL(10,2) | Gross weight per unit |
| `available_stock` | INT | Live vendor-managed stock |
| `updated_at` | TIMESTAMP | Last inventory update |

### 2.4 Ocean Freight Shipping Containers Log

```sql
-- 3. Ocean Freight Shipping Containers Log
CREATE TABLE logistics_containers (
    container_id SERIAL PRIMARY KEY,
    container_number VARCHAR(50) UNIQUE NOT NULL, -- World standard e.g. MSCU1234567
    shipping_line VARCHAR(100), -- e.g. MSC, Maersk, COSCO
    container_size VARCHAR(10), -- 20ft, 40ft
    is_full_container_load BOOLEAN DEFAULT FALSE, -- FCL vs LCL toggle flag
    operational_status VARCHAR(50) DEFAULT 'IN_WAREHOUSE', -- DEPARTED, SEA, PORT, DESTRUCTED
    geo_location GEOMETRY(Point, 4326), -- Active ship position coordinates
    estimated_time_departure DATE,
    estimated_time_arrival DATE
);
```

| Column | Type | Description |
|--------|------|-------------|
| `container_id` | SERIAL PK | Primary key |
| `container_number` | VARCHAR(50) UNIQUE | ISO standard (e.g., MSCU1234567) |
| `shipping_line` | VARCHAR(100) | Carrier (MSC, Maersk, COSCO) |
| `container_size` | VARCHAR(10) | 20ft / 40ft |
| `is_full_container_load` | BOOLEAN | FCL vs LCL routing flag |
| `operational_status` | VARCHAR(50) | `IN_WAREHOUSE`, `DEPARTED`, `SEA`, `PORT`, `DESTRUCTED` |
| `geo_location` | GEOMETRY(POINT, 4326) | **PostGIS** vessel position (lat/lon) |
| `estimated_time_departure` | DATE | ETD |
| `estimated_time_arrival` | DATE | ETA |

**PostGIS Usage Note:** The `geo_location` field stores active ship position coordinates using EPSG:4326 (WGS 84). Spatial queries for proximity, route visualization, and corridor analytics execute natively within this operational container, keeping telemetry load away from ERPNext.

### 2.5 Cargo Shipments Distribution Registry

```sql
-- 4. Cargo Shipments Distribution Registry
CREATE TABLE cargo_shipments (
    shipment_id SERIAL PRIMARY KEY,
    container_id INT REFERENCES logistics_containers(container_id),
    erp_customer_code VARCHAR(100) NOT NULL, -- Direct binding to ERPNext Customer entity
    waybill_number VARCHAR(120) UNIQUE NOT NULL,
    total_packages INT NOT NULL,
    calculated_cbm DECIMAL(12,4) NOT NULL,
    total_weight_kg DECIMAL(12,2) NOT NULL,
    freight_cost_usd DECIMAL(12,2) NOT NULL,
    is_cleared BOOLEAN DEFAULT FALSE
);
```

| Column | Type | Description |
|--------|------|-------------|
| `shipment_id` | SERIAL PK | Primary key |
| `container_id` | FK → containers | Parent vessel container |
| `erp_customer_code` | VARCHAR(100) | Direct ERPNext Customer binding |
| `waybill_number` | VARCHAR(120) UNIQUE | Unique consignment reference |
| `total_packages` | INT | Physical package count |
| `calculated_cbm` | DECIMAL(12,4) | Computed cargo volume |
| `total_weight_kg` | DECIMAL(12,2) | Gross cargo weight |
| `freight_cost_usd` | DECIMAL(12,2) | Charged freight in USD |
| `is_cleared` | BOOLEAN | Yemen customs clearance flag |

### 2.6 Alignment with Existing Schema

The blueprint below maps the new blueprint tables onto the existing `01_database_setup/create_tables.sql` infrastructure:

| Blueprint Table | Existing Table | Mapping Notes |
|-----------------|----------------|---------------|
| `suppliers_china` | — | New table (contract-source bound to `shipping_lines`) |
| `marketplace_catalog` | `shipments_items` (partial) | Refined into standalone curated SKU catalog |
| `logistics_containers` | `containers` | Adds `geo_location` PostGIS GEOMETRY field |
| `cargo_shipments` | `shipments` | Adds `erp_customer_code`, `waybill_number`, `calculated_cbm` |
| `branches` | `branches` | Admin console drives CRUD; retains `cost_center_id`/`warehouse_id` ERPNext mapping |
| `employees` / `user_accounts` | `users` (partial) | Refines legacy `users` into employee-bound accounts with ERPNext bindings (OP-04) |
| `platform_roles` / `user_branch_roles` | `users.role`, `users.permissions` (partial) | Replaces single-role field with ERPNext-synced branch-scoped RBAC (OP-04) |
| `permission_matrix` | `users.permissions` (partial) | Resource×Action grants mirrored from ERPNext permission rules |
| `acl_sync_log` | `audit_logs` (complement) | Dedicated immutable trail for role/account synchronization events |

---

## 3. Event-Driven Sync Matrix

The system relies on explicit system lifecycle events to sync changes down to the ERPNext general ledger:

| System Event | Origin Trigger | Operational Action | Target ERPNext Document Object |
|--------------|----------------|--------------------|--------------------------------|
| **Marketplace Order** | Customer checkout confirmation & payment verify | Sales Order (Draft status state) | `Sales Order` |
| **China Warehouse Intake** | Supplier delivers verified cargo batch to warehouse | Purchase Invoice (For China Supplier payout) | `Purchase Invoice` |
| **Yemen Customs Port Release** | Container clears local customs tax & land transit fees | Land Purchase Receipt / Expense Claim Object | `Purchase Receipt` / `Expense Claim` |
| **Cargo Delivery Complete** | Final cargo scan matching barcode verification at gate | Sales Invoice & Ledger Entry update | `Sales Invoice` + Ledger Entry |
| **Branch Provision** (OP-04) | Admin Console creates branch | Create financial mastership for the office | `Cost Center` + `Warehouse` |
| **Employee Onboarding** (OP-04) | Admin Console registers employee | Provision HR master record | `Employee` + `User` |
| **Role Assignment** (OP-04) | Admin grants branch-scoped role | Grant ERPNext user role | `User Role` / `Role Profile` |
| **Role/Permission Pull** (OP-04) | ERPNext role definition changes | Mirror authority down to platform RBAC | `Role` / `Role Permission` → platform |

---

## 4. ERPNext API Payload Blueprints (v15 JSON)

### 4.1 Marketplace Checkout - Sales Order Object Structure

```json
{
  "doctype": "Sales Order",
  "customer": "CUST-YEM-2026-00412",
  "transaction_date": "2026-09-01",
  "order_type": "Sales",
  "currency": "USD",
  "selling_price_list": "Standard Selling",
  "items": [
    {
      "item_code": "CN-ELECTRONICS-SKU892",
      "qty": 250,
      "rate": 14.25,
      "warehouse": "China TST Warehouse - MS"
    }
  ]
}
```

### 4.2 Final Shipping & Customs Settlement - Sales Invoice Object Structure

```json
{
  "doctype": "Sales Invoice",
  "customer": "CUST-YEM-2026-00412",
  "posting_date": "2026-09-01",
  "currency": "USD",
  "update_stock": 0,
  "cost_center": "CONTAINER-MSCU-992831",
  "items": [
    {
      "item_code": "LOGISTICS-LCL-OCEAN-FREIGHT",
      "qty": 4.250,
      "rate": 220.00,
      "description": "Ocean Freight Services based on 4.250 CBM calculated capacity cargo volume."
    },
    {
      "item_code": "YEMEN-CUSTOMS-CLEARANCE-PORT-TAX",
      "qty": 1,
      "rate": 185.50,
      "description": "Pro-rata shared portion distribution of Yemen entry seaport terminal clearance fees."
    }
  ]
}
```

> **Note:** The `cost_center` field (`CONTAINER-MSCU-992831`) demonstrates per-voyage Profit/Loss clarity — cost centers are named after the specific Container UUID, enabling automated P&L per voyage.

### 4.3 Payload Field-to-Table Binding

| Payload Field | Source Table/Column | Purpose |
|---------------|--------------------|---------|
| `customer` | `cargo_shipments.erp_customer_code` | ERPNext Customer binding |
| `item_code` | `marketplace_catalog.sku` | Curated SKU mapping |
| `rate` | `marketplace_catalog.factory_price_cny` → converted | USD markup engine output |
| `qty` / `calculated_cbm` | `cargo_shipments.calculated_cbm` | Volume-based LCL billing |
| `cost_center` | `logistics_containers.container_number` | Per-container P&L isolation |

### 4.4 Admin / ACL Payloads (OP-04) — Employees, Users & Roles

Payloads below are emitted by the **Admin Console** (OP-04) to provision ERPNext financial/HR objects and are recorded in `acl_sync_log`.

**Create Employee (source: `employees`)**

```json
{
  "doctype": "Employee",
  "employee_name": "Ahmed Saleh Al-Shami",
  "employee_number": "EMP-YEM-001",
  "company": "Yemen Shipping Co",
  "department": "Port Operations",
  "designation": "Yemen Port Operator",
  "gender": "Male",
  "date_of_joining": "2026-07-01",
  "status": "Active"
}
```

**Create Cost Center on Branch Provision (source: `branches`)**

```json
{
  "doctype": "Cost Center",
  "cost_center_name": "ADEN-PORT-OPS",
  "parent_cost_center": "Yemen Corp",
  "is_group": 0,
  "company": "Yemen Shipping Co"
}
```

**Create User + Role Assignment (source: `user_accounts` + `user_branch_roles`)**

```json
{
  "doctype": "User",
  "email": "ops.aden@shipping.com",
  "first_name": "Ahmed",
  "last_name": "Al-Shami",
  "roles": [
    { "role": "Yemen Port Operator" },
    { "role": "Delivery Scanning" }
  ],
  "enabled": 1
}
```

**Pull Permissions (IN direction — ERPNext authority → platform `permission_matrix`)**

```
GET /api/resource/Role/{role_name}
    → role_permissions translated into platform permission_matrix rows
```

### 4.5 ACL Payload Field-to-Table Binding

| Payload | Source Table | ERPNext Target |
|---------|--------------|----------------|
| `employee_number` / `employee_name` | `employees` | `Employee` doc |
| `cost_center_name` | `branches` (branch → cost center rule) | `Cost Center` |
| `email` / `first_name` | `user_accounts` / `employees` | `User` doc |
| `roles[]` | `user_branch_roles` → `platform_roles.erpnext_role` | ERPNext `User Role` |

---

## 5. Failsafe Mechanisms & Anti-Duplication Guardrails

### 5.1 Idempotency Keys

To prevent systemic double-billing, double-counting of volume capacities, and overlapping accounting entries, all backend requests targeting ERPNext endpoints require an **Idempotency Key** header calculated via **MD5 hash** over string values unique to the transaction payload.

```http
POST /api/resource/Sales%20Invoice
Content-Type: application/json
Idempotency-Key: md5("CUST-YEM-2026-00412|CONTAINER-MSCU-992831|2026-09-01|4.250")
Authorization: token <api_key>:<api_secret>
```

**Rule:** The key is derived from the concatenation of customer code + container UUID + posting date + payload total. Replayed requests with identical keys are rejected at the gateway before reaching ERPNext.

### 5.2 Async Queue Retry with Exponential Backoff

If a transaction fails midway due to network dropout or server downtime across seaport nodes in Yemen, network brokers buffer payloads within a non-volatile **Celery Async Queue backed by Redis**, which retries delivery up to **5 times** using exponential backoff scaling intervals.

```
Attempt 1  → 2s delay
Attempt 2  → 4s delay
Attempt 3  → 8s delay
Attempt 4  → 16s delay
Attempt 5  → 32s delay  (then dead-letter queue / admin alert)
```

### 5.3 Failure Categories & Handling

| Failure Type | Detection | Handling Strategy |
|--------------|-----------|-------------------|
| Network dropout (seaport nodes) | Request timeout / connection reset | Celery retry with exponential backoff |
| Server downtime (ERPNext) | 5xx / connection refused | Buffer in Redis, retry, dead-letter after 5 attempts |
| Duplicate payload | Idempotency-Key collision | Reject at gateway, escalate to audit log |
| Validation error (schema) | 4xx from ERPNext | Do NOT retry — route to manual review queue |

### 5.4 Celery Worker Configuration Reference

```python
# config for celery workers (planned services/erpnext_sync.py)
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/1"

ERPNEXT_SYNC_RETRIES = 5
ERPNEXT_SYNC_BACKOFF_BASE = 2    # seconds
ERPNEXT_SYNC_BACKOFF_MAX = 32    # seconds
IDEMPOTENCY_KEY_ALGO = "md5"
```

---

## 6. Environment Configuration (ERPNext Integration)

Refer to `01_database_setup/.env.example` for the live ERPNext connection settings:

```env
# ERPNEXT CONFIGURATION
ERPNEXT_URL=http://localhost:8000
ERPNEXT_API_KEY=your_erpnext_api_key_here
ERPNEXT_API_SECRET=your_erpnext_api_secret_here
ERPNEXT_DOCTYPE_PREFIX=Shipping-
```

---

*CONFIDENTIAL - Internal Technical Documentation*
