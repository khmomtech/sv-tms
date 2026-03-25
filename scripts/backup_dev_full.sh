#!/usr/bin/env bash
# Create a full dev database backup using mysqldump with utf8mb4 charset
# Usage:
#   ./scripts/backup_dev_full.sh <container-name> <db> <user> <password> <out-file>
# Example:
#   ./scripts/backup_dev_full.sh svtms-mysql driverapp root rootpass backups/dev_full_$(date +%s).sql

set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <mysql-container> <database> <user> <password> <out-file>"
  exit 2
fi

CONTAINER="$1"
DB="$2"
USER="$3"
PASS="$4"
OUT="$5"

echo "Creating backup of $DB from container $CONTAINER -> $OUT"

# Use --default-character-set=utf8mb4 to ensure dumps preserve utf8mb4 bytes.
# Use --single-transaction for InnoDB consistent snapshot (no locks).
docker exec -i "$CONTAINER" mysqldump -u"$USER" -p"$PASS" --default-character-set=utf8mb4 --single-transaction --routines --triggers --events "$DB" > "$OUT"

echo "Backup complete: $OUT"
