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
| **OP-01** | Supplier Catalog & Sourcing Operations | [`01-marketplace-b2b/`](01-marketplace-b2b/) | Phase 2 (Weeks 4-6) | Workstream A |
| **OP-02** | Independent Logistics & AIS Vessel Tracking | [`02-logistics-tracking/`](02-logistics-tracking/) | Phase 3 (Weeks 7-10) | Workstream B |
| **OP-03** | Async ERPNext Financial Integration Bus | [`03-erpnext-integration/`](03-erpnext-integration/) | Foundation + ongoing | Workstream C |
| **OP-04** | Platform Administration & Access Control | [`04-admin-user-management/`](04-admin-user-management/) | Phase 1 setup + ongoing | Workstream D (Administration) |

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
| **A: Supplier Catalog & Sourcing** | OP-01 | Catalog PostgreSQL + object storage | FastAPI module/service #1 |
| **B: Logistics Tracking** | OP-02 | Tracking PostgreSQL (PostGIS) | FastAPI Instance #2 |
| **C: ERPNext Integration** | OP-03 | Integration PostgreSQL (outbox/audit only) | FastAPI Gateway + worker queue |
| **D: Administration & Access** | OP-04 | Identity/admin PostgreSQL | Shared auth/admin module initially |

> **Isolation Guarantee:** No operation ever executes queries directly against the ERPNext database. Operational databases own operational details; ERPNext owns the official ledger. Financial writes traverse OP-03 over HTTPS with service authentication, an outbox, retries, and idempotency keys. Platform access policies are owned by the platform; ERPNext users and roles are provisioned only when an accounting or administration requirement needs them.

---

## 4. Cross-Cutting Dependencies

### Shared Infrastructure
- **PostgreSQL 15** with **PostGIS** extension (see `../01_database_setup/`)
- **Redis** — caching + Celery broker (planned)
- **Celery** — background task runners (planned)
- **JWT** auth layer shared across FastAPI instances

### Inter-Operation Flow
```
OP-01 Catalog/Sourcing ──approved order──▶ Customer/Order API ──cargo──▶ OP-02 Logistics
        │                                      │                         │
        ▼                                      ▼                         ▼
   Catalog DB                         Customer/Order DB              Logistics DB
        └────────────────────────────── financial events ────────────────┘
                                         │
                                         ▼
                                  OP-03 → ERPNext Core

     OP-04 Admin / Access ──platform policies + identity──▶ all operations
     (branches · employees · users · audit; optional ERPNext provisioning)
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

- **Branches & employees** are owned by the platform for operational access and may be provisioned to ERPNext when required for accounting or HR.
- **Roles and permissions for platform operations are defined in OP-04** and enforced locally through shared policy libraries. ERPNext remains authoritative only for its own accounting permissions.
- Supplier and customer users never receive ERPNext credentials.
- Every API surface validates shared identity claims and performs server-side tenant/ownership checks; no client-supplied ID proves ownership.

---

*Confidential - For Internal Development Team Use Only*

**Lead Software Architect** __________________________

**Operations Director (China/Yemen)** __________________________
