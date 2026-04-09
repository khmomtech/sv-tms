-- Separate pre-entry master data from daily safety master data.

CREATE TABLE IF NOT EXISTS pre_entry_check_categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL,
    name_km VARCHAR(255) NOT NULL,
    sort_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_pre_entry_category_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pre_entry_check_master_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    category_id BIGINT NOT NULL,
    item_key VARCHAR(100) NOT NULL,
    item_label_km VARCHAR(255) NOT NULL,
    check_time VARCHAR(50),
    sort_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_pre_entry_item_key (item_key),
    INDEX idx_pre_entry_master_category (category_id),
    CONSTRAINT fk_pre_entry_master_category FOREIGN KEY (category_id) REFERENCES pre_entry_check_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One-time backfill: clone current shared master data into pre-entry tables.
INSERT INTO pre_entry_check_categories (id, code, name_km, sort_order, is_active, created_at, updated_at)
SELECT s.id, s.code, s.name_km, s.sort_order, s.is_active, s.created_at, s.updated_at
FROM safety_check_categories s
LEFT JOIN pre_entry_check_categories p ON p.id = s.id
WHERE p.id IS NULL;

INSERT INTO pre_entry_check_master_items (id, category_id, item_key, item_label_km, check_time, sort_order, is_active, created_at, updated_at)
SELECT i.id, i.category_id, i.item_key, i.item_label_km, i.check_time, i.sort_order, i.is_active, i.created_at, i.updated_at
FROM safety_check_master_items i
JOIN pre_entry_check_categories c ON c.id = i.category_id
LEFT JOIN pre_entry_check_master_items p ON p.id = i.id
WHERE p.id IS NULL;

SET @next_pre_entry_category_id = (SELECT COALESCE(MAX(id), 0) + 1 FROM pre_entry_check_categories);
SET @sql_pre_entry_category_ai = CONCAT('ALTER TABLE pre_entry_check_categories AUTO_INCREMENT = ', @next_pre_entry_category_id);
PREPARE stmt_pre_entry_category_ai FROM @sql_pre_entry_category_ai;
EXECUTE stmt_pre_entry_category_ai;
DEALLOCATE PREPARE stmt_pre_entry_category_ai;

SET @next_pre_entry_item_id = (SELECT COALESCE(MAX(id), 0) + 1 FROM pre_entry_check_master_items);
SET @sql_pre_entry_item_ai = CONCAT('ALTER TABLE pre_entry_check_master_items AUTO_INCREMENT = ', @next_pre_entry_item_id);
PREPARE stmt_pre_entry_item_ai FROM @sql_pre_entry_item_ai;
EXECUTE stmt_pre_entry_item_ai;
DEALLOCATE PREPARE stmt_pre_entry_item_ai;
