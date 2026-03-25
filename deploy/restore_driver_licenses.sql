-- Restore driver_licenses table (reconstructed from JPA entity)
CREATE TABLE IF NOT EXISTS driver_licenses (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  driver_id BIGINT NOT NULL,
  license_number VARCHAR(50) NOT NULL UNIQUE,
  license_class VARCHAR(3),
  issued_date DATE,
  expiry_date DATE,
  issuing_authority VARCHAR(100),
  license_image_url VARCHAR(255),
  license_front_image VARCHAR(255),
  license_back_image VARCHAR(255),
  notes VARCHAR(255),
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_driver FOREIGN KEY (driver_id) REFERENCES drivers(id)
);
