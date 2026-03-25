#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT=/opt/sv-tms
COMPOSE_FILE=${COMPOSE_FILE:-$STACK_ROOT/infra/docker-compose.prod.yml}
ENV_FILE=${ENV_FILE:-$STACK_ROOT/infra/.env}
BACKUP_DIR=${1:-}
BACKUP_ROOT=${BACKUP_ROOT:-/opt/sv-tms/backups}

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)
fi

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
  echo "Backup directory not found" >&2
  exit 2
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-svlogistics_tms_db}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-rootpass}
TELEMATICS_POSTGRES_DB=${TELEMATICS_POSTGRES_DB:-svlogistics_telematics}
TELEMATICS_POSTGRES_USER=${TELEMATICS_POSTGRES_USER:-tele_user}
TELEMATICS_POSTGRES_PASSWORD=${TELEMATICS_POSTGRES_PASSWORD:-telepass}
MONGO_DATABASE=${MONGO_DATABASE:-svlogistics_tms_db}
DATA_ROOT=${DATA_ROOT:-/srv/svtms}

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

echo "Restoring from $BACKUP_DIR"

compose stop api-gateway admin-web-ui core-api auth-api driver-app-api telematics-api safety-api message-api || true

gunzip -c "$BACKUP_DIR/mysql-${MYSQL_DATABASE}.sql.gz" \
  | compose exec -T mysql sh -c "mysql -u${MYSQL_USER} -p'${MYSQL_PASSWORD}' ${MYSQL_DATABASE}"

cat "$BACKUP_DIR/postgres-${TELEMATICS_POSTGRES_DB}.dump" \
  | compose exec -T postgres sh -c "PGPASSWORD='${TELEMATICS_POSTGRES_PASSWORD}' pg_restore -U '${TELEMATICS_POSTGRES_USER}' -d '${TELEMATICS_POSTGRES_DB}' --clean --if-exists --no-owner --no-privileges"

if [[ -f "$BACKUP_DIR/mongo/${MONGO_DATABASE}.archive.gz" ]]; then
  cat "$BACKUP_DIR/mongo/${MONGO_DATABASE}.archive.gz" \
    | compose exec -T mongo sh -c "mongorestore --drop --archive --gzip"
fi

tar -C "$DATA_ROOT" -xzf "$BACKUP_DIR/uploads.tar.gz"
tar -C "$DATA_ROOT" -xzf "$BACKUP_DIR/telematics-spool.tar.gz"
tar -C "$DATA_ROOT" -xzf "$BACKUP_DIR/message-api.tar.gz"
tar -C "$DATA_ROOT" -xzf "$BACKUP_DIR/redis.tar.gz"

compose up -d

echo "Restore completed. Verify with:"
echo "  docker compose --env-file $ENV_FILE -f $COMPOSE_FILE ps"
