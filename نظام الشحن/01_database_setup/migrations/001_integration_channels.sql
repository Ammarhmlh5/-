-- Integration channel tables for ADMIN, MARKET, and SHIPPING.
-- Secrets are never stored here; secret_ref points to the configured secret manager.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS integration_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_code VARCHAR(20) NOT NULL UNIQUE
        CHECK (channel_code IN ('ADMIN', 'MARKET', 'SHIPPING')),
    target_system VARCHAR(30) NOT NULL DEFAULT 'ERPNEXT',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'DISABLED', 'SUSPENDED')),
    current_credential_id UUID,
    previous_credential_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS integration_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES integration_channels(id) ON DELETE CASCADE,
    owner_type VARCHAR(30) NOT NULL DEFAULT 'SYSTEM'
        CHECK (owner_type IN ('SYSTEM', 'CUSTOMER', 'SUPPLIER', 'EMPLOYEE')),
    owner_id UUID,
    secret_ref VARCHAR(300) NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    secret_hash CHAR(128) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'GRACE_PERIOD', 'REVOKED', 'EXPIRED')),
    scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    environment VARCHAR(20) NOT NULL DEFAULT 'production'
        CHECK (environment IN ('development', 'staging', 'production')),
    created_by UUID NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    activated_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS integration_key_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credential_id UUID REFERENCES integration_credentials(id) ON DELETE SET NULL,
    channel_code VARCHAR(20) NOT NULL
        CHECK (channel_code IN ('ADMIN', 'MARKET', 'SHIPPING')),
    actor_id UUID,
    action VARCHAR(40) NOT NULL,
    request_id UUID NOT NULL,
    result VARCHAR(20) NOT NULL,
    reason_code VARCHAR(80),
    source_ip INET,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_integration_credentials_channel_status
    ON integration_credentials(channel_id, status);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_owner
    ON integration_credentials(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_credential
    ON integration_key_events(credential_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_request
    ON integration_key_events(request_id);
CREATE INDEX IF NOT EXISTS idx_integration_key_events_created_at
    ON integration_key_events(created_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_integration_current_credential
    ON integration_channels(current_credential_id)
    WHERE current_credential_id IS NOT NULL;

ALTER TABLE integration_channels
    DROP CONSTRAINT IF EXISTS fk_channel_current_credential;
ALTER TABLE integration_channels
    ADD CONSTRAINT fk_channel_current_credential
    FOREIGN KEY (current_credential_id) REFERENCES integration_credentials(id)
    ON DELETE SET NULL;

ALTER TABLE integration_channels
    DROP CONSTRAINT IF EXISTS fk_channel_previous_credential;
ALTER TABLE integration_channels
    ADD CONSTRAINT fk_channel_previous_credential
    FOREIGN KEY (previous_credential_id) REFERENCES integration_credentials(id)
    ON DELETE SET NULL;

INSERT INTO integration_channels (channel_code)
VALUES ('ADMIN'), ('MARKET'), ('SHIPPING')
ON CONFLICT (channel_code) DO NOTHING;