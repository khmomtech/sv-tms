-- Strengthen document typing + expiry handling

ALTER TABLE vehicle_documents
  ADD COLUMN IF NOT EXISTS vehicle_id   BIGINT NULL,
  ADD COLUMN IF NOT EXISTS doc_type     VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS doc_number   VARCHAR(120) NULL,
  ADD COLUMN IF NOT EXISTS issued_date  DATE NULL,
  ADD COLUMN IF NOT EXISTS expiry_date  DATE NULL,
  ADD COLUMN IF NOT EXISTS file_url     VARCHAR(255) NULL,
  ADD COLUMN IF NOT EXISTS is_approved  TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS note         VARCHAR(255) NULL;

-- Set default doc_type if missing to avoid future NOT NULL blockers
UPDATE vehicle_documents SET doc_type='OTHER' WHERE doc_type IS NULL;

CREATE INDEX IF NOT EXISTS idx_vdoc_vehicle ON vehicle_documents(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vdoc_expiry  ON vehicle_documents(expiry_date);