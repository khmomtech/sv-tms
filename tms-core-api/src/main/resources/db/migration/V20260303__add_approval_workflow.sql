-- V20260303__add_approval_workflow.sql
-- Adds dispatch approval gate workflow tables and columns for Phase 2: Dispatch Approval & Closure
-- Enables: Approval status tracking, SLA measurement, history audit trail

-- Add new columns to dispatch table for approval workflow
ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS approval_status VARCHAR(50) DEFAULT 'NONE' 
    COMMENT 'Approval status: NONE, PENDING_APPROVAL, APPROVED, REJECTED, ON_HOLD';

ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL COMMENT 'User ID of admin who approved';

ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP NULL COMMENT 'Timestamp when dispatch was approved';

ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS approval_remarks TEXT NULL COMMENT 'Admin remarks during approval/rejection';

-- Create dispatch_approval_history table for audit trail
CREATE TABLE IF NOT EXISTS dispatch_approval_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispatch_id BIGINT NOT NULL,
    from_status VARCHAR(50) NOT NULL COMMENT 'Previous approval status',
    to_status VARCHAR(50) NOT NULL COMMENT 'New approval status',
    action VARCHAR(20) NOT NULL COMMENT 'APPROVED, REJECTED, ON_HOLD',
    approval_remarks TEXT,
    reviewed_by BIGINT NOT NULL COMMENT 'User ID who made the decision',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_dispatch_id (dispatch_id),
    INDEX idx_created_at (created_at),
    CONSTRAINT fk_dispatch_approval_history_dispatch 
        FOREIGN KEY (dispatch_id) REFERENCES dispatch(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail for dispatch approval decisions';

-- Create dispatch_approval_sla table to track closure turnaround
CREATE TABLE IF NOT EXISTS dispatch_approval_sla (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispatch_id BIGINT NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL COMMENT 'DELIVERED, PENDING_APPROVAL, APPROVED, REJECTED',
    delivered_at TIMESTAMP NOT NULL COMMENT 'When dispatch status changed to DELIVERED',
    approval_submitted_at TIMESTAMP NULL COMMENT 'When approval was requested',
    approved_at TIMESTAMP NULL COMMENT 'When approval was granted',
    sla_target_minutes INT DEFAULT 120 COMMENT 'Target SLA in minutes',
    actual_minutes INT NULL COMMENT 'Actual minutes taken (NULL until approved)',
    sla_status VARCHAR(20) COMMENT 'ON_TRACK, BREACHED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_dispatch_id (dispatch_id),
    INDEX idx_status (status),
    INDEX idx_delivered_at (delivered_at),
    CONSTRAINT fk_dispatch_approval_sla_dispatch 
        FOREIGN KEY (dispatch_id) REFERENCES dispatch(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='SLA tracking for dispatch closure turnaround time';

-- Add index on approval_status for efficient queries
CREATE INDEX IF NOT EXISTS idx_dispatch_approval_status ON dispatch(approval_status);
CREATE INDEX IF NOT EXISTS idx_dispatch_approved_at ON dispatch(approved_at);
