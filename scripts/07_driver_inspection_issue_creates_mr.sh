#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
VEHICLE_ID="${VEHICLE_ID:?VEHICLE_ID env var required}"

payload=$(cat <<JSON
{
  "vehicleId": ${VEHICLE_ID},
  "notes": "QA inspection issue",
  "items": [
    {
      "category": "Brakes",
      "itemKey": "BRAKE_AIR",
      "itemLabelKm": "Brake air pressure",
      "result": "ISSUE",
      "severity": "HIGH",
      "remark": "Air pressure low"
    }
  ]
}
JSON
)

curl -s -X POST "${BASE_URL}/api/driver/inspections/daily" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$payload" | python3 -m json.tool
