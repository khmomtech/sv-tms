-- Geofences table for tms-telematics-api
-- Stores configurable geographic zones used for driver entry/exit alerting.

CREATE TABLE geofences (
    id               BIGSERIAL        PRIMARY KEY,
    company_id       BIGINT           NOT NULL,
    name             VARCHAR(255)     NOT NULL,
    description      TEXT,
    type             VARCHAR(20)      NOT NULL CHECK (type IN ('CIRCLE', 'POLYGON', 'LINEAR')),
    center_latitude  DECIMAL(10, 7),
    center_longitude DECIMAL(11, 7),
    radius_meters    DECIMAL(10, 2),
    geo_json_coordinates TEXT,
    alert_type       VARCHAR(10)      NOT NULL DEFAULT 'NONE'
                         CHECK (alert_type IN ('ENTER', 'EXIT', 'BOTH', 'NONE')),
    speed_limit_kmh  INTEGER,
    active           BOOLEAN          NOT NULL DEFAULT TRUE,
    tags             TEXT,
    created_by       VARCHAR(255),
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_geofences_company_id ON geofences (company_id);
CREATE INDEX idx_geofences_active     ON geofences (active);
