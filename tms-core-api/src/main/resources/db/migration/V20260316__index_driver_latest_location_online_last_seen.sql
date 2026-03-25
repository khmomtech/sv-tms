-- Improve online/active driver lookups for live map queries.
CREATE INDEX IF NOT EXISTS idx_driver_latest_location_online_last_seen
  ON driver_latest_location (is_online, last_seen);
