#!/usr/bin/env bash
set -euo pipefail
# Simple DB backup helper. Tries Docker container first, then local mysqldump.
BACKUP_DIR="/opt/sv-tms/backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%F_%H%M%S)
echo "Backup dir: $BACKUP_DIR"
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q mysql; then
  CONTAINER=$(docker ps --format '{{.Names}}' | grep mysql | head -n1)
  echo "Found mysql container: $CONTAINER"
  docker exec "$CONTAINER" /usr/bin/mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD" > "$BACKUP_DIR/mysql_all_$TIMESTAMP.sql"
  echo "Saved $BACKUP_DIR/mysql_all_$TIMESTAMP.sql"
else
  echo "No mysql docker container found; attempting local mysqldump"
  mysqldump --all-databases > "$BACKUP_DIR/mysql_all_$TIMESTAMP.sql"
  echo "Saved $BACKUP_DIR/mysql_all_$TIMESTAMP.sql"
fi
