-- Add request_type to maintenance_requests for PM/repair classification
SET @mr_request_type_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'maintenance_requests' AND column_name = 'request_type'
);

SET @sql := IF(
  @mr_request_type_col = 0,
  "ALTER TABLE maintenance_requests ADD COLUMN request_type ENUM('REPAIR','EMERGENCY','PM','INSPECTION') NOT NULL DEFAULT 'REPAIR'",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @mr_request_type_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'maintenance_requests' AND index_name = 'idx_mr_request_type'
);
SET @sql := IF(@mr_request_type_idx = 0, 'ALTER TABLE maintenance_requests ADD INDEX idx_mr_request_type (request_type)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
