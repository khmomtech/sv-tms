#!/usr/bin/env bash
set -euo pipefail

# VPS-side split release script.
# Deploys tms-auth-api and tms-driver-app-api jars, installs/updates systemd units,
# writes default env files (if missing), restarts services, and verifies health.

BASE_DIR="/opt/sv-tms"
INCOMING_DIR=""
RELEASES_DIR=""
AUTH_APP_DIR="/opt/tms-auth-api"
DRIVER_APP_DIR="/opt/tms-driver-app-api"

AUTH_SERVICE="tms-auth-api"
DRIVER_SERVICE="tms-driver-app-api"
AUTH_UNIT_PATH="/etc/systemd/system/tms-auth-api.service"
DRIVER_UNIT_PATH="/etc/systemd/system/tms-driver-app-api.service"
AUTH_ENV_FILE="/etc/default/tms-auth-api"
DRIVER_ENV_FILE="/etc/default/tms-driver-app-api"

AUTH_JAR=""
DRIVER_JAR=""
AUTH_TEMPLATE=""
DRIVER_TEMPLATE=""

BACKUP_CMD=""
SKIP_DB_BACKUP=false
SKIP_NGINX_RELOAD=false

AUTH_HEALTH_URL="http://127.0.0.1:8083/actuator/health"
DRIVER_HEALTH_URL="http://127.0.0.1:8084/actuator/health"

usage() {
  cat <<'EOF'
Usage: sudo ./deploy/prod_release_split_vps.sh --auth-jar /opt/sv-tms/incoming/auth.jar --driver-jar /opt/sv-tms/incoming/driver.jar [options]

Options:
  --base-dir DIR              Default: /opt/sv-tms
  --incoming-dir DIR          Default: <base-dir>/incoming
  --releases-dir DIR          Default: <base-dir>/releases
  --auth-app-dir DIR          Default: /opt/tms-auth-api
  --driver-app-dir DIR        Default: /opt/tms-driver-app-api
  --auth-service NAME         Default: tms-auth-api
  --driver-service NAME       Default: tms-driver-app-api
  --auth-unit-path FILE       Default: /etc/systemd/system/tms-auth-api.service
  --driver-unit-path FILE     Default: /etc/systemd/system/tms-driver-app-api.service
  --auth-env-file FILE        Default: /etc/default/tms-auth-api
  --driver-env-file FILE      Default: /etc/default/tms-driver-app-api
  --auth-template FILE        Default: <base-dir>/deploy/tms-auth-api.service.template
  --driver-template FILE      Default: <base-dir>/deploy/tms-driver-app-api.service.template
  --backup-cmd FILE           Default: <base-dir>/deploy/prod_backup_vps.sh
  --skip-db-backup            Skip DB/files backup step
  --skip-nginx-reload         Do not reload nginx after service restart
  -h, --help                  Show help
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir) BASE_DIR="${2:-}"; shift 2 ;;
    --incoming-dir) INCOMING_DIR="${2:-}"; shift 2 ;;
    --releases-dir) RELEASES_DIR="${2:-}"; shift 2 ;;
    --auth-app-dir) AUTH_APP_DIR="${2:-}"; shift 2 ;;
    --driver-app-dir) DRIVER_APP_DIR="${2:-}"; shift 2 ;;
    --auth-service) AUTH_SERVICE="${2:-}"; shift 2 ;;
    --driver-service) DRIVER_SERVICE="${2:-}"; shift 2 ;;
    --auth-unit-path) AUTH_UNIT_PATH="${2:-}"; shift 2 ;;
    --driver-unit-path) DRIVER_UNIT_PATH="${2:-}"; shift 2 ;;
    --auth-env-file) AUTH_ENV_FILE="${2:-}"; shift 2 ;;
    --driver-env-file) DRIVER_ENV_FILE="${2:-}"; shift 2 ;;
    --auth-template) AUTH_TEMPLATE="${2:-}"; shift 2 ;;
    --driver-template) DRIVER_TEMPLATE="${2:-}"; shift 2 ;;
    --auth-jar) AUTH_JAR="${2:-}"; shift 2 ;;
    --driver-jar) DRIVER_JAR="${2:-}"; shift 2 ;;
    --backup-cmd) BACKUP_CMD="${2:-}"; shift 2 ;;
    --skip-db-backup) SKIP_DB_BACKUP=true; shift ;;
    --skip-nginx-reload) SKIP_NGINX_RELOAD=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

INCOMING_DIR="${INCOMING_DIR:-${BASE_DIR}/incoming}"
RELEASES_DIR="${RELEASES_DIR:-${BASE_DIR}/releases}"
AUTH_TEMPLATE="${AUTH_TEMPLATE:-${BASE_DIR}/deploy/tms-auth-api.service.template}"
DRIVER_TEMPLATE="${DRIVER_TEMPLATE:-${BASE_DIR}/deploy/tms-driver-app-api.service.template}"
BACKUP_CMD="${BACKUP_CMD:-${BASE_DIR}/deploy/prod_backup_vps.sh}"

if [[ -z "${AUTH_JAR}" || -z "${DRIVER_JAR}" ]]; then
  echo "ERROR: --auth-jar and --driver-jar are required." >&2
  usage
fi
if [[ ! -f "${AUTH_JAR}" ]]; then
  echo "ERROR: auth jar not found: ${AUTH_JAR}" >&2
  exit 1
fi
if [[ ! -f "${DRIVER_JAR}" ]]; then
  echo "ERROR: driver jar not found: ${DRIVER_JAR}" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: run as root (sudo)." >&2
  exit 1
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
release_id="split_release_${timestamp}"
release_dir="${RELEASES_DIR}/${release_id}"
manifest_path="${release_dir}/manifest.env"

mkdir -p "${release_dir}" "${AUTH_APP_DIR}" "${DRIVER_APP_DIR}" "${INCOMING_DIR}"

run_backup() {
  if ${SKIP_DB_BACKUP}; then
    echo "Skipping DB backup."
    return 0
  fi

  if [[ -x "${BACKUP_CMD}" ]]; then
    echo "Running backup: ${BACKUP_CMD}"
    "${BACKUP_CMD}"
  else
    echo "ERROR: backup command not found/executable: ${BACKUP_CMD}" >&2
    exit 1
  fi
}

install_unit_if_needed() {
  local unit_path="$1"
  local template="$2"

  if [[ -f "${unit_path}" ]]; then
    return 0
  fi
  if [[ ! -f "${template}" ]]; then
    echo "ERROR: systemd template not found: ${template}" >&2
    exit 1
  fi

  cp "${template}" "${unit_path}"
  chmod 644 "${unit_path}"
}

write_default_env_if_missing() {
  local env_file="$1"
  local port="$2"
  local xms="$3"
  local xmx="$4"

  if [[ -f "${env_file}" ]]; then
    return 0
  fi

  cat > "${env_file}" <<EOF
SERVER_PORT=${port}
SPRING_PROFILES_ACTIVE=prod
JAVA_OPTS=-Xms${xms} -Xmx${xmx} -Dspring.config.additional-location=file:/opt/sv-tms/backend/application.properties -Dspring.jpa.hibernate.ddl-auto=none
EOF
  chmod 640 "${env_file}"
}

ensure_env_key_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"

  if grep -q "^${key}=" "${env_file}" 2>/dev/null; then
    sed -i.bak "s#^${key}=.*#${key}=${value}#g" "${env_file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >> "${env_file}"
  fi
}

deploy_jars() {
  cp "${AUTH_JAR}" "${release_dir}/auth-app.jar"
  cp "${DRIVER_JAR}" "${release_dir}/driver-app.jar"
  cp "${release_dir}/auth-app.jar" "${AUTH_APP_DIR}/app.jar"
  cp "${release_dir}/driver-app.jar" "${DRIVER_APP_DIR}/app.jar"
  chmod 644 "${AUTH_APP_DIR}/app.jar" "${DRIVER_APP_DIR}/app.jar"
}

restart_and_verify() {
  systemctl daemon-reload
  systemctl enable "${AUTH_SERVICE}" "${DRIVER_SERVICE}" >/dev/null 2>&1 || true
  systemctl restart "${AUTH_SERVICE}" "${DRIVER_SERVICE}"
  systemctl is-active "${AUTH_SERVICE}" "${DRIVER_SERVICE}" >/dev/null

  if ! ${SKIP_NGINX_RELOAD}; then
    if systemctl list-unit-files | grep -q '^nginx\.service'; then
      nginx -t
      systemctl reload nginx || systemctl restart nginx
    fi
  fi

  curl -fsS "${AUTH_HEALTH_URL}" | grep -q '"status":"UP"'
  curl -fsS "${DRIVER_HEALTH_URL}" | grep -q '"status":"UP"'
}

write_manifest() {
  cat > "${manifest_path}" <<EOF
RELEASE_ID=${release_id}
CREATED_AT=${timestamp}
BASE_DIR=${BASE_DIR}
RELEASE_DIR=${release_dir}
AUTH_SERVICE=${AUTH_SERVICE}
DRIVER_SERVICE=${DRIVER_SERVICE}
AUTH_JAR_SOURCE=${AUTH_JAR}
DRIVER_JAR_SOURCE=${DRIVER_JAR}
AUTH_APP_JAR=${AUTH_APP_DIR}/app.jar
DRIVER_APP_JAR=${DRIVER_APP_DIR}/app.jar
AUTH_ENV_FILE=${AUTH_ENV_FILE}
DRIVER_ENV_FILE=${DRIVER_ENV_FILE}
BACKUP_CMD=${BACKUP_CMD}
EOF
}

run_backup
install_unit_if_needed "${AUTH_UNIT_PATH}" "${AUTH_TEMPLATE}"
install_unit_if_needed "${DRIVER_UNIT_PATH}" "${DRIVER_TEMPLATE}"
write_default_env_if_missing "${AUTH_ENV_FILE}" "8083" "256m" "1g"
write_default_env_if_missing "${DRIVER_ENV_FILE}" "8084" "512m" "2g"

if [[ -n "${APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS:-}" ]]; then
  ensure_env_key_value \
    "${DRIVER_ENV_FILE}" \
    "APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS" \
    "${APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS}"
fi

deploy_jars
restart_and_verify
write_manifest

echo "SPLIT_RELEASE_OK ${release_id}"
echo "Manifest: ${manifest_path}"
