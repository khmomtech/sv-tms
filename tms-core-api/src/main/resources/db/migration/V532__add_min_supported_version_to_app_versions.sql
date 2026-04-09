ALTER TABLE app_versions
    ADD COLUMN IF NOT EXISTS min_supported_version VARCHAR(50) NULL AFTER latest_version;

UPDATE app_versions
SET min_supported_version = latest_version
WHERE (min_supported_version IS NULL OR TRIM(min_supported_version) = '')
  AND mandatory_update = TRUE;
