#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api}"

DRIVER_USERNAME="${DRIVER_USERNAME:-}"
DRIVER_PASSWORD="${DRIVER_PASSWORD:-}"
DEVICE_ID="${DEVICE_ID:-}"
DRIVER_ID="${DRIVER_ID:-}"
VEHICLE_ID="${VEHICLE_ID:-}"
DATE="${DATE:-}"
WRITE="${WRITE:-true}"
SUBMIT="${SUBMIT:-false}"

usage() {
  cat <<'EOF'
Safety E2E Driver Test (auto login + smoke test)

Required env:
  DRIVER_USERNAME   Driver username/phone
  DRIVER_PASSWORD   Driver password
  DEVICE_ID         Device ID (required by /auth/driver/login unless skip-device-check is enabled)
  DRIVER_ID         Driver ID (for eligibility check)
  VEHICLE_ID        Vehicle ID (for today safety check)

Optional env:
  API_BASE_URL      (default: http://localhost:8080/api)
  DATE              (default: today)
  WRITE             true|false (default: true)
  SUBMIT            true|false (default: false)

Example:
  DRIVER_USERNAME=0167964508 \
  DRIVER_PASSWORD=123456 \
  DEVICE_ID=abc123 \
  DRIVER_ID=1 \
  VEHICLE_ID=1 \
  API_BASE_URL=http://192.168.0.94:8080/api \
  scripts/safety_e2e_driver_test.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$DEVICE_ID" ]]; then
  if command -v adb >/dev/null 2>&1; then
    DEVICE_ID="$(adb get-serialno 2>/dev/null | tr -d '\r')"
    if [[ "$DEVICE_ID" == "unknown" ]]; then
      DEVICE_ID=""
    fi
  fi
fi

if [[ -z "$DRIVER_USERNAME" || -z "$DRIVER_PASSWORD" || -z "$DEVICE_ID" ]]; then
  echo "Missing required env. See --help."
  echo "Resolved DEVICE_ID: ${DEVICE_ID:-<empty>}"
  exit 1
fi

if [[ -z "${DATE}" ]]; then
  DATE="$(date +%F)"
fi

echo "Logging in as driver..."
LOGIN_RESP="$(curl -sS -X POST "$API_BASE_URL/auth/driver/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$DRIVER_USERNAME\",\"password\":\"$DRIVER_PASSWORD\",\"deviceId\":\"$DEVICE_ID\"}")"

PYBIN="$(command -v python3 || command -v python || true)"
if [[ -z "$PYBIN" ]]; then
  echo "python3 not found. Please install Python."
  exit 1
fi

PARSED="$(printf '%s' "$LOGIN_RESP" | "$PYBIN" -c 'import json,sys
raw=sys.stdin.read().strip()
try:
    obj=json.loads(raw)
except Exception:
    print("")
    sys.exit(0)
data=obj.get("data", obj) if isinstance(obj, dict) else obj
if isinstance(data, dict):
    payload=data.get("data", data)
    if isinstance(payload, dict):
        token=payload.get("token","")
        user=payload.get("user", {})
        driver_id=user.get("driverId", "")
        vehicle_id=user.get("vehicleId", "")
        print(f"{token}||{driver_id}||{vehicle_id}")')"

TOKEN="${PARSED%%||*}"
REST="${PARSED#*||}"
LOGIN_DRIVER_ID="${REST%%||*}"
LOGIN_VEHICLE_ID="${REST#*||}"

if [[ -z "$TOKEN" ]]; then
  echo "Login failed or token missing."
  echo "Response:"
  echo "$LOGIN_RESP" | head -c 1200
  echo
  exit 1
fi

if [[ -z "$DRIVER_ID" && -n "$LOGIN_DRIVER_ID" ]]; then
  DRIVER_ID="$LOGIN_DRIVER_ID"
fi
if [[ -z "$VEHICLE_ID" && -n "$LOGIN_VEHICLE_ID" ]]; then
  VEHICLE_ID="$LOGIN_VEHICLE_ID"
fi

if [[ -z "$DRIVER_ID" ]]; then
  echo "Missing DRIVER_ID (not provided and not found in login response)."
  echo "Login response snippet:"
  echo "$LOGIN_RESP" | head -c 600
  echo
  exit 1
fi

if [[ -z "$VEHICLE_ID" ]]; then
  echo "Vehicle ID missing; attempting to fetch current assignment..."
  ASSIGN_RESP="$(curl -sS -X GET "$API_BASE_URL/driver/current-assignment" \
    -H "Authorization: Bearer $TOKEN")"
  VEHICLE_ID="$(printf '%s' "$ASSIGN_RESP" | "$PYBIN" -c 'import json,sys
raw=sys.stdin.read().strip()
try:
    obj=json.loads(raw)
except Exception:
    print("")
    sys.exit(0)
data=obj.get("data", obj) if isinstance(obj, dict) else obj
if isinstance(data, dict):
    eff=data.get("effectiveVehicle") or data.get("permanentVehicle") or data.get("temporaryVehicle")
    if isinstance(eff, dict):
        vid=eff.get("id") or eff.get("vehicleId") or eff.get("vehicle_id")
        if vid is not None:
            print(vid); sys.exit(0)
    vid=data.get("vehicleId") or data.get("vehicle_id")
    if vid is not None:
        print(vid); sys.exit(0)
print("")')"
fi

if [[ -z "$VEHICLE_ID" ]]; then
  echo "Still missing VEHICLE_ID. Provide VEHICLE_ID manually."
  echo "Assignment response snippet:"
  echo "$ASSIGN_RESP" | head -c 600
  echo
  exit 1
fi

echo "Login OK. Running safety smoke test..."

CMD=("$ROOT_DIR/scripts/safety_smoke_test.sh" "--vehicle" "$VEHICLE_ID" "--driver" "$DRIVER_ID")
if [[ "$WRITE" == "true" ]]; then
  CMD+=("--write")
fi
if [[ "$SUBMIT" == "true" ]]; then
  CMD+=("--submit")
fi

TOKEN="$TOKEN" DATE="$DATE" API_BASE_URL="$API_BASE_URL" "${CMD[@]}"
