-- V400 Manual Migration: Database Schema Normalization
-- Execute only the parts that Hibernate auto-update hasn't done
-- WARNING: Backup database before running!

-- =============================================================================
-- PART 1: Foreign Key Constraints (Hibernate doesn't auto-create these)
-- =============================================================================

-- Add FK from driver_latest_location to drivers (if not exists)
SET @fk_exists = (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'driver_latest_location' 
    AND CONSTRAINT_NAME = 'fk_driver_latest_location_driver');

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE driver_latest_location ADD CONSTRAINT fk_driver_latest_location_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE',
    'SELECT ''FK fk_driver_latest_location_driver already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add FK from drivers to partner_company (if not exists)
SET @fk_exists = (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'drivers' 
    AND CONSTRAINT_NAME = 'fk_driver_partner_company');

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE drivers ADD CONSTRAINT fk_driver_partner_company FOREIGN KEY (partner_company_id) REFERENCES partner_company(id) ON DELETE SET NULL',
    'SELECT ''FK fk_driver_partner_company already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- PART 2: Cleanup Deprecated Columns
-- =============================================================================

-- Drop backup columns that still exist
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'drivers' 
    AND COLUMN_NAME = 'partner_company_backup');

SET @sql = IF(@col_exists > 0,
    'ALTER TABLE drivers DROP COLUMN partner_company_backup',
    'SELECT ''Column partner_company_backup does not exist'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'drivers' 
    AND COLUMN_NAME = 'zone_backup');

SET @sql = IF(@col_exists > 0,
    'ALTER TABLE drivers DROP COLUMN zone_backup',
    'SELECT ''Column zone_backup does not exist'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- PART 3: Create vehicle_routes table (if not exists)
-- =============================================================================

CREATE TABLE IF NOT EXISTS vehicle_routes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    route_name VARCHAR(100) NOT NULL,
    availability ENUM('AVAILABLE', 'UNAVAILABLE', 'TEMPORARILY_UNAVAILABLE') DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicle_route_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    INDEX idx_vehicle_route_vehicle (vehicle_id),
    INDEX idx_vehicle_route_availability (availability),
    UNIQUE KEY uk_vehicle_route (vehicle_id, route_name)
) COMMENT 'Normalized vehicle route assignments';

-- Migrate existing route data if available_routes column still exists
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'vehicles' 
    AND COLUMN_NAME = 'available_routes');

-- Create stored procedure to migrate routes
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS migrate_vehicle_routes()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id BIGINT;
    DECLARE v_routes TEXT;
    DECLARE cur CURSOR FOR SELECT id, available_routes FROM vehicles WHERE available_routes IS NOT NULL AND available_routes != '';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    IF @col_exists > 0 THEN
        OPEN cur;
        read_loop: LOOP
            FETCH cur INTO v_id, v_routes;
            IF done THEN
                LEAVE read_loop;
            END IF;
            
            -- Insert each route (comma-separated)
            SET @routes = v_routes;
            WHILE LENGTH(@routes) > 0 DO
                SET @route = TRIM(SUBSTRING_INDEX(@routes, ',', 1));
                IF @route != '' THEN
                    INSERT IGNORE INTO vehicle_routes (vehicle_id, route_name, availability)
                    VALUES (v_id, @route, 'AVAILABLE');
                END IF;
                
                IF LOCATE(',', @routes) > 0 THEN
                    SET @routes = SUBSTRING(@routes, LOCATE(',', @routes) + 1);
                ELSE
                    SET @routes = '';
                END IF;
            END WHILE;
        END LOOP;
        CLOSE cur;
        
        -- Drop the old column
        ALTER TABLE vehicles DROP COLUMN available_routes;
    END IF;
END//
DELIMITER ;

CALL migrate_vehicle_routes();
DROP PROCEDURE migrate_vehicle_routes;

-- Drop unavailable_routes if it exists
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'vehicles' 
    AND COLUMN_NAME = 'unavailable_routes');

SET @sql = IF(@col_exists > 0,
    'ALTER TABLE vehicles DROP COLUMN unavailable_routes',
    'SELECT ''Column unavailable_routes does not exist'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- PART 4: Performance Indexes
-- =============================================================================

-- Add indexes that Hibernate doesn't create automatically (with conditional checks)
SET @index_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'drivers' 
    AND INDEX_NAME = 'idx_driver_partner_company');
SET @sql = IF(@index_exists = 0,
    'CREATE INDEX idx_driver_partner_company ON drivers(partner_company_id)',
    'SELECT ''Index idx_driver_partner_company already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'driver_latest_location' 
    AND INDEX_NAME = 'idx_driver_latest_location');
SET @sql = IF(@index_exists = 0,
    'CREATE INDEX idx_driver_latest_location ON driver_latest_location(driver_id)',
    'SELECT ''Index idx_driver_latest_location already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'driver_latest_location' 
    AND INDEX_NAME = 'idx_driver_location_updated');
SET @sql = IF(@index_exists = 0,
    'CREATE INDEX idx_driver_location_updated ON driver_latest_location(last_seen)',
    'SELECT ''Index idx_driver_location_updated already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- PART 5: Update permanent_assignments to use proper FKs
-- =============================================================================
-- NOTE: Hibernate already created driver_id and vehicle_id as proper FK columns
-- We just need to ensure the constraints exist

SET @fk_exists = (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'permanent_assignments' 
    AND CONSTRAINT_NAME = 'fk_assignment_driver');

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE permanent_assignments ADD CONSTRAINT fk_assignment_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE',
    'SELECT ''FK fk_assignment_driver already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = 'svlogistics_tms_db' 
    AND TABLE_NAME = 'permanent_assignments' 
    AND CONSTRAINT_NAME = 'fk_assignment_truck');

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE permanent_assignments ADD CONSTRAINT fk_assignment_truck FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE',
    'SELECT ''FK fk_assignment_truck already exists'' AS status');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

SELECT 'Migration V400 manual execution completed!' AS status;
SELECT COUNT(*) AS driver_count FROM drivers;
SELECT COUNT(*) AS location_count FROM driver_latest_location;
SELECT COUNT(*) AS vehicle_route_count FROM vehicle_routes;
SELECT COUNT(*) AS assignment_count FROM permanent_assignments;
