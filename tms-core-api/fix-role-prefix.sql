-- ================================================
-- Fix Spring Security Role Prefix Issue
-- ================================================
-- Spring Security's hasAnyRole() expects roles prefixed with "ROLE_"
-- This script adds the ROLE_ prefix to existing roles

-- Backup current roles (for reference)
SELECT id, name, 'Current roles (before fix)' AS note FROM roles;

-- Update role names to include ROLE_ prefix
UPDATE roles SET name = CONCAT('ROLE_', name) 
WHERE name NOT LIKE 'ROLE_%';

-- Verify the fix
SELECT id, name, 'Updated roles (after fix)' AS note FROM roles;

-- ================================================
-- Expected Result:
-- ================================================
-- ADMIN       → ROLE_ADMIN
-- MANAGER     → ROLE_MANAGER  
-- DRIVER      → ROLE_DRIVER
-- CUSTOMER    → ROLE_CUSTOMER
-- USER        → ROLE_USER
