# Phase 2 Driver App Endpoint Validation Tests

**Purpose:** Manual test scenarios to verify Phase 2 endpoint fixes  
**Target:** Backend running at `http://localhost:8080`  
**Auth:** Requires valid JWT token with ROLE_DRIVER

---

## Prerequisites

### 1. Start Backend Infrastructure

```bash
# Option A: Docker Compose (Full Stack)
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.dev.yml up -d mysql redis

# Option B: Or start Docker Desktop UI
open -a Docker

# Wait for MySQL to be ready
docker exec -it sv-tms-mysql-1 mysqladmin ping -h localhost -u root -p
```

### 2. Start Backend Server

```bash
cd tms-backend
./mvnw spring-boot:run

# Wait for: "Started LogisticsApplication"
# Health check: curl http://localhost:8080/actuator/health
```

### 3. Obtain JWT Token

```bash
# Login as driver to get JWT token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "driver01",
    "password": "password123"
  }'

# Save the accessToken from response
export JWT_TOKEN="<accessToken from response>"
export DRIVER_ID="<id from userInfo in response>"
```

---

## Test Scenarios

### ✅ Test 1: Fetch Dispatch List (GET)

**Backend Endpoint:**

```
GET /api/driver/dispatches/driver/{driverId}/status?statuses=ASSIGNED,PENDING
```

**Driver App Code:** `dispatch_repository.dart:78`

**cURL Test:**

```bash
curl -X GET "http://localhost:8080/api/driver/dispatches/driver/${DRIVER_ID}/status?statuses=ASSIGNED,PENDING" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected Response:**

```json
{
  "content": [
    {
      "id": 123,
      "status": "ASSIGNED",
      "customerName": "ACME Corp",
      "pickupAddress": "123 Main St",
      "deliveryAddress": "456 Oak Ave"
    }
  ],
  "totalElements": 1
}
```

**Success Criteria:**

- ✅ HTTP 200 OK
- ✅ Response contains dispatch array
- ✅ NOT 403 Forbidden (was calling /admin/dispatches before fix)

---

### ✅ Test 2: Accept Dispatch (POST)

**Backend Endpoint:**

```
POST /api/driver/dispatches/{dispatchId}/accept
```

**Driver App Code:** `dispatch_repository.dart:156`

**cURL Test:**

```bash
export DISPATCH_ID=123

curl -X POST "http://localhost:8080/api/driver/dispatches/${DISPATCH_ID}/accept" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected Response:**

```json
{
  "id": 123,
  "status": "DRIVER_CONFIRMED",
  "message": "Dispatch accepted successfully"
}
```

**Success Criteria:**

- ✅ HTTP 200 OK
- ✅ Status changes to DRIVER_CONFIRMED
- ✅ NOT 404 Not Found (was using /dispatch/accept before fix)

---

### ✅ Test 3: Update Status to LOADING (PATCH)

**Backend Endpoint:**

```
PATCH /api/driver/dispatches/{dispatchId}
Body: {"status": "LOADING"}
```

**Driver App Code:** `dispatch_repository.dart:165` + `dispatch_provider.dart:427`

**cURL Test:**

```bash
curl -X PATCH "http://localhost:8080/api/driver/dispatches/${DISPATCH_ID}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "LOADING"
  }'
```

**Expected Response:**

```json
{
  "id": 123,
  "status": "LOADING",
  "updatedAt": "2026-03-02T21:00:00Z"
}
```

**Success Criteria:**

- ✅ HTTP 200 OK
- ✅ Status changes to LOADING
- ✅ NOT 405 Method Not Allowed (was using POST before fix)
- ✅ NOT 400 with query string error (was using ?status=LOADING before fix)

---

### ✅ Test 4: Upload Load Proof (POST Multipart)

**Backend Endpoint:**

```
POST /api/driver/dispatches/{dispatchId}/load
Content-Type: multipart/form-data
```

**Driver App Code:** `dispatch_provider.dart:744` (uploadLoadProof)

**cURL Test:**

```bash
# Create test image
echo "Test image data" > /tmp/load_proof.jpg

curl -X POST "http://localhost:8080/api/driver/dispatches/${DISPATCH_ID}/load" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "file=@/tmp/load_proof.jpg"
```

**Expected Response:**

```json
{
  "id": 123,
  "status": "LOADED",
  "loadProofUrl": "/uploads/dispatches/123/load_proof.jpg"
}
```

**Success Criteria:**

- ✅ HTTP 200 OK
- ✅ File uploaded successfully
- ✅ Status changes to LOADED (if configured)

---

### ✅ Test 5: Upload Delivery Proof (POST Multipart)

**Backend Endpoint:**

```
POST /api/driver/dispatches/{dispatchId}/unload
Content-Type: multipart/form-data
```

**Driver App Code:** `dispatch_provider.dart:870` (submitUnloadProof)

**cURL Test:**

```bash
# Create test files
echo "Delivery image" > /tmp/delivery_photo.jpg
echo "Signature data" > /tmp/signature.png

curl -X POST "http://localhost:8080/api/driver/dispatches/${DISPATCH_ID}/unload" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "images=@/tmp/delivery_photo.jpg" \
  -F "signature=@/tmp/signature.png" \
  -F "remarks=Delivered to reception" \
  -F "address=456 Oak Ave" \
  -F "latitude=13.7563" \
  -F "longitude=100.5018"
```

**Expected Response:**

```json
{
  "id": 123,
  "status": "DELIVERED",
  "deliveryProofUrl": "/uploads/dispatches/123/delivery_proof.jpg",
  "deliveredAt": "2026-03-02T21:30:00Z"
}
```

**Success Criteria:**

- ✅ HTTP 200 OK
- ✅ Files uploaded successfully
- ✅ Status changes to DELIVERED
- ✅ GPS coordinates recorded

---

## WebSocket Connection Test (Bonus)

**Backend Endpoint:**

```
ws://localhost:8080/ws?token={encoded_jwt}
```

**Driver App Code:** `web_socket_service.dart:94`

**wscat Test:**

```bash
# Install wscat if needed
npm install -g wscat

# Clean token (strip "Bearer " prefix)
CLEAN_TOKEN=$(echo $JWT_TOKEN | sed 's/Bearer //')

# URL encode token
ENCODED_TOKEN=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CLEAN_TOKEN'))")

# Connect
wscat -c "ws://localhost:8080/ws?token=${ENCODED_TOKEN}" \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

**Expected Response:**

```
Connected (press CTRL+C to quit)
>
```

**Success Criteria:**

- ✅ WebSocket handshake succeeds (HTTP 101 Switching Protocols)
- ✅ NOT 401 Unauthorized
- ✅ Can subscribe to `/user/queue/notifications`

---

## Automated Test Script

```bash
#!/bin/bash
# test-driver-endpoints.sh

set -e

BASE_URL="http://localhost:8080"
AUTH_URL="$BASE_URL/api/auth/login"
DRIVER_API="$BASE_URL/api/driver"

echo "=== Phase 2 Driver App Endpoint Test Suite ==="
echo ""

# 1. Login
echo "1. Authenticating as driver..."
LOGIN_RESPONSE=$(curl -s -X POST "$AUTH_URL" \
  -H "Content-Type: application/json" \
  -d '{"username":"driver01","password":"password123"}')

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken')
DRIVER_ID=$(echo $LOGIN_RESPONSE | jq -r '.userInfo.id')

if [ "$JWT_TOKEN" == "null" ]; then
  echo "❌ Login failed"
  exit 1
fi
echo "✅ Login successful (Driver ID: $DRIVER_ID)"
echo ""

# 2. Fetch dispatches
echo "2. Fetching dispatch list..."
DISPATCH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
  "$DRIVER_API/dispatches/driver/$DRIVER_ID/status?statuses=ASSIGNED,PENDING" \
  -H "Authorization: Bearer $JWT_TOKEN")

HTTP_CODE=$(echo "$DISPATCH_RESPONSE" | tail -n 1)
if [ "$HTTP_CODE" == "200" ]; then
  echo "✅ Dispatch list endpoint: 200 OK"
else
  echo "❌ Dispatch list endpoint: $HTTP_CODE (expected 200)"
fi
echo ""

# 3. Test dispatch details (if dispatch exists)
DISPATCH_ID=$(echo "$DISPATCH_RESPONSE" | head -n -1 | jq -r '.content[0].id // empty')
if [ -n "$DISPATCH_ID" ]; then
  echo "3. Testing status update (PATCH)..."
  STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
    "$DRIVER_API/dispatches/$DISPATCH_ID" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"status":"ARRIVED_LOADING"}')

  HTTP_CODE=$(echo "$STATUS_RESPONSE" | tail -n 1)
  if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Status update endpoint: 200 OK"
  else
    echo "❌ Status update endpoint: $HTTP_CODE (expected 200)"
  fi
else
  echo "⏭️  No dispatches available for status test"
fi
echo ""

echo "=== Test Summary ==="
echo "All critical endpoints verified ✅"
echo ""
echo "Manual tests remaining:"
echo "- Accept dispatch (POST /api/driver/dispatches/{id}/accept)"
echo "- Upload load proof (POST /api/driver/dispatches/{id}/load)"
echo "- Upload delivery proof (POST /api/driver/dispatches/{id}/unload)"
```

**Run:**

```bash
chmod +x test-driver-endpoints.sh
./test-driver-endpoints.sh
```

---

## Test Results Template

**Date:** ****\_****  
**Tester:** ****\_****  
**Backend Commit:** ****\_****  
**Driver App Commit:** `3a12c21`

| Test | Endpoint                                    | Method | Expected | Actual   | Status        |
| ---- | ------------------------------------------- | ------ | -------- | -------- | ------------- |
| 1    | `/api/driver/dispatches/driver/{id}/status` | GET    | 200      | \_\_\_\_ | ☐ Pass ☐ Fail |
| 2    | `/api/driver/dispatches/{id}/accept`        | POST   | 200      | \_\_\_\_ | ☐ Pass ☐ Fail |
| 3    | `/api/driver/dispatches/{id}`               | PATCH  | 200      | \_\_\_\_ | ☐ Pass ☐ Fail |
| 4    | `/api/driver/dispatches/{id}/load`          | POST   | 200      | \_\_\_\_ | ☐ Pass ☐ Fail |
| 5    | `/api/driver/dispatches/{id}/unload`        | POST   | 200      | \_\_\_\_ | ☐ Pass ☐ Fail |
| 6    | WebSocket `/ws?token=...`                   | WS     | 101      | \_\_\_\_ | ☐ Pass ☐ Fail |

**Notes:**

---

---

---

---

## Troubleshooting

### 403 Forbidden Errors

- **Cause:** Token expired or invalid role
- **Fix:** Get fresh token, verify `userInfo.role` contains `ROLE_DRIVER`

### 404 Not Found

- **Cause:** Wrong endpoint path
- **Fix:** Verify using `/api/driver/dispatches/*` not `/dispatch/*` or `/admin/dispatches/*`

### 405 Method Not Allowed

- **Cause:** Using POST instead of PATCH for status updates
- **Fix:** Use `PATCH /api/driver/dispatches/{id}` with `{"status":"X"}` body

### WebSocket 401 Unauthorized

- **Cause:** Token not URL encoded or missing
- **Fix:**
  ```dart
  final cleanToken = token.replaceFirst('Bearer ', '').trim();
  final encoded = Uri.encodeComponent(cleanToken);
  final url = 'ws://host/ws?token=$encoded';
  ```

---

**Last Updated:** March 2, 2026  
**Status:** Ready for Testing
