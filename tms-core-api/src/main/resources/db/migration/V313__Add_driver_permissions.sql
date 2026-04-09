-- Add missing driver permissions
INSERT INTO permissions (name, description, resource_type, action_type) VALUES
('driver.view.all', 'View all drivers', 'driver', 'view'),
('driver.manage', 'Manage drivers (create, update, delete)', 'driver', 'manage'),
('driver.account.manage', 'Manage driver accounts', 'driver', 'account.manage');

-- Assign driver permissions to ADMIN role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'ADMIN'
AND p.name IN ('driver.view.all', 'driver.manage', 'driver.account.manage');

-- Optionally assign view permission to MANAGER role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'MANAGER'
AND p.name = 'driver.view.all';