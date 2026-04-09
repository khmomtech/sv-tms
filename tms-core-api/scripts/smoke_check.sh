#!/usr/bin/env bash
# Simple smoke checks for backend API used by Driver App
# Usage: ./smoke_check.sh <base-url> <username> <password> [deviceId]
# Example: ./smoke_check.sh http://localhost:8080 reviewer@test.sv Review!234 emulator-1234

set -euo pipefail
BASE=${1:-http://localhost:8080}
USER=${2:-reviewer@test.sv}
PASS=${3:-Review!234}
DEVICE_ID=${4:-smoke-device-1}

echo "[SMOKE] Base URL: $BASE"

# 1) Health
echo -n "[SMOKE] Health API... "
if curl -fsS "$BASE/actuator/health" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAIL (actuator/health)"; exit 2
fi

# 2) Driver login
echo "[SMOKE] Driver login -> /api/auth/driver/login"
LOGIN_RESP=$(curl -s -X POST "$BASE/api/auth/driver/login" \
  -H 'Content-Type: application/json' \
  -d "{ \"username\": \"$USER\", \"password\": \"$PASS\", \"deviceId\": \"$DEVICE_ID\" }")

if echo "$LOGIN_RESP" | jq -e '.success==true' >/dev/null 2>&1; then
  echo "[SMOKE] Login OK"
else
  echo "[SMOKE] Login FAILED: $LOGIN_RESP"; exit 3
fi

TOKEN=$(echo "$LOGIN_RESP" | jq -r '.data.token')
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "[SMOKE] No token returned"; exit 4
fi

# 3) Get jobs
echo -n "[SMOKE] GET /api/driver/jobs... "
JOBS_RESP=$(curl -s -X GET "$BASE/api/driver/jobs" -H "Authorization: Bearer $TOKEN")
if echo "$JOBS_RESP" | jq -e '.success==true' >/dev/null 2>&1; then
  echo "OK"
  echo "[SMOKE] Sample jobs output:" 
  echo "$JOBS_RESP" | jq '.data | .[0:2]'
else
  echo "FAIL (jobs): $JOBS_RESP"; exit 5
fi

echo "[SMOKE] All checks passed."
