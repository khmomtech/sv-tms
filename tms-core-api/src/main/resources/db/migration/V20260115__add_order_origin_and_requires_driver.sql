-- Add origin, requires_driver and source_reference to transport_orders
ALTER TABLE transport_orders
  ADD COLUMN origin VARCHAR(50) DEFAULT 'BOOKING',
  ADD COLUMN requires_driver BOOLEAN DEFAULT TRUE,
  ADD COLUMN source_reference VARCHAR(128);

CREATE INDEX IF NOT EXISTS idx_transport_orders_source_reference ON transport_orders (source_reference);
