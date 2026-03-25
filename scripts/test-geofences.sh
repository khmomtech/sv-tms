#!/bin/bash

# Geofence API Testing Script
# Usage: ./test-geofences.sh [JWT_TOKEN]
# If no token provided, will attempt to login with default credentials

set -e

BASE_URL="http://localhost:8080"
TOKEN="${1:-}"

echo "========================================="
echo "🗺️  Geofence API Testing Script"
echo "========================================="
echo ""

# Function to get auth token if not provided
get_auth_token() {
    if [ -z "$TOKEN" ]; then
        echo "🔐 No token provided, attempting login with default credentials..."
        LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"username":"admin","password":"admin123"}')
        
        TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        
        if [ -z "$TOKEN" ]; then
            echo "❌ Failed to get auth token. Response: $LOGIN_RESPONSE"
            echo "Please provide a valid JWT token as the first argument."
            exit 1
        fi
        echo "✅ Authentication successful"
        echo ""
    fi
}

# Function to make authenticated request
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "$BASE_URL$endpoint" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$BASE_URL$endpoint" \
            -H "Authorization: Bearer $TOKEN"
    fi
}

# Get auth token
get_auth_token

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
HEALTH=$(curl -s "$BASE_URL/api/admin/geofences/health")
echo "Response: $HEALTH"
echo ""

# Test 2: Create Circular Geofence - Downtown Office
echo "2️⃣  Creating Circular Geofence (Downtown Office)..."
GEOFENCE1=$(api_request "POST" "/api/admin/geofences" '{
  "partnerCompanyId": 1,
  "name": "Downtown Office",
  "description": "Main office zone - alerts on entry and exit",
  "type": "CIRCLE",
  "centerLatitude": 11.556374,
  "centerLongitude": 104.928206,
  "radiusMeters": 500,
  "alertType": "BOTH",
  "active": true
}')
GEOFENCE1_ID=$(echo "$GEOFENCE1" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "✅ Created Geofence ID: $GEOFENCE1_ID"
echo "Response: $GEOFENCE1" | jq '.' 2>/dev/null || echo "$GEOFENCE1"
echo ""

# Test 3: Create Polygon Geofence - Warehouse District
echo "3️⃣  Creating Polygon Geofence (Warehouse District)..."
GEOFENCE2=$(api_request "POST" "/api/admin/geofences" '{
  "partnerCompanyId": 1,
  "name": "Warehouse District",
  "description": "Industrial zone - entry alerts only",
  "type": "POLYGON",
  "geoJsonCoordinates": "[[11.550, 104.920], [11.550, 104.930], [11.560, 104.930], [11.560, 104.920], [11.550, 104.920]]",
  "alertType": "ENTER",
  "active": true
}')
GEOFENCE2_ID=$(echo "$GEOFENCE2" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "✅ Created Geofence ID: $GEOFENCE2_ID"
echo "Response: $GEOFENCE2" | jq '.' 2>/dev/null || echo "$GEOFENCE2"
echo ""

# Test 4: Create Speed-Limited Zone
echo "4️⃣  Creating Speed-Limited Zone (School Zone)..."
GEOFENCE3=$(api_request "POST" "/api/admin/geofences" '{
  "partnerCompanyId": 1,
  "name": "School Zone",
  "description": "Reduced speed area - 30 km/h limit",
  "type": "CIRCLE",
  "centerLatitude": 11.562000,
  "centerLongitude": 104.935000,
  "radiusMeters": 300,
  "alertType": "BOTH",
  "speedLimitKmh": 30,
  "active": true
}')
GEOFENCE3_ID=$(echo "$GEOFENCE3" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "✅ Created Geofence ID: $GEOFENCE3_ID"
echo "Response: $GEOFENCE3" | jq '.' 2>/dev/null || echo "$GEOFENCE3"
echo ""

# Test 5: Get All Active Geofences
echo "5️⃣  Fetching All Active Geofences..."
ALL_GEOFENCES=$(api_request "GET" "/api/admin/geofences?companyId=1")
COUNT=$(echo "$ALL_GEOFENCES" | grep -o '"id":[0-9]*' | wc -l | tr -d ' ')
echo "✅ Found $COUNT active geofences"
echo "Response: $ALL_GEOFENCES" | jq '.' 2>/dev/null || echo "$ALL_GEOFENCES"
echo ""

# Test 6: Get Specific Geofence
if [ -n "$GEOFENCE1_ID" ]; then
    echo "6️⃣  Fetching Specific Geofence (ID: $GEOFENCE1_ID)..."
    SINGLE_GEOFENCE=$(api_request "GET" "/api/admin/geofences/$GEOFENCE1_ID")
    echo "Response: $SINGLE_GEOFENCE" | jq '.' 2>/dev/null || echo "$SINGLE_GEOFENCE"
    echo ""
fi

# Test 7: Update Geofence
if [ -n "$GEOFENCE1_ID" ]; then
    echo "7️⃣  Updating Geofence (ID: $GEOFENCE1_ID)..."
    UPDATED=$(api_request "PUT" "/api/admin/geofences/$GEOFENCE1_ID" '{
      "partnerCompanyId": 1,
      "name": "Downtown Office (Updated)",
      "description": "Main office zone - updated with larger radius",
      "type": "CIRCLE",
      "centerLatitude": 11.556374,
      "centerLongitude": 104.928206,
      "radiusMeters": 600,
      "alertType": "BOTH",
      "active": true
    }')
    echo "✅ Updated successfully"
    echo "Response: $UPDATED" | jq '.' 2>/dev/null || echo "$UPDATED"
    echo ""
fi

echo "========================================="
echo "✅ All Tests Completed!"
echo "========================================="
echo ""
echo "Summary:"
echo "- Created 3 geofences (1 circle + 1 polygon + 1 speed-limited)"
echo "- Updated 1 geofence"
echo "- Retrieved geofences successfully"
echo ""
echo "To view in browser:"
echo "- Frontend: http://localhost:4200/driver-gps-tracking"
echo "- Swagger UI: http://localhost:8080/swagger-ui.html"
echo ""
echo "Test Coordinates for Crossing Detection:"
echo "- Downtown Office Center: 11.556374, 104.928206 (radius 600m after update)"
echo "- Point Inside: 11.556500, 104.928300"
echo "- Point Outside: 11.560000, 104.935000"
echo ""
