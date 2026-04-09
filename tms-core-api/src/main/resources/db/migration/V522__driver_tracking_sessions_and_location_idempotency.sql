CREATE TABLE IF NOT EXISTS driver_tracking_sessions (
  session_id VARCHAR(64) PRIMARY KEY,
  driver_id BIGINT NOT NULL,
  device_id VARCHAR(128) NOT NULL,
  issued_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  last_seen DATETIME NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  CONSTRAINT fk_tracking_session_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(id)
);

CREATE INDEX idx_tracking_sessions_driver_active
  ON driver_tracking_sessions(driver_id, device_id, revoked_at, expires_at);

ALTER TABLE location_history
  ADD COLUMN IF NOT EXISTS point_id VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS seq BIGINT NULL,
  ADD COLUMN IF NOT EXISTS session_id VARCHAR(64) NULL;

CREATE UNIQUE INDEX uq_location_history_driver_point
  ON location_history(driver_id, point_id);

CREATE INDEX idx_location_history_session_time
  ON location_history(session_id, event_time);
