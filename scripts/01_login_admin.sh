#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
TOKEN="${TOKEN:-}"
ADMIN_USER="${ADMIN_USER:-qa_admin}"
ADMIN_PASS="${ADMIN_PASS:-password}"

resp=$(curl -s -X POST "${BASE_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}")

echo "$resp" | python3 -m json.tool

token=$(python3 - <<'PY' <<<"$resp"
import json,sys
try:
    data=json.load(sys.stdin)
    token=data.get('data',{}).get('token') or data.get('data',{}).get('accessToken')
    if token:
        print(token)
except Exception:
    pass
PY
)

if [ -n "$token" ]; then
  echo "\nexport TOKEN=$token"
else
  echo "\nNo token found in response. Check credentials or response format."
fi
