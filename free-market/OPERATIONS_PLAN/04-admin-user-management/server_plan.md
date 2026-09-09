# OP-04: Server Plan — Admin Console, Employees & Role-Based Permissions

**Operation:** OP-04 | **Workstream D (Administration)** | **Phase 1 setup + ongoing**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the **Admin console service** that owns platform identities, roles, branch scope and access policies. ERPNext provisioning is an optional integration side effect; ERPNext remains authoritative only for permissions inside ERPNext itself.

---

## 2. Service Architecture

```
FastAPI Admin Instance :8003
├── routes/
│   ├── branches.py          (branch CRUD + ERPNext cost center/warehouse sync)
│   ├── employees.py         (employee registration)
│   ├── users.py             (user accounts + password reset)
│   ├── roles.py             (platform role management)
│   ├── permissions.py       (permission matrix viewer)
│   └── erpnext_provisioning.py (optional employee/user provisioning)
├── services/
│   ├── rbac_service.py      (role resolution → JWT claims)
│   ├── erpnext_provisioning.py (optional ERPNext Employee/User sync)
│   └── audit_service.py     (trail writer)
├── workers/
│   └── account_provisioner.py (Celery: optional ERPNext account provisioning)
├── models/
└── config.py
```

---

## 3. REST Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/admin/branches` | **SYSTEM-ADMIN** | Create branch → enqueue ERPNext Cost Center + Warehouse |
| `GET` | `/api/admin/branches` | admin/manager | List branches + ERPNext mapping |
| `PUT` | `/api/admin/branches/{code}` | **SYSTEM-ADMIN** | Update branch → ERPNext mirror |
| `POST` | `/api/admin/employees` | admin | Register employee → enqueue ERPNext Employee |
| `GET` | `/api/admin/employees` | admin/manager | List employees (branch-scoped) |
| `POST` | `/api/admin/users` | admin | Create user account + ERPNext User |
| `POST` | `/api/admin/users/{id}/password-reset` | admin/self | Password rotation (bcrypt) |
| `POST` | `/api/admin/users/{id}/roles` | admin | Assign `user_branch_roles` → ERPNext User Role |
| `DELETE` | `/api/admin/users/{id}/roles/{a}` | admin | Revoke role → ERPNext User Role removal |
| `GET` | `/api/admin/roles` | admin | Browse synced `platform_roles` |
| `POST` | `/api/admin/erpnext/provision` | **SYSTEM-ADMIN** | Provision approved employee/user data when required |
| `GET` | `/api/admin/erpnext/provision/{id}` | admin | Provisioning status + errors |
| `GET` | `/api/admin/audit` | **SYSTEM-ADMIN** | Privilege-change audit trail |

> **Branch scoping:** `GET` list endpoints apply a branch filter derived from the caller's JWT `branch_id` — employees/roles are only visible within authorized branches.

---

## 4. Core Services

### 4.1 `rbac_service.py` — Role Resolution → JWT

```python
def build_claims(user_id):
    roles = db.query(UserBranchRole, PlatformRole).join(...)  # scoped to active branch
    perms  = resolve_permission_matrix(roles)                  # flattened resource→actions
    return {"sub": user_id, "branches": [...], "roles": [...], "perms": perms,
            "token_version": user_account.token_version}
```

- Every FastAPI instance (OP-01/02/03/04) validates tokens and enforces `perms` via dependency guards
- On role change → `token_version += 1` → all prior tokens invalid
- On branch deactivation → assignments expire → tokens re-validated

### 4.2 `erpnext_provisioning.py` — Optional Accounting-System Provisioning

Handles optional provisioning with ERPNext v15:

| Local Action | ERPNext Target | Direction |
|--------------|----------------|-----------|
| Create branch | `Cost Center` + `Warehouse` | OUT |
| Create employee | `Employee` doc | OUT |
| Create user | `User` doc (+ email verification) | OUT |
| Assign role | `User Role` list on ERPNext User | OUT |
| Pull ERPNext roles | Not used to grant platform access | NONE |
| Deactivate account | Disable `User` in ERPNext when provisioned | OUT |

### 4.3 `audit_service.py` — Immutable Trail

Every privilege mutation writes to `acl_sync_log` + a human-readable audit entry with `(actor, actor_ip, action, entity, before, after)`.

---

## 5. RBAC Enforcement Points (Cross-Service)

| Operation | Guard Assertion |
|-----------|-----------------|
| OP-01 catalog write (vendor) | `perms.catalog.update` + branch = CHN |
| OP-01 checkout | `perms.orders.create` |
| OP-02 telemetry override | `perms.tracking.update` |
| OP-02 shipment create | `perms.shipments.create` |
| OP-03 outbox retry | `perms.outbox.update` |
| OP-04 user provisioning | `perms.users.create` + SYSTEM-ADMIN |

**Enforcement is centralized** as a shared guard package published to all FastAPI instances — no service invents its own permission logic (prevents ACL drift from ERPNext).

---

## 6. Background Tasks (Celery)

| Worker | Schedule / Trigger | Function |
|--------|--------------------|----------|
| `account_provisioner` | event | Create ERPNext Employee/User only after local approval |

---

## 7. Error Handling

| Error | Handling |
|-------|----------|
| ERPNext down during branch create | Local branch saved, sync queued in `acl_sync_log` (PENDING) |
| Employee email already in ERPNext | Map existing docname — no duplicate creation |
| Password reset | bcrypt rehash + token_version bump (force relogin) |
| ERPNext provisioning conflicts | Resolve by the local-to-ERP mapping key |
| Deactivated user attempts login | Reject, clear token, audit log |

---

## 8. Deployment Runbook

1. Apply OP-04 admin schema (extends Phase 1 schema)
2. Deploy FastAPI admin instance on `:8003`
3. Configure ERPNext credentials in `.env`
4. Seed platform roles and permissions from the versioned OP-04 policy set
5. Start Celery ACL workers + Redis broker
6. Bind admin web dashboard (Flutter Web / `frontend/`)
7. Register shared RBAC guard package on OP-01/02/03 instances

---

*Sub-plan of OPERATIONS_PLAN — Confidential*