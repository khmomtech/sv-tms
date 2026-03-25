#!/usr/bin/env bash
set -euo pipefail

# Local helper: build backend/frontend artifacts, upload them to the VPS,
# upload the VPS release/rollback scripts, and execute the release.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Permanent path mapping for current monorepo structure
BACKEND_DIR="${ROOT_DIR}/tms-core-api"
FRONTEND_DIR="${ROOT_DIR}/tms-admin-web-ui"

VPS=""
SSH_KEY=""
SSH_PORT=22
REMOTE_BASE_DIR="/opt/sv-tms"
REMOTE_INCOMING_DIR=""
REMOTE_BACKEND_DIR=""
REMOTE_FRONTEND_DIR=""
BACKEND_SERVICE="svtms-backend"
FRONTEND_RELOAD_SERVICE="nginx"
SKIP_BACKEND_BUILD=false
SKIP_FRONTEND_BUILD=false
SKIP_REMOTE_DB_BACKUP=false

usage() {
  cat <<'EOF'
Usage: ./deploy/deploy_update_to_vps.sh --vps user@host --ssh-key /path/to/key [options]

Options:
  --port PORT                    SSH port. Default: 22
  --remote-base-dir DIR          Default: /opt/sv-tms
  --remote-backend-dir DIR       Default: <remote-base-dir>/backend
  --remote-frontend-dir DIR      Default: <remote-base-dir>/frontend
  --backend-service NAME         Default: svtms-backend
  --frontend-reload-service NAME Default: nginx
  --skip-backend-build           Reuse existing jar in tms-backend/target
  --skip-frontend-build          Reuse existing dist build
  --skip-remote-db-backup        Pass --skip-db-backup to the VPS release script
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2;;
    --port) SSH_PORT="${2:-22}"; shift 2;;
    --remote-base-dir) REMOTE_BASE_DIR="${2:-}"; shift 2;;
    --remote-backend-dir) REMOTE_BACKEND_DIR="${2:-}"; shift 2;;
    --remote-frontend-dir) REMOTE_FRONTEND_DIR="${2:-}"; shift 2;;
    --backend-service) BACKEND_SERVICE="${2:-}"; shift 2;;
    --frontend-reload-service) FRONTEND_RELOAD_SERVICE="${2:-}"; shift 2;;
    --skip-backend-build) SKIP_BACKEND_BUILD=true; shift;;
    --skip-frontend-build) SKIP_FRONTEND_BUILD=true; shift;;
    --skip-remote-db-backup) SKIP_REMOTE_DB_BACKUP=true; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1" >&2; usage;;
  esac
done

if [[ -z "${VPS}" || -z "${SSH_KEY}" ]]; then
  usage
fi

REMOTE_INCOMING_DIR="${REMOTE_BASE_DIR}/incoming"
REMOTE_BACKEND_DIR="${REMOTE_BACKEND_DIR:-${REMOTE_BASE_DIR}/backend}"
REMOTE_FRONTEND_DIR="${REMOTE_FRONTEND_DIR:-${REMOTE_BASE_DIR}/frontend}"

build_backend() {
  if ! ${SKIP_BACKEND_BUILD}; then
    (cd "${BACKEND_DIR}" && ./mvnw -DskipTests package)
  fi

  BACKEND_JAR="$(find "${BACKEND_DIR}/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original*' | sort | tail -n1)"
  if [[ -z "${BACKEND_JAR:-}" || ! -f "${BACKEND_JAR}" ]]; then
    echo "ERROR: backend jar not found in ${BACKEND_DIR}/target" >&2
    exit 1
  fi
}

build_frontend() {
  if ! ${SKIP_FRONTEND_BUILD}; then
    (cd "${FRONTEND_DIR}" && npm ci && npm run build -- --configuration production)
  fi

  FRONTEND_BUILD_DIR=""
  if [[ -d "${FRONTEND_DIR}/dist/tms-frontend/browser" ]]; then
    FRONTEND_BUILD_DIR="${FRONTEND_DIR}/dist/tms-frontend/browser"
  elif [[ -d "${FRONTEND_DIR}/dist/tms-frontend" ]]; then
    FRONTEND_BUILD_DIR="${FRONTEND_DIR}/dist/tms-frontend"
  elif [[ -d "${FRONTEND_DIR}/dist/browser" ]]; then
    FRONTEND_BUILD_DIR="${FRONTEND_DIR}/dist/browser"
  else
    FRONTEND_BUILD_DIR="$(find "${FRONTEND_DIR}/dist" -mindepth 1 -maxdepth 2 -type d -name browser | head -n1 || true)"
  fi

  if [[ -z "${FRONTEND_BUILD_DIR}" || ! -d "${FRONTEND_BUILD_DIR}" ]]; then
    echo "ERROR: frontend build output not found under ${FRONTEND_DIR}/dist" >&2
    exit 1
  fi

  RELEASE_STAMP="$(date +%Y%m%d_%H%M%S)"
  FRONTEND_TAR="${ROOT_DIR}/deploy/frontend_${RELEASE_STAMP}.tar.gz"
  tar -czf "${FRONTEND_TAR}" -C "${FRONTEND_BUILD_DIR}" .
}

upload_and_release() {
  local ssh_base=(ssh -p "${SSH_PORT}" -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new)
  local scp_base=(scp -P "${SSH_PORT}" -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new)
  local remote_backend_jar="${REMOTE_INCOMING_DIR}/$(basename "${BACKEND_JAR}")"
  local remote_frontend_tar="${REMOTE_INCOMING_DIR}/$(basename "${FRONTEND_TAR}")"

  "${ssh_base[@]}" "${VPS}" "sudo mkdir -p '${REMOTE_INCOMING_DIR}' '${REMOTE_BASE_DIR}/deploy' '${REMOTE_BACKEND_DIR}' '${REMOTE_FRONTEND_DIR}'"
  "${scp_base[@]}" "${BACKEND_JAR}" "${VPS}:${remote_backend_jar}"
  "${scp_base[@]}" "${FRONTEND_TAR}" "${VPS}:${remote_frontend_tar}"
  "${scp_base[@]}" "${ROOT_DIR}/deploy/prod_release_vps.sh" "${VPS}:${REMOTE_BASE_DIR}/deploy/prod_release_vps.sh"
  "${scp_base[@]}" "${ROOT_DIR}/deploy/prod_rollback_vps.sh" "${VPS}:${REMOTE_BASE_DIR}/deploy/prod_rollback_vps.sh"

  local remote_cmd=(
    "sudo"
    "bash" "${REMOTE_BASE_DIR}/deploy/prod_release_vps.sh"
    "--base-dir" "${REMOTE_BASE_DIR}"
    "--backend-dir" "${REMOTE_BACKEND_DIR}"
    "--frontend-dir" "${REMOTE_FRONTEND_DIR}"
    "--backend-service" "${BACKEND_SERVICE}"
    "--frontend-reload-service" "${FRONTEND_RELOAD_SERVICE}"
    "--backend-jar" "${remote_backend_jar}"
    "--frontend-tar" "${remote_frontend_tar}"
  )
  if ${SKIP_REMOTE_DB_BACKUP}; then
    remote_cmd+=("--skip-db-backup")
  fi

  "${ssh_base[@]}" "${VPS}" "chmod +x '${REMOTE_BASE_DIR}/deploy/prod_release_vps.sh' '${REMOTE_BASE_DIR}/deploy/prod_rollback_vps.sh' && $(printf '%q ' "${remote_cmd[@]}")"
}

cleanup_local() {
  if [[ -n "${FRONTEND_TAR:-}" && -f "${FRONTEND_TAR}" ]]; then
    rm -f "${FRONTEND_TAR}"
  fi
}

trap cleanup_local EXIT

build_backend
build_frontend
upload_and_release

echo "Update deployed to ${VPS}"
echo "Rollback on VPS: sudo ${REMOTE_BASE_DIR}/deploy/prod_rollback_vps.sh"
