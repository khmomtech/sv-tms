-- Add all_functions permission for superadmin wildcard access
INSERT INTO permissions (name, description, resource_type, action_type) VALUES
('all_functions', 'Wildcard permission granting access to all system functions', 'system', 'all');

-- Assign all_functions permission to SUPERADMIN role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'SUPERADMIN'
AND p.name = 'all_functions';