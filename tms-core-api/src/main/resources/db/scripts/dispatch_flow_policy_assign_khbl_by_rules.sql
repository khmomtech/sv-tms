-- Assign existing dispatches to KHBL template by business matching rules
-- Safe to run multiple times.
-- Edit the matching rules in the WHERE clause for your real business logic.

START TRANSACTION;

-- Ensure KHBL template exists
INSERT INTO dispatch_flow_template (code, name, description, active)
SELECT 'KHBL', 'KHBL', 'G-Team control loading flow', TRUE
WHERE NOT EXISTS (SELECT 1 FROM dispatch_flow_template WHERE code = 'KHBL');

-- Optional reset: uncomment if you want all dispatches to GENERAL before KHBL remap
-- UPDATE dispatches SET loading_type_code = 'GENERAL';

-- Preview: how many dispatches match KHBL rules BEFORE update
SELECT COUNT(*) AS khbl_match_before
FROM dispatches d
LEFT JOIN transport_orders o ON o.id = d.transport_order_id
LEFT JOIN customers c ON c.id = COALESCE(d.customer_id, o.customer_id)
LEFT JOIN customer_addresses pa ON pa.id = o.pickup_address_id
LEFT JOIN customer_addresses da ON da.id = o.drop_address_id
WHERE
  UPPER(COALESCE(c.customer_code, '')) IN ('KHBL', 'KHBL')
  OR UPPER(COALESCE(c.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.route_code, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.from_location, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.to_location, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(pa.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(pa.address, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(da.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(da.address, '')) LIKE '%KHBL%'
  -- Example route-based shortcut (edit/remove as needed)
  OR (
    UPPER(COALESCE(d.from_location, '')) LIKE 'KB%'
    AND UPPER(COALESCE(d.to_location, '')) LIKE '%KSV5%'
  );

-- Apply assignment
UPDATE dispatches d
LEFT JOIN transport_orders o ON o.id = d.transport_order_id
LEFT JOIN customers c ON c.id = COALESCE(d.customer_id, o.customer_id)
LEFT JOIN customer_addresses pa ON pa.id = o.pickup_address_id
LEFT JOIN customer_addresses da ON da.id = o.drop_address_id
SET d.loading_type_code = 'KHBL'
WHERE
  UPPER(COALESCE(c.customer_code, '')) IN ('KHBL', 'KHBL')
  OR UPPER(COALESCE(c.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.route_code, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.from_location, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(d.to_location, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(pa.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(pa.address, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(da.name, '')) LIKE '%KHBL%'
  OR UPPER(COALESCE(da.address, '')) LIKE '%KHBL%'
  OR (
    UPPER(COALESCE(d.from_location, '')) LIKE 'KB%'
    AND UPPER(COALESCE(d.to_location, '')) LIKE '%KSV5%'
  );

COMMIT;

-- Verification summary
SELECT loading_type_code, COUNT(*) AS total
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;

SELECT d.id, d.route_code, d.from_location, d.to_location, d.loading_type_code,
       c.customer_code, c.name AS customer_name
FROM dispatches d
LEFT JOIN transport_orders o ON o.id = d.transport_order_id
LEFT JOIN customers c ON c.id = COALESCE(d.customer_id, o.customer_id)
WHERE d.loading_type_code = 'KHBL'
ORDER BY d.id DESC
LIMIT 50;
