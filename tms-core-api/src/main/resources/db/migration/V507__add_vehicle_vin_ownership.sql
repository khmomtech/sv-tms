-- Add VIN and ownership fields to vehicles table
-- Migration: V507__add_vehicle_vin_ownership.sql

ALTER TABLE vehicles
ADD COLUMN vin VARCHAR(17) UNIQUE,
ADD COLUMN ownership ENUM('OWNED', 'LEASED', 'VENDOR') NOT NULL DEFAULT 'OWNED';

-- Add index for VIN for performance
CREATE INDEX idx_vehicle_vin ON vehicles(vin);

-- Add comments for documentation
ALTER TABLE vehicles MODIFY COLUMN ownership ENUM('OWNED', 'LEASED', 'VENDOR') NOT NULL DEFAULT 'OWNED' COMMENT 'Vehicle ownership type: OWNED=company owned, LEASED=leased from external party, VENDOR=vendor/contractor vehicle';
ALTER TABLE vehicles MODIFY COLUMN vin VARCHAR(17) UNIQUE COMMENT 'Vehicle Identification Number (VIN) - 17 character standard format';