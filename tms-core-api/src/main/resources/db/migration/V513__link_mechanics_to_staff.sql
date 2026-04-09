-- ============================================================================
-- V513: Link mechanics to staff_members
-- ============================================================================

SET @mech_staff_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'mechanics' AND column_name = 'staff_id'
);
SET @sql := IF(@mech_staff_col = 0, 'ALTER TABLE mechanics ADD COLUMN staff_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @mech_staff_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'mechanics' AND index_name = 'uk_mechanic_staff'
);
SET @sql := IF(@mech_staff_uk = 0, 'ALTER TABLE mechanics ADD UNIQUE KEY uk_mechanic_staff (staff_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @mech_staff_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE constraint_schema = DATABASE() AND table_name = 'mechanics' AND constraint_name = 'fk_mechanic_staff'
);
SET @sql := IF(@mech_staff_fk = 0, 'ALTER TABLE mechanics ADD CONSTRAINT fk_mechanic_staff FOREIGN KEY (staff_id) REFERENCES staff_members(id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
