Production migration runbook — drivers & vehicles merge

Goal
  - Apply idempotent upserts for legacy drivers and vehicles into the target production database with minimal downtime and a reliable rollback path.

Preconditions
  - You MUST have an up-to-date full backup of production and the migration SQL files reviewed and tested on staging and dev.
  - Ensure all migration files are generated as per-row upserts (single-row INSERT ... ON DUPLICATE KEY UPDATE) and validated.
  - Confirm maintenance window and notify stakeholders.

Backup step (mandatory)
  - Run on the production host (example using docker container):
    docker exec -i <prod-mysql-container> mysqldump -uroot -p<rootpass> --default-character-set=utf8mb4 --single-transaction --routines --triggers --events <prod_db> > /backups/prod_full_$(date +%s).sql
  - Verify backup file size and exit status. Copy backup off-host to a safe storage.

Staging checklist (already required before prod)
  - Migrations applied to staging and verified.
  - Verify referential integrity: no orphaned FK rows created.
  - Smoke tests: admin login, list drivers/vehicles UI, sample driver detail pages.

Migration steps (production)
  1. Take production DB backup (above).
  2. Put the application into maintenance mode (if applicable) or reduce write activity.
  3. Optionally: create per-table backups/exports for quick rollback (drivers, vehicles):
       mysqldump -uroot -p<root> --default-character-set=utf8mb4 --single-transaction <prod_db> drivers vehicles > backups/prod_drivers_vehicles_$(date +%s).sql
  4. Apply the per-row upsert SQL files in a transaction where possible. Example (mysql client):
       mysql -uroot -p<root> <prod_db> -e "SET AUTOCOMMIT=0; START TRANSACTION; SOURCE /path/to/scripts/merge_legacy_drivers_per_row.sql; SOURCE /path/to/scripts/merge_legacy_vehicles_per_row.sql; COMMIT; SET AUTOCOMMIT=1;"
     - If the files are large, consider applying them in batches (by id ranges) and verify between batches.

Verification
  - Row counts: Compare expected counts with SELECT COUNT(*) FROM drivers; and vehicles.
  - Referential integrity: SELECT d.id FROM drivers d LEFT JOIN employees e ON d.employee_id = e.id WHERE d.employee_id IS NOT NULL AND e.id IS NULL LIMIT 10;
  - Random sample: SELECT id, name, first_name, last_name FROM drivers ORDER BY id DESC LIMIT 20; (inspect Khmer text visually)
  - Application smoke tests: admin login, driver list page, driver details pages, search by Khmer names.

Rollback (if needed)
  - If serious issues found, restore from the full backup: (ensure downtime)
      - Stop application services.
      - Restore database: docker exec -i <prod-mysql-container> sh -c 'gunzip < /backups/prod_full_...sql.gz | mysql -uroot -p<root> <prod_db' (adjust as needed)
    - Or, if you took per-table dumps before changes, restore only affected tables.

Post-migration cleanup
  - Remove any temporary backup tables or _backup columns if you created them and have validated data.
  - Re-enable normal operations and monitor for errors.

Notes and cautions
  - Never use FOREIGN_KEY_CHECKS=0 in production unless you fully understand and accept the integrity implications.
  - Test the exact commands you plan to run on a staging snapshot first.
  - Keep a documented sign-off from the relevant stakeholders after verification.
