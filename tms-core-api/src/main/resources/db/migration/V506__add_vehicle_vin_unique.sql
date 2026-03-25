-- Add unique constraint for VIN if it does not already exist.
-- MySQL allows multiple NULLs in UNIQUE indexes, so optional VINs remain valid.

SET @vin_unique := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'vehicles'
    AND column_name = 'vin'
    AND non_unique = 0
);

SET @sql := IF(
  @vin_unique = 0,
  'ALTER TABLE vehicles ADD CONSTRAINT uk_vehicle_vin UNIQUE (vin)',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
