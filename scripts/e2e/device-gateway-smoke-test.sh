#!/usr/bin/env bash

# Smoke test for device-gateway + persistence.
# Usage: ./scripts/e2e/device-gateway-smoke-test.sh

set -euo pipefail

# Configurable values
GATEWAY_URL=${GATEWAY_URL:-http://localhost:8085}
DEVICE_ID=${DEVICE_ID:-SMOKE_TEST_DEVICE}
SEQ=${SEQ:-$(date +%s)}
MYSQL_CONTAINER=${MYSQL_CONTAINER:-svtms-mysql}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-rootpass}

echo "Running device-gateway smoke test..."

echo "1) Health check"
HEALTH=$(curl -s -f "$GATEWAY_URL/actuator/health")
echo "Health: $HEALTH"

echo "2) Ingest telemetry"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$GATEWAY_URL/api/device/telemetry" \
  -H 'Content-Type: application/json' \
  -d "[{\"deviceId\":\"$DEVICE_ID\",\"sequenceNumber\":$SEQ,\"latitude\":12.34,\"longitude\":56.78,\"accuracy\":5.0}]" )

if [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: expected 201, got $HTTP_CODE"
  exit 1
fi

echo "3) Validate persistence in MySQL"
RESULT=$(docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PW" -sse \
  "SELECT COUNT(*) FROM device_gateway.telemetry_point WHERE device_id='$DEVICE_ID' AND sequence_number=$SEQ;")

if [ "$RESULT" != "1" ]; then
  echo "ERROR: expected 1 row in telemetry_point, found $RESULT"
  exit 1
fi

echo "✅ Device-gateway smoke test passed (deviceId=$DEVICE_ID, sequence=$SEQ)"
