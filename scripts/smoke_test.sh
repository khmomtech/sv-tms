#!/usr/bin/env bash
set -euo pipefail

# Basic smoke tests for local dev stack (backend + angular)
# - Waits for backend to respond
# - Attempts unauthenticated vehicles API (may be 401)
# - Tries a few candidate admin passwords to get a token
# - If token obtained, hits authenticated vehicles endpoint and reports counts

BASE_URL="http://localhost:8080"
TRIES=60
SLEEP=2

echo "[smoke] Waiting for backend to respond at $BASE_URL..."
for i in $(seq 1 $TRIES); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/admin/vehicles/all" || echo "000")
  if [ "$code" != "000" ]; then
    echo "[smoke] Backend responded: HTTP $code"
    break
  fi
  echo -n "."
  sleep $SLEEP
done
if [ "$code" = "000" ]; then
  echo "[smoke] Backend unreachable after $((TRIES*SLEEP))s" >&2
  exit 2
fi

echo "[smoke] Probe unauthenticated /api/admin/vehicles/all"
resp=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/admin/vehicles/all" || echo -e "\n000")
body=$(echo "$resp" | sed '$d' )
code=$(echo "$resp" | tail -n1)
echo "[smoke] Unauthenticated HTTP $code"
if [ "$code" = "200" ]; then
  approx=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  echo "[smoke] Vehicles (approx) without auth: $approx"
else
  echo "[smoke] Endpoint requires auth or returned $code. Will attempt admin login." 
fi

# Try candidate admin passwords (assumption: an 'admin' user may exist in seeded DB).
USERNAME=admin
PASSWORDS="admin password changeme admin123 secret"
TOKEN=""
for p in $PASSWORDS; do
  echo "[smoke] Trying login $USERNAME / $p..."
  res=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$p\"}" "$BASE_URL/api/auth/login" || echo "")
  token=$(echo "$res" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  if [ -n "$token" ]; then
    TOKEN=$token
    echo "[smoke] Got token with password '$p'"
    break
  fi
done
if [ -z "$TOKEN" ]; then
  echo "[smoke] Admin login failed with candidate passwords (this is OK if admin password is different)."
else
  echo "[smoke] Token obtained, calling authenticated vehicles API..."
  auth_resp=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/admin/vehicles/all")
  auth_cnt=$(echo "$auth_resp" | grep -o '"id"' | wc -l | tr -d ' ')
  echo "[smoke] Vehicles (approx) with auth: $auth_cnt"
fi

echo "[smoke] Done"
exit 0
