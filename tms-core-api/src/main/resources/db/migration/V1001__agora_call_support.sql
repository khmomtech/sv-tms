-- ============================================================
-- V1000: Agora voice/video call support
-- Adds agora_channel_name + call_session_id to driver_chat_messages
-- Creates call_sessions table
-- ============================================================

-- 1. Extend driver_chat_messages with Agora call fields
ALTER TABLE driver_chat_messages
    ADD COLUMN IF NOT EXISTS agora_channel_name VARCHAR(128)   NULL,
    ADD COLUMN IF NOT EXISTS call_session_id    BIGINT         NULL;

-- 2. Add new message types to the enum (MySQL ENUM alter)
--    If your DB uses VARCHAR for message_type (which is safer), skip this block.
--    For VARCHAR-backed enums (Spring default with @Enumerated(STRING)) this is a no-op.
--    For native MySQL ENUMs, uncomment and adjust:
-- ALTER TABLE driver_chat_messages
--     MODIFY COLUMN message_type ENUM(
--         'TEXT','IMAGE','VOICE','VIDEO','LOCATION',
--         'CALL_REQUEST','CALL_ACCEPTED','CALL_DECLINED','CALL_ENDED','TYPING'
--     ) NOT NULL DEFAULT 'TEXT';

-- 3. call_sessions table
CREATE TABLE IF NOT EXISTS call_sessions (
    id                BIGINT          NOT NULL AUTO_INCREMENT,
    driver_id         BIGINT          NOT NULL,
    admin_username    VARCHAR(100)    NULL,
    channel_name      VARCHAR(128)    NOT NULL,
    status            VARCHAR(20)     NOT NULL DEFAULT 'RINGING',
    started_at        DATETIME(6)     NOT NULL,
    answered_at       DATETIME(6)     NULL,
    ended_at          DATETIME(6)     NULL,
    duration_seconds  INT             NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_call_sessions_channel (channel_name),
    KEY idx_call_sessions_driver (driver_id),
    KEY idx_call_sessions_status  (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. FK from driver_chat_messages.call_session_id → call_sessions.id
ALTER TABLE driver_chat_messages
    ADD CONSTRAINT IF NOT EXISTS fk_chat_msg_call_session
        FOREIGN KEY (call_session_id) REFERENCES call_sessions (id)
        ON DELETE SET NULL;
