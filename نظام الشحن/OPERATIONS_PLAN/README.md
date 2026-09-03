# OPERATIONS PLAN: INTERNAL WORKSTREAM PLANS

**Subsidiary Implementation Plans for the Project Master Plan**

---

**Parent Document:** [`PROJECT_PLAN.md`](../PROJECT_PLAN.md) — Integrated Shipping & B2B Marketplace System Master Plan  
**Blueprint Reference:** [`DATABASE_ERPNEXT_BLUEPRINT.md`](../DATABASE_ERPNEXT_BLUEPRINT.md) — DB Schema & ERPNext Integration  
**Date:** September 2026  
**Version:** 1.0.0

---

## 1. Purpose

This directory houses the granular implementation plan for **each core operation** in the system. While the master plan defines the high-level architecture, roadmap, and risk posture, these sub-plans break each operation down into its three engineering pillars:

1. **Database Plan** — Schema, tables, PostGIS usage, indexes, and data flow
2. **Server Plan** — API endpoints, services, background workers, and deployment
3. **Architecture** — Component diagram, data flow, isolation boundaries, and security

---

## 2. Operations Index

| ID | Operation | Sub-Plan Directory | Phase | Workstream |
|----|-----------|--------------------|-------|------------|
| **OP-01** | Curated B2B Marketplace | [`01-marketplace-b2b/`](01-marketplace-b2b/) | Phase 2 (Weeks 4-6) | Workstream A |
| **OP-02** | Independent Logistics & AIS Vessel Tracking | [`02-logistics-tracking/`](02-logistics-tracking/) | Phase 3 (Weeks 7-10) | Workstream B |
| **OP-03** | Async ERPNext Financial Integration Bus | [`03-erpnext-integration/`](03-erpnext-integration/) | Phase 4 (Weeks 11-13) | Workstream C |
| **OP-04** | Admin Console, Employees & Role-Based Permissions | [`04-admin-user-management/`](04-admin-user-management/) | Phase 1 setup + ongoing | Workstream D (Administration) |

Each operation directory contains three files:

```
01-marketplace-b2b/
├── database_plan.md        # Database schema and data model
├── server_plan.md          # API, services, workers, deployment
└── architecture.md         # Components, data flow, security

02-logistics-tracking/
├── database_plan.md
├── server_plan.md
└── architecture.md

03-erpnext-integration/
├── database_plan.md
├── server_plan.md
└── architecture.md

04-admin-user-management/
├── database_plan.md
├── server_plan.md
└── architecture.md
```

---

## 3. Workstream Mapping

| Workstream | Operations Covered | Independent DB | Independent Server |
|------------|--------------------|----------------|--------------------|
| **A: B2B Marketplace** | OP-01 | Marketplace PostgreSQL (PostGIS) | FastAPI Instance #1 |
| **B: Logistics Tracking** | OP-02 | Tracking PostgreSQL (PostGIS) | FastAPI Instance #2 |
| **C: ERPNext Integration** | OP-03 | Billing/Logging DB (local) | FastAPI Gateway + Celery/Redis |
| **D: Administration & ACL** | OP-04 | Admin RBAC DB (shared infra) | FastAPI Admin Instance + Celery/Redis |

> **Isolation Guarantee:** No operation ever executes queries directly against the ERPNext core database. All financial writes traverse the OP-03 integration bus over HTTPS with JWT + Idempotency keys. Role/permission definitions are owned by ERPNext and synced (IN) to OP-04 for enforcement.

---

## 4. Cross-Cutting Dependencies

### Shared Infrastructure
- **PostgreSQL 15** with **PostGIS** extension (see `../01_database_setup/`)
- **Redis** — caching + Celery broker (planned)
- **Celery** — background task runners (planned)
- **JWT** auth layer shared across FastAPI instances

### Inter-Operation Flow
```
OP-01 Marketplace  ──places order──▶  OP-02 Logistics  ──cargo assign──▶  OP-03 ERPNext
   (catalog/order)                    (container/vessel)                  (finance/ledger)
        │                                   │                                   │
        ▼                                   ▼                                   ▼
   Catalog DB                         Logistics DB                        ERPNext Core

    OP-04 Admin / RBAC ──(roles·perms IN from ERPNext authority)──▶ all operations
    (branches · employees · users · ACL enforcement, OUT to ERPNext objects)
```

### Shared Configuration
- `.env` variables documented in `../01_database_setup/.env.example`
- ERPNext connection settings: `ERPNEXT_URL`, `ERPNEXT_API_KEY`, `ERPNEXT_API_SECRET`

---

## 5. Phase Allocation Reference

| Phase | Scope | Operation(s) | Link |
|-------|-------|--------------|------|
| Phase 1 (Wk 1-3) | Core Infra & DB Schema | — (foundation) + **OP-04** setup begins | `../01_database_setup/README.md`, [04-admin-user-management](04-admin-user-management/) |
| Phase 2 (Wk 4-6) | Marketplace Backend & Vendor Portal | **OP-01** | [01-marketplace-b2b](01-marketplace-b2b/) |
| Phase 3 (Wk 7-10) | Logistics & AIS Tracking | **OP-02** | [02-logistics-tracking](02-logistics-tracking/) |
| Phase 4 (Wk 11-13) | Async ERPNext Integration | **OP-03** | [03-erpnext-integration](03-erpnext-integration/) |
| Phase 5 (Wk 14-15) | Flutter UI Integration + Admin Console UI | Frontend + **OP-04** console | `../frontend/`, `../china_app/`, `../yemen_app/`, [04-admin-user-management](04-admin-user-management/) |
| Phase 6 (Wk 16) | QA, Pen Testing & Go-Live for RBAC + all | All | — |

---

## 6. Document Conventions

Each sub-plan follows a consistent structure for rapid cross-reference:

- **Database Plan** (`database_plan.md`): table-by-table specification, indexes, PostGIS geometry, seed data, migration strategy.
- **Server Plan** (`server_plan.md`): REST endpoints table, service modules, background tasks, error handling, deployment runbook.
- **Architecture** (`architecture.md`): ASCII component diagram, data-flow narrative, security boundaries, and failure-handling design.

---

## 7. Cross-Cutting Security & Governance (OP-04)

All operations enforce access control centrally through **OP-04**:

- **Branches & employees** are provisioned once from the Admin Console and mirrored to ERPNext.
- **Roles & permissions are defined in the accounting system (ERPNext)** and pulled down (`IN`) to the platform as the single authority — the platform never diverges.
- Every API surface (OP-01/02/03/04) validates the shared JWT RBAC claims; no service implements its own ACL.

---

*Confidential - For Internal Development Team Use Only*

**Lead Software Architect** __________________________

**Operations Director (China/Yemen)** __________________________
