-- Create work order child tables (tasks, photos, parts) for environments missing them

CREATE TABLE IF NOT EXISTS work_order_tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    category VARCHAR(100),
    description TEXT,
    assigned_technician_id BIGINT,
    diagnosis_result TEXT,
    actions_taken TEXT,
    time_spent_minutes INT DEFAULT 0,
    estimated_hours DOUBLE,
    actual_hours DOUBLE,
    notes TEXT,
    status ENUM('BLOCKED','CANCELLED','COMPLETED','IN_PROGRESS','IN_REVIEW','ON_HOLD','OPEN') DEFAULT 'OPEN',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_technician_id) REFERENCES users(id),
    INDEX idx_wot_wo (work_order_id),
    INDEX idx_wot_technician (assigned_technician_id),
    INDEX idx_wot_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS work_order_photos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    task_id BIGINT,
    photo_url VARCHAR(500) NOT NULL,
    photo_type ENUM('BEFORE','AFTER','DIAGNOSTIC') NOT NULL,
    description TEXT,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by BIGINT,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES work_order_tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    INDEX idx_photo_wo (work_order_id),
    INDEX idx_photo_task (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS work_order_parts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    work_order_id BIGINT NOT NULL,
    task_id BIGINT,
    part_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    notes VARCHAR(500),
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by BIGINT,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES work_order_tasks(id) ON DELETE SET NULL,
    FOREIGN KEY (part_id) REFERENCES parts_master(id),
    FOREIGN KEY (added_by) REFERENCES users(id),
    INDEX idx_wop_wo (work_order_id),
    INDEX idx_wop_task (task_id),
    INDEX idx_wop_part (part_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ensure work_orders.title length matches DTO max
SET @title_len := (
  SELECT CHARACTER_MAXIMUM_LENGTH
  FROM information_schema.COLUMNS
  WHERE table_schema = DATABASE()
    AND table_name = 'work_orders'
    AND column_name = 'title'
);
SET @sql := IF(@title_len IS NOT NULL AND @title_len < 300,
  'ALTER TABLE work_orders MODIFY COLUMN title VARCHAR(300)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
