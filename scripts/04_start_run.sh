#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:?TOKEN env var required}"
PM_RUN_ID="${PM_RUN_ID:?PM_RUN_ID env var required}"

curl -s -X POST "${BASE_URL}/api/workshop/pm/runs/${PM_RUN_ID}/start" \
  -H "Authorization: Bearer ${TOKEN}" | python3 -m json.tool
