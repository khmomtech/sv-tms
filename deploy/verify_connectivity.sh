#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Connectivity & Stack Verification Script
# Run this ON the VPS after deploying to confirm everything is working.
#
# Usage:
#   ssh root@207.180.245.156
#   cd /opt/sv-tms
#   bash deploy/verify_connectivity.sh
#
# Or from local machine with an external URL:
#   BASE_URL=https://svtms.svtrucking.biz bash deploy/verify_connectivity.sh --external
# =============================================================================
set -euo pipefail

DOMAIN="${DOMAIN:-svtms.svtrucking.biz}"
BASE_URL="${BASE_URL:-https://${DOMAIN}}"
COMPOSE_FILE="${COMPOSE_FILE:-/opt/sv-tms/infra/docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-/opt/sv-tms/infra/.env}"
EXTERNAL_MODE=false
[[ "${1:-}" == "--external" ]] && EXTERNAL_MODE=true

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0

ok()   { echo -e "${GREEN}  ✅  $*${NC}"; ((PASS++)) || true; }
fail() { echo -e "${RED}  ❌  $*${NC}"; ((FAIL++)) || true; }
warn() { echo -e "${YELLOW}  ⚠️   $*${NC}"; ((WARN++)) || true; }
info() { echo -e "${CYAN}  ℹ️   $*${NC}"; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ── Helper: HTTP check (with retry) ───────────────────────────────────────────
check_http() {
  local label="$1" url="$2" expected_code="${3:-200}" grep_body="${4:-}"
  local attempts=0
  while (( attempts < 3 )); do
    local http_code
    if [[ -n "${grep_body}" ]]; then
      body=$(curl -sk --max-time 8 -o - -w '' "${url}" 2>/dev/null || true)
      http_code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
      if [[ "${http_code}" == "${expected_code}" ]] && echo "${body}" | grep -q "${grep_body}"; then
        ok "${label} [${http_code}]"
        return 0
      fi
    else
      http_code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
      if [[ "${http_code}" == "${expected_code}" ]]; then
        ok "${label} [${http_code}]"
        return 0
      fi
    fi
    ((attempts++))
    sleep 2
  done
  fail "${label} — expected HTTP ${expected_code}, got ${http_code:-???} (${url})"
  return 1
}

# ── Helper: Check container is running and healthy ─────────────────────────────
check_container() {
  local name="$1" service="$2"
  local status
  status=$(docker inspect --format='{{.State.Status}}' "${name}" 2>/dev/null || echo "missing")
  local health
  health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "${name}" 2>/dev/null || echo "missing")
  if [[ "${status}" == "running" ]]; then
    if [[ "${health}" == "healthy" || "${health}" == "no-healthcheck" ]]; then
      ok "Container ${name}: running (health=${health})"
    else
      warn "Container ${name}: running but health=${health}"
    fi
  else
    fail "Container ${name}: status=${status}"
  fi
}

# ==============================================================================
echo -e "\n${BOLD}SV-TMS Connectivity Verification${NC}"
echo "  Domain  : ${DOMAIN}"
echo "  Base URL: ${BASE_URL}"
echo "  Mode    : $(${EXTERNAL_MODE} && echo 'External (from internet)' || echo 'Internal (on VPS)')"
echo "  Date    : $(date)"

# ── Section 1: Docker containers ──────────────────────────────────────────────
section "1. Docker Container Status"
for svc in mysql postgres mongo redis kafka-1 kafka-2 kafka-3 \
           core-api auth-api telematics-api driver-app-api safety-api \
           message-api api-gateway admin-web-ui nginx; do
  check_container "svtms-${svc}" "${svc}"
done

# ── Section 2: Internal API health (via localhost, VPS only) ──────────────────
if ! ${EXTERNAL_MODE}; then
  section "2. Internal API Health Endpoints (localhost)"
  declare -A SERVICES=(
    ["core-api"]="8080"
    ["auth-api"]="8083"
    ["telematics-api"]="8082"
    ["driver-app-api"]="8084"
    ["safety-api"]="8087"
    ["message-api"]="8088"
    ["api-gateway"]="8086"
  )
  for svc in "${!SERVICES[@]}"; do
    port="${SERVICES[$svc]}"
    check_http "  ${svc} /actuator/health" \
      "http://127.0.0.1:${port}/actuator/health" "200" '"status":"UP"'
  done
fi

# ── Section 3: SSL / HTTPS ─────────────────────────────────────────────────────
section "3. SSL Certificate"
cert_expiry=$(echo | timeout 5 openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null \
  | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "FAILED")
if [[ "${cert_expiry}" == "FAILED" ]]; then
  fail "Cannot retrieve SSL certificate — is nginx running and domain DNS propagated?"
else
  expiry_epoch=$(date -d "${cert_expiry}" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "${cert_expiry}" +%s 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
  if (( days_left > 14 )); then
    ok "TLS cert valid — expires in ${days_left} days (${cert_expiry})"
  elif (( days_left > 0 )); then
    warn "TLS cert expires in ${days_left} days — renew soon!"
  else
    fail "TLS cert EXPIRED (${cert_expiry})"
  fi
fi

# ── Section 4: HTTP → HTTPS redirect ─────────────────────────────────────────
section "4. HTTP → HTTPS Redirect"
redirect_code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "http://${DOMAIN}/" 2>/dev/null || echo "000")
if [[ "${redirect_code}" == "301" || "${redirect_code}" == "302" ]]; then
  ok "HTTP redirect: ${redirect_code} → HTTPS"
else
  fail "HTTP redirect not working (got ${redirect_code}, expected 301)"
fi

# ── Section 5: Admin Web UI ────────────────────────────────────────────────────
section "5. Admin Web UI (Angular SPA)"
check_http "  HTTPS root loads" "${BASE_URL}/" "200"
# Check Angular is actually served (index.html will contain ng- or app-root)
body=$(curl -sk --max-time 10 "${BASE_URL}/" 2>/dev/null || true)
if echo "${body}" | grep -qE "app-root|ng-version|<app|angular"; then
  ok "  Angular SPA content detected in response body"
elif echo "${body}" | grep -q "<!DOCTYPE html>"; then
  warn "  HTML served but Angular markers not found — check build output path"
else
  fail "  Response does not look like Angular SPA"
fi
# SPA deep-link routing (Angular handles client-side routes)
check_http "  SPA deep-link /dashboard returns 200" "${BASE_URL}/dashboard" "200"

# ── Section 6: API Gateway ────────────────────────────────────────────────────
section "6. API Gateway (/api/*)"
check_http "  /actuator/health" "${BASE_URL}/actuator/health" "200" '"status":"UP"'
check_http "  /api/v1/auth/login rejects empty body (400)" "${BASE_URL}/api/v1/auth/login" "400"
check_http "  /api/* protected route returns 401 (not 403/500)" "${BASE_URL}/api/v1/loads" "401"

# ── Section 7: Security Headers ───────────────────────────────────────────────
section "7. Security Headers"
headers=$(curl -sk --max-time 8 -I "${BASE_URL}/" 2>/dev/null || true)
for header in "strict-transport-security" "x-frame-options" "x-content-type-options"; do
  if echo "${headers,,}" | grep -q "${header}"; then
    ok "  Header present: ${header}"
  else
    fail "  Header MISSING: ${header}"
  fi
done

# ── Section 8: WebSocket endpoint ────────────────────────────────────────────
section "8. WebSocket Endpoint"
ws_code=$(curl -sk --max-time 5 -o /dev/null -w "%{http_code}" \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "${BASE_URL}/ws" 2>/dev/null || echo "000")
if [[ "${ws_code}" == "101" || "${ws_code}" == "400" || "${ws_code}" == "426" ]]; then
  ok "  /ws WebSocket endpoint reachable (HTTP ${ws_code})"
else
  warn "  /ws WebSocket returned ${ws_code} — check nginx proxy and core-api"
fi

# ── Section 9: Response time baseline ────────────────────────────────────────
section "9. Response Time Baseline"
time_ms=$(curl -sk --max-time 10 -o /dev/null -w "%{time_total}" "${BASE_URL}/" 2>/dev/null || echo "99")
time_ms_int=$(echo "${time_ms} * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "9999")
if (( time_ms_int < 3000 )); then
  ok "  Admin UI load time: ${time_ms}s (< 3s)"
else
  warn "  Admin UI load time: ${time_ms}s (> 3s threshold)"
fi

api_time=$(curl -sk --max-time 10 -o /dev/null -w "%{time_total}" "${BASE_URL}/actuator/health" 2>/dev/null || echo "99")
api_time_int=$(echo "${api_time} * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "9999")
if (( api_time_int < 1000 )); then
  ok "  API health response time: ${api_time}s (< 1s)"
else
  warn "  API health response time: ${api_time}s (> 1s threshold)"
fi

# ── Section 10: Disk & memory headroom ───────────────────────────────────────
if ! ${EXTERNAL_MODE}; then
  section "10. System Resources"
  disk_pct=$(df / | awk 'NR==2{print $5}' | tr -d '%')
  if (( disk_pct < 80 )); then
    ok "  Disk usage: ${disk_pct}% (healthy)"
  elif (( disk_pct < 90 )); then
    warn "  Disk usage: ${disk_pct}% (getting full — clean up logs/images)"
  else
    fail "  Disk usage: ${disk_pct}% — CRITICAL, free up space immediately"
  fi

  mem_free=$(free -m | awk '/^Mem/{print $7}')
  if (( mem_free > 512 )); then
    ok "  Free memory: ${mem_free} MB (healthy)"
  elif (( mem_free > 256 )); then
    warn "  Free memory: ${mem_free} MB (low)"
  else
    fail "  Free memory: ${mem_free} MB — very low, stack may be OOM"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════ RESULTS ══════════════════${NC}"
echo -e "  ${GREEN}Passed : ${PASS}${NC}"
[[ $WARN -gt 0 ]] && echo -e "  ${YELLOW}Warnings: ${WARN}${NC}"
[[ $FAIL -gt 0 ]] && echo -e "  ${RED}Failed : ${FAIL}${NC}"
echo ""

if (( FAIL > 0 )); then
  echo -e "${RED}${BOLD}❌ ${FAIL} check(s) failed — review output above${NC}"
  echo ""
  echo "Troubleshooting tips:"
  echo "  • View nginx logs : docker logs svtms-nginx --tail=50"
  echo "  • View all logs   : docker compose -f ${COMPOSE_FILE} logs --tail=50"
  echo "  • Check containers: docker compose -f ${COMPOSE_FILE} ps"
  echo "  • Restart service : docker compose -f ${COMPOSE_FILE} restart <service>"
  exit 1
else
  echo -e "${GREEN}${BOLD}✅ All checks passed — SV-TMS is up and reachable!${NC}"
  echo ""
  echo "  🌐 Admin Web UI  : ${BASE_URL}/"
  echo "  🔌 API Gateway   : ${BASE_URL}/api/"
  echo "  📊 Health check  : ${BASE_URL}/actuator/health"
  echo "  📈 Grafana       : ssh -L 3000:localhost:3000 svtms-deploy@207.180.245.156 -N"
  echo ""
  echo "  Mobile apps should connect to: ${BASE_URL}/api"
  echo "  WebSocket URL                : wss://${DOMAIN}/ws"
fi
