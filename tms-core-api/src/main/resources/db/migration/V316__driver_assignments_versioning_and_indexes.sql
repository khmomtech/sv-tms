-- Add optimistic locking and useful composite indexes to driver_assignments

ALTER TABLE driver_assignments
  ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- Composite indexes to accelerate common filters
CREATE INDEX IF NOT EXISTS idx_da_status_assignedat
  ON driver_assignments(status, assigned_at);

CREATE INDEX IF NOT EXISTS idx_da_driver_status
  ON driver_assignments(driver_id, status);

CREATE INDEX IF NOT EXISTS idx_da_vehicle_status
  ON driver_assignments(vehicle_id, status);
