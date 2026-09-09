-- Add automatic ERPNext synchronization state to local customers.
ALTER TABLE customers ADD COLUMN IF NOT EXISTS erpnext_sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS erpnext_sync_error TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS erpnext_synced_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX IF NOT EXISTS idx_customers_erpnext_sync_status ON customers(erpnext_sync_status);