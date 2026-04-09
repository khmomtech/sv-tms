-- ============================================================================
-- Fleet Management Schema Improvements
-- Version: V320
-- Purpose: Add missing indexes, constraints, and optimize fleet tables
-- ============================================================================

-- ============================================================================
-- VEHICLES TABLE IMPROVEMENTS
-- ============================================================================

-- Add missing indexes for performance optimization
CREATE INDEX idx_vehicle_assigned_zone ON vehicles(assigned_zone);
CREATE INDEX idx_vehicle_gps_device_id ON vehicles(gps_device_id);
CREATE INDEX idx_vehicle_next_service_due ON vehicles(next_service_due);
CREATE INDEX idx_vehicle_status_type ON vehicles(status, type);
CREATE INDEX idx_vehicle_created_at ON vehicles(created_at);

-- Note: parent_vehicle_id index already exists as FK index

-- ============================================================================
-- DRIVERS TABLE IMPROVEMENTS
-- ============================================================================

-- Add missing indexes for performance optimization
CREATE INDEX idx_driver_status ON drivers(status);
CREATE INDEX idx_driver_zone ON drivers(zone);
CREATE INDEX idx_driver_status_partner ON drivers(status, is_partner);
CREATE INDEX idx_driver_license_expiry ON drivers(license_expiry);
CREATE INDEX idx_driver_last_seen_at ON drivers(last_seen_at);
CREATE INDEX idx_driver_temp_assignment ON drivers(temp_assignment_expiry, temp_assigned_vehicle_id);

-- ============================================================================
-- DRIVER_ASSIGNMENTS TABLE IMPROVEMENTS
-- ============================================================================

-- Add composite index for assignment history queries
CREATE INDEX idx_da_driver_assigned_at ON driver_assignments(driver_id, assigned_at);
CREATE INDEX idx_da_vehicle_assigned_at ON driver_assignments(vehicle_id, assigned_at);
CREATE INDEX idx_da_status_type ON driver_assignments(status, assignment_type);
CREATE INDEX idx_da_completed_at ON driver_assignments(completed_at);
CREATE INDEX idx_da_unassigned_at ON driver_assignments(unassigned_at);

-- Note: Unique partial indexes not supported in MySQL
-- Duplicate assignment prevention is enforced in application layer

-- ============================================================================
-- ANALYTICS VIEWS
-- ============================================================================

-- Create view for fleet availability summary
CREATE OR REPLACE VIEW v_fleet_availability AS
SELECT 
    v.status,
    v.type,
    v.truck_size,
    COUNT(*) as vehicle_count,
    COUNT(da.id) as assigned_count,
    (COUNT(*) - COUNT(da.id)) as available_count
FROM vehicles v
LEFT JOIN driver_assignments da ON da.vehicle_id = v.id 
    AND da.status = 'ASSIGNED'
    AND da.unassigned_at IS NULL
    AND da.completed_at IS NULL
GROUP BY v.status, v.type, v.truck_size;

-- Create view for driver assignment summary
CREATE OR REPLACE VIEW v_driver_assignment_summary AS
SELECT 
    d.id as driver_id,
    COALESCE(d.name, CONCAT(d.first_name, ' ', d.last_name)) as driver_name,
    d.phone,
    d.status as driver_status,
    da.id as assignment_id,
    da.assignment_type,
    da.status as assignment_status,
    v.id as vehicle_id,
    v.license_plate,
    v.type as vehicle_type,
    da.assigned_at,
    da.unassigned_at,
    da.completed_at
FROM drivers d
LEFT JOIN driver_assignments da ON da.driver_id = d.id 
    AND da.status = 'ASSIGNED'
LEFT JOIN vehicles v ON v.id = da.vehicle_id;

-- ============================================================================
-- AUDIT TABLES IMPROVEMENTS
-- ============================================================================

CREATE INDEX idx_vehicle_audit_created_at ON vehicle_audit(created_at);
CREATE INDEX idx_vehicle_audit_created_by ON vehicle_audit(created_by);
CREATE INDEX idx_driver_audit_created_at ON driver_audit(created_at);
CREATE INDEX idx_driver_audit_created_by ON driver_audit(created_by);

-- ============================================================================
-- PERFORMANCE STATISTICS
-- ============================================================================

ANALYZE TABLE vehicles;
ANALYZE TABLE drivers;
ANALYZE TABLE driver_assignments;
ANALYZE TABLE vehicle_audit;
ANALYZE TABLE driver_audit;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
