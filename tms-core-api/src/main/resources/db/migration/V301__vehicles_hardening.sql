-- Normalize Vehicle to factory-ready shape (non-destructive, additive)

-- New/renamed core columns
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS license_plate      VARCHAR(50) NULL,
  ADD COLUMN IF NOT EXISTS vin                VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS manufacturer       VARCHAR(80) NULL,
  ADD COLUMN IF NOT EXISTS model              VARCHAR(80) NULL,
  ADD COLUMN IF NOT EXISTS year_made          INT NULL,
  ADD COLUMN IF NOT EXISTS type               VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS status             VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS fuel_type          VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS capacity_kg        INT NULL,
  ADD COLUMN IF NOT EXISTS volume_cbm         DECIMAL(10,2) NULL,
  ADD COLUMN IF NOT EXISTS current_odometer_km INT NULL,
  ADD COLUMN IF NOT EXISTS ownership          VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS partner_company    VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS gps_device_id      VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS remarks            TEXT NULL;

-- Backfill license_plate from common legacy columns (best-effort)
UPDATE vehicles
SET license_plate = COALESCE(license_plate, plate_no, plateNo, reg_no)
WHERE license_plate IS NULL;

-- Set sane defaults where NULL
UPDATE vehicles SET status='ACTIVE' WHERE status IS NULL;
UPDATE vehicles SET type='TRUCK' WHERE type IS NULL;
UPDATE vehicles SET fuel_type='DIESEL' WHERE fuel_type IS NULL;
UPDATE vehicles SET ownership='COMPANY' WHERE ownership IS NULL;
UPDATE vehicles SET current_odometer_km = 0 WHERE current_odometer_km IS NULL;

-- Unique index on license_plate (use a unique index, not table-level constraint for idempotency)
CREATE UNIQUE INDEX IF NOT EXISTS uq_vehicle_license ON vehicles(license_plate);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_vehicle_status     ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_ownership  ON vehicles(ownership);