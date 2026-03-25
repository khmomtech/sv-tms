#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-run"
mkdir -p "$RUN_DIR"

CORE_PORT="${CORE_PORT:-8080}"
AUTH_PORT="${AUTH_PORT:-8083}"
UI_PORT="${UI_PORT:-4200}"

stop_port() {
  local port="$1"
  local pids
  pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    echo "Stopping processes on port $port: $pids"
    kill $pids 2>/dev/null || true
    sleep 2
    pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
      kill -9 $pids 2>/dev/null || true
    fi
  fi
}

echo "Stopping Docker API containers that occupy app ports..."
(
  cd "$ROOT_DIR"
  docker compose -f docker-compose.local-dev.yml stop \
    core-api auth-api driver-app-api api-gateway telematics-api safety-api message-api angular \
    >/dev/null 2>&1 || true
)

stop_port "$CORE_PORT"
stop_port "$AUTH_PORT"
stop_port "$UI_PORT"

echo "Starting local auth-api on $AUTH_PORT..."
nohup bash -lc "
  cd '$ROOT_DIR' &&
  exec env \
    SPRING_PROFILES_ACTIVE=local \
    SERVER_PORT='$AUTH_PORT' \
    SERVER_ADDRESS=0.0.0.0 \
    SPRING_JPA_HIBERNATE_DDL_AUTO=none \
    SPRING_JPA_PROPERTIES_HIBERNATE_HBM2DDL_AUTO=none \
    java -jar '$ROOT_DIR/tms-auth-api/target/tms-auth-api-0.0.1-SNAPSHOT.jar'
" >"$RUN_DIR/auth-api.log" 2>&1 &
echo $! > "$RUN_DIR/auth-api.pid"

echo "Starting local core-api on $CORE_PORT..."
nohup bash -lc "
  cd '$ROOT_DIR' &&
  exec env \
    SPRING_PROFILES_ACTIVE=local \
    SERVER_PORT='$CORE_PORT' \
    SERVER_ADDRESS=0.0.0.0 \
    SPRING_DATASOURCE_URL='jdbc:mysql://localhost:3306/svlogistics_tms_db?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&zeroDateTimeBehavior=CONVERT_TO_NULL&allowPublicKeyRetrieval=true&useSSL=false' \
    SPRING_DATASOURCE_USERNAME=driver \
    SPRING_DATASOURCE_PASSWORD=driverpass \
    SPRING_JPA_HIBERNATE_DDL_AUTO=none \
    SPRING_JPA_PROPERTIES_HIBERNATE_HBM2DDL_AUTO=none \
    APP_DRIVER_SKIP_DEVICE_CHECK=true \
    APP_DRIVER_LOGIN_BYPASS=true \
    java -jar '$ROOT_DIR/tms-core-api/target/tms-core-api-0.0.1-SNAPSHOT-exec.jar'
" >"$RUN_DIR/core-api.log" 2>&1 &
echo $! > "$RUN_DIR/core-api.pid"

echo "Starting admin UI on $UI_PORT..."
nohup bash -lc "
  cd '$ROOT_DIR/tms-admin-web-ui' &&
  exec env \
    AUTH_API_PROXY_TARGET='http://127.0.0.1:${AUTH_PORT}' \
    CORE_API_PROXY_TARGET='http://127.0.0.1:${CORE_PORT}' \
    API_PROXY_TARGET='http://127.0.0.1:${CORE_PORT}' \
    npm start -- --host 0.0.0.0 --port '$UI_PORT'
" >"$RUN_DIR/admin-ui.log" 2>&1 &
echo $! > "$RUN_DIR/admin-ui.pid"

cat <<EOF

Local services starting in background.

Ports
- core-api: http://127.0.0.1:${CORE_PORT}
- auth-api: http://127.0.0.1:${AUTH_PORT}
- admin UI: http://127.0.0.1:${UI_PORT}

Logs
- $RUN_DIR/core-api.log
- $RUN_DIR/auth-api.log
- $RUN_DIR/admin-ui.log

Credentials
- admin UI: superadmin / super123
- driver app: drivertest / 123456

Useful checks
- curl http://127.0.0.1:${AUTH_PORT}/actuator/health
- curl http://127.0.0.1:${CORE_PORT}/actuator/health
- curl http://127.0.0.1:${CORE_PORT}/ws-sockjs/info?t=1
EOF
