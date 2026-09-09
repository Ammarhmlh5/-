# OP-03: Server Plan — Async ERPNext Financial Integration Bus

**Operation:** OP-03 | **Workstream C** | **Phase 4 (Weeks 11-13)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the server-side integration gateway that acts as a **secure gatekeeper** for approved financial commands. Catalog, customer and logistics services never connect directly to ERPNext. Operational events that do not affect a balance remain in their owning databases.

---

## 2. Service Architecture

```
FastAPI Integration Gateway :8002
├── routes/
│   ├── sales_orders.py      (Sales Order creation)
│   ├── purchase_invoices.py (Purchase Invoice for suppliers)
│   ├── sales_invoices.py    (Final shipping/customs settlement)
│   └── webhooks.py          (ERPNext event listeners)
├── services/
│   ├── erpnext_client.py    (ERPNext REST client)
│   ├── idempotency.py       (canonical SHA-256 key + guard)
│   └── retry_policy.py      (exponential backoff)
├── workers/
│   ├── outbox_sender.py     (Celery: drain integration_outbox)
│   └── webhook_listener.py  (Celery: consume ERPNext events)
├── models/
└── config.py
```

---

## 3. REST Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/integration/financial-command` | internal | Validate and enqueue an approved financial command |
| `POST` | `/api/integration/purchase-invoice` | internal | Enqueue Purchase Invoice |
| `POST` | `/api/integration/sales-invoice` | internal | Enqueue Sales Invoice settlement |
| `GET` | `/api/integration/outbox/{id}` | admin | Inspect payload status |
| `POST` | `/api/integration/outbox/{id}/retry` | admin | Manual retry push |
| `GET` | `/api/integration/health` | internal | Bus health check |

> **Internal** = trusted backend services authenticate with service-level credentials; endpoints are not internet-exposed. Customer and supplier clients cannot call this API.

---

## 4. ERPNext Client (`erpnext_client.py`)

Webhook/Client responsibilities against **ERPNext v15 REST API**:

- **Create:** only approved ERPNext documents required by the financial command policy, such as Sales Invoice, Purchase Invoice, Payment Entry, Credit Note and cost dimensions
- **Currency:** Enforce USD/CNY base transaction rules
- **Auth:** `Authorization: token <api_key>:<api_secret>` + TLS

```python
ERPNEXT_URL = os.getenv("ERPNEXT_URL", "http://localhost:8000")
ERPNEXT_API_KEY = os.getenv("ERPNEXT_API_KEY")
ERPNEXT_API_SECRET = os.getenv("ERPNEXT_API_SECRET")
```

---

## 5. Idempotency Guard (`idempotency.py`)

```python
import hashlib

def derive_idempotency_key(*parts: str) -> str:
    raw = "|".join(parts)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()
```

**Flow:** Before enqueue, the bus canonicalizes the command, computes the idempotency key and checks `integration_outbox`. A matching key in `DONE` state returns the existing ERPNext document; it never creates a second document.

---

## 6. Retry Policy (`retry_policy.py`) — Exponential Backoff

| Attempt | Delay |
|---------|-------|
| 1 | 2s |
| 2 | 4s |
| 3 | 8s |
| 4 | 16s |
| 5 | 32s → **DEADLETTER** + admin alert |

Criteria by failure class:
- **Network/5xx** → retry with backoff
- **4xx validation** → do NOT retry; route to manual review queue
- **Duplicate** (idempotency collision) → reject at gateway, escalate to audit

---

## 7. Background Tasks (Celery)

| Worker | Function |
|--------|----------|
| `outbox_sender` | Drain `integration_outbox` PENDING rows → ERPNext |
| `webhook_listener` | Consume ERPNext push events (Sales Order updates, etc.) |
| `deadletter_reaper` | Alert on stuck DEADLETTER payloads |

---

## 8. Deployment Runbook (Phase 4)

1. Provision `shipping_integration` DB (schema in `database_plan.md`)
2. Configure ERPNext credentials via `.env`
3. Deploy FastAPI gateway on `:8002`
4. Start Celery workers + Redis broker
5. Register webhook listeners in ERPNext
6. Run integration simulation TDD suite before UI binding (Week 16 load test)

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
