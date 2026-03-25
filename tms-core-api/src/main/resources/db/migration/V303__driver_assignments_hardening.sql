-- Ensure assignment lifecycle fields exist and are indexed

ALTER TABLE driver_assignments
  ADD COLUMN IF NOT EXISTS vehicle_id     BIGINT NULL,
  ADD COLUMN IF NOT EXISTS driver_id      BIGINT NULL,
  ADD COLUMN IF NOT EXISTS assigned_at    DATETIME NULL,
  ADD COLUMN IF NOT EXISTS unassigned_at  DATETIME NULL,
  ADD COLUMN IF NOT EXISTS completed_at   DATETIME NULL,
  ADD COLUMN IF NOT EXISTS status         VARCHAR(20) NULL;

-- Defaults
UPDATE driver_assignments SET status='ACTIVE' WHERE status IS NULL;
UPDATE driver_assignments SET assigned_at = COALESCE(assigned_at, NOW()) WHERE assigned_at IS NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_da_vehicle ON driver_assignments(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_da_driver  ON driver_assignments(driver_id);
CREATE INDEX IF NOT EXISTS idx_da_status  ON driver_assignments(status);