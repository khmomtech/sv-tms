#!/usr/bin/env bash
set -euo pipefail

STACK_ROOT=/opt/sv-tms
COMPOSE_FILE=${COMPOSE_FILE:-$STACK_ROOT/infra/docker-compose.prod.yml}
ENV_FILE=${ENV_FILE:-$STACK_ROOT/infra/.env}
HTTP_BASE=${HTTP_BASE:-http://localhost}

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

check_url() {
  local name=$1
  local url=$2
  echo "[smoke] $name -> $url"
  curl -fsS "$url" >/dev/null
}

check_service_health() {
  local service=$1
  local port=$2
  echo "[smoke] $service actuator health"
  compose exec -T "$service" curl -fsS "http://localhost:${port}/actuator/health" >/dev/null
}

check_service_health core-api 8080
check_service_health auth-api 8083
check_service_health driver-app-api 8084
check_service_health telematics-api 8082
check_service_health safety-api 8087
check_service_health message-api 8088
check_service_health api-gateway 8086

check_url "nginx root" "${HTTP_BASE}/"
check_url "gateway health" "${HTTP_BASE}/actuator/health"

echo "[smoke] OK"
