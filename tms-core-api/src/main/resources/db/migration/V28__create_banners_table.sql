-- Create banners table for carousel/announcement management
CREATE TABLE IF NOT EXISTS banners (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL COMMENT 'English title',
    title_kh VARCHAR(255) COMMENT 'Khmer title',
    subtitle VARCHAR(500) COMMENT 'English subtitle',
    subtitle_kh VARCHAR(500) COMMENT 'Khmer subtitle',
    image_url VARCHAR(500) NOT NULL COMMENT 'Banner image URL',
    category VARCHAR(50) NOT NULL DEFAULT 'general' COMMENT 'Category: announcement, promotion, safety, news',
    target_url VARCHAR(500) COMMENT 'Deep link or action URL',
    display_order INT NOT NULL DEFAULT 0 COMMENT 'Sort order (lower = higher priority)',
    start_date DATETIME NOT NULL COMMENT 'Banner activation date',
    end_date DATETIME NOT NULL COMMENT 'Banner expiration date',
    active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Active status',
    click_count INT NOT NULL DEFAULT 0 COMMENT 'Click tracking',
    view_count INT NOT NULL DEFAULT 0 COMMENT 'View tracking',
    created_by VARCHAR(100) COMMENT 'Creator username',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active_dates (active, start_date, end_date),
    INDEX idx_display_order (display_order),
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Banners and announcements for driver app carousel';

-- Insert sample banners
INSERT INTO banners (title, title_kh, subtitle, subtitle_kh, image_url, category, display_order, start_date, end_date, active, created_by) VALUES
('Welcome Driver!', 'សូមស្វាគមន៍ជំនិញបើកបរ!', 'Ready to make deliveries today', 'រួសរាន់ក្នុងការដឹកជញ្ជូនថ្ងៃនេះ', '/uploads/images/banners/welcome.jpg', 'announcement', 1, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE, 'system'),
('Safety First', 'សុវត្ថិភាពជាអាទិភាព', 'Drive safe, arrive safe', 'បើកបរដោយសុវត្ថិភាព មកដល់ដោយសុវត្ថិភាព', '/uploads/images/banners/safety.jpg', 'safety', 2, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE, 'system'),
('Earn More', 'រកប្រាក់បានច្រើន', 'Complete more trips, earn more rewards', 'បំពេញការធ្វើជើងដឹកបានច្រើន ទទួលបានរង្វាន់ច្រើន', '/uploads/images/banners/earnings.jpg', 'promotion', 3, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), TRUE, 'system');
