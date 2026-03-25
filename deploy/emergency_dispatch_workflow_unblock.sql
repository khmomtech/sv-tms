-- Emergency dispatch workflow unblock
-- Purpose:
-- 1. default dispatches to GENERAL
-- 2. keep GENERAL and KHBL active
-- 3. enable all driver-facing rules
-- 4. remove POL/POD input gating from DB rules
-- 5. allow DRIVER to execute every configured rule
--
-- Run manually on the live database only when operations are blocked.

START TRANSACTION;

UPDATE dispatch_flow_template
SET active = TRUE
WHERE code IN ('GENERAL', 'KHBL');

UPDATE dispatches
SET loading_type_code = 'GENERAL'
WHERE loading_type_code IS NULL
   OR TRIM(loading_type_code) = ''
   OR UPPER(TRIM(loading_type_code)) NOT IN (
        SELECT code FROM (
          SELECT UPPER(code) AS code
          FROM dispatch_flow_template
          WHERE active = TRUE
        ) active_templates
      );

UPDATE dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
SET r.enabled = TRUE,
    r.requires_confirmation = FALSE,
    r.requires_input = FALSE,
    r.validation_message = NULL,
    r.metadata_json = JSON_OBJECT(
      'proofRequired', FALSE,
      'requiredInputType', 'NONE',
      'proofType', NULL,
      'proofSubmissionAllowedStatuses', JSON_ARRAY(),
      'proofSubmissionMode', 'EMERGENCY_BYPASS',
      'proofReviewRequired', FALSE,
      'allowLateProofRecovery', TRUE,
      'blockCode', NULL,
      'blockMessage', NULL
    )
WHERE t.code IN ('GENERAL', 'KHBL');

UPDATE dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
SET a.can_execute = TRUE
WHERE t.code IN ('GENERAL', 'KHBL')
  AND a.actor_type = 'DRIVER';

INSERT INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, 'DRIVER', TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
LEFT JOIN dispatch_flow_transition_actor a
  ON a.transition_rule_id = r.id
 AND a.actor_type = 'DRIVER'
WHERE t.code IN ('GENERAL', 'KHBL')
  AND a.id IS NULL;

COMMIT;

SELECT
  t.code AS template_code,
  r.from_status,
  r.to_status,
  r.enabled,
  r.requires_input,
  r.requires_confirmation
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code IN ('GENERAL', 'KHBL')
ORDER BY t.code, r.from_status, r.priority, r.to_status;

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
  AND a.actor_type = 'DRIVER'
ORDER BY t.code, r.from_status, r.to_status;
