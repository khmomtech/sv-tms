-- Backfill permanent_assignments from existing driver.vehicle_id data
-- This migration populates the new permanent_assignments table with historical data
-- Run this AFTER V317 has created the permanent_assignments table

-- Create temporary table to detect conflicts
CREATE TEMPORARY TABLE assignment_conflicts (
    driver_id BIGINT,
    vehicle_id BIGINT,
    conflict_type VARCHAR(50),
    details TEXT
);

-- Detect drivers with multiple vehicles (should not happen in 1:1 model)
INSERT INTO assignment_conflicts (driver_id, vehicle_id, conflict_type, details)
SELECT d.id, d.vehicle_id, 'DUPLICATE_DRIVER', 
       CONCAT('Driver ', d.id, ' assigned to vehicle ', d.vehicle_id, ' - check for duplicate assignments')
FROM drivers d
WHERE d.vehicle_id IS NOT NULL
GROUP BY d.id, d.vehicle_id
HAVING COUNT(*) > 1;

-- Detect vehicles assigned to multiple drivers
INSERT INTO assignment_conflicts (driver_id, vehicle_id, conflict_type, details)
SELECT d.id, d.vehicle_id, 'DUPLICATE_VEHICLE',
       CONCAT('Vehicle ', d.vehicle_id, ' assigned to multiple drivers - last driver: ', d.id)
FROM drivers d
WHERE d.vehicle_id IS NOT NULL
  AND d.vehicle_id IN (
      SELECT vehicle_id 
      FROM drivers 
      WHERE vehicle_id IS NOT NULL 
      GROUP BY vehicle_id 
      HAVING COUNT(DISTINCT id) > 1
  );

-- Log conflicts if any
SELECT 'CONFLICTS DETECTED:' as message, COUNT(*) as count FROM assignment_conflicts;
SELECT * FROM assignment_conflicts ORDER BY conflict_type, driver_id;

-- Insert valid assignments (no conflicts)
INSERT INTO permanent_assignments (
    driver_id,
    vehicle_id,
    assigned_at,
    assigned_by,
    reason,
    revoked_at,
    revoked_by,
    revoke_reason,
    created_at,
    updated_at,
    version
)
SELECT 
    d.id as driver_id,
    d.vehicle_id as vehicle_id,
    COALESCE(d.updated_at, d.created_at, NOW()) as assigned_at,
    'system-migration' as assigned_by,
    'Migrated from driver.vehicle_id during V318 backfill' as reason,
    NULL as revoked_at,
    NULL as revoked_by,
    NULL as revoke_reason,
    NOW() as created_at,
    NOW() as updated_at,
    0 as version
FROM drivers d
WHERE d.vehicle_id IS NOT NULL
  AND d.status = 'AVAILABLE'  -- Only active drivers
  AND d.id NOT IN (SELECT driver_id FROM assignment_conflicts)  -- Exclude conflicts
  AND d.vehicle_id NOT IN (SELECT vehicle_id FROM assignment_conflicts WHERE vehicle_id IS NOT NULL)  -- Exclude conflict vehicles
ON DUPLICATE KEY UPDATE
    -- If assignment already exists, don't overwrite
    driver_id = driver_id;

-- Log results
SELECT 
    'BACKFILL SUMMARY' as operation,
    (SELECT COUNT(*) FROM permanent_assignments) as total_assignments,
    (SELECT COUNT(*) FROM assignment_conflicts) as conflicts_detected,
    (SELECT COUNT(*) FROM drivers WHERE vehicle_id IS NOT NULL) as drivers_with_vehicles,
    NOW() as completed_at;

-- Clean up
DROP TEMPORARY TABLE assignment_conflicts;

-- Add comment for audit trail
ALTER TABLE permanent_assignments COMMENT = 'Permanent driver-truck assignments. Backfilled from driver.vehicle_id on 2025-01-15 via V318';
