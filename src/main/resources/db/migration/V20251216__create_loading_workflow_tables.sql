-- =============================================================================
-- V20251216: Loading workflow + pre-loading safety tables
-- Adds queue/session tracking, pallet + empties details, loading documents,
-- and pre-loading safety check audits for dispatches.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1) Loading queue (one-to-one with dispatch)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loading_queue (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dispatch_id BIGINT NOT NULL,
    warehouse_code VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL,
    queue_position INT,
    bay VARCHAR(32),
    remarks VARCHAR(500),
    called_at DATETIME,
    loading_started_at DATETIME,
    loading_completed_at DATETIME,
    created_by BIGINT,
    updated_by BIGINT,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_loading_queue_dispatch UNIQUE (dispatch_id),
    CONSTRAINT fk_loading_queue_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE CASCADE,
    CONSTRAINT fk_loading_queue_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_loading_queue_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_loading_queue_status (status),
    INDEX idx_loading_queue_warehouse (warehouse_code),
    INDEX idx_loading_queue_dispatch (dispatch_id),
    INDEX idx_loading_queue_created_date (created_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2) Loading sessions (one-to-one with dispatch, optional link to queue)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loading_sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dispatch_id BIGINT NOT NULL,
    queue_id BIGINT,
    warehouse_code VARCHAR(10) NOT NULL,
    bay VARCHAR(32),
    started_at DATETIME,
    ended_at DATETIME,
    started_by BIGINT,
    ended_by BIGINT,
    remarks VARCHAR(500),
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_loading_session_dispatch UNIQUE (dispatch_id),
    CONSTRAINT fk_loading_session_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE CASCADE,
    CONSTRAINT fk_loading_session_queue FOREIGN KEY (queue_id) REFERENCES loading_queue(id) ON DELETE SET NULL,
    CONSTRAINT fk_loading_session_started_by FOREIGN KEY (started_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_loading_session_ended_by FOREIGN KEY (ended_by) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_loading_session_dispatch (dispatch_id),
    INDEX idx_loading_session_warehouse (warehouse_code),
    INDEX idx_loading_session_started (started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3) Loading pallet items (line items per session)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loading_pallet_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    loading_session_id BIGINT NOT NULL,
    item_description VARCHAR(255) NOT NULL,
    pallet_tag VARCHAR(64),
    quantity INT NOT NULL,
    unit VARCHAR(32),
    condition_note VARCHAR(255),
    verified_ok BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_loading_pallet_session FOREIGN KEY (loading_session_id) REFERENCES loading_sessions(id) ON DELETE CASCADE,
    INDEX idx_loading_pallet_session (loading_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4) Loading empties/returns (per session)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loading_empties_return (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    loading_session_id BIGINT NOT NULL,
    item_name VARCHAR(128) NOT NULL,
    quantity INT NOT NULL,
    unit VARCHAR(32),
    condition_note VARCHAR(255),
    recorded_at DATETIME,

    CONSTRAINT fk_loading_empties_session FOREIGN KEY (loading_session_id) REFERENCES loading_sessions(id) ON DELETE CASCADE,
    INDEX idx_loading_empties_session (loading_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5) Loading documents (per session/dispatch)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loading_documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    loading_session_id BIGINT NOT NULL,
    dispatch_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(512) NOT NULL,
    mime_type VARCHAR(100),
    uploaded_by BIGINT,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_loading_document_session FOREIGN KEY (loading_session_id) REFERENCES loading_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_loading_document_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE CASCADE,
    CONSTRAINT fk_loading_document_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_loading_doc_dispatch (dispatch_id),
    INDEX idx_loading_doc_session (loading_session_id),
    INDEX idx_loading_doc_type (document_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6) Pre-loading safety checks
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pre_loading_safety_checks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dispatch_id BIGINT NOT NULL,
    driver_ppe_ok BOOLEAN NOT NULL,
    fire_extinguisher_ok BOOLEAN NOT NULL,
    wheel_chock_ok BOOLEAN NOT NULL,
    truck_leakage_ok BOOLEAN NOT NULL,
    truck_clean_ok BOOLEAN NOT NULL,
    truck_condition_ok BOOLEAN NOT NULL,
    result VARCHAR(20) NOT NULL,
    fail_reason VARCHAR(500),
    checked_by_user_id BIGINT,
    checked_at DATETIME,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_preload_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE CASCADE,
    CONSTRAINT fk_preload_checked_by FOREIGN KEY (checked_by_user_id) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_preload_dispatch (dispatch_id),
    INDEX idx_preload_result (result),
    INDEX idx_preload_checked_at (checked_at),
    INDEX idx_preload_checked_by (checked_by_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
