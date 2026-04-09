-- Factory gate safety checklist table
CREATE TABLE IF NOT EXISTS pre_loading_safety_checks (
    id BIGSERIAL PRIMARY KEY,
    dispatch_id BIGINT NOT NULL REFERENCES dispatches(id) ON DELETE CASCADE,
    driver_ppe_ok BOOLEAN NOT NULL,
    fire_extinguisher_ok BOOLEAN NOT NULL,
    wheel_chock_ok BOOLEAN NOT NULL,
    truck_leakage_ok BOOLEAN NOT NULL,
    truck_clean_ok BOOLEAN NOT NULL,
    truck_condition_ok BOOLEAN NOT NULL,
    result VARCHAR(20) NOT NULL,
    fail_reason VARCHAR(500),
    checked_by_user_id BIGINT REFERENCES users(id),
    checked_at TIMESTAMP,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_preload_dispatch ON pre_loading_safety_checks(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_preload_result ON pre_loading_safety_checks(result);
CREATE INDEX IF NOT EXISTS idx_preload_checked_at ON pre_loading_safety_checks(checked_at);
CREATE INDEX IF NOT EXISTS idx_preload_checked_by ON pre_loading_safety_checks(checked_by_user_id);
