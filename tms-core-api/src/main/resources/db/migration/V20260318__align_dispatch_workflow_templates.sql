-- Align DB-backed dispatch workflows with expected driver flow.
-- Keep GENERAL as the default template and KHBL as the loading-controlled variant.

UPDATE dispatches
SET loading_type_code = 'GENERAL'
WHERE loading_type_code IS NULL OR TRIM(loading_type_code) = '';

-- Remove legacy APPROVED branch from DB-managed driver flows.
DELETE a
FROM dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code IN ('GENERAL', 'KHBL')
  AND (
    (r.from_status = 'DRIVER_CONFIRMED' AND r.to_status = 'APPROVED')
    OR r.from_status = 'APPROVED'
    OR r.to_status = 'APPROVED'
  );

DELETE r
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code IN ('GENERAL', 'KHBL')
  AND (
    (r.from_status = 'DRIVER_CONFIRMED' AND r.to_status = 'APPROVED')
    OR r.from_status = 'APPROVED'
    OR r.to_status = 'APPROVED'
  );

-- Require POD for unloading completion in driver-facing templates.
UPDATE dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
SET r.requires_input = TRUE,
    r.validation_message = 'Submit POD before completing unloading'
WHERE t.code IN ('GENERAL', 'KHBL')
  AND r.from_status = 'UNLOADING'
  AND r.to_status = 'UNLOADED';
