-- Idempotent seed: ensure 'all_functions' permission exists and is linked to ADMIN and SUPERADMIN
-- Safe to run multiple times.

INSERT INTO permissions (name, description, resource_type, action_type)
SELECT * FROM (
  SELECT 'all_functions' AS name,
         'Wildcard permission granting access to all system functions' AS description,
         'global' AS resource_type,
         'all' AS action_type
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'all_functions')
LIMIT 1;

-- Link the permission to ADMIN and SUPERADMIN roles (idempotent)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'all_functions'
WHERE r.name IN ('ADMIN','SUPERADMIN')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );
-- Idempotent seed: ensure 'all_functions' permission exists and is assigned
-- to ADMIN and SUPERADMIN roles.

INSERT INTO permissions (name, description, resource_type, action_type)
SELECT 'all_functions', 'Wildcard permission granting access to all system functions', 'global', 'all'
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.name = 'all_functions');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'all_functions'
WHERE r.name IN ('ADMIN', 'SUPERADMIN')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );
