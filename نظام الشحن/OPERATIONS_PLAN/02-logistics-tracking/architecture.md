# OP-02: Architecture — Independent Logistics & AIS Vessel Tracking

**Operation:** OP-02 | **Workstream B** | **Phase 3 (Weeks 7-10)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Component Overview

```
                          MARITIME CARRIERS (external)
   ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
   │   Maersk   │  │    MSC     │  │   COSCO    │  │  Evergreen │
   └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
         │               │               │               │
         └───────────────┴───────┬───────┴───────────────┘
                                 │ HTTPS (throttled, proxy-rotating)
                    ┌────────────▼─────────────┐
                    │  Celery telemetry_poller │
                    │  (per-line throttle)      │
                    └────────────┬─────────────┘
                                 │ scrub → cache
                    ┌────────────▼─────────────┐
                    │     Redis Cache 4-6h     │◄─── warp/read fallback
                    └────────────┬─────────────┘
┌────────────────────────────────▼──────────────────────────────────┐
│             ✦ OP-02 LOGISTICS SERVICE (FastAPI :8001) ✦          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Container API│  │  Tracking API│  │  Shipment API│             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
│         │                 │                 │                     │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐             │
│  │ vessel_tracker│  │carrier_client│  │lcl_calculator│             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                 ┌─────────────▼───────────┐
                 │   Logistics DB          │
                 │   shipping_logistics    │
                 │   + PostGIS GEOMETRY    │
                 │   logistics_containers  │
                 │   cargo_shipments       │
                 │   tracking_events       │
                 │   shipping_lines/ports  │
                 └─────────────┬───────────┘
                               │  (customs/delivery events)
┌──────────────────────────────┴────────────────────────────────────┐
│                     OPERATIONS PLAN BUS (OP-03)                    │
│            → Purchase Invoice / Sales Invoice / Ledger             │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow Narrative

1. **Celery pollers** hit carrier endpoints on strict throttles with proxy rotation to avoid IP bans.
2. Raw positions are scrubbed and cached in **Redis (4-6h)** to minimize redundant network hits.
3. The logistics service persists positions into `logistics_containers.geo_location` (PostGIS) and appends to `tracking_events`.
4. **LCL/FCL toggle** (`is_full_container_load`) selects billing basis — LCL uses `lcl_calculator` pro-rata CBM split.
5. On customs release / delivery complete, the service emits events to **OP-03** for the financial ledger.
6. During **port blackouts** in Yemen, mobile apps queue scans locally (SQLite) and sync when connectivity resumes.

---

## 3. Security & Throttle Boundaries

| Boundary | Enforcement |
|----------|-------------|
| Tracking DB → ERPNext | **Blocked** outright |
| Carrier IP ban | Proxy rotation + Redis cache fallback |
| Poll rate abuse | Per-line `poll_throttle_seconds` |
| Public tracking | Read-only, no sensitive financial fields exposed |

---

## 4. Failure Handling Design

- **Carrier down** → serve Redis-cached last known position (max 6h old).
- **PostGIS write failure** → park events in dead-letter, alert worker.
- **Full network blackout (Yemen port)** → Flutter app queues barcode scans in SQLite; batch sync on resume.
- **Celery queue overload** → multiple worker instances horizontally scaled.

---

## 5. Frontend Bindings

| Frontend | Role |
|----------|------|
| `china_app/` | Warehouse intake scans, barcode/thermal printing |
| `yemen_app/` | Client live tracking view, customs/delivery confirmation scans |

---

## 6. Out-of-Scope (Deferred to Other Ops)

- Catalog/orders → **OP-01**
- Financial ledger commit → **OP-03**

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
