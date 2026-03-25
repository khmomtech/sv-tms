START TRANSACTION;

SET @driver_id := 30210;

INSERT INTO vehicles (
  manufacturer,
  model,
  license_plate,
  type,
  ownership,
  status,
  mileage,
  created_at,
  updated_at,
  is_deleted
)
SELECT
  'Toyota',
  'Dyna',
  'HOME-30210',
  'TRUCK',
  'OWNED',
  'ACTIVE',
  0,
  NOW(6),
  NOW(6),
  0
WHERE NOT EXISTS (
  SELECT 1 FROM vehicles WHERE license_plate = 'HOME-30210'
);

SET @vehicle_id := (
  SELECT id
  FROM vehicles
  WHERE license_plate = 'HOME-30210'
  ORDER BY id DESC
  LIMIT 1
);

UPDATE drivers
SET assigned_vehicle_id = @vehicle_id,
    updated_at = NOW()
WHERE id = @driver_id;

INSERT INTO safety_checks (
  check_date,
  driver_id,
  vehicle_id,
  status,
  notes,
  shift,
  created_at,
  updated_at
)
SELECT
  CURDATE(),
  @driver_id,
  @vehicle_id,
  'DRAFT',
  'Local seeded safety check for home screen verification.',
  'Morning',
  NOW(6),
  NOW(6)
WHERE NOT EXISTS (
  SELECT 1
  FROM safety_checks
  WHERE driver_id = @driver_id
    AND vehicle_id = @vehicle_id
    AND check_date = CURDATE()
);

INSERT INTO dispatches (
  version,
  route_code,
  tracking_no,
  from_location,
  to_location,
  driver_id,
  vehicle_id,
  start_time,
  estimated_arrival,
  status,
  trip_type,
  loading_type_code,
  created_date,
  updated_date,
  km_locked_flag,
  expense_locked_flag,
  financial_locked_flag,
  revenue_locked_flag,
  route_locked_flag,
  pol_required,
  pol_submitted,
  pod_required,
  pod_submitted,
  pod_verified,
  pre_entry_safety_required
)
SELECT
  0,
  'LOCAL-TRIP-30210-A',
  'LD-30210-A',
  'Phnom Penh Depot',
  'Siem Reap Hub',
  @driver_id,
  @vehicle_id,
  DATE_SUB(NOW(6), INTERVAL 30 MINUTE),
  DATE_ADD(NOW(6), INTERVAL 3 HOUR),
  'IN_TRANSIT',
  'REGULAR',
  'GENERAL',
  NOW(6),
  NOW(6),
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0'
WHERE NOT EXISTS (
  SELECT 1 FROM dispatches WHERE tracking_no = 'LD-30210-A'
);

INSERT INTO dispatches (
  version,
  route_code,
  tracking_no,
  from_location,
  to_location,
  driver_id,
  vehicle_id,
  start_time,
  estimated_arrival,
  status,
  trip_type,
  loading_type_code,
  created_date,
  updated_date,
  km_locked_flag,
  expense_locked_flag,
  financial_locked_flag,
  revenue_locked_flag,
  route_locked_flag,
  pol_required,
  pol_submitted,
  pod_required,
  pod_submitted,
  pod_verified,
  pre_entry_safety_required
)
SELECT
  0,
  'LOCAL-TRIP-30210-B',
  'LD-30210-B',
  'Battambang Yard',
  'Phnom Penh Depot',
  @driver_id,
  @vehicle_id,
  DATE_ADD(NOW(6), INTERVAL 2 HOUR),
  DATE_ADD(NOW(6), INTERVAL 6 HOUR),
  'ASSIGNED',
  'REGULAR',
  'GENERAL',
  NOW(6),
  NOW(6),
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0',
  b'0'
WHERE NOT EXISTS (
  SELECT 1 FROM dispatches WHERE tracking_no = 'LD-30210-B'
);

INSERT INTO banners (
  title,
  title_kh,
  subtitle,
  subtitle_kh,
  image_url,
  target_url,
  category,
  display_order,
  active,
  start_date,
  end_date,
  view_count,
  click_count,
  created_at,
  updated_at,
  created_by
)
SELECT
  'Important Update',
  'ព័ត៌មានសំខាន់',
  'Today''s seeded update for the driver home screen.',
  'ព័ត៌មានសម្រាប់តេស្តលើអេក្រង់ដើម',
  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200',
  'https://svt.local/banner/important-update',
  'important_updates',
  1,
  b'1',
  DATE_SUB(NOW(6), INTERVAL 1 DAY),
  DATE_ADD(NOW(6), INTERVAL 30 DAY),
  0,
  0,
  NOW(6),
  NOW(6),
  'local-seed'
WHERE NOT EXISTS (
  SELECT 1 FROM banners WHERE title = 'Important Update' AND category = 'important_updates'
);

INSERT INTO banners (
  title,
  title_kh,
  subtitle,
  subtitle_kh,
  image_url,
  target_url,
  category,
  display_order,
  active,
  start_date,
  end_date,
  view_count,
  click_count,
  created_at,
  updated_at,
  created_by
)
SELECT
  'Maintenance Reminder',
  'ការរំលឹកថែទាំ',
  'Check vehicle condition before departure.',
  'សូមពិនិត្យស្ថានភាពយានជំនិះមុនចេញដំណើរ',
  'https://images.unsplash.com/photo-1486006920555-c77dcf18193c?w=1200',
  'https://svt.local/banner/maintenance',
  'maintenance',
  2,
  b'1',
  DATE_SUB(NOW(6), INTERVAL 1 DAY),
  DATE_ADD(NOW(6), INTERVAL 30 DAY),
  0,
  0,
  NOW(6),
  NOW(6),
  'local-seed'
WHERE NOT EXISTS (
  SELECT 1 FROM banners WHERE title = 'Maintenance Reminder' AND category = 'maintenance'
);

COMMIT;
