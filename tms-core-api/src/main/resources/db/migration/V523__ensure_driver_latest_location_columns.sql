-- Ensure driver_latest_location has all columns used by live tracking upsert queries.
-- This fixes silent write failures where location/presence endpoints return success
-- but no live rows are persisted, causing admin UI online count to stay at 0.

ALTER TABLE driver_latest_location
  ADD COLUMN IF NOT EXISTS speed DOUBLE NULL,
  ADD COLUMN IF NOT EXISTS heading DOUBLE NULL,
  ADD COLUMN IF NOT EXISTS dispatch_id BIGINT NULL,
  ADD COLUMN IF NOT EXISTS battery_level INT NULL,
  ADD COLUMN IF NOT EXISTS source VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS location_name VARCHAR(255) NULL,
  ADD COLUMN IF NOT EXISTS ws_connected TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accuracy_meters DOUBLE NULL,
  ADD COLUMN IF NOT EXISTS location_source VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS net_type VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS version BIGINT NULL;

-- Keep dispatch linkage best-effort; add FK only if table/column exists and not already constrained.
SET @fk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'driver_latest_location'
    AND CONSTRAINT_NAME = 'fk_dll_dispatch'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @ddl := IF(
  @fk_exists = 0,
  'ALTER TABLE driver_latest_location ADD CONSTRAINT fk_dll_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE SET NULL',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
