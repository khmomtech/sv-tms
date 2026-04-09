-- Flyway migration: create refresh_tokens table for token rotation
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  token VARCHAR(512) NOT NULL,
  user_id BIGINT,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NULL,
  revoked BOOLEAN DEFAULT FALSE,
  device_info VARCHAR(256),
  CONSTRAINT uq_refresh_token UNIQUE (token)
);
