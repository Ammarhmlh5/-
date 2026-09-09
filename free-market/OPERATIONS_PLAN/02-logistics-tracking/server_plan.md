# OP-02: Server Plan — Independent Logistics & AIS Vessel Tracking

**Operation:** OP-02 | **Workstream B** | **Phase 3 (Weeks 7-10)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the FastAPI server, Celery worker fleet, and container/vessel telemetry services that operate the independent logistics tracking suite.

---

## 2. Service Architecture

```
FastAPI Logistics Instance :8001
├── routes/
│   ├── containers.py       (container CRUD & status)
│   ├── tracking.py         (live telemetry reads)
│   └── shipments.py        (cargo shipment management)
├── services/
│   ├── vessel_tracker.py   (telemetry ingestion)
│   ├── lcl_calculator.py   (LCL volume computation)
│   └── carrier_client.py   (throttled carrier polling)
├── workers/
│   ├── telemetry_poller.py (Celery periodic scraper)
│   └── status_override.py  (manual container status override)
├── models/
└── config.py
```

---

## 3. REST Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/containers` | staff | List containers w/ live status |
| `POST` | `/api/containers` | staff | Register new container |
| `GET` | `/api/containers/{number}/tracking` | public | Live tracking feed |
| `POST` | `/api/containers/{number}/status` | staff | Manual status override |
| `POST` | `/api/shipments` | staff | Create cargo shipment |
| `GET` | `/api/shipments/{waybill}` | staff | Shipment detail + LCL calc |
| `GET` | `/api/telemetry/{container}` | staff | Raw AIS position history |
| `POST` | `/api/telemetry/refresh/{container}` | staff | Force carrier re-poll |

---

## 4. Core Services

### 4.1 `vessel_tracker.py` — Telemetry Ingestion

- Receives scraped positions from Celery workers
- Writes `geo_location` via PostGIS `ST_SetSRID(ST_MakePoint(lon, lat), 4326)`
- Appends to `tracking_events` (append-only immutable log)
- Optionally supports WebSocket push to live dashboards

### 4.2 `lcl_calculator.py` — LCL Volume Calculator

```
calculated_cbm = Σ (item.volume_cbm * qty)     # summed per cargo
line_freight = freight_cost_usd * (item_cbm / total_cbm)   # pro-rata split
```

| Mode | Billing Basis |
|------|---------------|
| **FCL** (is_full_container_load) | Flat-rate per container |
| **LCL** (shared capacity) | Pro-rata share of `calculated_cbm` |

### 4.3 `carrier_client.py` — Throttled Carrier Polling

- Polls shipping-line endpoints on configured `poll_throttle_seconds`
- **Proxy-rotating** to avoid IP bans
- Caches results in **Redis for 4-6 hours** to reduce redundant network hits
- Degrades gracefully when a carrier blocks the scraper (falls back to cached position)

---

## 5. Background Tasks (Celery)

| Worker | Schedule | Function |
|--------|----------|----------|
| `telemetry_poller` | Every N min (per-line throttle) | Poll carriers, update positions |
| `cache_warmer` | Every 4h | Refresh Redis location cache |

**Throttle Config:**
```python
POLL_THROTTLE_SECONDS = {
    "MAERSK": 3600,   # 1/hour
    "COSCO": 1800,    # 30 min
    "MSC": 3600,
    "EVERGREEN": 7200,
}
REDIS_CACHE_TTL = 6 * 3600  # 4-6 hour location cache
```

---

## 6. Error Handling

| Error | Handling |
|-------|----------|
| Carrier scraping block | Proxy rotation, fall back to Redis cache |
| Network outage | Queue in Celery, retry with throttled backoff |
| PostGIS write failure | Log, park events in dead-letter queue |
| Manual override collision | Version check — reject stale overrides |

---

## 7. Barcode / Thermal Printing Bridge (Phase 3)

- Generate LCL package volume labels + container barcodes
- Output to thermal printers at China warehouse
- Integrate with `tracking_events` for delivery scan verification (OP-03 gate scan)

---

## 8. Deployment Runbook

1. Provision `shipping_logistics` DB with PostGIS
2. Apply schema (`database_plan.md`)
3. Deploy FastAPI instance on `:8001`
4. Start Celery pollers + Redis broker/cache
5. Register carrier credentials + throttles
6. Load-test multi-tenant connection (Week 16)

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
