-- Dispatch loading-type workflow governance

ALTER TABLE dispatches
  ADD COLUMN IF NOT EXISTS loading_type_code VARCHAR(30) NOT NULL DEFAULT 'GENERAL' COMMENT 'Workflow loading type template code';

CREATE INDEX IF NOT EXISTS idx_dispatch_loading_type_code ON dispatches (loading_type_code);

CREATE TABLE IF NOT EXISTS dispatch_flow_template (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(30) NOT NULL,
  name VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by BIGINT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_dispatch_flow_template_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispatch_flow_transition_rule (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  template_id BIGINT NOT NULL,
  from_status VARCHAR(50) NOT NULL,
  to_status VARCHAR(50) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  priority INT NOT NULL DEFAULT 100,
  requires_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
  requires_input BOOLEAN NOT NULL DEFAULT FALSE,
  validation_message VARCHAR(255) NULL,
  metadata_json JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_flow_rule_template FOREIGN KEY (template_id) REFERENCES dispatch_flow_template(id) ON DELETE CASCADE,
  UNIQUE KEY uk_dispatch_flow_rule (template_id, from_status, to_status),
  KEY idx_dispatch_flow_rule_from (template_id, from_status, enabled, priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispatch_flow_transition_actor (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  transition_rule_id BIGINT NOT NULL,
  actor_type VARCHAR(50) NOT NULL,
  can_execute BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_flow_actor_rule FOREIGN KEY (transition_rule_id) REFERENCES dispatch_flow_transition_rule(id) ON DELETE CASCADE,
  UNIQUE KEY uk_dispatch_flow_actor (transition_rule_id, actor_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE dispatch_status_history
  ADD COLUMN IF NOT EXISTS actor_user_id BIGINT NULL,
  ADD COLUMN IF NOT EXISTS actor_roles_snapshot VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS source VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
  ADD COLUMN IF NOT EXISTS override_reason VARCHAR(500) NULL;

CREATE INDEX IF NOT EXISTS idx_dispatch_status_history_actor_user ON dispatch_status_history (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_status_history_source ON dispatch_status_history (source);

INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
  ('dispatch:flow:manage', 'Manage dispatch flow templates and transition policy', 'dispatch', 'flow:manage'),
  ('dispatch:status:override', 'Override dispatch status outside normal policy', 'dispatch', 'status:override'),
  ('dispatch:status:manual:update', 'Manual dispatch status update through admin channel', 'dispatch', 'status:manual:update');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('dispatch:flow:manage', 'dispatch:status:override', 'dispatch:status:manual:update')
WHERE r.name = 'SUPERADMIN';

INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'GENERAL', 'GENERAL', 'No G-Team control loading', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'GENERAL');

INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'KHBL', 'KHBL', 'G-Team control loading flow', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'KHBL');

-- Seed GENERAL transitions from current static transition map
INSERT IGNORE INTO dispatch_flow_transition_rule (template_id, from_status, to_status, enabled, priority, requires_confirmation, requires_input, validation_message)
SELECT t.id, x.from_status, x.to_status, TRUE, x.priority, x.requires_confirmation, x.requires_input, x.validation_message
FROM dispatch_flow_template t
JOIN (
  SELECT 'PLANNED' from_status, 'PENDING' to_status, 10 priority, FALSE requires_confirmation, FALSE requires_input, NULL validation_message UNION ALL
  SELECT 'PLANNED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'PENDING', 'ASSIGNED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'PENDING', 'SCHEDULED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'PENDING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'SCHEDULED', 'ASSIGNED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'SCHEDULED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ASSIGNED', 'DRIVER_CONFIRMED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ASSIGNED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ASSIGNED', 'REJECTED', 95, TRUE, TRUE, 'Rejection reason required' UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'ARRIVED_LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'APPROVED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'DRIVER_CONFIRMED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'APPROVED', 'PENDING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'APPROVED', 'ASSIGNED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'APPROVED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ARRIVED_LOADING', 'SAFETY_PASSED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ARRIVED_LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'SAFETY_PASSED', 'IN_QUEUE', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'SAFETY_PASSED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'IN_QUEUE', 'LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_QUEUE', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'LOADING', 'LOADED', 10, FALSE, TRUE, 'Submit POL before leaving loading' UNION ALL
  SELECT 'LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'LOADED', 'AT_HUB', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'LOADED', 'IN_TRANSIT', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'LOADED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'AT_HUB', 'HUB_LOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'AT_HUB', 'IN_TRANSIT', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'AT_HUB', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'HUB_LOADING', 'IN_TRANSIT', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'HUB_LOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'IN_TRANSIT', 'ARRIVED_UNLOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_TRANSIT', 'AT_HUB', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'IN_TRANSIT', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'ARRIVED_UNLOADING', 'UNLOADING', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'ARRIVED_UNLOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'UNLOADING', 'UNLOADED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'SAFETY_PASSED', 30, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'SAFETY_FAILED', 40, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADING', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'UNLOADED', 'DELIVERED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'UNLOADED', 'CANCELLED', 90, TRUE, TRUE, 'Cancellation reason required' UNION ALL
  SELECT 'DELIVERED', 'FINANCIAL_LOCKED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'DELIVERED', 'COMPLETED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'FINANCIAL_LOCKED', 'CLOSED', 10, FALSE, FALSE, NULL UNION ALL
  SELECT 'FINANCIAL_LOCKED', 'COMPLETED', 20, FALSE, FALSE, NULL UNION ALL
  SELECT 'CLOSED', 'COMPLETED', 10, FALSE, FALSE, NULL
) x
WHERE t.code = 'GENERAL';

-- Clone GENERAL transitions to KHBL template if missing
INSERT IGNORE INTO dispatch_flow_transition_rule (template_id, from_status, to_status, enabled, priority, requires_confirmation, requires_input, validation_message)
SELECT khbl.id, r.from_status, r.to_status, r.enabled, r.priority, r.requires_confirmation, r.requires_input, r.validation_message
FROM dispatch_flow_template khbl
JOIN dispatch_flow_template general ON general.code = 'GENERAL'
JOIN dispatch_flow_transition_rule r ON r.template_id = general.id
WHERE khbl.code = 'KHBL';

-- GENERAL actors: DRIVER + operational teams + admin/system
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, a.actor_type, TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
JOIN (
  SELECT 'DRIVER' actor_type UNION ALL
  SELECT 'LOADING' UNION ALL
  SELECT 'SAFETY' UNION ALL
  SELECT 'DISPATCH_MONITOR' UNION ALL
  SELECT 'SYSTEM'
) a
WHERE t.code = 'GENERAL';

-- KHBL baseline actors same as GENERAL, then harden loading control below
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, a.actor_type, TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
JOIN (
  SELECT 'DRIVER' actor_type UNION ALL
  SELECT 'LOADING' UNION ALL
  SELECT 'SAFETY' UNION ALL
  SELECT 'DISPATCH_MONITOR' UNION ALL
  SELECT 'SYSTEM'
) a
WHERE t.code = 'KHBL';

-- KHBL hardening: driver cannot execute loading-control transitions
UPDATE dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r ON r.id = a.transition_rule_id
JOIN dispatch_flow_template t ON t.id = r.template_id
SET a.can_execute = FALSE
WHERE t.code = 'KHBL'
  AND a.actor_type = 'DRIVER'
  AND ((r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED'));

-- KHBL hardening: loading team explicitly controls queue/loading transitions
INSERT IGNORE INTO dispatch_flow_transition_actor (transition_rule_id, actor_type, can_execute)
SELECT r.id, 'LOADING', TRUE
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template t ON t.id = r.template_id
WHERE t.code = 'KHBL'
  AND ((r.from_status = 'SAFETY_PASSED' AND r.to_status = 'IN_QUEUE')
    OR (r.from_status = 'IN_QUEUE' AND r.to_status = 'LOADING')
    OR (r.from_status = 'LOADING' AND r.to_status = 'LOADED'));
