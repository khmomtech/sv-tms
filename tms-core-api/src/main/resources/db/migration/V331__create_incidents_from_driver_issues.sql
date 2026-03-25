-- V331: Transform driver_issues to incidents for Incident & Case Management
-- This migration extends the driver_issues table with new fields for incident management
-- while maintaining backward compatibility with existing driver issue functionality

-- Add new columns for incident management
ALTER TABLE driver_issues 
ADD COLUMN `code` VARCHAR(50) NULL COMMENT 'Unique incident code (e.g., INC-2025-0001)',
ADD COLUMN `incident_group` VARCHAR(20) NULL COMMENT 'TRAFFIC, BEHAVIOR, CUSTOMER, ACCIDENT, VEHICLE',
ADD COLUMN `incident_type` VARCHAR(50) NULL COMMENT 'Specific type like SPEEDING, COMPLAINT, etc.',
ADD COLUMN `source` VARCHAR(20) NULL DEFAULT 'DRIVER_APP' COMMENT 'Source of incident report',
ADD COLUMN `incident_status` VARCHAR(20) NULL DEFAULT 'NEW' COMMENT 'NEW, VALIDATED, LINKED_TO_CASE, CLOSED',
ADD COLUMN `reported_by_user_id` BIGINT NULL COMMENT 'User who reported the incident',
ADD COLUMN `sla_due_at` DATETIME NULL COMMENT 'SLA target datetime for response';

-- Add foreign key for reported_by_user_id
ALTER TABLE driver_issues
ADD CONSTRAINT `fk_driver_issues_reported_by_user`
  FOREIGN KEY (`reported_by_user_id`) REFERENCES `users` (`id`)
  ON DELETE SET NULL;

-- Backfill existing records with sensible defaults
UPDATE driver_issues
SET 
  source = 'DRIVER_APP',
  incident_status = CASE 
    WHEN status = 'OPEN' THEN 'NEW'
    WHEN status = 'IN_PROGRESS' THEN 'VALIDATED'
    WHEN status = 'RESOLVED' OR status = 'CLOSED' THEN 'CLOSED'
    ELSE 'NEW'
  END,
  -- Map existing category to incident_group
  incident_group = CASE
    WHEN LOWER(category) LIKE '%accident%' OR LOWER(category) LIKE '%collision%' THEN 'ACCIDENT'
    WHEN LOWER(category) LIKE '%vehicle%' OR LOWER(category) LIKE '%breakdown%' OR LOWER(category) LIKE '%mechanical%' THEN 'VEHICLE'
    WHEN LOWER(category) LIKE '%customer%' OR LOWER(category) LIKE '%complaint%' THEN 'CUSTOMER'
    WHEN LOWER(category) LIKE '%speeding%' OR LOWER(category) LIKE '%traffic%' OR LOWER(category) LIKE '%road%' THEN 'TRAFFIC'
    WHEN LOWER(category) LIKE '%behavior%' OR LOWER(category) LIKE '%late%' OR LOWER(category) LIKE '%delay%' THEN 'BEHAVIOR'
    ELSE 'VEHICLE'
  END,
  -- Map existing category to incident_type  
  incident_type = CASE
    WHEN LOWER(category) LIKE '%speeding%' THEN 'SPEEDING'
    WHEN LOWER(category) LIKE '%brake%' OR LOWER(category) LIKE '%braking%' THEN 'HARSH_BRAKING'
    WHEN LOWER(category) LIKE '%accident%' OR LOWER(category) LIKE '%collision%' THEN 'COLLISION'
    WHEN LOWER(category) LIKE '%breakdown%' OR LOWER(category) LIKE '%mechanical%' THEN 'MECHANICAL_FAILURE'
    WHEN LOWER(category) LIKE '%customer%' OR LOWER(category) LIKE '%complaint%' THEN 'CUSTOMER_COMPLAINT'
    WHEN LOWER(category) LIKE '%late%' OR LOWER(category) LIKE '%delay%' THEN 'MISSED_SCHEDULE'
    ELSE 'OTHER'
  END
WHERE source IS NULL;

-- Generate unique codes for existing incidents
SET @incident_counter = 0;
UPDATE driver_issues
SET code = CONCAT('INC-', YEAR(created_at), '-', LPAD((@incident_counter := @incident_counter + 1), 4, '0'))
WHERE code IS NULL
ORDER BY created_at ASC;

-- Create indexes for new fields
CREATE INDEX `idx_driver_issues_code` ON `driver_issues` (`code`);
CREATE INDEX `idx_driver_issues_incident_group` ON `driver_issues` (`incident_group`);
CREATE INDEX `idx_driver_issues_incident_type` ON `driver_issues` (`incident_type`);
CREATE INDEX `idx_driver_issues_incident_status` ON `driver_issues` (`incident_status`);
CREATE INDEX `idx_driver_issues_source` ON `driver_issues` (`source`);
CREATE INDEX `idx_driver_issues_sla_due_at` ON `driver_issues` (`sla_due_at`);
CREATE INDEX `idx_driver_issues_reported_by` ON `driver_issues` (`reported_by_user_id`);

-- Composite index for common queries
CREATE INDEX `idx_driver_issues_status_severity_date` 
ON `driver_issues` (`incident_status`, `severity`, `created_at` DESC);

-- Add unique constraint on code
ALTER TABLE driver_issues
ADD UNIQUE KEY `uk_driver_issues_code` (`code`);

-- Add comment to table explaining its dual purpose
ALTER TABLE driver_issues COMMENT = 'Stores both legacy driver issues and new incident reports for Incident & Case Management system';
