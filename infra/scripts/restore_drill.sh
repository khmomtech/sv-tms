#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT=/opt/sv-tms
BACKUP_DIR=${1:-}
BACKUP_ROOT=${BACKUP_ROOT:-/opt/sv-tms/backups}
DRILL_ROOT=${DRILL_ROOT:-/tmp/svtms-restore-drill}

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)
fi

[[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]] || { echo "Backup directory not found" >&2; exit 2; }

mkdir -p "$DRILL_ROOT"
cp "$STACK_ROOT/infra/.env.example" "$DRILL_ROOT/.env"

cat >> "$DRILL_ROOT/.env" <<EOF
DATA_ROOT=$DRILL_ROOT/data
MYSQL_ROOT_PASSWORD=drill-root-pass
MYSQL_DATABASE=svlogistics_tms_db
MYSQL_USER=svtms_app
MYSQL_PASSWORD=drill-app-pass
TELEMATICS_POSTGRES_DB=svlogistics_telematics
TELEMATICS_POSTGRES_USER=telematics_app
TELEMATICS_POSTGRES_PASSWORD=drill-tele-pass
JWT_ACCESS_SECRET=drill-access-secret-32-characters-minimum-0001
JWT_REFRESH_SECRET=drill-refresh-secret-32-characters-minimum-0001
TELEMATICS_INTERNAL_API_KEY=drill-internal-api-key-0001
IMAGE_REGISTRY=local
IMAGE_TAG=latest
APP_CORS_ALLOWED_ORIGINS=http://localhost:4200
APP_WEBSOCKET_ALLOWED_ORIGINS=http://localhost:4200
EOF

mkdir -p "$DRILL_ROOT"/data/{mysql,postgres,mongo,redis,kafka,uploads,uploads-init,telematics-spool,message-api,certs,webroot}

echo "[restore-drill] Verifying backup set"
BACKUP_ROOT="$(dirname "$BACKUP_DIR")" "$STACK_ROOT/infra/scripts/verify_backup.sh" "$BACKUP_DIR"

echo "[restore-drill] Backup verified. Manual restore drill target prepared at $DRILL_ROOT"
echo "[restore-drill] Next steps:"
echo "  1. Review $DRILL_ROOT/.env"
echo "  2. Start a disposable stack with: docker compose --env-file $DRILL_ROOT/.env -f $STACK_ROOT/infra/docker-compose.prod.yml up -d"
echo "  3. Run restore against that environment by overriding ENV_FILE, COMPOSE_FILE, and DATA_ROOT"
