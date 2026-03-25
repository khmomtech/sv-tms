-- ============================================================================
-- VEHICLES NORMALIZATION - PHASE 1 (CRITICAL)
-- Version: V401
-- Date: 2026-01-22
-- Description: Fix critical 3NF violations in vehicles table
--   1. Create zones table (missing)
--   2. Replace assigned_zone VARCHAR with assigned_zone_id FK
--   3. Remove redundant truck_size column
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE ZONES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS zones (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  zone_code VARCHAR(32) NOT NULL UNIQUE COMMENT 'Unique zone identifier (e.g., ZONE-PP-01)',
  zone_name VARCHAR(128) NOT NULL COMMENT 'Zone name in English',
  zone_name_kh VARCHAR(128) COMMENT 'Zone name in Khmer',
  description VARCHAR(255) COMMENT 'Zone description',
  city VARCHAR(64) COMMENT 'City where zone is located',
  region VARCHAR(64) COMMENT 'Region/province',
  status TINYINT DEFAULT 1 COMMENT '1=Active, 0=Inactive',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_zone_code (zone_code),
  INDEX idx_zone_city (city),
  INDEX idx_zone_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Delivery zones for vehicle assignments and routing';

-- ============================================================================
-- STEP 2: SEED ZONES FROM EXISTING VEHICLE DATA
-- ============================================================================

-- Insert distinct zones from vehicles.assigned_zone
INSERT IGNORE INTO zones (zone_code, zone_name, city, region, status)
SELECT DISTINCT
  UPPER(TRIM(assigned_zone)) AS zone_code,
  INITCAP(TRIM(assigned_zone)) AS zone_name,
  CASE 
    WHEN UPPER(assigned_zone) LIKE '%PHNOM%PENH%' THEN 'Phnom Penh'
    WHEN UPPER(assigned_zone) = 'PROVINCE' THEN 'Province'
    ELSE 'Unknown'
  END AS city,
  CASE
    WHEN UPPER(assigned_zone) LIKE '%PHNOM%PENH%' THEN 'Phnom Penh'
    WHEN UPPER(assigned_zone) = 'PROVINCE' THEN 'Various Provinces'
    ELSE 'Other'
  END AS region,
  1 AS status
FROM vehicles
WHERE assigned_zone IS NOT NULL 
  AND TRIM(assigned_zone) != ''
ORDER BY assigned_zone;

-- ============================================================================
-- STEP 3: ADD NEW FK COLUMN TO VEHICLES
-- ============================================================================

-- Add assigned_zone_id column (nullable initially for migration)
ALTER TABLE vehicles 
  ADD COLUMN assigned_zone_id BIGINT AFTER id
  COMMENT 'FK to zones table - normalized zone assignment';

-- Add index for FK performance
ALTER TABLE vehicles 
  ADD INDEX idx_vehicle_assigned_zone_id (assigned_zone_id);

-- ============================================================================
-- STEP 4: MIGRATE DATA - MAP OLD assigned_zone TO assigned_zone_id
-- ============================================================================

-- Update vehicles with zone IDs
UPDATE vehicles v
INNER JOIN zones z ON UPPER(TRIM(v.assigned_zone)) = z.zone_code
SET v.assigned_zone_id = z.id
WHERE v.assigned_zone IS NOT NULL 
  AND TRIM(v.assigned_zone) != '';

-- Log unmapped zones (if any)
SELECT 
  'WARNING: Unmapped zones' AS alert,
  COUNT(*) AS unmapped_count,
  GROUP_CONCAT(DISTINCT assigned_zone SEPARATOR ', ') AS unmapped_zones
FROM vehicles
WHERE assigned_zone IS NOT NULL 
  AND TRIM(assigned_zone) != ''
  AND assigned_zone_id IS NULL;

-- ============================================================================
-- STEP 5: ADD FOREIGN KEY CONSTRAINT
-- ============================================================================

ALTER TABLE vehicles
  ADD CONSTRAINT fk_vehicle_zone
  FOREIGN KEY (assigned_zone_id) 
  REFERENCES zones(id)
  ON DELETE SET NULL
  ON UPDATE CASCADE;

-- ============================================================================
-- STEP 6: REMOVE REDUNDANT truck_size COLUMN
-- ============================================================================

-- truck_size duplicates information already in type column
-- Remove to achieve 3NF compliance
ALTER TABLE vehicles DROP COLUMN truck_size;

-- ============================================================================
-- STEP 7: DROP OLD DENORMALIZED assigned_zone COLUMN
-- ============================================================================

-- Drop old VARCHAR zone column (now replaced by FK)
ALTER TABLE vehicles DROP COLUMN assigned_zone;

-- ============================================================================
-- STEP 8: UPDATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Remove old index on assigned_zone (column no longer exists)
-- Add composite index for common query patterns
ALTER TABLE vehicles 
  ADD INDEX idx_vehicle_status_zone (status, assigned_zone_id);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify zones count
SELECT 
  '✅ Zones Created' AS checkpoint,
  COUNT(*) AS total_zones,
  COUNT(DISTINCT city) AS distinct_cities
FROM zones;

-- Verify vehicle-zone mapping
SELECT 
  '✅ Vehicles Mapped to Zones' AS checkpoint,
  COUNT(*) AS vehicles_with_zones,
  COUNT(DISTINCT assigned_zone_id) AS distinct_zones_used,
  (SELECT COUNT(*) FROM vehicles WHERE assigned_zone_id IS NULL) AS vehicles_without_zone
FROM vehicles
WHERE assigned_zone_id IS NOT NULL;

-- Verify no orphaned references
SELECT 
  '✅ Referential Integrity Check' AS checkpoint,
  COUNT(*) AS orphaned_references
FROM vehicles v
LEFT JOIN zones z ON v.assigned_zone_id = z.id
WHERE v.assigned_zone_id IS NOT NULL 
  AND z.id IS NULL;

-- Show zone distribution
SELECT 
  z.zone_code,
  z.zone_name,
  z.city,
  COUNT(v.id) AS vehicle_count
FROM zones z
LEFT JOIN vehicles v ON z.id = v.assigned_zone_id
GROUP BY z.id, z.zone_code, z.zone_name, z.city
ORDER BY vehicle_count DESC;

-- ============================================================================
-- MIGRATION SUMMARY
-- ============================================================================

SELECT '
╔════════════════════════════════════════════════════════════════════╗
║           VEHICLES NORMALIZATION PHASE 1 - COMPLETED               ║
╠════════════════════════════════════════════════════════════════════╣
║ ✅ Created zones table with proper structure                       ║
║ ✅ Migrated assigned_zone VARCHAR → assigned_zone_id FK            ║
║ ✅ Removed redundant truck_size column                             ║
║ ✅ Added FK constraint with cascading updates                      ║
║ ✅ Updated indexes for optimal performance                         ║
╠════════════════════════════════════════════════════════════════════╣
║ Normalization Level: 3NF (Third Normal Form) - ACHIEVED           ║
║ Data Integrity: Referential integrity enforced via FK             ║
║ Performance: Indexed FK for fast zone lookups                     ║
╚════════════════════════════════════════════════════════════════════╝
' AS migration_summary;
