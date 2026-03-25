-- Rename table `order_addresses` to `customer_addresses` (safe migration)
-- This preserves existing data and updates references at DB level.
RENAME TABLE order_addresses TO customer_addresses;
