#!/bin/bash

# Angular Tasks Components Smoke Tests
# Tests task list, detail, and form functionality

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Base URLs
BACKEND_URL="http://localhost:8080/api"
FRONTEND_URL="http://localhost:4200"

# Authentication
TOKEN=""
ADMIN_USERNAME="superadmin"
ADMIN_PASSWORD="super123"

# Helper functions
print_header() {
    echo ""
    echo "==== $1 ===="
}

assert_equals() {
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
        echo "  Expected: $expected"
        echo "  Actual: $actual"
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

# Check if backend is running
print_header "Checking Backend Availability"
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/../actuator/health")
if [ "$BACKEND_HEALTH" != "200" ]; then
    echo -e "${RED}✗${NC} Backend is not running at $BACKEND_URL"
    echo "Please start the backend first: cd tms-backend && ./mvnw spring-boot:run"
    exit 1
fi
echo -e "${GREEN}✓${NC} Backend is running"

# Check if frontend is running
print_header "Checking Frontend Availability"
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
if [ "$FRONTEND_HEALTH" != "200" ]; then
    echo -e "${YELLOW}⚠${NC} Frontend might not be running at $FRONTEND_URL (HTTP $FRONTEND_HEALTH)"
    echo "Note: Some tests require the frontend server to be running"
fi

# Login to get token
print_header "Authenticating as Admin"
LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}")

# Try both possible token field names
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗${NC} Failed to authenticate. Response: $LOGIN_RESPONSE"
    exit 1
fi
echo -e "${GREEN}✓${NC} Authentication successful"

# Test 1: Get Tasks List (Endpoint used by task-list.component.ts)
print_header "Test 1: GET /api/tasks - List all tasks with pagination"
TASKS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks?page=0&size=10&sortBy=createdDate&sortDir=DESC" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$TASKS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$TASKS_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"success":true' "Response has success=true"
assert_contains "$RESPONSE_BODY" '"content":\[' "Response has content array"
assert_contains "$RESPONSE_BODY" '"totalPages"' "Response has totalPages"
assert_contains "$RESPONSE_BODY" '"totalElements"' "Response has totalElements"

# Test 2: Search Tasks (task-list.component.ts onSearch)
print_header "Test 2: GET /api/tasks - Search with keyword"
SEARCH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks?page=0&size=10&keyword=test" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$SEARCH_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$SEARCH_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Search returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"success":true' "Search response has success=true"

# Test 3: Get Tasks by Status (task-list.component.ts loadFilteredTasks)
print_header "Test 3: GET /api/tasks/status/{status} - Filter by status"
STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/status/NOT_STARTED?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$STATUS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$STATUS_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Filter by status returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"success":true' "Filter response has success=true"

# Test 4: Get My Tasks (Used in dashboard/task views)
print_header "Test 4: GET /api/tasks/my-tasks - Get assigned tasks"
MY_TASKS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/my-tasks?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$MY_TASKS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$MY_TASKS_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "My tasks returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"success":true' "My tasks response has success=true"

# Test 5: Get Task Statistics (Dashboard widget)
print_header "Test 5: GET /api/tasks/statistics - Get task statistics"
STATS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/statistics" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$STATS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$STATS_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Statistics returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"success":true' "Statistics response has success=true"

# Test 6: Create Task (task-form.component.ts onSubmit)
print_header "Test 6: POST /api/tasks - Create new task"
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/tasks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "title": "Smoke Test Task",
        "description": "This is a test task created by smoke tests",
        "taskType": "BUG_FIX",
        "status": "NOT_STARTED",
        "priority": "MEDIUM",
        "dueDate": "2025-12-31T23:59:59"
    }')

HTTP_STATUS=$(echo "$CREATE_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

assert_http_status "201" "$HTTP_STATUS" "Create task returns HTTP 201"
assert_contains "$RESPONSE_BODY" '"success":true' "Create response has success=true"
assert_contains "$RESPONSE_BODY" '"title":"Smoke Test Task"' "Created task has correct title"

# Extract task ID for subsequent tests
TASK_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$TASK_ID" ]; then
    echo -e "${GREEN}✓${NC} Created task with ID: $TASK_ID"

    # Test 7: Get Task by ID (task-detail.component.ts loadTask)
    print_header "Test 7: GET /api/tasks/{id} - Get task details"
    DETAIL_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_STATUS=$(echo "$DETAIL_RESPONSE" | tail -n 1)
    RESPONSE_BODY=$(echo "$DETAIL_RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Get task by ID returns HTTP 200"
    assert_contains "$RESPONSE_BODY" '"success":true' "Detail response has success=true"
    assert_contains "$RESPONSE_BODY" "\"id\":$TASK_ID" "Returns correct task ID"

    # Test 8: Update Task Status (task-detail.component.ts updateStatus)
    print_header "Test 8: PUT /api/tasks/{id}/status - Update task status"
    STATUS_UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BACKEND_URL/tasks/$TASK_ID/status?status=IN_PROGRESS" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_STATUS=$(echo "$STATUS_UPDATE_RESPONSE" | tail -n 1)
    RESPONSE_BODY=$(echo "$STATUS_UPDATE_RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Update status returns HTTP 200"
    assert_contains "$RESPONSE_BODY" '"success":true' "Status update response has success=true"
    assert_contains "$RESPONSE_BODY" '"status":"IN_PROGRESS"' "Status updated to IN_PROGRESS"

    # Test 9: Update Task (task-form.component.ts onSubmit in edit mode)
    print_header "Test 9: PUT /api/tasks/{id} - Update task details"
    UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BACKEND_URL/tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"id\": $TASK_ID,
            \"title\": \"Updated Smoke Test Task\",
            \"description\": \"This task has been updated\",
            \"taskType\": \"BUG_FIX\",
            \"status\": \"IN_PROGRESS\",
            \"priority\": \"HIGH\",
            \"dueDate\": \"2025-12-31T23:59:59\"
        }")

    HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | tail -n 1)
    RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Update task returns HTTP 200"
    assert_contains "$RESPONSE_BODY" '"success":true' "Update response has success=true"
    assert_contains "$RESPONSE_BODY" '"title":"Updated Smoke Test Task"' "Task title updated"
    assert_contains "$RESPONSE_BODY" '"priority":"HIGH"' "Task priority updated"

    # Test 10: Delete Task (task-detail.component.ts deleteTask)
    print_header "Test 10: DELETE /api/tasks/{id} - Delete task"
    DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BACKEND_URL/tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_STATUS=$(echo "$DELETE_RESPONSE" | tail -n 1)
    RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

    assert_http_status "200" "$HTTP_STATUS" "Delete task returns HTTP 200"
    assert_contains "$RESPONSE_BODY" '"success":true' "Delete response has success=true"

    # Verify deletion
    print_header "Test 11: Verify task deletion"
    VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/$TASK_ID" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_STATUS=$(echo "$VERIFY_RESPONSE" | tail -n 1)

    assert_http_status "404" "$HTTP_STATUS" "Deleted task returns HTTP 404"
else
    echo -e "${YELLOW}⚠${NC} Could not extract task ID, skipping detail/update/delete tests"
    TOTAL_TESTS=$((TOTAL_TESTS + 5))
    FAILED_TESTS=$((FAILED_TESTS + 5))
fi

# Test 12: Validation - Create task without required fields
print_header "Test 12: POST /api/tasks - Validation (missing required fields)"
VALIDATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/tasks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}')

HTTP_STATUS=$(echo "$VALIDATION_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$VALIDATION_RESPONSE" | sed '$d')

assert_http_status "400" "$HTTP_STATUS" "Missing required fields returns HTTP 400"

# Test 13: Invalid Status Filter
print_header "Test 13: GET /api/tasks/status/{status} - Invalid status"
INVALID_STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks/status/INVALID_STATUS?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$INVALID_STATUS_RESPONSE" | tail -n 1)

# Should return 400 or 404 depending on implementation
if [ "$HTTP_STATUS" = "400" ] || [ "$HTTP_STATUS" = "404" ] || [ "$HTTP_STATUS" = "500" ]; then
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✓${NC} Invalid status handled appropriately (HTTP $HTTP_STATUS)"
else
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}✗${NC} Invalid status should return error status (got HTTP $HTTP_STATUS)"
fi

# Test 14: Pagination Edge Cases
print_header "Test 14: GET /api/tasks - Pagination edge cases"
LARGE_PAGE_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks?page=9999&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$LARGE_PAGE_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$LARGE_PAGE_RESPONSE" | sed '$d')

assert_http_status "200" "$HTTP_STATUS" "Large page number returns HTTP 200"
assert_contains "$RESPONSE_BODY" '"content":\[\]' "Empty page returns empty array"

# Test 15: Unauthorized Access (No token)
print_header "Test 15: GET /api/tasks - Unauthorized access"
UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/tasks")

HTTP_STATUS=$(echo "$UNAUTH_RESPONSE" | tail -n 1)

assert_http_status "401" "$HTTP_STATUS" "No token returns HTTP 401"

# Summary
print_header "Test Summary"
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
else
    echo "Failed: 0"
fi

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi
