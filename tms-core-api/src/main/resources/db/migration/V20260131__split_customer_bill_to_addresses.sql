-- Split Bill To addresses from `customer_addresses` into dedicated table `customer_bill_to_addresses`
-- Notes:
-- - This keeps `customer_addresses` for operational locations (pickup/drop/warehouse/depo/etc.)
-- - Existing BILL_TO rows (type LIKE 'BILL%') are migrated and then removed from `customer_addresses`.

CREATE TABLE IF NOT EXISTS customer_bill_to_addresses (
  id BIGINT NOT NULL AUTO_INCREMENT,
  customer_id BIGINT NOT NULL,
  name VARCHAR(255) NULL,
  address VARCHAR(255) NULL,
  city VARCHAR(255) NULL,
  state VARCHAR(255) NULL,
  zip VARCHAR(64) NULL,
  country VARCHAR(255) NULL,
  contact_name VARCHAR(255) NULL,
  contact_phone VARCHAR(255) NULL,
  email VARCHAR(255) NULL,
  tax_id VARCHAR(255) NULL,
  notes TEXT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_customer_bill_to_customer_id (customer_id),
  CONSTRAINT fk_customer_bill_to_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE
);

-- Migrate existing BILL_TO-type rows from customer_addresses.
INSERT INTO customer_bill_to_addresses (
  customer_id,
  name,
  address,
  city,
  zip,
  country,
  contact_name,
  contact_phone,
  is_primary
)
SELECT
  customer_id,
  name,
  address,
  city,
  postcode,
  country,
  contact_name,
  contact_phone,
  TRUE
FROM customer_addresses
WHERE customer_id IS NOT NULL
  AND (UPPER(type) LIKE 'BILL%');

-- Remove migrated BILL_TO rows from customer_addresses to avoid duplicates in UI.
DELETE FROM customer_addresses
WHERE customer_id IS NOT NULL
  AND (UPPER(type) LIKE 'BILL%');

