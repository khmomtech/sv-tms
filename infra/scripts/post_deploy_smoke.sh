#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STACK_ROOT=${STACK_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}
COMPOSE_FILE=${COMPOSE_FILE:-$STACK_ROOT/docker-compose.prod.yml}
ENV_FILE=${ENV_FILE:-$STACK_ROOT/.env}
HTTP_BASE=${HTTP_BASE:-http://localhost}
ADMIN_USERNAME=${ADMIN_USERNAME:-}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-}
ADMIN_TOKEN=${ADMIN_TOKEN:-}
TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

request_http_code() {
  local method=$1
  local url=$2
  local output_file=$3
  local auth_token=${4:-}
  local body=${5:-}

  local curl_args=(-sS -L -o "$output_file" -w "%{http_code}" -X "$method")
  if [[ -n "$auth_token" ]]; then
    curl_args+=(-H "Authorization: Bearer $auth_token")
  fi
  if [[ -n "$body" ]]; then
    curl_args+=(-H "Content-Type: application/json" --data "$body")
  fi

  curl "${curl_args[@]}" "$url" || true
}

check_service_health() {
  local service=$1
  local port=$2
  echo "[smoke] $service actuator health"
  compose exec -T "$service" curl -fsS "http://localhost:${port}/actuator/health" >/dev/null
}

assert_code_in() {
  local actual=$1
  local label=$2
  shift 2
  local expected
  for expected in "$@"; do
    if [[ "$actual" == "$expected" ]]; then
      return 0
    fi
  done
  echo "[smoke] FAIL: ${label} returned HTTP ${actual}, expected one of: $*" >&2
  return 1
}

assert_not_code_in() {
  local actual=$1
  local label=$2
  shift 2
  local blocked
  for blocked in "$@"; do
    if [[ "$actual" == "$blocked" ]]; then
      echo "[smoke] FAIL: ${label} returned blocked HTTP ${actual}" >&2
      return 1
    fi
  done
}

require_path_in_file() {
  local file=$1
  local pattern=$2
  local label=$3
  if ! grep -q "$pattern" "$file"; then
    echo "[smoke] FAIL: missing ${label} (${pattern})" >&2
    return 1
  fi
}

forbid_path_in_file() {
  local file=$1
  local pattern=$2
  local label=$3
  if grep -q "$pattern" "$file"; then
    echo "[smoke] FAIL: unexpected ${label} (${pattern})" >&2
    return 1
  fi
}

check_service_health core-api 8080
check_service_health auth-api 8083
check_service_health driver-app-api 8084
check_service_health telematics-api 8082
check_service_health safety-api 8087
check_service_health message-api 8088
check_service_health api-gateway 8086

echo "[smoke] public routing"
ROOT_CODE=$(request_http_code GET "${HTTP_BASE}/" "$TMP_DIR/root.out")
assert_code_in "$ROOT_CODE" "nginx root" 200

GATEWAY_HEALTH_CODE=$(request_http_code GET "${HTTP_BASE}/actuator/health" "$TMP_DIR/gateway-health.out")
assert_code_in "$GATEWAY_HEALTH_CODE" "gateway health" 200

AUTH_LOGIN_CODE=$(request_http_code POST "${HTTP_BASE}/api/auth/login" "$TMP_DIR/auth-login.out" "" '{}')
assert_not_code_in "$AUTH_LOGIN_CODE" "public /api/auth/login" 404 502 503

AUTH_DEVICE_CODE=$(request_http_code POST "${HTTP_BASE}/api/driver/device/register" "$TMP_DIR/auth-device.out" "" '{}')
assert_not_code_in "$AUTH_DEVICE_CODE" "public /api/driver/device/register" 404 502 503

DRIVER_LOC_CODE=$(request_http_code POST "${HTTP_BASE}/api/driver/location/update" "$TMP_DIR/driver-location.out" "" '{}')
assert_not_code_in "$DRIVER_LOC_CODE" "public /api/driver/location/update" 404 502 503

DRIVER_APP_CODE=$(request_http_code GET "${HTTP_BASE}/api/driver-app/home-layout" "$TMP_DIR/driver-app-home.out")
assert_not_code_in "$DRIVER_APP_CODE" "public /api/driver-app/home-layout" 404 502 503

DRIVER_BOOTSTRAP_CODE=$(request_http_code GET "${HTTP_BASE}/api/driver-app/bootstrap" "$TMP_DIR/driver-bootstrap.out")
assert_not_code_in "$DRIVER_BOOTSTRAP_CODE" "public /api/driver-app/bootstrap" 404 502 503

DRIVER_SETTINGS_CODE=$(request_http_code GET "${HTTP_BASE}/api/user-settings" "$TMP_DIR/driver-settings.out")
assert_not_code_in "$DRIVER_SETTINGS_CODE" "public /api/user-settings" 404 502 503

WS_INFO_CODE=$(request_http_code GET "${HTTP_BASE}/ws-sockjs/info?token=SMOKE_TEST_TOKEN" "$TMP_DIR/ws-info.out")
assert_code_in "$WS_INFO_CODE" "public /ws-sockjs/info" 200
echo "MICROSERVICE_ROUTING_SMOKE_OK"

echo "[smoke] openapi split"
compose exec -T auth-api curl -fsS "http://localhost:8083/v3/api-docs" > "$TMP_DIR/openapi-auth.json"
compose exec -T driver-app-api curl -fsS "http://localhost:8084/v3/api-docs" > "$TMP_DIR/openapi-driver.json"

require_path_in_file "$TMP_DIR/openapi-auth.json" '"/api/auth/' "auth routes"
require_path_in_file "$TMP_DIR/openapi-auth.json" '"/api/driver/device/' "driver device auth routes"
forbid_path_in_file "$TMP_DIR/openapi-auth.json" '"/api/driver-app/' "driver-app routes in auth"
forbid_path_in_file "$TMP_DIR/openapi-auth.json" '"/api/driver/location/' "driver location routes in auth"

require_path_in_file "$TMP_DIR/openapi-driver.json" '"/api/driver/' "driver routes"
require_path_in_file "$TMP_DIR/openapi-driver.json" '"/api/driver-app/' "driver-app routes"
require_path_in_file "$TMP_DIR/openapi-driver.json" '"/api/user-settings' "user-settings routes"
forbid_path_in_file "$TMP_DIR/openapi-driver.json" '"/api/auth/' "auth routes in driver-app"
forbid_path_in_file "$TMP_DIR/openapi-driver.json" '"/api/driver/device/' "driver device auth routes in driver-app"
echo "OPENAPI_SPLIT_SMOKE_OK"

if [[ -z "$ADMIN_TOKEN" && -n "$ADMIN_USERNAME" && -n "$ADMIN_PASSWORD" ]]; then
  echo "[smoke] fetch admin token"
  LOGIN_PAYLOAD="{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}"
  LOGIN_CODE=$(request_http_code POST "${HTTP_BASE}/api/auth/login" "$TMP_DIR/admin-login.out" "" "$LOGIN_PAYLOAD")
  assert_code_in "$LOGIN_CODE" "admin auth login" 200
  ADMIN_TOKEN=$(grep -o '"token":"[^"]*"' "$TMP_DIR/admin-login.out" | head -n1 | sed 's/"token":"//;s/"$//')
  if [[ -z "$ADMIN_TOKEN" ]]; then
    ADMIN_TOKEN=$(grep -o '"accessToken":"[^"]*"' "$TMP_DIR/admin-login.out" | head -n1 | sed 's/"accessToken":"//;s/"$//')
  fi
fi

if [[ -n "$ADMIN_TOKEN" ]]; then
  echo "[smoke] dynamic driver policy"
  VALID_POLICY_PAYLOAD='{"groupCode":"app.policies","keyCode":"nav.home.quick_actions","scope":"GLOBAL","value":["my_trips","incident_report"],"reason":"dynamic-policy-smoke-valid"}'
  VALID_POLICY_CODE=$(request_http_code POST "${HTTP_BASE}/api/admin/settings/value" "$TMP_DIR/policy-valid.out" "$ADMIN_TOKEN" "$VALID_POLICY_PAYLOAD")
  assert_code_in "$VALID_POLICY_CODE" "valid dynamic policy upsert" 200

  INVALID_POLICY_PAYLOAD='{"groupCode":"app.policies","keyCode":"nav.home.quick_actions","scope":"GLOBAL","value":["my_trips","invalid_action_smoke"],"reason":"dynamic-policy-smoke-invalid"}'
  INVALID_POLICY_CODE=$(request_http_code POST "${HTTP_BASE}/api/admin/settings/value" "$TMP_DIR/policy-invalid.out" "$ADMIN_TOKEN" "$INVALID_POLICY_PAYLOAD")
  assert_code_in "$INVALID_POLICY_CODE" "invalid dynamic policy upsert" 400
  echo "DYNAMIC_DRIVER_POLICY_SMOKE_OK"
else
  echo "[smoke] WARNING: skipping dynamic driver policy smoke because ADMIN_TOKEN or ADMIN_USERNAME/ADMIN_PASSWORD were not provided" >&2
fi

echo "[smoke] OK"
