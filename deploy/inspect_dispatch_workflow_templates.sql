-- Dispatch workflow rollout inspection queries.
-- Run these in staging/pilot after applying workflow-alignment migrations.

SELECT
  id,
  code,
  name,
  active,
  created_at,
  updated_at
FROM dispatch_flow_template
ORDER BY code;

SELECT
  t.code AS template_code,
  r.id AS rule_id,
  r.from_status,
  r.to_status,
  r.enabled,
  r.driver_initiated,
  r.requires_confirmation,
  r.requires_input,
  r.required_input,
  r.input_route_hint,
  r.display_order
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code IN ('GENERAL', 'KHBL')
ORDER BY t.code, r.from_status, r.display_order, r.to_status;

SELECT
  t.code AS template_code,
  r.from_status,
  r.to_status,
  a.actor_type,
  a.can_execute
FROM dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code IN ('GENERAL', 'KHBL')
ORDER BY t.code, r.from_status, r.to_status, a.actor_type;

SELECT
  id,
  dispatch_no,
  status,
  loading_type_code
FROM dispatches
WHERE loading_type_code IS NULL OR TRIM(loading_type_code) = ''
ORDER BY id DESC;

SELECT
  t.code AS template_code,
  r.from_status,
  r.to_status,
  r.enabled
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.active = TRUE
  AND (r.from_status = 'APPROVED' OR r.to_status = 'APPROVED')
ORDER BY t.code, r.from_status, r.to_status;

SELECT
  t.code AS template_code,
  r.from_status,
  r.to_status,
  r.requires_input,
  r.required_input,
  r.input_route_hint
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE (r.from_status = 'LOADING' AND r.to_status = 'LOADED')
   OR (r.from_status = 'UNLOADING' AND r.to_status = 'UNLOADED')
ORDER BY t.code, r.from_status, r.to_status;

SELECT
  t.code AS template_code,
  SUM(CASE WHEN r.from_status = 'APPROVED' OR r.to_status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_rule_count,
  SUM(CASE WHEN r.from_status = 'UNLOADING'
             AND r.to_status = 'UNLOADED'
             AND COALESCE(r.required_input, '') <> 'POD'
           THEN 1 ELSE 0 END) AS unload_without_pod_count
FROM dispatch_flow_template t
LEFT JOIN dispatch_flow_transition_rule r ON r.template_id = t.id
WHERE t.active = TRUE
GROUP BY t.code
ORDER BY t.code;
