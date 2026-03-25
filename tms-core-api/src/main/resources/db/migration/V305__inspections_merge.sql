-- Migrate from legacy `inspection` table into `vehicle_inspections` (if you have it)
-- This is best-effort; adjust source columns as needed.

-- 1) Backfill vehicle_inspections from legacy inspection table if it exists
INSERT INTO vehicle_inspections (
  vehicle_id, inspection_type, inspection_date,
  brakes_checked, tires_checked, oil_checked, lights_checked, engine_checked,
  status, comments, photo_url, created_at, updated_at, is_deleted
)
SELECT
  i.vehicle_id,
  COALESCE(i.type, 'PRE_TRIP'),
  COALESCE(i.inspected_at, i.created_at, NOW()),
  COALESCE(i.brakes_ok, 0),
  COALESCE(i.tires_ok, 0),
  COALESCE(i.oil_ok, 0),
  COALESCE(i.lights_ok, 0),
  COALESCE(i.engine_ok, 0),
  CASE
    WHEN i.result IN ('PASS','OK') THEN 'PASS'
    WHEN i.result IN ('FAIL','NG') THEN 'FAIL'
    ELSE 'REQUIRES_SERVICE'
  END,
  i.comments,
  i.photo_url,
  i.created_at, i.updated_at, COALESCE(i.is_deleted,0)
FROM inspection i
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='inspection')
ON DUPLICATE KEY UPDATE inspection_date = VALUES(inspection_date);

-- 2) Helpful indexes
CREATE INDEX IF NOT EXISTS idx_vinsp_vehicle ON vehicle_inspections(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vinsp_date    ON vehicle_inspections(inspection_date);