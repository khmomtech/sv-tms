-- Ensure the vehicle_drivers table only relies on vehicle_id
-- Drop the legacy vehicle_id column (which was added automatically via hibernate update)
-- and keep the new vehicle_id index for the active assignment query.

ALTER TABLE vehicle_drivers
    DROP INDEX IF EXISTS idx_truck_active;

ALTER TABLE vehicle_drivers
    DROP COLUMN IF EXISTS vehicle_id;

ALTER TABLE vehicle_drivers
    DROP INDEX IF EXISTS idx_vehicle_active;

ALTER TABLE vehicle_drivers
    ADD INDEX idx_vehicle_active (vehicle_id, revoked_at);

ALTER TABLE vehicle_drivers
    MODIFY COLUMN vehicle_id BIGINT NOT NULL;
