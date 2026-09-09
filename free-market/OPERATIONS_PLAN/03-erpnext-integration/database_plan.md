# OP-03: Database Plan — Async ERPNext Financial Integration Bus

**Operation:** OP-03 | **Workstream C** | **Phase 4 (Weeks 11-13)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the local integration database that logs, tracks, and deduplicates **approved financial commands** destined for ERPNext. This is **not** a second ledger and must not become a copy of ERPNext accounting data.

---

## 2. Isolation & Security

- Local database: `shipping_integration`
- **Does not** store ERPNext core tables — only sync-state, payloads, and audit trail
- Service-authenticated gateway; ERPNext credentials are supplied through protected configuration, never stored in payloads or application tables
- All writes to ERPNext traverse HTTPS via orchestration proxy

---

## 3. Tables Specification

### 3.1 `integration_outbox` — Outbound Payload Queue Log

```sql
CREATE TABLE integration_outbox (
    outbox_id SERIAL PRIMARY KEY,
    idempotency_key VARCHAR(64) UNIQUE NOT NULL,   -- SHA-256 of canonical command
    doctype VARCHAR(50) NOT NULL,                  -- Sales Order, Sales Invoice...
    payload JSONB NOT NULL,                        -- full ERPNext payload
    status VARCHAR(20) DEFAULT 'PENDING',          -- PENDING, DONE, FAILED, DEAD
    attempt_count INT DEFAULT 0,
    next_attempt_at TIMESTAMP,
    erp_document_name VARCHAR(120),                -- ERPNext assigned name
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose:** Failsafe anti-duplication store. The canonical SHA-256 `idempotency_key` guarantees that a financial command cannot create duplicate ledger documents.

**Indexes:**
```sql
CREATE INDEX idx_outbox_status ON integration_outbox(status);
CREATE INDEX idx_outbox_idem ON integration_outbox(idempotency_key);
CREATE INDEX idx_outbox_next ON integration_outbox(next_attempt_at) WHERE status = 'PENDING';
```

### 3.2 `integration_audit` — Payload Event Audit

```sql
CREATE TABLE integration_audit (
    audit_id SERIAL PRIMARY KEY,
    outbox_id INT REFERENCES integration_outbox(outbox_id),
    action VARCHAR(50) NOT NULL,                   -- SENT, RETRY, REJECTED, DEADLETTER
    attempt INT,
    http_status INT,
    response_summary TEXT,
    actor_reference VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose:** Immutable audit trail for every transit attempt per payload.

### 3.3 `erp_entity_map` — Local↔ERPNext Entity Binding

```sql
CREATE TABLE erp_entity_map (
    map_id SERIAL PRIMARY KEY,
    local_entity_type VARCHAR(50) NOT NULL,        -- CUSTOMER, CONTAINER, SHIPMENT
    local_entity_id VARCHAR(120) NOT NULL,         -- operations UUID / waybill
    erpnext_document VARCHAR(120),                 -- ERPNext customer/sales invoice name
    erpnext_cost_center VARCHAR(120),              -- optional financial dimension
    UNIQUE(local_entity_type, local_entity_id)
);
```

**Purpose:** Maps operations entities (Container UUIDs, waybills, customer codes) to ERPNext documents for per-voyage P&L clarity.

---

## 4. Idempotency Key Derivation

```sql
-- Example for Sales Invoice:
idempotency_key = SHA256(canonical_json(financial_command))
```

| Transaction | Key Components |
|-------------|----------------|
| Customer invoice | customer + approved order + invoice version |
| Supplier invoice | supplier + approved sourcing/shipment cost + invoice version |
| Shipping invoice | customer + shipment + charge version |
| Payment/refund | ERPNext invoice + payment reference + operation |

---

## 5. Data Flow

```
Customer/order, sourcing or logistics services emit an approved financial command
        │
        ▼
integration_outbox (INSERT, status=PENDING, idempotency_key=SHA-256)
        │
        ▼
Celery worker → HTTPS + JWT → ERPNext
        │
   ├─ success → status=DONE, audit=SENT, erp_document_name
   └─ failure → status=FAILED, attempt_count+1
                → retry w/ exponential backoff (max 5)
                → EXHAUSTED → status=DEADLETTER, admin alert
```

---

## 6. Migration Strategy

- Schema primed at Phase 4 before any payload emission
- `integration_outbox` seeded empty; idempotency enforced from day one
- Audit table append-only; archival to cold storage after N days (optional)

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
