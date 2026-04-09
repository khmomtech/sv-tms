-- Hard reset pre-entry master data before import/seed.
-- Requested: truncate old data first, then import target checklist.

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE pre_entry_check_master_items;
TRUNCATE TABLE pre_entry_check_categories;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO pre_entry_check_categories (code, name_km, sort_order, is_active)
VALUES
  ('LOAD', 'សម្ភារះលើឡានមុនចូលរោងចក្រ', 1, TRUE),
  ('DOCUMENTS', 'តង់គ្របទំនិញគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', 2, TRUE),
  ('WINDSHIELD', 'ត្រួតពិនិត្យឡាន', 3, TRUE);

SET @cat_load := (SELECT id FROM pre_entry_check_categories WHERE code = 'LOAD' LIMIT 1);
SET @cat_documents := (SELECT id FROM pre_entry_check_categories WHERE code = 'DOCUMENTS' LIMIT 1);
SET @cat_vehicle := (SELECT id FROM pre_entry_check_categories WHERE code = 'WINDSHIELD' LIMIT 1);

INSERT INTO pre_entry_check_master_items (category_id, item_key, item_label_km, check_time, sort_order, is_active)
VALUES
  (@cat_load, 'pre_entry_load_strap', 'ខ្សែរឹតទំនិញគ្រប់គ្រាន់អត់', NULL, 1, TRUE),
  (@cat_load, 'pre_entry_load_dunnage', 'កំណល់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 2, TRUE),
  (@cat_load, 'pre_entry_load_insulation', 'អ៊ីសូឡង់គ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 3, TRUE),
  (@cat_load, 'pre_entry_load_steel_bar', 'ដែកវ៉េគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់', NULL, 4, TRUE),

  (@cat_documents, 'pre_entry_load_floor_tarp', 'តង់ក្រាលបាតត្រឹមត្រូវអត់', NULL, 5, TRUE),
  (@cat_documents, 'pre_entry_driver_general_check', 'ត្រូតពិនិត្យតៃកុងឡាន', NULL, 6, TRUE),
  (@cat_documents, 'pre_entry_driver_safety_shoes', 'ស្បែកជើងសុវត្ថិភាព នឹងស្រោមជើងត្រឹមត្រូវអត់', NULL, 7, TRUE),
  (@cat_documents, 'pre_entry_driver_reflective_vest', 'អាវពន្លឺត្រឹមត្រូវអត់', NULL, 8, TRUE),
  (@cat_documents, 'pre_entry_driver_alcohol', 'តៃកុងសារធាតុស្រវឹងអត់?', NULL, 9, TRUE),

  (@cat_vehicle, 'pre_entry_vehicle_clean_before_entry', 'បាញ់ទឹកសម្អាតឡានអត់មុនចូលរោងចក្រ', NULL, 10, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_door_glass_open', 'ទ្វាឡានបើកកញ្ចក់មុនចូលរោងចក្រ', NULL, 11, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_trailer_floor_hole', 'បាតរម៉ក់ផតអត់', NULL, 12, TRUE),
  (@cat_vehicle, 'pre_entry_vehicle_trailer_board_out', 'ក្តរម៉កលៀនចេញក្រៅអត់', NULL, 13, TRUE);
