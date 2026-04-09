-- ============================================================================
-- V511: Failure Codes + Maintenance Request link
-- ============================================================================

CREATE TABLE IF NOT EXISTS failure_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    category VARCHAR(100),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_failure_code (code),
    INDEX idx_failure_code_active (active),
    INDEX idx_failure_code_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @mr_failure_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'maintenance_requests' AND column_name = 'failure_code_id'
);
SET @sql := IF(@mr_failure_col = 0, 'ALTER TABLE maintenance_requests ADD COLUMN failure_code_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @mr_failure_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'maintenance_requests' AND index_name = 'idx_mr_failure_code'
);
SET @sql := IF(@mr_failure_idx = 0, 'ALTER TABLE maintenance_requests ADD INDEX idx_mr_failure_code (failure_code_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @mr_failure_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE constraint_schema = DATABASE() AND table_name = 'maintenance_requests' AND constraint_name = 'fk_mr_failure_code'
);
SET @sql := IF(@mr_failure_fk = 0, 'ALTER TABLE maintenance_requests ADD CONSTRAINT fk_mr_failure_code FOREIGN KEY (failure_code_id) REFERENCES failure_codes(id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
