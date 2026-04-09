-- Add temporary assignment override fields and assignment typing
ALTER TABLE drivers
  ADD COLUMN temp_assigned_vehicle_id BIGINT NULL,
  ADD COLUMN temp_assignment_expiry TIMESTAMP NULL;

ALTER TABLE driver_assignments
  ADD COLUMN assignment_type VARCHAR(16) NULL,
  ADD COLUMN reason VARCHAR(255) NULL;

ALTER TABLE drivers
  ADD CONSTRAINT fk_drivers_temp_vehicle
    FOREIGN KEY (temp_assigned_vehicle_id)
    REFERENCES vehicles(id);

-- Backfill existing driver_assignments rows as PERMANENT
UPDATE driver_assignments SET assignment_type = 'PERMANENT' WHERE assignment_type IS NULL;
