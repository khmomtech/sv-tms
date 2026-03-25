-- KHBL Dispatch Flow Policy sample seed
-- Purpose: create/refresh KHBL template policy with G-Team controlled loading steps.
-- Safe to run multiple times.

START TRANSACTION;

-- 1) Ensure KHBL template exists
INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'KHBL', 'KHBL', 'G-Team control loading flow', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'KHBL');

-- 2) Ensure baseline transitions exist for KHBL
-- If GENERAL exists, clone missing transitions from GENERAL -> KHBL
INSERT IGNORE INTO dispatch_flow_transition_rule (
  template_id,
  from_status,
  to_status,
  enabled,
  priority,
  requires_confirmation,
  requires_input,
  validation_message
)
SELECT
  khbl.id,
  gr.from_status,
  gr.to_status,
  gr.enabled,
  gr.priority,
  gr.requires_confirmation,
  gr.requires_input,
  gr.validation_message
FROM dispatch_flow_template khbl
JOIN dispatch_flow_template general ON general.code = 'GENERAL'
JOIN dispatch_flow_transition_rule gr ON gr.template_id = general.id
WHERE khbl.code = 'KHBL';

-- If GENERAL is not available, seed minimum core path directly
INSERT IGNORE INTO dispatch_flow_transition_rule (
  template_id,
  from_status,
  to_status,
  enabled,
  priority,
  requires_confirmation,
  requires_input,
  validation_message
)
SELECT t.id, s.from_status, s.to_status, TRUE, s.priority, FALSE, FALSE, NULL
FROM dispatch_flow_template t
JOIN (
  SELECT 'ASSIGNED' from_status, 'DRIVER_CONFIRMED' to_status, 1 priority UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'ARRIVED_LOADING', 2 UNION ALL
  SELECT 'ARRIVED_LOADING', 'SAFETY_PASSED', 3 UNION ALL
  SELECT 'SAFETY_PASSED', 'IN_QUEUE', 4 UNION ALL
  SELECT 'IN_QUEUE', 'LOADING', 5 UNION ALL
  SELECT 'LOADING', 'LOADED', 6 UNION ALL
  SELECT 'LOADED', 'IN_TRANSIT', 7 UNION ALL
  SELECT 'IN_TRANSIT', 'ARRIVED_UNLOADING', 8 UNION ALL
  SELECT 'ARRIVED_UNLOADING', 'UNLOADING', 9 UNION ALL
  SELECT 'UNLOADING', 'UNLOADED', 10 UNION ALL
  SELECT 'UNLOADED', 'DELIVERED', 11
) s
WHERE t.code = 'KHBL';

-- 3) Ensure actor matrix rows exist for KHBL transitions
-- baseline actors (all true initially)
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

-- 4) KHBL governance: loading team controls queue/loading
-- Driver blocked for 3 loading-control transitions
UPDATE dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
SET a.can_execute = FALSE
WHERE t.code = 'KHBL'
  AND a.actor_type = 'DRIVER'
  AND (
    (r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED')
  );

-- LOADING role explicitly allowed on these 3 transitions
UPDATE dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
SET a.can_execute = TRUE
WHERE t.code = 'KHBL'
  AND a.actor_type = 'LOADING'
  AND (
    (r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED')
  );

-- 5) Optional: assign recent dispatches to KHBL for quick UAT (latest 5)
UPDATE dispatches
SET loading_type_code = 'KHBL'
WHERE id IN (
  SELECT id FROM (
    SELECT id FROM dispatches ORDER BY id DESC LIMIT 5
  ) x
);

COMMIT;

-- Verification
SELECT id, code, name, active FROM dispatch_flow_template WHERE code = 'KHBL';

SELECT r.id, r.from_status, r.to_status, r.priority, r.enabled
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code = 'KHBL'
ORDER BY r.priority, r.id;

SELECT r.from_status, r.to_status,
       MAX(CASE WHEN a.actor_type = 'DRIVER' THEN a.can_execute END) AS driver_can,
       MAX(CASE WHEN a.actor_type = 'LOADING' THEN a.can_execute END) AS loading_can,
       MAX(CASE WHEN a.actor_type = 'SAFETY' THEN a.can_execute END) AS safety_can
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
LEFT JOIN dispatch_flow_transition_actor a ON a.transition_rule_id = r.id
WHERE t.code = 'KHBL'
GROUP BY r.id, r.from_status, r.to_status
ORDER BY r.priority, r.id;

SELECT loading_type_code, COUNT(*) total
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;
