-- Add contact_name column to order_stops to persist per-stop contact person
ALTER TABLE order_stops
  ADD COLUMN contact_name VARCHAR(255) NULL;
