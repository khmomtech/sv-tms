-- Tracks per-conversation admin state (archive, resolve) for driver chat.
-- One row per driverId; created on first action.
CREATE TABLE IF NOT EXISTS driver_chat_conversation_metadata (
    driver_id         BIGINT      NOT NULL PRIMARY KEY,
    archived_by_admin BOOLEAN     NOT NULL DEFAULT FALSE,
    resolved_by_admin BOOLEAN     NOT NULL DEFAULT FALSE,
    updated_at        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);
