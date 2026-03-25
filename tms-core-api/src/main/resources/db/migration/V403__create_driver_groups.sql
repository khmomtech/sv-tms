-- Create driver_groups lookup table
CREATE TABLE IF NOT EXISTS driver_groups (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  code VARCHAR(50) UNIQUE,
  description VARCHAR(255),
  is_active BIT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
);

-- Seed demo data
INSERT INTO driver_groups (name, code, description)
VALUES
  ('Main Drivers', 'MAIN', 'Primary in-house drivers'),
  ('Partner Drivers', 'PARTNER', 'Partner/vendor drivers')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description);

-- Link drivers to driver_groups
ALTER TABLE drivers
  ADD COLUMN driver_group_id BIGINT NULL AFTER id_card_expiry,
  ADD CONSTRAINT fk_driver_group
    FOREIGN KEY (driver_group_id) REFERENCES driver_groups(id)
    ON DELETE SET NULL;

CREATE INDEX idx_drivers_driver_group ON drivers(driver_group_id);
