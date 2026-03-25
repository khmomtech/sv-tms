-- Ensure only one load proof exists per dispatch and enforce uniqueness.

-- Remove duplicate load proofs, keeping the most recent per dispatch.
DELETE lp
FROM load_proof lp
JOIN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY dispatch_id ORDER BY uploaded_at DESC, id DESC) AS rn
        FROM load_proof
    ) ranked
    WHERE rn > 1
) dup ON lp.id = dup.id;

-- Add a unique constraint on dispatch_id if it does not already exist.
SET @constraint_name := 'uq_load_proof_dispatch';
SET @exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
      AND TABLE_NAME = 'load_proof'
      AND CONSTRAINT_NAME = @constraint_name
);

SET @sql := IF(
    @exists = 0,
    'ALTER TABLE load_proof ADD CONSTRAINT uq_load_proof_dispatch UNIQUE (dispatch_id);',
    'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
