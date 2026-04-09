-- Migration: Create home_layout_sections table for admin-controlled home screen layout
-- Date: 2026-03-10
-- Description: Allows admin to control visibility and order of driver app home screen sections

CREATE TABLE IF NOT EXISTS home_layout_sections (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    section_key VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique identifier for section',
    section_name VARCHAR(100) NOT NULL COMMENT 'Display name (English)',
    section_name_kh VARCHAR(100) COMMENT 'Display name (Khmer)',
    description VARCHAR(500) COMMENT 'Description of section purpose',
    description_kh VARCHAR(500) COMMENT 'Description (Khmer)',
    display_order INT NOT NULL DEFAULT 0 COMMENT 'Display order (lower = first)',
    visible BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Whether section is visible to drivers',
    is_mandatory BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether section can be hidden',
    icon VARCHAR(50) COMMENT 'Material icon name for admin UI',
    category VARCHAR(50) DEFAULT 'general' COMMENT 'Category for grouping',
    config_json TEXT COMMENT 'JSON configuration for section-specific settings',
    created_by VARCHAR(100) COMMENT 'Username who created this',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100) COMMENT 'Username who last updated',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_section_key (section_key),
    INDEX idx_visible_order (visible, display_order),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Home screen layout configuration for driver app';

-- Insert default sections
INSERT INTO home_layout_sections 
    (section_key, section_name, section_name_kh, description, description_kh, display_order, visible, is_mandatory, icon, category)
VALUES
    ('header', 'Header', 'ក្បាល', 'User greeting and notifications', 'ស្វាគមន៍អ្នកប្រើប្រាស់និងការជូនដំណឹង', 0, true, true, 'person', 'system'),
    ('maintenance_banner', 'Maintenance Banner', 'ផ្ទាំងថែទាំ', 'System announcements and maintenance alerts', 'ការប្រកាសប្រព័ន្ធនិងការជូនដំណឹងថែទាំ', 1, true, false, 'warning', 'system'),
    ('shift_status', 'Shift Status', 'ស្ថានភាពវេនការងារ', 'Current shift information', 'ព័ត៌មានវេនការងារបច្ចុប្បន្ន', 2, true, false, 'access_time', 'status'),
    ('safety_status', 'Safety Status', 'ស្ថានភាពសុវត្ថិភាព', 'Pre-trip safety check status', 'ស្ថានភាពពិនិត្យសុវត្ថិភាពមុនដំណើរ', 3, true, false, 'verified_user', 'safety'),
    ('important_updates', 'Important Updates', 'ព័ត៌មានថ្មីសំខាន់', 'Banners and announcements from admin', 'ផ្ទាំងនិងការប្រកាសពីអ្នកគ្រប់គ្រង', 4, true, false, 'campaign', 'content'),
    ('current_trip', 'Current Trip', 'ដំណើរបច្ចុប្បន្ន', 'Active trip information and progress', 'ព័ត៌មានដំណើរសកម្មនិងដំណើរការ', 5, true, false, 'local_shipping', 'trips'),
    ('quick_actions', 'Quick Actions', 'សកម្មភាពរហ័ស', 'Frequently used app features', 'មុខងារកម្មវិធីដែលប្រើញឹកញាប់', 6, true, false, 'grid_view', 'navigation')
ON DUPLICATE KEY UPDATE
    section_name = VALUES(section_name),
    section_name_kh = VALUES(section_name_kh),
    description = VALUES(description),
    description_kh = VALUES(description_kh);
