# OP-04: Database Plan — Admin Console, Employees & Role-Based Permissions

**Operation:** OP-04 | **Workstream D (Administration)** | **Phase 1 setup + ongoing across all phases**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the administration database that powers the **Admin Console** — the interface for creating branches, registering employees, provisioning user accounts, and controlling platform RBAC. Platform roles and permissions are owned here. ERPNext receives optional employee/user provisioning when required by accounting or HR; it is not the authority for customer, supplier or platform access policies.

---

## 2. Isolation & Security

- Dedicated identity/admin schema within the operations PostgreSQL
- **OP-04 is the platform role/permission authority**; ERPNext permissions apply only inside ERPNext
- Passwords stored only as bcrypt hashes; never transmitted outside the admin service
- Every privilege change is written to an immutable audit trail

---

## 3. Role & Permission Model (Platform-Driven)

```
Platform (Authority)                         ERPNext (Optional Mirror)
platform_roles + permission_matrix ───────► ERPNext users/roles when required
          │                              
          └──────────────► JWT claims and route guards
```

| Design Rule | Description |
|-------------|-------------|
| **Single source of truth** | Platform roles/permissions are created and approved in OP-04; ERPNext roles are managed separately for ERPNext access |
| **Branch scoping** | A user is granted roles **per branch** (`user_branch_roles`) — e.g., YEM branch operator cannot touch CHN data |
| **No orphan users** | Every user account must belong to an `employees` record |
| **Auto-revoke** | Deactivating an employee (or ERPNext user) revokes all live tokens immediately (token version bump) |

---

## 4. Tables Specification

### 4.1 `branches` — Branch Registry (extended from Phase 1)

```sql
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(10) NOT NULL UNIQUE,          -- CHN, YEM
    country VARCHAR(50) NOT NULL,
    erpnext_cost_center VARCHAR(100),          -- ERPNext Cost Center docname
    erpnext_warehouse VARCHAR(100),            -- ERPNext Warehouse docname
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

> Aligned with existing `01_database_setup/create_tables.sql` (`branches` table). The admin console drives row CRUD here.

### 4.2 `employees` — Employee Registry

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50) UNIQUE NOT NULL,      -- e.g. EMP-CHN-001
    full_name VARCHAR(200) NOT NULL,
    full_name_ar VARCHAR(200),
    job_title VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    branch_id UUID REFERENCES branches(id),
    erpnext_employee VARCHAR(100),                  -- ERPNext Employee docname
    department VARCHAR(100),
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employees_branch ON employees(branch_id);
CREATE INDEX idx_employees_code ON employees(employee_code);
```

### 4.3 `user_accounts` — Platform User Accounts

```sql
CREATE TABLE user_accounts (
    user_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,            -- bcrypt only
    default_branch_id UUID REFERENCES branches(id),
    erpnext_user VARCHAR(100),                      -- ERPNext User docname
    token_version INT DEFAULT 1,                    -- bumped on role change / deactivate
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP
);

CREATE INDEX idx_users_username ON user_accounts(username);
CREATE INDEX idx_users_employee ON user_accounts(employee_id);
```

### 4.4 `platform_roles` — Platform Role Registry

```sql
CREATE TABLE platform_roles (
    role_id SERIAL PRIMARY KEY,
    role_code VARCHAR(50) UNIQUE NOT NULL,          -- e.g. YEM-OPERATOR, CHN-MANAGER
    role_name_ar VARCHAR(100),
    erpnext_role VARCHAR(100),                       -- optional ERPNext mapping
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.5 `user_branch_roles` — Branch-Scoped Role Assignments

```sql
CREATE TABLE user_branch_roles (
    assignment_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES user_accounts(user_id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    role_id INT REFERENCES platform_roles(role_id),
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    UNIQUE(user_id, branch_id, role_id)
);

CREATE INDEX idx_assignments_user ON user_branch_roles(user_id);
CREATE INDEX idx_assignments_branch ON user_branch_roles(branch_id);
```

### 4.6 `permission_matrix` — Resource×Action Matrix (mirrors ERPNext permission rules)

```sql
CREATE TABLE permission_matrix (
    permission_id SERIAL PRIMARY KEY,
    role_id INT REFERENCES platform_roles(role_id),
    resource VARCHAR(50) NOT NULL,                  -- catalog, orders, containers,
                                                    -- tracking, outbox, users, branches
    actions TEXT[],                                 -- {'read'} {'read'} {'create','update'}
    UNIQUE(role_id, resource)
);
```

### 4.7 `acl_sync_log` — ERPNext Provisioning Trail

```sql
CREATE TABLE acl_sync_log (
    sync_id SERIAL PRIMARY KEY,
    entity_type VARCHAR(30) NOT NULL,               -- EMPLOYEE, USER, ROLE, BRANCH, PERMISSION
    local_entity_id VARCHAR(120),
    erpnext_document VARCHAR(120),
    operation VARCHAR(20) NOT NULL,                 -- CREATE, UPDATE, DEACTIVATE, PROVISION
    direction VARCHAR(10) NOT NULL,                 -- OUT (platform to ERPNext)
    status VARCHAR(20) DEFAULT 'PENDING',           -- PENDING, DONE, FAILED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 5. Seed Data (Initial Platform Roles)

Defined and versioned by OP-04:

| platform_role | erpnext_role | Typical Grants |
|---------------|--------------|----------------|
| `SYSTEM-ADMIN` | optional ERPNext Administrator mapping | all resources, all branches |
| `CHN-MANAGER` | China Operations Manager | catalog, orders, outbox, users (CHN) |
| `CHN-VENDOR` | Marketplace Vendor | catalog (own SKUs) |
| `YEM-MANAGER` | Yemen Operations Manager | orders, tracking, containers, outbox (YEM) |
| `YEM-OPERATOR` | Yemen Port Operator | tracking, containers, scan/delivery events |
| `FILTERING-AUDITOR` | Finance Auditor | read-only across invoices/ledger |

---

## 6. Data Flow

```
Admin Console (platform authority)
    platform_roles + permission_matrix ──▶ JWT claims on every platform API
                                                     │
                                                     ▼
Branch create ──OUT─▶ ERPNext Cost Center + Warehouse
Employee create ──OUT─▶ ERPNext Employee + User
Role assignment ──optional OUT─▶ ERPNext User Role add
                                        │
                          acl_sync_log (immutable trail)
```

---

## 7. Migration Strategy

- Extends Phase 1 `branches` + `users` tables in `01_database_setup/create_tables.sql`
- Existing `users.role` column migrates to `user_branch_roles` reference model (keep `role` as legacy fallback during transition)
- Admin schema versioned via Alembic with the marketplace/logistics schemas

---

*Sub-plan of OPERATIONS_PLAN — Confidential*