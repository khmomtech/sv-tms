-- V20260309: Deduplicate unload proofs per dispatch and enforce uniqueness.
-- Canonical row rule:
--   1) Keep greatest submitted_at
--   2) If submitted_at ties, keep greatest id
-- Idempotency:
--   - Re-running is safe because rows are already deduplicated and constraint creation is guarded.
-- Rollback note:
--   - Data deletions are not reversible by migration rollback; restore from backup if needed.
--
-- Deduplicate unload proofs per dispatch (keep newest submittedAt, then highest id).
-- NOTE: unload_proof_images has FK to unload_proof, so child rows must be removed first.
DROP TEMPORARY TABLE IF EXISTS tmp_unload_proof_delete_ids;
CREATE TEMPORARY TABLE tmp_unload_proof_delete_ids (id BIGINT PRIMARY KEY);

INSERT INTO tmp_unload_proof_delete_ids (id)
SELECT up1.id
FROM unload_proof up1
JOIN unload_proof up2
  ON up1.dispatch_id = up2.dispatch_id
 AND (
      COALESCE(up1.submitted_at, '1970-01-01 00:00:00') < COALESCE(up2.submitted_at, '1970-01-01 00:00:00')
      OR (
          COALESCE(up1.submitted_at, '1970-01-01 00:00:00') = COALESCE(up2.submitted_at, '1970-01-01 00:00:00')
          AND up1.id < up2.id
      )
 );

DELETE FROM unload_proof_images
WHERE unload_proof_id IN (SELECT id FROM tmp_unload_proof_delete_ids);

DELETE FROM unload_proof
WHERE id IN (SELECT id FROM tmp_unload_proof_delete_ids);

-- Enforce one proof row per dispatch_id (matches Dispatch <-> UnloadProof one-to-one mapping)
SET @uk_exists := (
  SELECT COUNT(*)
  FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'unload_proof'
    AND constraint_name = 'uk_unload_proof_dispatch'
    AND constraint_type = 'UNIQUE'
);

SET @uk_sql := IF(
  @uk_exists = 0,
  'ALTER TABLE unload_proof ADD CONSTRAINT uk_unload_proof_dispatch UNIQUE (dispatch_id)',
  'SELECT 1'
);

PREPARE stmt FROM @uk_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
