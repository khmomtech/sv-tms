-- Reset + reseed Dispatch Flow Template policy data
-- WARNING: This will delete all existing flow templates/rules/actors.
-- Safe for re-run.

START TRANSACTION;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM dispatch_flow_transition_actor;
DELETE FROM dispatch_flow_transition_rule;
DELETE FROM dispatch_flow_template;
SET FOREIGN_KEY_CHECKS = 1;

-- Normalize dispatch records after reset (default to GENERAL if missing/invalid)
UPDATE dispatches
SET loading_type_code = 'GENERAL'
WHERE loading_type_code IS NULL
   OR TRIM(loading_type_code) = ''
   OR UPPER(TRIM(loading_type_code)) NOT IN ('GENERAL', 'KHBL');


INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
  ('dispatch:flow:manage', 'Manage dispatch flow templates and transition policy', 'dispatch', 'flow:manage'),
  ('dispatch:status:override', 'Override dispatch status outside normal policy', 'dispatch', 'status:override'),
  ('dispatch:status:manual:update', 'Manual dispatch status update through admin channel', 'dispatch', 'status:manual:update');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('dispatch:flow:manage', 'dispatch:status:override', 'dispatch:status:manual:update')
WHERE r.name = 'SUPERADMIN';

INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'GENERAL', 'GENERAL', 'No G-Team control loading', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'GENERAL');

INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'KHBL', 'KHBL', 'G-Team control loading flow', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'KHBL');

-- Seed GENERAL transitions from current static transition map
INSERT IGNORE INTO dispatch_flow_transition_rule (template_id, from_status, to_status, enabled, priority, requires_confirmation, requires_input, validation_message)
SELECT t.id, x.from_status, x.to_status, TRUE, x.priority, x.requires_confirmation, x.requires_input, x.validation_message
FROM dispatch_flow_template t
JOIN (
  SELECT 'PLANNED' from_status, 'PENDING' to_status, 10 priority, FALSE requires_confirmation, FALSE requires_input, NULL validation_message UNION ALL
  SELECT 'PLANNED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'PENDING', 'ASSIGNED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'PENDING', 'SCHEDULED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'PENDING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'SCHEDULED', 'ASSIGNED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'SCHEDULED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ASSIGNED', 'DRIVER_CONFIRMED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ASSIGNED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ASSIGNED', 'REJECTED', 95, TRUE, TRUE, 'Rejection reason required' UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'ARRIVED_LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'APPROVED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'APPROVED', 'PENDING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'APPROVED', 'ASSIGNED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'APPROVED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ARRIVED_LOADING', 'SAFETY_PASSED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ARRIVED_LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'SAFETY_PASSED', 'IN_QUEUE', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'SAFETY_PASSED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'IN_QUEUE', 'LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_QUEUE', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'LOADING', 'LOADED', 10, FALSE, TRUE, 'Submit POL before leaving loading' UNION ALL
  SELECT 'LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'LOADED', 'AT_HUB', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'LOADED', 'IN_TRANSIT', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'LOADED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'AT_HUB', 'HUB_LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'AT_HUB', 'IN_TRANSIT', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'AT_HUB', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'HUB_LOADING', 'IN_TRANSIT', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'HUB_LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'IN_TRANSIT', 'ARRIVED_UNLOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_TRANSIT', 'AT_HUB', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_TRANSIT', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ARRIVED_UNLOADING', 'UNLOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ARRIVED_UNLOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'UNLOADING', 'UNLOADED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'SAFETY_PASSED', 30, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'SAFETY_FAILED', 40, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'UNLOADED', 'DELIVERED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'DELIVERED', 'FINANCIAL_LOCKED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'DELIVERED', 'COMPLETED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'FINANCIAL_LOCKED', 'CLOSED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'FINANCIAL_LOCKED', 'COMPLETED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'CLOSED', 'COMPLETED', 10, FALSE, FALSE, NULL
) x
WHERE t.code = 'GENERAL';

-- Clone GENERAL transitions to KHBL template if missing
INSERT IGNORE INTO dispatch_flow_transition_rule (template_id, from_status, to_status, enabled, priority, requires_confirmation, requires_input, validation_message)
SELECT khbl.id, r.from_status, r.to_status, r.enabled, r.priority, r.requires_confirmation, r.requires_input, r.validation_message
FROM dispatch_flow_template khbl
JOIN dispatch_flow_template general ON general.code = 'GENERAL'
JOIN dispatch_flow_transition_rule r ON r.template_id = general.id
WHERE khbl.code = 'KHBL';

-- GENERAL actors: DRIVER + operational teams + admin/system
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, a.actor_type, TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
JOIN (
  SELECT 'DRIVER' actor_type UNION ALL
  SELECT 'LOADING' UNION ALL
  SELECT 'SAFETY' UNION ALL
  SELECT 'DISPATCH_MONITOR' UNION ALL
  SELECT 'SYSTEM'
) a
WHERE t.code = 'GENERAL';

-- KHBL baseline actors same as GENERAL, then harden loading control below
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, a.actor_type, TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
JOIN (
  SELECT 'DRIVER' actor_type UNION ALL
  SELECT 'LOADING' UNION ALL
  SELECT 'SAFETY' UNION ALL
  SELECT 'DISPATCH_MONITOR' UNION ALL
  SELECT 'SYSTEM'
) a
WHERE t.code = 'KHBL';

-- KHBL hardening: driver cannot execute loading-control transitions
UPDATE dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
SET a.can_execute = FALSE
WHERE t.code = 'KHBL'
  AND a.actor_type = 'DRIVER'
  AND ((r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED'));

-- KHBL hardening: loading team explicitly controls queue/loading transitions
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, 'LOADING', TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code = 'KHBL'
  AND ((r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED'));

COMMIT;

-- Verification
SELECT code, name, active FROM dispatch_flow_template ORDER BY code;
SELECT t.code, COUNT(*) AS rule_count
FROM dispatch_flow_template t
LEFT JOIN dispatch_flow_transition_rule r ON r.template_id = t.id
GROUP BY t.code
ORDER BY t.code;
SELECT loading_type_code, COUNT(*) AS total
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;
