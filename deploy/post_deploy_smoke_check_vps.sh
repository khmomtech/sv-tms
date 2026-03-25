#!/usr/bin/env bash
set -euo pipefail

# Post-deploy smoke check for SVTMS on a VPS.
# Verifies:
# - systemd services are active (backend, nginx, mysql, redis)
# - backend actuator health is UP (HTTP 200 + "status":"UP")
# - public HTTPS endpoints return 200 (TMS + Safety + API)
#
# Auth:
# - Preferred: --ssh-key /path/to/key
# - Password: export SSHPASS='...' and pass --password-auth
#
# Usage:
#   ./deploy/post_deploy_smoke_check_vps.sh --vps root@207.180.245.156 --password-auth
#   ./deploy/post_deploy_smoke_check_vps.sh --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519
#
# Optional URL overrides:
#   --tms-url https://svtms.svtrucking.biz
#   --safety-url https://svsafety.svtrucking.biz
#   --api-url https://svtms.svtrucking.biz

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

TMS_URL="https://svtms.svtrucking.biz"
SAFETY_URL="https://svsafety.svtrucking.biz"
API_URL="https://svtms.svtrucking.biz"

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--tms-url URL] [--safety-url URL] [--api-url URL]

Notes:
- For --password-auth, set SSHPASS in your environment.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2;;
    --port) SSH_PORT="${2:-22}"; shift 2;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2;;
    --password-auth) PASSWORD_AUTH=true; shift;;
    --tms-url) TMS_URL="${2:-}"; shift 2;;
    --safety-url) SAFETY_URL="${2:-}"; shift 2;;
    --api-url) API_URL="${2:-}"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1" >&2; usage;;
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

echo "== Services"
ssh_run "systemctl is-active svtms-backend nginx mysql redis-server >/dev/null && echo OK || (systemctl --no-pager --failed; exit 1)"

echo "== Backend health (direct)"
HEALTH="$(ssh_run "curl -sS -m 8 -i http://127.0.0.1:8080/actuator/health" || true)"
echo "${HEALTH}" | sed -n '1,20p'
echo "${HEALTH}" | grep -qE '^HTTP/.* 200' || { echo "FAIL: backend actuator did not return 200" >&2; exit 1; }
echo "${HEALTH}" | grep -q '"status":"UP"' || { echo "FAIL: backend health is not UP" >&2; exit 1; }

echo "== Nginx config"
ssh_run "nginx -t >/dev/null && echo OK"

echo "== HTTPS endpoints"
ssh_run "curl -fsSI -m 10 '${TMS_URL}/' | head -n 12"
ssh_run "curl -fsSI -m 10 '${SAFETY_URL}/' | head -n 12"
ssh_run "curl -fsSI -m 10 '${API_URL}/actuator/health' | head -n 20"

echo "SMOKE_CHECK_OK"

