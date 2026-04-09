-- Rebuild pre-entry master data from actual submitted pre-entry safety items.
-- Requested behavior: clear pre-entry master then migrate from pre_entry_safety_items.

-- 1) Clear existing pre-entry master data
DELETE FROM pre_entry_check_master_items;
DELETE FROM pre_entry_check_categories;

-- 2) Recreate categories from distinct codes in pre_entry_safety_items
INSERT INTO pre_entry_check_categories (code, name_km, sort_order, is_active)
SELECT
  src.category_code,
  CASE src.category_code
    WHEN 'LOAD' THEN 'ត្រូតពិនិត្យសម្ភារះលើឡានមុនចូលរោងចក្រ'
    WHEN 'DOCUMENTS' THEN 'ត្រូតពិនិត្យតៃកុងឡាន'
    WHEN 'WINDSHIELD' THEN 'ត្រួតពិនិត្យឡាន'
    WHEN 'LIGHTS' THEN 'ភ្លើង'
    WHEN 'TIRES' THEN 'សំបកកង់'
    WHEN 'WEIGHT' THEN 'ទម្ងន់'
    WHEN 'BRAKES' THEN 'ហ្វ្រាំង'
    ELSE src.category_code
  END AS name_km,
  ROW_NUMBER() OVER (ORDER BY src.category_code) AS sort_order,
  TRUE AS is_active
FROM (
  SELECT DISTINCT UPPER(TRIM(category)) AS category_code
  FROM pre_entry_safety_items
  WHERE category IS NOT NULL AND TRIM(category) <> ''
) src;

-- 3) Recreate master items from distinct (category, item_name)
INSERT INTO pre_entry_check_master_items (category_id, item_key, item_label_km, check_time, sort_order, is_active)
SELECT
  c.id AS category_id,
  CONCAT('migrated_', LOWER(c.code), '_',
         LPAD(ROW_NUMBER() OVER (PARTITION BY c.code ORDER BY x.item_label_km), 3, '0')) AS item_key,
  x.item_label_km,
  NULL AS check_time,
  ROW_NUMBER() OVER (PARTITION BY c.code ORDER BY x.item_label_km) AS sort_order,
  TRUE AS is_active
FROM (
  SELECT
    UPPER(TRIM(category)) AS category_code,
    TRIM(item_name) AS item_label_km
  FROM pre_entry_safety_items
  WHERE category IS NOT NULL
    AND TRIM(category) <> ''
    AND item_name IS NOT NULL
    AND TRIM(item_name) <> ''
  GROUP BY UPPER(TRIM(category)), TRIM(item_name)
) x
JOIN pre_entry_check_categories c ON c.code = x.category_code;

-- 4) Reset auto increment counters
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
