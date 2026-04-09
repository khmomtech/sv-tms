-- ============================================================================
-- VEHICLES NORMALIZATION - PHASE 1 ROLLBACK
-- Version: U401_ROLLBACK
-- Date: 2026-01-22
-- Description: Rollback script to restore original vehicles table structure
-- WARNING: Use only if Phase 1 migration needs to be reverted
-- ============================================================================

-- ============================================================================
-- STEP 1: ADD BACK OLD COLUMNS
-- ============================================================================

-- Restore assigned_zone VARCHAR column
ALTER TABLE vehicles 
  ADD COLUMN assigned_zone VARCHAR(80) AFTER id
  COMMENT 'Zone assignment (denormalized - legacy)';

-- Restore truck_size ENUM column
ALTER TABLE vehicles
  ADD COLUMN truck_size ENUM('BIG_TRUCK','MEDIUM_TRUCK','SMALL_VAN')
  AFTER type
  COMMENT 'Truck size classification (redundant with type)';

-- ============================================================================
-- STEP 2: RESTORE DATA FROM NORMALIZED STRUCTURE
-- ============================================================================

-- Copy zone names back from zones table
UPDATE vehicles v
INNER JOIN zones z ON v.assigned_zone_id = z.id
SET v.assigned_zone = z.zone_code;

-- Restore truck_size based on type
UPDATE vehicles
SET truck_size = CASE
  WHEN type IN ('BIG_TRUCK', 'TRUCK') THEN 'BIG_TRUCK'
  WHEN type = 'VAN' THEN 'SMALL_VAN'
  ELSE NULL
END
WHERE type IN ('BIG_TRUCK', 'TRUCK', 'VAN');

-- ============================================================================
-- STEP 3: REMOVE FK CONSTRAINT
-- ============================================================================

ALTER TABLE vehicles 
  DROP FOREIGN KEY fk_vehicle_zone;

-- ============================================================================
-- STEP 4: DROP NORMALIZED COLUMNS
-- ============================================================================

-- Drop FK column
ALTER TABLE vehicles 
  DROP COLUMN assigned_zone_id;

-- ============================================================================
-- STEP 5: RESTORE OLD INDEXES
-- ============================================================================

-- Add back old index on assigned_zone
ALTER TABLE vehicles 
  ADD INDEX idx_vehicle_assigned_zone (assigned_zone);

-- Remove new composite index
ALTER TABLE vehicles 
  DROP INDEX idx_vehicle_status_zone;

-- ============================================================================
-- STEP 6: DROP ZONES TABLE (OPTIONAL)
-- ============================================================================

-- WARNING: This will permanently delete the zones table
-- Comment out if you want to keep zones data for reference

-- DROP TABLE IF EXISTS zones;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 
  '⚠️ ROLLBACK COMPLETED' AS status,
  COUNT(*) AS total_vehicles,
  COUNT(assigned_zone) AS vehicles_with_zone,
  COUNT(truck_size) AS vehicles_with_truck_size
FROM vehicles;

SELECT '
╔════════════════════════════════════════════════════════════════════╗
║        VEHICLES NORMALIZATION PHASE 1 - ROLLED BACK                ║
╠════════════════════════════════════════════════════════════════════╣
║ ⚠️  Restored assigned_zone VARCHAR column                          ║
║ ⚠️  Restored truck_size ENUM column                                ║
║ ⚠️  Removed FK constraint                                          ║
║ ⚠️  Removed assigned_zone_id column                                ║
║ ⚠️  Restored original index structure                              ║
╠════════════════════════════════════════════════════════════════════╣
║ Status: Back to original denormalized structure                    ║
║ Note: zones table preserved for reference (drop manually if needed)║
╚════════════════════════════════════════════════════════════════════╝
' AS rollback_summary;
