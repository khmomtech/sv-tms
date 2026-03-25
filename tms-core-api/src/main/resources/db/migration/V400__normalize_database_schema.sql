-- ============================================================================
-- Database Normalization Migration
-- Version: V400
-- Description: Comprehensive database normalization for driver and fleet management
-- Date: 2025-12-02
-- ============================================================================

-- ============================================================================
-- PART 1: Remove duplicate location data from drivers table
-- ============================================================================

-- Step 1: Ensure all drivers have entries in driver_latest_location
-- (Backfill missing entries with NULL values - will be updated by location tracking)
INSERT INTO driver_latest_location (driver_id, latitude, longitude, last_seen, is_online)
SELECT d.id, 
       COALESCE(d.latitude, 0.0), 
       COALESCE(d.longitude, 0.0),
       COALESCE(d.last_location_at, NOW()),
       CASE WHEN d.status = 'ONLINE' THEN 1 ELSE 0 END
FROM drivers d
WHERE NOT EXISTS (
    SELECT 1 FROM driver_latest_location dll WHERE dll.driver_id = d.id
);

-- Step 2: Drop redundant location columns from drivers table
ALTER TABLE drivers DROP COLUMN latitude;
ALTER TABLE drivers DROP COLUMN longitude;
ALTER TABLE drivers DROP COLUMN last_location_at;

-- ============================================================================
-- PART 2: Add foreign key constraint to driver_latest_location
-- ============================================================================

-- Clean up orphan driver_latest_location entries before applying FK constraint.
DELETE FROM driver_latest_location
WHERE driver_id IS NOT NULL
  AND driver_id NOT IN (SELECT id FROM drivers);

-- Add foreign key if it doesn't exist
ALTER TABLE driver_latest_location
    ADD CONSTRAINT fk_driver_latest_location_driver 
    FOREIGN KEY (driver_id) REFERENCES drivers(id) 
    ON DELETE CASCADE;

-- ============================================================================
-- PART 3: Remove deprecated and backup fields from drivers
-- ============================================================================

-- Drop backup name fields (unclear purpose, causing confusion)
ALTER TABLE drivers DROP COLUMN first_name_backup;
ALTER TABLE drivers DROP COLUMN last_name_backup;
ALTER TABLE drivers DROP COLUMN name_backup;

-- Drop deprecated partner_company string field (use partner_company_id FK instead)
ALTER TABLE drivers
    DROP COLUMN partner_company;

-- ============================================================================
-- PART 4: Create VehicleRoute normalized table
-- ============================================================================

-- Create new table for vehicle routes
CREATE TABLE IF NOT EXISTS vehicle_routes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    route_name VARCHAR(100) NOT NULL,
    availability ENUM('AVAILABLE', 'RESTRICTED') NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicle_route_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(id) ON DELETE CASCADE,
    INDEX idx_vr_vehicle (vehicle_id),
    INDEX idx_vr_route (route_name),
    UNIQUE KEY uk_vehicle_route (vehicle_id, route_name, availability)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migrate data from available_routes TEXT column (assuming comma-separated values)
-- Note: This is a simplified migration. Adjust based on actual data format.
INSERT INTO vehicle_routes (vehicle_id, route_name, availability)
SELECT id, 
       TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(available_routes, ',', numbers.n), ',', -1)) AS route_name,
       'AVAILABLE'
FROM vehicles
CROSS JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
) numbers
WHERE available_routes IS NOT NULL 
  AND available_routes != ''
  AND CHAR_LENGTH(available_routes) - CHAR_LENGTH(REPLACE(available_routes, ',', '')) >= numbers.n - 1
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(available_routes, ',', numbers.n), ',', -1)) != ''
ON DUPLICATE KEY UPDATE route_name = route_name; -- Skip duplicates

-- Migrate data from unavailable_routes TEXT column
INSERT INTO vehicle_routes (vehicle_id, route_name, availability)
SELECT id, 
       TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(unavailable_routes, ',', numbers.n), ',', -1)) AS route_name,
       'RESTRICTED'
FROM vehicles
CROSS JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
) numbers
WHERE unavailable_routes IS NOT NULL 
  AND unavailable_routes != ''
  AND CHAR_LENGTH(unavailable_routes) - CHAR_LENGTH(REPLACE(unavailable_routes, ',', '')) >= numbers.n - 1
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(unavailable_routes, ',', numbers.n), ',', -1)) != ''
ON DUPLICATE KEY UPDATE route_name = route_name; -- Skip duplicates

-- Drop old TEXT columns
ALTER TABLE vehicles DROP COLUMN available_routes;
ALTER TABLE vehicles DROP COLUMN unavailable_routes;

-- ============================================================================
-- PART 5: Add license class fields for driver-vehicle compatibility validation
-- ============================================================================

-- Add license class to drivers
ALTER TABLE drivers
    ADD COLUMN license_class VARCHAR(10) COMMENT 'License class: A, B, C, D, E, COMMERCIAL, MOTORCYCLE';

-- Add required license class to vehicles
ALTER TABLE vehicles
    ADD COLUMN required_license_class VARCHAR(10) COMMENT 'Required license class to operate this vehicle';

-- Add index for license class queries
CREATE INDEX IF NOT EXISTS idx_driver_license_class ON drivers(license_class);
CREATE INDEX IF NOT EXISTS idx_vehicle_required_license ON vehicles(required_license_class);

-- ============================================================================
-- PART 6: Add missing composite indexes for performance
-- ============================================================================

-- Driver composite indexes
CREATE INDEX IF NOT EXISTS idx_driver_zone_status ON drivers(zone, status);
CREATE INDEX IF NOT EXISTS idx_driver_partner ON drivers(is_partner, partner_company_id);
CREATE INDEX IF NOT EXISTS idx_driver_status_active ON drivers(status, is_active);

-- Vehicle composite indexes
CREATE INDEX IF NOT EXISTS idx_vehicle_zone_status ON vehicles(assigned_zone, status);
CREATE INDEX IF NOT EXISTS idx_vehicle_type_status ON vehicles(type, status);
CREATE INDEX IF NOT EXISTS idx_vehicle_type_size ON vehicles(type, truck_size);

-- Assignment history indexes
CREATE INDEX IF NOT EXISTS idx_da_history ON driver_assignments(driver_id, assigned_at DESC);
CREATE INDEX IF NOT EXISTS idx_da_vehicle_history ON driver_assignments(vehicle_id, assigned_at DESC);
CREATE INDEX IF NOT EXISTS idx_da_status_assigned ON driver_assignments(status, assigned_at DESC);

-- ============================================================================
-- PART 7: Improve VehicleDocument table structure
-- ============================================================================

-- Add audit fields if they don't exist
ALTER TABLE vehicle_documents
    ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN updated_by VARCHAR(100),
    ADD COLUMN deleted BOOLEAN DEFAULT FALSE;

-- Add index on deleted for soft delete queries
CREATE INDEX IF NOT EXISTS idx_vd_deleted ON vehicle_documents(deleted);
CREATE INDEX IF NOT EXISTS idx_vd_vehicle_active ON vehicle_documents(vehicle_id, deleted);

-- Convert document_type to use proper values (cleanup invalid data)
UPDATE vehicle_documents 
SET document_type = UPPER(TRIM(document_type))
WHERE document_type IS NOT NULL;

-- ============================================================================
-- PART 8: Data cleanup and constraints
-- ============================================================================

-- Ensure license_plate is NOT NULL and unique
UPDATE vehicles SET license_plate = CONCAT('UNKNOWN-', id) 
WHERE license_plate IS NULL OR license_plate = '';

ALTER TABLE vehicles
    MODIFY COLUMN license_plate VARCHAR(50) NOT NULL;

-- Ensure driver phone and license numbers are present
UPDATE drivers SET phone = CONCAT('MISSING-', id) 
WHERE phone IS NULL OR phone = '';

UPDATE drivers SET license_number = CONCAT('LIC-', id)
WHERE license_number IS NULL OR license_number = '';

-- ============================================================================
-- PART 9: Add table comments for documentation
-- ============================================================================

ALTER TABLE vehicle_routes COMMENT 'Normalized vehicle route assignments (replaces TEXT columns)';
ALTER TABLE driver_latest_location COMMENT 'Real-time driver locations (single source of truth for current position)';

-- ============================================================================
-- VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- SELECT COUNT(*) AS drivers_without_location 
-- FROM drivers d 
-- LEFT JOIN driver_latest_location dll ON d.id = dll.driver_id 
-- WHERE dll.driver_id IS NULL;

-- SELECT v.id, v.license_plate, COUNT(vr.id) AS route_count 
-- FROM vehicles v 
-- LEFT JOIN vehicle_routes vr ON v.id = vr.vehicle_id 
-- GROUP BY v.id, v.license_plate 
-- ORDER BY route_count DESC 
-- LIMIT 10;

-- SELECT COUNT(*) AS drivers_with_backup_fields 
-- FROM information_schema.columns 
-- WHERE table_schema = DATABASE() 
-- AND table_name = 'drivers' 
-- AND column_name LIKE '%_backup';

-- ============================================================================
-- END OF MIGRATION V400
-- ============================================================================
