#!/usr/bin/env zsh
set -euo pipefail

# Export backend OpenAPI to api/driver-app-openapi.json using the built JAR for tms-backend
# Usage: ./scripts/export-openapi-tms.sh

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
JAR="$ROOT_DIR/tms-backend/target/tms-backend-0.0.1-SNAPSHOT.jar"
OUT="$ROOT_DIR/api/driver-app-openapi.json"

if [ ! -f "$JAR" ]; then
  echo "JAR not found at $JAR. Run ./mvnw -q -DskipTests package in tms-backend first." >&2
  exit 1
fi

PORT="${EXPORT_SERVER_PORT:-8085}"
export SERVER_PORT="$PORT"

# Start a temporary server on an alternate port with in-memory DB
SPRING_DATASOURCE_URL=jdbc:h2:mem:devdb;MODE=MySQL;DB_CLOSE_DELAY=-1 \
SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop \
SPRING_FLYWAY_ENABLED=false \
SPRING_TASK_SCHEDULING_ENABLED=false \
APP_INIT_AUDIT=false \
SPRING_PROFILES_ACTIVE=export \
java -Dspring.profiles.active=export \
  -Dspring.jpa.hibernate.ddl-auto=create-drop \
  -Dspring.flyway.enabled=false \
  -Dspring.task.scheduling.enabled=false \
  -Dapp.init-audit=false \
  -Dserver.port="$PORT" \
  -jar "$JAR" &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT

# wait for health
ATTEMPTS=0
until curl -sS "http://localhost:${PORT}/actuator/health" >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS+1))
  if [ $ATTEMPTS -ge 90 ]; then
    echo "Server did not become ready" >&2
    kill $PID || true
    exit 1
  fi
  sleep 1
done

# fetch openapi
curl -fsSL "http://localhost:${PORT}/v3/api-docs" -o "$OUT"

bytes=$(wc -c < "$OUT" | tr -d ' ')
echo "Exported OpenAPI (${bytes} bytes) to $OUT"
kill $PID || true
