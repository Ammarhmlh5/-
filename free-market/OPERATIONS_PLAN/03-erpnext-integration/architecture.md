# OP-03: Architecture — Async ERPNext Financial Integration Bus

**Operation:** OP-03 | **Workstream C** | **Phase 4 (Weeks 11-13)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Component Overview

```
┌────────────────────┐   ┌────────────────────┐
│  OP-01 Marketplace │   │  OP-02 Logistics   │
│  (orders, PAID)    │   │  (customs, delivery)│
└─────────┬──────────┘   └─────────┬──────────┘
          │  enqueue (internal JWT) │
          └──────────┬──────────────┘
                     ▼
┌──────────────────────────────────────────────────────────────────────┐
│        ✦ OP-03 INTEGRATION GATEWAY (FastAPI :8002) ✦                │
│   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   │
│   │ Sales Order API │   │ Purchase Inv API│   │ Sales Invoice   │   │
│   └────────┬────────┘   └────────┬────────┘   │ API             │   │
│            │                     │             └────────┬────────┘   │
│   ┌────────▼─────────────────────▼──────────────────────▼────────┐  │
│   │          services/                                           │  │
│   │   erpnext_client + idempotency + retry_policy                │  │
│   └────────┬───────────────────────────────────────────────────────┘  │
└────────────┬───────────────────────────────────────────────────────────┘
             │
   ┌─────────▼─────────┐        ┌──────────────────┐
   │ integration_outbox│        │  Redis Broker /  │
   │  (PostgreSQL)     │        │  Celery Queue    │
   │  idempotency/audit│        └────────┬─────────┘
   └─────────┬─────────┘                 │
             │ drain (Celery outbox_sender)
             ▼
   ┌───────────────────────────────────────────────┐
   │        HTTPS + JWT + Idempotency-Key          │
   │                    ▼                          │
   │   ┌────────────────────────────────────────┐  │
   │   │        ERPNext v15 (Financial Core)    │  │
   │   │  Sales Order / Purchase Invoice /      │  │
   │   │  Sales Invoice / Cost Centers / Ledger │  │
   │   └────────────────────────────────────────┘  │
   │        ▲                              │        │
   │        └──── webhook events ──────────┘        │
   └───────────────────────────────────────────────┘
```

---

## 2. Data Flow Narrative

1. **Catalog, customer/order and logistics services** emit an approved financial command with a computed **idempotency key** (SHA-256).
2. The gateway persists the payload to `integration_outbox` (`status=PENDING`).
3. **Celery `outbox_sender`** drains pending rows → `HTTP POST` to ERPNext over HTTPS with JWT auth.
4. On **success** → `status=DONE`, store `erp_document_name`, write `integration_audit`.
5. On **failure** → `status=FAILED`, increment attempt, retry with **exponential backoff** (max 5), then `DEADLETTER` → admin alert.
6. **ERPNext webhooks** (invoice/payment updates) are consumed by `webhook_listener` and reflected back to `erp_entity_map` and the owning operational service.

---

## 3. Security Boundaries

| Boundary | Enforcement |
|----------|-------------|
| External apps → ERPNext DB | **Blocked** — no direct read/write |
| Outbound payloads | JWT service tokens + TLS |
| Duplicate ledger entries | Idempotency-Key guard (409 on collision) |
| Credentials | Stored in a secret manager or protected runtime configuration |
| Payload integrity | Canonical SHA-256 key + full payload audit trail |

---

## 4. Failure Handling Design

- **Network dropout (seaport nodes)** → Celery buffering in Redis + retry backoff.
- **Server downtime (ERPNext)** → payload retained in outbox; retried; then DEADLETTER alert.
- **Empty/validation error** → 4xx, no retry, manual review queue.
- **Duplicate payload** → existing ERPNext document is returned for the same key; no second accounting document is created.

---

## 5. P&L Clarity per Voyage

Cost Centers are named after **Container UUIDs** (e.g., `CONTAINER-MSCU-992831`), tying every outbound financial line to a specific container for absolute automated profit/loss clarity per voyage.

| Financial Object | Map-to |
|------------------|--------|
| Sales Order | `erp_entity_map` (order ref) |
| Purchase Invoice | `suppliers_china` (supplier payout) |
| Sales Invoice | container cost center + customer |
| Expense Claim | container + customs amount |

---

## 6. Frontend Bindings

- No direct frontend; consumed via internal APIs only (dashboard read of `integration_outbox` status for ops visibility).

---

## 7. Out-of-Scope (Deferred to Other Ops)

- Catalog/orders → **OP-01**
- Container/vessel tracking → **OP-02**

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
