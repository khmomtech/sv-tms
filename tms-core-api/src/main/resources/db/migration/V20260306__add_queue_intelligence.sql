-- V20260306__add_queue_intelligence.sql
-- Adds queue intelligence columns for Phase 1: Warehouse Loading
-- Enables: Intelligent queue sequencing, priority-based loading, and audit trail

-- Add columns to loading_queue table for enhanced intelligence
ALTER TABLE loading_queue ADD COLUMN IF NOT EXISTS priority_score INT DEFAULT 0 
    COMMENT 'Priority score 0-100: higher = earlier in sequence';

ALTER TABLE loading_queue ADD COLUMN IF NOT EXISTS sequence_order INT DEFAULT 0 
    COMMENT 'Calculated sequence order based on priority and optimization';

ALTER TABLE loading_queue ADD COLUMN IF NOT EXISTS estimated_loading_minutes INT DEFAULT 30 
    COMMENT 'Estimated time in minutes to load this vehicle';

ALTER TABLE loading_queue ADD COLUMN IF NOT EXISTS destination_cluster VARCHAR(50) 
    COMMENT 'Geographic cluster for route optimization (e.g., CENTRAL, NORTH, SOUTH)';

ALTER TABLE loading_queue ADD COLUMN IF NOT EXISTS last_sequenced_at TIMESTAMP NULL 
    COMMENT 'When the queue sequence was last recalculated';

-- Create queue_sequencing_log table for audit trail
CREATE TABLE IF NOT EXISTS queue_sequencing_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    loading_queue_id BIGINT NOT NULL,
    dispatch_id BIGINT NOT NULL,
    warehouse_code VARCHAR(50),
    
    -- Sequencing details
    previous_sequence_order INT,
    new_sequence_order INT,
    previous_priority_score INT,
    new_priority_score INT,
    
    -- Reason for change
    reason VARCHAR(255) COMMENT 'Why sequence changed (algo_recalc, manual_adjust, etc)',
    triggered_by BIGINT COMMENT 'User ID if manual adjustment, NULL if algorithm',
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_loading_queue_id (loading_queue_id),
    INDEX idx_dispatch_id (dispatch_id),
    INDEX idx_created_at (created_at),
    CONSTRAINT fk_queue_sequencing_log_queue 
        FOREIGN KEY (loading_queue_id) REFERENCES loading_queue(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail for queue sequencing changes and priority recalculations';

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_loading_queue_priority_score ON loading_queue(priority_score);
CREATE INDEX IF NOT EXISTS idx_loading_queue_sequence_order ON loading_queue(sequence_order);
CREATE INDEX IF NOT EXISTS idx_loading_queue_destination_cluster ON loading_queue(destination_cluster);
CREATE INDEX IF NOT EXISTS idx_loading_queue_warehouse_sequence 
    ON loading_queue(warehouse_code, sequence_order);
