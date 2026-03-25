#!/usr/bin/env bash
set -euo pipefail

# Post-deploy smoke check for dynamic driver-app policy guardrails.
# Verifies:
# - admin auth token can be obtained (or provided)
# - valid dynamic policy payload is accepted
# - invalid dynamic policy payload is rejected (HTTP 400)
#
# Usage:
#   ./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
#     --vps root@1.2.3.4 --ssh-key ~/.ssh/id_ed25519 \
#     --admin-username superadmin --admin-password '***'
#
#   SSHPASS='...' ./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
#     --vps root@1.2.3.4 --password-auth --admin-token 'eyJ...'

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

PUBLIC_URL="https://svtms.svtrucking.biz"
LOGIN_PATH="/api/auth/login"
SETTINGS_VALUE_PATH="/api/admin/settings/value"

ADMIN_USERNAME=""
ADMIN_PASSWORD=""
ADMIN_TOKEN=""

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--public-url URL] [--login-path /api/auth/login]
          [--settings-value-path /api/admin/settings/value]
          [--admin-token TOKEN | --admin-username USER --admin-password PASS]

Notes:
- For --password-auth (SSH), export SSHPASS in your shell.
- Admin credentials/token are for API auth and are separate from SSH auth.
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
    --login-path) LOGIN_PATH="${2:-}"; shift 2 ;;
    --settings-value-path) SETTINGS_VALUE_PATH="${2:-}"; shift 2 ;;
    --admin-username) ADMIN_USERNAME="${2:-}"; shift 2 ;;
    --admin-password) ADMIN_PASSWORD="${2:-}"; shift 2 ;;
    --admin-token) ADMIN_TOKEN="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${VPS}" ]]; then
  echo "ERROR: --vps is required" >&2
  usage
fi

if [[ -z "${ADMIN_TOKEN}" && ( -z "${ADMIN_USERNAME}" || -z "${ADMIN_PASSWORD}" ) ]]; then
  echo "ERROR: provide --admin-token or (--admin-username and --admin-password)" >&2
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

remote_http_code() {
  local method="$1"
  local url="$2"
  local out_file="$3"
  local auth="${4:-}"
  local body="${5:-}"
  local code
  if [[ -n "${auth}" && -n "${body}" ]]; then
    code="$(ssh_run "curl -sS -o '${out_file}' -w '%{http_code}' -X ${method} -H 'Content-Type: application/json' -H 'Authorization: Bearer ${auth}' --data '${body}' '${url}' || true")"
  elif [[ -n "${auth}" ]]; then
    code="$(ssh_run "curl -sS -o '${out_file}' -w '%{http_code}' -X ${method} -H 'Authorization: Bearer ${auth}' '${url}' || true")"
  elif [[ -n "${body}" ]]; then
    code="$(ssh_run "curl -sS -o '${out_file}' -w '%{http_code}' -X ${method} -H 'Content-Type: application/json' --data '${body}' '${url}' || true")"
  else
    code="$(ssh_run "curl -sS -o '${out_file}' -w '%{http_code}' -X ${method} '${url}' || true")"
  fi
  echo "${code}"
}

assert_code() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  local out_file="$4"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "FAIL: ${label} returned HTTP ${actual}, expected ${expected}" >&2
    echo "Response preview:" >&2
    ssh_run "sed -n '1,60p' '${out_file}'" >&2 || true
    exit 1
  fi
}

echo "== Service baseline"
ssh_run "systemctl is-active tms-auth-api tms-driver-app-api nginx >/dev/null && echo OK || (systemctl --no-pager --failed; exit 1)"

if [[ -z "${ADMIN_TOKEN}" ]]; then
  echo "== Fetch admin token"
  login_payload="{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}"
  login_code="$(remote_http_code POST "${PUBLIC_URL}${LOGIN_PATH}" /tmp/dynamic_policy_login.out "" "${login_payload}")"
  assert_code "${login_code}" "200" "auth login" "/tmp/dynamic_policy_login.out"

  ADMIN_TOKEN="$(ssh_run "grep -o '\"token\":\"[^\"]*\"' /tmp/dynamic_policy_login.out | head -n1 | sed 's/\"token\":\"//;s/\"$//'")"
  if [[ -z "${ADMIN_TOKEN}" ]]; then
    ADMIN_TOKEN="$(ssh_run "grep -o '\"accessToken\":\"[^\"]*\"' /tmp/dynamic_policy_login.out | head -n1 | sed 's/\"accessToken\":\"//;s/\"$//'")"
  fi
  if [[ -z "${ADMIN_TOKEN}" ]]; then
    echo "FAIL: unable to parse admin token from login response" >&2
    ssh_run "sed -n '1,80p' /tmp/dynamic_policy_login.out" >&2 || true
    exit 1
  fi
fi

echo "== Validate accepted policy payload"
valid_payload='{"groupCode":"app.policies","keyCode":"nav.home.quick_actions","scope":"GLOBAL","value":["my_trips","incident_report"],"reason":"dynamic-policy-smoke-valid"}'
valid_code="$(remote_http_code POST "${PUBLIC_URL}${SETTINGS_VALUE_PATH}" /tmp/dynamic_policy_valid.out "${ADMIN_TOKEN}" "${valid_payload}")"
assert_code "${valid_code}" "200" "valid dynamic policy upsert" "/tmp/dynamic_policy_valid.out"

echo "== Validate rejected policy payload"
invalid_payload='{"groupCode":"app.policies","keyCode":"nav.home.quick_actions","scope":"GLOBAL","value":["my_trips","invalid_action_smoke"],"reason":"dynamic-policy-smoke-invalid"}'
invalid_code="$(remote_http_code POST "${PUBLIC_URL}${SETTINGS_VALUE_PATH}" /tmp/dynamic_policy_invalid.out "${ADMIN_TOKEN}" "${invalid_payload}")"
assert_code "${invalid_code}" "400" "invalid dynamic policy upsert" "/tmp/dynamic_policy_invalid.out"

echo "DYNAMIC_DRIVER_POLICY_SMOKE_OK"
