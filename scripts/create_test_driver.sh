#!/usr/bin/env bash
# Helper to create a test driver, register a driver account (via admin) and add an approved device.
# Assumes docker-compose.dev.yml is running and services use the standard names from the repo.
# - MySQL container name: svtms-mysql
# - DB: svlogistics_tms_db
# - MySQL root password: rootpass
# - Backend: http://localhost:8080

set -euo pipefail

# Configurable values
MYSQL_CONTAINER=svtms-mysql
MYSQL_ROOT_PASS=rootpass
DB_NAME=svlogistics_tms_db
BACKEND_URL=http://localhost:8080

DRIVER_LICENSE=TEST-LIC-001
DRIVER_PHONE='+10000000001'
DRIVER_FIRST='Test'
DRIVER_LAST='Driver'

DEVICE_ID=test-device-001
DEVICE_NAME='Test Device'

# Admin credentials (adjust if you changed admin password)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

echo "Seeding driver row (license=${DRIVER_LICENSE}) into ${DB_NAME}..."
docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p"${MYSQL_ROOT_PASS}" -D ${DB_NAME} <<'SQL'
INSERT INTO drivers (first_name, last_name, license_number, phone, is_active, status, is_partner)
SELECT 'Test', 'Driver', 'TEST-LIC-001', '+10000000001', 1, 'ONLINE', 0
WHERE NOT EXISTS (
  SELECT 1 FROM drivers WHERE license_number = 'TEST-LIC-001'
);

SQL

echo "Fetching driver id..."
DRIVER_ID=$(docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p"${MYSQL_ROOT_PASS}" -D ${DB_NAME} -N -e "SELECT id FROM drivers WHERE license_number='${DRIVER_LICENSE}' LIMIT 1;")
if [ -z "${DRIVER_ID}" ]; then
  echo "Failed to fetch driver id. Aborting." >&2
  exit 2
fi
echo "Driver id = ${DRIVER_ID}"

echo "Requesting admin token..."
RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/login" -H 'Content-Type: application/json' -d "{\"username\": \"${ADMIN_USERNAME}\", \"password\": \"${ADMIN_PASSWORD}\"}")
TOKEN=$(python3 - <<PY
import sys, json
try:
    obj = json.load(sys.stdin)
    # ApiResponse.success wraps data under 'data' key; token placed in data.token
    data = obj.get('data') or {}
    token = data.get('token') or (data.get('accessToken') if isinstance(data, dict) else None)
    if not token:
        # Try nested
        token = obj.get('token')
    print(token or '')
except Exception:
    print('')
PY
<<<"$RESPONSE")

if [ -z "${TOKEN}" ]; then
  echo "Failed to obtain admin token. Response:" >&2
  echo "${RESPONSE}" >&2
  exit 3
fi
echo "Obtained admin token (trimmed): ${TOKEN:0:30}..."

echo "Registering driver account (username: testdriver)..."
REGISTER_PAYLOAD=$(cat <<JSON
{
  "username": "testdriver",
  "password": "driverpass",
  "email": "testdriver@example.com",
  "roles": ["DRIVER"]
}
JSON
)

REG_RESP=$(curl -s -w "\n%{http_code}" -X POST "${BACKEND_URL}/api/auth/registerdriver?driverId=${DRIVER_ID}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d "${REGISTER_PAYLOAD}")

HTTP_CODE=$(echo "$REG_RESP" | tail -n1)
BODY=$(echo "$REG_RESP" | sed '$d')
echo "Register response code: ${HTTP_CODE}"
echo "Body: ${BODY}"

if [ "${HTTP_CODE}" != "201" ] && [ "${HTTP_CODE}" != "200" ]; then
  echo "Driver registration may have failed. See output above." >&2
else
  echo "Driver registered or already exists." 
fi

echo "Creating/approving device record (${DEVICE_ID}) for driver ${DRIVER_ID}..."
docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p"${MYSQL_ROOT_PASS}" -D ${DB_NAME} <<SQL
INSERT INTO device_registered (device_id, device_name, registered_at, status, status_updated_at, driver_id)
SELECT '${DEVICE_ID}', '${DEVICE_NAME}', NOW(), 'APPROVED', NOW(), ${DRIVER_ID}
WHERE NOT EXISTS (
  SELECT 1 FROM device_registered WHERE driver_id = ${DRIVER_ID} AND device_id = '${DEVICE_ID}'
);
SQL

echo "Attempting driver login (driver/driverpass) with deviceId=${DEVICE_ID}..."
DRIVER_LOGIN_RESP=$(curl -s -X POST "${BACKEND_URL}/api/auth/driver/login" -H 'Content-Type: application/json' -d "{\"username\": \"testdriver\", \"password\": \"driverpass\", \"deviceId\": \"${DEVICE_ID}\"}")
echo "Driver login response: ${DRIVER_LOGIN_RESP}"

echo "Done. You can now open the driver app (web at http://localhost:5001) and sign in with username 'testdriver' and password 'driverpass' using device id '${DEVICE_ID}'."
#!/usr/bin/env bash
set -euo pipefail

# Script: create_test_driver.sh
# Purpose: Login as admin, create a driver (with linked user), and verify driver login.
# Requirements: `curl` and `jq` available on PATH.

API_BASE=${API_BASE:-http://localhost:8080/api}

echo "Using API base: $API_BASE"

echo "[1/3] Admin login..."
login_resp=$(curl -sS -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')

echo "$login_resp" | jq .

token=$(echo "$login_resp" | jq -r '.token // .accessToken // .access_token')

if [ -z "$token" ] || [ "$token" = "null" ]; then
  echo "ERROR: Could not obtain admin token from login response." >&2
  exit 2
fi

echo "[2/3] Creating driver 'sotheakh'..."
create_resp=$(curl -sS -X POST "$API_BASE/admin/drivers/add" \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {"username": "sotheakh", "password": "password123", "email": "sotheakh@example.com", "roles": ["DRIVER"]},
    "firstName": "Sothea",
    "lastName": "K",
    "phone": "0123456789"
  }')

echo "$create_resp" | jq .

ok=$(echo "$create_resp" | jq -r '(.message // "")')
if [ -z "$ok" ] || [ "$ok" = "null" ]; then
  echo "WARN: Driver creation may have failed or returned unexpected payload." >&2
fi

echo "[3/3] Verifying driver login..."
driver_login_resp=$(curl -sS -X POST "$API_BASE/auth/driver/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"sotheakh","password":"password123"}')

echo "$driver_login_resp" | jq .

driver_token=$(echo "$driver_login_resp" | jq -r '.token // .accessToken // .access_token')
if [ -z "$driver_token" ] || [ "$driver_token" = "null" ]; then
  echo "Driver login failed or did not return a token." >&2
  exit 3
fi

echo "Success — driver token received."
echo
echo "Tip: Re-run Flutter with --dart-define=API_BASE_URL=\"$API_BASE\" to point the app at this backend."
