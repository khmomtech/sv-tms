-- Ensure safety master constraints/indexes remain correct and idempotent.

-- Unique category code
SET @has_uk_cat_code := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'safety_check_categories'
    AND index_name = 'uk_safety_category_code'
    AND non_unique = 0
);
SET @sql := IF(
  @has_uk_cat_code = 0,
  'ALTER TABLE safety_check_categories ADD UNIQUE KEY uk_safety_category_code (code)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Unique item key
SET @has_uk_item_key := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'safety_check_master_items'
    AND index_name = 'uk_safety_item_key'
    AND non_unique = 0
);
SET @sql := IF(
  @has_uk_item_key = 0,
  'ALTER TABLE safety_check_master_items ADD UNIQUE KEY uk_safety_item_key (item_key)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Category index
SET @has_idx_category := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'safety_check_master_items'
    AND index_name = 'idx_safety_master_category'
);
SET @sql := IF(
  @has_idx_category = 0,
  'ALTER TABLE safety_check_master_items ADD INDEX idx_safety_master_category (category_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Foreign key integrity
SET @has_fk_category := (
  SELECT COUNT(*)
  FROM information_schema.referential_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'safety_check_master_items'
    AND constraint_name = 'fk_safety_master_category'
);
SET @sql := IF(
  @has_fk_category = 0,
  'ALTER TABLE safety_check_master_items ADD CONSTRAINT fk_safety_master_category FOREIGN KEY (category_id) REFERENCES safety_check_categories(id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
