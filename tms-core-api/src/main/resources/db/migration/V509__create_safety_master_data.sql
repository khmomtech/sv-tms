-- ════════════════════════════════════════════════════════════════════════════
-- V509: Safety Check Master Data (Categories + Items)
-- Source: Excel "របាយការណ៏តៃកុងត្រួតពិនិត្យ_ប្រចាំថ្ងៃ_2.xlsx"
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS safety_check_categories (
    id BIGINT PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name_km VARCHAR(255) NOT NULL,
    sort_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_safety_category_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Safety check master categories';

CREATE TABLE IF NOT EXISTS safety_check_master_items (
    id BIGINT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    item_key VARCHAR(100) NOT NULL,
    item_label_km VARCHAR(255) NOT NULL,
    check_time VARCHAR(50),
    sort_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_safety_item_key (item_key),
    INDEX idx_safety_master_category (category_id),
    CONSTRAINT fk_safety_master_category FOREIGN KEY (category_id) REFERENCES safety_check_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Safety check master items';

-- Categories (from Excel + additional categories for full workflow)
INSERT INTO safety_check_categories (id, code, name_km, sort_order, is_active) VALUES
  (1, 'ENGINE', 'ផ្នែកម៉ាស៊ីន', 1, TRUE),
  (2, 'UNDERBODY', 'ផ្នែកគ្រឿងក្រោម', 2, TRUE),
  (3, 'LIGHTS', 'ផ្នែកភ្លើង', 3, TRUE),
  (4, 'VEHICLE_EQUIPMENT', 'សម្ភារះបំពាក់លើរថយន្ត', 4, TRUE),
  (5, 'APPEARANCE', 'សោភ័ណ្ឌភាពរថយន្ត', 5, TRUE),
  (6, 'DRIVER_HEALTH', 'សុខភាពអ្នកបើកបរ', 6, TRUE),
  (7, 'SAFETY_EQUIPMENT', 'ឧបករណ៍សុវត្ថិភាព', 7, TRUE),
  (8, 'LOAD', 'ទំនិញ', 8, TRUE),
  (9, 'ENVIRONMENT', 'បរិស្ថាន', 9, TRUE);

-- Items from Excel (vehicle inspection)
INSERT INTO safety_check_master_items (id, category_id, item_key, item_label_km, check_time, sort_order, is_active) VALUES
  (1, 1, 'item_1', 'ប្រេងម៉ាស៊ីន', 'ព្រឹក', 1, TRUE),
  (2, 1, 'item_2', 'ទឹកស្អំម៉ាស៊ីន', 'ព្រឹក', 2, TRUE),
  (3, 1, 'item_3', 'ទុយោធុងទឹក លើ/ក្រោម', 'ព្រឹក', 3, TRUE),
  (7, 1, 'item_7', 'ប្រេងបូមចង្កូត', 'ព្រឹក', 4, TRUE),
  (8, 1, 'item_8', 'ប្រេងហ្រ្វាំង', 'ព្រឹក', 5, TRUE),
  (11, 1, 'item_11', 'ហ្វឺតប្រអប់ចង្កូត', 'ព្រឹក', 6, TRUE),
  (12, 1, 'item_12', 'សញ្ញាក្នុងតាបឡូ (ប្រេងបូម ,ខ្យល់ ,សាកអាគុយ ,កំដៅទឹក)', 'ពេលបើកបរ', 7, TRUE),
  (13, 2, 'item_13', 'ប្រព័ន្ធប្រេងអ៊ំព្រីយ៉ា', 'ព្រឹក', 8, TRUE),
  (14, 2, 'item_14', 'ក្រឡអ៊ំព្រីយ៉ា លើ/ក្រោម', 'ព្រឹក', 9, TRUE),
  (15, 2, 'item_15', 'សំបកកង់', 'ព្រឹក', 10, TRUE),
  (16, 2, 'item_16', 'ថាស់', 'ព្រឹក', 11, TRUE),
  (17, 2, 'item_17', 'តាកេ', 'ព្រឹក', 12, TRUE),
  (18, 2, 'item_18', 'គំរបទប់ខ្លាញ់ចុងដុំ', 'ព្រឹក', 13, TRUE),
  (19, 2, 'item_19', 'ប៊ូឡុងកាឡេ', 'ព្រឹក', 14, TRUE),
  (20, 2, 'item_20', 'ខ្វែងកាឡេ', 'ពេលបើកបរ', 15, TRUE),
  (21, 2, 'item_21', 'សាបកាឡេ', 'ពេលបើកបរ', 16, TRUE),
  (22, 2, 'item_22', 'រទីលម៉ែត្រចង្កូត', 'ពេលបើកបរ', 17, TRUE),
  (23, 2, 'item_23', 'សាបចង្កូត', 'ពេលបើកបរ', 18, TRUE),
  (24, 2, 'item_24', 'ប្រព័ន្ធហ្រ្វាំងក្បាល', 'ពេលបើកបរ', 19, TRUE),
  (25, 2, 'item_25', 'ប្រព័ន្ធហ្រ្វាំងរឺម៉ក', 'ពេលបើកបរ', 20, TRUE),
  (26, 2, 'item_26', 'បាតរឺម៉ក (ផ្ទៃលើ)', 'ព្រឹក', 21, TRUE),
  (27, 3, 'item_27', 'ភ្លើងហ្វាកូដ /ភ្លើងដឺមី /ភ្លើងស៊ីញ៉ូ /ភ្លើងសុំផ្លូវ', 'ព្រឹក', 22, TRUE),
  (28, 3, 'item_28', 'ស៊ីផ្លេ', 'ព្រឹក', 23, TRUE),
  (29, 3, 'item_29', 'ប្រអប់ប៊ូស៊ីបលើតាបឡូ /ជាប់អាគុយ', 'ព្រឹក', 24, TRUE),
  (30, 3, 'item_30', 'ភ្លើងលើកាប៊ីន', 'ព្រឹក', 25, TRUE),
  (31, 3, 'item_31', 'ភ្លើងតាបឡូ', 'ព្រឹក', 26, TRUE),
  (32, 3, 'item_32', 'ភ្លើងជាន់ហ្រ្វាំង', 'ព្រឹក', 27, TRUE),
  (33, 3, 'item_33', 'ម៉ូទ័រផ្លិតទឹក', 'ព្រឹក', 28, TRUE),
  (34, 3, 'item_34', 'ប្រព័ន្ធភ្លើង និង ប្រព័ន្ធខ្យល់ ពីក្បាលទៅរឺម៉ក', 'ព្រឹក', 29, TRUE),
  (35, 4, 'item_35', 'តង់គ្រប់ធំ', 'ព្រឹក', 30, TRUE),
  (36, 4, 'item_36', 'តង់ក្រាលបាត', 'ព្រឹក', 31, TRUE),
  (37, 4, 'item_37', 'តង់ស', 'ព្រឹក', 32, TRUE),
  (38, 4, 'item_38', 'ដែកវេ', 'ព្រឹក', 33, TRUE),
  (39, 4, 'item_39', 'កៅឡាក់', 'ព្រឹក', 34, TRUE),
  (40, 4, 'item_40', 'កំណល់', 'ព្រឹក', 35, TRUE),
  (41, 5, 'item_41', 'កាងក្បាលឡាន /កាងរឺម៉ក', 'ព្រឹក', 36, TRUE),
  (42, 5, 'item_42', 'ប៉ាណា', 'ព្រឹក', 37, TRUE),
  (43, 5, 'item_43', 'ជ័រចុងកាង', 'ព្រឹក', 38, TRUE),
  (44, 5, 'item_44', 'ស្តុប', 'ព្រឹក', 39, TRUE),
  (45, 5, 'item_45', 'ថ្ពាល់កាប៊ីនឆ្វេង /ស្តាំ', 'ព្រឹក', 40, TRUE),
  (46, 5, 'item_46', 'ដៃកញ្ចក់', 'ព្រឹក', 41, TRUE),
  (47, 5, 'item_47', 'កញ្ចក់ព្រិលឆ្វេង /ស្តាំ', 'ព្រឹក', 42, TRUE),
  (48, 5, 'item_48', 'កញ្ចក់ចំហៀងឆ្វេង /ស្តាំ', 'ព្រឹក', 43, TRUE),
  (49, 5, 'item_49', 'កញ្ចក់ធំមុខ', 'ព្រឹក', 44, TRUE),
  (50, 5, 'item_50', 'ស៊ុមកញ្ចក់', 'ព្រឹក', 45, TRUE),
  (51, 5, 'item_51', 'ការសំអាតក្នុងកាប៊ីន', 'ព្រឹក', 46, TRUE),
  -- Additional workflow items
  (1001, 6, 'slept_enough', 'គេងគ្រប់គ្រាន់', NULL, 47, TRUE),
  (1002, 6, 'sick', 'មានជំងឺ', NULL, 48, TRUE),
  (1003, 6, 'fatigue', 'អស់កម្លាំង', NULL, 49, TRUE),
  (1004, 6, 'alcohol_drugs', 'ស្រា/សារធាតុញៀន', NULL, 50, TRUE),
  (1101, 7, 'fire_extinguisher', 'ឧបករណ៍ពន្លត់អគ្គីភ័យ', NULL, 51, TRUE),
  (1102, 7, 'triangle', 'សញ្ញាត្រីកោណ', NULL, 52, TRUE),
  (1103, 7, 'reflective_vest', 'អាវពន្លឺ', NULL, 53, TRUE),
  (1104, 7, 'first_aid', 'ប្រអប់ថែទាំបឋម', NULL, 54, TRUE),
  (1201, 8, 'secured', 'ទំនិញបានចាក់សោរល្អ', NULL, 55, TRUE),
  (1202, 8, 'overweight', 'ទំនិញលើសទម្ងន់', NULL, 56, TRUE),
  (1203, 8, 'blocking_view', 'ទំនិញបាំងចក្ខុវិស័យ', NULL, 57, TRUE),
  (1301, 9, 'weather', 'អាកាសធាតុ', NULL, 58, TRUE),
  (1302, 9, 'road', 'ស្ថានភាពផ្លូវ', NULL, 59, TRUE);
