-- Remove legacy assignment_vehicle_to_driver table now replaced by vehicle_drivers.
-- Use IF EXISTS for safe re-runs.

DROP TABLE IF EXISTS assignment_vehicle_to_driver;
