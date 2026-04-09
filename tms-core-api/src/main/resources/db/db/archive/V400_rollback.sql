-- V400 Rollback Script: Revert Database Schema Normalization
-- WARNING: This will restore the old schema structure and may lose some data consistency
-- Created: 2025-12-02
-- Related: V400__normalize_database_schema.sql

-- =============================================================================
-- PART 1: RESTORE DRIVER LEGACY COLUMNS
-- =============================================================================

-- Re-add deprecated location columns to drivers table
ALTER TABLE drivers
    ADD COLUMN latitude DECIMAL(10, 8) COMMENT 'Deprecated: Use driver_latest_locations',
    ADD COLUMN longitude DECIMAL(11, 8) COMMENT 'Deprecated: Use driver_latest_locations',
    ADD COLUMN last_location_at TIMESTAMP NULL COMMENT 'Deprecated: Use driver_latest_locations';

-- Re-add backup name columns
ALTER TABLE drivers
    ADD COLUMN full_name_backup VARCHAR(255) COMMENT 'Backup of original full name',
    ADD COLUMN first_name_backup VARCHAR(100) COMMENT 'Backup of original first name',
    ADD COLUMN last_name_backup VARCHAR(100) COMMENT 'Backup of original last name';

-- Re-add deprecated partner company ID
ALTER TABLE drivers
    ADD COLUMN partner_company BIGINT COMMENT 'Deprecated: Use partner_company_id FK';

-- Copy data back from normalized tables
UPDATE drivers d
INNER JOIN driver_latest_locations dl ON d.id = dl.driver_id
SET d.latitude = dl.latitude,
    d.longitude = dl.longitude,
    d.last_location_at = dl.updated_at
WHERE dl.latitude IS NOT NULL OR dl.longitude IS NOT NULL;

UPDATE drivers d
SET d.partner_company = d.partner_company_id
WHERE d.partner_company_id IS NOT NULL;

-- =============================================================================
-- PART 2: DROP NORMALIZED FK CONSTRAINTS
-- =============================================================================

-- Drop foreign key from driver_latest_locations
ALTER TABLE driver_latest_locations
    DROP FOREIGN KEY IF EXISTS fk_driver_location_driver;

-- Drop foreign keys from permanent_assignments
ALTER TABLE permanent_assignments
    DROP FOREIGN KEY IF EXISTS fk_assignment_driver,
    DROP FOREIGN KEY IF EXISTS fk_assignment_truck;

-- Drop foreign key from drivers to partner_company
ALTER TABLE drivers
    DROP FOREIGN KEY IF EXISTS fk_driver_partner_company;

-- =============================================================================
-- PART 3: RESTORE DENORMALIZED VEHICLE ROUTES
-- =============================================================================

-- Re-add available_routes TEXT column to vehicles
ALTER TABLE vehicles
    ADD COLUMN available_routes TEXT COMMENT 'Comma-separated route names (denormalized)';

-- Copy routes back from normalized table
UPDATE vehicles v
SET v.available_routes = (
    SELECT GROUP_CONCAT(vr.route_name ORDER BY vr.route_name SEPARATOR ',')
    FROM vehicle_routes vr
    WHERE vr.vehicle_id = v.id
    AND vr.availability = 'AVAILABLE'
);

-- Drop the normalized vehicle_routes table
DROP TABLE IF EXISTS vehicle_routes;

-- =============================================================================
-- PART 4: RESTORE PERMANENT_ASSIGNMENTS STRUCTURE
-- =============================================================================

-- Re-add driver_id and vehicle_id as BIGINT columns
ALTER TABLE permanent_assignments
    ADD COLUMN driver_id_backup BIGINT,
    ADD COLUMN vehicle_id_backup BIGINT;

-- Copy IDs from FK relationships
UPDATE permanent_assignments pa
LEFT JOIN drivers d ON pa.driver_id = d.id
LEFT JOIN vehicles v ON pa.vehicle_id = v.id
SET pa.driver_id_backup = d.id,
    pa.vehicle_id_backup = v.id;

-- Drop the FK columns
ALTER TABLE permanent_assignments
    DROP COLUMN driver_id,
    DROP COLUMN vehicle_id;

-- Rename backup columns to original names
ALTER TABLE permanent_assignments
    CHANGE COLUMN driver_id_backup driver_id BIGINT,
    CHANGE COLUMN vehicle_id_backup vehicle_id BIGINT;

-- Add back original indexes
CREATE INDEX idx_permanent_assignment_driver ON permanent_assignments(driver_id);
CREATE INDEX idx_permanent_assignment_truck ON permanent_assignments(vehicle_id);

-- =============================================================================
-- PART 5: REVERT VEHICLE_DOCUMENTS ENHANCEMENTS
-- =============================================================================

-- Drop enum constraint on document_type
ALTER TABLE vehicle_documents
    MODIFY COLUMN document_type VARCHAR(50);

-- Drop audit columns
ALTER TABLE vehicle_documents
    DROP COLUMN IF EXISTS uploaded_by,
    DROP COLUMN IF EXISTS verified_by,
    DROP COLUMN IF EXISTS verified_at;

-- =============================================================================
-- PART 6: REMOVE LICENSE_CLASS NORMALIZATION
-- =============================================================================

-- Revert license_class to VARCHAR
ALTER TABLE drivers
    MODIFY COLUMN license_class VARCHAR(20);

-- =============================================================================
-- PART 7: DROP PERFORMANCE INDEXES
-- =============================================================================

-- Drop indexes added in V400
DROP INDEX IF EXISTS idx_driver_partner_company ON drivers;
DROP INDEX IF EXISTS idx_driver_latest_location ON driver_latest_locations;
DROP INDEX IF EXISTS idx_driver_location_updated ON driver_latest_locations;
DROP INDEX IF EXISTS idx_vehicle_route_vehicle ON vehicle_routes;
DROP INDEX IF EXISTS idx_vehicle_route_availability ON vehicle_routes;
DROP INDEX IF EXISTS idx_vehicle_document_vehicle ON vehicle_documents;
DROP INDEX IF EXISTS idx_vehicle_document_type ON vehicle_documents;
DROP INDEX IF EXISTS idx_vehicle_document_expiry ON vehicle_documents;

-- =============================================================================
-- PART 8: CLEANUP COMMENTS
-- =============================================================================

-- Remove table comments
ALTER TABLE drivers COMMENT '';
ALTER TABLE driver_latest_locations COMMENT '';
ALTER TABLE vehicles COMMENT '';
ALTER TABLE permanent_assignments COMMENT '';
ALTER TABLE vehicle_documents COMMENT '';

-- =============================================================================
-- PART 9: VERIFICATION QUERIES (RUN MANUALLY AFTER ROLLBACK)
-- =============================================================================

-- Check data restoration
-- SELECT COUNT(*) FROM drivers WHERE latitude IS NOT NULL; -- Should match pre-migration count
-- SELECT COUNT(*) FROM vehicles WHERE available_routes IS NOT NULL; -- Should match pre-migration count
-- SELECT COUNT(*) FROM permanent_assignments WHERE driver_id IS NOT NULL; -- Should match pre-migration count

-- Check no orphaned data
-- SELECT COUNT(*) FROM driver_latest_locations WHERE driver_id NOT IN (SELECT id FROM drivers);

-- =============================================================================
-- NOTES:
-- =============================================================================
-- 1. This rollback restores the old denormalized schema
-- 2. Data in vehicle_routes table will be LOST after rollback (converted back to TEXT)
-- 3. Enhanced vehicle_documents audit trail will be LOST
-- 4. Foreign key constraints will be removed
-- 5. After rollback, you must also revert entity/service code changes
-- 6. Backup database before running this rollback!
-- 
-- To execute this rollback:
-- 1. Stop the application
-- 2. Backup current database: ./backup_docker_mysql.sh
-- 3. Connect to MySQL: docker exec -it sv-tms-mysql-1 mysql -u root -p tms
-- 4. Source this file: source /path/to/V400_rollback.sql;
-- 5. Verify data integrity using queries in PART 9
-- 6. Revert entity/service code to pre-V400 state
-- 7. Rebuild and restart application
-- =============================================================================
