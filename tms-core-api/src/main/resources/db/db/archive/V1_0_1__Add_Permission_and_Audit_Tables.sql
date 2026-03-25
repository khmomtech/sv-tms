-- Add description and permissions columns to roles table
ALTER TABLE roles 
ADD COLUMN description VARCHAR(500) NULL,
ADD COLUMN permissions VARCHAR(1000) NULL;

-- Create permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500) NULL,
    resource_type VARCHAR(255) NULL,
    action_type VARCHAR(255) NULL
);

-- Create role_permissions table for many-to-many relationship
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- Add user_permissions table for many-to-many relationship
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- Create audit_trails table
CREATE TABLE IF NOT EXISTS audit_trails (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    username VARCHAR(255) NULL,
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(255) NULL,
    resource_id BIGINT NULL,
    resource_name VARCHAR(255) NULL,
    timestamp DATETIME NOT NULL,
    details TEXT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(500) NULL
);

-- Insert default permissions
INSERT INTO permissions (name, description, resource_type, action_type) VALUES
('user:create', 'Create users', 'user', 'create'),
('user:read', 'Read users', 'user', 'read'),
('user:update', 'Update users', 'user', 'update'),
('user:delete', 'Delete users', 'user', 'delete'),
('role:create', 'Create roles', 'role', 'create'),
('role:read', 'Read roles', 'role', 'read'),
('role:update', 'Update roles', 'role', 'update'),
('role:delete', 'Delete roles', 'role', 'delete'),
('permission:create', 'Create permissions', 'permission', 'create'),
('permission:read', 'Read permissions', 'permission', 'read'),
('permission:update', 'Update permissions', 'permission', 'update'),
('permission:delete', 'Delete permissions', 'permission', 'delete'),
('audit:read', 'Read audit trails', 'audit', 'read');

-- Insert default roles with permissions
-- Admin role gets all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'ADMIN';

-- Manager role gets user, role, and permission read permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'MANAGER' 
AND p.name IN ('user:read', 'role:read', 'permission:read');

-- Driver role gets only user read permission
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'DRIVER' 
AND p.name = 'user:read';