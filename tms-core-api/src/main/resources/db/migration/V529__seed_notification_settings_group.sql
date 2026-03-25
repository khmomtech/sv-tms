-- ============================================================
-- V529 — Seed notification setting group and definitions
--
-- Enables DynamicPushProvider to read/write the active push
-- provider from the DB-backed SettingService so admins can
-- switch providers at runtime without restarting the app:
--
--   POST /api/admin/settings/value
--   { "groupCode": "notification", "keyCode": "push.provider",
--     "value": "kafka", "scope": "GLOBAL",
--     "reason": "Switch to Kafka for load testing" }
-- ============================================================

-- ── 1. Setting group ─────────────────────────────────────────
INSERT INTO setting_group (code, name, description)
VALUES (
  'notification',
  'Notification Settings',
  'Controls push notification delivery channel (Kafka / FCM / none), queue behaviour, and Kafka topic routing.'
)
ON DUPLICATE KEY UPDATE
  name        = VALUES(name),
  description = VALUES(description);

-- ── 2. Setting definitions ───────────────────────────────────
-- push.provider  (default: kafka)
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, regex_pattern, requires_restart)
SELECT
  g.id,
  'push.provider',
  'Push Provider',
  'Active push-notification delivery channel. '
  || 'kafka = Publish to Kafka topic; a downstream worker forwards to FCM/APNS (default). '
  || 'fcm = Firebase direct send (requires FIREBASE_CONFIG_PATH). '
  || 'none = Suppress all push notifications (dev/CI).',
  'STRING',
  0,
  'kafka',
  '^(fcm|kafka|none)$',
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label           = VALUES(label),
  description     = VALUES(description),
  default_value   = VALUES(default_value),
  regex_pattern   = VALUES(regex_pattern);

-- queue.enabled
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, requires_restart)
SELECT
  g.id,
  'queue.enabled',
  'Queue Enabled',
  'When true, notifications are enqueued in Redis before delivery. '
  || 'When false, the configured push provider is called synchronously (no Redis required).',
  'BOOLEAN',
  0,
  'true',
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label         = VALUES(label),
  description   = VALUES(description),
  default_value = VALUES(default_value);

-- queue.max-attempts
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, min_value, max_value, requires_restart)
SELECT
  g.id,
  'queue.max-attempts',
  'Queue Max Retry Attempts',
  'Maximum number of delivery attempts before a queued notification is dropped.',
  'NUMBER',
  0,
  '5',
  1,
  50,
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label         = VALUES(label),
  description   = VALUES(description),
  default_value = VALUES(default_value);

-- queue.poll-interval-ms
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, min_value, max_value, requires_restart)
SELECT
  g.id,
  'queue.poll-interval-ms',
  'Queue Poll Interval (ms)',
  'How often the queue consumer drains pending notifications from Redis, in milliseconds.',
  'NUMBER',
  0,
  '3000',
  500,
  60000,
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label         = VALUES(label),
  description   = VALUES(description),
  default_value = VALUES(default_value);

-- kafka.topic
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, requires_restart)
SELECT
  g.id,
  'kafka.topic',
  'Kafka Topic (General)',
  'Kafka topic name for regular push notifications. Only used when push.provider=kafka.',
  'STRING',
  0,
  'notifications.push',
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label         = VALUES(label),
  description   = VALUES(description),
  default_value = VALUES(default_value);

-- kafka.call-topic
INSERT INTO setting_def
  (group_id, key_code, label, description, type, required, default_value, requires_restart)
SELECT
  g.id,
  'kafka.call-topic',
  'Kafka Topic (Incoming Calls)',
  'Kafka topic for high-priority INCOMING_CALL events. '
  || 'Defaults to the general topic if left blank. Only used when push.provider=kafka.',
  'STRING',
  0,
  'notifications.call',
  0
FROM setting_group g WHERE g.code = 'notification'
ON DUPLICATE KEY UPDATE
  label         = VALUES(label),
  description   = VALUES(description),
  default_value = VALUES(default_value);
