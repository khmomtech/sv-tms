-- Flyway migration: create import_audit table to record provenance of large imports
-- Run this before performing bulk imports to record start/finish and checksums
CREATE TABLE IF NOT EXISTS import_audit (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  import_id VARCHAR(64) NOT NULL,
  source_file VARCHAR(512),
  row_count INT DEFAULT 0,
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at TIMESTAMP NULL,
  checksum VARCHAR(128),
  status VARCHAR(32) DEFAULT 'PENDING',
  created_by VARCHAR(128),
  notes TEXT,
  UNIQUE KEY uq_import_id (import_id)
);
