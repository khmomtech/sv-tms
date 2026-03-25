#!/usr/bin/env bash
set -euo pipefail

# VPS-side release script for non-containerized backend/frontend deployments.
# It backs up the current database and deployed assets, installs new artifacts,
# writes a release manifest, and restarts services.

BASE_DIR="/opt/sv-tms"
BACKEND_DIR=""
FRONTEND_DIR=""
BACKUPS_DIR=""
RELEASES_DIR=""
INCOMING_DIR=""
BACKEND_SERVICE="svtms-backend"
FRONTEND_RELOAD_SERVICE="nginx"
BACKEND_JAR=""
FRONTEND_TAR=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
DB_HOST="127.0.0.1"
DB_PORT="3306"
APP_PROPS=""
ENV_FILE=""
SKIP_DB_BACKUP=false

usage() {
  cat <<'EOF'
Usage: sudo ./deploy/prod_release_vps.sh --backend-jar /path/app.jar --frontend-tar /path/frontend.tar.gz [options]

Options:
  --base-dir DIR                Base deploy dir. Default: /opt/sv-tms
  --backend-dir DIR             Live backend dir. Default: <base-dir>/backend
  --frontend-dir DIR            Live frontend dir. Default: <base-dir>/frontend
  --incoming-dir DIR            Incoming artifacts dir. Default: <base-dir>/incoming
  --backups-dir DIR             Backup root dir. Default: <base-dir>/backups
  --releases-dir DIR            Release metadata dir. Default: <base-dir>/releases
  --backend-service NAME        systemd backend service. Default: svtms-backend
  --frontend-reload-service     Service to reload after frontend deploy. Default: nginx
  --db-name NAME                DB name override
  --db-user USER                DB user override
  --db-password PASS            DB password override
  --db-host HOST                DB host override. Default: 127.0.0.1
  --db-port PORT                DB port override. Default: 3306
  --env-file FILE               Env file with MYSQL_* vars
  --app-props FILE              Spring application.properties file
  --skip-db-backup              Skip mysqldump
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir) BASE_DIR="${2:-}"; shift 2;;
    --backend-dir) BACKEND_DIR="${2:-}"; shift 2;;
    --frontend-dir) FRONTEND_DIR="${2:-}"; shift 2;;
    --incoming-dir) INCOMING_DIR="${2:-}"; shift 2;;
    --backups-dir) BACKUPS_DIR="${2:-}"; shift 2;;
    --releases-dir) RELEASES_DIR="${2:-}"; shift 2;;
    --backend-service) BACKEND_SERVICE="${2:-}"; shift 2;;
    --frontend-reload-service) FRONTEND_RELOAD_SERVICE="${2:-}"; shift 2;;
    --backend-jar) BACKEND_JAR="${2:-}"; shift 2;;
    --frontend-tar) FRONTEND_TAR="${2:-}"; shift 2;;
    --db-name) DB_NAME="${2:-}"; shift 2;;
    --db-user) DB_USER="${2:-}"; shift 2;;
    --db-password) DB_PASSWORD="${2:-}"; shift 2;;
    --db-host) DB_HOST="${2:-}"; shift 2;;
    --db-port) DB_PORT="${2:-}"; shift 2;;
    --env-file) ENV_FILE="${2:-}"; shift 2;;
    --app-props) APP_PROPS="${2:-}"; shift 2;;
    --skip-db-backup) SKIP_DB_BACKUP=true; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1" >&2; usage;;
  esac
done

BACKEND_DIR="${BACKEND_DIR:-${BASE_DIR}/backend}"
FRONTEND_DIR="${FRONTEND_DIR:-${BASE_DIR}/frontend}"
INCOMING_DIR="${INCOMING_DIR:-${BASE_DIR}/incoming}"
BACKUPS_DIR="${BACKUPS_DIR:-${BASE_DIR}/backups}"
RELEASES_DIR="${RELEASES_DIR:-${BASE_DIR}/releases}"
APP_PROPS="${APP_PROPS:-${BACKEND_DIR}/application.properties}"
ENV_FILE="${ENV_FILE:-${BASE_DIR}/infra/.env}"

if [[ -z "${BACKEND_JAR}" || -z "${FRONTEND_TAR}" ]]; then
  echo "ERROR: --backend-jar and --frontend-tar are required." >&2
  usage
fi

if [[ ! -f "${BACKEND_JAR}" ]]; then
  echo "ERROR: backend jar not found: ${BACKEND_JAR}" >&2
  exit 1
fi

if [[ ! -f "${FRONTEND_TAR}" ]]; then
  echo "ERROR: frontend tar not found: ${FRONTEND_TAR}" >&2
  exit 1
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
release_id="release_${timestamp}"
backup_dir="${BACKUPS_DIR}/${release_id}"
release_dir="${RELEASES_DIR}/${release_id}"
frontend_stage_dir="${release_dir}/frontend"
manifest_path="${release_dir}/manifest.env"

mkdir -p "${BACKEND_DIR}" "${FRONTEND_DIR}" "${INCOMING_DIR}" "${BACKUPS_DIR}" "${RELEASES_DIR}" "${release_dir}"

trim() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

read_prop() {
  local file="$1"
  local key="$2"
  [[ -f "${file}" ]] || return 0
  awk -F= -v k="${key}" '$1==k { v=$2 } END { gsub(/\r/,"",v); print v }' "${file}"
}

load_env_file() {
  local file="$1"
  [[ -f "${file}" ]] || return 0
  while IFS='=' read -r key value; do
    [[ -z "${key}" || "${key}" =~ ^[[:space:]]*# ]] && continue
    key="$(trim "${key}")"
    value="$(trim "${value}")"
    value="${value%\"}"
    value="${value#\"}"
    export "${key}=${value}"
  done < "${file}"
}

derive_db_settings() {
  load_env_file "${ENV_FILE}"

  local app_db_url
  app_db_url="$(read_prop "${APP_PROPS}" "spring.datasource.url" || true)"
  local app_db_user
  app_db_user="$(read_prop "${APP_PROPS}" "spring.datasource.username" || true)"
  local app_db_password
  app_db_password="$(read_prop "${APP_PROPS}" "spring.datasource.password" || true)"

  DB_NAME="${DB_NAME:-${MYSQL_DATABASE:-}}"
  DB_USER="${DB_USER:-${MYSQL_USER:-${MYSQL_USERNAME:-${app_db_user:-}}}}"
  DB_PASSWORD="${DB_PASSWORD:-${MYSQL_PASSWORD:-${MYSQL_ROOT_PASSWORD:-${app_db_password:-}}}}"
  DB_HOST="${DB_HOST:-127.0.0.1}"
  DB_PORT="${DB_PORT:-3306}"

  if [[ -n "${app_db_url}" ]]; then
    local parsed_host_port db_part host_port
    parsed_host_port="$(printf '%s' "${app_db_url}" | sed -nE 's|^jdbc:mysql://([^/]+)/.*|\1|p')"
    db_part="$(printf '%s' "${app_db_url}" | sed -nE 's|^jdbc:mysql://[^/]+/([^?]+).*$|\1|p')"
    if [[ -n "${db_part}" && -z "${DB_NAME}" ]]; then
      DB_NAME="${db_part}"
    fi
    if [[ -n "${parsed_host_port}" ]]; then
      host_port="${parsed_host_port}"
      if [[ "${host_port}" == *:* ]]; then
        if [[ "${DB_HOST}" == "127.0.0.1" ]]; then
          DB_HOST="${host_port%%:*}"
        fi
        if [[ "${DB_PORT}" == "3306" ]]; then
          DB_PORT="${host_port##*:}"
        fi
      elif [[ "${DB_HOST}" == "127.0.0.1" ]]; then
        DB_HOST="${host_port}"
      fi
    fi
  fi

  DB_NAME="${DB_NAME:-svlogistics_tms_db}"
  DB_USER="${DB_USER:-root}"
}

backup_db() {
  if ${SKIP_DB_BACKUP}; then
    echo "Skipping DB backup."
    return 0
  fi

  derive_db_settings

  if ! command -v mysqldump >/dev/null 2>&1; then
    echo "ERROR: mysqldump is required on the VPS." >&2
    exit 1
  fi

  if [[ -z "${DB_PASSWORD}" ]]; then
    echo "ERROR: database password is empty; refusing to run unattended backup." >&2
    exit 1
  fi

  mkdir -p "${backup_dir}"
  local db_dump="${backup_dir}/db_${DB_NAME}_${timestamp}.sql.gz"
  echo "Backing up database ${DB_NAME} from ${DB_HOST}:${DB_PORT}"
  mysqldump \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --user="${DB_USER}" \
    --password="${DB_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "${DB_NAME}" | gzip -1 > "${db_dump}"
}

backup_paths() {
  mkdir -p "${backup_dir}"

  if [[ -d "${BACKEND_DIR}" ]]; then
    tar \
      --warning=no-file-changed \
      --exclude="$(basename "${BACKEND_DIR}")/logs/*" \
      -czf "${backup_dir}/backend_live_${timestamp}.tar.gz" \
      -C "$(dirname "${BACKEND_DIR}")" \
      "$(basename "${BACKEND_DIR}")"
  fi

  if [[ -d "${FRONTEND_DIR}" ]]; then
    tar -czf "${backup_dir}/frontend_live_${timestamp}.tar.gz" -C "$(dirname "${FRONTEND_DIR}")" "$(basename "${FRONTEND_DIR}")"
  fi
}

write_manifest() {
  cat > "${manifest_path}" <<EOF
RELEASE_ID=${release_id}
CREATED_AT=${timestamp}
BASE_DIR=${BASE_DIR}
BACKUP_DIR=${backup_dir}
BACKEND_DIR=${BACKEND_DIR}
FRONTEND_DIR=${FRONTEND_DIR}
BACKEND_SERVICE=${BACKEND_SERVICE}
FRONTEND_RELOAD_SERVICE=${FRONTEND_RELOAD_SERVICE}
BACKEND_BACKUP_TAR=${backup_dir}/backend_live_${timestamp}.tar.gz
FRONTEND_BACKUP_TAR=${backup_dir}/frontend_live_${timestamp}.tar.gz
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASSWORD=${DB_PASSWORD:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_DUMP=${backup_dir}/db_${DB_NAME:-unknown}_${timestamp}.sql.gz
EOF
}

deploy_backend() {
  install -d -m 0755 "${BACKEND_DIR}"
  cp "${BACKEND_JAR}" "${release_dir}/app.jar"
  cp "${release_dir}/app.jar" "${BACKEND_DIR}/app.jar"
}

deploy_frontend() {
  rm -rf "${frontend_stage_dir}"
  mkdir -p "${frontend_stage_dir}"
  tar -xzf "${FRONTEND_TAR}" -C "${frontend_stage_dir}"

  local resolved_source="${frontend_stage_dir}"
  if [[ -d "${frontend_stage_dir}/dist" ]]; then
    resolved_source="${frontend_stage_dir}/dist"
  elif [[ -d "${frontend_stage_dir}/browser" ]]; then
    resolved_source="${frontend_stage_dir}/browser"
  else
    local first_dir
    first_dir="$(find "${frontend_stage_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
    if [[ -n "${first_dir}" && -f "${first_dir}/index.html" ]]; then
      resolved_source="${first_dir}"
    fi
  fi

  install -d -m 0755 "${FRONTEND_DIR}"
  find "${FRONTEND_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -R "${resolved_source}/." "${FRONTEND_DIR}/"
}

restart_services() {
  systemctl restart "${BACKEND_SERVICE}"
  systemctl is-active --quiet "${BACKEND_SERVICE}"

  if systemctl list-unit-files | grep -q "^${FRONTEND_RELOAD_SERVICE}"; then
    systemctl reload "${FRONTEND_RELOAD_SERVICE}" || systemctl restart "${FRONTEND_RELOAD_SERVICE}"
  fi
}

main() {
  backup_db
  backup_paths
  write_manifest
  deploy_backend
  deploy_frontend
  restart_services
  ln -sfn "${release_dir}" "${RELEASES_DIR}/latest"
  echo "Release complete: ${release_id}"
  echo "Manifest: ${manifest_path}"
}

main "$@"
