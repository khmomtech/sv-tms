-- ==========================================================================
-- V501: backfill optimistic locking version columns
-- ==========================================================================

-- Transport orders may still contain NULL versions from previous migrations.
UPDATE transport_orders SET version = 0 WHERE version IS NULL;
ALTER TABLE transport_orders
    MODIFY COLUMN version INT NOT NULL DEFAULT 0;

-- Ensure driver assignments also have non-null versions
-- Removed assignment_vehicle_to_driver references (table deleted)
    MODIFY COLUMN version BIGINT NOT NULL DEFAULT 0;

-- Keep permanent assignment versions healthy
UPDATE permanent_assignments SET version = 0 WHERE version IS NULL;
ALTER TABLE permanent_assignments
    MODIFY COLUMN version BIGINT NOT NULL DEFAULT 0;
