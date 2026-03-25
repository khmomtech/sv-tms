-- Explicit Khmer pre-entry master checklist seed.
-- Safe to run after V20260312; keeps data deterministic for admin pre-entry master pages.

-- Categories
INSERT INTO pre_entry_check_categories (code, name_km, sort_order, is_active)
VALUES
  ('LOAD', 'ត្រូតពិនិត្យសម្ភារះលើឡានមុនចូលរោងចក្រ', 1, TRUE),
  ('DOCUMENTS', 'ត្រូតពិនិត្យតៃកុងឡាន', 2, TRUE),
  ('WINDSHIELD', 'ត្រួតពិនិត្យឡាន', 3, TRUE)
ON DUPLICATE KEY UPDATE
  name_km = VALUES(name_km),
  sort_order = VALUES(sort_order),
  is_active = VALUES(is_active);

SET @cat_load := (SELECT id FROM pre_entry_check_categories WHERE code = 'LOAD' LIMIT 1);
SET @cat_documents := (SELECT id FROM pre_entry_check_categories WHERE code = 'DOCUMENTS' LIMIT 1);
SET @cat_vehicle := (SELECT id FROM pre_entry_check_categories WHERE code = 'WINDSHIELD' LIMIT 1);

-- Items from requested checklist
INSERT INTO pre_entry_check_master_items (category_id, item_key, item_label_km, check_time, sort_order, is_active)
VALUES
  (@cat_load, 'pre_entry_load_strap', 'ខ្សែរឹតទំនិញគ្រប់គ្រាន់អត់', NULL, 1, TRUE),
  (@cat_load, 'pre_entry_load_dunnage', 'កំណល់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 2, TRUE),
  (@cat_load, 'pre_entry_load_insulation', 'អ៊ីសូឡង់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 3, TRUE),
  (@cat_load, 'pre_entry_load_steel_bar', 'ដែកវ៉េគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 4, TRUE),
  (@cat_load, 'pre_entry_load_cover_tarp', 'តង់គ្របទំនិញគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 5, TRUE),
  (@cat_load, 'pre_entry_load_floor_tarp', 'តង់ក្រាលបាតត្រឹមត្រូវអត់', NULL, 6, TRUE),

  (@cat_documents, 'pre_entry_driver_general_check', 'ត្រូតពិនិត្យតៃកុងឡាន', NULL, 7, TRUE),
  (@cat_documents, 'pre_entry_driver_safety_shoes', 'ស្បែកជើងសុវត្ថិភាព នឹងស្រោមជើងត្រឹមត្រូវអត់', NULL, 8, TRUE),
  (@cat_documents, 'pre_entry_driver_reflective_vest', 'អាវពន្លឺត្រឹមត្រូវអត់', NULL, 9, TRUE),
  (@cat_documents, 'pre_entry_driver_alcohol', 'តៃកុងសារធាតុស្រវឹងអត់?', NULL, 10, TRUE),

  (@cat_vehicle, 'pre_entry_vehicle_clean_before_entry', 'បាញ់ទឹកសម្អាតឡានអត់មុនចូលរោងចក្រ', NULL, 11, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_door_glass_open', 'ទ្វាឡានបើកកញ្ចក់មុនចូលរោងចក្រ', NULL, 12, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_trailer_floor_hole', 'បាតរម៉ក់ផតអត់', NULL, 13, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_trailer_board_out', 'ក្តរម៉កលៀនចេញក្រៅអត', NULL, 14, TRUE)
ON DUPLICATE KEY UPDATE
  category_id = VALUES(category_id),
  item_label_km = VALUES(item_label_km),
  check_time = VALUES(check_time),
  sort_order = VALUES(sort_order),
  is_active = VALUES(is_active);

-- Keep explicit set active for pre-entry master.
UPDATE pre_entry_check_master_items
SET is_active = FALSE
WHERE item_key NOT IN (
  'pre_entry_load_strap',
  'pre_entry_load_dunnage',
  'pre_entry_load_insulation',
  'pre_entry_load_steel_bar',
  'pre_entry_load_cover_tarp',
  'pre_entry_load_floor_tarp',
  'pre_entry_driver_general_check',
  'pre_entry_driver_safety_shoes',
  'pre_entry_driver_reflective_vest',
  'pre_entry_driver_alcohol',
  'pre_entry_vehicle_clean_before_entry',
  'pre_entry_vehicle_door_glass_open',
  'pre_entry_vehicle_trailer_floor_hole',
  'pre_entry_vehicle_trailer_board_out'
);

UPDATE pre_entry_check_categories
SET is_active = FALSE
WHERE code NOT IN ('LOAD', 'DOCUMENTS', 'WINDSHIELD');
