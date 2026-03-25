-- Safety-only identity schema (MySQL)

CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(100) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  account_non_locked BOOLEAN NOT NULL DEFAULT TRUE,
  account_non_expired BOOLEAN NOT NULL DEFAULT TRUE,
  credentials_non_expired BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS roles (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(500) NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(500) NULL,
  resource_type VARCHAR(50) NULL,
  action_type VARCHAR(50) NULL,
  INDEX idx_permission_resource (resource_type),
  INDEX idx_permission_action (action_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT NOT NULL,
  permission_id BIGINT NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  token VARCHAR(512) NOT NULL UNIQUE,
  user_id BIGINT NOT NULL,
  issued_at DATETIME NULL,
  expires_at DATETIME NULL,
  revoked BOOLEAN NULL,
  device_info VARCHAR(255) NULL,
  INDEX idx_refresh_token_user (user_id),
  INDEX idx_refresh_token_expires_at (expires_at),
  CONSTRAINT fk_refresh_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Minimal driver profile used by safety flows.
CREATE TABLE IF NOT EXISTS drivers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NULL UNIQUE,
  name VARCHAR(255) NULL,
  phone VARCHAR(50) NULL,
  status VARCHAR(16) NULL,
  is_active BOOLEAN NULL DEFAULT TRUE,
  created_at DATETIME NULL,
  updated_at DATETIME NULL,
  INDEX idx_driver_user (user_id),
  INDEX idx_driver_status (status),
  CONSTRAINT fk_driver_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Minimal vehicle reference used by safety portal and safety checks.
CREATE TABLE IF NOT EXISTS vehicles (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  license_plate VARCHAR(20) NOT NULL UNIQUE,
  INDEX idx_vehicle_plate (license_plate)
) ENGINE=InnoDB;

-- Device approval tracking.
CREATE TABLE IF NOT EXISTS device_registered (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT NOT NULL,
  device_id VARCHAR(128) NOT NULL,
  device_name VARCHAR(255) NULL,
  os VARCHAR(50) NULL,
  version VARCHAR(50) NULL,
  app_version VARCHAR(50) NULL,
  manufacturer VARCHAR(50) NULL,
  model VARCHAR(50) NULL,
  ip_address VARCHAR(64) NULL,
  location VARCHAR(255) NULL,
  status VARCHAR(20) NOT NULL,
  registered_at DATETIME NOT NULL,
  approved_by VARCHAR(100) NULL,
  status_updated_at DATETIME NULL,
  UNIQUE KEY uk_device_driver_device (driver_id, device_id),
  INDEX idx_device_driver (driver_id),
  INDEX idx_device_status (status),
  CONSTRAINT fk_device_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

