-- ============================================================
-- Geofences table
-- Stores geographic zones used for driver arrival/departure
-- event detection and speed-limit enforcement.
-- ============================================================

CREATE TABLE IF NOT EXISTS geofences (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_id           BIGINT        NOT NULL,
    name                 VARCHAR(255)  NOT NULL,
    description          TEXT,

    -- Geometry: CIRCLE uses center_* + radius_meters;
    --           POLYGON/LINEAR use geo_json_coordinates
    type                 VARCHAR(20)   NOT NULL COMMENT 'CIRCLE | POLYGON | LINEAR',
    center_latitude      DOUBLE,
    center_longitude     DOUBLE,
    radius_meters        DOUBLE,
    geo_json_coordinates TEXT          COMMENT 'JSON-encoded coordinate array',

    alert_type           VARCHAR(10)   NOT NULL DEFAULT 'NONE' COMMENT 'ENTER | EXIT | BOTH | NONE',
    speed_limit_kmh      INT,
    active               TINYINT(1)   NOT NULL DEFAULT 1,

    -- Category tags stored as a JSON array string e.g. ["warehouse","restricted"]
    tags                 TEXT,

    created_by           VARCHAR(255),
    created_at           DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at           DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),

    INDEX idx_geofences_company_id (company_id),
    INDEX idx_geofences_active     (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
