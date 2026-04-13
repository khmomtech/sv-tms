#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STACK_ROOT=${STACK_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}
SOURCE_ROOT=${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}
COMPOSE_FILE=${COMPOSE_FILE:-$STACK_ROOT/docker-compose.prod.yml}
ENV_FILE=${ENV_FILE:-$STACK_ROOT/.env}

fail() {
  echo "[preflight] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

check_duplicate_flyway_versions() {
  local migration_dir=$1
  [[ -d "$migration_dir" ]] || return 0

  local duplicates
  duplicates=$(
    find "$migration_dir" -maxdepth 1 -type f -name 'V*__*.sql' -print \
      | sed 's#^.*/##' \
      | awk -F'__' '{print $1}' \
      | sort \
      | uniq -d
  )

  [[ -z "$duplicates" ]] || fail "Duplicate Flyway versions in $migration_dir: ${duplicates//$'\n'/, }"
}

require_cmd docker
require_cmd curl
require_cmd sha256sum

[[ -f "$ENV_FILE" ]] || fail "Missing env file: $ENV_FILE"
[[ -f "$COMPOSE_FILE" ]] || fail "Missing compose file: $COMPOSE_FILE"

set -a
. "$ENV_FILE"
set +a

for var in DOMAIN EMAIL DATA_ROOT MYSQL_ROOT_PASSWORD MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD TELEMATICS_POSTGRES_DB TELEMATICS_POSTGRES_USER TELEMATICS_POSTGRES_PASSWORD JWT_ACCESS_SECRET JWT_REFRESH_SECRET TELEMATICS_INTERNAL_API_KEY APP_CORS_ALLOWED_ORIGINS APP_WEBSOCKET_ALLOWED_ORIGINS; do
  [[ -n "${!var:-}" ]] || fail "Required env var is empty: $var"
done

[[ ${#JWT_ACCESS_SECRET} -ge 32 ]] || fail "JWT_ACCESS_SECRET must be at least 32 chars"
[[ ${#JWT_REFRESH_SECRET} -ge 32 ]] || fail "JWT_REFRESH_SECRET must be at least 32 chars"
[[ ${#TELEMATICS_INTERNAL_API_KEY} -ge 24 ]] || fail "TELEMATICS_INTERNAL_API_KEY should be long and random"

mkdir -p "$DATA_ROOT"/{mysql,postgres,mongo,redis,uploads,uploads-init,telematics-spool,message-api,certs,webroot}
mkdir -p "$DATA_ROOT"/kafka-{1,2,3}

check_duplicate_flyway_versions "$SOURCE_ROOT/tms-core-api/src/main/resources/db/migration"
check_duplicate_flyway_versions "$SOURCE_ROOT/tms-safety-api/src/main/resources/db/migration"
check_duplicate_flyway_versions "$SOURCE_ROOT/tms-telematics-api/src/main/resources/db/migration"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config >/dev/null || fail "docker compose config failed"

echo "[preflight] Checking docker daemon"
docker info >/dev/null || fail "docker daemon unavailable"

if [[ "${PREFER_PREBUILT_IMAGES:-true}" == "true" ]]; then
  echo "[preflight] Verifying image resolution"
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull --ignore-buildable >/dev/null || true
fi

echo "[preflight] OK"
