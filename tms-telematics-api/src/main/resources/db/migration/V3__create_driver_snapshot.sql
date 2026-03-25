-- V3: Driver snapshot — minimal driver info pushed by tms-backend (fire-and-forget sync)

CREATE TABLE IF NOT EXISTS driver_snapshot (
    driver_id       BIGINT          NOT NULL,
    full_name       VARCHAR(255),
    phone_number    VARCHAR(32),
    vehicle_plate   VARCHAR(32),
    synced_at       TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (driver_id)
);
