-- ============================================================================
-- V524: Seed helper rows for SV Standard maintenance extension tables.
-- This is safe to run in environments with existing partner_companies/parts_master.
-- ============================================================================

-- Seed vendor extension rows for existing partner companies (idempotent).
INSERT IGNORE INTO vendors (id)
SELECT pc.id FROM partner_companies pc;

-- Seed parts extension rows for existing parts_master (idempotent).
INSERT IGNORE INTO parts (id)
SELECT pm.id FROM parts_master pm;
