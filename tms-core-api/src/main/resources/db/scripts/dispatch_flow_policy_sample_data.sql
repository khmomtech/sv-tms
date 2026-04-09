-- Manual sample data for dispatch flow policy testing
-- Safe to run multiple times.
-- Usage:
--   mysql -u <user> -p <db_name> < dispatch_flow_policy_sample_data.sql

START TRANSACTION;

-- 1) Ensure templates exist (idempotent)
INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'GENERAL', 'GENERAL', 'No G-Team control loading', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'GENERAL');

INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'KHBL', 'KHBL', 'G-Team control loading flow', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'KHBL');

-- 2) Tag recent dispatches with loading type for quick UAT
-- Latest 5 dispatches -> KHBL
UPDATE dispatches
SET loading_type_code = 'KHBL'
WHERE id IN (
  SELECT id FROM (
    SELECT id FROM dispatches ORDER BY id DESC LIMIT 5
  ) x
);

-- Next 5 dispatches -> GENERAL
UPDATE dispatches
SET loading_type_code = 'GENERAL'
WHERE id IN (
  SELECT id FROM (
    SELECT id FROM dispatches ORDER BY id DESC LIMIT 5 OFFSET 5
  ) x
);

COMMIT;

-- 3) Verification queries
SELECT code, name, active
FROM dispatch_flow_template
ORDER BY code;

SELECT loading_type_code, COUNT(*) AS total_dispatches
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;

SELECT id, status, loading_type_code, driver_id, updated_date
FROM dispatches
ORDER BY id DESC
LIMIT 15;
