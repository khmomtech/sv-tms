-- ============================================================================
-- V516: Seed mechanics (sample data)
-- ============================================================================

INSERT INTO mechanics (user_id, staff_id, full_name, phone, active)
SELECT NULL, NULL, 'Chenda Sok', '012-555-201', TRUE
WHERE NOT EXISTS (SELECT 1 FROM mechanics WHERE full_name = 'Chenda Sok');

INSERT INTO mechanics (user_id, staff_id, full_name, phone, active)
SELECT NULL, NULL, 'Sophea Hem', '012-555-202', TRUE
WHERE NOT EXISTS (SELECT 1 FROM mechanics WHERE full_name = 'Sophea Hem');

INSERT INTO mechanics (user_id, staff_id, full_name, phone, active)
SELECT NULL, NULL, 'Dara Khem', '012-555-203', TRUE
WHERE NOT EXISTS (SELECT 1 FROM mechanics WHERE full_name = 'Dara Khem');
