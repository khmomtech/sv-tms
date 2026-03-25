#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
PM_RUN_ID="${PM_RUN_ID:?PM_RUN_ID env var required}"
CHECKLIST_ITEM_ID1="${CHECKLIST_ITEM_ID1:?CHECKLIST_ITEM_ID1 env var required}"
PERFORMED_KM="${PERFORMED_KM:-196920}"
PERFORMED_AT="${PERFORMED_AT:-2026-02-04T10:30:00}"

payload=$(cat <<JSON
{
  "performedAt": "${PERFORMED_AT}",
  "performedKm": ${PERFORMED_KM},
  "notes": "QA invalid completion",
  "checklistResults": [
    {"checklistItemId": ${CHECKLIST_ITEM_ID1}, "checkedBool": true}
  ]
}
JSON
)

curl -s -X POST "${BASE_URL}/api/workshop/pm/runs/${PM_RUN_ID}/complete" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$payload" | python3 -m json.tool
