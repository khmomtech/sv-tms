#!/usr/bin/env bash
set -euo pipefail

# Local helper: build split jars, upload deploy scripts/templates, execute VPS split release script.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${ROOT_DIR}/deploy"

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

REMOTE_BASE_DIR="/opt/sv-tms"
REMOTE_INCOMING_DIR=""
REMOTE_DEPLOY_DIR=""

SKIP_BUILD=false
SKIP_REMOTE_DB_BACKUP=false

usage() {
  cat <<'EOF'
Usage: ./deploy/deploy_split_to_vps.sh --vps user@host [--ssh-key /path | --password-auth] [options]

Options:
  --port PORT                 SSH port (default: 22)
  --remote-base-dir DIR       Default: /opt/sv-tms
  --skip-build                Reuse existing local jars
  --skip-remote-db-backup     Pass --skip-db-backup to VPS release script
  -h, --help                  Show help

Examples:
  ./deploy/deploy_split_to_vps.sh --vps root@1.2.3.4 --ssh-key ~/.ssh/id_ed25519
  SSHPASS='...' ./deploy/deploy_split_to_vps.sh --vps root@1.2.3.4 --password-auth
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
    --skip-build) SKIP_BUILD=true; shift ;;
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

if ! ${SKIP_BUILD}; then
  (cd "${ROOT_DIR}" && mvn -pl tms-auth-api,tms-driver-app-api -am -DskipTests package)
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

REMOTE_AUTH_JAR="${REMOTE_INCOMING_DIR}/$(basename "${AUTH_JAR}")"
REMOTE_DRIVER_JAR="${REMOTE_INCOMING_DIR}/$(basename "${DRIVER_JAR}")"

ssh_run "mkdir -p '${REMOTE_INCOMING_DIR}' '${REMOTE_DEPLOY_DIR}'"

scp_put "${AUTH_JAR}" "${REMOTE_AUTH_JAR}"
scp_put "${DRIVER_JAR}" "${REMOTE_DRIVER_JAR}"
scp_put "${DEPLOY_DIR}/prod_release_split_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh"
scp_put "${DEPLOY_DIR}/prod_backup_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_backup_vps.sh"
scp_put "${DEPLOY_DIR}/prod_rollback_vps.sh" "${REMOTE_DEPLOY_DIR}/prod_rollback_vps.sh"
scp_put "${DEPLOY_DIR}/tms-auth-api.service.template" "${REMOTE_DEPLOY_DIR}/tms-auth-api.service.template"
scp_put "${DEPLOY_DIR}/tms-driver-app-api.service.template" "${REMOTE_DEPLOY_DIR}/tms-driver-app-api.service.template"

REMOTE_CMD="chmod +x '${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh' '${REMOTE_DEPLOY_DIR}/prod_backup_vps.sh' '${REMOTE_DEPLOY_DIR}/prod_rollback_vps.sh' && sudo '${REMOTE_DEPLOY_DIR}/prod_release_split_vps.sh' --auth-jar '${REMOTE_AUTH_JAR}' --driver-jar '${REMOTE_DRIVER_JAR}'"
if ${SKIP_REMOTE_DB_BACKUP}; then
  REMOTE_CMD="${REMOTE_CMD} --skip-db-backup"
fi

ssh_run "${REMOTE_CMD}"

echo "Split deployment completed on ${VPS}"
echo "Auth jar: ${REMOTE_AUTH_JAR}"
echo "Driver jar: ${REMOTE_DRIVER_JAR}"
