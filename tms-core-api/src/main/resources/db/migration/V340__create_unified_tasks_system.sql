-- ════════════════════════════════════════════════════════════════════════════
-- V340: Create Unified Tasks System
-- ════════════════════════════════════════════════════════════════════════════
-- Purpose: Create comprehensive task management system supporting:
--   - Standalone tasks (no parent entity)
--   - Incident tasks (relation_type='INCIDENT')
--   - Work order tasks (relation_type='WORK_ORDER')
--   - Vehicle tasks (relation_type='VEHICLE')
--   - Case tasks (relation_type='CASE')
--   - Any future entity tasks via flexible polymorphic relation
--   - Hierarchical tasks (parent/child subtasks)
--   - Rich collaboration (comments, attachments, tags, watchers)
--   - Full audit trail (activity logs)
-- ════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- 1. TASK TAG DEFINITIONS (master list of reusable tags)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_tag_definitions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL COMMENT 'Hex color code, e.g., #FF5733',
    category VARCHAR(50) COMMENT 'Tag category: urgent, bug, feature, maintenance, etc.',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_task_tag_name (name),
    INDEX idx_task_tag_category (category),
    INDEX idx_task_tag_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable tag definitions for task categorization';

-- ════════════════════════════════════════════════════════════════════════════
-- 2. MAIN TASKS TABLE (unified task entity)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL COMMENT 'Auto-generated unique code: TASK-2025-0001',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- ════════ Flexible polymorphic relation ════════
    -- NULL = standalone task
    -- 'INCIDENT' + incident_id = incident task
    -- 'WORK_ORDER' + work_order_id = work order task
    -- 'VEHICLE' + vehicle_id = vehicle task
    -- 'CASE' + case_id = case task
    -- etc.
    relation_type VARCHAR(50) COMMENT 'Entity type: INCIDENT, WORK_ORDER, VEHICLE, CASE, CUSTOMER, etc.',
    relation_id BIGINT COMMENT 'Foreign key to related entity',
    
    -- ════════ Task hierarchy ════════
    parent_task_id BIGINT COMMENT 'Parent task for subtask hierarchy',
    
    -- ════════ Status & Priority ════════
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN, IN_PROGRESS, BLOCKED, ON_HOLD, IN_REVIEW, COMPLETED, CANCELLED',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' COMMENT 'CRITICAL, HIGH, MEDIUM, LOW',
    
    -- ════════ Time tracking ════════
    estimated_minutes INT COMMENT 'Estimated time in minutes',
    actual_minutes INT COMMENT 'Actual time spent in minutes',
    progress_percentage INT DEFAULT 0 COMMENT 'Task completion percentage (0-100)',
    
    -- ════════ Dates ════════
    start_date DATETIME COMMENT 'Actual start date',
    due_date DATETIME COMMENT 'Due date for task completion',
    completed_at DATETIME COMMENT 'Timestamp when task was completed',
    
    -- ════════ Assignment ════════
    assigned_to BIGINT COMMENT 'User assigned to this task',
    created_by BIGINT NOT NULL COMMENT 'User who created the task',
    
    -- ════════ Flags & Metadata ════════
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(100) COMMENT 'Cron expression or pattern for recurring tasks',
    is_billable BOOLEAN DEFAULT FALSE,
    is_internal BOOLEAN DEFAULT FALSE COMMENT 'Internal-only task (not visible to customers)',
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- ════════ Audit fields ════════
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- ════════ Constraints ════════
    UNIQUE KEY uk_task_code (code),
    
    -- ════════ Foreign keys ════════
    CONSTRAINT fk_task_parent FOREIGN KEY (parent_task_id) REFERENCES tasks(id) ON DELETE SET NULL,
    CONSTRAINT fk_task_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_task_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
    
    -- ════════ Indexes ════════
    INDEX idx_task_relation (relation_type, relation_id),
    INDEX idx_task_status (status),
    INDEX idx_task_priority (priority),
    INDEX idx_task_assigned_to (assigned_to),
    INDEX idx_task_created_by (created_by),
    INDEX idx_task_parent (parent_task_id),
    INDEX idx_task_due_date (due_date),
    INDEX idx_task_created_at (created_at),
    INDEX idx_task_is_deleted (is_deleted),
    INDEX idx_task_status_assignee (status, assigned_to),
    INDEX idx_task_overdue (due_date, status) COMMENT 'Quick lookup for overdue tasks'
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Unified task management table supporting all task types';

-- ════════════════════════════════════════════════════════════════════════════
-- 3. TASK COMMENTS (threaded discussion)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_comments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    parent_comment_id BIGINT COMMENT 'For threaded replies',
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE COMMENT 'Internal-only comment',
    author_id BIGINT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_task_comment_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_comment_parent FOREIGN KEY (parent_comment_id) REFERENCES task_comments(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_comment_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT,
    
    INDEX idx_task_comment_task (task_id),
    INDEX idx_task_comment_parent (parent_comment_id),
    INDEX idx_task_comment_author (author_id),
    INDEX idx_task_comment_created (created_at)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Comments on tasks with threading support';

-- ════════════════════════════════════════════════════════════════════════════
-- 4. TASK ATTACHMENTS (files linked to tasks)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL COMMENT 'Storage path or URL',
    file_size BIGINT COMMENT 'File size in bytes',
    mime_type VARCHAR(100) COMMENT 'Content type',
    uploaded_by BIGINT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT fk_task_attachment_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_attachment_uploader FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE RESTRICT,
    
    INDEX idx_task_attachment_task (task_id),
    INDEX idx_task_attachment_uploader (uploaded_by),
    INDEX idx_task_attachment_uploaded (uploaded_at)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='File attachments for tasks';

-- ════════════════════════════════════════════════════════════════════════════
-- 5. TASK TAGS (many-to-many join table)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_tags (
    task_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (task_id, tag_id),
    
    CONSTRAINT fk_task_tags_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_tags_tag FOREIGN KEY (tag_id) REFERENCES task_tag_definitions(id) ON DELETE CASCADE,
    
    INDEX idx_task_tags_tag (tag_id)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Many-to-many relationship between tasks and tags';

-- ════════════════════════════════════════════════════════════════════════════
-- 6. TASK WATCHERS (users watching task updates)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_watchers (
    task_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (task_id, user_id),
    
    CONSTRAINT fk_task_watchers_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_watchers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_task_watchers_user (user_id)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Users watching task updates';

-- ════════════════════════════════════════════════════════════════════════════
-- 7. TASK ACTIVITY LOG (full audit trail)
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS task_activity_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL COMMENT 'CREATED, UPDATED, COMMENTED, COMPLETED, etc.',
    description TEXT NOT NULL,
    metadata JSON COMMENT 'Additional structured data about the change',
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_task_activity_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_activity_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    
    INDEX idx_task_activity_task (task_id),
    INDEX idx_task_activity_user (user_id),
    INDEX idx_task_activity_action (action),
    INDEX idx_task_activity_created (created_at)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Complete audit trail of all task changes';

-- ════════════════════════════════════════════════════════════════════════════
-- 8. SEED DEFAULT TAGS
-- ════════════════════════════════════════════════════════════════════════════
INSERT INTO task_tag_definitions (name, color, category, description) VALUES
('Urgent', '#FF0000', 'priority', 'Requires immediate attention'),
('Bug', '#FF6B6B', 'type', 'Software defect or error'),
('Feature', '#4ECDC4', 'type', 'New functionality or enhancement'),
('Maintenance', '#FFE66D', 'type', 'Routine maintenance task'),
('Investigation', '#95E1D3', 'type', 'Research or diagnostic work'),
('Documentation', '#C7CEEA', 'type', 'Documentation updates'),
('Training', '#FFDAB9', 'type', 'Training or knowledge transfer'),
('Customer Request', '#B8E994', 'source', 'Originated from customer'),
('Blocked', '#FA8072', 'status', 'Blocked by external dependency'),
('Quick Win', '#90EE90', 'effort', 'Low effort, high value task')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- ════════════════════════════════════════════════════════════════════════════
-- 9. COMMENTS
-- ════════════════════════════════════════════════════════════════════════════
-- Unified Tasks System successfully created!
-- 
-- Features:
-- Flexible polymorphic relation (relation_type + relation_id)
-- Hierarchical tasks (parent/child subtasks)
-- Rich collaboration (comments, attachments, tags, watchers)
-- Time tracking (estimated, actual, progress)
-- Priority & status management
-- Full audit trail (activity logs)
-- Soft delete pattern
-- Recurring tasks support
-- Internal/billable flags
-- 
-- Supported Task Types:
-- • Standalone tasks (relation_type = NULL)
-- • Incident tasks (relation_type = 'INCIDENT')
-- • Work order tasks (relation_type = 'WORK_ORDER')
-- • Vehicle tasks (relation_type = 'VEHICLE')
-- • Case tasks (relation_type = 'CASE')
-- • Any future entity via flexible pattern
-- 
-- Next Steps:
-- 1. Run migration: ./mvnw flyway:migrate
-- 2. Test API endpoints at /api/tasks
-- 3. Optional: Migrate data from old tables (case_tasks, maintenance_tasks, work_order_tasks)
-- ════════════════════════════════════════════════════════════════════════════
