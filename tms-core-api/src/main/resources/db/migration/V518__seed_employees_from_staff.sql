-- Seed employees from existing staff_members when present
INSERT INTO employees (
  employee_code,
  first_name,
  last_name,
  email,
  phone,
  department,
  position,
  status,
  user_id
)
SELECT
  CONCAT('EMP-', LPAD(s.id, 4, '0')) AS employee_code,
  CASE
    WHEN s.full_name LIKE '% %' THEN SUBSTRING_INDEX(s.full_name, ' ', 1)
    ELSE s.full_name
  END AS first_name,
  CASE
    WHEN s.full_name LIKE '% %' THEN SUBSTRING(s.full_name, LOCATE(' ', s.full_name) + 1)
    ELSE ''
  END AS last_name,
  s.email,
  s.phone,
  s.department,
  s.job_title,
  CASE WHEN s.active THEN 'ACTIVE' ELSE 'INACTIVE' END AS status,
  s.user_id
FROM staff_members s
WHERE NOT EXISTS (
  SELECT 1 FROM employees e
  WHERE e.employee_code = CONCAT('EMP-', LPAD(s.id, 4, '0'))
);
