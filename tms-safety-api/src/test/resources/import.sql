-- import.sql for tests: only provide portable inserts for objects
-- Hibernate will create schema from entities; avoid DDL here to keep H2 happy.

-- Roles (name field is an ENUM RoleType, insert as STRING values)
INSERT INTO roles (id, name, description) VALUES (1, 'SUPERADMIN', 'Super Administrator');
INSERT INTO roles (id, name, description) VALUES (2, 'ADMIN', 'Administrator');
INSERT INTO roles (id, name, description) VALUES (3, 'DRIVER', 'Driver');
INSERT INTO roles (id, name, description) VALUES (4, 'MANAGER', 'Manager');
INSERT INTO roles (id, name, description) VALUES (5, 'CUSTOMER', 'Customer');
INSERT INTO roles (id, name, description) VALUES (6, 'USER', 'User');

-- Permissions
INSERT INTO permissions (id, name, resource_type, action_type) VALUES (1, 'all_functions', 'Global', 'manage');
INSERT INTO permissions (id, name, resource_type, action_type) VALUES (2, 'driver:manage', 'driver', 'manage');

-- Users (explicit IDs so tests that rely on known user IDs work)
-- Password for 'super123' is '$2a$10$DQ0TcvjWZmnG4F24cYuM7OYLyxSHXefGeOXsxxDozPI6.QR8P8mve'
INSERT INTO users (id, username, password, email, enabled, account_non_expired, account_non_locked, credentials_non_expired) VALUES (1, 'superadmin', '$2a$10$DQ0TcvjWZmnG4F24cYuM7OYLyxSHXefGeOXsxxDozPI6.QR8P8mve', 'superadmin@example.com', true, true, true, true);

-- Password for 'admin123' is '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
INSERT INTO users (id, username, password, email, enabled, account_non_expired, account_non_locked, credentials_non_expired) VALUES (2, 'admin', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@example.com', true, true, true, true);

-- User-Roles
INSERT INTO user_roles (user_id, role_id) VALUES (1, 1);
INSERT INTO user_roles (user_id, role_id) VALUES (1, 2);
INSERT INTO user_roles (user_id, role_id) VALUES (2, 2);

-- Role-Permissions (assign all_functions to SUPERADMIN role)
INSERT INTO role_permissions (role_id, permission_id) VALUES (1, 1);
