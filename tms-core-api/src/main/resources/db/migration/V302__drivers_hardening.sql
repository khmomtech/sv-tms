-- Strengthen Driver with enums-ish columns and ownership

ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS first_name        VARCHAR(80) NULL,
  ADD COLUMN IF NOT EXISTS last_name         VARCHAR(80) NULL,
  ADD COLUMN IF NOT EXISTS status            VARCHAR(20) NULL,
  ADD COLUMN IF NOT EXISTS ownership         VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS partner_company   VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS phone             VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS email             VARCHAR(120) NULL,
  ADD COLUMN IF NOT EXISTS license_number    VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS license_expiry    DATE NULL,
  ADD COLUMN IF NOT EXISTS latitude          DOUBLE NULL,
  ADD COLUMN IF NOT EXISTS longitude         DOUBLE NULL,
  ADD COLUMN IF NOT EXISTS last_heartbeat    DATETIME NULL;

-- Sane defaults
UPDATE drivers SET status='ACTIVE' WHERE status IS NULL;
UPDATE drivers SET ownership='COMPANY' WHERE ownership IS NULL;

CREATE INDEX IF NOT EXISTS idx_driver_status ON drivers(status);
CREATE INDEX IF NOT EXISTS idx_driver_ownership ON drivers(ownership);