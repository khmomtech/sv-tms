-- ============================================================================
-- V514: Seed staff members (sample data)
-- ============================================================================

INSERT INTO staff_members (user_id, full_name, email, phone, job_title, department, active)
SELECT NULL, 'Sok Dara', 'dara.ops@svtms.local', '012-555-100', 'Dispatcher', 'Operations', TRUE
WHERE NOT EXISTS (SELECT 1 FROM staff_members WHERE full_name = 'Sok Dara');

INSERT INTO staff_members (user_id, full_name, email, phone, job_title, department, active)
SELECT NULL, 'Srey Neang', 'neang.hr@svtms.local', '012-555-101', 'HR Coordinator', 'HR', TRUE
WHERE NOT EXISTS (SELECT 1 FROM staff_members WHERE full_name = 'Srey Neang');

INSERT INTO staff_members (user_id, full_name, email, phone, job_title, department, active)
SELECT NULL, 'Vannak Lim', 'vannak.maint@svtms.local', '012-555-102', 'Maintenance Lead', 'Maintenance', TRUE
WHERE NOT EXISTS (SELECT 1 FROM staff_members WHERE full_name = 'Vannak Lim');

INSERT INTO staff_members (user_id, full_name, email, phone, job_title, department, active)
SELECT NULL, 'Rothana Chy', 'rothana.safety@svtms.local', '012-555-103', 'Safety Officer', 'Safety', TRUE
WHERE NOT EXISTS (SELECT 1 FROM staff_members WHERE full_name = 'Rothana Chy');

INSERT INTO staff_members (user_id, full_name, email, phone, job_title, department, active)
SELECT NULL, 'Bora Kim', 'bora.finance@svtms.local', '012-555-104', 'Accountant', 'Finance', TRUE
WHERE NOT EXISTS (SELECT 1 FROM staff_members WHERE full_name = 'Bora Kim');
