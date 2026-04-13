#!/usr/bin/env bash
set -euo pipefail

# Post-deploy smoke check for split services behind nginx routing.
# Verifies:
# - systemd services are active (auth-api, driver-app-api, nginx)
# - local service health endpoints are UP on expected ports
# - public path routing sends auth paths to auth-api and driver paths to driver-app-api
# - ws-sockjs info endpoint responds through nginx
#
# Usage:
#   ./deploy/post_deploy_microservices_routing_smoke_vps.sh --vps root@1.2.3.4 --ssh-key ~/.ssh/id_ed25519
#   SSHPASS='...' ./deploy/post_deploy_microservices_routing_smoke_vps.sh --vps root@1.2.3.4 --password-auth

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

PUBLIC_URL="https://svtms.svtrucking.biz"
AUTH_LOCAL_URL="http://127.0.0.1:8083"
DRIVER_LOCAL_URL="http://127.0.0.1:8084"

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--public-url URL] [--auth-local-url URL] [--driver-local-url URL]

Notes:
- For --password-auth, export SSHPASS in your shell.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2 ;;
    --port) SSH_PORT="${2:-22}"; shift 2 ;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2 ;;
    --password-auth) PASSWORD_AUTH=true; shift ;;
    --public-url) PUBLIC_URL="${2:-}"; shift 2 ;;
    --auth-local-url) AUTH_LOCAL_URL="${2:-}"; shift 2 ;;
    --driver-local-url) DRIVER_LOCAL_URL="${2:-}"; shift 2 ;;
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

SSH_BASE=(ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_KEY}" ]]; then
  SSH_BASE+=(-i "${SSH_KEY}")
fi
if ${PASSWORD_AUTH}; then
  SSH_BASE+=(
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

remote_http_code() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local code
  if [[ -n "${body}" ]]; then
    code="$(ssh_run "curl -sS -o /tmp/smoke_body.out -w '%{http_code}' -X ${method} -H 'Content-Type: application/json' --data '${body}' '${url}' || true")"
  else
    code="$(ssh_run "curl -sS -o /tmp/smoke_body.out -w '%{http_code}' -X ${method} '${url}' || true")"
  fi
  echo "${code}"
}

assert_code_in() {
  local actual="$1"
  local label="$2"
  shift 2
  local ok=false
  for expected in "$@"; do
    if [[ "${actual}" == "${expected}" ]]; then
      ok=true
      break
    fi
  done
  if ! ${ok}; then
    echo "FAIL: ${label} returned HTTP ${actual}, expected one of: $*" >&2
    echo "Response preview:" >&2
    ssh_run "sed -n '1,40p' /tmp/smoke_body.out" >&2 || true
    exit 1
  fi
}

assert_not_code_in() {
  local actual="$1"
  local label="$2"
  shift 2
  for blocked in "$@"; do
    if [[ "${actual}" == "${blocked}" ]]; then
      echo "FAIL: ${label} returned blocked HTTP ${actual}" >&2
      echo "Response preview:" >&2
      ssh_run "sed -n '1,40p' /tmp/smoke_body.out" >&2 || true
      exit 1
    fi
  done
}

echo "== Services"
ssh_run "systemctl is-active tms-auth-api tms-driver-app-api nginx >/dev/null && echo OK || (systemctl --no-pager --failed; exit 1)"

echo "== Local health checks"
AUTH_HEALTH="$(remote_http_code GET "${AUTH_LOCAL_URL}/actuator/health")"
assert_code_in "${AUTH_HEALTH}" "auth local health" 200
ssh_run "grep -q '\"status\":\"UP\"' /tmp/smoke_body.out"

DRIVER_HEALTH="$(remote_http_code GET "${DRIVER_LOCAL_URL}/actuator/health")"
assert_code_in "${DRIVER_HEALTH}" "driver-app local health" 200
ssh_run "grep -q '\"status\":\"UP\"' /tmp/smoke_body.out"

echo "== Nginx config"
ssh_run "nginx -t >/dev/null && echo OK"

echo "== Public routing checks"
# Auth-owned routes should exist and not 404/502.
# Use /api/auth/login as a stable probe: empty payload should return 4xx from app layer (not nginx 404/502).
AUTH_LOGIN_CODE="$(remote_http_code POST "${PUBLIC_URL}/api/auth/login" '{}')"
assert_not_code_in "${AUTH_LOGIN_CODE}" "public /api/auth/login" 404 502 503

AUTH_DEVICE_CODE="$(remote_http_code POST "${PUBLIC_URL}/api/driver/device/register" '{}')"
assert_not_code_in "${AUTH_DEVICE_CODE}" "public /api/driver/device/register" 404 502 503

# Driver-app-owned routes should exist and not 404/502.
DRIVER_LOC_CODE="$(remote_http_code POST "${PUBLIC_URL}/api/driver/location" '{}')"
assert_not_code_in "${DRIVER_LOC_CODE}" "public /api/driver/location" 404 502 503

DRIVER_APP_CODE="$(remote_http_code GET "${PUBLIC_URL}/api/driver-app/home-layout")"
assert_not_code_in "${DRIVER_APP_CODE}" "public /api/driver-app/home-layout" 404 502 503

DRIVER_BOOTSTRAP_CODE="$(remote_http_code GET "${PUBLIC_URL}/api/driver-app/bootstrap")"
assert_not_code_in "${DRIVER_BOOTSTRAP_CODE}" "public /api/driver-app/bootstrap" 404 502 503

DRIVER_SETTINGS_CODE="$(remote_http_code GET "${PUBLIC_URL}/api/user-settings")"
assert_not_code_in "${DRIVER_SETTINGS_CODE}" "public /api/user-settings" 404 502 503

WS_INFO_CODE="$(remote_http_code GET "${PUBLIC_URL}/ws-sockjs/info?token=SMOKE_TEST_TOKEN")"
assert_code_in "${WS_INFO_CODE}" "public /ws-sockjs/info" 200

echo "MICROSERVICE_ROUTING_SMOKE_OK"
