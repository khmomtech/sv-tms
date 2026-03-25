-- Restore driver_latest_location table for SV-TMS
-- Run this SQL in your MySQL database

CREATE TABLE IF NOT EXISTS driver_latest_location (
  driver_id BIGINT NOT NULL PRIMARY KEY,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  speed DOUBLE,
  heading DOUBLE,
  dispatch_id BIGINT,
  last_seen DATETIME(6),
  is_online TINYINT(1),
  ws_connected TINYINT(1) NOT NULL DEFAULT 0,
  battery_level INT,
  location_name VARCHAR(255),
  source VARCHAR(32),
  version BIGINT,
  accuracy_meters DOUBLE,
  location_source VARCHAR(16),
  net_type VARCHAR(16),
  CONSTRAINT fk_driver_latest_location_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dll_online ON driver_latest_location(is_online);
CREATE INDEX idx_dll_last_seen ON driver_latest_location(last_seen);
CREATE INDEX idx_dll_online_lastseen ON driver_latest_location(is_online, last_seen);

-- Optional: Backfill from old drivers table if needed
INSERT INTO driver_latest_location (driver_id, latitude, longitude, last_seen, is_online)
SELECT d.id, COALESCE(d.latitude, 0.0), COALESCE(d.longitude, 0.0), COALESCE(d.last_location_at, NOW()), CASE WHEN d.status = 'ONLINE' THEN 1 ELSE 0 END
FROM drivers d
WHERE NOT EXISTS (
    SELECT 1 FROM driver_latest_location dll WHERE dll.driver_id = d.id
);
