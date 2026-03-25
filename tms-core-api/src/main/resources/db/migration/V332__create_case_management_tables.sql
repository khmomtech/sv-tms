-- V332: Create Case Management tables for Incident & Case Management system

-- Cases table
CREATE TABLE `cases` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL COMMENT 'Unique case code (e.g., CASE-2025-0041)',
  `title` VARCHAR(300) NOT NULL,
  `description` TEXT NULL,
  `category` VARCHAR(30) NOT NULL COMMENT 'SAFETY, HR_BEHAVIOR, ACCIDENT, CUSTOMER_ESCALATION',
  `severity` VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' COMMENT 'LOW, MEDIUM, HIGH, CRITICAL',
  `status` VARCHAR(30) NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN, INVESTIGATION, PENDING_APPROVAL, CLOSED',
  
  -- Assignment
  `assigned_to_user_id` BIGINT NULL COMMENT 'Assigned investigator/handler',
  `assigned_team` VARCHAR(100) NULL COMMENT 'Assigned team name',
  
  -- Related entities
  `driver_id` BIGINT NULL COMMENT 'Primary driver involved',
  `vehicle_id` BIGINT NULL COMMENT 'Primary vehicle involved',
  
  -- SLA tracking
  `sla_target_at` DATETIME NULL COMMENT 'SLA target for resolution',
  
  -- Audit timestamps
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by_user_id` BIGINT NULL,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  `closed_at` DATETIME NULL,
  
  -- Soft delete
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cases_code` (`code`),
  KEY `idx_cases_status` (`status`),
  KEY `idx_cases_category` (`category`),
  KEY `idx_cases_severity` (`severity`),
  KEY `idx_cases_assigned_to` (`assigned_to_user_id`),
  KEY `idx_cases_driver` (`driver_id`),
  KEY `idx_cases_vehicle` (`vehicle_id`),
  KEY `idx_cases_created_at` (`created_at` DESC),
  KEY `idx_cases_sla_target` (`sla_target_at`),
  KEY `idx_cases_status_severity_date` (`status`, `severity`, `created_at` DESC),
  
  CONSTRAINT `fk_cases_assigned_to_user`
    FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_cases_driver`
    FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_cases_vehicle`
    FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_cases_created_by_user`
    FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Case management for investigations and escalations';

-- Case-Incident link table (many-to-many)
CREATE TABLE `case_incidents` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `case_id` BIGINT NOT NULL,
  `incident_id` BIGINT NOT NULL COMMENT 'References driver_issues.id',
  `linked_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `linked_by_user_id` BIGINT NULL,
  `notes` TEXT NULL COMMENT 'Reason for linking',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_incident` (`case_id`, `incident_id`),
  KEY `idx_case_incidents_case` (`case_id`),
  KEY `idx_case_incidents_incident` (`incident_id`),
  KEY `idx_case_incidents_linked_by` (`linked_by_user_id`),
  
  CONSTRAINT `fk_case_incidents_case`
    FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_case_incidents_incident`
    FOREIGN KEY (`incident_id`) REFERENCES `driver_issues` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_case_incidents_linked_by_user`
    FOREIGN KEY (`linked_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Links incidents to cases (many-to-many relationship)';

-- Case Tasks table
CREATE TABLE `case_tasks` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `case_id` BIGINT NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'TODO' COMMENT 'TODO, IN_PROGRESS, DONE',
  `owner_user_id` BIGINT NULL COMMENT 'Task owner/assignee',
  `due_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by_user_id` BIGINT NULL,
  `completed_at` DATETIME NULL,
  `completed_by_user_id` BIGINT NULL,
  
  PRIMARY KEY (`id`),
  KEY `idx_case_tasks_case` (`case_id`),
  KEY `idx_case_tasks_status` (`status`),
  KEY `idx_case_tasks_owner` (`owner_user_id`),
  KEY `idx_case_tasks_due_at` (`due_at`),
  KEY `idx_case_tasks_case_status` (`case_id`, `status`),
  
  CONSTRAINT `fk_case_tasks_case`
    FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_case_tasks_owner_user`
    FOREIGN KEY (`owner_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_case_tasks_created_by_user`
    FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_case_tasks_completed_by_user`
    FOREIGN KEY (`completed_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tasks within a case investigation';

-- Case Timeline table
CREATE TABLE `case_timeline` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `case_id` BIGINT NOT NULL,
  `entry_type` VARCHAR(30) NOT NULL COMMENT 'CREATED, STATUS_CHANGE, TASK_ADDED, NOTE, EVIDENCE_UPLOADED, etc.',
  `message` TEXT NOT NULL COMMENT 'Timeline entry description',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by_user_id` BIGINT NULL,
  `metadata` JSON NULL COMMENT 'Additional structured data',
  
  PRIMARY KEY (`id`),
  KEY `idx_case_timeline_case` (`case_id`),
  KEY `idx_case_timeline_created_at` (`created_at` DESC),
  KEY `idx_case_timeline_type` (`entry_type`),
  KEY `idx_case_timeline_case_date` (`case_id`, `created_at` DESC),
  
  CONSTRAINT `fk_case_timeline_case`
    FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_case_timeline_created_by_user`
    FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail and timeline for case activities';

-- Case Attachments table
CREATE TABLE `case_attachments` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `case_id` BIGINT NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_path` VARCHAR(500) NOT NULL COMMENT 'Relative path or object storage URL',
  `file_size` BIGINT NULL COMMENT 'File size in bytes',
  `mime_type` VARCHAR(100) NULL,
  `description` TEXT NULL,
  `uploaded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `uploaded_by_user_id` BIGINT NULL,
  
  PRIMARY KEY (`id`),
  KEY `idx_case_attachments_case` (`case_id`),
  KEY `idx_case_attachments_uploaded_at` (`uploaded_at` DESC),
  KEY `idx_case_attachments_uploaded_by` (`uploaded_by_user_id`),
  
  CONSTRAINT `fk_case_attachments_case`
    FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_case_attachments_uploaded_by_user`
    FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Attachments and evidence for cases';

-- Create auto-increment sequence tracking for case codes
-- This will be managed by application logic to generate codes like CASE-2025-0001
