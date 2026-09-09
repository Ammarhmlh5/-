# PROJECT PLAN: INTEGRATED SHIPPING & B2B MARKETPLACE SYSTEM

## PROJECT IMPLEMENTATION MASTER PLAN

**Comprehensive Blueprint for Cross-Border B2B Marketplace, Independent Logistics Tracking & ERPNext Unified Infrastructure (China - Yemen Route)**

---

**Authors:** Core Development Duo  
**Tech Stack:** Python (FastAPI), PostgreSQL (PostGIS), Flutter Framework  
**Integration Core:** ERPNext REST API Async Bus  
**Target Domain:** International Logistics & Curated Sourcing  
**Date of Release:** September 2026

---

## 1. Executive Summary & Core Architecture Strategy

This project master plan outlines the engineering blueprint to build a scalable, highly secure, and structurally isolated cross-border supply chain platform. The architecture purposely decouples front-facing operations—namely the B2B Marketplace and the Independent Logistics Management System—from the sensitive financial ledger, ERPNext. By hosting independent FastAPI instances powered by robust PostgreSQL databases, the platform maximizes throughput, safeguards accounting databases from intense customer tracking queries, and handles local logistics vulnerabilities smoothly.

### Key Objectives:

- **Isolated Environments:** Zero direct marketplace/tracking DB execution on ERPNext database layers.
- **High-Performance Sync:** Microservices leverage background task runners to pass verified payloads to ERPNext asynchronously.
- **Curated Sourcing:** Contracted Chinese vendors manage live stock catalogs natively, shifting operational weight outwards.
- **Resilient Yemeni Workflows:** Mobile apps embed local storage layers to function in completely offline port environments.

---

## 2. Project Workstreams & Technical Breakdowns

### Workstream A: Curated B2B Marketplace Platform

Responsible for handling client interactions in Yemen and stock entries from China. The marketplace does not allow open public registry; it operates as a curated catalog utilizing strict SKU variants mapped to contracted factories. Features dynamic markup algorithms written in Python that ingest current factory wholesale rates in Chinese Yuan (CNY) and render final, inclusive pricing in US Dollars (USD) to merchants.

**Current Implementation:**
- `backend/routes/customers.py` - Customer management endpoints
- `backend/routes/shipments.py` - Shipment creation and tracking
- `frontend/lib/main.dart` - Flutter mobile application

**Database Schema:**
- `customers` - Client registry with ERPNext mapping
- `shipments` - Order management with container tracking
- `shipments_items` - SKU-level product catalog items

### Workstream B: Independent Logistics & AIS Vessel Tracking

An autonomous operations suite executing real-time spatial telemetry processing. Utilizes PostGIS extensions within PostgreSQL to store vessel coordinates. Employs background Celery workers that poll shipping lines' endpoints on strict throttling intervals to prevent IP bans, while enabling container-level status overrides (LCL grouping vs FCL flat-rate routing).

**Current Implementation:**
- `backend/routes/tracking.py` - Tracking event management
- `01_database_setup/create_tables.sql` - PostGIS-ready schema with spatial fields

**Database Schema:**
- `containers` - Container registry with tracking data (JSONB)
- `tracking_events` - Spatial telemetry with latitude/longitude
- `shipping_lines` - Carrier integration endpoints
- `ports` - Global port registry

### Workstream C: Async ERPNext Financial Integration Bus

The system's financial core. Acts as a secure gatekeeper. It processes outbound JSON payloads from operations to spin up Sales Orders, Purchase Invoices, and Cost Center lines mapped directly to specific Container UUIDs for absolute automated profit/loss clarity per voyage.

**Current Implementation:**
- ERPNext field mappings in `branches`, `customers`, `shipments`, `invoices`, `payments` tables
- Cost center and warehouse ID references throughout schema

**Database Schema:**
- `invoices` - Financial document sync with ERPNext
- `payments` - Payment processing with exchange rate tracking
- `branches` - Cost center and warehouse mappings

### Workstream D: Admin Console, Employees & Role-Based Permissions

Governance layer for all operations. Provides an administrative interface to create **branches** and register **employees**, provision user accounts, and assign **roles/permissions that are defined and enforced from the accounting system (ERPNext)**. Roles and permission rules live in ERPNext as the single authority and are synchronized into the platform enforcement layer; branches, employees, and users are mirrored up to ERPNext financial objects (Cost Center, Warehouse, Employee, User). A shared JWT RBAC guard enforces the same grants across every FastAPI instance — no operation invents its own ACL.

**Implementation:**
- `OPERATIONS_PLAN/04-admin-user-management/` - Full sub-plan (database, server, architecture)

**Database Schema:**
- `branches` - Branch registry with ERPNext Cost Center/Warehouse mapping
- `employees` - Employee registry tied to ERPNext Employee docs
- `user_accounts` - Platform logins (bcrypt) with ERPNext User binding
- `platform_roles` / `user_branch_roles` - ERPNext-synced role mirror + branch-scoped assignments
- `permission_matrix` - Resource×Action matrix mirrored from ERPNext permissions
- `acl_sync_log` - Immutable role/account synchronization trail

---

## 3. Implementation Roadmap & Gantt Schedule

The execution roadmap spans 16 weeks, allocated across the two core developers and supplementary engineering staff. The project operates on a strict test-driven delivery paradigm, ensuring integration buses are fully simulation-tested prior to user interface binding.

| Phase & Scope | Duration | Core Deliverables & Milestones |
|---------------|----------|--------------------------------|
| **Phase 1: Core Infrastructure & DB Schema** | Weeks 1 - 3 | Setup PostgreSQL with PostGIS extensions. Define unified schemas for items, shipments, and billing logs. Initialize FastAPI base apps. |
| **Phase 2: Marketplace Backend & Vendor Portal** | Weeks 4 - 6 | Build Chinese Vendor interface for stock/catalog entry. Develop currency conversion engine (CNY to USD). Bind local caching layers via Redis. |
| **Phase 3: Logistics System & AIS Tracking Engine** | Weeks 7 - 10 | Deploy Celery workers for vessel telemetry syncing. Build LCL package volume calculators and barcode thermal printing bridges. |
| **Phase 4: Async ERPNext REST Integration Bus** | Weeks 11 - 13 | Secure API endpoints with JWT tokens. Map automatic webhook listeners for Sales Orders, Invoices, and Container-level Cost Centers. |
| **Phase 5: Cross-Platform Flutter UI Integration** | Weeks 14 - 15 | Compile unified Flutter codebases into responsive Web dashboards for China/Yemen hubs, and native Android/iOS apps for Yemeni clients. |
| **Phase 6: QA, Penetration Testing & Go-Live** | Week 16 | Execute multi-tenant connection load tests. Conduct offline SQLite database synchronization audits in unstable network mockups. Deploy. |

---

## 4. Technical Architecture

### 4.1 Backend Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Application                       │
├─────────────────────────────────────────────────────────────┤
│  Routes Layer                                                │
│  ├── customers.py    (Customer CRUD & ERPNext Sync)         │
│  ├── shipments.py    (Shipment Management)                  │
│  └── tracking.py     (Tracking Events)                      │
├─────────────────────────────────────────────────────────────┤
│  Services Layer (Planned)                                    │
│  ├── erpnext_sync.py (Async ERPNext Integration)            │
│  ├── currency.py     (CNY/USD Conversion Engine)            │
│  └── vessel_tracker.py (AIS Telemetry Processing)           │
├─────────────────────────────────────────────────────────────┤
│  Models Layer (SQLAlchemy ORM)                               │
│  └── __init__.py     (Model Definitions)                    │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL + PostGIS Database                               │
│  └── 13 Tables with UUID PKs, JSONB, Spatial Indexes        │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Database Schema (13 Tables)

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `branches` | China/Yemen offices | ERPNext cost_center_id, warehouse_id |
| `warehouses` | Storage locations | Hierarchical parent_warehouse_id |
| `customers` | Client registry | erpnext_customer_id sync |
| `shipments` | Order management | UUID shipment_number, status workflow |
| `containers` | Container tracking | JSONB tracking_data, type validation |
| `tracking_events` | Spatial telemetry | latitude/longitude, event_type |
| `invoices` | Financial sync | erpnext_invoice_id, cost_center_id |
| `payments` | Payment processing | exchange_rate, payment_method |
| `users` | Authentication | role-based permissions JSONB |
| `shipments_items` | SKU catalog | unit_price, weight, volume |
| `shipping_lines` | Carrier integration | api_endpoint, tracking_url_template |
| `ports` | Global ports | country, city, port codes |
| `audit_logs` | Security trail | old_values/new_values JSONB |

### 4.3 Frontend Stack (Flutter)

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
├─────────────────────────────────────────────────────────────┤
│  Dependencies:                                               │
│  ├── http: ^1.1.0          (API Communication)              │
│  ├── provider: ^6.1.1      (State Management)               │
│  ├── intl: ^0.18.1         (Localization AR/EN)             │
│  └── shared_preferences    (Local Storage/Offline)          │
├─────────────────────────────────────────────────────────────┤
│  Target Platforms:                                           │
│  ├── Android (Yemeni clients)                                │
│  ├── iOS (Yemeni clients)                                    │
│  └── Web (China/Yemen admin dashboards)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Risk Mitigation Matrix (Technical & Logistical)

Deploying technical infrastructure across volatile geographic corridors requires preemptive defensive programming and strict operational constraints.

| Identified Threat Context | Architectural Defense / Mitigation Protocol |
|---------------------------|---------------------------------------------|
| **Carrier Scraping Blocks:** Tracking bots get blocked or rate-limited by global maritime liners (e.g., MSC, Maersk). | Deploy decentralized, proxy-rotating Celery scrapers. Cache location outputs in Redis for 4-6 hours to minimize redundant remote network hits. |
| **Yemeni Port Blackouts:** Total drop in data connectivity at customs yards during offloading scans. | Configure Flutter apps with reactive internal SQLite database layers. Queue warehouse barcode actions locally; sync when handshakes resume. |
| **Currency Fluctuations:** Rapid shifts in Rial value against Chinese Yuan during the 30-day shipping voyage. | Enforce USD/CNY base transaction rules inside ERPNext ledger cores. Expose dynamic conversion tables updated daily at point-of-collection in Yemen. |
| **Factory Product Defect Risks:** Chinese vendors supplying damaged cargo to Yemeni buyers. | Mandate quality control gate checks inside China Hub interface. Warehousemen execute live image uploads cross-referenced with vendor digital order sheets. |

---

## 6. API Endpoints (Current Implementation)

### Base URL: `http://localhost:5000`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | System status check |
| `GET` | `/health` | Health check endpoint |
| `GET` | `/api/customers` | List all customers |
| `POST` | `/api/customers` | Create new customer |
| `GET` | `/api/shipments` | List all shipments |
| `POST` | `/api/shipments` | Create new shipment |
| `GET` | `/api/tracking/{shipment_id}` | Get tracking events |

---

## 7. Environment Configuration

### Database (.env)
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/shipping_system
SECRET_KEY=dev-secret-key-change-in-production
```

### Docker Compose Services
- **PostgreSQL 15** with PostGIS extensions
- **Redis** for caching (planned)
- **Celery** workers for async tasks (planned)

---

## 8. Operations Sub-Plans

Each operation has a granular sub-plan covering database, server, and architecture. See the **[`OPERATIONS_PLAN/`](OPERATIONS_PLAN/README.md)** directory:

| Operation | Directory | Database Plan | Server Plan | Architecture |
|-----------|-----------|---------------|-------------|--------------|
| **OP-01** Curated B2B Marketplace | [`01-marketplace-b2b/`](OPERATIONS_PLAN/01-marketplace-b2b/) | [database_plan.md](OPERATIONS_PLAN/01-marketplace-b2b/database_plan.md) | [server_plan.md](OPERATIONS_PLAN/01-marketplace-b2b/server_plan.md) | [architecture.md](OPERATIONS_PLAN/01-marketplace-b2b/architecture.md) |
| **OP-02** Logistics & AIS Tracking | [`02-logistics-tracking/`](OPERATIONS_PLAN/02-logistics-tracking/) | [database_plan.md](OPERATIONS_PLAN/02-logistics-tracking/database_plan.md) | [server_plan.md](OPERATIONS_PLAN/02-logistics-tracking/server_plan.md) | [architecture.md](OPERATIONS_PLAN/02-logistics-tracking/architecture.md) |
| **OP-03** Async ERPNext Integration Bus | [`03-erpnext-integration/`](OPERATIONS_PLAN/03-erpnext-integration/) | [database_plan.md](OPERATIONS_PLAN/03-erpnext-integration/database_plan.md) | [server_plan.md](OPERATIONS_PLAN/03-erpnext-integration/server_plan.md) | [architecture.md](OPERATIONS_PLAN/03-erpnext-integration/architecture.md) |
| **OP-04** Admin Console, Employees & RBAC | [`04-admin-user-management/`](OPERATIONS_PLAN/04-admin-user-management/) | [database_plan.md](OPERATIONS_PLAN/04-admin-user-management/database_plan.md) | [server_plan.md](OPERATIONS_PLAN/04-admin-user-management/server_plan.md) | [architecture.md](OPERATIONS_PLAN/04-admin-user-management/architecture.md) |

> **Note:** Branches, employees, user accounts, and their roles/permissions are managed through the **OP-04 Admin Console**. Roles and permission rules are defined in the accounting system (ERPNext) and synchronized to the platform for enforcement — see the OP-04 sub-plan for the full RBAC model.

---

## 9. Resource Allocation & Project Sign-off

By adhering strictly to this blueprint and its operation-level sub-plans, the development team maintains optimal structural velocity while avoiding enterprise feature creep. The system is designed to launch as a minimal viable ecosystem at Week 16, transitioning immediately into revenue operations.

---

**Lead Software Architect**

__________________________

**Operations Director (China/Yemen)**

__________________________

---

*Confidential - For Internal Development Team Use Only*
