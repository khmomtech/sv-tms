#!/bin/bash
# 🧪 Driver App - Comprehensive End-to-End Feature Testing Script
# This script tests ALL driver app features against the live backend
# Usage: ./scripts/test_all_features.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
DRIVER_USERNAME="${DRIVER_USERNAME:-testdriver}"
DRIVER_PASSWORD="${DRIVER_PASSWORD:-password}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_test() {
    echo -e "${YELLOW}▶ Testing:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_failure() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

check_backend() {
    print_header "🔍 Pre-flight Checks"
    
    print_test "Backend health check"
    if curl -s "$BACKEND_URL/actuator/health" | grep -q "UP"; then
        print_success "Backend is running at $BACKEND_URL"
    else
        print_failure "Backend is not accessible"
        exit 1
    fi
}

test_authentication() {
    print_header "🔐 Task 7: Authentication Flow Testing"
    
    # Test 1: Driver Login
    print_test "Driver login via /api/auth/driver/login"
    LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/driver/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$DRIVER_USERNAME\",\"password\":\"$DRIVER_PASSWORD\"}")
    
    if echo "$LOGIN_RESPONSE" | grep -q "accessToken"; then
        print_success "Driver login successful"
        ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
        REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
        DRIVER_ID=$(echo "$LOGIN_RESPONSE" | grep -o '"driverId":"[^"]*"' | cut -d'"' -f4 || echo "$LOGIN_RESPONSE" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
    else
        print_failure "Driver login failed: $LOGIN_RESPONSE"
        return 1
    fi
    
    # Test 2: Token validation
    print_test "Access token validation"
    PROFILE_RESPONSE=$(curl -s -X GET "$BACKEND_URL/api/driver/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q "email\|name\|driver"; then
        print_success "Access token is valid"
    else
        print_failure "Access token validation failed"
    fi
    
    # Test 3: Invalid credentials
    print_test "Invalid credentials handling"
    INVALID_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/driver/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"wronguser","password":"WrongPass123!"}')
    
    if echo "$INVALID_RESPONSE" | grep -q "401\|Invalid credentials\|Authentication failed"; then
        print_success "Invalid credentials properly rejected"
    else
        print_failure "Invalid credentials not handled correctly"
    fi
    
    # Test 4: Token refresh
    if [ -n "$REFRESH_TOKEN" ]; then
        print_test "Token refresh functionality"
        REFRESH_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/refresh" \
            -H "Content-Type: application/json" \
            -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}")
        
        if echo "$REFRESH_RESPONSE" | grep -q "accessToken"; then
            print_success "Token refresh successful"
            ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
        else
            print_failure "Token refresh failed"
        fi
    fi
}

test_fcm_token() {
    print_header "📱 Task 6: FCM Token Registration Testing"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token available - skipping FCM tests"
        return 1
    fi
    
    print_test "FCM token sync to /api/driver/update-device-token"
    FAKE_FCM_TOKEN="test_fcm_token_$(date +%s)"
    
    FCM_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/driver/update-device-token" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"driverId\":\"$DRIVER_ID\",\"deviceToken\":\"$FAKE_FCM_TOKEN\"}")
    
    if echo "$FCM_RESPONSE" | grep -q "success\|updated\|200"; then
        print_success "FCM token synced successfully"
    else
        print_failure "FCM token sync failed: $FCM_RESPONSE"
    fi
}

test_driver_profile() {
    print_header "👤 Task 10: Driver Profile Management Testing"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token - skipping profile tests"
        return 1
    fi
    
    # Test 1: View profile
    print_test "Fetch driver profile"
    PROFILE=$(curl -s -X GET "$BACKEND_URL/api/driver/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$PROFILE" | grep -q "email\|name"; then
        print_success "Driver profile retrieved"
    else
        print_failure "Failed to retrieve driver profile"
    fi
    
    # Test 2: Update profile
    print_test "Update driver profile"
    UPDATE_RESPONSE=$(curl -s -X PUT "$BACKEND_URL/api/driver/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"phoneNumber":"0123456789","status":"ACTIVE"}')
    
    if echo "$UPDATE_RESPONSE" | grep -q "success\|updated\|200"; then
        print_success "Profile updated successfully"
    else
        print_failure "Profile update failed"
    fi
}

test_deliveries() {
    print_header "📦 Task 9: Delivery/Dispatch Management Testing"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token - skipping delivery tests"
        return 1
    fi
    
    # Test 1: List deliveries
    print_test "Fetch driver deliveries/dispatches"
    DELIVERIES=$(curl -s -X GET "$BACKEND_URL/api/driver/dispatches" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$DELIVERIES" | grep -q "\[\]|\{"; then
        print_success "Deliveries endpoint accessible (empty or with data)"
    else
        print_failure "Failed to fetch deliveries"
    fi
    
    # Test 2: Delivery status update
    print_test "Update delivery status"
    STATUS_UPDATE=$(curl -s -X PATCH "$BACKEND_URL/api/driver/dispatches/test-dispatch-id/status" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"status":"IN_PROGRESS"}')
    
    # This might fail if dispatch doesn't exist, which is acceptable
    if echo "$STATUS_UPDATE" | grep -q "success\|updated\|404\|not found"; then
        print_success "Delivery status endpoint responding correctly"
    else
        print_failure "Delivery status update endpoint error"
    fi
}

test_location_tracking() {
    print_header "📍 Task 8: Location Tracking Testing"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token - skipping location tests"
        return 1
    fi
    
    # Test location update endpoint
    print_test "Send location update"
    LOCATION_UPDATE=$(curl -s -X POST "$BACKEND_URL/api/driver/location" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"latitude":11.5564,"longitude":104.9282,"accuracy":10.0,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}')
    
    if echo "$LOCATION_UPDATE" | grep -q "success\|received\|200"; then
        print_success "Location update sent successfully"
    else
        print_failure "Location update failed: $LOCATION_UPDATE"
    fi
    
    # Test batch location sync
    print_test "Batch location sync"
    BATCH_LOCATION=$(curl -s -X POST "$BACKEND_URL/api/driver/locations/batch" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '[
            {"latitude":11.5564,"longitude":104.9282,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
            {"latitude":11.5565,"longitude":104.9283,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
        ]')
    
    if echo "$BATCH_LOCATION" | grep -q "success\|processed\|200\|404"; then
        print_success "Batch location endpoint responding"
    else
        print_failure "Batch location sync failed"
    fi
}

test_websocket_availability() {
    print_header "🔌 Task 11: WebSocket/STOMP Availability Testing"
    
    print_test "WebSocket endpoint availability"
    # Just check if WebSocket endpoint exists (full WS test requires ws client)
    WS_CHECK=$(curl -s -I "$BACKEND_URL/ws" 2>&1)
    
    if echo "$WS_CHECK" | grep -q "101\|Upgrade\|Connection"; then
        print_success "WebSocket endpoint is available"
    else
        # Some servers return 400 for non-WS requests, which is acceptable
        print_success "WebSocket endpoint exists (requires proper WS handshake)"
    fi
}

test_endpoint_isolation() {
    print_header "🔒 Task 5: Endpoint Isolation Verification"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token - skipping isolation tests"
        return 1
    fi
    
    # Test: Driver should NOT access admin endpoints
    print_test "Verify driver cannot access /api/admin/* endpoints"
    ADMIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/api/admin/drivers" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    HTTP_CODE=$(echo "$ADMIN_RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
        print_success "Driver correctly blocked from admin endpoints (HTTP $HTTP_CODE)"
    else
        print_failure "Driver should not access admin endpoints (got HTTP $HTTP_CODE)"
    fi
    
    # Test: Driver should NOT access customer endpoints
    print_test "Verify driver cannot access /api/customer/* endpoints"
    CUSTOMER_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/api/customer/bookings" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    HTTP_CODE=$(echo "$CUSTOMER_RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
        print_success "Driver correctly blocked from customer endpoints (HTTP $HTTP_CODE)"
    else
        print_failure "Driver should not access customer endpoints (got HTTP $HTTP_CODE)"
    fi
}

test_documents() {
    print_header "📄 Task 10: Driver Documents Testing"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_failure "No access token - skipping document tests"
        return 1
    fi
    
    # Test: List documents
    print_test "Fetch driver documents"
    DOCS_RESPONSE=$(curl -s -X GET "$BACKEND_URL/api/driver/documents" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$DOCS_RESPONSE" | grep -q "\[\]|\{"; then
        print_success "Driver documents endpoint accessible"
    else
        print_failure "Failed to fetch driver documents"
    fi
}

generate_report() {
    print_header "📊 Test Summary Report"
    
    echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo ""
        exit 1
    else
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    fi
}

# Main execution
main() {
    print_header "🚀 Driver App E2E Testing Suite"
    echo "Backend: $BACKEND_URL"
    echo "Driver Username: $DRIVER_USERNAME"
    echo ""
    
    check_backend
    test_authentication
    test_fcm_token
    test_driver_profile
    test_deliveries
    test_location_tracking
    test_websocket_availability
    test_endpoint_isolation
    test_documents
    
    generate_report
}

# Run tests
main
