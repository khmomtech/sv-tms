-- Add max_volume column to vehicles
ALTER TABLE vehicles
  ADD COLUMN max_volume DECIMAL(10,2);

CREATE INDEX idx_vehicle_max_volume ON vehicles(max_volume);
