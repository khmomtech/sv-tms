#!/bin/bash
# Integration Test Suite - Full Stack Verification
# Tests: Backend API + Frontend Routes + WebSocket + GPS Tracking

set -e

echo "🧪 SV-TMS Integration Test Suite"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:4200"
TEST_USER="admin@svtrucking.com"
TEST_PASS="admin123"
DRIVER_ID="30210"

# Test counters
PASSED=0
FAILED=0

# Helper functions
test_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo "1. Testing Services Availability"
echo "-----------------------------------"

# Test Backend Health
if curl -s "$BACKEND_URL/actuator/health" | grep -q '"status":"UP"'; then
    test_pass "Backend health check"
else
    test_fail "Backend health check"
fi

# Test Frontend Serving
if curl -s "$FRONTEND_URL" | grep -q "SV-TMS"; then
    test_pass "Frontend serving"
else
    test_fail "Frontend serving"
fi

# Test MySQL
if lsof -i :3306 | grep -q LISTEN; then
    test_pass "MySQL running"
else
    test_fail "MySQL running"
fi

# Test Redis
if lsof -i :6379 | grep -q LISTEN; then
    test_pass "Redis running"
else
    test_fail "Redis running"
fi

echo ""
echo "2. Testing Authentication Flow"
echo "-----------------------------------"

# Get JWT token
AUTH_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")

if echo "$AUTH_RESPONSE" | grep -q "token"; then
    TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    test_pass "Authentication successful"
    echo "   Token: ${TOKEN:0:20}..."
else
    test_fail "Authentication failed"
    echo "   Response: $AUTH_RESPONSE"
    TOKEN=""
fi

echo ""
echo "3. Testing Driver API Endpoints"
echo "-----------------------------------"

if [ -n "$TOKEN" ]; then
    # Test driver list
    DRIVER_LIST=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "$BACKEND_URL/api/admin/drivers?page=0&size=5")

    if echo "$DRIVER_LIST" | grep -q '"content"'; then
        test_pass "GET /api/admin/drivers (list)"
    else
        test_fail "GET /api/admin/drivers (list)"
    fi

    # Test specific driver
    DRIVER_DETAIL=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "$BACKEND_URL/api/admin/drivers/$DRIVER_ID")

    if echo "$DRIVER_DETAIL" | grep -q '"id"'; then
        test_pass "GET /api/admin/drivers/$DRIVER_ID (detail)"
    else
        test_fail "GET /api/admin/drivers/$DRIVER_ID (detail)"
    fi

    # Test driver location history
    LOCATION_HISTORY=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "$BACKEND_URL/api/admin/drivers/$DRIVER_ID/location-history?days=1")

    if echo "$LOCATION_HISTORY" | grep -q '\['; then
        test_pass "GET /api/admin/drivers/$DRIVER_ID/location-history"
        COUNT=$(echo "$LOCATION_HISTORY" | grep -o '"latitude"' | wc -l)
        echo "   Found $COUNT location points"
    else
        test_warn "GET /api/admin/drivers/$DRIVER_ID/location-history (no data)"
    fi

    # Test driver current location
    CURRENT_LOC=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "$BACKEND_URL/api/admin/drivers/locations/all")

    if echo "$CURRENT_LOC" | grep -q '\['; then
        test_pass "GET /api/admin/drivers/locations/all"
    else
        test_fail "GET /api/admin/drivers/locations/all"
    fi
else
    test_fail "Skipping API tests (no token)"
fi

echo ""
echo "4. Testing Frontend Routes"
echo "-----------------------------------"

# Test driver list page
if curl -s "$FRONTEND_URL/drivers" | grep -q "SV-TMS"; then
    test_pass "GET /drivers (route)"
else
    test_fail "GET /drivers (route)"
fi

# Test driver location history page
if curl -s "$FRONTEND_URL/drivers/$DRIVER_ID/location-history" | grep -q "SV-TMS"; then
    test_pass "GET /drivers/$DRIVER_ID/location-history (route)"
else
    test_fail "GET /drivers/$DRIVER_ID/location-history (route)"
fi

# Test GPS tracking page
if curl -s "$FRONTEND_URL/live/drivers" | grep -q "SV-TMS"; then
    test_pass "GET /live/drivers (GPS tracking)"
else
    test_fail "GET /live/drivers (GPS tracking)"
fi

# Test dashboard
if curl -s "$FRONTEND_URL/dashboard" | grep -q "SV-TMS"; then
    test_pass "GET /dashboard (route)"
else
    test_fail "GET /dashboard (route)"
fi

echo ""
echo "5. Testing WebSocket Endpoint"
echo "-----------------------------------"

# Test WebSocket endpoint availability (HTTP handshake)
WS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "$BACKEND_URL/ws")

if [ "$WS_RESPONSE" -eq "400" ] || [ "$WS_RESPONSE" -eq "426" ]; then
    test_pass "WebSocket endpoint available (HTTP upgrade required)"
else
    test_warn "WebSocket endpoint status: $WS_RESPONSE"
fi

# Test SockJS info endpoint
SOCKJS_INFO=$(curl -s "$BACKEND_URL/ws-sockjs/info")

if echo "$SOCKJS_INFO" | grep -q "websocket"; then
    test_pass "SockJS info endpoint"
else
    test_fail "SockJS info endpoint"
fi

echo ""
echo "6. Testing Static Assets"
echo "-----------------------------------"

# Test Google Maps API key in env
if curl -s "$FRONTEND_URL/assets/env.js" | grep -q "googleMapsApiKey"; then
    test_pass "Environment configuration loaded"
else
    test_fail "Environment configuration"
fi

echo ""
echo "=================================="
echo "Test Results Summary"
echo "=================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo "✅ Next Steps:"
    echo "   1. Open http://localhost:4200/live/drivers"
    echo "   2. Test GPS tracking with real-time updates"
    echo "   3. Open http://localhost:4200/drivers/$DRIVER_ID/location-history"
    echo "   4. Verify location history displays correctly"
    echo ""
    echo "🧪 Manual Alert Testing:"
    echo "   1. Open browser console (F12)"
    echo "   2. Run: const comp = ng.getComponent(document.querySelector('app-driver-gps-tracking'));"
    echo "   3. Run: comp.driverAlertService.checkAndEmitAlerts(1, { speed: 95 });"
    echo "   4. Verify yellow toast appears in top-right"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
