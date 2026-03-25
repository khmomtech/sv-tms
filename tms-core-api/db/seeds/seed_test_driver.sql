-- Idempotent seed: create a test driver if not exists
-- Usage: run this against the `svlogistics_tms_db` database

INSERT INTO drivers (first_name, last_name, license_number, phone, is_active, status, is_partner)
SELECT 'Test', 'Driver', 'TEST-LIC-001', '+10000000001', 1, 'ONLINE', 0
WHERE NOT EXISTS (
  SELECT 1 FROM drivers WHERE license_number = 'TEST-LIC-001'
);

-- Optionally insert an approved device for the driver. This is left out here so the helper script
-- can insert it with the correct driver_id after the driver row exists.
