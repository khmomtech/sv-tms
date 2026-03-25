-- Optional preflight snapshot before modifying dispatch flow policy data
-- Creates backup tables with timestamp suffix (run manually and update suffix).

-- Change suffix before run (example: 20260306_0130)
SET @suffix = '20260306_0130';

SET @q1 = CONCAT('CREATE TABLE IF NOT EXISTS dispatch_flow_template_bak_', @suffix, ' AS SELECT * FROM dispatch_flow_template');
SET @q2 = CONCAT('CREATE TABLE IF NOT EXISTS dispatch_flow_transition_rule_bak_', @suffix, ' AS SELECT * FROM dispatch_flow_transition_rule');
SET @q3 = CONCAT('CREATE TABLE IF NOT EXISTS dispatch_flow_transition_actor_bak_', @suffix, ' AS SELECT * FROM dispatch_flow_transition_actor');
SET @q4 = CONCAT('CREATE TABLE IF NOT EXISTS dispatches_loading_type_bak_', @suffix, ' AS SELECT id, loading_type_code FROM dispatches');

PREPARE s1 FROM @q1; EXECUTE s1; DEALLOCATE PREPARE s1;
PREPARE s2 FROM @q2; EXECUTE s2; DEALLOCATE PREPARE s2;
PREPARE s3 FROM @q3; EXECUTE s3; DEALLOCATE PREPARE s3;
PREPARE s4 FROM @q4; EXECUTE s4; DEALLOCATE PREPARE s4;

SELECT 'Backup snapshot created' AS message, @suffix AS snapshot_suffix;
