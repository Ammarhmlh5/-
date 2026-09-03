# OP-02: Database Plan — Independent Logistics & AIS Vessel Tracking

**Operation:** OP-02 | **Workstream B** | **Phase 3 (Weeks 7-10)**  
**Parent:** [OPERATIONS_PLAN/README.md](../README.md)

---

## 1. Purpose

Defines the independent PostgreSQL (with PostGIS) database that stores real-time vessel telemetry, ocean freight container logistics, and cargo shipment distributions. This database is **structurally isolated** from ERPNext and the marketplace database so intense tracking queries never degrade ERPNext accounting performance.

---

## 2. Isolation & Security

- Dedicated database: `shipping_logistics`
- **PostGIS extension** mandatory for spatial telemetry
- Throttled carrier polling — outputs cached in Redis to prevent IP bans
- No direct ERPNext access; only OP-03 receives financial payloads

---

## 3. Tables Specification

### 3.1 `logistics_containers` — Ocean Freight Containers Log

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE logistics_containers (
    container_id SERIAL PRIMARY KEY,
    container_number VARCHAR(50) UNIQUE NOT NULL,  -- ISO e.g. MSCU1234567
    shipping_line VARCHAR(100),                     -- MSC, Maersk, COSCO
    container_size VARCHAR(10),                      -- 20ft, 40ft
    is_full_container_load BOOLEAN DEFAULT FALSE,   -- FCL vs LCL
    operational_status VARCHAR(50) DEFAULT 'IN_WAREHOUSE',
    geo_location GEOMETRY(Point, 4326),             -- PostGIS live position
    estimated_time_departure DATE,
    estimated_time_arrival DATE
);
```

**Statuses:** `IN_WAREHOUSE`, `DEPARTED`, `SEA`, `PORT`, `DESTRUCTED`

**Indexes (PostGIS GiST for spatial):**
```sql
CREATE INDEX idx_containers_number ON logistics_containers(container_number);
CREATE INDEX idx_containers_status ON logistics_containers(operational_status);
CREATE INDEX idx_containers_geo ON logistics_containers USING GIST(geo_location);
```

### 3.2 `cargo_shipments` — Cargo Shipments Distribution

```sql
CREATE TABLE cargo_shipments (
    shipment_id SERIAL PRIMARY KEY,
    container_id INT REFERENCES logistics_containers(container_id),
    erp_customer_code VARCHAR(100) NOT NULL,       -- ERPNext Customer binding
    waybill_number VARCHAR(120) UNIQUE NOT NULL,
    total_packages INT NOT NULL,
    calculated_cbm DECIMAL(12,4) NOT NULL,
    total_weight_kg DECIMAL(12,2) NOT NULL,
    freight_cost_usd DECIMAL(12,2) NOT NULL,
    is_cleared BOOLEAN DEFAULT FALSE
);
```

**Purpose:** LCL grouping (shared container capacity) vs FCL flat-rate routing. `calculated_cbm` drives pro-rata LCL billing.

**Indexes:**
```sql
CREATE INDEX idx_shipments_container ON cargo_shipments(container_id);
CREATE INDEX idx_shipments_waybill ON cargo_shipments(waybill_number);
CREATE INDEX idx_shipments_customer ON cargo_shipments(erp_customer_code);
CREATE INDEX idx_shipments_cleared ON cargo_shipments(is_cleared);
```

### 3.3 `tracking_events` — Spatial Telemetry Log

```sql
CREATE TABLE tracking_events (
    event_id SERIAL PRIMARY KEY,
    container_id INT REFERENCES logistics_containers(container_id),
    event_type VARCHAR(50) NOT NULL,               -- DEPARTURE, SEA, ARRIVAL, CUSTOMS, DELIVERY
    event_date TIMESTAMP NOT NULL,
    location GEOGRAPHY(Point, 4326),               -- PostGIS geospatial event point
    port_code VARCHAR(10),
    country VARCHAR(50),
    description TEXT,
    source VARCHAR(20) DEFAULT 'celery',           -- celery, manual, api
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose:** Append-only telemetry from Celery scrapers. Stored as **GEOGRAPHY** to allow metric-based distance computations (meters) natively in PostGIS.

**Indexes:**
```sql
CREATE INDEX idx_events_container ON tracking_events(container_id);
CREATE INDEX idx_events_date ON tracking_events(event_date);
CREATE INDEX idx_events_type ON tracking_events(event_type);
CREATE INDEX idx_events_geo ON tracking_events USING GIST(location);
```

### 3.4 Supporting Lookups

```sql
CREATE TABLE shipping_lines (
    line_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    api_endpoint VARCHAR(200),
    tracking_url_template VARCHAR(300),
    poll_throttle_seconds INT DEFAULT 3600,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE ports (
    port_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) UNIQUE,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    geo_location GEOMETRY(Point, 4326)
);
```

---

## 4. PostGIS Geospatial Capabilities

| Capability | Query Example | Use Case |
|------------|---------------|----------|
| Vessel proximity | `ST_DWithin(geo_location, target, 50000)` | Port arrival detection |
| Route corridor | `ST_Buffer(ST_MakeLine(...), ...)` | Shipping lane analytics |
| Event geo-join | `ST_Distance(event.geo, port.geo)` | Nearest port mapping |

---

## 5. Data Flow

```
Carrier endpoints (MSC/Maersk/COSCO) ──throttled poll──▶ Celery scraper
                                                              │
                                                  proxy-rotating + Redis cache (4-6h)
                                                              │
                                                              ▼
                                          logistics_containers (geo_location updated)
                                                              │
                                                              ▼
                                                      tracking_events (append-only)
                                                              │
                                                      cargo_shipments (customer binding)
                                                              │
                                                              ▼
                                                OP-03 bus → customs/delivery settlement
```

---

## 6. Migration & Seed Strategy

- Seed `shipping_lines`: COSCO, Maersk, MSC, Evergreen, Yang Ming (see `01_database_setup/create_tables.sql`)
- Seed `ports`: Shanghai, Ningbo, Shenzhen, Guangzhou, Qingdao (China) + Aden, Hodeidah, Mukalla (Yemen)
- Rtia PostgreSQL `init.sql` alignment with `tracking_events`, `containers`, `shipping_lines`, `ports`

---

*Sub-plan of OPERATIONS_PLAN — Confidential*
