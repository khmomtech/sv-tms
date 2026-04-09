-- Revert seed: remove 'all_functions' permission and any role links
-- WARNING: this will remove the permission and unlink it from roles.

-- Remove role links
DELETE rp
FROM role_permissions rp
JOIN permissions p ON rp.permission_id = p.id
WHERE p.name = 'all_functions';

-- Remove the permission row
DELETE FROM permissions WHERE name = 'all_functions';
-- Revert script: remove 'all_functions' permission and its role links
-- Use with caution. This will detach the permission from roles and delete it
-- only if no other references exist.

-- Remove role -> permission links for the permission
DELETE rp
FROM role_permissions rp
JOIN permissions p ON rp.permission_id = p.id
WHERE p.name = 'all_functions';

-- Remove the permission if it's no longer referenced
DELETE FROM permissions
WHERE name = 'all_functions'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.permission_id = permissions.id
  );
