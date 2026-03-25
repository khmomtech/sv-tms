-- V341: Create customer activities table and enhance customers table

-- Create customer_activities table
CREATE TABLE customer_activities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    metadata TEXT COMMENT 'JSON string for additional activity metadata',
    related_entity_id BIGINT,
    related_entity_type VARCHAR(50),
    created_by_name VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_customer_activity_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    
    INDEX idx_customer_activity_customer_created (customer_id, created_at DESC),
    INDEX idx_customer_activity_type (type),
    INDEX idx_customer_activity_related (related_entity_type, related_entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add customer segmentation and health score columns
ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS tags TEXT COMMENT 'JSON string array of customer tags',
    ADD COLUMN IF NOT EXISTS customer_segment VARCHAR(20) COMMENT 'Customer segment: VIP, REGULAR, HIGH_VALUE, AT_RISK, NEW, DORMANT',
    ADD COLUMN IF NOT EXISTS health_score INT COMMENT 'Customer health score 0-100',
    ADD INDEX IF NOT EXISTS idx_customer_segment (customer_segment),
    ADD INDEX IF NOT EXISTS idx_customer_health_score (health_score);

-- Add first_order_date and last_order_date if not exist
ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS first_order_date DATE COMMENT 'Date of first order',
    ADD COLUMN IF NOT EXISTS last_order_date DATE COMMENT 'Date of most recent order',
    ADD INDEX IF NOT EXISTS idx_customer_last_order (last_order_date);

COMMIT;
