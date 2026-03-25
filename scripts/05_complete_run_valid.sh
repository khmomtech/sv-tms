#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
PM_RUN_ID="${PM_RUN_ID:?PM_RUN_ID env var required}"
CHECKLIST_ITEM_ID1="${CHECKLIST_ITEM_ID1:?CHECKLIST_ITEM_ID1 env var required}"
CHECKLIST_ITEM_ID2="${CHECKLIST_ITEM_ID2:?CHECKLIST_ITEM_ID2 env var required}"
CHECKLIST_ITEM_ID3="${CHECKLIST_ITEM_ID3:?CHECKLIST_ITEM_ID3 env var required}"
CHECKLIST_ITEM_ID4="${CHECKLIST_ITEM_ID4:?CHECKLIST_ITEM_ID4 env var required}"
PERFORMED_KM="${PERFORMED_KM:-196900}"
PERFORMED_AT="${PERFORMED_AT:-2026-02-04T10:00:00}"

payload=$(cat <<JSON
{
  "performedAt": "${PERFORMED_AT}",
  "performedKm": ${PERFORMED_KM},
  "notes": "QA completion",
  "checklistResults": [
    {"checklistItemId": ${CHECKLIST_ITEM_ID1}, "checkedBool": true},
    {"checklistItemId": ${CHECKLIST_ITEM_ID2}, "checkedBool": true},
    {"checklistItemId": ${CHECKLIST_ITEM_ID3}, "checkedBool": true},
    {"checklistItemId": ${CHECKLIST_ITEM_ID4}, "checkedBool": true}
  ]
}
JSON
)

curl -s -X POST "${BASE_URL}/api/workshop/pm/runs/${PM_RUN_ID}/complete" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$payload" | python3 -m json.tool
