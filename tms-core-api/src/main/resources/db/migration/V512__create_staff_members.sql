-- ============================================================================
-- V512: Staff Members
-- ============================================================================

CREATE TABLE IF NOT EXISTS staff_members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(120),
    phone VARCHAR(50),
    job_title VARCHAR(120),
    department VARCHAR(120),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_staff_user (user_id),
    INDEX idx_staff_active (active),
    INDEX idx_staff_full_name (full_name),
    CONSTRAINT fk_staff_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
