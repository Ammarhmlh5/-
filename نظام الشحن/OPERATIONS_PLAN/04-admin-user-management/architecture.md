# OP-04: Architecture — Admin Console, Employees & Role-Based Permissions

**Operation:** OP-04 | **Workstream D (Administration)** | **Phase 1 setup + ongoing**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Component Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                    ADMIN CONSOLE (Flutter Web)                        │
│   Branches │ Employees │ User Accounts │ Roles │ Permissions │ Audit   │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │ HTTPS + JWT (SYSTEM-ADMIN scoped)
┌──────────────────────────────▼──────────────────────────────────────────┐
│           ✦ OP-04 ADMIN SERVICE (FastAPI :8003)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────────┐  │
│  │ Branch API   │ │ Employee API │ │  User API    │ │ Roles/Perms   │  │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └───────┬───────┘  │
│  ┌──────▼───────────────▼────────────────▼────────────────────▼──────┐ │
│  │   services/  rbac_service + erpnext_acl_service + audit_service    │ │
│  └──────┬───────────────┬────────────────┬────────────────────────────┘ │
│         │               │                │                              │
│  ┌──────▼───┐    ┌──────▼────────┐   ┌───▼────────────┐                │
│  │  Admin DB│    │ acl_sync_log  │   │ Celery/Redis   │                │
│  │ branches │    │ (immutable)   │   │ acl_rep worker │                │
│  │ employees│    └───────────────┘   └───┬────────────┘                │
│  │ accounts │                            │  OUT (Employee/User/Role)   │
│  │ roles    │                            ▼  IN (Role/perm inventory)   │
│  │ matrix   │                 ┌────────────────────────────┐           │
│  │ audit    │                 │  ERPNext v15 (ACL Authority)│           │
│  └──────────┘                 │  Employee │ User │ Role ✔  │           │
│                               │  Cost Center │ Warehouse   │           │
│                               └────────────────────────────┘           │
└──────────────────────────────────────────────────────────────────────────┘
                              │  JWT with role claims
      ┌───────────┬───────────┼──────────────┬──────────────┐
      ▼           ▼           ▼              ▼              ▼
 OP-01       OP-02       OP-03          OP-04          Frontends
 Marketplace Logistics  Integration    Admin           china_app/
 (RBAC guard)  (RBAC guard) (RBAC guard) (RBAC guard)    yemen_app/
```

---

## 2. Data Flow Narrative

1. **SYSTEM-ADMIN** uses the Admin Console to create a branch. Local `branches` row is created and an OUT sync is enqueued to create the ERPNext `Cost Center` + `Warehouse`.
2. **Employee registration** creates an `employees` row and mirrors an ERPNext `Employee` doc.
3. **User provisioning** creates `user_accounts` (bcrypt) + ERPNext `User`, then role assignments create `user_branch_roles`.
4. **Roles/permissions are pulled from ERPNext** (authority) into `platform_roles` + `permission_matrix` via the Celery ACL worker.
5. The shared **RBAC guard** turns those grants into **JWT claims** consumed by every service — no service rewrites permission logic.
6. Any privilege change bumps `token_version`, invalidating prior tokens and forcing re-authentication.
7. Every step writes an immutable trail in `acl_sync_log` / audit.

---

## 3. Security Boundaries

| Boundary | Enforcement |
|----------|-------------|
| Password storage | bcrypt only; never in logs or ERPNext payloads |
| ERPNext → platform ACL | One-directional authority (roles/permissions) — platform never edits ERPNext role definitions |
| Branch isolation | `user_branch_roles` scoping — CHN users cannot act on YEM rows |
| Revoked user | `token_version` bump + ERPNext `User` disable (OUT) |
| Admin surface | SYSTEM-ADMIN role only; separated console route tree |
| Audit integrity | Append-only `acl_sync_log` + `audit` — no UPDATE/DELETE |

---

## 4. Failure Handling Design

- **ERPNext unreachable on branch create** → local row persists; OUT sync stays PENDING in `acl_sync_log`; retried by Celery.
- **ACL pull conflict** → resolved by `erpnext_role` unique key; duplicate rows merged, audit logged.
- **Forgotten ERPNext role mapped to nothing** → flagged in console for manual mapping (never auto-granted).
- **Deactivated employee still has token** → token_version check rejects at guard layer.

---

## 5. Frontend Binding

| Frontend | Surface |
|----------|---------|
| Admin Console (Flutter Web) | Branches, employees, users, roles, permissions, audit |
| `china_app/` / `yemen_app/` | Consume JWTs issued by OP-04; role-scoped menus |

---

## 6. Out-of-Scope (Deferred to Other Ops)

- Catalog/orders → **OP-01**  ·  Vessel/containers → **OP-02**  ·  Financial ledger commit → **OP-03**

---

*Sub-plan of OPERATIONS_PLAN — Confidential*