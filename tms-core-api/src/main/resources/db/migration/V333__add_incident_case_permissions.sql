-- V333: Add permissions for Incident & Case Management

-- Incident permissions
INSERT INTO permissions (name, description, resource_type, action_type)
VALUES
  ('incident:view', 'View incidents', 'INCIDENT', 'READ'),
  ('incident:list', 'List all incidents', 'INCIDENT', 'LIST'),
  ('incident:create', 'Create new incident', 'INCIDENT', 'CREATE'),
  ('incident:update', 'Update incident details', 'INCIDENT', 'UPDATE'),
  ('incident:delete', 'Delete incident', 'INCIDENT', 'DELETE'),
  ('incident:validate', 'Validate and approve incidents', 'INCIDENT', 'VALIDATE'),
  ('incident:escalate', 'Escalate incident to case', 'INCIDENT', 'ESCALATE'),
  ('incident:manage', 'Full incident management', 'INCIDENT', 'MANAGE')
ON DUPLICATE KEY UPDATE 
  description = VALUES(description),
  resource_type = VALUES(resource_type),
  action_type = VALUES(action_type);

-- Case permissions
INSERT INTO permissions (name, description, resource_type, action_type)
VALUES
  ('case:view', 'View cases', 'CASE', 'READ'),
  ('case:list', 'List all cases', 'CASE', 'LIST'),
  ('case:create', 'Create new case', 'CASE', 'CREATE'),
  ('case:update', 'Update case details', 'CASE', 'UPDATE'),
  ('case:delete', 'Delete case', 'CASE', 'DELETE'),
  ('case:assign', 'Assign cases to users', 'CASE', 'ASSIGN'),
  ('case:close', 'Close and resolve cases', 'CASE', 'CLOSE'),
  ('case:manage', 'Full case management', 'CASE', 'MANAGE')
ON DUPLICATE KEY UPDATE 
  description = VALUES(description),
  resource_type = VALUES(resource_type),
  action_type = VALUES(action_type);

-- Case Task permissions
INSERT INTO permissions (name, description, resource_type, action_type)
VALUES
  ('case_task:view', 'View case tasks', 'CASE_TASK', 'READ'),
  ('case_task:create', 'Create case tasks', 'CASE_TASK', 'CREATE'),
  ('case_task:update', 'Update case tasks', 'CASE_TASK', 'UPDATE'),
  ('case_task:delete', 'Delete case tasks', 'CASE_TASK', 'DELETE'),
  ('case_task:manage', 'Full case task management', 'CASE_TASK', 'MANAGE')
ON DUPLICATE KEY UPDATE 
  description = VALUES(description),
  resource_type = VALUES(resource_type),
  action_type = VALUES(action_type);

-- Case Attachment permissions
INSERT INTO permissions (name, description, resource_type, action_type)
VALUES
  ('case_attachment:view', 'View case attachments', 'CASE_ATTACHMENT', 'READ'),
  ('case_attachment:upload', 'Upload case attachments', 'CASE_ATTACHMENT', 'CREATE'),
  ('case_attachment:delete', 'Delete case attachments', 'CASE_ATTACHMENT', 'DELETE'),
  ('case_attachment:manage', 'Full case attachment management', 'CASE_ATTACHMENT', 'MANAGE')
ON DUPLICATE KEY UPDATE 
  description = VALUES(description),
  resource_type = VALUES(resource_type),
  action_type = VALUES(action_type);

-- Grant permissions to ADMIN role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
  AND p.name IN (
    'incident:view', 'incident:list', 'incident:create', 'incident:update', 
    'incident:delete', 'incident:validate', 'incident:escalate', 'incident:manage',
    'case:view', 'case:list', 'case:create', 'case:update', 
    'case:delete', 'case:assign', 'case:close', 'case:manage',
    'case_task:view', 'case_task:create', 'case_task:update', 
    'case_task:delete', 'case_task:manage',
    'case_attachment:view', 'case_attachment:upload', 
    'case_attachment:delete', 'case_attachment:manage'
  )
ON DUPLICATE KEY UPDATE permission_id = VALUES(permission_id);

-- Grant view permissions to DISPATCHER role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'DISPATCHER'
  AND p.name IN (
    'incident:view', 'incident:list', 'incident:create',
    'case:view', 'case:list'
  )
ON DUPLICATE KEY UPDATE permission_id = VALUES(permission_id);

-- Grant basic incident reporting to DRIVER role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'DRIVER'
  AND p.name IN ('incident:create', 'incident:view')
ON DUPLICATE KEY UPDATE permission_id = VALUES(permission_id);
