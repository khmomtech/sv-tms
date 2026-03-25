-- V20260305__add_pre_entry_safety_checks.sql
-- Adds pre-entry safety check tables for Phase 3: Field Checker & Safety
-- Enables: Detailed safety inspection before warehouse arrival with item-level tracking

-- Add columns to dispatch table for pre-entry safety tracking
ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS pre_entry_safety_status VARCHAR(50) 
    COMMENT 'Safety status: NOT_STARTED, IN_PROGRESS, PASSED, FAILED, CONDITIONAL';

ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS pre_entry_safety_required BOOLEAN DEFAULT FALSE 
    COMMENT 'If true, pre-entry safety check required before queue entry';

-- Create pre_entry_safety_check table
CREATE TABLE IF NOT EXISTS pre_entry_safety_check (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispatch_id BIGINT NOT NULL UNIQUE COMMENT 'One-to-one with dispatch',
    vehicle_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    warehouse_code VARCHAR(50),
    
    -- Safety check metadata
    status VARCHAR(50) DEFAULT 'NOT_STARTED' 
        COMMENT 'NOT_STARTED, IN_PROGRESS, PASSED, FAILED, CONDITIONAL',
    check_date DATE NOT NULL,
    remarks TEXT COMMENT 'General remarks about safety condition',
    
    -- Inspection details
    checked_by BIGINT COMMENT 'Security/Field checker user ID who performed the inspection',
    checked_at TIMESTAMP NULL COMMENT 'When the inspection was performed',
    checker_signature_path VARCHAR(255) COMMENT 'Path to field checkers signature file',
    inspection_photos JSON COMMENT 'Array of inspection photo file paths',
    
    -- Conditional override (if CONDITIONAL status)
    override_approved_by BIGINT COMMENT 'Supervisor/ADMIN user ID who approved override',
    override_approved_at TIMESTAMP NULL COMMENT 'When override was approved',
    override_remarks TEXT COMMENT 'Reason for conditional approval',
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_dispatch_id (dispatch_id),
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_check_date (check_date),
    CONSTRAINT fk_pre_entry_safety_check_dispatch 
        FOREIGN KEY (dispatch_id) REFERENCES dispatch(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Pre-entry safety checks performed before warehouse arrival';

-- Create pre_entry_safety_items table (detailed checklist items)
CREATE TABLE IF NOT EXISTS pre_entry_safety_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    safety_check_id BIGINT NOT NULL,
    
    -- Item category and status
    category VARCHAR(50) NOT NULL 
        COMMENT 'TIRES, LIGHTS, LOAD, DOCUMENTS, WEIGHT, BRAKES, WINDSHIELD',
    item_name VARCHAR(255) NOT NULL COMMENT 'e.g., Front left tire condition',
    status VARCHAR(50) DEFAULT 'OK' COMMENT 'OK, FAILED, CONDITIONAL',
    
    -- Item details
    remarks TEXT COMMENT 'Description of issue or conditional status',
    photo_path VARCHAR(255) COMMENT 'Photo of the item/issue',
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_safety_check_id (safety_check_id),
    INDEX idx_category (category),
    INDEX idx_status (status),
    CONSTRAINT fk_pre_entry_safety_items_check 
        FOREIGN KEY (safety_check_id) REFERENCES pre_entry_safety_check(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual safety check items with category and status';

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_dispatch_pre_entry_safety_status ON dispatch(pre_entry_safety_status);
CREATE INDEX IF NOT EXISTS idx_dispatch_pre_entry_safety_required ON dispatch(pre_entry_safety_required);
