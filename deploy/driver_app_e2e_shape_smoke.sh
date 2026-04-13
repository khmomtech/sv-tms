#!/usr/bin/env bash
set -euo pipefail

# Driver app E2E shape smoke:
# - logs in as a real driver
# - verifies login response includes data.user.driverId + token
# - verifies key driver app endpoints are reachable with auth
# - verifies wrapped/data or page/content response shapes expected by the app
#
# Usage:
#   DRIVER_USERNAME=070396749 DRIVER_PASSWORD=123456 ./deploy/driver_app_e2e_shape_smoke.sh
#   BASE_URL=https://svtms.svtrucking.biz/api DRIVER_USERNAME=... DRIVER_PASSWORD=... ./deploy/driver_app_e2e_shape_smoke.sh

BASE_URL="${BASE_URL:-https://svtms.svtrucking.biz/api}"
DRIVER_USERNAME="${DRIVER_USERNAME:-}"
DRIVER_PASSWORD="${DRIVER_PASSWORD:-}"
DEVICE_ID="${DEVICE_ID:-codex-e2e-device}"

if [[ -z "${DRIVER_USERNAME}" || -z "${DRIVER_PASSWORD}" ]]; then
  echo "ERROR: set DRIVER_USERNAME and DRIVER_PASSWORD" >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

banner() {
  printf '\n== %s ==\n' "$1"
}

http_json() {
  local method="$1"
  local url="$2"
  local out_file="$3"
  local token="${4:-}"
  local body="${5:-}"
  local code

  if [[ -n "${token}" && -n "${body}" ]]; then
    code="$(curl -sS --max-time 20 -o "${out_file}" -w '%{http_code}' \
      -X "${method}" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${token}" \
      --data "${body}" \
      "${url}" || true)"
  elif [[ -n "${token}" ]]; then
    code="$(curl -sS --max-time 20 -o "${out_file}" -w '%{http_code}' \
      -X "${method}" \
      -H "Authorization: Bearer ${token}" \
      "${url}" || true)"
  elif [[ -n "${body}" ]]; then
    code="$(curl -sS --max-time 20 -o "${out_file}" -w '%{http_code}' \
      -X "${method}" \
      -H 'Content-Type: application/json' \
      --data "${body}" \
      "${url}" || true)"
  else
    code="$(curl -sS --max-time 20 -o "${out_file}" -w '%{http_code}' \
      -X "${method}" \
      "${url}" || true)"
  fi

  echo "${code}"
}

assert_code() {
  local actual="$1"
  local label="$2"
  local out_file="$3"
  shift 3
  for expected in "$@"; do
    if [[ "${actual}" == "${expected}" ]]; then
      return 0
    fi
  done
  echo "FAIL: ${label} returned HTTP ${actual}, expected one of: $*" >&2
  sed -n '1,80p' "${out_file}" >&2 || true
  exit 1
}

assert_shape() {
  local out_file="$1"
  local mode="$2"
  local label="$3"
  python3 - "$out_file" "$mode" "$label" <<'PY'
import json, sys
path, mode, label = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as fh:
    payload = json.load(fh)

if mode == 'login':
    assert isinstance(payload, dict), f"{label}: root must be object"
    assert isinstance(payload.get('data'), dict), f"{label}: missing data object"
    data = payload['data']
    assert isinstance(data.get('user'), dict), f"{label}: missing data.user"
    assert data.get('token') or data.get('accessToken'), f"{label}: missing token"
    assert data['user'].get('driverId'), f"{label}: missing user.driverId"
elif mode == 'wrapped-data':
    assert isinstance(payload, dict), f"{label}: root must be object"
    assert 'data' in payload, f"{label}: missing data"
elif mode == 'page-or-wrapped-page':
    assert isinstance(payload, dict), f"{label}: root must be object"
    page = payload.get('data') if isinstance(payload.get('data'), dict) else payload
    assert isinstance(page, dict), f"{label}: page must be object"
    assert 'content' in page, f"{label}: missing content"
    assert isinstance(page['content'], list), f"{label}: content must be list"
else:
    raise AssertionError(f"Unknown mode: {mode}")
PY
}

banner "Driver Login"
LOGIN_FILE="${TMP_DIR}/login.json"
LOGIN_BODY="$(printf '{"username":"%s","password":"%s","deviceId":"%s"}' "${DRIVER_USERNAME}" "${DRIVER_PASSWORD}" "${DEVICE_ID}")"
LOGIN_CODE="$(http_json POST "${BASE_URL}/auth/driver/login" "${LOGIN_FILE}" "" "${LOGIN_BODY}")"
assert_code "${LOGIN_CODE}" "driver login" "${LOGIN_FILE}" 200
assert_shape "${LOGIN_FILE}" "login" "driver login"

TOKEN="$(python3 - "${LOGIN_FILE}" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    payload = json.load(fh)
print((payload['data'].get('token') or payload['data'].get('accessToken') or '').strip())
PY
)"

DRIVER_ID="$(python3 - "${LOGIN_FILE}" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    payload = json.load(fh)
print(payload['data']['user']['driverId'])
PY
)"

probe_page() {
  local path="$1"
  local label="$2"
  local file="${TMP_DIR}/$(echo "${label}" | tr ' /' '__').json"
  local code
  code="$(http_json GET "${BASE_URL}${path}" "${file}" "${TOKEN}")"
  assert_code "${code}" "${label}" "${file}" 200
  assert_shape "${file}" "page-or-wrapped-page" "${label}"
  echo "PASS: ${label}"
}

probe_wrapped() {
  local path="$1"
  local label="$2"
  local file="${TMP_DIR}/$(echo "${label}" | tr ' /' '__').json"
  local code
  code="$(http_json GET "${BASE_URL}${path}" "${file}" "${TOKEN}")"
  assert_code "${code}" "${label}" "${file}" 200
  assert_shape "${file}" "wrapped-data" "${label}"
  echo "PASS: ${label}"
}

banner "Dispatch APIs"
probe_page "/driver/dispatches/me/pending?sort=startTime,DESC&page=0&size=100" "dispatch me pending"
probe_page "/driver/dispatches/me/in-progress?sort=startTime,DESC&page=0&size=100" "dispatch me in-progress"
probe_page "/driver/dispatches/me/completed?sort=endTime,DESC&page=0&size=100" "dispatch me completed"
probe_page "/driver/dispatches/driver/${DRIVER_ID}?page=0&size=20" "dispatch by driver id"

banner "Driver App APIs"
probe_wrapped "/driver/banners/active" "driver banners active"
probe_wrapped "/driver-app/bootstrap" "driver bootstrap"
probe_wrapped "/driver/me/vehicle" "driver me vehicle"

echo
echo "DRIVER_APP_E2E_SHAPE_SMOKE_OK"
