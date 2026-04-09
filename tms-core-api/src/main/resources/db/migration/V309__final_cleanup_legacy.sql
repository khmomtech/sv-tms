-- Remove legacy/duplicate columns ONLY after verifying the application is reading the new columns.
-- Comment out lines you don't need.

-- 1) Vehicles: drop old plate columns if present (we now use license_plate)
ALTER TABLE vehicles
  DROP COLUMN IF EXISTS plate_no,
  DROP COLUMN IF EXISTS plateNo,
  DROP COLUMN IF EXISTS reg_no;

-- 2) Legacy inspection table (data already migrated in V305)
DROP TABLE IF EXISTS inspection;

-- 3) Make vehicle status/type/fuel/ownership NOT NULL now that values exist
ALTER TABLE vehicles
  MODIFY COLUMN status      VARCHAR(32) NOT NULL,
  MODIFY COLUMN type        VARCHAR(32) NOT NULL,
  MODIFY COLUMN fuel_type   VARCHAR(16) NOT NULL,
  MODIFY COLUMN ownership   VARCHAR(16) NOT NULL;

-- 4) Ensure current_odometer_km has a default
ALTER TABLE vehicles
  MODIFY COLUMN current_odometer_km INT NOT NULL DEFAULT 0;