-- Add max_weight column to vehicles
ALTER TABLE vehicles
ADD COLUMN max_weight DECIMAL(10,2);

-- Optional: create an index for queries filtering by max_weight
CREATE INDEX idx_vehicle_max_weight ON vehicles(max_weight);
