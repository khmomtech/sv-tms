-- ============================================================================
-- V505: SV Standard Vehicle Maintenance Module
-- - Maintenance Requests (MR) -> Work Orders (WO)
-- - OWN / VENDOR repair flows with quotations + invoices + payments
-- - Mechanics, vendors (extension), parts (extension)
-- ============================================================================

-- ----------------------------
-- 1) Maintenance Requests
-- ----------------------------
CREATE TABLE IF NOT EXISTS maintenance_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    mr_number VARCHAR(50) NOT NULL,
    vehicle_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority ENUM('URGENT','HIGH','NORMAL','LOW') NOT NULL DEFAULT 'NORMAL',
    status ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'SUBMITTED',
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    rejected_at DATETIME,
    approval_remarks TEXT,
    rejection_reason TEXT,
    created_by BIGINT,
    approved_by BIGINT,
    rejected_by BIGINT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE KEY uk_mr_number (mr_number),
    INDEX idx_mr_vehicle (vehicle_id),
    INDEX idx_mr_status (status),
    INDEX idx_mr_requested_at (requested_at),
    CONSTRAINT fk_mr_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    CONSTRAINT fk_mr_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_mr_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_mr_rejected_by FOREIGN KEY (rejected_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- 2) Work Orders enhancements
-- ----------------------------
-- Use conditional DDL to keep migrations idempotent across environments.
SET @wo_mr_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'work_orders' AND column_name = 'maintenance_request_id'
);
SET @wo_repair_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'work_orders' AND column_name = 'repair_type'
);
SET @wo_closed_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'work_orders' AND column_name = 'closed_at'
);

SET @sql := IF(@wo_mr_col = 0, 'ALTER TABLE work_orders ADD COLUMN maintenance_request_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF(@wo_repair_col = 0, "ALTER TABLE work_orders ADD COLUMN repair_type ENUM('OWN','VENDOR') NULL", 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF(@wo_closed_col = 0, 'ALTER TABLE work_orders ADD COLUMN closed_at DATETIME NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @wo_mr_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'work_orders' AND index_name = 'idx_wo_mr'
);
SET @sql := IF(@wo_mr_idx = 0, 'ALTER TABLE work_orders ADD INDEX idx_wo_mr (maintenance_request_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @wo_mr_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE constraint_schema = DATABASE() AND table_name = 'work_orders' AND constraint_name = 'fk_work_orders_mr'
);
SET @sql := IF(@wo_mr_fk = 0, 'ALTER TABLE work_orders ADD CONSTRAINT fk_work_orders_mr FOREIGN KEY (maintenance_request_id) REFERENCES maintenance_requests(id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 3) Mechanics (internal)
-- ----------------------------
CREATE TABLE IF NOT EXISTS mechanics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    full_name VARCHAR(200) NOT NULL,
    phone VARCHAR(50),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_mechanic_user (user_id),
    INDEX idx_mechanic_active (active),
    CONSTRAINT fk_mechanic_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS work_order_mechanics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    mechanic_id BIGINT NOT NULL,
    role VARCHAR(50) DEFAULT 'MECHANIC',
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_wo_mechanic (work_order_id, mechanic_id),
    INDEX idx_wo_mechanic_wo (work_order_id),
    INDEX idx_wo_mechanic_mechanic (mechanic_id),
    CONSTRAINT fk_wo_mech_wo FOREIGN KEY (work_order_id) REFERENCES work_orders(id),
    CONSTRAINT fk_wo_mech_mechanic FOREIGN KEY (mechanic_id) REFERENCES mechanics(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- 4) Vendors (extension table)
-- - SV TMS already uses partner_companies + /api/vendors.
-- - This table provides an FK target to satisfy: vendor_quotations -> vendors.
-- ----------------------------
CREATE TABLE IF NOT EXISTS vendors (
    id BIGINT PRIMARY KEY,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vendors_partner_company FOREIGN KEY (id) REFERENCES partner_companies(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- 5) Vendor Quotations (VENDOR flow)
-- ----------------------------
CREATE TABLE IF NOT EXISTS vendor_quotations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    vendor_id BIGINT NOT NULL,
    quotation_number VARCHAR(100),
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED') NOT NULL DEFAULT 'SUBMITTED',
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    approved_by BIGINT,
    rejection_reason TEXT,
    UNIQUE KEY uk_vendor_quote_wo (work_order_id),
    INDEX idx_vendor_quote_vendor (vendor_id),
    INDEX idx_vendor_quote_status (status),
    CONSTRAINT fk_vendor_quote_wo FOREIGN KEY (work_order_id) REFERENCES work_orders(id),
    CONSTRAINT fk_vendor_quote_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(id),
    CONSTRAINT fk_vendor_quote_approved_by FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- 6) Parts (extension table)
-- - SV TMS already uses parts_master and work_order_parts.part_id -> parts_master.id.
-- - This table provides an FK target to satisfy: work_order_parts -> parts.
-- ----------------------------
CREATE TABLE IF NOT EXISTS parts (
    id BIGINT PRIMARY KEY,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_parts_master FOREIGN KEY (id) REFERENCES parts_master(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- 7) Invoices & Payments (VENDOR flow)
-- - Invoices table exists in some deployments; create if absent then extend for WO linkage.
-- ----------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NULL,
    invoice_date DATE,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    UNIQUE KEY uk_invoice_order (order_id),
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES transport_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @inv_wo_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'invoices' AND column_name = 'work_order_id'
);
SET @sql := IF(@inv_wo_col = 0, 'ALTER TABLE invoices ADD COLUMN work_order_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @inv_wo_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'invoices' AND index_name = 'uk_invoice_work_order'
);
SET @sql := IF(@inv_wo_uk = 0, 'ALTER TABLE invoices ADD UNIQUE KEY uk_invoice_work_order (work_order_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Ensure order_id can be null (maintenance invoices do not require an order)
SET @inv_order_nullable := (
  SELECT CASE WHEN IS_NULLABLE = 'YES' THEN 1 ELSE 0 END
  FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'invoices' AND column_name = 'order_id'
);
SET @sql := IF(@inv_order_nullable = 0, 'ALTER TABLE invoices MODIFY COLUMN order_id BIGINT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @inv_wo_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE constraint_schema = DATABASE() AND table_name = 'invoices' AND constraint_name = 'fk_invoice_work_order'
);
SET @sql := IF(@inv_wo_fk = 0, 'ALTER TABLE invoices ADD CONSTRAINT fk_invoice_work_order FOREIGN KEY (work_order_id) REFERENCES work_orders(id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    method VARCHAR(50),
    reference_no VARCHAR(100),
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_by BIGINT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payment_invoice (invoice_id),
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_payment_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
