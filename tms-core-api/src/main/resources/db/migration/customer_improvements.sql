-- Customer Management Improvements Migration
-- Production-ready enhancements for data integrity and performance

-- Check and add columns individually (MySQL 8.0 compatible)

-- 5. Add soft delete columns
SET @dbname = 'svlogistics_tms_db';
SET @tablename = 'customers';

SET @col_exists_deleted_at = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'deleted_at');
SET @col_exists_deleted_by = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'deleted_by');

SET @sql_deleted_at = IF(@col_exists_deleted_at = 0, 
    'ALTER TABLE customers ADD COLUMN deleted_at TIMESTAMP NULL', 
    'SELECT "deleted_at already exists" AS message');
SET @sql_deleted_by = IF(@col_exists_deleted_by = 0, 
    'ALTER TABLE customers ADD COLUMN deleted_by VARCHAR(100) NULL', 
    'SELECT "deleted_by already exists" AS message');

PREPARE stmt FROM @sql_deleted_at; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_deleted_by; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 6. Add financial tracking columns
SET @col_exists_credit = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'credit_limit');
SET @col_exists_payment = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'payment_terms');
SET @col_exists_currency = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'currency');
SET @col_exists_balance = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'current_balance');
SET @col_exists_manager = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'account_manager_id');

SET @sql_credit = IF(@col_exists_credit = 0, 
    'ALTER TABLE customers ADD COLUMN credit_limit DECIMAL(15,2) DEFAULT 0.00', 'SELECT 1');
SET @sql_payment = IF(@col_exists_payment = 0, 
    'ALTER TABLE customers ADD COLUMN payment_terms VARCHAR(50) DEFAULT "NET_30"', 'SELECT 1');
SET @sql_currency = IF(@col_exists_currency = 0, 
    'ALTER TABLE customers ADD COLUMN currency VARCHAR(3) DEFAULT "USD"', 'SELECT 1');
SET @sql_balance = IF(@col_exists_balance = 0, 
    'ALTER TABLE customers ADD COLUMN current_balance DECIMAL(15,2) DEFAULT 0.00', 'SELECT 1');
SET @sql_manager = IF(@col_exists_manager = 0, 
    'ALTER TABLE customers ADD COLUMN account_manager_id BIGINT NULL', 'SELECT 1');

PREPARE stmt FROM @sql_credit; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_payment; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_currency; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_balance; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_manager; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 7. Add lifecycle stage column
SET @col_exists_lifecycle = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'lifecycle_stage');

SET @sql_lifecycle = IF(@col_exists_lifecycle = 0, 
    'ALTER TABLE customers ADD COLUMN lifecycle_stage VARCHAR(20) DEFAULT "CUSTOMER"', 'SELECT 1');

PREPARE stmt FROM @sql_lifecycle; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 8. Add business metrics columns
SET @col_exists_last_order = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'last_order_date');
SET @col_exists_total_orders = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'total_orders');
SET @col_exists_total_revenue = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'total_revenue');
SET @col_exists_first_order = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'first_order_date');

SET @sql_last_order = IF(@col_exists_last_order = 0, 
    'ALTER TABLE customers ADD COLUMN last_order_date DATE NULL', 'SELECT 1');
SET @sql_total_orders = IF(@col_exists_total_orders = 0, 
    'ALTER TABLE customers ADD COLUMN total_orders INT DEFAULT 0', 'SELECT 1');
SET @sql_total_revenue = IF(@col_exists_total_revenue = 0, 
    'ALTER TABLE customers ADD COLUMN total_revenue DECIMAL(15,2) DEFAULT 0.00', 'SELECT 1');
SET @sql_first_order = IF(@col_exists_first_order = 0, 
    'ALTER TABLE customers ADD COLUMN first_order_date DATE NULL', 'SELECT 1');

PREPARE stmt FROM @sql_last_order; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_total_orders; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_total_revenue; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_first_order; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 9. Add customer segment and tags
SET @col_exists_segment = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'segment');
SET @col_exists_tags = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tablename AND COLUMN_NAME = 'tags');

SET @sql_segment = IF(@col_exists_segment = 0, 
    'ALTER TABLE customers ADD COLUMN segment VARCHAR(50) NULL', 'SELECT 1');
SET @sql_tags = IF(@col_exists_tags = 0, 
    'ALTER TABLE customers ADD COLUMN tags JSON NULL', 'SELECT 1');

PREPARE stmt FROM @sql_segment; EXECUTE stmt; DEALLOCATE PREPARE stmt;
PREPARE stmt FROM @sql_tags; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 10. Update existing records to have proper defaults
UPDATE customers SET 
    credit_limit = COALESCE(credit_limit, 0.00),
    current_balance = COALESCE(current_balance, 0.00),
    total_orders = COALESCE(total_orders, 0),
    total_revenue = COALESCE(total_revenue, 0.00),
    lifecycle_stage = COALESCE(lifecycle_stage, 'CUSTOMER'),
    currency = COALESCE(currency, 'USD'),
    payment_terms = COALESCE(payment_terms, 'NET_30');

SELECT 'Customer improvements migration completed successfully' AS Status;
