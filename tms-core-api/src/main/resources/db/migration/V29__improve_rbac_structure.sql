-- =========================================
-- V29: Improve RBAC (Role-Based Access Control) Structure
-- =========================================
-- This migration removes unused fields and tables to simplify the permission model.
-- All permissions should be granted through roles, not directly to users.
-- =========================================

-- Drop the user_permissions table (unused - 0 records)
-- All permissions should be assigned through roles for better maintainability
DROP TABLE IF EXISTS user_permissions;

-- Remove the redundant 'permissions' varchar column from roles table
-- This column stored comma-separated permission strings, which is poor database design
-- The proper many-to-many relationship through role_permissions table should be used instead
ALTER TABLE roles DROP COLUMN IF EXISTS permissions;

-- Add indexes to permissions table for better query performance
CREATE INDEX IF NOT EXISTS idx_permission_resource ON permissions(resource_type);
CREATE INDEX IF NOT EXISTS idx_permission_action ON permissions(action_type);

-- Add length constraints to improve database performance and data integrity
-- These align with the entity definitions
ALTER TABLE users MODIFY username VARCHAR(50) NOT NULL;
ALTER TABLE users MODIFY email VARCHAR(100) NOT NULL;
ALTER TABLE roles MODIFY name VARCHAR(50) NOT NULL;
ALTER TABLE permissions MODIFY name VARCHAR(100) NOT NULL;
ALTER TABLE permissions MODIFY resource_type VARCHAR(50);
ALTER TABLE permissions MODIFY action_type VARCHAR(50);

-- =========================================
-- Benefits of this migration:
-- =========================================
-- 1. Simpler authorization model (permissions only through roles)
-- 2. Better database performance (proper indexes, constrained field lengths)
-- 3. Eliminates redundant/unused data (user_permissions table, roles.permissions column)
-- 4. Follows best practices for RBAC design
-- 5. Reduces JPA complexity (fewer relationships to manage)
-- =========================================
