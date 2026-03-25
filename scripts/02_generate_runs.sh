#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
LOOKAHEAD_DAYS="${LOOKAHEAD_DAYS:-7}"

curl -s -X POST "${BASE_URL}/api/admin/pm/runs/generate" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"lookaheadDays\": ${LOOKAHEAD_DAYS}}" | python3 -m json.tool
