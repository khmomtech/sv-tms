-- ════════════════════════════════════════════════════════════════════════════
-- V508: Driver Daily Safety Checks
-- ════════════════════════════════════════════════════════════════════════════
-- Purpose:
--  - Store daily safety checks per driver + vehicle + day
--  - Track checklist items, attachments, and audit trail
--  - Enforce one record per day per driver+vehicle
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS safety_checks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    check_date DATE NOT NULL,
    shift VARCHAR(50),
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL,
    risk_level VARCHAR(20),
    risk_override VARCHAR(20),
    submitted_at DATETIME,
    approved_at DATETIME,
    approved_by BIGINT,
    reject_reason VARCHAR(1000),
    notes TEXT,
    gps_lat DECIMAL(10,7),
    gps_lng DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_safety_check_date_driver_vehicle (check_date, driver_id, vehicle_id),
    INDEX idx_safety_check_status (status),
    INDEX idx_safety_check_date (check_date),
    INDEX idx_safety_check_driver (driver_id),
    INDEX idx_safety_check_vehicle (vehicle_id),
    INDEX idx_safety_check_risk (risk_level),

    CONSTRAINT fk_safety_check_driver FOREIGN KEY (driver_id) REFERENCES drivers(id),
    CONSTRAINT fk_safety_check_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    CONSTRAINT fk_safety_check_approved_by FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Driver daily safety checks';

CREATE TABLE IF NOT EXISTS safety_check_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    safety_check_id BIGINT NOT NULL,
    category VARCHAR(50) NOT NULL,
    item_key VARCHAR(100) NOT NULL,
    item_label_km VARCHAR(255),
    result VARCHAR(20),
    severity VARCHAR(20),
    remark VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_safety_check_items_check (safety_check_id),
    INDEX idx_safety_check_items_category (category),
    INDEX idx_safety_check_items_key (item_key),

    CONSTRAINT fk_safety_check_items_check
        FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Daily safety check items';

CREATE TABLE IF NOT EXISTS safety_check_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    safety_check_id BIGINT NOT NULL,
    item_id BIGINT,
    file_url VARCHAR(500) NOT NULL,
    file_name VARCHAR(255),
    mime_type VARCHAR(100),
    uploaded_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_safety_check_attachments_check (safety_check_id),
    INDEX idx_safety_check_attachments_item (item_id),
    INDEX idx_safety_check_attachments_uploaded_by (uploaded_by),

    CONSTRAINT fk_safety_check_attachments_check
        FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_check_attachments_item
        FOREIGN KEY (item_id) REFERENCES safety_check_items(id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_check_attachments_uploaded_by
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Safety check attachments';

CREATE TABLE IF NOT EXISTS safety_check_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    safety_check_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL,
    actor_id BIGINT,
    actor_role VARCHAR(50),
    message VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_safety_check_audit_check (safety_check_id),
    INDEX idx_safety_check_audit_actor (actor_id),
    INDEX idx_safety_check_audit_action (action),

    CONSTRAINT fk_safety_check_audit_check
        FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Safety check audit log';
