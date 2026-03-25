> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Data Import & Migration Handbook

A focused, step-by-step guide to import seed data and execute migrations safely across SV‑TMS environments.

## Scope

- Covers local dev, staging, and production imports
- Uses CSV templates and SQL scripts under `data/import/`
- Ensures referential integrity, idempotency, and safe rollback

## Prerequisites

- MySQL 8 reachable as `svlogistics_tms`
- Backend reachable for OpenAPI export (optional)
- Validated CSV templates (see [data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md](data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md))
- Sufficient DB user permissions: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `LOAD DATA`, `LOCK TABLES`
- For staging/prod: maintenance window and database backup in place

## Environments

- Dev: via Docker Compose — see [docker-compose.dev.yml](docker-compose.dev.yml)
- Test/CI: use [docker-compose.test.yml](docker-compose.test.yml)
- Staging/Prod: your managed MySQL instance; confirm connection and backups

## Files & Templates

Key CSV templates:
- Customers: [data/import/customers_import.csv](data/import/customers_import.csv)
- Customer Addresses: [data/import/customer_addresses_import.csv](data/import/customer_addresses_import.csv)
- Drivers: [data/import/drivers_import.csv](data/import/drivers_import.csv)
- Vehicles: [data/import/vehicles_import.csv](data/import/vehicles_import.csv)
- Assignments: [data/import/assignments_import.csv](data/import/assignments_import.csv)
- Items: [data/import/items_import.csv](data/import/items_import.csv)
- Zones: [data/import/zones_import.csv](data/import/zones_import.csv)
- Transport Orders: [data/import/transport_orders_import.csv](data/import/transport_orders_import.csv)
- Dispatches: [data/import/dispatches_import.csv](data/import/dispatches_import.csv)

SQL scripts:
- All-in-one: [data/import/migration_complete_v3.sql](data/import/migration_complete_v3.sql)
- Sequence:
  - [data/import/migration_customers.sql](data/import/migration_customers.sql)
  - [data/import/migration_import_v2.sql](data/import/migration_import_v2.sql)
  - [data/import/migration_items_zones.sql](data/import/migration_items_zones.sql)
  - [data/import/migration_orders.sql](data/import/migration_orders.sql)
  - [data/import/migration_dispatches.sql](data/import/migration_dispatches.sql)

## Pre-Import Validation

Run these checks to ensure natural keys and formats match across templates.

Customer code consistency:
```bash
awk -F',' 'NR>1 {print $1}' data/import/customers_import.csv | sort > /tmp/customers_codes.txt
awk -F',' 'NR>1 {print $2}' data/import/transport_orders_import.csv | sort > /tmp/orders_customer_codes.txt
diff -u /tmp/customers_codes.txt /tmp/orders_customer_codes.txt || echo "Differences detected"
```

Driver phone consistency:
```bash
awk -F',' 'NR>1 {print $3}' data/import/drivers_import.csv | sort > /tmp/drivers_phones.txt
awk -F',' 'NR>1 {print $3}' data/import/dispatches_import.csv | sort > /tmp/dispatches_phones.txt
diff -u /tmp/drivers_phones.txt /tmp/dispatches_phones.txt || echo "Differences detected"
```

Vehicle plate uniqueness and consistency:
```bash
awk -F',' 'NR>1 {print $1}' data/import/vehicles_import.csv | sort | uniq -d && echo "Duplicates exist" || echo "No duplicates"
awk -F',' 'NR>1 {print $4}' data/import/dispatches_import.csv | sort > /tmp/dispatches_plates.txt
awk -F',' 'NR>1 {print $2}' data/import/assignments_import.csv | sort > /tmp/assignments_plates.txt
awk -F',' 'NR>1 {print $1}' data/import/vehicles_import.csv | sort > /tmp/vehicles_plates.txt
diff -u /tmp/vehicles_plates.txt /tmp/dispatches_plates.txt || echo "Dispatches reference unknown plates"
diff -u /tmp/vehicles_plates.txt /tmp/assignments_plates.txt || echo "Assignments reference unknown plates"
```

## Import Execution

All-in-one (recommended after validation):
```bash
mysql -u root -p svlogistics_tms < data/import/migration_complete_v3.sql
```

Sequential (for step-by-step control):
```bash
mysql -u root -p svlogistics_tms < data/import/migration_customers.sql
mysql -u root -p svlogistics_tms < data/import/migration_import_v2.sql
mysql -u root -p svlogistics_tms < data/import/migration_items_zones.sql
mysql -u root -p svlogistics_tms < data/import/migration_orders.sql
mysql -u root -p svlogistics_tms < data/import/migration_dispatches.sql
```

Dev/Test via Docker Compose (integration tests):
```bash
docker compose -f docker-compose.test.yml up -d
# Run backend tests against test DB
cd tms-backend && ./mvnw verify
```

## Post-Import Verification

Orphan checks (should all be 0):
```sql
SELECT COUNT(*) AS orders_without_customers
FROM transport_orders o LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL;

SELECT COUNT(*) AS dispatches_without_orders
FROM dispatches d LEFT JOIN transport_orders o ON d.order_id = o.id
WHERE o.id IS NULL;

SELECT COUNT(*) AS dispatches_without_drivers
FROM dispatches d LEFT JOIN drivers dr ON d.driver_id = dr.id
WHERE dr.id IS NULL;

SELECT COUNT(*) AS dispatches_without_vehicles
FROM dispatches d LEFT JOIN vehicles v ON d.vehicle_id = v.id
WHERE v.id IS NULL;

SELECT COUNT(*) AS permanent_assignments_without_drivers
FROM permanent_assignments pa LEFT JOIN drivers d ON pa.driver_id = d.id
WHERE d.id IS NULL;

SELECT COUNT(*) AS permanent_assignments_without_vehicles
FROM permanent_assignments pa LEFT JOIN vehicles v ON pa.vehicle_id = v.id
WHERE v.id IS NULL;
```

Record counts (expected baseline: 10 each in seed data):
```sql
SELECT 'customers' AS t, COUNT(*) FROM customers
UNION ALL SELECT 'customer_addresses', COUNT(*) FROM customer_addresses
UNION ALL SELECT 'drivers', COUNT(*) FROM drivers
UNION ALL SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL SELECT 'permanent_assignments', COUNT(*) FROM permanent_assignments
UNION ALL SELECT 'items', COUNT(*) FROM items
UNION ALL SELECT 'zones', COUNT(*) FROM zones
UNION ALL SELECT 'transport_orders', COUNT(*) FROM transport_orders
UNION ALL SELECT 'dispatches', COUNT(*) FROM dispatches;
```

## Rollback & Re-Run Safety

- Always take a backup before import:
```bash
mysqldump -u root -p svlogistics_tms > /backups/svlogistics_tms_$(date +%F_%H%M).sql
```
- If import fails mid-way, prefer restoring from backup for consistency across tables.
- For re-runs, ensure scripts use either `REPLACE INTO` or deduplication logic, or TRUNCATE relevant staging tables prior to re-import.
- Avoid partial manual deletes without understanding FK constraints.

## Idempotency Guidelines

- Natural keys must be stable: `customer_code`, `phone`, `license_plate`, `order_code`, `dispatch_code`.
- Use `ON DUPLICATE KEY UPDATE` or `REPLACE` behavior in scripts (where applicable) to avoid duplicates.
- Maintain a migration ledger table to record executed script versions and timestamps (optional best practice).

## Troubleshooting

- Duplicate key errors: check [data/import/vehicles_import.csv](data/import/vehicles_import.csv) for plate uniqueness and [data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md](data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md) for resolved duplicates.
- FK constraint failures: verify templates reference existing natural keys; re-run Pre-Import Validation.
- CORS or frontend API issues in dev: start Angular via `npm start` proxy (see [tms-frontend](tms-frontend)) and avoid hardcoded `http://localhost:8080`.
- Backend mapper/DTO changes: run `./mvnw clean package` to regenerate Lombok/MapStruct outputs.

## References & Runbooks

- Execution readiness guide: [MIGRATION_EXECUTION_READY.md](MIGRATION_EXECUTION_READY.md)
- Completed import status: [DATA_IMPORT_COMPLETE_READY.md](DATA_IMPORT_COMPLETE_READY.md)
- Template fixes & validations: [data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md](data/import/IMPORT_TEMPLATES_IMPROVEMENTS.md)
- Backend/Angular debug: [BACKEND_ANGULAR_DEBUG_GUIDE.md](BACKEND_ANGULAR_DEBUG_GUIDE.md)

## Recommended Workflow (Staging → Prod)

1. Validate templates locally with Pre-Import Validation.
2. Execute import on staging using the sequential scripts.
3. Run Post-Import Verification on staging; fix any discrepancies.
4. Take production backup; schedule maintenance window.
5. Execute all-in-one import on production.
6. Run Post-Import Verification on production and smoke test API/UI.

## Next Actions

- Run Pre-Import Validation commands now to confirm integrity.
- Choose all-in-one or sequential import flow based on environment.
- Verify and, if needed, prepare a DB backup for rollback safety.
