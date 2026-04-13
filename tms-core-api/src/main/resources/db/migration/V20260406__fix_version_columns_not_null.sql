-- Fix @Version columns: coerce NULL → 0 then add NOT NULL + DEFAULT constraint
-- Affects: dispatches.version, transport_orders.version, vehicle_drivers.version

-- dispatches
UPDATE dispatches SET version = 0 WHERE version IS NULL;
ALTER TABLE dispatches MODIFY COLUMN version BIGINT NOT NULL DEFAULT 0;

-- transport_orders
UPDATE transport_orders SET version = 0 WHERE version IS NULL;
ALTER TABLE transport_orders MODIFY COLUMN version INT NOT NULL DEFAULT 0;

-- vehicle_drivers
UPDATE vehicle_drivers SET version = 0 WHERE version IS NULL;
ALTER TABLE vehicle_drivers MODIFY COLUMN version BIGINT NOT NULL DEFAULT 0;
