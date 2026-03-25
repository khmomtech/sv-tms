-- Rename vehicle_id column to vehicle_id in vehicle_drivers table
-- Ensures the entity maps to vehicle_id while preserving historical data

ALTER TABLE vehicle_drivers
    DROP FOREIGN KEY fk_permanent_assignment_truck;

ALTER TABLE vehicle_drivers
    DROP INDEX idx_truck_active;

ALTER TABLE vehicle_drivers
    CHANGE COLUMN vehicle_id vehicle_id BIGINT NOT NULL;

ALTER TABLE vehicle_drivers
    ADD CONSTRAINT fk_vehicle_drivers_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT;

ALTER TABLE vehicle_drivers
    ADD INDEX idx_vehicle_active (vehicle_id, revoked_at);
