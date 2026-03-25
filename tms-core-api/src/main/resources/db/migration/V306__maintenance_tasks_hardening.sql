-- Tighten maintenance tasks, status semantics and foreign keys

-- Ensure status has a value
UPDATE maintenance_tasks SET status = COALESCE(status, 'OPEN');

-- Add indexes if not present
CREATE INDEX IF NOT EXISTS idx_mtask_vehicle ON maintenance_tasks(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mtask_status  ON maintenance_tasks(status);