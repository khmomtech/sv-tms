-- Add license-specific metadata columns to driver_documents.
-- This ensures driver_documents can store license data when driver_licenses is removed.

ALTER TABLE driver_documents
  ADD COLUMN IF NOT EXISTS license_number VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS license_class VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS issue_date DATE NULL,
  ADD COLUMN IF NOT EXISTS issuing_authority VARCHAR(255) NULL,
  ADD COLUMN IF NOT EXISTS license_image_url VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS license_front_image VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS license_back_image VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS license_notes TEXT NULL,
  ADD COLUMN IF NOT EXISTS document_url VARCHAR(500) NULL;

-- Index license_number for lookups
CREATE INDEX IF NOT EXISTS idx_driver_documents_license_number ON driver_documents(license_number);
