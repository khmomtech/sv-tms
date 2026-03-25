-- Add index to speed up sweeper queries that mark drivers offline
CREATE INDEX IF NOT EXISTS idx_driver_latest_location_last_seen ON driver_latest_location (last_seen);
