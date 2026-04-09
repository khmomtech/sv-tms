-- ============================================================================
-- SV-TMS Partner Company & Multi-Tenant User System Migration
-- ============================================================================
-- This migration adds complete partner company support and customer login capability
-- Run this after the driver improvements migration
-- ============================================================================

-- Step 1: Create partner_companies table
-- ============================================================================
CREATE TABLE IF NOT EXISTS partner_companies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_code VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique company identifier (e.g., PART-001)',
    company_name VARCHAR(255) NOT NULL COMMENT 'Partner company name',
    business_license VARCHAR(100) UNIQUE COMMENT 'Tax ID or Business Registration Number',
    contact_person VARCHAR(255) COMMENT 'Primary contact person name',
    email VARCHAR(255) NOT NULL COMMENT 'Company email',
    phone VARCHAR(50) NOT NULL COMMENT 'Company phone number',
    address TEXT COMMENT 'Company address',
    partnership_type VARCHAR(30) NOT NULL COMMENT 'DRIVER_FLEET, CUSTOMER_CORPORATE, FULL_SERVICE, etc.',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE or INACTIVE',
    contract_start_date DATE COMMENT 'Partnership contract start date',
    contract_end_date DATE COMMENT 'Partnership contract end date',
    commission_rate DOUBLE COMMENT 'Revenue sharing percentage (0-100)',
    credit_limit DOUBLE COMMENT 'Credit limit for corporate customers',
    notes TEXT COMMENT 'Additional notes about the partner',
    logo_url VARCHAR(500) COMMENT 'URL to company logo',
    website VARCHAR(255) COMMENT 'Company website',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100) COMMENT 'Username who created this record',
    updated_by VARCHAR(100) COMMENT 'Username who last updated this record',
    
    INDEX idx_company_code (company_code),
    INDEX idx_partnership_type (partnership_type),
    INDEX idx_status (status),
    INDEX idx_business_license (business_license)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Partner companies providing drivers, customers, or both';

-- Step 2: Create partner_admins linking table
-- ============================================================================
CREATE TABLE IF NOT EXISTS partner_admins (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT 'FK to users table',
    partner_company_id BIGINT NOT NULL COMMENT 'FK to partner_companies table',
    can_manage_drivers BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Can view/manage drivers',
    can_manage_customers BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Can view/manage customers',
    can_view_reports BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Can view financial reports',
    can_manage_settings BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Can manage company settings',
    is_primary BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Is primary admin for this company',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) COMMENT 'Username who created this assignment',
    
    CONSTRAINT fk_partner_admin_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_partner_admin_company FOREIGN KEY (partner_company_id) REFERENCES partner_companies(id) ON DELETE CASCADE,
    CONSTRAINT uk_user_company UNIQUE (user_id, partner_company_id),
    
    INDEX idx_user_id (user_id),
    INDEX idx_partner_company_id (partner_company_id),
    INDEX idx_is_primary (is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Links users with PARTNER_ADMIN role to their companies';

-- Step 3: Add user_id to customers table (for customer login)
-- ============================================================================
ALTER TABLE customers 
ADD COLUMN user_id BIGINT NULL COMMENT 'Optional login account for customer portal' 
AFTER status;

ALTER TABLE customers 
ADD CONSTRAINT fk_customer_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX idx_customer_user_id ON customers(user_id);

-- Step 4: Add partner_company_id to customers table (for corporate customers)
-- ============================================================================
ALTER TABLE customers 
ADD COLUMN partner_company_id BIGINT NULL COMMENT 'Link to partner company (for corporate customers)' 
AFTER user_id;

ALTER TABLE customers 
ADD CONSTRAINT fk_customer_partner_company 
FOREIGN KEY (partner_company_id) REFERENCES partner_companies(id) ON DELETE SET NULL;

CREATE INDEX idx_customer_partner_company ON customers(partner_company_id);

-- Step 5: Add partner_company_id to drivers table (replace string partner_company)
-- ============================================================================
ALTER TABLE drivers 
ADD COLUMN partner_company_id BIGINT NULL COMMENT 'Link to partner company (replaces partner_company string)' 
AFTER partner_company;

ALTER TABLE drivers 
ADD CONSTRAINT fk_driver_partner_company 
FOREIGN KEY (partner_company_id) REFERENCES partner_companies(id) ON DELETE SET NULL;

CREATE INDEX idx_driver_partner_company ON drivers(partner_company_id);

-- Step 6: Insert PARTNER_ADMIN role into roles table
-- ============================================================================
INSERT IGNORE INTO roles (name, description) 
VALUES ('PARTNER_ADMIN', 'Partner company administrator with limited scope');

-- Step 7: Sample data (optional - remove in production)
-- ============================================================================
-- Sample partner company
INSERT IGNORE INTO partner_companies (
    company_code, 
    company_name, 
    business_license, 
    contact_person, 
    email, 
    phone, 
    address, 
    partnership_type, 
    status, 
    commission_rate,
    created_by
) VALUES (
    'PART-001',
    'Express Logistics Co., Ltd.',
    'TIN-123456789',
    'John Smith',
    'contact@expresslogistics.com',
    '+855-12-345678',
    'Phnom Penh, Cambodia',
    'DRIVER_FLEET',
    'ACTIVE',
    15.0,
    'system'
);

-- ============================================================================
-- Data Migration: Link existing partner drivers to partner companies
-- ============================================================================
-- This is a placeholder - adjust based on your actual data
-- Example: Update drivers with partner_company='ABC' to link to PART-001
-- 
-- UPDATE drivers d
-- JOIN partner_companies pc ON pc.company_code = 'PART-001'
-- SET d.partner_company_id = pc.id
-- WHERE d.is_partner = TRUE 
-- AND d.partner_company = 'ABC';

-- ============================================================================
-- Verification Queries
-- ============================================================================
-- Run these to verify the migration

-- Check partner_companies table
-- SELECT * FROM partner_companies;

-- Check partner_admins table
-- SELECT * FROM partner_admins;

-- Check customers with login accounts
-- SELECT c.id, c.name, c.email, u.username, u.enabled
-- FROM customers c
-- LEFT JOIN users u ON c.user_id = u.id;

-- Check drivers linked to partner companies
-- SELECT d.id, d.name, d.phone, pc.company_name, pc.company_code
-- FROM drivers d
-- LEFT JOIN partner_companies pc ON d.partner_company_id = pc.id
-- WHERE d.is_partner = TRUE;

-- Check users with PARTNER_ADMIN role
-- SELECT u.username, u.email, r.name as role
-- FROM users u
-- JOIN user_roles ur ON u.id = ur.user_id
-- JOIN roles r ON ur.role_id = r.id
-- WHERE r.name = 'PARTNER_ADMIN';

-- ============================================================================
-- Rollback Script (use with caution!)
-- ============================================================================
/*
-- Remove foreign keys first
ALTER TABLE drivers DROP FOREIGN KEY fk_driver_partner_company;
ALTER TABLE customers DROP FOREIGN KEY fk_customer_partner_company;
ALTER TABLE customers DROP FOREIGN KEY fk_customer_user;
ALTER TABLE partner_admins DROP FOREIGN KEY fk_partner_admin_user;
ALTER TABLE partner_admins DROP FOREIGN KEY fk_partner_admin_company;

-- Drop columns
ALTER TABLE drivers DROP COLUMN partner_company_id;
ALTER TABLE customers DROP COLUMN partner_company_id;
ALTER TABLE customers DROP COLUMN user_id;

-- Drop tables
DROP TABLE IF EXISTS partner_admins;
DROP TABLE IF EXISTS partner_companies;

-- Remove role
DELETE FROM user_roles WHERE role_id IN (SELECT id FROM roles WHERE name = 'PARTNER_ADMIN');
DELETE FROM roles WHERE name = 'PARTNER_ADMIN';
*/

-- ============================================================================
-- End of Migration
-- ============================================================================
