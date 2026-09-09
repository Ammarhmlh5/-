-- =====================================================
-- قاعدة بيانات السوق الحرة - PostgreSQL 15+
-- قاعدة مستقلة عن ERPNext وعن قاعدة نظام الشحن.
-- لا تحفظ الأسرار هنا؛ تحفظ المراجع والبصمات والهاشات فقط.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name VARCHAR(200) NOT NULL,
    company_name_en VARCHAR(255),
    company_name_zh VARCHAR(255),
    contact_phone VARCHAR(50),
    contract_reference VARCHAR(100) UNIQUE,
    settlement_currency CHAR(3) NOT NULL DEFAULT 'CNY',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'CLOSED')),
    erpnext_supplier_id VARCHAR(140) UNIQUE,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS supplier_users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120),
    role VARCHAR(30) NOT NULL DEFAULT 'SUPPLIER_OPERATOR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS market_operators (
    operator_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120),
    role VARCHAR(30) NOT NULL DEFAULT 'MARKET_OPERATOR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS marketplace_catalog (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
    sku VARCHAR(100) NOT NULL UNIQUE,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    description TEXT,
    image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
    factory_price_cny NUMERIC(12,2) NOT NULL CHECK (factory_price_cny >= 0),
    handling_fee_usd NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (handling_fee_usd >= 0),
    volume_cbm NUMERIC(10,4) NOT NULL DEFAULT 0 CHECK (volume_cbm >= 0),
    weight_kg NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (weight_kg >= 0),
    available_stock INTEGER NOT NULL DEFAULT 0 CHECK (available_stock >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'ACTIVE', 'INACTIVE')),
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE marketplace_catalog
    ADD COLUMN IF NOT EXISTS image_urls JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE TABLE IF NOT EXISTS catalog_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (supplier_id, name)
);

CREATE TABLE IF NOT EXISTS product_categories (
    product_id UUID NOT NULL REFERENCES marketplace_catalog(product_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES catalog_categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);

CREATE TABLE IF NOT EXISTS marketplace_orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_reference VARCHAR(120) NOT NULL UNIQUE,
    customer_user_id UUID NOT NULL,
    erp_customer_code VARCHAR(100),
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'CONFIRMED', 'PAID', 'CANCELLED')),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    total_usd NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (total_usd >= 0),
    fx_rate_used NUMERIC(10,6) CHECK (fx_rate_used > 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE marketplace_orders
    ADD COLUMN IF NOT EXISTS erpnext_sales_order_id VARCHAR(140) UNIQUE;

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES marketplace_orders(order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES marketplace_catalog(product_id) ON DELETE RESTRICT,
    sku VARCHAR(100) NOT NULL,
    qty INTEGER NOT NULL CHECK (qty > 0),
    unit_rate_cny NUMERIC(12,2) NOT NULL CHECK (unit_rate_cny >= 0),
    handling_fee_usd NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (handling_fee_usd >= 0),
    fx_rate_used NUMERIC(10,6) CHECK (fx_rate_used > 0),
    unit_rate_usd NUMERIC(12,2) NOT NULL CHECK (unit_rate_usd >= 0),
    warehouse VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS market_api_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    owner_type VARCHAR(20) NOT NULL
        CHECK (owner_type IN ('SYSTEM', 'TENANT', 'EMPLOYEE')),
    owner_id UUID NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    key_hash TEXT NOT NULL,
    scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_by UUID,
    revoked_by UUID,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (owner_type = 'SYSTEM' OR supplier_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS market_erp_credentials (
    credential_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID NOT NULL UNIQUE REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    channel VARCHAR(20) NOT NULL DEFAULT 'MARKET' CHECK (channel = 'MARKET'),
    erpnext_entity_type VARCHAR(30) NOT NULL DEFAULT 'Supplier',
    erpnext_entity_id VARCHAR(140) NOT NULL UNIQUE,
    secret_ref VARCHAR(300) NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PROVISIONING'
        CHECK (status IN ('PROVISIONING', 'READY', 'FAILED', 'REVOKED')),
    allowed_operations JSONB NOT NULL DEFAULT '[]'::jsonb,
    expires_at TIMESTAMPTZ,
    rotated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS market_provisioning_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    operation VARCHAR(40) NOT NULL,
    idempotency_key VARCHAR(140) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED')),
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    last_error_code VARCHAR(80),
    next_attempt_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fx_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    base_currency CHAR(3) NOT NULL DEFAULT 'CNY',
    quote_currency CHAR(3) NOT NULL DEFAULT 'USD',
    rate NUMERIC(12,6) NOT NULL CHECK (rate > 0),
    effective_date DATE NOT NULL,
    source VARCHAR(30) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (base_currency, quote_currency, effective_date)
);

CREATE TABLE IF NOT EXISTS product_change_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES marketplace_catalog(product_id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    action VARCHAR(40) NOT NULL,
    actor_id UUID,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS market_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL,
    tenant_id UUID,
    actor_id UUID,
    actor_key_id UUID REFERENCES market_api_keys(key_id) ON DELETE SET NULL,
    channel VARCHAR(20) CHECK (channel = 'MARKET'),
    credential_id UUID REFERENCES market_erp_credentials(credential_id) ON DELETE SET NULL,
    operation VARCHAR(60),
    result VARCHAR(20),
    reason_code VARCHAR(80),
    source_ip INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_suppliers_status ON suppliers(status);
CREATE INDEX IF NOT EXISTS idx_supplier_users_supplier ON supplier_users(supplier_id, is_active);
CREATE INDEX IF NOT EXISTS idx_catalog_supplier_status ON marketplace_catalog(supplier_id, status);
CREATE INDEX IF NOT EXISTS idx_catalog_stock ON marketplace_catalog(available_stock) WHERE available_stock > 0;
CREATE INDEX IF NOT EXISTS idx_catalog_categories_supplier ON catalog_categories(supplier_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_category ON product_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_status ON marketplace_orders(customer_user_id, status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_market_keys_supplier_status ON market_api_keys(supplier_id, status);
CREATE INDEX IF NOT EXISTS idx_market_keys_owner ON market_api_keys(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_provisioning_supplier_status ON market_provisioning_jobs(supplier_id, status);
CREATE INDEX IF NOT EXISTS idx_product_changes_product_date ON product_change_logs(product_id, created_at);
CREATE INDEX IF NOT EXISTS idx_market_audit_request ON market_audit_logs(request_id);
CREATE INDEX IF NOT EXISTS idx_market_audit_tenant_date ON market_audit_logs(tenant_id, created_at);

CREATE OR REPLACE FUNCTION market_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS suppliers_updated_at ON suppliers;
CREATE TRIGGER suppliers_updated_at BEFORE UPDATE ON suppliers
FOR EACH ROW EXECUTE FUNCTION market_update_updated_at();

DROP TRIGGER IF EXISTS catalog_updated_at ON marketplace_catalog;
CREATE TRIGGER catalog_updated_at BEFORE UPDATE ON marketplace_catalog
FOR EACH ROW EXECUTE FUNCTION market_update_updated_at();

DROP TRIGGER IF EXISTS orders_updated_at ON marketplace_orders;
CREATE TRIGGER orders_updated_at BEFORE UPDATE ON marketplace_orders
FOR EACH ROW EXECUTE FUNCTION market_update_updated_at();

COMMENT ON TABLE market_api_keys IS 'Local marketplace keys only; never ERPNext credentials';
COMMENT ON TABLE market_erp_credentials IS 'Secret manager references for supplier ERP identities';
COMMENT ON TABLE market_audit_logs IS 'Audit context without secrets or sensitive payloads';

SELECT 'Marketplace database schema ready' AS status;
