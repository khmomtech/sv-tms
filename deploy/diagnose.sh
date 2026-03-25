#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Quick VPS Diagnosis Script
# =============================================================================
# Run this ON the VPS to instantly see what's wrong and get fix commands.
#
# Usage (run ON the VPS):
#   ssh root@207.180.245.156
#   cd /opt/sv-tms
#   bash deploy/diagnose.sh
# =============================================================================
set -uo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/sv-tms}"
ENV_FILE="${DEPLOY_DIR}/infra/.env"
COMPOSE_FILE="${DEPLOY_DIR}/infra/docker-compose.prod.yml"
DATA_ROOT="/srv/svtms"
DOMAIN="svtms.svtrucking.biz"

# Load DATA_ROOT and DOMAIN from .env if it exists
if [[ -f "${ENV_FILE}" ]]; then
  _domain=$(grep -E '^DOMAIN=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
  [[ -n "${_domain}" ]] && DOMAIN="${_domain}"
  _data_root=$(grep -E '^DATA_ROOT=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
  [[ -n "${_data_root}" ]] && DATA_ROOT="${_data_root}"
fi

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

FIXES=()
WARNINGS=()
PASS=0; FAIL=0; WARN=0

ok()   { echo -e "  ${GREEN}✅  $*${NC}"; ((PASS++)) || true; }
fail() { echo -e "  ${RED}❌  $*${NC}"; ((FAIL++)) || true; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; ((WARN++)) || true; }
info() { echo -e "  ${CYAN}ℹ️   $*${NC}"; }
fix()  { FIXES+=("$*"); }
section() { echo -e "\n${BOLD}${CYAN}━━ $* ━━${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}SV-TMS VPS Diagnosis${NC}"
echo "  Server : $(hostname -f 2>/dev/null || hostname)"
echo "  IP     : $(hostname -I | awk '{print $1}')"
echo "  Domain : ${DOMAIN}"
echo "  Date   : $(date)"
echo ""

# =============================================================================
section "1. Environment & Config"
# =============================================================================

if [[ -f "${ENV_FILE}" ]]; then
  ok ".env file exists at ${ENV_FILE}"
  # Check for CHANGE_ME placeholders
  bad_vars=$(grep -E '^[A-Z_]+=.*CHANGE_ME' "${ENV_FILE}" 2>/dev/null | cut -d= -f1 || true)
  if [[ -n "${bad_vars}" ]]; then
    fail "These .env variables still have CHANGE_ME placeholders:"
    echo "${bad_vars}" | while read -r v; do echo "     • ${v}"; done
    fix "Edit ${ENV_FILE} and set real values for the above variables"
  else
    ok "No CHANGE_ME placeholders in .env"
  fi
else
  fail ".env not found at ${ENV_FILE}"
  fix "Copy ${DEPLOY_DIR}/infra/.env.example to ${ENV_FILE} and fill in all values"
fi

if [[ -f "${COMPOSE_FILE}" ]]; then
  ok "docker-compose.prod.yml exists"
else
  fail "docker-compose.prod.yml not found at ${COMPOSE_FILE}"
  fix "Run: cd ${DEPLOY_DIR} && git pull origin main"
fi

# =============================================================================
section "2. Docker"
# =============================================================================

if command -v docker &>/dev/null; then
  ok "Docker installed: $(docker --version 2>/dev/null | head -1)"
  if docker info &>/dev/null 2>&1; then
    ok "Docker daemon is running"
  else
    fail "Docker daemon is NOT running"
    fix "Run: systemctl start docker && systemctl enable docker"
  fi
else
  fail "Docker is not installed"
  fix "Run: bash ${DEPLOY_DIR}/deploy/vps_deploy_now.sh (it will install Docker)"
fi

# =============================================================================
section "3. Container Status"
# =============================================================================

CRITICAL_CONTAINERS=(
  "svtms-nginx"
  "svtms-core-api"
  "svtms-auth-api"
  "svtms-api-gateway"
  "svtms-mysql"
  "svtms-admin-web-ui"
)
OTHER_CONTAINERS=(
  "svtms-driver-app-api"
  "svtms-telematics-api"
  "svtms-safety-api"
  "svtms-message-api"
  "svtms-postgres"
  "svtms-mongo"
  "svtms-redis"
  "svtms-kafka-1"
  "svtms-kafka-2"
  "svtms-kafka-3"
  "svtms-certbot"
)

for container in "${CRITICAL_CONTAINERS[@]}"; do
  status=$(docker inspect --format='{{.State.Status}}' "${container}" 2>/dev/null || echo "missing")
  health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "${container}" 2>/dev/null || echo "missing")
  if [[ "${status}" == "running" ]]; then
    if [[ "${health}" == "healthy" || "${health}" == "no-healthcheck" || "${health}" == "starting" ]]; then
      ok "${container}: running"
    else
      warn "${container}: running but unhealthy (${health})"
    fi
  elif [[ "${status}" == "missing" ]]; then
    fail "${container}: NOT FOUND (stack not started?)"
    if [[ "${container}" == "svtms-nginx" ]]; then
      fix "nginx is not running — this is why the site is down!"
      fix "Check nginx logs: docker logs svtms-nginx --tail=50"
    fi
  else
    fail "${container}: ${status}"
    fix "Check logs: docker logs ${container} --tail=50"
  fi
done

echo ""
info "Secondary containers:"
for container in "${OTHER_CONTAINERS[@]}"; do
  status=$(docker inspect --format='{{.State.Status}}' "${container}" 2>/dev/null || echo "missing")
  if [[ "${status}" == "running" ]]; then
    echo -e "    ${GREEN}✅${NC}  ${container}"
  elif [[ "${status}" == "missing" ]]; then
    echo -e "    ${YELLOW}⚠️${NC}   ${container}: not started"
  else
    echo -e "    ${RED}❌${NC}  ${container}: ${status}"
  fi
done

# =============================================================================
section "4. nginx Specific Diagnosis"
# =============================================================================

nginx_status=$(docker inspect --format='{{.State.Status}}' "svtms-nginx" 2>/dev/null || echo "missing")

if [[ "${nginx_status}" != "running" ]]; then
  fail "nginx container is not running — diagnosing..."

  # Check the last nginx startup error
  echo ""
  info "Last 20 lines of nginx container logs:"
  docker logs svtms-nginx --tail=20 2>&1 | sed 's/^/     /' || echo "     (no logs available)"
  echo ""

  # Check for the most common cause: missing SSL cert
  CERT_FILE="${DATA_ROOT}/certs/live/${DOMAIN}/fullchain.pem"
  KEY_FILE="${DATA_ROOT}/certs/live/${DOMAIN}/privkey.pem"

  if [[ ! -f "${CERT_FILE}" ]]; then
    fail "ROOT CAUSE: SSL cert missing at ${CERT_FILE}"
    fix "Generate dummy cert so nginx can start:"
    fix "  mkdir -p ${DATA_ROOT}/certs/live/${DOMAIN}"
    fix "  openssl req -x509 -nodes -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -days 1 -subj '/CN=${DOMAIN}/O=Bootstrap'"
    fix "  docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} up -d nginx"
    fix "  # Then get real cert:"
    fix "  docker exec svtms-certbot certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} -m ops@svtrucking.biz --agree-tos --non-interactive"
    fix "  docker exec svtms-nginx nginx -s reload"
  elif [[ ! -f "${KEY_FILE}" ]]; then
    fail "ROOT CAUSE: SSL private key missing at ${KEY_FILE}"
    fix "Re-run: bash ${DEPLOY_DIR}/deploy/vps_deploy_now.sh"
  else
    warn "SSL cert files exist but nginx still failed — check config:"
    # Validate nginx config
    docker run --rm \
      -v "${DEPLOY_DIR}/infra/nginx/site.conf:/etc/nginx/conf.d/default.conf:ro" \
      nginx:stable-alpine nginx -t 2>&1 | sed 's/^/     /' || true
    fix "Fix any nginx config errors shown above, then: docker compose -f ${COMPOSE_FILE} up -d nginx"
  fi
else
  ok "nginx is running"

  # Check nginx config validity inside the running container
  if docker exec svtms-nginx nginx -t 2>/dev/null; then
    ok "nginx config is valid"
  else
    warn "nginx config has errors:"
    docker exec svtms-nginx nginx -t 2>&1 | sed 's/^/     /'
    fix "Fix nginx config, then: docker exec svtms-nginx nginx -s reload"
  fi
fi

# =============================================================================
section "5. SSL Certificate"
# =============================================================================

CERT_FILE="${DATA_ROOT}/certs/live/${DOMAIN}/fullchain.pem"

if [[ -f "${CERT_FILE}" ]]; then
  issuer=$(openssl x509 -in "${CERT_FILE}" -noout -issuer 2>/dev/null | sed 's/issuer=//')
  expiry=$(openssl x509 -in "${CERT_FILE}" -noout -enddate 2>/dev/null | cut -d= -f2)
  expiry_ts=$(date -d "${expiry}" +%s 2>/dev/null || echo 0)
  days_left=$(( (expiry_ts - $(date +%s)) / 86400 ))

  if [[ "${days_left}" -le 1 ]]; then
    warn "DUMMY/EXPIRED cert in place (expires in ${days_left} days)"
    warn "Issuer: ${issuer}"
    info "Site is reachable but browser shows certificate warning"
    fix "Get real cert: docker exec svtms-certbot certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} -m ops@svtrucking.biz --agree-tos --non-interactive"
    fix "Then reload: docker exec svtms-nginx nginx -s reload"
  elif [[ "${days_left}" -lt 14 ]]; then
    warn "Cert expires soon: ${days_left} days (${expiry})"
    fix "Renew: docker exec svtms-certbot certbot renew --quiet && docker exec svtms-nginx nginx -s reload"
  else
    ok "Valid cert — expires in ${days_left} days (${expiry})"
    info "Issuer: ${issuer}"
  fi
else
  fail "SSL cert NOT FOUND at ${CERT_FILE}"
  fix "mkdir -p ${DATA_ROOT}/certs/live/${DOMAIN}"
  fix "openssl req -x509 -nodes -newkey rsa:2048 -keyout ${DATA_ROOT}/certs/live/${DOMAIN}/privkey.pem -out ${CERT_FILE} -days 1 -subj '/CN=${DOMAIN}'"
  fix "docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} restart nginx"
fi

# =============================================================================
section "6. DNS Resolution"
# =============================================================================

VPS_IP=$(hostname -I | awk '{print $1}')
RESOLVED_IP=$(dig +short "${DOMAIN}" A 2>/dev/null | tail -1 || \
              nslookup "${DOMAIN}" 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}' || \
              echo "unknown")

if [[ -z "${RESOLVED_IP}" || "${RESOLVED_IP}" == "unknown" ]]; then
  warn "Could not resolve ${DOMAIN} (dig/nslookup not available on VPS)"
  info "Check manually: dig +short ${DOMAIN} A"
elif [[ "${RESOLVED_IP}" == "${VPS_IP}" ]]; then
  ok "DNS OK: ${DOMAIN} → ${RESOLVED_IP} (this server ✅)"
else
  fail "DNS MISMATCH: ${DOMAIN} resolves to ${RESOLVED_IP}, but this server is ${VPS_IP}"
  fix "Update your DNS A record for ${DOMAIN} to point to ${VPS_IP}"
  fix "DNS changes can take up to 24h to propagate"
fi

# =============================================================================
section "7. Port Availability"
# =============================================================================

for port in 80 443; do
  if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
    ok "Port ${port} is listening"
  elif netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
    ok "Port ${port} is listening"
  else
    fail "Port ${port} is NOT listening"
    if [[ "${port}" == "80" || "${port}" == "443" ]]; then
      fix "nginx is not bound to port ${port} — check: docker logs svtms-nginx --tail=30"
    fi
  fi
done

# Check firewall
if command -v ufw &>/dev/null; then
  ufw_status=$(ufw status 2>/dev/null | head -1)
  if echo "${ufw_status}" | grep -qi "active"; then
    for port in 80 443 22; do
      if ufw status 2>/dev/null | grep -qE "^${port}.*ALLOW"; then
        ok "UFW: port ${port} is allowed"
      else
        warn "UFW: port ${port} may be blocked"
        fix "Run: ufw allow ${port}/tcp"
      fi
    done
  else
    ok "UFW is inactive (all ports open)"
  fi
fi

# =============================================================================
section "8. Internal API Health"
# =============================================================================

declare -A APIS=(
  ["core-api"]="8080"
  ["auth-api"]="8083"
  ["api-gateway"]="8086"
  ["driver-app-api"]="8084"
  ["telematics-api"]="8082"
  ["safety-api"]="8087"
  ["message-api"]="8088"
)

for svc in "${!APIS[@]}"; do
  port="${APIS[$svc]}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 4 "http://127.0.0.1:${port}/actuator/health" 2>/dev/null || echo "000")
  if [[ "${code}" == "200" ]]; then
    ok "${svc} (port ${port}): healthy"
  elif [[ "${code}" == "000" ]]; then
    fail "${svc} (port ${port}): not responding — check: docker logs svtms-${svc} --tail=30"
    fix "docker logs svtms-${svc} --tail=50 | grep -i 'error\|exception\|failed'"
  else
    warn "${svc} (port ${port}): HTTP ${code}"
  fi
done

# =============================================================================
section "9. Site Reachability"
# =============================================================================

# Test HTTP
http_code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "http://${DOMAIN}/" 2>/dev/null || echo "000")
if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
  ok "HTTP reachable: http://${DOMAIN}/ → ${http_code}"
elif [[ "${http_code}" == "000" ]]; then
  fail "HTTP not reachable (connection refused or timeout)"
  fix "Check nginx: docker logs svtms-nginx --tail=30"
else
  warn "HTTP returned unexpected code: ${http_code}"
fi

# Test HTTPS
https_code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" 2>/dev/null || echo "000")
if [[ "${https_code}" =~ ^(200|301|302)$ ]]; then
  ok "HTTPS reachable: https://${DOMAIN}/ → ${https_code}"
elif [[ "${https_code}" == "000" ]]; then
  fail "HTTPS not reachable (connection refused or timeout)"
  if [[ "${nginx_status}" != "running" ]]; then
    fix "nginx is down — fix it first (see section 4 above)"
  else
    fix "nginx is running but HTTPS fails — check cert and port 443:"
    fix "  docker exec svtms-nginx nginx -t"
    fix "  docker logs svtms-nginx --tail=20"
  fi
else
  warn "HTTPS returned unexpected code: ${https_code}"
fi

# =============================================================================
section "10. Disk & Memory"
# =============================================================================

disk_pct=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
if (( disk_pct < 80 )); then
  ok "Disk usage: ${disk_pct}%"
elif (( disk_pct < 90 )); then
  warn "Disk usage: ${disk_pct}% — getting full"
  fix "Clean up: docker system prune -f && docker image prune -a -f"
else
  fail "Disk usage: ${disk_pct}% — CRITICAL"
  fix "URGENT: docker system prune -a -f && journalctl --vacuum-size=200M"
fi

mem_free=$(free -m | awk '/^Mem/{print $7}')
if (( mem_free > 512 )); then
  ok "Free memory: ${mem_free} MB"
elif (( mem_free > 256 )); then
  warn "Free memory: ${mem_free} MB — low"
else
  fail "Free memory: ${mem_free} MB — very low, stack may OOM"
  fix "Investigate: docker stats --no-stream | sort -k4 -hr | head -10"
fi

# =============================================================================
# Summary & Fix Commands
# =============================================================================

echo ""
echo -e "${BOLD}${CYAN}══════════════════ DIAGNOSIS SUMMARY ══════════════════${NC}"
echo -e "  ${GREEN}Passed  : ${PASS}${NC}"
[[ ${WARN} -gt 0 ]] && echo -e "  ${YELLOW}Warnings: ${WARN}${NC}"
[[ ${FAIL} -gt 0 ]] && echo -e "  ${RED}Failed  : ${FAIL}${NC}"
echo ""

if (( FAIL > 0 )) || (( WARN > 0 )); then
  echo -e "${BOLD}${YELLOW}── Recommended Fix Commands ──────────────────────────────${NC}"
  i=1
  for fix_cmd in "${FIXES[@]}"; do
    echo -e "  ${CYAN}${i}.${NC} ${fix_cmd}"
    ((i++))
  done
  echo ""
fi

if (( FAIL == 0 )); then
  echo -e "${GREEN}${BOLD}✅  Stack looks healthy — site should be accessible!${NC}"
  echo ""
  echo "  Test: curl -sk https://${DOMAIN}/actuator/health | python3 -m json.tool"
else
  echo -e "${RED}${BOLD}❌  ${FAIL} issue(s) found — follow the fix commands above${NC}"
  echo ""
  echo "  After fixing, re-run: bash ${DEPLOY_DIR}/deploy/diagnose.sh"
  echo ""
  echo -e "${BOLD}Quick nuclear option (full redeploy):${NC}"
  echo "  cd ${DEPLOY_DIR} && bash deploy/vps_deploy_now.sh"
fi
echo ""
