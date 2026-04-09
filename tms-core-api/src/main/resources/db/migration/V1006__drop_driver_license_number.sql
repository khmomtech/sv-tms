-- Drop the license_number column and associated index from drivers table
-- Review and run in staging before production

SET FOREIGN_KEY_CHECKS=0;

-- drop index if exists (MySQL)
ALTER TABLE drivers DROP INDEX idx_driver_license;

-- drop the column
ALTER TABLE drivers DROP COLUMN license_number;

SET FOREIGN_KEY_CHECKS=1;
