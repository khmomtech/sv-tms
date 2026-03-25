-- ════════════════════════════════════════════════════════════════════════════
-- V510: Enable AUTO_INCREMENT for safety master data tables
-- ════════════════════════════════════════════════════════════════════════════

-- Drop FK to allow altering referenced PK column
ALTER TABLE safety_check_master_items
  DROP FOREIGN KEY fk_safety_master_category;

ALTER TABLE safety_check_categories
  MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT;

ALTER TABLE safety_check_master_items
  MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT;

ALTER TABLE safety_check_master_items
  ADD CONSTRAINT fk_safety_master_category
    FOREIGN KEY (category_id) REFERENCES safety_check_categories(id);
