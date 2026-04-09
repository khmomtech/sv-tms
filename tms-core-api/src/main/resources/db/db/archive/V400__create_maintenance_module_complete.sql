-- ========================================
-- MAINTENANCE MODULE - Complete Implementation
-- Created: 2025-11-29
-- Purpose: Full maintenance management system
-- ========================================

-- 1. DRIVER ISSUES (Issue Reporting)
CREATE TABLE IF NOT EXISTS driver_issues (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    severity ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'MEDIUM',
    category VARCHAR(100),
    status ENUM('OPEN','IN_PROGRESS','RESOLVED','CLOSED') DEFAULT 'OPEN',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_address VARCHAR(500),
    reported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    assigned_to BIGINT,
    work_order_id BIGINT,
    resolved_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    INDEX idx_issue_status (status),
    INDEX idx_issue_driver (driver_id),
    INDEX idx_issue_vehicle (vehicle_id),
    INDEX idx_issue_severity (severity),
    INDEX idx_issue_reported (reported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS driver_issue_photos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    issue_id BIGINT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES driver_issues(id) ON DELETE CASCADE,
    INDEX idx_photo_issue (issue_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. WORK ORDERS
CREATE TABLE IF NOT EXISTS work_orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    wo_number VARCHAR(50) UNIQUE NOT NULL,
    vehicle_id BIGINT NOT NULL,
    issue_summary TEXT,
    status ENUM('OPEN','IN_PROGRESS','WAITING_PARTS','COMPLETED','CANCELLED') DEFAULT 'OPEN',
    type ENUM('PREVENTIVE','REPAIR','EMERGENCY','INSPECTION') NOT NULL,
    priority ENUM('URGENT','HIGH','NORMAL','LOW') DEFAULT 'NORMAL',
    assigned_technician_id BIGINT,
    supervisor_id BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    scheduled_date DATETIME,
    started_at DATETIME,
    completed_at DATETIME,
    labor_cost DECIMAL(10,2) DEFAULT 0,
    parts_cost DECIMAL(10,2) DEFAULT 0,
    total_cost DECIMAL(10,2) DEFAULT 0,
    remarks TEXT,
    approved BOOLEAN DEFAULT FALSE,
    approved_at DATETIME,
    approval_remarks TEXT,
    rejection_reason TEXT,
    requires_approval BOOLEAN DEFAULT TRUE,
    -- Breakdown/Emergency fields
    breakdown_location VARCHAR(500),
    breakdown_latitude DECIMAL(10,8),
    breakdown_longitude DECIMAL(11,8),
    breakdown_reported_at DATETIME,
    technician_dispatched_at DATETIME,
    technician_arrived_at DATETIME,
    downtime_minutes INT,
    -- Audit fields
    created_by BIGINT,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (assigned_technician_id) REFERENCES users(id),
    FOREIGN KEY (supervisor_id) REFERENCES users(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_wo_vehicle (vehicle_id),
    INDEX idx_wo_status (status),
    INDEX idx_wo_type (type),
    INDEX idx_wo_priority (priority),
    INDEX idx_wo_technician (assigned_technician_id),
    INDEX idx_wo_scheduled (scheduled_date),
    INDEX idx_wo_number (wo_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. WORK ORDER TASKS (Multi-task support)
CREATE TABLE IF NOT EXISTS work_order_tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    category VARCHAR(100),
    description TEXT,
    assigned_technician_id BIGINT,
    diagnosis_result TEXT,
    actions_taken TEXT,
    time_spent_minutes INT DEFAULT 0,
    status ENUM('OPEN','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'OPEN',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_technician_id) REFERENCES users(id),
    INDEX idx_wot_wo (work_order_id),
    INDEX idx_wot_technician (assigned_technician_id),
    INDEX idx_wot_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. WORK ORDER PHOTOS
CREATE TABLE IF NOT EXISTS work_order_photos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    task_id BIGINT,
    photo_url VARCHAR(500) NOT NULL,
    photo_type ENUM('BEFORE','AFTER','DIAGNOSTIC') NOT NULL,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    uploaded_by BIGINT,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES work_order_tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    INDEX idx_photo_wo (work_order_id),
    INDEX idx_photo_task (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. PARTS MASTER (No inventory tracking - just catalog)
CREATE TABLE IF NOT EXISTS parts_master (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    part_code VARCHAR(50) UNIQUE NOT NULL,
    part_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- Engine, Electrical, AC, Brake, Tires, etc.
    manufacturer VARCHAR(200),
    supplier_name VARCHAR(200),
    supplier_contact VARCHAR(200),
    reference_cost DECIMAL(10,2),
    notes TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    INDEX idx_part_code (part_code),
    INDEX idx_part_category (category),
    INDEX idx_part_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. PARTS COMPATIBLE VEHICLES
CREATE TABLE IF NOT EXISTS parts_compatible_vehicles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    part_id BIGINT NOT NULL,
    vehicle_type VARCHAR(100), -- Freightliner, Kenworth, etc.
    notes VARCHAR(500),
    FOREIGN KEY (part_id) REFERENCES parts_master(id) ON DELETE CASCADE,
    INDEX idx_pcv_part (part_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. WORK ORDER PARTS USED
CREATE TABLE IF NOT EXISTS work_order_parts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    task_id BIGINT,
    part_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    notes VARCHAR(500),
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    added_by BIGINT,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES work_order_tasks(id) ON DELETE SET NULL,
    FOREIGN KEY (part_id) REFERENCES parts_master(id),
    FOREIGN KEY (added_by) REFERENCES users(id),
    INDEX idx_wop_wo (work_order_id),
    INDEX idx_wop_task (task_id),
    INDEX idx_wop_part (part_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. PM (PREVENTIVE MAINTENANCE) SCHEDULES
CREATE TABLE IF NOT EXISTS pm_schedules (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    schedule_name VARCHAR(200) NOT NULL,
    description TEXT,
    vehicle_id BIGINT, -- NULL = applies to vehicle type
    vehicle_type VARCHAR(100), -- If vehicle_id is NULL
    trigger_type ENUM('KILOMETER','DATE','ENGINE_HOUR') NOT NULL,
    trigger_interval INT NOT NULL, -- 10000 (km), 180 (days), 500 (hours)
    reminder_before_km INT DEFAULT 1000,
    reminder_before_days INT DEFAULT 7,
    task_type_id BIGINT,
    active BOOLEAN DEFAULT TRUE,
    last_performed_at DATETIME,
    last_performed_km INT,
    last_performed_engine_hours INT,
    next_due_date DATE,
    next_due_km INT,
    next_due_engine_hours INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (task_type_id) REFERENCES maintenance_task_types(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_pm_vehicle (vehicle_id),
    INDEX idx_pm_active (active),
    INDEX idx_pm_next_due_date (next_due_date),
    INDEX idx_pm_next_due_km (next_due_km)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. PM SCHEDULE HISTORY
CREATE TABLE IF NOT EXISTS pm_schedule_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pm_schedule_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    work_order_id BIGINT,
    performed_at DATETIME,
    performed_km INT,
    performed_engine_hours INT,
    next_due_date DATE,
    next_due_km INT,
    next_due_engine_hours INT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pm_schedule_id) REFERENCES pm_schedules(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id),
    INDEX idx_pmh_schedule (pm_schedule_id),
    INDEX idx_pmh_vehicle (vehicle_id),
    INDEX idx_pmh_wo (work_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. TECHNICIAN SIGNATURES
CREATE TABLE IF NOT EXISTS work_order_signatures (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    technician_id BIGINT NOT NULL,
    signature_data TEXT, -- Base64 encoded signature image
    signed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES users(id),
    INDEX idx_sig_wo (work_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Update maintenance_tasks table to link with work_orders
ALTER TABLE maintenance_tasks 
    ADD COLUMN IF NOT EXISTS work_order_id BIGINT,
    ADD CONSTRAINT fk_mtask_wo FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- 12. Update driver_issues to link with work_orders
ALTER TABLE driver_issues 
    ADD CONSTRAINT fk_issue_wo FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- 13. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mtask_wo ON maintenance_tasks(work_order_id);
CREATE INDEX IF NOT EXISTS idx_mtask_due_date ON maintenance_tasks(due_date);

-- 14. Seed initial parts master data (common parts)
INSERT INTO parts_master (part_code, part_name, category, description, reference_cost) VALUES
('OIL-FL-001', 'Engine Oil Filter', 'Filters', 'Premium oil filter for heavy-duty trucks', 25.50),
('OIL-10W40', 'Engine Oil 10W-40', 'Fluids', 'Synthetic engine oil 10W-40', 45.00),
('BRAKE-PAD-HD', 'Heavy Duty Brake Pads', 'Brake System', 'High-performance brake pads set', 125.00),
('AIR-FILTER-001', 'Air Filter', 'Filters', 'Engine air filter', 35.00),
('COOLANT-5L', 'Engine Coolant 5L', 'Fluids', 'Antifreeze coolant 5 liters', 28.00),
('BELT-SERPENTINE', 'Serpentine Belt', 'Engine Parts', 'Drive belt for engine accessories', 65.00),
('SPARK-PLUG-SET', 'Spark Plug Set', 'Engine Parts', 'High-performance spark plugs (set of 8)', 95.00),
('TIRE-11R22.5', 'Tire 11R22.5', 'Tires', 'Heavy-duty truck tire 11R22.5', 450.00),
('BATTERY-HD-12V', 'Heavy Duty Battery 12V', 'Electrical', 'Heavy-duty 12V battery', 185.00),
('WIPER-BLADE-24', 'Wiper Blade 24"', 'Accessories', 'Windshield wiper blade 24 inch', 18.00)
ON DUPLICATE KEY UPDATE part_name = VALUES(part_name);

-- 15. Seed PM schedule templates
INSERT INTO pm_schedules (schedule_name, description, vehicle_type, trigger_type, trigger_interval, task_type_id) 
SELECT 
    'A-Service (Oil Change)', 
    'Basic service including oil change and filter replacement', 
    NULL,
    'KILOMETER', 
    15000, 
    id 
FROM maintenance_task_types WHERE name LIKE '%Oil Change%' LIMIT 1
ON DUPLICATE KEY UPDATE schedule_name = VALUES(schedule_name);

INSERT INTO pm_schedules (schedule_name, description, vehicle_type, trigger_type, trigger_interval, task_type_id) 
SELECT 
    'B-Service (Full Inspection)', 
    'Comprehensive inspection and maintenance', 
    NULL,
    'KILOMETER', 
    30000, 
    id 
FROM maintenance_task_types WHERE name LIKE '%Inspection%' LIMIT 1
ON DUPLICATE KEY UPDATE schedule_name = VALUES(schedule_name);

-- 16. Create view for overdue maintenance
CREATE OR REPLACE VIEW v_overdue_maintenance AS
SELECT 
    v.id AS vehicle_id,
    v.license_plate,
    v.current_km,
    pm.id AS pm_schedule_id,
    pm.schedule_name,
    pm.next_due_km,
    pm.next_due_date,
    CASE 
        WHEN pm.trigger_type = 'KILOMETER' THEN v.current_km - pm.next_due_km
        WHEN pm.trigger_type = 'DATE' THEN DATEDIFF(CURDATE(), pm.next_due_date)
        ELSE 0
    END AS overdue_amount,
    pm.trigger_type
FROM vehicles v
JOIN pm_schedules pm ON (pm.vehicle_id = v.id OR pm.vehicle_id IS NULL)
WHERE pm.active = TRUE
  AND (
    (pm.trigger_type = 'KILOMETER' AND v.current_km >= pm.next_due_km)
    OR (pm.trigger_type = 'DATE' AND CURDATE() >= pm.next_due_date)
  );

-- 17. Create view for work order summary
CREATE OR REPLACE VIEW v_work_order_summary AS
SELECT 
    wo.id,
    wo.wo_number,
    wo.status,
    wo.type,
    wo.priority,
    v.license_plate AS vehicle,
    CONCAT(u.first_name, ' ', u.last_name) AS technician,
    wo.scheduled_date,
    wo.total_cost,
    COUNT(DISTINCT wot.id) AS total_tasks,
    SUM(CASE WHEN wot.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_tasks,
    wo.created_at
FROM work_orders wo
LEFT JOIN vehicles v ON wo.vehicle_id = v.id
LEFT JOIN users u ON wo.assigned_technician_id = u.id
LEFT JOIN work_order_tasks wot ON wo.id = wot.work_order_id
WHERE wo.is_deleted = FALSE
GROUP BY wo.id;

COMMIT;
