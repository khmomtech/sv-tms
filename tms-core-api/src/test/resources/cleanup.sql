-- Clean up test data in reverse order to avoid foreign key constraints
DELETE FROM user_roles WHERE user_id IN (1, 2);
DELETE FROM employees WHERE user_id IN (1, 2);
DELETE FROM order_stops WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2));
DELETE FROM order_items WHERE order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2));
DELETE FROM dispatch_status_history WHERE dispatch_id IN (SELECT id FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2)));
DELETE FROM unload_proof_images WHERE unload_proof_id IN (SELECT id FROM unload_proof WHERE dispatch_id IN (SELECT id FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2))));
DELETE FROM unload_proof WHERE dispatch_id IN (SELECT id FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2)));
DELETE FROM load_proof_images WHERE load_proof_id IN (SELECT id FROM load_proof WHERE dispatch_id IN (SELECT id FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2))));
DELETE FROM load_proof WHERE dispatch_id IN (SELECT id FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2)));
DELETE FROM dispatches WHERE transport_order_id IN (SELECT id FROM transport_orders WHERE created_by IN (1, 2));
DELETE FROM transport_orders WHERE created_by IN (1, 2);
DELETE FROM users WHERE id IN (1, 2);
DELETE FROM user_roles WHERE role_id IN (1, 2, 3, 4, 5, 6);
DELETE FROM role_permissions WHERE role_id IN (1, 2, 3, 4, 5, 6);
DELETE FROM role_permissions WHERE permission_id IN (1, 2);
DELETE FROM permissions WHERE id IN (1, 2);
DELETE FROM roles WHERE id IN (1, 2, 3, 4, 5, 6);