#!/usr/bin/env bash
set -euo pipefail

# OpenAPI split smoke check for auth-api and driver-app-api on VPS.
# Verifies:
# - both local OpenAPI docs are reachable
# - auth-api owns auth/device routes and does not expose driver-app routes
# - driver-app-api owns driver routes and does not expose auth routes
#
# Usage:
#   ./deploy/post_deploy_openapi_split_smoke_vps.sh --vps root@1.2.3.4 --ssh-key ~/.ssh/id_ed25519
#   SSHPASS='...' ./deploy/post_deploy_openapi_split_smoke_vps.sh --vps root@1.2.3.4 --password-auth

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

AUTH_LOCAL_URL="http://127.0.0.1:8083"
DRIVER_LOCAL_URL="http://127.0.0.1:8084"

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--auth-local-url URL] [--driver-local-url URL]

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

require_path_in() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! ssh_run "grep -q '${pattern}' '${file}'"; then
    echo "FAIL: missing ${label} (${pattern}) in ${file}" >&2
    exit 1
  fi
}

forbid_path_in() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ssh_run "grep -q '${pattern}' '${file}'"; then
    echo "FAIL: unexpected ${label} (${pattern}) found in ${file}" >&2
    exit 1
  fi
}

echo "== Fetch OpenAPI docs"
ssh_run "curl -fsS '${AUTH_LOCAL_URL}/v3/api-docs' -o /tmp/openapi-auth.json"
ssh_run "curl -fsS '${DRIVER_LOCAL_URL}/v3/api-docs' -o /tmp/openapi-driver.json"

echo "== Auth ownership checks"
require_path_in /tmp/openapi-auth.json '\"/api/auth/' 'auth routes'
require_path_in /tmp/openapi-auth.json '\"/api/driver/device/' 'driver device auth routes'
forbid_path_in /tmp/openapi-auth.json '\"/api/driver-app/' 'driver-app routes in auth'
forbid_path_in /tmp/openapi-auth.json '\"/api/driver/location/' 'driver location routes in auth'

echo "== Driver-app ownership checks"
require_path_in /tmp/openapi-driver.json '\"/api/driver/' 'driver routes'
require_path_in /tmp/openapi-driver.json '\"/api/driver-app/' 'driver-app routes'
require_path_in /tmp/openapi-driver.json '\"/api/user-settings' 'user-settings routes'
forbid_path_in /tmp/openapi-driver.json '\"/api/auth/' 'auth routes in driver-app'
forbid_path_in /tmp/openapi-driver.json '\"/api/driver/device/' 'driver device auth routes in driver-app'

echo "OPENAPI_SPLIT_SMOKE_OK"
