#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the telemetry stream pipeline: Redis stream → tms-telematics consumer → Postgres
# Usage: ./scripts/telemetry-pipeline-smoke-test.sh

DRIVER_ID=${DRIVER_ID:-99999999}
LAT=${LAT:-12.345678}
LON=${LON:-98.765432}

echo "Running telemetry pipeline smoke test (driverId=${DRIVER_ID}, lat=${LAT}, lon=${LON})"

# Produce a stream event
STREAM_ID=$(docker compose -f docker-compose.dev.yml exec -T redis redis-cli xadd telemetry:events '*' driverId ${DRIVER_ID} eventTime "$(date -u +%Y-%m-%dT%H:%M:%SZ)" latitude ${LAT} longitude ${LON} | tr -d '\r')

echo "  -> produced stream entry ${STREAM_ID}"

# Poll Postgres for the inserted record up to a timeout.
MAX_WAIT=20
SLEEP=1
elapsed=0

while true; do
  row=$(docker compose -f docker-compose.dev.yml exec -T postgres psql -U tele_user -d svlogistics_telematics -t -A -c "select latitude, longitude from driver_latest_location where driver_id=${DRIVER_ID};" | tr -d '\r')
  if [[ -n "$row" ]]; then
    echo "  -> found row in Postgres: $row"
    # Validate lat/lon match expected values
    if [[ "$row" == "${LAT}|${LON}" ]]; then
      echo "✅ Smoke test passed: telemetry pipeline delivered the record to Postgres."
      exit 0
    else
      echo "⚠️  Row found but values mismatch (expected ${LAT}|${LON}): $row"
      exit 1
    fi
  fi

  if (( elapsed >= MAX_WAIT )); then
    echo "❌ Timeout: record not found in Postgres after ${MAX_WAIT}s."
    exit 2
  fi

  sleep ${SLEEP}
  elapsed=$((elapsed + SLEEP))
  echo "  waiting... (${elapsed}s)"

done
