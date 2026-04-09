-- Rename permanent_assignments table to vehicle_drivers
-- This migration renames the table while preserving all data, indexes, and constraints

-- Step 1: Rename the table
ALTER TABLE permanent_assignments RENAME TO vehicle_drivers;

-- Step 2: Verify indexes were automatically renamed (MySQL does this automatically)
-- The following indexes should now be on vehicle_drivers:
-- - idx_driver_active
-- - idx_truck_active  
-- - idx_assigned_at
-- - idx_revoked_at

-- Step 3: Update table comment
ALTER TABLE vehicle_drivers COMMENT = 'Vehicle-driver assignments (renamed from permanent_assignments). Tracks current and historical assignments.';

-- Validation queries (run these manually to verify)
-- SELECT COUNT(*) FROM vehicle_drivers;
-- SHOW INDEX FROM vehicle_drivers;
-- SHOW CREATE TABLE vehicle_drivers;
