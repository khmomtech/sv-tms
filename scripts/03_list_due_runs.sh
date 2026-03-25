#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
VEHICLE_ID="${VEHICLE_ID:-}"

url="${BASE_URL}/api/admin/pm/runs?status=DUE"
if [ -n "$VEHICLE_ID" ]; then
  url="${url}&vehicleId=${VEHICLE_ID}"
fi

curl -s -X GET "$url" \
  -H "Authorization: Bearer ${TOKEN}" | python3 -m json.tool
