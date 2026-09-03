ALTER TABLE payments ADD COLUMN IF NOT EXISTS erpnext_sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS erpnext_sync_error TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS erpnext_synced_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX IF NOT EXISTS idx_payments_erpnext_sync_status ON payments(erpnext_sync_status);