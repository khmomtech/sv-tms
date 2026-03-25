-- Clear all order / transport order data and every related dispatch record.
-- Safe for the current mixed schema where:
-- - dispatch data lives in `dispatches`
-- - order data lives in `transport_orders`
-- - legacy `orders` rows may still exist for `shipments`
--
-- WARNING:
-- - This permanently deletes dispatches, proofs, queue/session rows, invoices, status history,
--   route rows, safety rows, and transport orders.
-- - Run only against the database you intend to reset.

USE svlogistics_tms_db;

SET @previous_foreign_key_checks = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_target_transport_orders;
CREATE TEMPORARY TABLE tmp_target_transport_orders (
  id BIGINT PRIMARY KEY
);

INSERT INTO tmp_target_transport_orders (id)
SELECT id
FROM transport_orders;

DROP TEMPORARY TABLE IF EXISTS tmp_target_dispatches;
CREATE TEMPORARY TABLE tmp_target_dispatches (
  id BIGINT PRIMARY KEY
);

INSERT INTO tmp_target_dispatches (id)
SELECT id
FROM dispatches
WHERE transport_order_id IN (SELECT id FROM tmp_target_transport_orders);

DROP TEMPORARY TABLE IF EXISTS tmp_target_load_proof;
CREATE TEMPORARY TABLE tmp_target_load_proof (
  id BIGINT PRIMARY KEY
);

INSERT INTO tmp_target_load_proof (id)
SELECT id
FROM load_proof
WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches);

DROP TEMPORARY TABLE IF EXISTS tmp_target_unload_proof;
CREATE TEMPORARY TABLE tmp_target_unload_proof (
  id BIGINT PRIMARY KEY
);

INSERT INTO tmp_target_unload_proof (id)
SELECT id
FROM unload_proof
WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches);

DROP PROCEDURE IF EXISTS clear_table_if_exists;
DELIMITER $$
CREATE PROCEDURE clear_table_if_exists(IN p_sql TEXT, IN p_table_name VARCHAR(128))
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = p_table_name
  ) THEN
    SET @cleanup_sql = p_sql;
    PREPARE cleanup_stmt FROM @cleanup_sql;
    EXECUTE cleanup_stmt;
    DEALLOCATE PREPARE cleanup_stmt;
  END IF;
END$$
DELIMITER ;

-- Delete proof child rows before proofs.
CALL clear_table_if_exists(
  'DELETE FROM load_proof_images WHERE load_proof_id IN (SELECT id FROM tmp_target_load_proof)',
  'load_proof_images'
);
CALL clear_table_if_exists(
  'DELETE FROM unload_proof_images WHERE unload_proof_id IN (SELECT id FROM tmp_target_unload_proof)',
  'unload_proof_images'
);

-- Dispatch child tables.
CALL clear_table_if_exists(
  'DELETE FROM driver_latest_location WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'driver_latest_location'
);
CALL clear_table_if_exists(
  'DELETE FROM driver_issues WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'driver_issues'
);
CALL clear_table_if_exists(
  'DELETE FROM location_history WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'location_history'
);
CALL clear_table_if_exists(
  'DELETE FROM unload_details WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'unload_details'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_approval_history WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_approval_history'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_approval_sla WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_approval_sla'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_reviews WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_reviews'
);
CALL clear_table_if_exists(
  'DELETE FROM km_validation_log WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'km_validation_log'
);
CALL clear_table_if_exists(
  'DELETE FROM loading_documents WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'loading_documents'
);
CALL clear_table_if_exists(
  'DELETE FROM loading_queue WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'loading_queue'
);
CALL clear_table_if_exists(
  'DELETE FROM loading_sessions WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'loading_sessions'
);
CALL clear_table_if_exists(
  'DELETE FROM pre_entry_safety_check WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'pre_entry_safety_check'
);
CALL clear_table_if_exists(
  'DELETE FROM pre_loading_safety_checks WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'pre_loading_safety_checks'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_items WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_items'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_status_history WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_status_history'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_stops WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_stops'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_route_stops WHERE dispatch_route_id IN (SELECT id FROM dispatch_routes WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches))',
  'dispatch_route_stops'
);
CALL clear_table_if_exists(
  'DELETE FROM dispatch_routes WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatch_routes'
);
CALL clear_table_if_exists(
  'DELETE FROM load_proof WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'load_proof'
);
CALL clear_table_if_exists(
  'DELETE FROM unload_proof WHERE dispatch_id IN (SELECT id FROM tmp_target_dispatches)',
  'unload_proof'
);

-- Core dispatch rows.
CALL clear_table_if_exists(
  'DELETE FROM dispatches WHERE id IN (SELECT id FROM tmp_target_dispatches)',
  'dispatches'
);

-- Transport-order children.
CALL clear_table_if_exists(
  'DELETE FROM invoices WHERE order_id IN (SELECT id FROM tmp_target_transport_orders)',
  'invoices'
);
CALL clear_table_if_exists(
  'DELETE FROM order_status_history WHERE order_id IN (SELECT id FROM tmp_target_transport_orders)',
  'order_status_history'
);
CALL clear_table_if_exists(
  'DELETE FROM order_items WHERE order_id IN (SELECT id FROM tmp_target_transport_orders)',
  'order_items'
);
CALL clear_table_if_exists(
  'DELETE FROM order_stops WHERE transport_order_id IN (SELECT id FROM tmp_target_transport_orders)',
  'order_stops'
);

-- Legacy order-linked tables, if still populated.
CALL clear_table_if_exists(
  'DELETE FROM shipments WHERE order_id IN (SELECT id FROM orders)',
  'shipments'
);

-- Core order rows.
CALL clear_table_if_exists(
  'DELETE FROM transport_orders WHERE id IN (SELECT id FROM tmp_target_transport_orders)',
  'transport_orders'
);
CALL clear_table_if_exists(
  'DELETE FROM orders',
  'orders'
);

DROP PROCEDURE IF EXISTS clear_table_if_exists;

DROP TEMPORARY TABLE IF EXISTS tmp_target_unload_proof;
DROP TEMPORARY TABLE IF EXISTS tmp_target_load_proof;
DROP TEMPORARY TABLE IF EXISTS tmp_target_dispatches;
DROP TEMPORARY TABLE IF EXISTS tmp_target_transport_orders;

SET FOREIGN_KEY_CHECKS = @previous_foreign_key_checks;
