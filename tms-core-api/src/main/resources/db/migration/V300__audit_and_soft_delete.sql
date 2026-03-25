-- Add auditing + soft-delete to all core tables (no data loss)

-- Vehicles
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS created_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS updated_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS is_deleted     TINYINT(1) NOT NULL DEFAULT 0;

-- Drivers
ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS created_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS updated_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS is_deleted     TINYINT(1) NOT NULL DEFAULT 0;

-- Driver assignments
ALTER TABLE driver_assignments
  ADD COLUMN IF NOT EXISTS created_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS updated_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS is_deleted     TINYINT(1) NOT NULL DEFAULT 0;

-- Vehicle documents
ALTER TABLE vehicle_documents
  ADD COLUMN IF NOT EXISTS created_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS updated_at     DATETIME NULL,
  ADD COLUMN IF NOT EXISTS is_deleted     TINYINT(1) NOT NULL DEFAULT 0;

-- Vehicle inspections (create if you currently only have `inspection` table; merged later)
CREATE TABLE IF NOT EXISTS vehicle_inspections (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  vehicle_id BIGINT NOT NULL,
  inspection_type VARCHAR(20) NOT NULL,
  inspection_date DATETIME NOT NULL,
  brakes_checked TINYINT(1) DEFAULT 0,
  tires_checked  TINYINT(1) DEFAULT 0,
  oil_checked    TINYINT(1) DEFAULT 0,
  lights_checked TINYINT(1) DEFAULT 0,
  engine_checked TINYINT(1) DEFAULT 0,
  status VARCHAR(20) NOT NULL,
  comments TEXT NULL,
  photo_url VARCHAR(255) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_vinsp_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);

-- Maintenance task type / task shells (if already exist, the IF NOT EXISTS keeps it safe)
CREATE TABLE IF NOT EXISTS maintenance_task_types (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_maint_task_type_name (name)
);

CREATE TABLE IF NOT EXISTS maintenance_tasks (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  vehicle_id BIGINT NOT NULL,
  type_id BIGINT NULL,
  title VARCHAR(150) NOT NULL,
  status VARCHAR(20) NOT NULL,
  scheduled_date DATE NULL,
  started_at DATETIME NULL,
  completed_at DATETIME NULL,
  notes TEXT NULL,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_mtask_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  CONSTRAINT fk_mtask_type    FOREIGN KEY (type_id)    REFERENCES maintenance_task_types(id)
);