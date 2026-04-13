CREATE TABLE IF NOT EXISTS telemetry_point (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    sequence_number BIGINT NOT NULL,
    driver_id BIGINT NULL,
    received_at TIMESTAMP(6) NOT NULL,
    recorded_at TIMESTAMP(6) NOT NULL,
    latitude DOUBLE NULL,
    longitude DOUBLE NULL,
    accuracy DOUBLE NULL,
    publish_status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    publish_attempts INT NOT NULL DEFAULT 0,
    published_at TIMESTAMP(6) NULL,
    last_publish_error VARCHAR(1000) NULL,
    CONSTRAINT uk_telemetry_device_sequence UNIQUE (device_id, sequence_number)
);

CREATE INDEX idx_telemetry_publish_status_received_at
    ON telemetry_point (publish_status, received_at);

CREATE INDEX idx_telemetry_driver_received_at
    ON telemetry_point (driver_id, received_at);
