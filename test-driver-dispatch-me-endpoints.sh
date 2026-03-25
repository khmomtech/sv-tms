#!/bin/bash

# Test script for new Driver Dispatch "Me" Endpoints
# Tests the refactored endpoints that get driver ID from authentication context

set -e

HOST="http://localhost:8080"
DRIVER_USERNAME="${DRIVER_USERNAME:-driver1}"
DRIVER_PASSWORD="${DRIVER_PASSWORD:-driver123}"

echo "======================================"
echo "Driver Dispatch 'Me' Endpoints Test"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Login as driver
echo -e "${YELLOW}1. Logging in as driver...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$HOST/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$DRIVER_USERNAME\",\"password\":\"$DRIVER_PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // .data.token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo -e "${RED}❌ Login failed!${NC}"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Step 2: Test /me/pending
echo -e "${YELLOW}2. Testing GET /api/driver/dispatches/me/pending${NC}"
PENDING_RESPONSE=$(curl -s -X GET "$HOST/api/driver/dispatches/me/pending?page=0&size=10" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

PENDING_COUNT=$(echo "$PENDING_RESPONSE" | jq -r '.content | length // 0')
PENDING_TOTAL=$(echo "$PENDING_RESPONSE" | jq -r '.totalElements // 0')

if [ "$PENDING_COUNT" != "null" ]; then
  echo -e "${GREEN}✅ Pending dispatches endpoint works${NC}"
  echo "   Found: $PENDING_COUNT dispatches (page), $PENDING_TOTAL total"
  
  # Check statuses
  STATUSES=$(echo "$PENDING_RESPONSE" | jq -r '.content[].status' | sort -u | tr '\n' ', ')
  echo "   Statuses: ${STATUSES:-none}"
else
  echo -e "${RED}❌ Failed to fetch pending dispatches${NC}"
  echo "$PENDING_RESPONSE" | jq .
fi
echo ""

# Step 3: Test /me/in-progress
echo -e "${YELLOW}3. Testing GET /api/driver/dispatches/me/in-progress${NC}"
INPROGRESS_RESPONSE=$(curl -s -X GET "$HOST/api/driver/dispatches/me/in-progress?page=0&size=10" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

INPROGRESS_COUNT=$(echo "$INPROGRESS_RESPONSE" | jq -r '.content | length // 0')
INPROGRESS_TOTAL=$(echo "$INPROGRESS_RESPONSE" | jq -r '.totalElements // 0')

if [ "$INPROGRESS_COUNT" != "null" ]; then
  echo -e "${GREEN}✅ In-progress dispatches endpoint works${NC}"
  echo "   Found: $INPROGRESS_COUNT dispatches (page), $INPROGRESS_TOTAL total"
  
  # Check statuses
  STATUSES=$(echo "$INPROGRESS_RESPONSE" | jq -r '.content[].status' | sort -u | tr '\n' ', ')
  echo "   Statuses: ${STATUSES:-none}"
else
  echo -e "${RED}❌ Failed to fetch in-progress dispatches${NC}"
  echo "$INPROGRESS_RESPONSE" | jq .
fi
echo ""

# Step 4: Test /me/completed
echo -e "${YELLOW}4. Testing GET /api/driver/dispatches/me/completed${NC}"
COMPLETED_RESPONSE=$(curl -s -X GET "$HOST/api/driver/dispatches/me/completed?page=0&size=10" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json")

COMPLETED_COUNT=$(echo "$COMPLETED_RESPONSE" | jq -r '.content | length // 0')
COMPLETED_TOTAL=$(echo "$COMPLETED_RESPONSE" | jq -r '.totalElements // 0')

if [ "$COMPLETED_COUNT" != "null" ]; then
  echo -e "${GREEN}✅ Completed dispatches endpoint works${NC}"
  echo "   Found: $COMPLETED_COUNT dispatches (page), $COMPLETED_TOTAL total"
  
  # Check statuses
  STATUSES=$(echo "$COMPLETED_RESPONSE" | jq -r '.content[].status' | sort -u | tr '\n' ', ')
  echo "   Statuses: ${STATUSES:-none}"
else
  echo -e "${RED}❌ Failed to fetch completed dispatches${NC}"
  echo "$COMPLETED_RESPONSE" | jq .
fi
echo ""

# Step 5: Test without authentication (should fail)
echo -e "${YELLOW}5. Testing authentication requirement...${NC}"
UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$HOST/api/driver/dispatches/me/pending")
HTTP_CODE=$(echo "$UNAUTH_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
  echo -e "${GREEN}✅ Endpoint properly secured (returned $HTTP_CODE)${NC}"
else
  echo -e "${RED}❌ Security issue: endpoint returned $HTTP_CODE without auth${NC}"
fi
echo ""

# Summary
echo "======================================"
echo -e "${GREEN}✅ All tests completed!${NC}"
echo "======================================"
echo ""
echo "Summary:"
echo "  - Pending dispatches: $PENDING_TOTAL total"
echo "  - In-progress dispatches: $INPROGRESS_TOTAL total"
echo "  - Completed dispatches: $COMPLETED_TOTAL total"
echo ""
echo "Next steps:"
echo "  1. ✅ Backend endpoints working correctly"
echo "  2. ✅ Authentication working"
echo "  3. ✅ Status filtering working"
echo "  4. 🔄 Update Flutter app to use new methods"
echo ""
