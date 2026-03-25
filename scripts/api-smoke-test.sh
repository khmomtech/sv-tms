#!/usr/bin/env bash
# Simple API smoke-test for the dispatch flow.
# Usage:
#   BASE="http://localhost:8080" TOKEN="Bearer <JWT>" ./scripts/api-smoke-test.sh
set -euo pipefail
BASE=${BASE:-http://localhost:8080}
TOKEN=${TOKEN:-"Bearer <JWT>"}
DRIVER_TOKEN=${DRIVER_TOKEN:-$TOKEN}

echo "Create dispatch..."
curl -s -X POST "$BASE/api/admin/dispatches" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerId":123,"routeCode":"R001","pickup":"A","dropoff":"B","eta":"2025-12-24T09:00:00"}' | jq .

echo "\nAssign driver & truck (replace IDs)..."
# replace 456,12,34 as needed
curl -s -X POST "$BASE/api/admin/dispatches/456/assign?driverId=12&vehicleId=34" \
  -H "Authorization: $TOKEN" | jq .

echo "\nDriver accept (driver token)..."
curl -s -X POST "$BASE/api/driver/dispatches/456/accept" \
  -H "Authorization: $DRIVER_TOKEN" | jq .

echo "\nSubmit load proof (multipart)"
# Note: adjust file paths
curl -s -X POST "$BASE/api/admin/dispatches/456/load" \
  -H "Authorization: $DRIVER_TOKEN" \
  -F "remarks=Loaded at warehouse" \
  -F "images=@/tmp/example-load-1.jpg" \
  -F "signature=@/tmp/example-sign.png" | jq .

echo "\nGenerate safety PDF (download to file)..."
curl -s -X GET "$BASE/api/admin/dispatches/456/safety-pdf" \
  -H "Authorization: $TOKEN" --output safety-456.pdf && echo "Saved safety-456.pdf"

echo "\nMark status to LOADED"
curl -s -X PATCH "$BASE/api/admin/dispatches/456/status?status=LOADED" \
  -H "Authorization: $TOKEN" | jq .

echo "\nSubmit unload proof"
curl -s -X POST "$BASE/api/admin/dispatches/456/unload" \
  -H "Authorization: $DRIVER_TOKEN" \
  -F "remarks=Delivered to customer" \
  -F "images=@/tmp/example-unload-1.jpg" | jq .

echo "\nMark delivered"
curl -s -X PATCH "$BASE/api/admin/dispatches/456/status?status=DELIVERED" \
  -H "Authorization: $TOKEN" | jq .

echo "\nGet dispatch and status history"
curl -s -X GET "$BASE/api/admin/dispatches/456" -H "Authorization: $TOKEN" | jq .
curl -s -X GET "$BASE/api/admin/dispatches/456/status-history" -H "Authorization: $TOKEN" | jq .

echo "\nChange truck (expect optional warning)"
# To test the warning behavior, call change-truck with a vehicle that the current driver is NOT assigned to.
# Replace 456 and 99 with appropriate dispatchId and a vehicleId that is not assigned to the driver.
CHANGE_DISPATCH_ID=${CHANGE_DISPATCH_ID:-456}
CHANGE_VEHICLE_ID=${CHANGE_VEHICLE_ID:-99}
EXPECT_WARNING=${EXPECT_WARNING:-false}

resp=$(curl -s -X PUT "$BASE/api/admin/dispatches/$CHANGE_DISPATCH_ID/change-truck?vehicleId=$CHANGE_VEHICLE_ID" \
  -H "Authorization: $TOKEN")
echo "$resp" | jq .

if [ "$EXPECT_WARNING" = "true" ]; then
  if echo "$resp" | jq -e '.["errors"].warnings' >/dev/null 2>&1; then
    echo "Warning present as expected."
  else
    echo "Expected warning not present!" >&2
    exit 2
  fi
fi

echo "\nSmoke test completed."
