-- Safety-only daily safety checks schema (MySQL)

CREATE TABLE IF NOT EXISTS safety_check_categories (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL,
  name_km VARCHAR(255) NOT NULL,
  sort_order INT NULL,
  is_active BOOLEAN NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  UNIQUE KEY uk_safety_category_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS safety_check_master_items (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT NOT NULL,
  item_key VARCHAR(100) NOT NULL,
  item_label_km VARCHAR(255) NOT NULL,
  check_time VARCHAR(50) NULL,
  sort_order INT NULL,
  is_active BOOLEAN NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_safety_master_category (category_id),
  UNIQUE KEY uk_safety_master_item_key (item_key),
  CONSTRAINT fk_safety_master_category FOREIGN KEY (category_id) REFERENCES safety_check_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS safety_checks (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  check_date DATE NOT NULL,
  shift VARCHAR(50) NULL,
  driver_id BIGINT NOT NULL,
  vehicle_id BIGINT NOT NULL,
  status VARCHAR(32) NOT NULL,
  risk_level VARCHAR(32) NULL,
  risk_override VARCHAR(32) NULL,
  submitted_at DATETIME NULL,
  approved_at DATETIME NULL,
  approved_by_user_id BIGINT NULL,
  reject_reason VARCHAR(1000) NULL,
  notes TEXT NULL,
  gps_lat DOUBLE NULL,
  gps_lng DOUBLE NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_safety_check_status (status),
  INDEX idx_safety_check_date (check_date),
  INDEX idx_safety_check_driver (driver_id),
  INDEX idx_safety_check_vehicle (vehicle_id),
  INDEX idx_safety_check_risk (risk_level),
  CONSTRAINT fk_safety_checks_approved_by FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_safety_checks_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  CONSTRAINT fk_safety_checks_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS safety_check_items (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  safety_check_id BIGINT NOT NULL,
  category VARCHAR(50) NOT NULL,
  item_key VARCHAR(100) NOT NULL,
  item_label_km VARCHAR(255) NULL,
  result VARCHAR(32) NULL,
  severity VARCHAR(32) NULL,
  remark VARCHAR(1000) NULL,
  created_at DATETIME NULL,
  INDEX idx_safety_check_items_check (safety_check_id),
  INDEX idx_safety_check_items_category (category),
  INDEX idx_safety_check_items_key (item_key),
  CONSTRAINT fk_safety_check_items_check FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS safety_check_attachments (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  safety_check_id BIGINT NOT NULL,
  item_id BIGINT NULL,
  file_url VARCHAR(500) NOT NULL,
  file_name VARCHAR(255) NULL,
  mime_type VARCHAR(100) NULL,
  uploaded_by_user_id BIGINT NULL,
  created_at DATETIME NULL,
  INDEX idx_safety_check_attachments_check (safety_check_id),
  INDEX idx_safety_check_attachments_item (item_id),
  INDEX idx_safety_check_attachments_uploaded_by (uploaded_by_user_id),
  CONSTRAINT fk_safety_check_attachments_check FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE,
  CONSTRAINT fk_safety_check_attachments_uploaded_by FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS safety_check_audit (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  safety_check_id BIGINT NOT NULL,
  action VARCHAR(50) NOT NULL,
  actor_id BIGINT NULL,
  actor_role VARCHAR(50) NULL,
  message VARCHAR(1000) NULL,
  created_at DATETIME NULL,
  INDEX idx_safety_check_audit_check (safety_check_id),
  INDEX idx_safety_check_audit_actor (actor_id),
  INDEX idx_safety_check_audit_action (action),
  CONSTRAINT fk_safety_check_audit_check FOREIGN KEY (safety_check_id) REFERENCES safety_checks(id) ON DELETE CASCADE
) ENGINE=InnoDB;

