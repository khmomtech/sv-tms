-- Add contact_name and contact_phone columns to customer_addresses
ALTER TABLE customer_addresses
  ADD COLUMN contact_name VARCHAR(255),
  ADD COLUMN contact_phone VARCHAR(255);
