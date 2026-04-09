-- Driver Index Optimization Migration
-- Optimizes driver table with critical indexes for common query patterns
-- Created: December 4, 2025

-- CRITICAL: Authentication lookups (findByUserId)
-- This index is essential for user authentication and authorization
CREATE INDEX IF NOT EXISTS idx_driver_user_id ON drivers(user_id);

-- HIGH PRIORITY: Search queries (searchDrivers, advancedSearch)
-- License number is frequently used in searches and must be unique
CREATE INDEX IF NOT EXISTS idx_driver_license_number ON drivers(license_number);

-- MEDIUM PRIORITY: Filtering queries
-- Composite index for common filter combination (active + status)
CREATE INDEX IF NOT EXISTS idx_driver_active_status ON drivers(is_active, status);

-- Zone-based filtering (dispatcher assignment, regional queries)
CREATE INDEX IF NOT EXISTS idx_driver_zone_status ON drivers(zone, status);

-- Vehicle type filtering (fleet management, assignment matching)
CREATE INDEX IF NOT EXISTS idx_driver_vehicle_type ON drivers(vehicle_type);

-- LOW PRIORITY: Partner queries
-- Separate company-owned vs partner drivers
CREATE INDEX IF NOT EXISTS idx_driver_partner ON drivers(is_partner);

-- Performance optimization: covering index for common list queries
-- Includes frequently selected columns to reduce table lookups
CREATE INDEX IF NOT EXISTS idx_driver_list_covering 
    ON drivers(is_active, status, zone, rating);

-- Username lookup (alternative authentication method)
-- Note: Ensure user_id foreign key is also indexed above
CREATE INDEX IF NOT EXISTS idx_driver_user_lookup 
    ON drivers(user_id, is_active);
