CREATE TABLE IF NOT EXISTS vehicle_fuel_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  vehicle_id BIGINT NOT NULL,
  filled_at DATE,
  odometer_km DECIMAL(10,2),
  liters DECIMAL(10,2),
  amount DECIMAL(10,2),
  station VARCHAR(120),
  notes TEXT,
  created_by BIGINT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL,
  CONSTRAINT fk_vehicle_fuel_logs_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  CONSTRAINT fk_vehicle_fuel_logs_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_vehicle_fuel_logs_vehicle_id ON vehicle_fuel_logs(vehicle_id);
CREATE INDEX idx_vehicle_fuel_logs_filled_at ON vehicle_fuel_logs(filled_at);
