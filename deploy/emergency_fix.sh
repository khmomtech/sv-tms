#!/usr/bin/env bash
# =============================================================================
# SV-TMS Emergency Fix — Run this on the VPS to get the site up immediately
# =============================================================================
# Usage (paste this whole file into your VPS terminal as root):
#   ssh root@207.180.245.156
#   bash /opt/sv-tms/deploy/emergency_fix.sh
#
# OR run it remotely:
#   ssh root@207.180.245.156 "bash /opt/sv-tms/deploy/emergency_fix.sh"
# =============================================================================
set -uo pipefail

DEPLOY_DIR="/opt/sv-tms"
DATA_ROOT="/srv/svtms"
DOMAIN="svtms.svtrucking.biz"
EMAIL="ops@svtrucking.biz"
ENV_FILE="${DEPLOY_DIR}/infra/.env"
COMPOSE_FILE="${DEPLOY_DIR}/infra/docker-compose.prod.yml"
COMPOSE_CMD="docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅  $*${NC}"; }
fail() { echo -e "  ${RED}❌  $*${NC}"; }
info() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   SV-TMS Emergency Fix — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════${NC}"
echo ""

# ── Read DOMAIN/DATA_ROOT from .env if available ──────────────────────────────
if [[ -f "${ENV_FILE}" ]]; then
  _d=$(grep -E '^DOMAIN=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
  [[ -n "${_d}" ]] && DOMAIN="${_d}"
  _dr=$(grep -E '^DATA_ROOT=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
  [[ -n "${_dr}" ]] && DATA_ROOT="${_dr}"
  _em=$(grep -E '^EMAIL=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
  [[ -n "${_em}" ]] && EMAIL="${_em}"
fi

CERT_DIR="${DATA_ROOT}/certs/live/${DOMAIN}"
CERT_FILE="${CERT_DIR}/fullchain.pem"
KEY_FILE="${CERT_DIR}/privkey.pem"

# =============================================================================
info "Step 1/7 — Checking prerequisites..."
# =============================================================================

# Check Docker
if ! command -v docker &>/dev/null; then
  fail "Docker not installed"
  echo "  Installing Docker..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
  ok "Docker installed"
else
  ok "Docker: $(docker --version | head -1)"
fi

# Check .env
if [[ ! -f "${ENV_FILE}" ]]; then
  fail ".env not found at ${ENV_FILE}"
  echo ""
  echo "  You must create the .env file first:"
  echo "  cp ${DEPLOY_DIR}/infra/.env.example ${ENV_FILE}"
  echo "  nano ${ENV_FILE}   # fill in all values"
  exit 1
fi
ok ".env exists"

# Check compose file
if [[ ! -f "${COMPOSE_FILE}" ]]; then
  fail "docker-compose.prod.yml not found"
  echo "  Run: cd ${DEPLOY_DIR} && git pull origin main"
  exit 1
fi
ok "docker-compose.prod.yml exists"

# =============================================================================
info "Step 2/7 — Creating data directories..."
# =============================================================================
for dir in mysql postgres redis mongo \
           kafka-1 kafka-2 kafka-3 \
           uploads uploads-init \
           telematics-spool message-api \
           "certs/live/${DOMAIN}" "certs/archive/${DOMAIN}" \
           "webroot/.well-known/acme-challenge" \
           monitoring/prometheus monitoring/grafana monitoring/alertmanager \
           releases backups; do
  mkdir -p "${DATA_ROOT}/${dir}"
done
mkdir -p "${DEPLOY_DIR}/secrets"
ok "Directories ready under ${DATA_ROOT}"

# =============================================================================
info "Step 3/7 — SSL certificate setup..."
# =============================================================================

is_real_cert=false
if [[ -f "${CERT_FILE}" ]]; then
  expiry_str=$(openssl x509 -in "${CERT_FILE}" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")
  if [[ -n "${expiry_str}" ]]; then
    expiry_ts=$(date -d "${expiry_str}" +%s 2>/dev/null || echo 0)
    days_left=$(( (expiry_ts - $(date +%s)) / 86400 ))
    if [[ "${days_left}" -gt 1 ]]; then
      is_real_cert=true
      ok "Valid SSL cert in place (expires in ${days_left} days)"
    else
      warn "Dummy/expired cert found (${days_left} days left) — will replace with real cert"
    fi
  fi
else
  warn "No SSL cert found — generating dummy cert so nginx can start"
fi

if ! "${is_real_cert}"; then
  # Generate dummy cert (nginx needs these files to exist at startup)
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -days 1 \
    -subj "/CN=${DOMAIN}/O=SV-TMS-Bootstrap/OU=Dummy" \
    2>/dev/null
  chmod 600 "${KEY_FILE}"
  cp "${CERT_FILE}" "${DATA_ROOT}/certs/archive/${DOMAIN}/fullchain1.pem" 2>/dev/null || true
  cp "${KEY_FILE}"  "${DATA_ROOT}/certs/archive/${DOMAIN}/privkey1.pem"   2>/dev/null || true
  ok "Dummy cert generated at ${CERT_FILE}"
fi

# =============================================================================
info "Step 4/7 — Pulling latest Docker images..."
# =============================================================================

# Login to GHCR if credentials available
GHCR_TOKEN=$(grep -E '^GHCR_TOKEN=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "")
GITHUB_ACTOR=$(grep -E '^GITHUB_ACTOR=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "github")
IMAGE_REGISTRY=$(grep -E '^IMAGE_REGISTRY=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "")
IMAGE_TAG=$(grep -E '^IMAGE_TAG=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "latest")

if [[ -n "${GHCR_TOKEN}" && -n "${IMAGE_REGISTRY}" ]]; then
  echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR:-github}" --password-stdin 2>/dev/null \
    && ok "Logged into GHCR" \
    || warn "GHCR login failed — will try with existing cached images"

  echo "  Pulling images (tag: ${IMAGE_TAG})..."
  IMAGE_REGISTRY="${IMAGE_REGISTRY}" IMAGE_TAG="${IMAGE_TAG}" \
    ${COMPOSE_CMD} pull \
    2>&1 | grep -E "Pulling|pulled|exists|Error|error" || true
  ok "Images pulled"
else
  warn "GHCR_TOKEN or IMAGE_REGISTRY not in .env — using locally cached images"
fi

# =============================================================================
info "Step 5/7 — Starting the full stack..."
# =============================================================================

cd "${DEPLOY_DIR}/infra"

# When using local images (built via build_images_on_vps.sh), skip pull to avoid
# "pull access denied for local/svtms-*" errors — use --pull never.
# For GHCR, allow default pull behaviour.
if [[ "${IMAGE_REGISTRY}" == "local" ]]; then
  warn "IMAGE_REGISTRY=local — using locally-built images (skipping pull)"
  IMAGE_REGISTRY="${IMAGE_REGISTRY}" IMAGE_TAG="${IMAGE_TAG}" \
    ${COMPOSE_CMD} up -d --remove-orphans --pull never
else
  IMAGE_REGISTRY="${IMAGE_REGISTRY}" IMAGE_TAG="${IMAGE_TAG}" \
    ${COMPOSE_CMD} up -d --remove-orphans
fi

ok "Stack started — waiting for services to initialise..."

# Wait for nginx specifically (most critical)
echo "  Waiting for nginx..."
for i in $(seq 1 30); do
  if docker inspect --format='{{.State.Status}}' svtms-nginx 2>/dev/null | grep -q "running"; then
    if docker inspect --format='{{.State.Health.Status}}' svtms-nginx 2>/dev/null | grep -qE "healthy|no-healthcheck" 2>/dev/null || true; then
      # Check if port 80 responds
      code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:80/" 2>/dev/null || echo "000")
      if [[ "${code}" != "000" ]]; then
        ok "nginx is up and responding (HTTP ${code})"
        break
      fi
    fi
  fi
  echo "    Waiting... ${i}/30"
  sleep 5
done

# Show container status
echo ""
${COMPOSE_CMD} ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | head -30 || \
  docker ps --format "table {{.Names}}\t{{.Status}}" | grep svtms

# =============================================================================
info "Step 6/7 — Obtaining real SSL certificate..."
# =============================================================================

if "${is_real_cert}"; then
  ok "Already have valid cert — skipping certbot"
else
  # Check DNS resolves to this server before trying certbot
  VPS_IP=$(hostname -I | awk '{print $1}')
  DNS_IP=$(dig +short "${DOMAIN}" A 2>/dev/null | tail -1 || \
           nslookup "${DOMAIN}" 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}' || \
           echo "")

  if [[ -z "${DNS_IP}" ]]; then
    warn "Cannot resolve DNS for ${DOMAIN} — trying certbot anyway (may fail)"
  elif [[ "${DNS_IP}" != "${VPS_IP}" ]]; then
    warn "DNS MISMATCH: ${DOMAIN} → ${DNS_IP} but this server is ${VPS_IP}"
    warn "Certbot will FAIL until DNS is updated to point to ${VPS_IP}"
    warn "Skipping certbot — site runs with dummy cert for now"
    warn "Once DNS is fixed, run: docker exec svtms-certbot certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} -m ${EMAIL} --agree-tos --non-interactive"
  else
    ok "DNS OK: ${DOMAIN} → ${DNS_IP} (this server ✅)"
    echo "  Waiting 10s for nginx to be fully ready for ACME challenge..."
    sleep 10

    docker exec svtms-certbot certbot certonly \
      --webroot \
      -w /var/www/certbot \
      -d "${DOMAIN}" \
      -m "${EMAIL}" \
      --agree-tos \
      --no-eff-email \
      --non-interactive \
      --force-renewal \
      2>&1 && {
        ok "Real Let's Encrypt cert obtained for ${DOMAIN}!"
        docker exec svtms-nginx nginx -s reload 2>/dev/null \
          && ok "nginx reloaded with real SSL cert" \
          || warn "nginx reload failed — try: docker exec svtms-nginx nginx -s reload"
      } || {
        warn "Certbot failed. Site runs with dummy cert."
        warn "To retry: docker exec svtms-certbot certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} -m ${EMAIL} --agree-tos --non-interactive"
      }
  fi
fi

# =============================================================================
info "Step 7/7 — Verification..."
# =============================================================================

echo ""
PASS=0; FAIL=0

check() {
  local name="$1"; local url="$2"; local expected="$3"
  code=$(curl -sk --max-time 8 -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
  if [[ "${code}" =~ ${expected} ]]; then
    echo -e "  ${GREEN}✅  ${name}: HTTP ${code}${NC}"; ((PASS++))
  else
    echo -e "  ${RED}❌  ${name}: HTTP ${code} (expected ${expected})${NC}"; ((FAIL++))
  fi
}

# Internal checks (from VPS)
check "nginx HTTP"           "http://127.0.0.1:80/"                          "^(200|301|302)"
check "nginx HTTPS"          "https://127.0.0.1:443/"         "^(200|301|302)"
check "core-api health"      "http://127.0.0.1:8080/actuator/health"         "^200"
check "auth-api health"      "http://127.0.0.1:8083/actuator/health"         "^200"
check "api-gateway health"   "http://127.0.0.1:8086/actuator/health"         "^200"
check "driver-app-api"       "http://127.0.0.1:8084/actuator/health"         "^200"
check "telematics-api"       "http://127.0.0.1:8082/actuator/health"         "^200"
check "safety-api"           "http://127.0.0.1:8087/actuator/health"         "^200"
check "message-api"          "http://127.0.0.1:8088/actuator/health"         "^200"

# External check (via domain)
echo ""
echo "  External checks:"
check "https://svtms.svtrucking.biz"  "https://${DOMAIN}/"               "^(200|301|302)"
check "https API gateway"             "https://${DOMAIN}/api/actuator/health"   "^(200|401|403)"

# SSL cert check
echo ""
if [[ -f "${CERT_FILE}" ]]; then
  expiry=$(openssl x509 -in "${CERT_FILE}" -noout -enddate 2>/dev/null | cut -d= -f2)
  expiry_ts=$(date -d "${expiry}" +%s 2>/dev/null || echo 0)
  days=$(( (expiry_ts - $(date +%s)) / 86400 ))
  issuer=$(openssl x509 -in "${CERT_FILE}" -noout -issuer 2>/dev/null | sed 's/issuer=//')
  if [[ "${days}" -gt 1 ]]; then
    echo -e "  ${GREEN}✅  SSL cert: valid for ${days} days (${issuer})${NC}"; ((PASS++))
  else
    echo -e "  ${YELLOW}⚠️   SSL cert: DUMMY cert in place (certbot needed)${NC}"; ((FAIL++))
  fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BOLD}${CYAN}════════════════════ RESULT ════════════════════${NC}"
if [[ "${FAIL}" -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}"
  echo "   🎉  ALL CHECKS PASSED — Site is LIVE!"
  echo ""
  echo "   🌐  https://${DOMAIN}"
  echo "   📱  Mobile apps: https://${DOMAIN}/api"
  echo "   📊  Grafana:     http://$(hostname -I | awk '{print $1}'):3000"
  echo -e "${NC}"
else
  echo -e "${YELLOW}${BOLD}   ${PASS} passed / ${FAIL} failed${NC}"
  echo ""
  if [[ "${FAIL}" -gt 0 ]]; then
    echo "  Some services may still be starting up (Spring Boot takes 2-3 min)."
    echo "  Wait 3 minutes and re-check:"
    echo ""
    echo "    bash ${DEPLOY_DIR}/deploy/diagnose.sh"
    echo ""
    echo "  Or watch logs:"
    echo "    docker compose -f ${COMPOSE_FILE} --env-file ${ENV_FILE} logs -f --tail=50"
  fi
fi
echo ""

# Set up cron for auto cert renewal
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
  (crontab -l 2>/dev/null; echo "0 3 * * * docker exec svtms-certbot certbot renew --quiet && docker exec svtms-nginx nginx -s reload 2>/dev/null") | crontab -
  ok "Auto SSL renewal cron installed (daily at 3am)"
fi
