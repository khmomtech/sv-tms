-- Add ID card expiry date to drivers
ALTER TABLE drivers
  ADD COLUMN id_card_expiry DATE NULL AFTER license_class;
