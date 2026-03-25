-- V20260308__pre_entry_safety_photos_table.sql
-- Ensure table exists for @ElementCollection mapping in PreEntrySafetyCheck.inspectionPhotos

CREATE TABLE IF NOT EXISTS pre_entry_safety_inspection_photos (
    safety_check_id BIGINT NOT NULL,
    photo_path VARCHAR(255),
    CONSTRAINT fk_pre_entry_safety_photos_check
        FOREIGN KEY (safety_check_id) REFERENCES pre_entry_safety_check(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX IF NOT EXISTS idx_pre_entry_safety_photos_check_id
    ON pre_entry_safety_inspection_photos (safety_check_id);
