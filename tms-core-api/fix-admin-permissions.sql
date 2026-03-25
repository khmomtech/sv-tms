-- ================================================
-- Grant all driver permissions to ADMIN role
-- ================================================
-- This script ensures ADMIN role has full access to driver management features
-- Run this if you get "Access denied. You need DRIVER_VIEW_ALL or DRIVER_MANAGE permission"

-- Step 1: Ensure permissions exist
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('driver.view.all', 'View all drivers', 'driver', 'view'),
('driver.manage', 'Manage drivers (create, update, delete)', 'driver', 'manage'),
('driver.account.manage', 'Manage driver accounts', 'driver', 'account.manage');

-- Step 2: Verify ADMIN role exists
-- (If not, you may need to create it first)
SELECT id, name FROM roles WHERE name = 'ADMIN';

-- Step 3: Assign driver permissions to ADMIN role
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
AND p.name IN ('driver.view.all', 'driver.manage', 'driver.account.manage');

-- Step 4: Verify the assignments
SELECT 
    r.name AS role_name,
    p.name AS permission_name,
    p.description AS permission_description
FROM roles r
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON p.id = rp.permission_id
WHERE r.name = 'ADMIN';

-- ================================================
-- Optional: Create SUPER_ADMIN role
-- ================================================
-- Uncomment the following if you want to add SUPER_ADMIN role to RoleType enum

-- INSERT IGNORE INTO roles (name, description) VALUES
-- ('SUPER_ADMIN', 'Super Administrator with full system access');

-- -- Grant all existing permissions to SUPER_ADMIN
-- INSERT IGNORE INTO role_permissions (role_id, permission_id)
-- SELECT r.id, p.id
-- FROM roles r
-- CROSS JOIN permissions p
-- WHERE r.name = 'SUPER_ADMIN';

-- ================================================
-- How to use this script:
-- ================================================
-- Option 1: Using Docker MySQL container
--   docker exec -i sv-tms-mysql-1 mysql -udriver -pdriverpass svlogistics_tms_db < fix-admin-permissions.sql
--
-- Option 2: Using local MySQL client
--   mysql -h localhost -u driver -pdriverpass svlogistics_tms_db < fix-admin-permissions.sql
--
-- Option 3: Copy-paste into MySQL Workbench or phpMyAdmin
--
-- After running, verify by logging in as admin user and accessing driver management.
