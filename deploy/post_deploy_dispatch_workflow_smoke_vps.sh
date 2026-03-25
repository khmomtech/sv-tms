#!/usr/bin/env bash
set -euo pipefail

# Post-deploy dispatch workflow smoke check.
# Verifies:
# - split mobile endpoints respond from the public URL
# - admin resolve endpoint matches expected template binding
# - driver available-actions omit legacy APPROVED path
# - POL/POD metadata is present when LOADED/UNLOADED transitions are exposed
# - KHBL loading-control transitions are not directly executable by driver
#
# Usage:
#   ./deploy/post_deploy_dispatch_workflow_smoke_vps.sh \
#     --public-url https://svtms.svtrucking.biz \
#     --admin-username superadmin --admin-password '***' \
#     --driver-username driver1 --driver-password '***' \
#     --general-dispatch-id 123 --khbl-dispatch-id 456 \
#     --fallback-dispatch-id 789 --fallback-linked-template LEGACY_KHBL

PUBLIC_URL="https://svtms.svtrucking.biz"
LOGIN_PATH="/api/auth/login"

ADMIN_USERNAME=""
ADMIN_PASSWORD=""
ADMIN_TOKEN=""

DRIVER_USERNAME=""
DRIVER_PASSWORD=""
DRIVER_TOKEN=""

GENERAL_DISPATCH_ID=""
KHBL_DISPATCH_ID=""
FALLBACK_DISPATCH_ID=""
FALLBACK_LINKED_TEMPLATE=""

usage() {
  cat <<EOF
Usage: $0 [--public-url URL] [--login-path /api/auth/login]
          [--admin-token TOKEN | --admin-username USER --admin-password PASS]
          [--driver-token TOKEN | --driver-username USER --driver-password PASS]
          [--general-dispatch-id ID] [--khbl-dispatch-id ID]
          [--fallback-dispatch-id ID --fallback-linked-template CODE]

Notes:
- Provide at least one dispatch id.
- Admin credentials/token are used for /api/admin/dispatch-flow/resolve/{dispatchId}.
- Driver credentials/token are used for bootstrap, user-settings, and available-actions.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public-url) PUBLIC_URL="${2:-}"; shift 2 ;;
    --login-path) LOGIN_PATH="${2:-}"; shift 2 ;;
    --admin-username) ADMIN_USERNAME="${2:-}"; shift 2 ;;
    --admin-password) ADMIN_PASSWORD="${2:-}"; shift 2 ;;
    --admin-token) ADMIN_TOKEN="${2:-}"; shift 2 ;;
    --driver-username) DRIVER_USERNAME="${2:-}"; shift 2 ;;
    --driver-password) DRIVER_PASSWORD="${2:-}"; shift 2 ;;
    --driver-token) DRIVER_TOKEN="${2:-}"; shift 2 ;;
    --general-dispatch-id) GENERAL_DISPATCH_ID="${2:-}"; shift 2 ;;
    --khbl-dispatch-id) KHBL_DISPATCH_ID="${2:-}"; shift 2 ;;
    --fallback-dispatch-id) FALLBACK_DISPATCH_ID="${2:-}"; shift 2 ;;
    --fallback-linked-template) FALLBACK_LINKED_TEMPLATE="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${GENERAL_DISPATCH_ID}" && -z "${KHBL_DISPATCH_ID}" && -z "${FALLBACK_DISPATCH_ID}" ]]; then
  echo "ERROR: provide --general-dispatch-id and/or --khbl-dispatch-id and/or --fallback-dispatch-id" >&2
  usage
fi

if [[ -n "${FALLBACK_DISPATCH_ID}" && -z "${FALLBACK_LINKED_TEMPLATE}" ]]; then
  echo "ERROR: --fallback-linked-template is required when --fallback-dispatch-id is provided" >&2
  usage
fi

if [[ -z "${ADMIN_TOKEN}" && ( -z "${ADMIN_USERNAME}" || -z "${ADMIN_PASSWORD}" ) ]]; then
  echo "ERROR: provide --admin-token or (--admin-username and --admin-password)" >&2
  usage
fi

if [[ -z "${DRIVER_TOKEN}" && ( -z "${DRIVER_USERNAME}" || -z "${DRIVER_PASSWORD}" ) ]]; then
  echo "ERROR: provide --driver-token or (--driver-username and --driver-password)" >&2
  usage
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

curl_json() {
  local method="$1"
  local url="$2"
  local out_file="$3"
  local auth="${4:-}"
  local body="${5:-}"
  local code
  if [[ -n "${auth}" && -n "${body}" ]]; then
    code="$(curl -sS -o "${out_file}" -w '%{http_code}' -X "${method}" \
      -H 'Content-Type: application/json' -H "Authorization: Bearer ${auth}" \
      --data "${body}" "${url}" || true)"
  elif [[ -n "${auth}" ]]; then
    code="$(curl -sS -o "${out_file}" -w '%{http_code}' -X "${method}" \
      -H "Authorization: Bearer ${auth}" "${url}" || true)"
  elif [[ -n "${body}" ]]; then
    code="$(curl -sS -o "${out_file}" -w '%{http_code}' -X "${method}" \
      -H 'Content-Type: application/json' --data "${body}" "${url}" || true)"
  else
    code="$(curl -sS -o "${out_file}" -w '%{http_code}' -X "${method}" "${url}" || true)"
  fi
  echo "${code}"
}

assert_code_in() {
  local actual="$1"
  local label="$2"
  local out_file="$3"
  shift 3
  local ok=false
  for expected in "$@"; do
    if [[ "${actual}" == "${expected}" ]]; then
      ok=true
      break
    fi
  done
  if ! ${ok}; then
    echo "FAIL: ${label} returned HTTP ${actual}, expected one of: $*" >&2
    sed -n '1,80p' "${out_file}" >&2 || true
    exit 1
  fi
}

extract_token() {
  local file="$1"
  python3 - "$file" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    payload = json.load(fh)
candidates = [
    payload.get("token"),
    payload.get("accessToken"),
    (payload.get("data") or {}).get("token") if isinstance(payload.get("data"), dict) else None,
    (payload.get("data") or {}).get("accessToken") if isinstance(payload.get("data"), dict) else None,
]
for item in candidates:
    if item:
        print(item)
        sys.exit(0)
sys.exit(1)
PY
}

login_if_needed() {
  local username="$1"
  local password="$2"
  local target_name="$3"
  local out_file="${TMP_DIR}/${target_name}_login.json"
  local payload
  payload="$(printf '{"username":"%s","password":"%s"}' "${username}" "${password}")"
  local code
  code="$(curl_json POST "${PUBLIC_URL}${LOGIN_PATH}" "${out_file}" "" "${payload}")"
  assert_code_in "${code}" "${target_name} login" "${out_file}" 200
  extract_token "${out_file}"
}

json_eval() {
  local file="$1"
  local script="$2"
  python3 - "$file" "$script" <<'PY'
import json, sys
path = sys.argv[1]
script = sys.argv[2]
with open(path, 'r', encoding='utf-8') as fh:
    payload = json.load(fh)
ns = {"payload": payload, "json": json}
exec(script, ns, ns)
PY
}

if [[ -z "${ADMIN_TOKEN}" ]]; then
  echo "== Fetch admin token"
  ADMIN_TOKEN="$(login_if_needed "${ADMIN_USERNAME}" "${ADMIN_PASSWORD}" admin)"
fi

if [[ -z "${DRIVER_TOKEN}" ]]; then
  echo "== Fetch driver token"
  DRIVER_TOKEN="$(login_if_needed "${DRIVER_USERNAME}" "${DRIVER_PASSWORD}" driver)"
fi

echo "== Public mobile endpoint checks"
bootstrap_file="${TMP_DIR}/bootstrap.json"
bootstrap_code="$(curl_json GET "${PUBLIC_URL}/api/driver-app/bootstrap" "${bootstrap_file}" "${DRIVER_TOKEN}")"
assert_code_in "${bootstrap_code}" "driver bootstrap" "${bootstrap_file}" 200
json_eval "${bootstrap_file}" $'assert isinstance(payload.get("user"), dict)\nassert "policies" in payload\n'

settings_file="${TMP_DIR}/user_settings.json"
settings_code="$(curl_json GET "${PUBLIC_URL}/api/user-settings" "${settings_file}" "${DRIVER_TOKEN}")"
assert_code_in "${settings_code}" "driver user-settings" "${settings_file}" 200
json_eval "${settings_file}" $'assert payload.get("success") is True\n'

validate_dispatch() {
  local dispatch_id="$1"
  local expected_template="$2"
  local label="$3"
  local resolve_file="${TMP_DIR}/${label}_resolve.json"
  local actions_file="${TMP_DIR}/${label}_actions.json"

  echo "== Validate ${label} dispatch ${dispatch_id}"
  local resolve_code
  resolve_code="$(curl_json GET "${PUBLIC_URL}/api/admin/dispatch-flow/resolve/${dispatch_id}" "${resolve_file}" "${ADMIN_TOKEN}")"
  assert_code_in "${resolve_code}" "${label} resolve endpoint" "${resolve_file}" 200
  json_eval "${resolve_file}" $'data = payload.get("data") or {}\nassert data.get("resolvedTemplateCode") == "'${expected_template}'"\nassert "APPROVED" not in json.dumps(data.get("availableActions") or [])\n'

  local actions_code
  actions_code="$(curl_json GET "${PUBLIC_URL}/api/driver/dispatches/${dispatch_id}/available-actions" "${actions_file}" "${DRIVER_TOKEN}")"
  assert_code_in "${actions_code}" "${label} available-actions" "${actions_file}" 200
  json_eval "${actions_file}" $'
import json
data = payload.get("data") or {}
actions = data.get("availableActions") or []
blob = json.dumps(actions)
assert "APPROVED" not in blob
for action in actions:
    target = action.get("targetStatus")
    if target == "LOADED":
        assert action.get("requiredInput") == "POL" or action.get("inputRouteHint") == "LOAD_PROOF"
    if target == "UNLOADED":
        assert action.get("requiredInput") == "POD" or action.get("inputRouteHint") == "UNLOAD_PROOF"
'

  if [[ "${expected_template}" == "KHBL" ]]; then
    json_eval "${actions_file}" $'
actions = (payload.get("data") or {}).get("availableActions") or []
targets = {"IN_QUEUE", "LOADING", "LOADED"}
for action in actions:
    if action.get("targetStatus") in targets:
        assert (action.get("allowedForCurrentUser") is False) or (action.get("driverInitiated") is False)
'
  fi
}

if [[ -n "${GENERAL_DISPATCH_ID}" ]]; then
  validate_dispatch "${GENERAL_DISPATCH_ID}" "GENERAL" "general"
fi

if [[ -n "${KHBL_DISPATCH_ID}" ]]; then
  validate_dispatch "${KHBL_DISPATCH_ID}" "KHBL" "khbl"
fi

if [[ -n "${FALLBACK_DISPATCH_ID}" ]]; then
  echo "== Validate fallback dispatch ${FALLBACK_DISPATCH_ID}"
  fallback_resolve_file="${TMP_DIR}/fallback_resolve.json"
  fallback_actions_file="${TMP_DIR}/fallback_actions.json"

  fallback_resolve_code="$(curl_json GET "${PUBLIC_URL}/api/admin/dispatch-flow/resolve/${FALLBACK_DISPATCH_ID}" "${fallback_resolve_file}" "${ADMIN_TOKEN}")"
  assert_code_in "${fallback_resolve_code}" "fallback resolve endpoint" "${fallback_resolve_file}" 200
  json_eval "${fallback_resolve_file}" $'data = payload.get("data") or {}\nassert data.get("linkedTemplateCode") == "'${FALLBACK_LINKED_TEMPLATE}'"\nassert data.get("resolvedTemplateCode") == "GENERAL"\nassert data.get("fallbackToDefault") is True\nassert "APPROVED" not in json.dumps(data.get("availableActions") or [])\n'

  fallback_actions_code="$(curl_json GET "${PUBLIC_URL}/api/driver/dispatches/${FALLBACK_DISPATCH_ID}/available-actions" "${fallback_actions_file}" "${DRIVER_TOKEN}")"
  assert_code_in "${fallback_actions_code}" "fallback available-actions" "${fallback_actions_file}" 200
  json_eval "${fallback_actions_file}" $'data = payload.get("data") or {}\nassert data.get("loadingTypeCode") == "GENERAL"\nassert "APPROVED" not in json.dumps(data.get("availableActions") or [])\n'
fi

echo "DISPATCH_WORKFLOW_SMOKE_OK"
