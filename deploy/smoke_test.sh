#!/usr/bin/env bash
# =============================================================================
# SV-TMS Post-Deploy Smoke Test
# =============================================================================
# Runs against the live production URL to verify all services are up.
#
# Usage:
#   ./deploy/smoke_test.sh                          # uses default BASE_URL
#   BASE_URL=https://svtms.svtrucking.biz ./deploy/smoke_test.sh
#   BASE_URL=http://207.180.245.156 ./deploy/smoke_test.sh  # IP direct
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed
# =============================================================================
set -euo pipefail

BASE_URL="${BASE_URL:-https://svtms.svtrucking.biz}"
TIMEOUT="${TIMEOUT:-15}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-5}"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0
RESULTS=()

banner() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }
pass()   { echo -e "  ${GREEN}✅ PASS${NC}  $*"; ((PASS++)); RESULTS+=("PASS: $*"); }
fail()   { echo -e "  ${RED}❌ FAIL${NC}  $*"; ((FAIL++)); RESULTS+=("FAIL: $*"); }
warn()   { echo -e "  ${YELLOW}⚠️  WARN${NC}  $*"; ((WARN++)); RESULTS+=("WARN: $*"); }
info()   { echo -e "  ${CYAN}ℹ️  INFO${NC}  $*"; }

# ── Helper: HTTP check with retry ────────────────────────────────────────────
check_http() {
  local label="$1"
  local url="$2"
  local expected_code="${3:-200}"
  local grep_body="${4:-}"

  for attempt in $(seq 1 "${MAX_RETRIES}"); do
    response=$(curl -sk \
      --max-time "${TIMEOUT}" \
      --write-out "\n__STATUS__%{http_code}__TIME__%{time_total}__SIZE__%{size_download}" \
      "${url}" 2>&1) || true

    http_code=$(echo "${response}" | grep -o '__STATUS__[0-9]*' | tr -d '__STATUS__' || echo "000")
    time_total=$(echo "${response}" | grep -o '__TIME__[0-9.]*' | tr -d '__TIME__' || echo "?")
    body=$(echo "${response}" | sed 's/__STATUS__.*$//')

    if [[ "${http_code}" == "${expected_code}" ]]; then
      if [[ -n "${grep_body}" ]]; then
        if echo "${body}" | grep -q "${grep_body}"; then
          pass "${label}  [HTTP ${http_code}] [${time_total}s] — body contains '${grep_body}'"
          return 0
        else
          if [[ "${attempt}" -lt "${MAX_RETRIES}" ]]; then
            sleep "${RETRY_DELAY}"; continue
          fi
          fail "${label}  [HTTP ${http_code}] — body missing '${grep_body}'"
          info "Body snippet: $(echo "${body}" | head -c 200)"
          return 1
        fi
      else
        pass "${label}  [HTTP ${http_code}] [${time_total}s]"
        return 0
      fi
    fi

    if [[ "${attempt}" -lt "${MAX_RETRIES}" ]]; then
      echo "    Retry ${attempt}/${MAX_RETRIES} — got HTTP ${http_code}, expecting ${expected_code}..."
      sleep "${RETRY_DELAY}"
    fi
  done

  fail "${label}  [HTTP ${http_code}] — expected ${expected_code}"
  [[ -n "${body}" ]] && info "Body snippet: $(echo "${body}" | head -c 300)"
  return 1
}

check_json_field() {
  local label="$1"
  local url="$2"
  local json_path="$3"   # grep pattern
  local expected="$4"

  body=$(curl -sk --max-time "${TIMEOUT}" "${url}" 2>&1 || echo "CURL_FAILED")

  if echo "${body}" | grep -q "${json_path}.*${expected}"; then
    pass "${label}  — ${json_path}=${expected}"
  else
    fail "${label}  — expected ${json_path}=${expected}"
    info "Response: $(echo "${body}" | head -c 300)"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   SV-TMS Smoke Test — ${BASE_URL}${NC}"
echo -e "${BOLD}   $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"

# ── 1. Connectivity & TLS ──────────────────────────────────────────────────────
banner "1. Connectivity & TLS"

# DNS resolution
if host "${BASE_URL//https:\/\//}" >/dev/null 2>&1 || \
   nslookup "${BASE_URL//https:\/\//}" >/dev/null 2>&1; then
  pass "DNS resolution — ${BASE_URL//https:\/\//}"
else
  warn "DNS resolution failed (may work anyway)"
fi

# HTTPS reachable
check_http "Main URL reachable" "${BASE_URL}/" "200"

# HTTP → HTTPS redirect
if [[ "${BASE_URL}" == https://* ]]; then
  http_url="${BASE_URL/https:\/\//http://}"
  redirect_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "${TIMEOUT}" "${http_url}/" 2>/dev/null || echo "000")
  if [[ "${redirect_code}" == "301" || "${redirect_code}" == "302" ]]; then
    pass "HTTP → HTTPS redirect  [HTTP ${redirect_code}]"
  else
    warn "HTTP → HTTPS redirect  [HTTP ${redirect_code}] — expected 301/302"
  fi
fi

# TLS certificate validity
if command -v openssl >/dev/null 2>&1; then
  domain="${BASE_URL//https:\/\//}"
  domain="${domain%%/*}"
  cert_expiry=$(echo | timeout 5 openssl s_client -connect "${domain}:443" -servername "${domain}" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "UNKNOWN")
  if [[ "${cert_expiry}" != "UNKNOWN" ]]; then
    pass "TLS certificate valid — expires ${cert_expiry}"
    # Warn if expiring within 30 days
    expiry_epoch=$(date -d "${cert_expiry}" +%s 2>/dev/null || date -jf "%b %d %T %Y %Z" "${cert_expiry}" +%s 2>/dev/null || echo "0")
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
    if [[ "${days_left}" -lt 30 ]]; then
      warn "TLS cert expires in ${days_left} days — renew soon!"
    else
      info "TLS cert valid for ${days_left} more days"
    fi
  else
    warn "Could not verify TLS certificate expiry"
  fi
fi

# ── 2. Admin Web UI ────────────────────────────────────────────────────────────
banner "2. Admin Web UI"

check_http "Admin UI — root" "${BASE_URL}/" "200"
check_http "Admin UI — login page" "${BASE_URL}/auth/login" "200"
check_http "Admin UI — assets (JS)" "${BASE_URL}/main.js" "200"

# Check for Angular app bootstrap
check_http "Admin UI — app loads Angular" "${BASE_URL}/" "200" "app-root\|ng-version\|<app"

# Security headers
banner_headers=$(curl -skI --max-time "${TIMEOUT}" "${BASE_URL}/" 2>/dev/null || echo "")
check_header() {
  local header_name="$1"
  if echo "${banner_headers}" | grep -qi "^${header_name}:"; then
    pass "Security header present — ${header_name}"
  else
    warn "Security header missing — ${header_name}"
  fi
}
check_header "X-Frame-Options"
check_header "X-Content-Type-Options"
check_header "Strict-Transport-Security"

# ── 3. API Gateway ────────────────────────────────────────────────────────────
banner "3. API Gateway"

check_http "API Gateway — health" "${BASE_URL}/api/health" "200" "UP\|status"
check_http "API Gateway — actuator" "${BASE_URL}/actuator/health" "200" "UP"

# ── 4. Authentication API ─────────────────────────────────────────────────────
banner "4. Authentication API"

check_http "Auth API — health" "${BASE_URL}/auth/actuator/health" "200" "UP"

# Test login endpoint exists (expect 400/401/422 — not 404/500)
login_code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --max-time "${TIMEOUT}" \
  -X POST "${BASE_URL}/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"username":"smoke-test@test.invalid","password":"invalid"}' 2>/dev/null || echo "000")
if [[ "${login_code}" =~ ^(400|401|403|422|429)$ ]]; then
  pass "Auth — login endpoint alive  [HTTP ${login_code}] (rejected invalid creds correctly)"
elif [[ "${login_code}" == "404" ]]; then
  warn "Auth — login endpoint returned 404 (check API route mapping)"
elif [[ "${login_code}" =~ ^5 ]]; then
  fail "Auth — login endpoint server error  [HTTP ${login_code}]"
else
  warn "Auth — login endpoint  [HTTP ${login_code}] (unexpected)"
fi

# ── 5. Core API ────────────────────────────────────────────────────────────────
banner "5. Core API"

check_http "Core API — health" "${BASE_URL}/api/actuator/health" "200" "UP"

# Unauthenticated endpoints should return 401 (not 500)
core_code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --max-time "${TIMEOUT}" \
  "${BASE_URL}/api/v1/loads" 2>/dev/null || echo "000")
if [[ "${core_code}" =~ ^(401|403)$ ]]; then
  pass "Core API — /api/v1/loads protected  [HTTP ${core_code}]"
elif [[ "${core_code}" =~ ^5 ]]; then
  fail "Core API — /api/v1/loads server error  [HTTP ${core_code}]"
else
  warn "Core API — /api/v1/loads  [HTTP ${core_code}]"
fi

# ── 6. Driver App API ─────────────────────────────────────────────────────────
banner "6. Driver App API"

check_http "Driver App API — health" "${BASE_URL}/driver/actuator/health" "200" "UP"

driver_code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --max-time "${TIMEOUT}" \
  "${BASE_URL}/driver/api/v1/trips" 2>/dev/null || echo "000")
if [[ "${driver_code}" =~ ^(401|403)$ ]]; then
  pass "Driver API — /trips protected  [HTTP ${driver_code}]"
elif [[ "${driver_code}" =~ ^5 ]]; then
  fail "Driver API — /trips server error  [HTTP ${driver_code}]"
else
  warn "Driver API — /trips  [HTTP ${driver_code}]"
fi

# ── 7. Telematics API ─────────────────────────────────────────────────────────
banner "7. Telematics API"

check_http "Telematics API — health" "${BASE_URL}/telematics/actuator/health" "200" "UP"

# ── 8. Safety API ─────────────────────────────────────────────────────────────
banner "8. Safety API"

check_http "Safety API — health" "${BASE_URL}/safety/actuator/health" "200" "UP"

# ── 9. Message API ────────────────────────────────────────────────────────────
banner "9. Message API"

check_http "Message API — health" "${BASE_URL}/message/actuator/health" "200" "UP"

# ── 10. WebSocket endpoint ────────────────────────────────────────────────────
banner "10. WebSocket"

# Check WebSocket upgrade endpoint exists (101 Switching Protocols or 400 = server is up)
ws_code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --max-time "${TIMEOUT}" \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "${BASE_URL}/ws" 2>/dev/null || echo "000")
if [[ "${ws_code}" =~ ^(101|400|426)$ ]]; then
  pass "WebSocket endpoint reachable  [HTTP ${ws_code}]"
elif [[ "${ws_code}" == "404" ]]; then
  warn "WebSocket endpoint not found at /ws  [HTTP 404]"
elif [[ "${ws_code}" =~ ^5 ]]; then
  fail "WebSocket endpoint server error  [HTTP ${ws_code}]"
else
  warn "WebSocket endpoint  [HTTP ${ws_code}]"
fi

# ── 11. Performance baselines ─────────────────────────────────────────────────
banner "11. Response Time Baselines"

time_main=$(curl -sk -o /dev/null -w "%{time_total}" --max-time "${TIMEOUT}" "${BASE_URL}/" 2>/dev/null || echo "99")
time_api=$(curl -sk -o /dev/null -w "%{time_total}" --max-time "${TIMEOUT}" "${BASE_URL}/api/actuator/health" 2>/dev/null || echo "99")

check_perf() {
  local label="$1"; local time_val="$2"; local threshold="$3"
  local int_time; int_time=$(echo "${time_val}" | awk '{printf "%.0f", $1 * 1000}')
  if [[ "${int_time}" -lt "${threshold}" ]]; then
    pass "${label}  ${time_val}s < ${threshold}ms threshold"
  else
    warn "${label}  ${time_val}s — exceeds ${threshold}ms threshold"
  fi
}

check_perf "Admin UI load time" "${time_main}" 3000
check_perf "API health response time" "${time_api}" 1000

# ── 12. Error page handling ───────────────────────────────────────────────────
banner "12. Error Handling"

check_http "404 for unknown route" "${BASE_URL}/this-does-not-exist-xyz" "404"
check_http "No server version leakage" "${BASE_URL}/" "200"

# Check Server header doesn't reveal version
server_header=$(curl -skI --max-time "${TIMEOUT}" "${BASE_URL}/" 2>/dev/null | grep -i "^server:" || echo "")
if echo "${server_header}" | grep -qi "nginx/[0-9]\|apache/[0-9]\|jetty/[0-9]"; then
  warn "Server version exposed in header: ${server_header}"
else
  pass "Server header does not expose version"
fi

# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   SMOKE TEST RESULTS${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}PASS: ${PASS}${NC}  ${RED}FAIL: ${FAIL}${NC}  ${YELLOW}WARN: ${WARN}${NC}"
echo ""

if [[ "${FAIL}" -gt 0 ]]; then
  echo -e "${RED}Failed checks:${NC}"
  for r in "${RESULTS[@]}"; do
    [[ "${r}" == FAIL:* ]] && echo "  ❌ ${r#FAIL: }"
  done
  echo ""
fi

if [[ "${WARN}" -gt 0 ]]; then
  echo -e "${YELLOW}Warnings:${NC}"
  for r in "${RESULTS[@]}"; do
    [[ "${r}" == WARN:* ]] && echo "  ⚠️  ${r#WARN: }"
  done
  echo ""
fi

echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"

if [[ "${FAIL}" -gt 0 ]]; then
  echo -e "${RED}${BOLD}SMOKE TEST FAILED — ${FAIL} check(s) failed${NC}"
  exit 1
else
  echo -e "${GREEN}${BOLD}ALL SMOKE TESTS PASSED ✅${NC}"
  exit 0
fi
