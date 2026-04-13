#!/usr/bin/env bash
set -euo pipefail

# Local helper: deploy split backend services (auth + driver-app) and the admin UI
# to a VPS that runs split systemd services behind nginx.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${ROOT_DIR}/deploy"
ADMIN_UI_DIR="${ROOT_DIR}/tms-admin-web-ui"

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

REMOTE_BASE_DIR="/opt/sv-tms"
REMOTE_FRONTEND_DIR=""
REMOTE_INCOMING_DIR=""
REMOTE_DEPLOY_DIR=""
FRONTEND_RELOAD_SERVICE="nginx"

SKIP_BACKEND_BUILD=false
SKIP_FRONTEND_BUILD=false
SKIP_REMOTE_DB_BACKUP=false

usage() {
  cat <<'EOF'
Usage: ./deploy/deploy_split_and_admin_ui_to_vps.sh --vps user@host [--ssh-key /path | --password-auth] [options]

Options:
  --port PORT                 SSH port (default: 22)
  --remote-base-dir DIR       Default: /opt/sv-tms
  --remote-frontend-dir DIR   Default: <remote-base-dir>/frontend
  --frontend-reload-service   Default: nginx
  --skip-backend-build        Reuse existing auth/driver jars
  --skip-frontend-build       Reuse existing admin UI dist output
  --skip-remote-db-backup     Pass --skip-db-backup to split VPS release script
  -h, --help                  Show help

Examples:
  ./deploy/deploy_split_and_admin_ui_to_vps.sh --vps root@1.2.3.4 --ssh-key ~/.ssh/id_ed25519
  SSHPASS='...' ./deploy/deploy_split_and_admin_ui_to_vps.sh --vps root@1.2.3.4 --password-auth
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2 ;;
    --port) SSH_PORT="${2:-22}"; shift 2 ;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2 ;;
    --password-auth) PASSWORD_AUTH=true; shift ;;
    --remote-base-dir) REMOTE_BASE_DIR="${2:-}"; shift 2 ;;
    --remote-frontend-dir) REMOTE_FRONTEND_DIR="${2:-}"; shift 2 ;;
    --frontend-reload-service) FRONTEND_RELOAD_SERVICE="${2:-}"; shift 2 ;;
    --skip-backend-build) SKIP_BACKEND_BUILD=true; shift ;;
    --skip-frontend-build) SKIP_FRONTEND_BUILD=true; shift ;;
    --skip-remote-db-backup) SKIP_REMOTE_DB_BACKUP=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${VPS}" ]]; then
  usage
fi
if [[ -z "${SSH_KEY}" && "${PASSWORD_AUTH}" = false ]]; then
  echo "ERROR: specify --ssh-key or --password-auth." >&2
  exit 1
fi
if ${PASSWORD_AUTH}; then
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "ERROR: sshpass not installed (required for --password-auth)." >&2
    exit 1
  fi
  if [[ -z "${SSHPASS:-}" ]]; then
    echo "ERROR: SSHPASS env var is required for --password-auth." >&2
    exit 1
  fi
fi

REMOTE_FRONTEND_DIR="${REMOTE_FRONTEND_DIR:-${REMOTE_BASE_DIR}/frontend}"
REMOTE_INCOMING_DIR="${REMOTE_BASE_DIR}/incoming"
REMOTE_DEPLOY_DIR="${REMOTE_BASE_DIR}/deploy"

SSH_BASE=(ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=accept-new)
SCP_BASE=(scp -P "${SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_KEY}" ]]; then
  SSH_BASE+=(-i "${SSH_KEY}")
  SCP_BASE+=(-i "${SSH_KEY}")
fi
if ${PASSWORD_AUTH}; then
  SSH_BASE+=(
    -o PreferredAuthentications=password,keyboard-interactive
    -o PubkeyAuthentication=no
  )
  SCP_BASE+=(
    -o PreferredAuthentications=password,keyboard-interactive
    -o PubkeyAuthentication=no
  )
fi

ssh_run() {
  if ${PASSWORD_AUTH}; then
    sshpass -e "${SSH_BASE[@]}" "${VPS}" "$@"
  else
    "${SSH_BASE[@]}" "${VPS}" "$@"
  fi
}

scp_put() {
  local src="$1"
  local dst="$2"
  if ${PASSWORD_AUTH}; then
    sshpass -e "${SCP_BASE[@]}" "${src}" "${VPS}:${dst}"
  else
    "${SCP_BASE[@]}" "${src}" "${VPS}:${dst}"
  fi
}

build_backend() {
  if ! ${SKIP_BACKEND_BUILD}; then
    if [[ -x "${ROOT_DIR}/mvnw" ]]; then
      (cd "${ROOT_DIR}" && ./mvnw -pl tms-auth-api,tms-driver-app-api -am -DskipTests package)
    elif command -v mvn >/dev/null 2>&1; then
      (cd "${ROOT_DIR}" && mvn -pl tms-auth-api,tms-driver-app-api -am -DskipTests package)
    else
      echo "ERROR: neither ./mvnw nor mvn is available for backend build" >&2
      exit 1
    fi
  fi

  AUTH_JAR="$(find "${ROOT_DIR}/tms-auth-api/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original*' | sort | tail -n1)"
  DRIVER_JAR="$(find "${ROOT_DIR}/tms-driver-app-api/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original*' | sort | tail -n1)"

  if [[ -z "${AUTH_JAR:-}" || ! -f "${AUTH_JAR}" ]]; then
    echo "ERROR: auth jar not found in tms-auth-api/target" >&2
    exit 1
  fi
  if [[ -z "${DRIVER_JAR:-}" || ! -f "${DRIVER_JAR}" ]]; then
    echo "ERROR: driver jar not found in tms-driver-app-api/target" >&2
    exit 1
  fi
}

build_frontend() {
  if ! ${SKIP_FRONTEND_BUILD}; then
    (cd "${ADMIN_UI_DIR}" && npm ci && npm run build -- --configuration production)
  fi

  FRONTEND_BUILD_DIR=""
  if [[ -d "${ADMIN_UI_DIR}/dist/tms-admin-web-ui/browser" ]]; then
    FRONTEND_BUILD_DIR="${ADMIN_UI_DIR}/dist/tms-admin-web-ui/browser"
  elif [[ -d "${ADMIN_UI_DIR}/dist/tms-admin-web-ui" ]]; then
    FRONTEND_BUILD_DIR="${ADMIN_UI_DIR}/dist/tms-admin-web-ui"
  elif [[ -d "${ADMIN_UI_DIR}/dist/browser" ]]; then
    FRONTEND_BUILD_DIR="${ADMIN_UI_DIR}/dist/browser"
  else
    FRONTEND_BUILD_DIR="$(find "${ADMIN_UI_DIR}/dist" -mindepth 1 -maxdepth 2 -type d -name browser | head -n1 || true)"
  fi

  if [[ -z "${FRONTEND_BUILD_DIR}" || ! -d "${FRONTEND_BUILD_DIR}" ]]; then
    echo "ERROR: admin UI build output not found under ${ADMIN_UI_DIR}/dist" >&2
    exit 1
  fi

  RELEASE_STAMP="$(date +%Y%m%d_%H%M%S)"
  FRONTEND_TAR="${ROOT_DIR}/deploy/tms_admin_web_ui_${RELEASE_STAMP}.tar.gz"
  tar -czf "${FRONTEND_TAR}" -C "${FRONTEND_BUILD_DIR}" .
}

deploy_frontend_remote() {
  local remote_frontend_tar="${REMOTE_INCOMING_DIR}/$(basename "${FRONTEND_TAR}")"
  local remote_cmd

  remote_cmd=$(cat <<EOF
set -euo pipefail
timestamp="\$(date +%Y%m%d_%H%M%S)"
release_id="frontend_release_\${timestamp}"
release_dir="${REMOTE_BASE_DIR}/releases/\${release_id}"
backup_dir="${REMOTE_BASE_DIR}/backups/\${release_id}"
stage_dir="\${release_dir}/frontend"
manifest="\${release_dir}/manifest.env"

mkdir -p "${REMOTE_FRONTEND_DIR}" "${REMOTE_BASE_DIR}/releases" "${REMOTE_BASE_DIR}/backups" "\${release_dir}" "\${backup_dir}" "\${stage_dir}"

if [[ -d "${REMOTE_FRONTEND_DIR}" ]]; then
  tar -czf "\${backup_dir}/frontend_live_\${timestamp}.tar.gz" -C "$(dirname "${REMOTE_FRONTEND_DIR}")" "$(basename "${REMOTE_FRONTEND_DIR}")"
fi

tar -xzf "${remote_frontend_tar}" -C "\${stage_dir}"

resolved_source="\${stage_dir}"
if [[ -d "\${stage_dir}/dist" ]]; then
  resolved_source="\${stage_dir}/dist"
elif [[ -d "\${stage_dir}/browser" ]]; then
  resolved_source="\${stage_dir}/browser"
else
  first_dir="\$(find "\${stage_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
  if [[ -n "\${first_dir}" && -f "\${first_dir}/index.html" ]]; then
    resolved_source="\${first_dir}"
  fi
fi

find "${REMOTE_FRONTEND_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp -R "\${resolved_source}/." "${REMOTE_FRONTEND_DIR}/"

if systemctl list-unit-files | grep -q "^${FRONTEND_RELOAD_SERVICE}"; then
  systemctl reload "${FRONTEND_RELOAD_SERVICE}" || systemctl restart "${FRONTEND_RELOAD_SERVICE}"
fi

cat > "\${manifest}" <<MANIFEST
RELEASE_ID=\${release_id}
CREATED_AT=\${timestamp}
FRONTEND_DIR=${REMOTE_FRONTEND_DIR}
FRONTEND_TAR_SOURCE=${remote_frontend_tar}
FRONTEND_BACKUP_TAR=\${backup_dir}/frontend_live_\${timestamp}.tar.gz
MANIFEST

ln -sfn "\${release_dir}" "${REMOTE_BASE_DIR}/releases/frontend_latest"
echo "FRONTEND_RELEASE_OK \${release_id}"
EOF
)

  ssh_run "sudo bash -lc $(printf '%q' "${remote_cmd}")"
}

cleanup_local() {
  if [[ -n "${FRONTEND_TAR:-}" && -f "${FRONTEND_TAR}" ]]; then
    rm -f "${FRONTEND_TAR}"
  fi
}

trap cleanup_local EXIT

build_backend
build_frontend

REMOTE_AUTH_JAR="${REMOTE_INCOMING_DIR}/$(basename "${AUTH_JAR}")"
REMOTE_DRIVER_JAR="${REMOTE_INCOMING_DIR}/$(basename "${DRIVER_JAR}")"
REMOTE_FRONTEND_TAR="${REMOTE_INCOMING_DIR}/$(basename "${FRONTEND_TAR}")"

ssh_run "mkdir -p '${REMOTE_INCOMING_DIR}' '${REMOTE_DEPLOY_DIR}' '${REMOTE_FRONTEND_DIR}'"

scp_put "${AUTH_JAR}" "${REMOTE_AUTH_JAR}"
scp_put "${DRIVER_JAR}" "${REMOTE_DRIVER_JAR}"
scp_put "${FRONTEND_TAR}" "${REMOTE_FRONTEND_TAR}"
scp_put "${DEPLOY_DIR}/prod_release_split_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh"
scp_put "${DEPLOY_DIR}/prod_backup_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_backup_vps.sh"
scp_put "${DEPLOY_DIR}/prod_rollback_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_rollback_vps.sh"
scp_put "${DEPLOY_DIR}/tms-auth-api.service.template" "${REMOTE_DEPLOY_DIR}/tms-auth-api.service.template"
scp_put "${DEPLOY_DIR}/tms-driver-app-api.service.template" "${REMOTE_DEPLOY_DIR}/tms-driver-app-api.service.template"

REMOTE_BACKEND_CMD="chmod +x '${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh' '${REMOTE_DEPLOY_DIR}/prod_backup_vps.sh' '${REMOTE_DEPLOY_DIR}/prod_rollback_vps.sh' && sudo '${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh' --auth-jar '${REMOTE_AUTH_JAR}' --driver-jar '${REMOTE_DRIVER_JAR}'"
if ${SKIP_REMOTE_DB_BACKUP}; then
  REMOTE_BACKEND_CMD="${REMOTE_BACKEND_CMD} --skip-db-backup"
fi
ssh_run "${REMOTE_BACKEND_CMD}"

deploy_frontend_remote

echo "Split backend + admin UI deployment completed on ${VPS}"
echo "Auth jar: ${REMOTE_AUTH_JAR}"
echo "Driver jar: ${REMOTE_DRIVER_JAR}"
echo "Admin UI tar: ${REMOTE_FRONTEND_TAR}"
