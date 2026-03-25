#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT=/opt/sv-tms
COMPOSE_FILE=${COMPOSE_FILE:-$STACK_ROOT/infra/docker-compose.prod.yml}
ENV_FILE=${ENV_FILE:-$STACK_ROOT/infra/.env}
BACKUP_ROOT=${1:-${BACKUP_ROOT:-/opt/sv-tms/backups}}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$BACKUP_ROOT/$TIMESTAMP"
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-14}

mkdir -p "$RUN_DIR"

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

sha256_file() {
  local path=$1
  sha256sum "$path" | awk '{print $1}'
}

echo "Creating backup in $RUN_DIR"

compose exec -T mysql sh -c \
  "mysqldump --single-transaction --set-gtid-purged=OFF --routines --events --triggers -u${MYSQL_USER} -p'${MYSQL_PASSWORD}' ${MYSQL_DATABASE}" \
  | gzip -c > "$RUN_DIR/mysql-${MYSQL_DATABASE}.sql.gz"

compose exec -T postgres sh -c \
  "PGPASSWORD='${TELEMATICS_POSTGRES_PASSWORD}' pg_dump -U '${TELEMATICS_POSTGRES_USER}' -d '${TELEMATICS_POSTGRES_DB}' -Fc" \
  > "$RUN_DIR/postgres-${TELEMATICS_POSTGRES_DB}.dump"

compose exec -T mongo sh -c \
  "rm -rf /tmp/mongo-backup && mkdir -p /tmp/mongo-backup && mongodump --db '${MONGO_DATABASE}' --archive=/tmp/mongo-backup/${MONGO_DATABASE}.archive.gz --gzip" \
  >/dev/null
compose cp mongo:/tmp/mongo-backup/. "$RUN_DIR/mongo"

tar -C "$DATA_ROOT" -czf "$RUN_DIR/uploads.tar.gz" uploads
tar -C "$DATA_ROOT" -czf "$RUN_DIR/telematics-spool.tar.gz" telematics-spool
tar -C "$DATA_ROOT" -czf "$RUN_DIR/message-api.tar.gz" message-api
tar -C "$DATA_ROOT" -czf "$RUN_DIR/redis.tar.gz" redis

cat > "$RUN_DIR/manifest.txt" <<EOF
created_at=$TIMESTAMP
mysql_file=mysql-${MYSQL_DATABASE}.sql.gz
mysql_sha256=$(sha256_file "$RUN_DIR/mysql-${MYSQL_DATABASE}.sql.gz")
postgres_file=postgres-${TELEMATICS_POSTGRES_DB}.dump
postgres_sha256=$(sha256_file "$RUN_DIR/postgres-${TELEMATICS_POSTGRES_DB}.dump")
mongo_archive=mongo/${MONGO_DATABASE}.archive.gz
mongo_sha256=$(sha256_file "$RUN_DIR/mongo/${MONGO_DATABASE}.archive.gz")
uploads_file=uploads.tar.gz
uploads_sha256=$(sha256_file "$RUN_DIR/uploads.tar.gz")
telematics_spool_file=telematics-spool.tar.gz
telematics_spool_sha256=$(sha256_file "$RUN_DIR/telematics-spool.tar.gz")
message_api_file=message-api.tar.gz
message_api_sha256=$(sha256_file "$RUN_DIR/message-api.tar.gz")
redis_file=redis.tar.gz
redis_sha256=$(sha256_file "$RUN_DIR/redis.tar.gz")
EOF

echo "Backup completed:"
ls -lh "$RUN_DIR"

find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$BACKUP_RETENTION_DAYS" -print -exec rm -rf {} +
