-- =====================================================
-- نظام الشحن الصيني اليمني - إنشاء الجداول
-- Shipping System Database Schema
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Table: branches (الفروع/المكاتب)
-- =====================================================
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    country VARCHAR(50) NOT NULL,
    cost_center_id VARCHAR(100),          -- ERPNext Cost Center ID
    warehouse_id VARCHAR(100),             -- ERPNext Warehouse ID
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_branches_code ON branches(code);
CREATE INDEX idx_branches_country ON branches(country);

-- =====================================================
-- Table: warehouses (المستودعات)
-- =====================================================
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    erpnext_warehouse_id VARCHAR(100),
    parent_warehouse_id UUID REFERENCES warehouses(id),
    location VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_warehouses_branch ON warehouses(branch_id);
CREATE INDEX idx_warehouses_parent ON warehouses(parent_warehouse_id);

-- =====================================================
-- Table: customers (العملاء)
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    erpnext_customer_id VARCHAR(100) UNIQUE,
    erpnext_sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    erpnext_sync_error TEXT,
    erpnext_synced_at TIMESTAMP WITH TIME ZONE,
    name VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200),
    name_en VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    address_ar TEXT,
    country VARCHAR(50),
    city VARCHAR(50),
    tax_number VARCHAR(50),
    credit_limit DECIMAL(15,2) DEFAULT 0,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_erpnext ON customers(erpnext_customer_id);
CREATE INDEX idx_customers_branch ON customers(branch_id);
CREATE INDEX idx_customers_name ON customers(name);

CREATE INDEX IF NOT EXISTS idx_customers_erpnext_sync_status
    ON customers(erpnext_sync_status);

CREATE TABLE IF NOT EXISTS customer_integration_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    key_hash CHAR(128) NOT NULL,
    scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_active_integration_key
    ON customer_integration_credentials(customer_id)
    WHERE status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_customer_integration_credentials_status
    ON customer_integration_credentials(status);

-- =====================================================
-- Table: shipments (الشحنات)
-- =====================================================
CREATE TABLE IF NOT EXISTS shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) NOT NULL UNIQUE,
    branch_id UUID NOT NULL REFERENCES branches(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    erpnext_sales_invoice_id VARCHAR(100),
    
    -- Shipping Details
    status VARCHAR(30) DEFAULT 'pending',
    origin_port VARCHAR(100),
    destination_port VARCHAR(100),
    vessel_name VARCHAR(200),
    voyage_number VARCHAR(50),
    
    -- Container Info
    container_number VARCHAR(50),
    container_count INTEGER DEFAULT 1,
    
    -- Dates
    order_date DATE,
    departure_date TIMESTAMP WITH TIME ZONE,
    expected_arrival TIMESTAMP WITH TIME ZONE,
    actual_arrival TIMESTAMP WITH TIME ZONE,
    delivery_date TIMESTAMP WITH TIME ZONE,
    
    -- Financial
    total_cost DECIMAL(15,2) DEFAULT 0,
    selling_price DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Notes
    description TEXT,
    notes TEXT,
    
    created_by UUID,  -- REFERENCES users(id)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shipments_number ON shipments(shipment_number);
CREATE INDEX idx_shipments_branch ON shipments(branch_id);
CREATE INDEX idx_shipments_customer ON shipments(customer_id);
CREATE INDEX idx_shipments_status ON shipments(status);
CREATE INDEX idx_shipments_erpnext ON shipments(erpnext_sales_invoice_id);

-- =====================================================
-- Table: containers (الحاويات)
-- =====================================================
CREATE TABLE IF NOT EXISTS containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    container_number VARCHAR(50) NOT NULL,
    container_type VARCHAR(20) NOT NULL,  -- 20GP, 40GP, 40HC, 45HC
    seal_number VARCHAR(50),
    weight DECIMAL(10,2),
    volume DECIMAL(10,3),
    package_count INTEGER DEFAULT 0,
    description TEXT,
    status VARCHAR(30) DEFAULT 'loading',
    tracking_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(shipment_id, container_number)
);

CREATE INDEX idx_containers_shipment ON containers(shipment_id);
CREATE INDEX idx_containers_number ON containers(container_number);
CREATE INDEX idx_containers_type ON containers(container_type);

-- =====================================================
-- Table: tracking_events (أحداث التتبع)
-- =====================================================
CREATE TABLE IF NOT EXISTS tracking_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_id UUID NOT NULL REFERENCES containers(id) ON DELETE CASCADE,
    shipment_id UUID REFERENCES shipments(id),
    
    event_type VARCHAR(50) NOT NULL,  -- departure, in_transit, arrival, customs, delivery
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(200),
    port_code VARCHAR(10),
    country VARCHAR(50),
    description TEXT,
    source VARCHAR(20) DEFAULT 'manual',  -- manual, api
    reference_number VARCHAR(100),
    
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tracking_container ON tracking_events(container_id);
CREATE INDEX idx_tracking_shipment ON tracking_events(shipment_id);
CREATE INDEX idx_tracking_date ON tracking_events(event_date);
CREATE INDEX idx_tracking_type ON tracking_events(event_type);

-- =====================================================
-- Table: invoices (الفواتير)
-- =====================================================
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    erpnext_invoice_id VARCHAR(100) UNIQUE,
    invoice_type VARCHAR(20) NOT NULL,  -- sales, purchase
    invoice_number VARCHAR(50),
    invoice_date DATE,
    
    customer_id UUID REFERENCES customers(id),
    supplier_id VARCHAR(100),
    
    amount DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    status VARCHAR(20) DEFAULT 'draft',  -- draft, submitted, paid, cancelled
    cost_center_id VARCHAR(100),
    warehouse_id VARCHAR(100),
    
    due_date DATE,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    
    notes TEXT,
    erpnext_link VARCHAR(200),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoices_shipment ON invoices(shipment_id);
CREATE INDEX idx_invoices_erpnext ON invoices(erpnext_invoice_id);
CREATE INDEX idx_invoices_customer ON invoices(customer_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- =====================================================
-- Table: payments (المدفوعات)
-- =====================================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    erpnext_payment_id VARCHAR(100) UNIQUE,
    erpnext_sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    erpnext_sync_error TEXT,
    erpnext_synced_at TIMESTAMP WITH TIME ZONE,
    
    payment_type VARCHAR(20) NOT NULL,  -- received, made
    payment_number VARCHAR(50),
    payment_date DATE NOT NULL,
    
    customer_id UUID REFERENCES customers(id),
    supplier_id VARCHAR(100),
    branch_id UUID REFERENCES branches(id),
    
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10,4) DEFAULT 1,
    
    payment_method VARCHAR(30),  -- cash, bank_transfer, credit_card
    reference_number VARCHAR(100),
    
    status VARCHAR(20) DEFAULT 'pending',  -- pending, completed, failed
    
    notes TEXT,
    erpnext_link VARCHAR(200),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_invoice ON payments(invoice_id);
CREATE INDEX idx_payments_erpnext ON payments(erpnext_payment_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_erpnext_sync_status ON payments(erpnext_sync_status);

-- =====================================================
-- Table: users (المستخدمين)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    full_name VARCHAR(100),
    full_name_ar VARCHAR(100),
    phone VARCHAR(20),
    
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'operator',  -- admin, manager, operator, viewer
    
    permissions JSONB DEFAULT '{}',
    
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_branch ON users(branch_id);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- Table: shipments_items (بنود الشحنات - عناصر الشحنة)
-- =====================================================
CREATE TABLE IF NOT EXISTS shipments_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    
    item_name VARCHAR(200) NOT NULL,
    item_name_ar VARCHAR(200),
    item_code VARCHAR(50),
    quantity DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20),
    unit_price DECIMAL(15,2),
    total_price DECIMAL(15,2),
    
    weight DECIMAL(10,2),
    volume DECIMAL(10,3),
    
    description TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shipments_items_shipment ON shipments_items(shipment_id);

-- =====================================================
-- Table: shipping_lines (شركات الشحن)
-- =====================================================
CREATE TABLE IF NOT EXISTS shipping_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(20) UNIQUE,
    api_endpoint VARCHAR(200),
    tracking_url_template VARCHAR(300),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Table: ports (الموانئ)
-- =====================================================
CREATE TABLE IF NOT EXISTS ports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(10) UNIQUE,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ports_country ON ports(country);

-- =====================================================
-- Table: audit_logs (سجل المراجعة)
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_date ON audit_logs(created_at);

-- =====================================================
-- Tables: integration channels and credential metadata
-- Secrets are kept in a secret manager; only references and hashes are stored here.
-- =====================================================
CREATE TABLE IF NOT EXISTS integration_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_code VARCHAR(20) NOT NULL UNIQUE CHECK (channel_code IN ('ADMIN', 'MARKET', 'SHIPPING')),
    target_system VARCHAR(30) NOT NULL DEFAULT 'ERPNEXT',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    current_credential_id UUID,
    previous_credential_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_channels_status
    ON integration_channels(status);

CREATE TABLE IF NOT EXISTS integration_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES integration_channels(id),
    owner_type VARCHAR(30) NOT NULL DEFAULT 'SYSTEM',
    owner_id UUID,
    secret_ref VARCHAR(300) NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    secret_hash CHAR(128) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    scopes JSONB NOT NULL DEFAULT '[]',
    environment VARCHAR(20) NOT NULL,
    created_by UUID NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    activated_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_credentials_channel_status
    ON integration_credentials(channel_id, status);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_owner
    ON integration_credentials(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_expires_at
    ON integration_credentials(expires_at);

CREATE TABLE IF NOT EXISTS integration_key_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credential_id UUID REFERENCES integration_credentials(id) ON DELETE SET NULL,
    channel_code VARCHAR(20) NOT NULL,
    actor_id UUID,
    action VARCHAR(40) NOT NULL,
    request_id UUID NOT NULL,
    result VARCHAR(20) NOT NULL,
    reason_code VARCHAR(80),
    source_ip INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_key_events_credential ON integration_key_events(credential_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_channel ON integration_key_events(channel_code);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_request ON integration_key_events(request_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_created_at ON integration_key_events(created_at);

CREATE TABLE IF NOT EXISTS integration_webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id VARCHAR(100) NOT NULL UNIQUE,
    event VARCHAR(100) NOT NULL,
    payload_hash CHAR(64) NOT NULL,
    result VARCHAR(20) NOT NULL DEFAULT 'ACCEPTED',
    source_ip VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_webhook_events_created_at
    ON integration_webhook_events(created_at);

-- =====================================================
-- Tables: integration_outbox / integration_audit
-- Financial commands queued for asynchronous ERPNext delivery
-- =====================================================
CREATE TABLE IF NOT EXISTS integration_outbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idempotency_key CHAR(64) NOT NULL UNIQUE,
    command_type VARCHAR(60) NOT NULL,
    source_type VARCHAR(60) NOT NULL,
    source_id VARCHAR(120) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP WITH TIME ZONE,
    erp_document_name VARCHAR(120),
    last_error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_integration_outbox_status
        CHECK (status IN ('PENDING', 'PROCESSING', 'DONE', 'FAILED', 'DEAD'))
);

CREATE INDEX IF NOT EXISTS idx_integration_outbox_status
    ON integration_outbox(status);
CREATE INDEX IF NOT EXISTS idx_integration_outbox_next_attempt
    ON integration_outbox(next_attempt_at)
    WHERE status IN ('PENDING', 'FAILED');

CREATE TABLE IF NOT EXISTS integration_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outbox_id UUID NOT NULL REFERENCES integration_outbox(id) ON DELETE CASCADE,
    action VARCHAR(40) NOT NULL,
    attempt INTEGER,
    http_status INTEGER,
    response_summary TEXT,
    actor_reference VARCHAR(120),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_audit_outbox
    ON integration_audit(outbox_id);
CREATE INDEX IF NOT EXISTS idx_integration_audit_created_at
    ON integration_audit(created_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_integration_current_credential
    ON integration_channels(current_credential_id)
    WHERE current_credential_id IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_channel_current_credential'
    ) THEN
        ALTER TABLE integration_channels
            ADD CONSTRAINT fk_channel_current_credential
            FOREIGN KEY (current_credential_id) REFERENCES integration_credentials(id)
            ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_channel_previous_credential'
    ) THEN
        ALTER TABLE integration_channels
            ADD CONSTRAINT fk_channel_previous_credential
            FOREIGN KEY (previous_credential_id) REFERENCES integration_credentials(id)
            ON DELETE SET NULL;
    END IF;
END $$;

INSERT INTO integration_channels (channel_code)
VALUES ('ADMIN'), ('MARKET'), ('SHIPPING')
ON CONFLICT (channel_code) DO NOTHING;

-- =====================================================
-- Functions و Triggers
-- =====================================================

-- Function لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers لـ updated_at
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shipments_updated_at BEFORE UPDATE ON shipments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_containers_updated_at BEFORE UPDATE ON containers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function لتوليد رقم الشحنة التلقائي
CREATE OR REPLACE FUNCTION generate_shipment_number(branch_code VARCHAR, year INT)
RETURNS TEXT AS $$
DECLARE
    next_num INT;
    result TEXT;
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(shipment_number FROM '\d+$') AS INT)
    ), 0) + 1
    INTO next_num
    FROM shipments
    WHERE shipment_number LIKE 'SHIP-' || branch_code || '-' || year || '-%';
    
    result := 'SHIP-' || branch_code || '-' || year || '-' || LPAD(next_num::TEXT, 4, '0');
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- البيانات الأولية - الفروع
-- =====================================================
INSERT INTO branches (name, code, country, cost_center_id, warehouse_id, address, phone, email) VALUES
('مكتب الصين', 'CHN', 'الصين', 'CC-CHN-001', 'WH-CHN-001', 'شنتشن، الصين', '+86-755-XXXXXXX', 'china@shipping.com'),
('مكتب اليمن', 'YEM', 'اليمن', 'CC-YEM-001', 'WH-YEM-001', 'عدن، اليمن', '+967-2-XXXXXXX', 'yemen@shipping.com')
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- البيانات الأولية - شركات الشحن
-- =====================================================
INSERT INTO shipping_lines (name, name_ar, code, tracking_url_template) VALUES
('COSCO Shipping', 'كوستكو شيبينغ', 'COSCO', 'https://www.coscoclean.com/search?keyword={container_no}'),
('Maersk', 'مارسك', 'MAERSK', 'https://www.maersk.com/tracking/{container_no}'),
('MSC', 'MSC', 'MSC', 'https://www.msc.com/track-shipment/{container_no}'),
('Evergreen', 'إيفرغرين', 'EGL', 'https://www.evergreen-marine.com/'),
('Yang Ming', 'يانغ مينغ', 'YML', 'https://www.yangming.com/')
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- البيانات الأولية - الموانئ
-- =====================================================
-- موانئ الصين
INSERT INTO ports (name, name_ar, code, country, city) VALUES
('Shanghai Port', 'ميناء شانغهاي', 'SHA', 'الصين', 'شانغهاي'),
('Ningbo Port', 'ميناء نينغبو', 'NGB', 'الصين', 'نينغبو'),
('Shenzhen Port', 'ميناء شنتشن', 'SZX', 'الصين', 'شنتشن'),
('Guangzhou Port', 'ميناء قوانغتشو', 'CAN', 'الصين', 'قوانغتشو'),
('Qingdao Port', 'ميناء كينغدو', 'TAO', 'الصين', 'كينغدو')
ON CONFLICT (code) DO NOTHING;

-- موانئ اليمن
INSERT INTO ports (name, name_ar, code, country, city) VALUES
('Aden Port', 'ميناءعدن', 'ADE', 'اليمن', 'عدن'),
('Hodeidah Port', 'ميناء الحديدة', 'HOD', 'اليمن', 'الحديدة'),
('Mukalla Port', 'ميناء المكلا', 'MUK', 'اليمن', 'المكلا')
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- إنشاء مستخدم مسؤول افتراضي (كلمة المرور: Admin123!)
-- =====================================================
INSERT INTO users (username, email, password_hash, full_name, role, branch_id)
SELECT 'admin', 'admin@shipping.com', 
       '$2b$12$8/93VO0azt8Hn5gGPUR0ieEdMftUN8jbsJG5fK5KRI59SfB.1HaGq',
       'المدير العام', 'admin', id
FROM branches WHERE code = 'CHN'
ON CONFLICT (username) DO NOTHING;

-- ملاحظة: كلمة المرور الافتراضية مشفرة باستخدام bcrypt
-- القيمة المعروضة هي تشفير صالح لـ "Admin123!"
-- لتغييرها، استخدم قيمة جديدة من bcrypt

-- =====================================================
-- Grant Permissions
-- =====================================================
-- Grant all tables to application user
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shipping_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shipping_user;

-- END OF SQL
SELECT 'Database schema created successfully!' as status;