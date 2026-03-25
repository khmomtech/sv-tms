-- Add max_volume column to vehicles table and index
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS max_volume DECIMAL(10,2);

CREATE INDEX IF NOT EXISTS idx_vehicle_max_volume ON vehicles(max_volume);
