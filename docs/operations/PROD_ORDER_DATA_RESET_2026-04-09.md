# Production Order Data Reset - 2026-04-09

Date: 2026-04-09
Target: VPS production MySQL database `svlogistics_tms_db`
Host: `root@207.180.245.156`

## Backup

A full MySQL application-database backup was created before deletion:

- Path: `/opt/sv-tms/backups/manual-20260409-004345/mysql-svlogistics_tms_db.sql.gz`
- SHA-256: `6d13e26401acedef7577ec625e02afe4b4a7a22e2e2c65235e42b30fc465c87a`

Note: the standard stack backup script failed because the MySQL app user lacked the tablespace privilege needed by `mysqldump` in that mode. The backup was completed successfully using `mysqldump --no-tablespaces`.

## Source Cleanup Script

The production reset used:

- [scripts/clear_transport_orders.sql](/Users/sotheakh/Documents/develop/sv-tms/scripts/clear_transport_orders.sql)

This script deletes transport orders and dispatch-linked data in FK-safe order.

## Counts Before Cleanup

- `transport_orders`: `372`
- `dispatches`: `372`
- `order_items`: `1024`
- `order_status_history`: `0`
- `invoices`: `0`
- `dispatch_items`: `0`
- `dispatch_status_history`: `137`
- `dispatch_stops`: `0`
- `load_proof`: `0`
- `unload_proof`: `0`
- `location_history`: `0`
- `driver_latest_location`: `35`
- `orders`: `0`

## Counts After Cleanup

- `transport_orders`: `0`
- `dispatches`: `0`
- `order_items`: `0`
- `order_status_history`: `0`
- `invoices`: `0`
- `dispatch_items`: `0`
- `dispatch_status_history`: `0`
- `dispatch_stops`: `0`
- `load_proof`: `0`
- `unload_proof`: `0`
- `location_history`: `0`
- `orders`: `0`

## Related Integrity Checks After Cleanup

- `dispatch_routes`: `0`
- `dispatch_route_stops`: `0`
- `loading_queue`: `0`
- `loading_sessions`: `0`
- `loading_documents`: `0`
- `order_stops`: `0`
- `shipments`: `0`
- `driver_latest_location` with `dispatch_id IS NOT NULL`: `0`

## Remaining Data Not Tied To Orders/Dispatches

These rows were intentionally left because they are not linked to deleted transport orders/dispatches:

- `driver_latest_location`: `35` rows remain, all with `dispatch_id IS NULL`
- `driver_issues`: `1` row remains, standalone:
  - `id=1`
  - `code=INC-2026-0001`
  - `dispatch_id=NULL`
  - `driver_id=30021`
  - `source=DRIVER_APP`
  - `status=OPEN`
  - `title=Mechanical Issue`

## Operational Notes

- The cleanup was executed using MySQL root inside the production MySQL container.
- The app database user had sufficient database privileges, but the root path was used to avoid client/STDIN ambiguity and ensure consistent execution.
- No application code was changed during this production data reset.
