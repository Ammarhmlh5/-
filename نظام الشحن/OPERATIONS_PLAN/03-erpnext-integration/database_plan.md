# OP-03: Database Plan — Async ERPNext Financial Integration Bus

**Operation:** OP-03 | **Workstream C** | **Phase 4 (Weeks 11-13)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the local billing/audit database that logs, tracks, and deduplicates all outbound JSON payloads destined for ERPNext. This is **not** the ERPNext core database — it is the integration bus's operational logging store that enables idempotency, retry, and audit.

---

## 2. Isolation & Security

- Local database: `shipping_integration_bus`
- **Does not** store ERPNext core tables — only sync-state, payloads, and audit trail
- JWT-secured gateway; no direct ERPNext credentials stored in application DB
- All writes to ERPNext traverse HTTPS via orchestration proxy

---

## 3. Tables Specification

### 3.1 `integration_outbox` — Outbound Payload Queue Log

```sql
CREATE TABLE integration_outbox (
    outbox_id SERIAL PRIMARY KEY,
    idempotency_key VARCHAR(64) UNIQUE NOT NULL,   -- MD5 of payload
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

**Purpose:** Failsafe anti-duplication store. The `idempotency_key` (MD5) guarantees no double-ledger entries.

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
    ip_address VARCHAR(45),
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
    erpnext_cost_center VARCHAR(120),              -- e.g. CONTAINER-MSCU-992831
    UNIQUE(local_entity_type, local_entity_id)
);
```

**Purpose:** Maps operations entities (Container UUIDs, waybills, customer codes) to ERPNext documents for per-voyage P&L clarity.

---

## 4. Idempotency Key Derivation

```sql
-- Example for Sales Invoice:
idempotency_key = MD5(
    CONCAT(erp_customer_code, '|', container_number, '|', posting_date, '|', total_amount)
)
```

| Transaction | Key Components |
|-------------|----------------|
| Sales Order | customer + order_reference + date + total |
| Purchase Invoice | supplier + batch + date + total |
| Sales Invoice | customer + container + date + total |
| Expense Claim | container + customs amount + date |

---

## 5. Data Flow

```
OP-01/OP-02 emit financial event
        │
        ▼
integration_outbox (INSERT, status=PENDING, idempotency_key=MD5)
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
