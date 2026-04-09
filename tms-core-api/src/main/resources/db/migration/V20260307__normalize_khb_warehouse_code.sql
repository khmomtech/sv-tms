-- Canonicalize legacy warehouse code values from W1 to KHB.
-- Keeps historical data aligned with the new WarehouseCode enum mapping.

SET @db_name = DATABASE();

SET @has_loading_queue = (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = @db_name
      AND table_name = 'loading_queue'
);
SET @sql_loading_queue = IF(
    @has_loading_queue > 0,
    "UPDATE loading_queue SET warehouse_code = 'KHB' WHERE UPPER(TRIM(warehouse_code)) = 'W1'",
    "SELECT 1"
);
PREPARE stmt_loading_queue FROM @sql_loading_queue;
EXECUTE stmt_loading_queue;
DEALLOCATE PREPARE stmt_loading_queue;

SET @has_loading_session = (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = @db_name
      AND table_name = 'loading_session'
);
SET @sql_loading_session = IF(
    @has_loading_session > 0,
    "UPDATE loading_session SET warehouse_code = 'KHB' WHERE UPPER(TRIM(warehouse_code)) = 'W1'",
    "SELECT 1"
);
PREPARE stmt_loading_session FROM @sql_loading_session;
EXECUTE stmt_loading_session;
DEALLOCATE PREPARE stmt_loading_session;

SET @has_pre_entry_safety_check = (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = @db_name
      AND table_name = 'pre_entry_safety_check'
);
SET @sql_pre_entry_safety_check = IF(
    @has_pre_entry_safety_check > 0,
    "UPDATE pre_entry_safety_check SET warehouse_code = 'KHB' WHERE UPPER(TRIM(warehouse_code)) = 'W1'",
    "SELECT 1"
);
PREPARE stmt_pre_entry_safety_check FROM @sql_pre_entry_safety_check;
EXECUTE stmt_pre_entry_safety_check;
DEALLOCATE PREPARE stmt_pre_entry_safety_check;

SET @has_queue_sequencing_log = (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = @db_name
      AND table_name = 'queue_sequencing_log'
);
SET @sql_queue_sequencing_log = IF(
    @has_queue_sequencing_log > 0,
    "UPDATE queue_sequencing_log SET warehouse_code = 'KHB' WHERE UPPER(TRIM(warehouse_code)) = 'W1'",
    "SELECT 1"
);
PREPARE stmt_queue_sequencing_log FROM @sql_queue_sequencing_log;
EXECUTE stmt_queue_sequencing_log;
DEALLOCATE PREPARE stmt_queue_sequencing_log;
