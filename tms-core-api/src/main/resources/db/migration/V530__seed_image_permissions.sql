-- V530__seed_image_permissions.sql
-- Adds image:* permissions to the permissions table and assigns them to SUPERADMIN role.
-- Required by ImageManagementController which uses @PreAuthorize with PermissionNames.IMAGE_*.

INSERT IGNORE INTO permissions (name, description)
VALUES
  ('image:read',   'View/list managed images'),
  ('image:create', 'Upload new images'),
  ('image:update', 'Update image metadata'),
  ('image:delete', 'Delete managed images');

-- Assign all image permissions to SUPERADMIN role
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('image:read', 'image:create', 'image:update', 'image:delete')
WHERE r.name = 'SUPERADMIN';
