-- ==========================================================================
-- V20260320: backfill and enforce non-null version on vehicle_drivers (DEPRECATED)
-- ========================================================================== 

-- This migration is preserved as a no-op for compatibility but is no longer
-- actively used. Legacy driver_assignments/permanent_assignments/driver_licenses
-- handling is fully covered by V527__cleanup_legacy_driver_assignment_and_license_tables.sql.

SELECT 1;
