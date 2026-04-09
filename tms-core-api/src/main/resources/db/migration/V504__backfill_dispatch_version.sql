-- ==========================================================================
-- V504: backfill dispatches.version and enforce NOT NULL default
-- ==========================================================================

-- Set NULL versions to 0 for dispatches
UPDATE dispatches SET version = 0 WHERE version IS NULL;

-- Make version column NOT NULL with default 0
ALTER TABLE dispatches
    MODIFY COLUMN version BIGINT NOT NULL DEFAULT 0;

-- Sanity: ensure no remaining nulls
SELECT COUNT(*) AS dispatches_with_null_version FROM dispatches WHERE version IS NULL;
