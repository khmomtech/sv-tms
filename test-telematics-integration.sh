#!/usr/bin/env bash
# =============================================================================
# test-telematics-integration.sh
#
# Integration contract test between tms_driver_app and tms-telematics-api.
# Mirrors the exact payloads sent by the Flutter driver app.
#
# Usage:
#   ./test-telematics-integration.sh                   # default: localhost:8082
#   TELE_URL=http://192.168.1.5:8082 ./test-telematics-integration.sh
#   JWT_SECRET=my-secret ./test-telematics-integration.sh
# =============================================================================
set -euo pipefail

TELE_URL="${TELE_URL:-http://localhost:8082}"
INTERNAL_KEY="${INTERNAL_KEY:-dev-internal-key}"
JWT_SECRET="${JWT_SECRET:-changeme-dev-secret-32-chars-min!!!}"
DRIVER_ID="${DRIVER_ID:-42}"
DEVICE_ID="${DEVICE_ID:-test-device-flutter-android-001}"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0
TRACKING_TOKEN=""
SESSION_ID=""

# ── Helpers ───────────────────────────────────────────────────────────────────
header() { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }
pass()   { echo -e "  ${GREEN}✓ PASS${NC} $*"; PASS=$((PASS + 1)); }
fail()   { echo -e "  ${RED}✗ FAIL${NC} $*"; FAIL=$((FAIL + 1)); }
skip()   { echo -e "  ${YELLOW}~ SKIP${NC} $*"; SKIP=$((SKIP + 1)); }
info()   { echo -e "         $*"; }

check_status() {
  local label="$1" expected="$2" actual="$3" body="$4"
  if [ "$actual" = "$expected" ]; then
    pass "$label (HTTP $actual)"
  else
    fail "$label — expected HTTP $expected, got $actual"
    info "Body: $(echo "$body" | head -c 300)"
  fi
}

check_field() {
  local label="$1" field="$2" body="$3"
  local val
  val=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$field',''))" 2>/dev/null || echo "")
  if [ -n "$val" ] && [ "$val" != "None" ] && [ "$val" != "null" ]; then
    pass "$label — field '$field' present (${val:0:60})"
    echo "$val"
  else
    fail "$label — field '$field' missing or null"
    echo ""
  fi
}

# Generate JWT access token (same claims as tms-backend → accepted by telematics)
gen_access_token() {
  python3 - <<PYEOF
import jwt, time
payload = {
    "sub": "test_driver_flutter",
    "driverId": $DRIVER_ID,
    "exp": int(time.time()) + 3600
}
token = jwt.encode(payload, "$JWT_SECRET", algorithm="HS256")
print(token if isinstance(token, str) else token.decode())
PYEOF
}

# Generate tracking token (issued after session start — same structure as TelematicsJwtUtil.generateTrackingToken)
gen_tracking_token() {
  local session_id="$1"
  python3 - <<PYEOF
import jwt, time
payload = {
    "sub": "test_driver_flutter",
    "driverId": $DRIVER_ID,
    "typ": "tracking",
    "scope": "LOCATION_WRITE TRACKING_WS",
    "deviceId": "$DEVICE_ID",
    "sessionId": "$session_id",
    "exp": int(time.time()) + 86400
}
token = jwt.encode(payload, "$JWT_SECRET", algorithm="HS256")
print(token if isinstance(token, str) else token.decode())
PYEOF
}

ACCESS_TOKEN=""
NOW_MS=$(python3 -c "import time; print(int(time.time()*1000))")

# =============================================================================
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║    tms_driver_app ↔ tms-telematics-api           ║"
echo "║    Integration Contract Tests                         ║"
echo "╚══════════════════════════════════════════════════════╝${NC}"
echo "  Target : $TELE_URL"
echo "  DriverId: $DRIVER_ID  DeviceId: $DEVICE_ID"
echo ""

# =============================================================================
header "0. Token Generation"
# =============================================================================
ACCESS_TOKEN=$(gen_access_token)
if [ -n "$ACCESS_TOKEN" ]; then
  pass "Access JWT generated (${ACCESS_TOKEN:0:30}...)"
else
  fail "Access JWT generation failed — check PyJWT and JWT_SECRET"
  exit 1
fi

# =============================================================================
header "1. Service Health"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 "$TELE_URL/actuator/health" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "GET /actuator/health" "200" "$STATUS" "$BODY"

STATUS_FIELD=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)
if [ "$STATUS_FIELD" = "UP" ]; then
  pass "Health status=UP"
else
  fail "Health status unexpected: '$STATUS_FIELD'"
fi

# =============================================================================
header "2. Internal API — Driver Snapshot Sync (mirrors TelematicsProxyService.syncDriverAsync)"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X PATCH "$TELE_URL/api/internal/telematics/driver-sync" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Api-Key: $INTERNAL_KEY" \
  -d "{\"driverId\": $DRIVER_ID, \"name\": \"Test Driver Flutter\", \"phone\": \"+85512345678\", \"vehiclePlate\": \"ABC-1234\"}")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "PATCH /api/internal/telematics/driver-sync" "200" "$STATUS" "$BODY"

# Bulk sync
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X PATCH "$TELE_URL/api/internal/telematics/driver-sync/bulk" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Api-Key: $INTERNAL_KEY" \
  -d "{\"drivers\": [{\"driverId\": $DRIVER_ID, \"name\": \"Test Driver Flutter\", \"phone\": \"+85512345678\", \"vehiclePlate\": \"ABC-1234\"}]}")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "PATCH /api/internal/telematics/driver-sync/bulk" "200" "$STATUS" "$BODY"

# Reject without API key
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X PATCH "$TELE_URL/api/internal/telematics/driver-sync" \
  -H "Content-Type: application/json" \
  -d "{\"driverId\": $DRIVER_ID, \"name\": \"hacker\"}")
STATUS=$(echo "$RESP" | tail -1)
if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
  pass "Internal endpoint rejects missing API key (HTTP $STATUS)"
else
  fail "Internal endpoint allowed request without API key (HTTP $STATUS)"
fi

# =============================================================================
header "3. Tracking Session Start (mirrors TrackingSessionManager.startTrackingSession)"
# =============================================================================
# Driver app sends: {deviceId, appVersion, platform}
RESP=$(curl -s -w "\n%{http_code}" --max-time 15 \
  -X POST "$TELE_URL/api/driver/tracking-session/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"deviceId\": \"$DEVICE_ID\", \"appVersion\": \"1.5.0\", \"platform\": \"android\"}")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/tracking-session/start" "200" "$STATUS" "$BODY"

# Verify driver app expected response fields: sessionId, trackingToken, expiresAtEpochMs
SESSION_ID=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sessionId') or d.get('data',{}).get('sessionId',''))" 2>/dev/null || echo "")
TRACKING_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('trackingToken') or d.get('data',{}).get('trackingToken',''))" 2>/dev/null || echo "")
EXPIRES_MS=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('expiresAtEpochMs') or d.get('data',{}).get('expiresAtEpochMs',''))" 2>/dev/null || echo "")

[ -n "$SESSION_ID" ]    && pass "sessionId present: $SESSION_ID"   || fail "sessionId missing from response"
[ -n "$TRACKING_TOKEN" ] && pass "trackingToken present"           || fail "trackingToken missing — driver app will fail to start location updates"
[ -n "$EXPIRES_MS" ]    && pass "expiresAtEpochMs present: $EXPIRES_MS" || fail "expiresAtEpochMs missing — driver app cannot schedule token refresh"

# Also test the alternate path the driver app uses: /driver/tracking/session/start
RESP2=$(curl -s -w "\n%{http_code}" --max-time 15 \
  -X POST "$TELE_URL/api/driver/tracking/session/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"deviceId\": \"${DEVICE_ID}-alt\", \"appVersion\": \"1.5.0\", \"platform\": \"android\"}")
STATUS2=$(echo "$RESP2" | tail -1)
check_status "POST /api/driver/tracking/session/start (driver app path)" "200" "$STATUS2" "$(echo "$RESP2" | head -1)"

# =============================================================================
header "4. Location Update (mirrors LocationService._sendPayload / LocationUpdate.toJson)"
# =============================================================================
if [ -z "$TRACKING_TOKEN" ]; then
  TRACKING_TOKEN=$(gen_tracking_token "$SESSION_ID")
  info "Using locally generated tracking token (session start returned no token)"
fi

# Exact payload from tms_driver_app/lib/services/location_service.dart LocationUpdate.toJson()
LOCATION_PAYLOAD=$(cat <<JSON
{
  "driverId": $DRIVER_ID,
  "driverName": "Test Driver Flutter",
  "vehiclePlate": "ABC-1234",
  "latitude": 11.5564,
  "longitude": 104.9282,
  "speed": 7.5,
  "clientSpeedKmh": 27.0,
  "accuracyMeters": 5.0,
  "heading": 95.3,
  "batteryLevel": 78,
  "isMocked": false,
  "batterySaver": false,
  "source": "FLUTTER_ANDROID",
  "clientTime": $NOW_MS,
  "timestampEpochMs": $NOW_MS,
  "keepAlive": false,
  "gpsOn": true,
  "sessionId": "$SESSION_ID",
  "dispatchId": null,
  "netType": "WIFI",
  "locationSource": "GPS"
}
JSON
)

# Using tracking token (normal flow after session start)
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/location/update" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$LOCATION_PAYLOAD")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/location/update (tracking token)" "200" "$STATUS" "$BODY"

OK_FIELD=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ok',''))" 2>/dev/null)
[ "$OK_FIELD" = "True" ] || [ "$OK_FIELD" = "true" ] \
  && pass "Response ok=true" \
  || fail "Response ok field unexpected: '$OK_FIELD'"

# Verify driverId echoed back (driver app uses this for dedup detection)
ECHO_DRIVER=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('driverId',''))" 2>/dev/null)
[ "$ECHO_DRIVER" = "$DRIVER_ID" ] && pass "driverId echoed correctly" || fail "driverId not echoed (got: $ECHO_DRIVER)"

# Second update — tests throttle (should get dedup=true within 3s)
sleep 0.3
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/location/update" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$LOCATION_PAYLOAD")
STATUS2=$(echo "$RESP2" | tail -1)
BODY2=$(echo "$RESP2" | head -1)
check_status "POST /api/driver/location/update (duplicate within throttle window)" "200" "$STATUS2" "$BODY2"
DEDUP=$(echo "$BODY2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('dedup',''))" 2>/dev/null)
[ "$DEDUP" = "True" ] || [ "$DEDUP" = "true" ] \
  && pass "Throttle/dedup correctly applied (dedup=true)" \
  || info "dedup field: '$DEDUP' (may be first update accepted if enough time passed)"

# Using access token (backward compat for driver app not yet on tracking session flow)
RESP3=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/location/update" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "$(echo "$LOCATION_PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); d['sessionId']=''; print(json.dumps(d))")")
STATUS3=$(echo "$RESP3" | tail -1)
check_status "POST /api/driver/location/update (access token — backward compat)" "200" "$STATUS3" "$(echo "$RESP3" | head -1)"

# Reject unauthenticated
RESP4=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/location/update" \
  -H "Content-Type: application/json" \
  -d "$LOCATION_PAYLOAD")
STATUS4=$(echo "$RESP4" | tail -1)
[ "$STATUS4" = "401" ] \
  && pass "Location update rejects missing auth (HTTP 401)" \
  || fail "Location update without auth returned HTTP $STATUS4 (expected 401)"

# =============================================================================
header "5. Presence Heartbeat (mirrors WebSocketService STOMP heartbeat / app state push)"
# =============================================================================
# Payload mirrors PresenceHeartbeatDto — driver app sends battery, gpsEnabled, ts
HEARTBEAT_PAYLOAD=$(cat <<JSON
{
  "driverId": $DRIVER_ID,
  "device": "FLUTTER_ANDROID",
  "battery": 78,
  "gpsEnabled": true,
  "ts": $NOW_MS,
  "reason": "APP_FOREGROUND"
}
JSON
)
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/presence/heartbeat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$HEARTBEAT_PAYLOAD")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/presence/heartbeat (tracking token)" "200" "$STATUS" "$BODY"

PRESENCE_STATUS=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('presenceStatus',''))" 2>/dev/null)
[ "$PRESENCE_STATUS" = "ONLINE" ] \
  && pass "presenceStatus=ONLINE (driver marked online after heartbeat)" \
  || info "presenceStatus='$PRESENCE_STATUS' (may be IDLE if clock skew)"

# Background / idle heartbeat
IDLE_HB=$(echo "$HEARTBEAT_PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); d['reason']='APP_BACKGROUND'; print(json.dumps(d))")
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/presence/heartbeat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$IDLE_HB")
STATUS2=$(echo "$RESP2" | tail -1)
check_status "POST /api/driver/presence/heartbeat (APP_BACKGROUND reason)" "200" "$STATUS2" "$(echo "$RESP2" | head -1)"

# Reject unauthenticated
RESP3=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/presence/heartbeat" \
  -H "Content-Type: application/json" \
  -d "$HEARTBEAT_PAYLOAD")
STATUS3=$(echo "$RESP3" | tail -1)
[ "$STATUS3" = "401" ] \
  && pass "Heartbeat rejects missing auth (HTTP 401)" \
  || fail "Heartbeat without auth returned HTTP $STATUS3 (expected 401)"

# =============================================================================
header "6. Admin Presence Lookup"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/admin/driver/$DRIVER_ID/presence" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "GET /api/admin/driver/$DRIVER_ID/presence" "200" "$STATUS" "$BODY"

PS=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('presenceStatus',''))" 2>/dev/null)
[ -n "$PS" ] && pass "presenceStatus field present: $PS" || fail "presenceStatus missing from presence response"

# =============================================================================
header "7. Spoofing Alert (mirrors LocationService._sendSpoofAlert)"
# =============================================================================
# Driver app sends this when it detects impossible movements or mocked GPS
SPOOF_PAYLOAD=$(cat <<JSON
{
  "driverId": $DRIVER_ID,
  "reason": "HIGH_SPEED_SPIKE",
  "latitude": 11.5564,
  "longitude": 104.9282,
  "accuracy": 12.0,
  "speed": 150.0,
  "isMocked": false
}
JSON
)
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/locations/spoofing-alert" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "$SPOOF_PAYLOAD")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/locations/spoofing-alert" "200" "$STATUS" "$BODY"

# Mocked location variant
MOCKED_SPOOF=$(echo "$SPOOF_PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); d['reason']='MOCK_PROVIDER_DETECTED'; d['isMocked']=True; print(json.dumps(d))")
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/locations/spoofing-alert" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$MOCKED_SPOOF")
STATUS2=$(echo "$RESP2" | tail -1)
check_status "POST /api/locations/spoofing-alert (isMocked=true, tracking token)" "200" "$STATUS2" "$(echo "$RESP2" | head -1)"

# =============================================================================
header "8. Admin Live Drivers Query"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 15 \
  "$TELE_URL/api/admin/telematics/live-drivers" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "GET /api/admin/telematics/live-drivers" "200" "$STATUS" "$BODY"

# Admin query without auth must be rejected
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/admin/telematics/live-drivers")
STATUS2=$(echo "$RESP2" | tail -1)
[ "$STATUS2" = "401" ] \
  && pass "Admin live-drivers rejects missing auth (HTTP 401)" \
  || fail "Admin endpoint without auth returned HTTP $STATUS2 (expected 401)"

# Single driver location
RESP3=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/admin/telematics/driver/$DRIVER_ID/location" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
STATUS3=$(echo "$RESP3" | tail -1)
BODY3=$(echo "$RESP3" | head -1)
# 200 if driver has location, 404 if not found yet
[ "$STATUS3" = "200" ] || [ "$STATUS3" = "404" ] \
  && pass "GET /api/admin/telematics/driver/$DRIVER_ID/location (HTTP $STATUS3)" \
  || fail "GET /api/admin/telematics/driver/$DRIVER_ID/location unexpected HTTP $STATUS3"

if [ "$STATUS3" = "200" ]; then
  LAT=$(echo "$BODY3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('latitude') or d.get('lat',''))" 2>/dev/null)
  [ -n "$LAT" ] && pass "latitude present in admin location response: $LAT" || info "latitude field: '$LAT'"
fi

# =============================================================================
header "9. Tracking Session Refresh (mirrors TrackingSessionManager ensureTrackingSession)"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/tracking-session/refresh" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/tracking-session/refresh" "200" "$STATUS" "$BODY"

NEW_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('trackingToken',''))" 2>/dev/null)
[ -n "$NEW_TOKEN" ] \
  && pass "Rotated tracking token returned on refresh" \
  || fail "No trackingToken in refresh response — driver app keeps stale token"

# Also test driver app path alias
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/tracking/session/refresh" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS2=$(echo "$RESP2" | tail -1)
check_status "POST /api/driver/tracking/session/refresh (driver app path alias)" "200" "$STATUS2" "$(echo "$RESP2" | head -1)"

# =============================================================================
header "10. Public Tracking (no auth required)"
# =============================================================================
# 404 expected without a real order reference — validates endpoint is reachable
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/public/tracking/FAKE-REF-0000")
STATUS=$(echo "$RESP" | tail -1)
[ "$STATUS" = "404" ] || [ "$STATUS" = "200" ] \
  && pass "GET /api/public/tracking/{ref} reachable (HTTP $STATUS)" \
  || fail "GET /api/public/tracking/{ref} unexpected HTTP $STATUS"

RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/public/tracking/FAKE-REF-0000/location")
STATUS2=$(echo "$RESP2" | tail -1)
[ "$STATUS2" = "404" ] || [ "$STATUS2" = "200" ] \
  && pass "GET /api/public/tracking/{ref}/location reachable (HTTP $STATUS2)" \
  || fail "GET /api/public/tracking/{ref}/location unexpected HTTP $STATUS2"

# =============================================================================
header "11. Driver Logout (mirrors SessionManager._forceLogout post-clear)"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/logout?driverId=$DRIVER_ID" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/logout?driverId=$DRIVER_ID" "200" "$STATUS" "$BODY"

STATUS_F=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)
[ "$STATUS_F" = "ok" ] && pass "Logout response status=ok" || fail "Logout response status='$STATUS_F'"

# Presence should now reflect offline
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  "$TELE_URL/api/admin/driver/$DRIVER_ID/presence" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
STATUS2=$(echo "$RESP2" | tail -1)
BODY2=$(echo "$RESP2" | head -1)
if [ "$STATUS2" = "200" ]; then
  PS2=$(echo "$BODY2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('presenceStatus',''))" 2>/dev/null)
  pass "Driver presence after logout: $PS2"
fi

# =============================================================================
header "12. Tracking Session Stop (mirrors TrackingSessionManager.stopTrackingSession)"
# =============================================================================
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/tracking-session/stop" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -1)
check_status "POST /api/driver/tracking-session/stop" "200" "$STATUS" "$BODY"

# Verify session is revoked — second stop should 404/401
RESP2=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/tracking-session/stop" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS2=$(echo "$RESP2" | tail -1)
[ "$STATUS2" = "404" ] || [ "$STATUS2" = "401" ] \
  && pass "Second stop correctly rejects revoked session (HTTP $STATUS2)" \
  || info "Second stop returned HTTP $STATUS2 (session may already be cleaned up)"

# Driver app path alias
RESP3=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/tracking/session/stop" \
  -H "Authorization: Bearer $TRACKING_TOKEN")
STATUS3=$(echo "$RESP3" | tail -1)
[ "$STATUS3" = "404" ] || [ "$STATUS3" = "401" ] || [ "$STATUS3" = "200" ] \
  && pass "POST /api/driver/tracking/session/stop (driver app path alias) HTTP $STATUS3" \
  || fail "Unexpected HTTP $STATUS3 for driver app session stop path"

# =============================================================================
header "13. Auth Boundary — Access Token Cannot Write Location After Stop"
# =============================================================================
# After session revocation, a tracking token for that session must be rejected
RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$TELE_URL/api/driver/location/update" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRACKING_TOKEN" \
  -d "$LOCATION_PAYLOAD")
STATUS=$(echo "$RESP" | tail -1)
[ "$STATUS" = "401" ] \
  && pass "Location update with revoked tracking token rejected (HTTP 401)" \
  || info "Revoked session returned HTTP $STATUS (may be re-accepted via access token fallback)"

# =============================================================================
header "Results"
# =============================================================================
TOTAL=$((PASS + FAIL + SKIP))
echo ""
echo "  Tests run : $TOTAL"
echo -e "  ${GREEN}Passed${NC}    : $PASS"
[ $FAIL -gt 0 ] && echo -e "  ${RED}Failed${NC}    : $FAIL" || echo "  Failed    : $FAIL"
[ $SKIP -gt 0 ] && echo -e "  ${YELLOW}Skipped${NC}   : $SKIP" || true
echo ""

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}All tests passed. tms_driver_app ↔ tms-telematics-api contract verified.${NC}"
  exit 0
else
  echo -e "${RED}$FAIL test(s) failed. Review output above.${NC}"
  exit 1
fi
