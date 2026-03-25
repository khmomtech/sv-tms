-- Rollback dispatch flow policy engine to static DispatchStateMachine behavior
-- Effect:
--   1) Set all dispatches loading_type_code to GENERAL
--   2) Remove template/rule/actor policy rows so backend falls back to static state machine
-- NOTE:
--   Does not remove permission rows.

START TRANSACTION;

UPDATE dispatches
SET loading_type_code = 'GENERAL';

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM dispatch_flow_transition_actor;
DELETE FROM dispatch_flow_transition_rule;
DELETE FROM dispatch_flow_template;
SET FOREIGN_KEY_CHECKS = 1;

COMMIT;

-- Verification
SELECT COUNT(*) AS templates_after_rollback FROM dispatch_flow_template;
SELECT COUNT(*) AS rules_after_rollback FROM dispatch_flow_transition_rule;
SELECT COUNT(*) AS actors_after_rollback FROM dispatch_flow_transition_actor;

SELECT loading_type_code, COUNT(*) AS total
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;
