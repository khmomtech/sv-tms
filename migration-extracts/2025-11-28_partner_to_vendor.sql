-- Draft migration plan: Rename Partner* to Vendor* (MySQL)
-- NOTE: Review and adapt to your schema state before executing.
-- Assumptions from codebase:
--   Tables: partner_companies, partner_admins
--   Columns: partner_company_id (FK from partner_admins, drivers, customers, possibly vehicles)
--   Text columns: partner_company (drivers, vehicles) used for legacy display
--   Constraints follow default naming; adjust FK names to match your DB
--
-- Recommended rollout:
--  1) Put app in maintenance; backup DB
--  2) Drop FKs referencing partner_company_id
--  3) Rename tables and columns
--  4) Recreate FKs/indexes
--  5) Validate application; keep compatibility DB views if needed

START TRANSACTION;

-- 1) Drop foreign keys (adjust names to your DB)
-- Partner admins → partner_companies
ALTER TABLE partner_admins DROP FOREIGN KEY fk_partner_admins_partner_company_id;
ALTER TABLE partner_admins DROP INDEX uq_partner_admins_user_partner_company;

-- Drivers → partner_companies
ALTER TABLE drivers DROP FOREIGN KEY fk_drivers_partner_company_id;

-- Customers → partner_companies
ALTER TABLE customers DROP FOREIGN KEY fk_customers_partner_company_id;

-- Vehicles → partner_companies (if exists)
ALTER TABLE vehicles DROP FOREIGN KEY fk_vehicles_partner_company_id;

-- 2) Rename tables
RENAME TABLE partner_companies TO vendor_companies;
RENAME TABLE partner_admins    TO vendor_admins;

-- 3) Rename columns referencing partner_company_id
ALTER TABLE vendor_admins CHANGE COLUMN partner_company_id vendor_company_id BIGINT NOT NULL;
ALTER TABLE drivers      CHANGE COLUMN partner_company_id vendor_company_id BIGINT NULL;
ALTER TABLE customers    CHANGE COLUMN partner_company_id vendor_company_id BIGINT NULL;
ALTER TABLE vehicles     CHANGE COLUMN partner_company_id vendor_company_id BIGINT NULL;

-- 3a) Optional: rename legacy text columns for consistency
ALTER TABLE drivers  CHANGE COLUMN partner_company  vendor_company  VARCHAR(150) NULL;
ALTER TABLE vehicles CHANGE COLUMN partner_company  vendor_company  VARCHAR(150) NULL;

-- 4) Recreate unique/indexes
ALTER TABLE vendor_admins
  ADD CONSTRAINT uq_vendor_admins_user_vendor_company UNIQUE (user_id, vendor_company_id);

-- 5) Recreate foreign keys to vendor_companies.id
ALTER TABLE vendor_admins
  ADD CONSTRAINT fk_vendor_admins_vendor_company_id
  FOREIGN KEY (vendor_company_id) REFERENCES vendor_companies(id);

ALTER TABLE drivers
  ADD CONSTRAINT fk_drivers_vendor_company_id
  FOREIGN KEY (vendor_company_id) REFERENCES vendor_companies(id);

ALTER TABLE customers
  ADD CONSTRAINT fk_customers_vendor_company_id
  FOREIGN KEY (vendor_company_id) REFERENCES vendor_companies(id);

ALTER TABLE vehicles
  ADD CONSTRAINT fk_vehicles_vendor_company_id
  FOREIGN KEY (vendor_company_id) REFERENCES vendor_companies(id);

COMMIT;

-- Compatibility layer (optional): create views to keep old names temporarily
-- DROP VIEW IF EXISTS partner_companies;
-- CREATE VIEW partner_companies AS SELECT * FROM vendor_companies;
-- Adjust permissions as needed.
