-- Flyway migration: create driver_audit and vehicle_audit tables to store before/after snapshots
CREATE TABLE IF NOT EXISTS driver_audit (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT,
  action VARCHAR(64),
  payload_before JSON,
  payload_after JSON,
  created_by VARCHAR(128),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_audit (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  vehicle_id BIGINT,
  action VARCHAR(64),
  payload_before JSON,
  payload_after JSON,
  created_by VARCHAR(128),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
