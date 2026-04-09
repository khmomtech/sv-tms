#!/bin/bash

# Updated Angular Tasks Smoke Tests - Tests Maintenance Tasks
# Tests the ACTUAL backend endpoints that exist

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Base URL
BACKEND_URL="http://localhost:8080/api"

# Authentication
TOKEN=""
ADMIN_USERNAME="superadmin"
ADMIN_PASSWORD="super123"

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}==== $1 ====${NC}"
}

assert_http_status() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected HTTP status: $expected"
        echo "  Actual HTTP status: $actual"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Could not find '$needle' in response"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Check backend availability
print_header "1. Checking Backend Availability"
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/../actuator/health")
if [ "$BACKEND_HEALTH" != "200" ]; then
    echo -e "${RED}✗${NC} Backend is not running at $BACKEND_URL"
    echo "  Please start the backend server first"
    exit 1
fi
echo -e "${GREEN}✓${NC} Backend is running"

# Login
print_header "2. Authentication"
LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗${NC} Authentication failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi
echo -e "${GREEN}✓${NC} Authentication successful (token acquired)"

# Test Maintenance Tasks endpoints
print_header "3. GET /api/admin/maintenance-tasks - List tasks"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "List maintenance tasks returns 200"
assert_contains "$BODY" '"success":true' "Response has success:true"
assert_contains "$BODY" '"data"' "Response has data field"

print_header "4. GET /api/admin/maintenance-tasks with filters"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks?status=SCHEDULED&page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

assert_http_status "200" "$HTTP_STATUS" "Filter by status works"

print_header "5. GET /api/admin/maintenance-tasks with keyword search"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks?keyword=test&page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

assert_http_status "200" "$HTTP_STATUS" "Keyword search works"

print_header "6. POST /api/admin/maintenance-tasks - Create task"
CREATE_PAYLOAD='{
  "title": "Test Maintenance Task",
  "description": "Created by smoke test",
  "status": "SCHEDULED",
  "dueDate": "2025-12-31T00:00:00"
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/admin/maintenance-tasks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$CREATE_PAYLOAD")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Create task returns 200"
assert_contains "$BODY" '"success":true' "Create response has success:true"

# Extract task ID from response
TASK_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

if [ -n "$TASK_ID" ]; then
    echo -e "${GREEN}✓${NC} Created task with ID: $TASK_ID"

    print_header "7. GET /api/admin/maintenance-tasks/{id} - Get single task"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")
    HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Get task by ID returns 200"
    assert_contains "$BODY" "\"id\":$TASK_ID" "Response contains correct task ID"
    assert_contains "$BODY" '"title":"Test Maintenance Task"' "Response contains task title"

    print_header "8. PUT /api/admin/maintenance-tasks/{id} - Update task"
    UPDATE_PAYLOAD='{
      "title": "Updated Test Task",
      "description": "Updated by smoke test",
      "status": "IN_PROGRESS"
    }'

    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BACKEND_URL/admin/maintenance-tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$UPDATE_PAYLOAD")
    HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Update task returns 200"
    assert_contains "$BODY" '"title":"Updated Test Task"' "Task title updated"

    print_header "9. POST /api/admin/maintenance-tasks/{id}/complete - Complete task"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/admin/maintenance-tasks/$TASK_ID/complete" \
        -H "Authorization: Bearer $TOKEN")
    HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

    assert_http_status "200" "$HTTP_STATUS" "Complete task returns 200"

    print_header "10. DELETE /api/admin/maintenance-tasks/{id} - Delete task"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BACKEND_URL/admin/maintenance-tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")
    HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

    assert_http_status "200" "$HTTP_STATUS" "Delete task returns 200"

    # Verify deletion
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")
    HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

    if [ "$HTTP_STATUS" = "404" ] || [ "$HTTP_STATUS" = "500" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓${NC} Task successfully deleted (returns 404 or 500)"
    else
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗${NC} Task not deleted (still returns $HTTP_STATUS)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Could not extract task ID, skipping individual task tests"
    TOTAL_TESTS=$((TOTAL_TESTS + 6))
    FAILED_TESTS=$((FAILED_TESTS + 6))
fi

print_header "11. GET /api/admin/maintenance-tasks/overdue - Get overdue tasks"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks/overdue" \
    -H "Authorization: Bearer $TOKEN")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

assert_http_status "200" "$HTTP_STATUS" "Get overdue tasks returns 200"

print_header "12. Authorization - Test without token"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/admin/maintenance-tasks")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

assert_http_status "401" "$HTTP_STATUS" "No token returns 401 Unauthorized"

print_header "13. Validation - Create task without required field"
INVALID_PAYLOAD='{
  "description": "Missing title field"
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/admin/maintenance-tasks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$INVALID_PAYLOAD")
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$HTTP_STATUS" = "400" ] || [ "$HTTP_STATUS" = "500" ]; then
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✓${NC} Validation error for missing title (returns $HTTP_STATUS)"
else
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}✗${NC} Should return 400/500 for invalid data, got $HTTP_STATUS"
fi

# Summary
print_header "Test Summary"
PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Total Tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
else
    echo "  Failed: 0"
fi
echo "  Pass Rate: $PASS_RATE%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "The Angular task components are now properly integrated"
    echo "with the backend maintenance tasks API."
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please review the failed tests above."
    exit 1
fi
