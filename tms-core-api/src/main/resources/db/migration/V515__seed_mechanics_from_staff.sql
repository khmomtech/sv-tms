-- ============================================================================
-- V515: Seed mechanics linked to staff members
-- ============================================================================

INSERT INTO mechanics (user_id, staff_id, full_name, phone, active)
SELECT s.user_id, s.id, s.full_name, s.phone, TRUE
FROM staff_members s
WHERE (s.department = 'Maintenance' OR s.job_title LIKE '%Mechanic%' OR s.job_title LIKE '%Maintenance%')
  AND NOT EXISTS (SELECT 1 FROM mechanics m WHERE m.staff_id = s.id);
