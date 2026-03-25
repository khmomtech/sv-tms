-- Seed fixtures for local Driver App development (guarded by IF NOT EXISTS)
INSERT INTO drivers (id, first_name, last_name, name, license_number, license_class, phone, rating,
  performance_score, leaderboard_rank, on_time_percent, safety_score,
  is_active, zone, vehicle_type, status, is_partner)
SELECT
  72, 'Demo', 'Driver', 'Demo Driver', 'DEV-072', 'B', '017000072', 4.9,
  92, 8, 98, 'Excellent',
  1, 'PHNOM_PENH', 'TRUCK', 'ONLINE', 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM drivers WHERE id = 72);

INSERT INTO driver_latest_location (driver_id, latitude, longitude, last_seen, is_online, ws_connected)
SELECT
  72, 11.5564, 104.8800, NOW(), 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM driver_latest_location WHERE driver_id = 72);
