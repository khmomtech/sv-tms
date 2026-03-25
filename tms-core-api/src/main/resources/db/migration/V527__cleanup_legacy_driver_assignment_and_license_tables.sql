-- Cleanup legacy driver assignment + license tables.
--
-- This migration is safe to run multiple times and will only affect existing legacy tables.
-- It migrates any remaining driver_licenses data into driver_documents (category='license')
-- and then drops the legacy tables.

-- 0) Ensure canonical table vehicle_drivers exists.
--      If legacy permanent_assignments table still exists, promote it.
SET @has_vehicle_drivers = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'vehicle_drivers'
);
SET @has_permanent_assignments = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'permanent_assignments'
);

-- Rename permanent_assignments to vehicle_drivers if needed and if canonical table missing.
SET @rename_permanent_sql = IF(@has_vehicle_drivers = 0 AND @has_permanent_assignments > 0,
  'ALTER TABLE permanent_assignments RENAME TO vehicle_drivers',
  'SELECT 1'
);
PREPARE stmt FROM @rename_permanent_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure vehicle_drivers exists to preserve permanent assignment history.
CREATE TABLE IF NOT EXISTS vehicle_drivers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    assigned_at DATETIME NOT NULL,
    assigned_by VARCHAR(100) NOT NULL,
    reason VARCHAR(500),
    revoked_at DATETIME NULL,
    revoked_by VARCHAR(100),
    revoke_reason VARCHAR(500),
    version BIGINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NULL,
    INDEX idx_driver_active (driver_id, revoked_at),
    INDEX idx_truck_active (vehicle_id, revoked_at),
    INDEX idx_assigned_at (assigned_at),
    INDEX idx_revoked_at (revoked_at)
) ENGINE=InnoDB;

-- 1) Migrate driver_licenses into driver_documents (if driver_licenses exists)
SET @has_driver_licenses = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'driver_licenses'
);

SET @migrate_license_sql = CONCAT(
  'INSERT IGNORE INTO driver_documents (driver_id, category, description, is_required, created_at, updated_at) ',
  'SELECT dl.driver_id, ''license'', dl.license_number, FALSE, NOW(), NOW() ',
  'FROM driver_licenses dl WHERE dl.deleted = FALSE'
);

PREPARE stmt FROM IF(@has_driver_licenses > 0, @migrate_license_sql, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) Drop legacy license table (no longer used after migration)
DROP TABLE IF EXISTS driver_licenses;

-- 3) Drop legacy assignment tables (only vehicle_drivers should remain)
DROP TABLE IF EXISTS driver_assignments;
DROP TABLE IF EXISTS assignment_vehicle_to_driver;
DROP TABLE IF EXISTS permanent_assignments;

-- 4) Drop old historical artifacts that may linger
DROP TABLE IF EXISTS assignment_vehicle_to_driver_history;
DROP TABLE IF EXISTS driver_assignments_history;
