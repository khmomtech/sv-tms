-- Create Settings module tables
CREATE TABLE IF NOT EXISTS setting_group (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(128) NOT NULL UNIQUE,
  name VARCHAR(128) NOT NULL,
  description VARCHAR(512) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS setting_def (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  group_id BIGINT NOT NULL,
  key_code VARCHAR(128) NOT NULL,
  label VARCHAR(128) NOT NULL,
  description VARCHAR(512) NULL,
  type ENUM('STRING','NUMBER','BOOLEAN','JSON','URL','EMAIL','LIST','MAP','PASSWORD') NOT NULL,
  required TINYINT(1) NOT NULL DEFAULT 0,
  default_value LONGTEXT NULL,
  min_value BIGINT NULL,
  max_value BIGINT NULL,
  regex_pattern VARCHAR(256) NULL,
  requires_restart TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_group_key (group_id, key_code),
  CONSTRAINT fk_sd_group FOREIGN KEY (group_id) REFERENCES setting_group(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS setting_value (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  def_id BIGINT NOT NULL,
  scope ENUM('GLOBAL','TENANT','SITE') NOT NULL DEFAULT 'GLOBAL',
  scope_ref VARCHAR(128) NULL,
  value_text LONGTEXT NULL,
  version INT NOT NULL DEFAULT 1,
  updated_by VARCHAR(128) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sv_def FOREIGN KEY (def_id) REFERENCES setting_def(id) ON DELETE CASCADE,
  KEY idx_sv_scope (scope, scope_ref),
  KEY idx_sv_def (def_id),
  KEY idx_sv_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS setting_audit (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  def_id BIGINT NOT NULL,
  scope ENUM('GLOBAL','TENANT','SITE') NOT NULL,
  scope_ref VARCHAR(128) NULL,
  old_value LONGTEXT NULL,
  new_value LONGTEXT NULL,
  updated_by VARCHAR(128) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reason VARCHAR(256) NULL,
  CONSTRAINT fk_sa_def FOREIGN KEY (def_id) REFERENCES setting_def(id) ON DELETE CASCADE,
  KEY idx_sa_def (def_id),
  KEY idx_sa_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;