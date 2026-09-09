-- Add product media metadata without storing binary files in PostgreSQL.
ALTER TABLE marketplace_catalog
    ADD COLUMN IF NOT EXISTS image_urls JSONB NOT NULL DEFAULT '[]'::jsonb;
