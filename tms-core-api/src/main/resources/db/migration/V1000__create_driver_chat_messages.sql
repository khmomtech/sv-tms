-- Create table to support driver <-> admin chat messages
CREATE TABLE IF NOT EXISTS driver_chat_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    sender_role VARCHAR(20) NOT NULL,
    sender VARCHAR(100),
    message TEXT NOT NULL,
    message_type VARCHAR(20) NOT NULL DEFAULT 'TEXT',
    created_at TIMESTAMP NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_driver_chat_messages_driver_id (driver_id),
    INDEX idx_driver_chat_messages_created_at (created_at)
);
