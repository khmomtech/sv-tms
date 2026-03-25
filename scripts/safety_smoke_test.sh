#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api}"
TOKEN="${TOKEN:-}"
DRIVER_ID="${DRIVER_ID:-}"
VEHICLE_ID="${VEHICLE_ID:-}"
DATE="${DATE:-}"
WRITE=false
SUBMIT=false
ADMIN=false

usage() {
  cat <<'EOF'
Safety Smoke Test (curl-based)

Usage:
  scripts/safety_smoke_test.sh [options]

Options:
  --base <url>       API base URL (default: http://localhost:8080/api)
  --token <jwt>      JWT access token (or set TOKEN env)
  --driver <id>      Driver ID (for eligibility check)
  --vehicle <id>     Vehicle ID (required for driver endpoints)
  --date <yyyy-mm-dd> Date for eligibility/history (default: today)
  --write            POST draft after GET today
  --submit           Submit after draft (implies --write)
  --admin            Call admin list/detail (requires admin token)
  -h|--help          Show help

Environment variables:
  API_BASE_URL, TOKEN, DRIVER_ID, VEHICLE_ID, DATE

Examples:
  API_BASE_URL=http://localhost:8080/api TOKEN=... VEHICLE_ID=1 \\
    scripts/safety_smoke_test.sh

  scripts/safety_smoke_test.sh --vehicle 1 --write
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) API_BASE_URL="$2"; shift ;;
    --token) TOKEN="$2"; shift ;;
    --driver) DRIVER_ID="$2"; shift ;;
    --vehicle) VEHICLE_ID="$2"; shift ;;
    --date) DATE="$2"; shift ;;
    --write) WRITE=true ;;
    --submit) SUBMIT=true; WRITE=true ;;
    --admin) ADMIN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ -z "${DATE}" ]]; then
  if date -v -1d >/dev/null 2>&1; then
    DATE="$(date +%F)"
  else
    DATE="$(date +%F)"
  fi
fi

echo "API_BASE_URL: $API_BASE_URL"
echo "DATE: $DATE"
echo "TOKEN: ${TOKEN:+(set)}${TOKEN:-<empty>}"
echo "DRIVER_ID: ${DRIVER_ID:-<empty>}"
echo "VEHICLE_ID: ${VEHICLE_ID:-<empty>}"
echo "WRITE: $WRITE | SUBMIT: $SUBMIT | ADMIN: $ADMIN"
echo "------------------------------------------------------------"

LAST_STATUS=""
LAST_BODY=""

request() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  local tmp
  tmp="$(mktemp)"
  local args=(-sS -o "$tmp" -w "%{http_code}" -X "$method" "$url")
  if [[ -n "$TOKEN" ]]; then
    args+=(-H "Authorization: Bearer $TOKEN")
  fi
  if [[ -n "$data" ]]; then
    args+=(-H "Content-Type: application/json" -d "$data")
  fi
  local status
  status="$(curl "${args[@]}")"
  LAST_STATUS="$status"
  LAST_BODY="$(cat "$tmp")"
  rm -f "$tmp"
  echo "-> $method $url [$status]"
  if [[ -n "$LAST_BODY" ]]; then
    echo "$LAST_BODY" | head -c 1200
    if [[ ${#LAST_BODY} -gt 1200 ]]; then
      echo
      echo "...(truncated)"
    fi
  else
    echo "(no body)"
  fi
  echo
}

extract_id() {
  local pybin
  pybin="$(command -v python3 || command -v python || true)"
  if [[ -z "$pybin" ]]; then
    echo ""
    return
  fi
  "$pybin" -c 'import json,sys
raw=sys.stdin.read().strip()
if not raw:
    print(""); sys.exit(0)
try:
    obj=json.loads(raw)
except Exception:
    print(""); sys.exit(0)
data=obj.get("data", obj) if isinstance(obj, dict) else obj
if isinstance(data, dict):
    print(data.get("id") or ""); sys.exit(0)
if isinstance(data, list) and data:
    item=data[0]
    if isinstance(item, dict):
        print(item.get("id") or ""); sys.exit(0)
print("")'
}

build_draft_payload() {
  local pybin
  pybin="$(command -v python3 || command -v python || true)"
  if [[ -z "$pybin" ]]; then
    echo "{}"
    return
  fi
  "$pybin" -c 'import json,sys
vehicle_id=sys.argv[1]
check_date=sys.argv[2]
raw=sys.stdin.read().strip()
payload={"vehicleId": int(vehicle_id), "checkDate": check_date, "items": []}
try:
    obj=json.loads(raw)
    data=obj.get("data", obj) if isinstance(obj, dict) else obj
    if isinstance(data, dict):
        if data.get("checkDate"):
            payload["checkDate"]=data["checkDate"]
        if data.get("items"):
            payload["items"]=data["items"]
        if data.get("gpsLat") is not None:
            payload["gpsLat"]=data["gpsLat"]
        if data.get("gpsLng") is not None:
            payload["gpsLng"]=data["gpsLng"]
except Exception:
    pass
print(json.dumps(payload))' "$VEHICLE_ID" "$DATE"
}

if [[ -z "$VEHICLE_ID" ]]; then
  echo "WARN: VEHICLE_ID not set. Driver endpoints will be skipped."
else
  request "GET" "$API_BASE_URL/driver/safety-checks/today?vehicleId=$VEHICLE_ID"

  if $WRITE; then
    payload="$(printf "%s" "$LAST_BODY" | build_draft_payload)"
    request "POST" "$API_BASE_URL/driver/safety-checks/draft" "$payload"
  fi

  if $SUBMIT; then
    safety_id="$(printf "%s" "$LAST_BODY" | extract_id)"
    if [[ -n "$safety_id" ]]; then
      request "POST" "$API_BASE_URL/driver/safety-checks/$safety_id/submit"
    else
      echo "WARN: Could not extract safety_check id to submit."
      echo
    fi
  fi

  request "GET" "$API_BASE_URL/driver/safety-checks?from=$DATE&to=$DATE"
fi

if [[ -n "$DRIVER_ID" && -n "$VEHICLE_ID" ]]; then
  request "GET" "$API_BASE_URL/dispatch/safety-eligibility?driverId=$DRIVER_ID&vehicleId=$VEHICLE_ID&date=$DATE"
else
  echo "WARN: DRIVER_ID or VEHICLE_ID missing. Eligibility check skipped."
  echo
fi

if $ADMIN; then
  request "GET" "$API_BASE_URL/admin/safety-checks?page=0&size=5"
  admin_id="$(printf "%s" "$LAST_BODY" | extract_id)"
  if [[ -n "$admin_id" ]]; then
    request "GET" "$API_BASE_URL/admin/safety-checks/$admin_id"
  else
    echo "WARN: Could not extract admin safety_check id for detail."
    echo
  fi
fi

echo "Done."
