#!/usr/bin/env bash
set -euo pipefail

# Post-release stabilization watcher for split services.
# Collects periodic status snapshots for auth-api, driver-app-api, and nginx.

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

AUTH_LOCAL_URL="http://127.0.0.1:8083"
DRIVER_LOCAL_URL="http://127.0.0.1:8084"

DURATION_MIN=60
INTERVAL_SEC=60
OUT_DIR="./deploy/reports"

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--auth-local-url URL] [--driver-local-url URL]
          [--duration-min 60] [--interval-sec 60] [--out-dir ./deploy/reports]

Examples:
  $0 --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519
  SSHPASS='...' $0 --vps root@207.180.245.156 --password-auth --duration-min 30
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2 ;;
    --port) SSH_PORT="${2:-22}"; shift 2 ;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2 ;;
    --password-auth) PASSWORD_AUTH=true; shift ;;
    --auth-local-url) AUTH_LOCAL_URL="${2:-}"; shift 2 ;;
    --driver-local-url) DRIVER_LOCAL_URL="${2:-}"; shift 2 ;;
    --duration-min) DURATION_MIN="${2:-60}"; shift 2 ;;
    --interval-sec) INTERVAL_SEC="${2:-60}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-./deploy/reports}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${VPS}" ]]; then
  echo "ERROR: --vps is required" >&2
  usage
fi

if ${PASSWORD_AUTH}; then
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "ERROR: sshpass not installed (required for --password-auth)" >&2
    exit 1
  fi
  if [[ -z "${SSHPASS:-}" ]]; then
    echo "ERROR: SSHPASS env var is required for --password-auth" >&2
    exit 1
  fi
fi

if ! [[ "${DURATION_MIN}" =~ ^[0-9]+$ && "${INTERVAL_SEC}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: duration and interval must be integers" >&2
  exit 1
fi

SSH_BASE=(ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_KEY}" ]]; then
  SSH_BASE+=(-i "${SSH_KEY}")
fi

ssh_run() {
  if ${PASSWORD_AUTH}; then
    sshpass -e "${SSH_BASE[@]}" "${VPS}" "$@"
  else
    "${SSH_BASE[@]}" "${VPS}" "$@"
  fi
}

mkdir -p "${OUT_DIR}"
ts="$(date +%Y%m%d_%H%M%S)"
report="${OUT_DIR}/stabilization_watch_${ts}.log"

end_epoch=$(( $(date +%s) + DURATION_MIN * 60 ))
iter=0

echo "STABILIZATION_WATCH_START ${ts}" | tee -a "${report}"
echo "vps=${VPS} duration_min=${DURATION_MIN} interval_sec=${INTERVAL_SEC}" | tee -a "${report}"

while (( $(date +%s) < end_epoch )); do
  iter=$((iter + 1))
  local_ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "" | tee -a "${report}"
  echo "=== SNAPSHOT ${iter} @ ${local_ts} ===" | tee -a "${report}"

  ssh_run "systemctl is-active tms-auth-api tms-driver-app-api nginx" | sed 's/^/service: /' | tee -a "${report}" || true
  ssh_run "curl -sS '${AUTH_LOCAL_URL}/actuator/health' | tr -d '\n'; echo" | sed 's/^/auth_health: /' | tee -a "${report}" || true
  ssh_run "curl -sS '${DRIVER_LOCAL_URL}/actuator/health' | tr -d '\n'; echo" | sed 's/^/driver_health: /' | tee -a "${report}" || true
  ssh_run "tail -n 20 /var/log/nginx/error.log | sed 's/^/nginx_err: /'" | tee -a "${report}" || true
  ssh_run "journalctl -u tms-auth-api -n 20 --no-pager | sed 's/^/auth_log: /'" | tee -a "${report}" || true
  ssh_run "journalctl -u tms-driver-app-api -n 20 --no-pager | sed 's/^/driver_log: /'" | tee -a "${report}" || true

  sleep "${INTERVAL_SEC}"
done

echo "STABILIZATION_WATCH_DONE $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${report}"
echo "report=${report}" | tee -a "${report}"

