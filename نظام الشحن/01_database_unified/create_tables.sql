-- ============================================================================
-- نظام الشحن والإدارة - قاعدة البيانات الموحدة
-- Unified Shipping & Administration Database - PostgreSQL 15+
-- ============================================================================
-- هذا الملف يدمج جداول نظام الشحن وجداول الإدارة (الموظفون + الصلاحيات RBAC)
-- في قاعدة واحدة متكاملة، مع الإبقاء على جداول التكامل مع ERPNext.
-- الأسرار لا تخزن هنا؛ تحفظ المراجع والبصمات والهاشات فقط.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- (1) الإدارة: الفروع والأقسام والموظفون والمستخدمون والصلاحيات
-- ============================================================================

-- ------------------------------------------------------------
-- Table: branches (الفروع/المكاتب)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(10) NOT NULL UNIQUE,               -- CHN, YEM
    country VARCHAR(50) NOT NULL,
    cost_center_id VARCHAR(100),                     -- ERPNext Cost Center ID
    warehouse_id VARCHAR(100),                       -- ERPNext Warehouse ID
    erpnext_branch VARCHAR(100),                     -- ERPNext Branch/docname reference
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_branches_code ON branches(code);
CREATE INDEX IF NOT EXISTS idx_branches_country ON branches(country);
CREATE INDEX IF NOT EXISTS idx_branches_active ON branches(is_active);

-- ------------------------------------------------------------
-- Table: departments (الأقسام)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(20),
    manager_employee_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_id, name)
);

CREATE INDEX IF NOT EXISTS idx_departments_branch ON departments(branch_id);

-- ------------------------------------------------------------
-- Table: employees (سجل الموظفين - الإدارة)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_code VARCHAR(50) NOT NULL UNIQUE,       -- e.g. EMP-CHN-001
    full_name VARCHAR(200) NOT NULL,
    full_name_ar VARCHAR(200),
    job_title VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    erpnext_employee VARCHAR(100),                   -- ERPNext Employee docname
    erpnext_user VARCHAR(100),                       -- ERPNext User docname
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_employees_branch ON employees(branch_id);
CREATE INDEX IF NOT EXISTS idx_employees_code ON employees(employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_employees_active ON employees(is_active);

-- ------------------------------------------------------------
-- Table: users (المستخدمون - حسابات النظام الموحدة)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES employees(employee_id) ON DELETE SET NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,             -- bcrypt only

    full_name VARCHAR(100),
    full_name_ar VARCHAR(100),
    phone VARCHAR(20),

    default_branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'operator',    -- admin, manager, operator, viewer (legacy fallback)

    token_version INT DEFAULT 1,                     -- bumped on role change / deactivation
    permissions JSONB DEFAULT '{}',

    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_branch ON users(default_branch_id);
CREATE INDEX IF NOT EXISTS idx_users_employee ON users(employee_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ------------------------------------------------------------
-- Table: platform_roles (الأدوار - مرآة مزامنة من ERPNext)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform_roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_code VARCHAR(50) NOT NULL UNIQUE,           -- e.g. YEM-OPERATOR, CHN-MANAGER
    role_name_ar VARCHAR(100),
    erpnext_role VARCHAR(100) NOT NULL,              -- authoritative ERPNext role name
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_platform_roles_code ON platform_roles(role_code);
CREATE INDEX IF NOT EXISTS idx_platform_roles_erpnext ON platform_roles(erpnext_role);

-- ------------------------------------------------------------
-- Table: user_branch_roles (تعيينات الأدوار حسب الفرع)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_branch_roles (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES platform_roles(role_id),
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    granted_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, branch_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_assignments_user ON user_branch_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_assignments_branch ON user_branch_roles(branch_id);
CREATE INDEX IF NOT EXISTS idx_assignments_role ON user_branch_roles(role_id);

-- ------------------------------------------------------------
-- Table: permission_matrix (مصفوفة الصلاحيات للدور)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS permission_matrix (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES platform_roles(role_id),
    resource VARCHAR(50) NOT NULL,                   -- catalog, orders, containers, tracking, outbox, users, branches, ...
    actions TEXT[] NOT NULL DEFAULT '{read}',        -- {'read'} {'create','update'} ...
    UNIQUE (role_id, resource)
);

CREATE INDEX IF NOT EXISTS idx_permission_role ON permission_matrix(role_id);

-- ------------------------------------------------------------
-- Table: acl_sync_log (سجل مزامنة الصلاحيات من ERPNext)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS acl_sync_log (
    sync_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(30) NOT NULL,                -- EMPLOYEE, USER, ROLE, BRANCH, PERMISSION
    local_entity_id VARCHAR(120),
    erpnext_document VARCHAR(120),
    operation VARCHAR(20) NOT NULL,                  -- CREATE, UPDATE, DEACTIVATE, PULL
    direction VARCHAR(10) NOT NULL,                  -- OUT (upload) / IN (pull roles)
    status VARCHAR(20) DEFAULT 'PENDING',            -- PENDING, DONE, FAILED
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_acl_sync_type ON acl_sync_log(entity_type);
CREATE INDEX IF NOT EXISTS idx_acl_sync_status ON acl_sync_log(status);
CREATE INDEX IF NOT EXISTS idx_acl_sync_date ON acl_sync_log(created_at);

-- ------------------------------------------------------------
-- Table: refresh_tokens (جلسات/رموز التحديث)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_fingerprint CHAR(64) NOT NULL UNIQUE,      -- hash of the refresh token
    user_agent VARCHAR(255),
    ip_address INET,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expiry ON refresh_tokens(expires_at);

-- ============================================================================
-- (2) الشحن: المستودعات والعملاء والشحنات والتتبع
-- ============================================================================

-- ------------------------------------------------------------
-- Table: warehouses (المستودعات)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    erpnext_warehouse_id VARCHAR(100),
    parent_warehouse_id UUID REFERENCES warehouses(id),
    location VARCHAR(100),
    manager_employee_id UUID REFERENCES employees(employee_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_warehouses_branch ON warehouses(branch_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_parent ON warehouses(parent_warehouse_id);

-- ------------------------------------------------------------
-- Table: customers (العملاء)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    erpnext_customer_id VARCHAR(100) UNIQUE,
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
    credit_limit NUMERIC(15,2) DEFAULT 0,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_customers_erpnext ON customers(erpnext_customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_branch ON customers(branch_id);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);

-- ------------------------------------------------------------
-- Table: shipping_lines (شركات الشحن)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shipping_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(20) UNIQUE,
    api_endpoint VARCHAR(200),
    tracking_url_template VARCHAR(300),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Table: ports (الموانئ)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(10) UNIQUE,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ports_country ON ports(country);

-- ------------------------------------------------------------
-- Table: shipments (الشحنات)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) NOT NULL UNIQUE,
    branch_id UUID NOT NULL REFERENCES branches(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    erpnext_sales_invoice_id VARCHAR(100),

    status VARCHAR(30) DEFAULT 'pending',
    origin_port VARCHAR(100),
    destination_port VARCHAR(100),
    vessel_name VARCHAR(200),
    voyage_number VARCHAR(50),

    container_number VARCHAR(50),
    container_count INTEGER DEFAULT 1,

    order_date DATE,
    departure_date TIMESTAMPTZ,
    expected_arrival TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    delivery_date TIMESTAMPTZ,

    total_cost NUMERIC(15,2) DEFAULT 0,
    selling_price NUMERIC(15,2) DEFAULT 0,
    currency CHAR(3) DEFAULT 'USD',

    description TEXT,
    notes TEXT,

    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shipments_number ON shipments(shipment_number);
CREATE INDEX IF NOT EXISTS idx_shipments_branch ON shipments(branch_id);
CREATE INDEX IF NOT EXISTS idx_shipments_customer ON shipments(customer_id);
CREATE INDEX IF NOT EXISTS idx_shipments_status ON shipments(status);
CREATE INDEX IF NOT EXISTS idx_shipments_erpnext ON shipments(erpnext_sales_invoice_id);

-- ------------------------------------------------------------
-- Table: shipments_items (بنود الشحنة)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shipments_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    container_id UUID,
    item_name VARCHAR(200) NOT NULL,
    item_name_ar VARCHAR(200),
    item_code VARCHAR(50),
    quantity NUMERIC(10,2) NOT NULL,
    unit VARCHAR(20),
    unit_price NUMERIC(15,2),
    total_price NUMERIC(15,2),
    weight NUMERIC(10,2),
    volume NUMERIC(10,3),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shipments_items_shipment ON shipments_items(shipment_id);
CREATE INDEX IF NOT EXISTS idx_shipments_items_container ON shipments_items(container_id);

-- ------------------------------------------------------------
-- Table: containers (الحاويات)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    container_number VARCHAR(50) NOT NULL,
    container_type VARCHAR(20) NOT NULL,             -- 20GP, 40GP, 40HC, 45HC
    seal_number VARCHAR(50),
    weight NUMERIC(10,2),
    volume NUMERIC(10,3),
    package_count INTEGER DEFAULT 0,
    description TEXT,
    status VARCHAR(30) DEFAULT 'loading',
    tracking_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (shipment_id, container_number)
);

CREATE INDEX IF NOT EXISTS idx_containers_shipment ON containers(shipment_id);
CREATE INDEX IF NOT EXISTS idx_containers_number ON containers(container_number);
CREATE INDEX IF NOT EXISTS idx_containers_type ON containers(container_type);

-- ------------------------------------------------------------
-- Table: tracking_events (أحداث التتبع)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tracking_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_id UUID NOT NULL REFERENCES containers(id) ON DELETE CASCADE,
    shipment_id UUID REFERENCES shipments(id),
    event_type VARCHAR(50) NOT NULL,                 -- departure, in_transit, arrival, customs, delivery
    event_date TIMESTAMPTZ NOT NULL,
    location VARCHAR(200),
    port_code VARCHAR(10),
    country VARCHAR(50),
    description TEXT,
    source VARCHAR(20) DEFAULT 'manual',             -- manual, api
    reference_number VARCHAR(100),
    latitude NUMERIC(10,8),
    longitude NUMERIC(11,8),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tracking_container ON tracking_events(container_id);
CREATE INDEX IF NOT EXISTS idx_tracking_shipment ON tracking_events(shipment_id);
CREATE INDEX IF NOT EXISTS idx_tracking_date ON tracking_events(event_date);
CREATE INDEX IF NOT EXISTS idx_tracking_type ON tracking_events(event_type);

-- ============================================================================
-- (3) المالية: الفواتير والمدفوعات
-- ============================================================================

-- ------------------------------------------------------------
-- Table: invoices (الفواتير)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    erpnext_invoice_id VARCHAR(100) UNIQUE,
    invoice_type VARCHAR(20) NOT NULL,               -- sales, purchase
    invoice_number VARCHAR(50),
    invoice_date DATE,
    customer_id UUID REFERENCES customers(id),
    supplier_id VARCHAR(100),
    amount NUMERIC(15,2) NOT NULL,
    tax_amount NUMERIC(15,2) DEFAULT 0,
    discount_amount NUMERIC(15,2) DEFAULT 0,
    total_amount NUMERIC(15,2) NOT NULL,
    currency CHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'draft',              -- draft, submitted, paid, cancelled
    cost_center_id VARCHAR(100),
    warehouse_id VARCHAR(100),
    due_date DATE,
    paid_amount NUMERIC(15,2) DEFAULT 0,
    notes TEXT,
    erpnext_link VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_invoices_shipment ON invoices(shipment_id);
CREATE INDEX IF NOT EXISTS idx_invoices_erpnext ON invoices(erpnext_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);

-- ------------------------------------------------------------
-- Table: payments (المدفوعات)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    erpnext_payment_id VARCHAR(100) UNIQUE,
    payment_type VARCHAR(20) NOT NULL,               -- received, made
    payment_number VARCHAR(50),
    payment_date DATE NOT NULL,
    customer_id UUID REFERENCES customers(id),
    supplier_id VARCHAR(100),
    branch_id UUID REFERENCES branches(id),
    amount NUMERIC(15,2) NOT NULL,
    currency CHAR(3) DEFAULT 'USD',
    exchange_rate NUMERIC(10,4) DEFAULT 1,
    payment_method VARCHAR(30),                      -- cash, bank_transfer, credit_card
    reference_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending',            -- pending, completed, failed
    notes TEXT,
    erpnext_link VARCHAR(200),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_erpnext ON payments(erpnext_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- ============================================================================
-- (4) المراجعة والتدقيق
-- ============================================================================

-- ------------------------------------------------------------
-- Table: audit_logs (سجل المراجعة العام)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_date ON audit_logs(created_at);

-- ============================================================================
-- (5) التكامل مع ERPNext (قنوات واعتمادات)
-- ============================================================================

-- ------------------------------------------------------------
-- Table: integration_channels (قنوات التكامل)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS integration_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_code VARCHAR(20) NOT NULL UNIQUE CHECK (channel_code IN ('ADMIN', 'MARKET', 'SHIPPING')),
    target_system VARCHAR(30) NOT NULL DEFAULT 'ERPNEXT',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    current_credential_id UUID,
    previous_credential_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_channels_status ON integration_channels(status);

-- ------------------------------------------------------------
-- Table: integration_credentials (بيانات اعتماد التكامل)
-- ------------------------------------------------------------
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
    environment VARCHAR(20) NOT NULL DEFAULT 'production',
    created_by UUID NOT NULL,
    expires_at TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    revoked_by UUID,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_credentials_channel_status
    ON integration_credentials(channel_id, status);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_owner
    ON integration_credentials(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_expires_at
    ON integration_credentials(expires_at);

-- ------------------------------------------------------------
-- Table: integration_key_events (دورة حياة مفاتيح التكامل)
-- ------------------------------------------------------------
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_key_events_credential ON integration_key_events(credential_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_channel ON integration_key_events(channel_code);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_request ON integration_key_events(request_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_created_at ON integration_key_events(created_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_integration_current_credential
    ON integration_channels(current_credential_id)
    WHERE current_credential_id IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_channel_current_credential') THEN
        ALTER TABLE integration_channels
            ADD CONSTRAINT fk_channel_current_credential
            FOREIGN KEY (current_credential_id) REFERENCES integration_credentials(id)
            ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_channel_previous_credential') THEN
        ALTER TABLE integration_channels
            ADD CONSTRAINT fk_channel_previous_credential
            FOREIGN KEY (previous_credential_id) REFERENCES integration_credentials(id)
            ON DELETE SET NULL;
    END IF;
END $$;

INSERT INTO integration_channels (channel_code)
VALUES ('ADMIN'), ('MARKET'), ('SHIPPING')
ON CONFLICT (channel_code) DO NOTHING;

-- ============================================================================
-- Functions و Triggers
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_branches_updated_at ON branches;
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_departments_updated_at ON departments;
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_employees_updated_at ON employees;
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_platform_roles_updated_at ON platform_roles;
CREATE TRIGGER update_platform_roles_updated_at BEFORE UPDATE ON platform_roles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_warehouses_updated_at ON warehouses;
CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_shipments_updated_at ON shipments;
CREATE TRIGGER update_shipments_updated_at BEFORE UPDATE ON shipments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_containers_updated_at ON containers;
CREATE TRIGGER update_containers_updated_at BEFORE UPDATE ON containers
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_shipping_lines_updated_at ON shipping_lines;
CREATE TRIGGER update_shipping_lines_updated_at BEFORE UPDATE ON shipping_lines
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_integration_channels_updated_at ON integration_channels;
CREATE TRIGGER update_integration_channels_updated_at BEFORE UPDATE ON integration_channels
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- دالة توليد رقم الشحنة التلقائي
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

-- ============================================================================
-- البيانات الأولية (Seed Data)
-- ============================================================================

-- الفروع
INSERT INTO branches (name, name_ar, code, country, cost_center_id, warehouse_id, address, phone, email) VALUES
('مكتب الصين', 'مكتب الصين', 'CHN', 'الصين', 'CC-CHN-001', 'WH-CHN-001', 'شنتشن، الصين', '+86-755-XXXXXXX', 'china@shipping.com'),
('مكتب اليمن', 'مكتب اليمن', 'YEM', 'اليمن', 'CC-YEM-001', 'WH-YEM-001', 'عدن، اليمن', '+967-2-XXXXXXX', 'yemen@shipping.com')
ON CONFLICT (code) DO NOTHING;

-- شركات الشحن
INSERT INTO shipping_lines (name, name_ar, code, tracking_url_template) VALUES
('COSCO Shipping', 'كوستكو شيبينغ', 'COSCO', 'https://www.coscoclean.com/search?keyword={container_no}'),
('Maersk', 'مارسك', 'MAERSK', 'https://www.maersk.com/tracking/{container_no}'),
('MSC', 'MSC', 'MSC', 'https://www.msc.com/track-shipment/{container_no}'),
('Evergreen', 'إيفرغرين', 'EGL', 'https://www.evergreen-marine.com/'),
('Yang Ming', 'يانغ مينغ', 'YML', 'https://www.yangming.com/')
ON CONFLICT (code) DO NOTHING;

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
('Aden Port', 'ميناء عدن', 'ADE', 'اليمن', 'عدن'),
('Hodeidah Port', 'ميناء الحديدة', 'HOD', 'اليمن', 'الحديدة'),
('Mukalla Port', 'ميناء المكلا', 'MUK', 'اليمن', 'المكلا')
ON CONFLICT (code) DO NOTHING;

-- الأقسام الافتراضية
INSERT INTO departments (branch_id, name, name_ar, code)
SELECT b.id, 'Operations', 'العمليات', b.code || '-OPS' FROM branches b
UNION ALL
SELECT b.id, 'Finance', 'المالية', b.code || '-FIN' FROM branches b
UNION ALL
SELECT b.id, 'Administration', 'الإدارة', b.code || '-ADM' FROM branches b
ON CONFLICT (branch_id, name) DO NOTHING;

-- الأدوار الأولية (تُزامَن وتُسحب من ERPNext لاحقاً)
INSERT INTO platform_roles (role_code, role_name_ar, erpnext_role, is_system) VALUES
('SYSTEM-ADMIN', 'مدير النظام', 'Administrator', TRUE),
('CHN-MANAGER', 'مدير عمليات الصين', 'China Operations Manager', FALSE),
('CHN-VENDOR', 'مورد السوق', 'Marketplace Vendor', FALSE),
('YEM-MANAGER', 'مدير عمليات اليمن', 'Yemen Operations Manager', FALSE),
('YEM-OPERATOR', 'مشغل ميناء اليمن', 'Yemen Port Operator', FALSE),
('FILTERING-AUDITOR', 'مدقق مالي', 'Finance Auditor', FALSE)
ON CONFLICT (role_code) DO NOTHING;

-- مصفوفة الصلاحيات الافتراضية للمدير العام
INSERT INTO permission_matrix (role_id, resource, actions)
SELECT r.role_id, res.resource,
       CASE WHEN r.role_code = 'SYSTEM-ADMIN'
            THEN ARRAY['read','create','update','delete','approve']
            ELSE ARRAY['read'] END
FROM platform_roles r
CROSS JOIN (VALUES
    ('branches'), ('warehouses'), ('employees'), ('users'),
    ('customers'), ('shipments'), ('containers'), ('tracking'),
    ('invoices'), ('payments'), ('ports'), ('shipping_lines'), ('outbox')
) AS res(resource)
WHERE r.role_code = 'SYSTEM-ADMIN'
ON CONFLICT (role_id, resource) DO NOTHING;

-- إنشاء مستخدم مسؤول افتراضي (كلمة المرور: Admin123!)
INSERT INTO users (username, email, password_hash, full_name, full_name_ar, role, default_branch_id)
SELECT 'admin', 'admin@shipping.com',
       '$2b$12$8/93VO0azt8Hn5gGPUR0ieEdMftUN8jbsJG5fK5KRI59SfB.1HaGq',
       'General Manager', 'المدير العام', 'admin', id
FROM branches WHERE code = 'CHN'
ON CONFLICT (username) DO NOTHING;

-- ربط مدير النظام بدور SYSTEM-ADMIN في فرعه الافتراضي
INSERT INTO user_branch_roles (user_id, branch_id, role_id)
SELECT u.id, u.default_branch_id, r.role_id
FROM users u CROSS JOIN platform_roles r
WHERE u.username = 'admin' AND r.role_code = 'SYSTEM-ADMIN'
ON CONFLICT (user_id, branch_id, role_id) DO NOTHING;

-- ملاحظة: كلمة المرور الافتراضية مشفرة باستخدام bcrypt لـ "Admin123!"

-- ============================================================================
-- صلاحيات مستخدم التطبيق (اختياري - ألغِ التعليق عند الحاجة)
-- ============================================================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shipping_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shipping_user;

SELECT 'Unified shipping & administration database schema ready' AS status;
