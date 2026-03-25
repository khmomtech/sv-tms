-- After normalization, tighten required columns (only when safe)

-- Vehicles: make columns NOT NULL only if all rows are filled; otherwise leave nullable for now.
-- License plate should be NOT NULL going forward; backfilled earlier.
ALTER TABLE vehicles
  MODIFY COLUMN license_plate VARCHAR(50) NOT NULL;

-- Set default constraints via CHECK (MySQL 8.0 has limited CHECK support; use ENUMs carefully in prod changes)
-- Here we keep VARCHARs and rely on app-level enums + data normalization.

-- Enforce foreign keys if missing
ALTER TABLE driver_assignments
  ADD CONSTRAINT IF NOT EXISTS fk_da_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id);

ALTER TABLE driver_assignments
  ADD CONSTRAINT IF NOT EXISTS fk_da_driver  FOREIGN KEY (driver_id)  REFERENCES drivers(id);