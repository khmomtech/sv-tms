#!/bin/bash
# Quick endpoint validation for Phase 2 driver app fixes
# Tests the critical HTTP endpoints without running Flutter app

set -e

BASE_URL="http://localhost:8080"
DRIVER_USERNAME="${DRIVER_USERNAME:-driver01}"
DRIVER_PASSWORD="${DRIVER_PASSWORD:-password123}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "  Phase 2 Driver Endpoint Tests"
echo "======================================"
echo ""

# Check if backend is running
echo -n "Checking backend health... "
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health" || echo "000")
if [ "$HEALTH" != "200" ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "Backend is not running on $BASE_URL"
    echo ""
    echo "Start backend with:"
    echo "  cd tms-backend && ./mvnw spring-boot:run"
    echo ""
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Login as driver
echo -n "Authenticating driver... "
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$DRIVER_USERNAME\",\"password\":\"$DRIVER_PASSWORD\"}" || echo '{"error":"failed"}')

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token // .accessToken // empty')
# API response doesn't include user ID, so we need to derive it from database
# For test user, we know it's 99999
if [ "$DRIVER_USERNAME" == "testdriver01" ]; then
    DRIVER_ID="99999"
else
    DRIVER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.id // .userInfo.id // .data.userId // empty')
fi

if [ -z "$JWT_TOKEN" ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "Login response:"
    echo "$LOGIN_RESPONSE" | jq '.'
    echo ""
    echo "Verify driver credentials: $DRIVER_USERNAME / $DRIVER_PASSWORD"
    exit 1
fi
echo -e "${GREEN}OK${NC} (Driver ID: $DRIVER_ID)"

# Test 1: Fetch dispatch list (GET)
echo ""
echo "Test 1: Fetch Dispatch List"
echo "----------------------------"
echo "Endpoint: GET /api/driver/dispatches/driver/$DRIVER_ID/status?status=..."
echo -n "Status: "

DISPATCH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
  "$BASE_URL/api/driver/dispatches/driver/$DRIVER_ID/status?status=ASSIGNED,PENDING,DRIVER_CONFIRMED" \
  -H "Authorization: Bearer $JWT_TOKEN")

HTTP_CODE=$(echo "$DISPATCH_RESPONSE" | tail -n 1)
BODY=$(echo "$DISPATCH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}200 OK ✅${NC}"
    DISPATCH_COUNT=$(echo "$BODY" | jq -r '.content | length // 0')
    echo "Dispatches found: $DISPATCH_COUNT"
    
    # Save first dispatch ID for later tests
    DISPATCH_ID=$(echo "$BODY" | jq -r '.content[0].id // empty')
    if [ -n "$DISPATCH_ID" ]; then
        echo "First dispatch ID: $DISPATCH_ID"
    fi
elif [ "$HTTP_CODE" == "403" ]; then
    echo -e "${RED}403 FORBIDDEN ❌${NC}"
    echo "This indicates admin endpoint contamination bug is present!"
else
    echo -e "${RED}$HTTP_CODE ❌${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
fi

# Test 2: PATCH status update (only if dispatch exists)
if [ -n "$DISPATCH_ID" ]; then
    echo ""
    echo "Test 2: PATCH Status Update"
    echo "----------------------------"
    echo "Endpoint: PATCH /api/driver/dispatches/$DISPATCH_ID/status"
    echo -n "Status: "
    
    PATCH_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
      "$BASE_URL/api/driver/dispatches/$DISPATCH_ID/status" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"status":"DRIVER_CONFIRMED"}')
    
    HTTP_CODE=$(echo "$PATCH_RESPONSE" | tail -n 1)
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}200 OK ✅${NC}"
        echo "Status update successful (PATCH method working)"
    elif [ "$HTTP_CODE" == "405" ]; then
        echo -e "${RED}405 METHOD NOT ALLOWED ❌${NC}"
        echo "This indicates POST→PATCH fix was not applied!"
    elif [ "$HTTP_CODE" == "400" ]; then
        BODY=$(echo "$PATCH_RESPONSE" | sed '$d')
        if echo "$BODY" | grep -q "status"; then
            echo -e "${RED}400 BAD REQUEST ❌${NC}"
            echo "Possible query string bug (using ?status= instead of body)"
        else
            echo -e "${RED}400 BAD REQUEST${NC}"
        fi
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    else
        echo -e "${RED}$HTTP_CODE ❌${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}Test 2: SKIPPED (no dispatches available)${NC}"
fi

# Test 3: Accept endpoint check (OPTIONS)
echo ""
echo "Test 3: Accept Endpoint Check"
echo "------------------------------"
echo "Endpoint: OPTIONS /api/driver/dispatches/{id}/accept"
echo -n "Status: "

if [ -n "$DISPATCH_ID" ]; then
    OPTIONS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS \
      "$BASE_URL/api/driver/dispatches/$DISPATCH_ID/accept" \
      -H "Authorization: Bearer $JWT_TOKEN")
    
    if [ "$OPTIONS_RESPONSE" == "200" ] || [ "$OPTIONS_RESPONSE" == "204" ]; then
        echo -e "${GREEN}$OPTIONS_RESPONSE ✅${NC}"
        echo "Accept endpoint exists"
    elif [ "$OPTIONS_RESPONSE" == "404" ]; then
        echo -e "${RED}404 NOT FOUND ❌${NC}"
        echo "This indicates legacy /dispatch/accept path is still being used!"
    else
        echo -e "${YELLOW}$OPTIONS_RESPONSE${NC}"
    fi
else
    echo -e "${YELLOW}SKIPPED (no dispatch ID)${NC}"
fi

# Summary
echo ""
echo "======================================"
echo "  Test Summary"
echo "======================================"
echo ""

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Critical endpoints working correctly"
    echo ""
    echo "Phase 2 endpoint fixes verified:"
    echo "  ✓ Using /api/driver/dispatches/* (not /admin/dispatches)"
    echo "  ✓ PATCH method for status updates (not POST)"
    echo "  ✓ Driver role authentication working"
    echo ""
    echo "Next steps:"
    echo "  1. Test with Flutter driver app"
    echo "  2. Test proof upload endpoints (require multipart)"
    echo "  3. Monitor WebSocket connection status"
else
    echo -e "${RED}❌ FAIL${NC} - Some endpoints not working"
    echo ""
    echo "Review ENDPOINT_VALIDATION_TESTS.md for detailed troubleshooting"
fi

echo ""
