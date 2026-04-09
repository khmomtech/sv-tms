-- Migration: svlogistics_tms_db_old -> svlogistics_tms_db
-- Scope: customers, customer_addresses (from old order_addresses + customer_addresses), items
-- Date: 2026-03-04

SET @src_db = 'svlogistics_tms_db_old';
SET @dst_db = 'svlogistics_tms_db';
USE svlogistics_tms_db;

-- 0) Backup current target tables (data snapshot)
CREATE TABLE IF NOT EXISTS svlogistics_tms_db.customers_bak_20260304 AS
SELECT * FROM svlogistics_tms_db.customers;

CREATE TABLE IF NOT EXISTS svlogistics_tms_db.customer_addresses_bak_20260304 AS
SELECT * FROM svlogistics_tms_db.customer_addresses;

CREATE TABLE IF NOT EXISTS svlogistics_tms_db.items_bak_20260304 AS
SELECT * FROM svlogistics_tms_db.items;

-- 1) CUSTOMERS
-- 1.1 Update existing customers by customer_code
UPDATE svlogistics_tms_db.customers n
JOIN svlogistics_tms_db_old.customers o
  ON n.customer_code COLLATE utf8mb4_unicode_ci = o.customer_code COLLATE utf8mb4_unicode_ci
SET
  n.name = COALESCE(o.name, n.name),
  n.address = COALESCE(o.address, n.address),
  n.email = COALESCE(o.email, n.email),
  n.phone = COALESCE(o.phone, n.phone),
  n.status = COALESCE(o.status, n.status),
  n.type = COALESCE(o.type, n.type),
  n.updated_at = NOW(6);

-- 1.2 Insert missing customers from old DB
INSERT INTO svlogistics_tms_db.customers (
  customer_code, name, address, email, phone, status, type,
  created_at, updated_at
)
SELECT
  o.customer_code,
  o.name,
  o.address,
  o.email,
  o.phone,
  COALESCE(o.status, 'ACTIVE'),
  COALESCE(o.type, 'COMPANY'),
  NOW(6), NOW(6)
FROM svlogistics_tms_db_old.customers o
LEFT JOIN svlogistics_tms_db.customers n
  ON n.customer_code COLLATE utf8mb4_unicode_ci = o.customer_code COLLATE utf8mb4_unicode_ci
WHERE n.id IS NULL;

-- 2) ITEMS
-- Keep existing rows; insert missing item_code from old DB.
-- Map old varchar item_type into current enum when possible.
INSERT INTO svlogistics_tms_db.items (
  item_code, item_name, item_name_kh,
  quantity, size, unit, weight,
  item_type, pallets, pallet_type,
  status, sort_order, created_at, updated_at
)
SELECT
  o.item_code,
  COALESCE(o.item_name, o.item_code),
  o.item_name_kh,
  COALESCE(o.quantity, 0),
  o.size,
  o.unit,
  o.weight,
  CASE
    WHEN UPPER(o.item_type) IN (
      'AUTOPARTS','BEVERAGE','CLOTHING','CONSUMER_GOODS','DOCUMENT',
      'ELECTRONICS','FRAGILE','FURNITURE','HEAVY_EQUIPMENT','OTHERS',
      'PERISHABLE','PHARMACEUTICAL'
    ) THEN UPPER(o.item_type)
    ELSE NULL
  END,
  o.pallets,
  o.pallet_type,
  COALESCE(o.status, 1),
  o.sort_order,
  COALESCE(o.created_at, NOW(6)),
  COALESCE(o.updated_at, NOW(6))
FROM svlogistics_tms_db_old.items o
LEFT JOIN svlogistics_tms_db.items n
  ON n.item_code COLLATE utf8mb4_unicode_ci = o.item_code COLLATE utf8mb4_unicode_ci
WHERE n.id IS NULL;

-- 3) CUSTOMER ADDRESSES
-- Build unified source from old.order_addresses + old.customer_addresses
DROP TEMPORARY TABLE IF EXISTS tmp_old_addresses;
CREATE TEMPORARY TABLE tmp_old_addresses AS
SELECT
  customer_id,
  type,
  name,
  country,
  city,
  address,
  latitude,
  longitude,
  NULL AS postcode,
  NULL AS scheduled_time
FROM svlogistics_tms_db_old.customer_addresses
UNION ALL
SELECT
  customer_id,
  type,
  name,
  country,
  city,
  address,
  latitude,
  longitude,
  postcode,
  scheduled_time
FROM svlogistics_tms_db_old.order_addresses;

-- Deduplicate by (mapped_customer_id, name, type)
DROP TEMPORARY TABLE IF EXISTS tmp_old_addresses_mapped;
CREATE TEMPORARY TABLE tmp_old_addresses_mapped AS
SELECT
  ncu.id AS mapped_customer_id,
  a.type,
  a.name,
  a.country,
  a.city,
  a.address,
  a.latitude,
  a.longitude,
  a.postcode,
  a.scheduled_time
FROM tmp_old_addresses a
LEFT JOIN svlogistics_tms_db_old.customers ocu
  ON ocu.id = a.customer_id
LEFT JOIN svlogistics_tms_db.customers ncu
  ON ncu.customer_code COLLATE utf8mb4_unicode_ci = ocu.customer_code COLLATE utf8mb4_unicode_ci;

INSERT INTO svlogistics_tms_db.customer_addresses (
  dtype, customer_id, type, name, country, city, address,
  latitude, longitude, postcode, scheduled_time,
  contact_name, contact_phone
)
SELECT
  'CustomerAddress' AS dtype,
  m.mapped_customer_id,
  m.type,
  m.name,
  m.country,
  m.city,
  m.address,
  m.latitude,
  m.longitude,
  m.postcode,
  m.scheduled_time,
  NULL,
  NULL
FROM (
  SELECT
    mapped_customer_id,
    type,
    name,
    country,
    city,
    address,
    latitude,
    longitude,
    postcode,
    scheduled_time,
    ROW_NUMBER() OVER (
      PARTITION BY IFNULL(mapped_customer_id,-1), IFNULL(name,''), IFNULL(type,'')
      ORDER BY IFNULL(name,''), IFNULL(type,'')
    ) AS rn
  FROM tmp_old_addresses_mapped
  WHERE name IS NOT NULL AND TRIM(name) <> ''
) m
WHERE m.rn = 1
  AND NOT EXISTS (
    SELECT 1
    FROM svlogistics_tms_db.customer_addresses n
    WHERE n.customer_id <=> m.mapped_customer_id
      AND n.name COLLATE utf8mb4_unicode_ci = m.name COLLATE utf8mb4_unicode_ci
      AND IFNULL(n.type, '') COLLATE utf8mb4_unicode_ci = IFNULL(m.type, '') COLLATE utf8mb4_unicode_ci
  );

-- 4) Post-migration checks
SELECT 'customers_total_new' AS metric, COUNT(*) AS value FROM svlogistics_tms_db.customers
UNION ALL
SELECT 'items_total_new', COUNT(*) FROM svlogistics_tms_db.items
UNION ALL
SELECT 'customer_addresses_total_new', COUNT(*) FROM svlogistics_tms_db.customer_addresses;

SELECT 'missing_customers_by_code' AS metric, COUNT(*) AS value
FROM svlogistics_tms_db_old.customers o
LEFT JOIN svlogistics_tms_db.customers n
  ON n.customer_code COLLATE utf8mb4_unicode_ci = o.customer_code COLLATE utf8mb4_unicode_ci
WHERE n.id IS NULL
UNION ALL
SELECT 'missing_items_by_code', COUNT(*)
FROM svlogistics_tms_db_old.items o
LEFT JOIN svlogistics_tms_db.items n
  ON n.item_code COLLATE utf8mb4_unicode_ci = o.item_code COLLATE utf8mb4_unicode_ci
WHERE n.id IS NULL;
