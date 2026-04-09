ALTER TABLE dispatch_flow_template
  ADD COLUMN IF NOT EXISTS active_published_version_id BIGINT NULL;

ALTER TABLE dispatches
  ADD COLUMN IF NOT EXISTS workflow_version_id BIGINT NULL,
  ADD COLUMN IF NOT EXISTS pod_required BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS pod_submitted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS pod_submitted_at TIMESTAMP NULL,
  ADD COLUMN IF NOT EXISTS pod_verified BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_dispatch_workflow_version_id ON dispatches (workflow_version_id);

CREATE TABLE IF NOT EXISTS dispatch_flow_template_version (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  template_id BIGINT NOT NULL,
  version_no INT NOT NULL,
  version_label VARCHAR(40) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
  active_published BOOLEAN NOT NULL DEFAULT FALSE,
  source_updated_at TIMESTAMP NULL,
  notes VARCHAR(255) NULL,
  created_by BIGINT NULL,
  published_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_flow_template_version_template
    FOREIGN KEY (template_id) REFERENCES dispatch_flow_template(id) ON DELETE CASCADE,
  UNIQUE KEY uk_dispatch_flow_template_version (template_id, version_no),
  KEY idx_dispatch_flow_template_version_active (template_id, active_published)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispatch_flow_transition_rule_version (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  template_version_id BIGINT NOT NULL,
  source_rule_id BIGINT NULL,
  from_status VARCHAR(50) NOT NULL,
  to_status VARCHAR(50) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  priority INT NOT NULL DEFAULT 100,
  requires_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
  requires_input BOOLEAN NOT NULL DEFAULT FALSE,
  validation_message VARCHAR(255) NULL,
  metadata_json JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_flow_rule_version_template
    FOREIGN KEY (template_version_id) REFERENCES dispatch_flow_template_version(id) ON DELETE CASCADE,
  UNIQUE KEY uk_dispatch_flow_rule_version (template_version_id, from_status, to_status),
  KEY idx_dispatch_flow_rule_version_from (template_version_id, from_status, enabled, priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispatch_flow_transition_actor_version (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  transition_rule_version_id BIGINT NOT NULL,
  actor_type VARCHAR(50) NOT NULL,
  can_execute BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_flow_actor_version_rule
    FOREIGN KEY (transition_rule_version_id) REFERENCES dispatch_flow_transition_rule_version(id) ON DELETE CASCADE,
  UNIQUE KEY uk_dispatch_flow_actor_version (transition_rule_version_id, actor_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispatch_proof_event (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  dispatch_id BIGINT NOT NULL,
  workflow_version_id BIGINT NULL,
  proof_type VARCHAR(20) NOT NULL,
  actor_user_id BIGINT NULL,
  actor_roles_snapshot VARCHAR(500) NULL,
  dispatch_status_at_submission VARCHAR(50) NULL,
  accepted BOOLEAN NOT NULL DEFAULT FALSE,
  block_code VARCHAR(100) NULL,
  block_reason VARCHAR(500) NULL,
  idempotency_key VARCHAR(150) NULL,
  file_count INT NOT NULL DEFAULT 0,
  review_status VARCHAR(20) NOT NULL DEFAULT 'NOT_REQUIRED',
  review_note VARCHAR(500) NULL,
  reviewed_by BIGINT NULL,
  reviewed_at TIMESTAMP NULL,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispatch_proof_event_dispatch
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE CASCADE,
  KEY idx_dispatch_proof_event_dispatch (dispatch_id, submitted_at),
  KEY idx_dispatch_proof_event_review (review_status, submitted_at),
  KEY idx_dispatch_proof_event_idempotency (dispatch_id, proof_type, idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO dispatch_flow_template_version (
  template_id,
  version_no,
  version_label,
  status,
  active_published,
  source_updated_at,
  notes,
  created_by,
  published_at
)
SELECT
  t.id,
  1,
  'v1',
  'PUBLISHED',
  TRUE,
  t.updated_at,
  'Initial snapshot from editable draft tables',
  t.updated_by,
  CURRENT_TIMESTAMP
FROM dispatch_flow_template t
WHERE NOT EXISTS (
  SELECT 1
  FROM dispatch_flow_template_version v
  WHERE v.template_id = t.id
);

INSERT INTO dispatch_flow_transition_rule_version (
  template_version_id,
  source_rule_id,
  from_status,
  to_status,
  enabled,
  priority,
  requires_confirmation,
  requires_input,
  validation_message,
  metadata_json
)
SELECT
  v.id,
  r.id,
  r.from_status,
  r.to_status,
  r.enabled,
  r.priority,
  r.requires_confirmation,
  r.requires_input,
  r.validation_message,
  r.metadata_json
FROM dispatch_flow_transition_rule r
JOIN dispatch_flow_template_version v
  ON v.template_id = r.template_id
 AND v.version_no = 1
WHERE NOT EXISTS (
  SELECT 1
  FROM dispatch_flow_transition_rule_version rv
  WHERE rv.template_version_id = v.id
    AND rv.from_status = r.from_status
    AND rv.to_status = r.to_status
);

INSERT INTO dispatch_flow_transition_actor_version (
  transition_rule_version_id,
  actor_type,
  can_execute
)
SELECT
  rv.id,
  a.actor_type,
  a.can_execute
FROM dispatch_flow_transition_actor a
JOIN dispatch_flow_transition_rule r
  ON r.id = a.transition_rule_id
JOIN dispatch_flow_template_version v
  ON v.template_id = r.template_id
 AND v.version_no = 1
JOIN dispatch_flow_transition_rule_version rv
  ON rv.template_version_id = v.id
 AND rv.from_status = r.from_status
 AND rv.to_status = r.to_status
WHERE NOT EXISTS (
  SELECT 1
  FROM dispatch_flow_transition_actor_version av
  WHERE av.transition_rule_version_id = rv.id
    AND av.actor_type = a.actor_type
);

UPDATE dispatch_flow_template t
JOIN dispatch_flow_template_version v
  ON v.template_id = t.id
 AND v.active_published = TRUE
SET t.active_published_version_id = v.id
WHERE t.active_published_version_id IS NULL;

UPDATE dispatches d
LEFT JOIN dispatch_flow_template t
  ON UPPER(t.code) = UPPER(COALESCE(NULLIF(TRIM(d.loading_type_code), ''), 'GENERAL'))
LEFT JOIN dispatch_flow_template tg
  ON tg.code = 'GENERAL'
LEFT JOIN dispatch_flow_template_version v
  ON v.id = COALESCE(t.active_published_version_id, tg.active_published_version_id)
SET d.loading_type_code = COALESCE(NULLIF(TRIM(d.loading_type_code), ''), 'GENERAL'),
    d.workflow_version_id = COALESCE(d.workflow_version_id, v.id)
WHERE d.workflow_version_id IS NULL OR d.loading_type_code IS NULL OR TRIM(d.loading_type_code) = '';

UPDATE dispatches d
LEFT JOIN unload_proof up ON up.dispatch_id = d.id
SET d.pod_submitted = CASE WHEN up.id IS NOT NULL THEN TRUE ELSE d.pod_submitted END,
    d.pod_submitted_at = COALESCE(d.pod_submitted_at, up.submitted_at)
WHERE up.id IS NOT NULL;
