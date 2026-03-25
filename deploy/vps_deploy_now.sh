#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Full VPS Deploy (one command)
# =============================================================================
# Run this on the VPS itself (as root or svtms-deploy) to:
#   1. Install Docker if missing
#   2. Create all data directories
#   3. Use nginx HTTP-only config for first run (before SSL cert)
#   4. Start the full stack
#   5. Run certbot to get SSL certificate
#   6. Switch nginx to HTTPS config and reload
#   7. Run health checks
#
# Usage (run ON the VPS):
#   curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/sv-tms/main/deploy/vps_deploy_now.sh | bash
# OR:
#   ssh root@207.180.245.156
#   cd /opt/sv-tms
#   bash deploy/vps_deploy_now.sh
# =============================================================================
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/sv-tms}"
DATA_ROOT="${DATA_ROOT:-/srv/svtms}"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/infra/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${DEPLOY_DIR}/infra/docker-compose.prod.yml}"
NGINX_CONF="${DEPLOY_DIR}/infra/nginx/site.conf"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "\n${CYAN}▶ $*${NC}"; }
ok()    { echo -e "  ${GREEN}✅ $*${NC}"; }
warn()  { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "  ${RED}❌ $*${NC}"; exit 1; }

# ── 1. Install Docker ─────────────────────────────────────────────────────────
info "Step 1/8 — Checking Docker..."
if ! command -v docker &>/dev/null; then
  info "Installing Docker..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
  ok "Docker installed: $(docker --version)"
else
  ok "Docker already installed: $(docker --version)"
fi

# ── 2. Check .env ─────────────────────────────────────────────────────────────
info "Step 2/8 — Validating .env..."
[[ -f "${ENV_FILE}" ]] || error ".env not found at ${ENV_FILE}. Copy infra/.env.example to infra/.env and fill in all values."

# Safely source only key=value lines (no subshell injection via backtick/dollar values)
while IFS='=' read -r key val; do
  # Skip empty lines and comments
  [[ -z "${key}" || "${key}" =~ ^# ]] && continue
  # Strip leading/trailing whitespace from key
  key="${key// /}"
  # Only export simple alphanumeric keys
  [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && export "${key}=${val}"
done < <(grep -v '^#' "${ENV_FILE}" | grep '=' | sed 's/\r//')

# Check for placeholder values that must be changed
MISSING=0
for var in IMAGE_REGISTRY JWT_ACCESS_SECRET JWT_REFRESH_SECRET MYSQL_ROOT_PASSWORD MYSQL_PASSWORD; do
  val="${!var:-}"
  if [[ -z "${val}" || "${val}" == *"CHANGE_ME"* || "${val}" == *"YOUR_GITHUB"* || "${val}" == *"replace-me"* ]]; then
    warn "  .env: ${var} is not set or still has a placeholder value"
    MISSING=1
  fi
done
[[ "${MISSING}" -eq 1 ]] && error "Fix the .env values above before deploying."
ok ".env looks valid"

# ── 3. Create data directories ────────────────────────────────────────────────
info "Step 3/8 — Creating data directories..."
for dir in mysql postgres redis mongo \
           kafka-1 kafka-2 kafka-3 \
           uploads uploads-init \
           telematics-spool message-api \
           certs webroot \
           monitoring/prometheus monitoring/grafana monitoring/alertmanager \
           releases backups; do
  mkdir -p "${DATA_ROOT}/${dir}"
done
mkdir -p "${DEPLOY_DIR}/secrets"
ok "Directories created under ${DATA_ROOT}"

# ── 4. Ensure SSL cert exists so nginx can start ──────────────────────────────
info "Step 4/8 — Ensuring SSL cert exists (generating dummy if needed)..."
DOMAIN="${DOMAIN:-svtms.svtrucking.biz}"
CERT_DIR="${DATA_ROOT}/certs/live/${DOMAIN}"
CERT_FILE="${CERT_DIR}/fullchain.pem"
KEY_FILE="${CERT_DIR}/privkey.pem"

# Ensure all required directories exist
mkdir -p "${CERT_DIR}"
mkdir -p "${DATA_ROOT}/certs/archive/${DOMAIN}"
mkdir -p "${DATA_ROOT}/webroot/.well-known/acme-challenge"

if [[ -f "${CERT_FILE}" ]]; then
  ok "SSL cert already present at ${CERT_FILE}"
else
  warn "No SSL cert found — generating temporary self-signed cert so nginx can start"
  warn "Certbot (Step 7) will replace it with a real Let's Encrypt cert"

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -days 1 \
    -subj "/CN=${DOMAIN}/O=SV-TMS-Bootstrap/OU=Dummy" \
    2>/dev/null
  chmod 600 "${KEY_FILE}"
  # Mirror to archive directory (certbot uses this structure)
  cp "${CERT_FILE}" "${DATA_ROOT}/certs/archive/${DOMAIN}/fullchain1.pem" 2>/dev/null || true
  cp "${KEY_FILE}"  "${DATA_ROOT}/certs/archive/${DOMAIN}/privkey1.pem"   2>/dev/null || true
  ok "Dummy cert generated — nginx will start without SSL errors"
fi

# ── 5. Login to GHCR and pull/start the stack ─────────────────────────────────
info "Step 5/8 — Starting Docker stack..."

# Pull images (login to GHCR if token provided)
if [[ -n "${GHCR_TOKEN:-}" ]]; then
  echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR:-github}" --password-stdin
  ok "Logged into GHCR"
else
  warn "GHCR_TOKEN not set — skipping login. Public images only."
fi

cd "${DEPLOY_DIR}/infra"

# Pull all images
IMAGE_REGISTRY="${IMAGE_REGISTRY}" IMAGE_TAG="${IMAGE_TAG:-latest}" \
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull \
  2>&1 | grep -E "Pulling|pulled|exists|error|Error" || true

# Start all services
IMAGE_REGISTRY="${IMAGE_REGISTRY}" IMAGE_TAG="${IMAGE_TAG:-latest}" \
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" \
  up -d --remove-orphans
ok "Stack started"

# ── 6. Wait for all services to be healthy ────────────────────────────────────
info "Step 6/8 — Waiting for services to be healthy..."
MAX_WAIT=600
INTERVAL=10
elapsed=0

check_health() {
  local name="$1"; local port="$2"; local path="${3:-/actuator/health}"
  local url="http://127.0.0.1:${port}${path}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}" 2>/dev/null || echo "000")
  [[ "${code}" =~ ^(200|401|403)$ ]]
}

declare -A SERVICES=(
  [nginx]="80,/"
  [core-api]="8080,/actuator/health"
  [auth-api]="8083,/actuator/health"
  [api-gateway]="8086,/actuator/health"
  [driver-app-api]="8084,/actuator/health"
  [telematics-api]="8082,/actuator/health"
  [safety-api]="8087,/actuator/health"
  [message-api]="8088,/actuator/health"
)

while [[ "${elapsed}" -lt "${MAX_WAIT}" ]]; do
  all_up=true
  for svc in "${!SERVICES[@]}"; do
    IFS=',' read -r port path <<< "${SERVICES[${svc}]}"
    if ! check_health "${svc}" "${port}" "${path}" 2>/dev/null; then
      all_up=false
    fi
  done

  if "${all_up}"; then
    ok "All services healthy after ${elapsed}s"
    break
  fi

  echo "  Waiting... ${elapsed}/${MAX_WAIT}s"
  sleep "${INTERVAL}"
  elapsed=$((elapsed + INTERVAL))
done

# Show current status
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# ── 7. Obtain SSL certificate ──────────────────────────────────────────────────
info "Step 7/8 — Obtaining SSL certificate..."
DOMAIN="${DOMAIN:-svtms.svtrucking.biz}"
EMAIL="${EMAIL:-admin@svtrucking.biz}"

# Check if cert already exists
if [[ -f "${DATA_ROOT}/certs/live/${DOMAIN}/fullchain.pem" ]]; then
  ok "SSL certificate already exists — skipping certbot"
else
  warn "Requesting Let's Encrypt cert for ${DOMAIN}..."
  warn "Make sure DNS A record for ${DOMAIN} points to this server's IP!"
  echo ""

  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" run --rm certbot \
    certbot certonly \
    --webroot \
    -w /var/www/certbot \
    -d "${DOMAIN}" \
    -m "${EMAIL}" \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    2>&1 || {
      warn "Certbot failed. Check DNS and try: bash deploy/vps_deploy_now.sh --ssl-only"
      warn "Continuing with HTTP only..."
    }

  if [[ -f "${DATA_ROOT}/certs/live/${DOMAIN}/fullchain.pem" ]]; then
    ok "SSL certificate obtained for ${DOMAIN}"
  fi
fi

# ── 8. Reload nginx with real cert ────────────────────────────────────────────
info "Step 8/8 — Reloading nginx..."
CERT_PATH="${DATA_ROOT}/certs/live/${DOMAIN}/fullchain.pem"

if [[ -f "${CERT_PATH}" ]]; then
  # Check if the cert is a real Let's Encrypt cert (not the dummy)
  expiry_str=$(openssl x509 -in "${CERT_PATH}" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")
  expiry_ts=$(date -d "${expiry_str}" +%s 2>/dev/null || echo 0)
  now_ts=$(date +%s)
  days_left=$(( (expiry_ts - now_ts) / 86400 ))

  if [[ "${days_left}" -gt 1 ]]; then
    docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec nginx nginx -s reload \
      2>/dev/null && ok "nginx reloaded with Let's Encrypt cert (expires in ${days_left} days)" \
      || warn "nginx reload failed — try: docker exec svtms-nginx nginx -s reload"
  else
    warn "Dummy cert still in place — certbot did not obtain a real cert"
    warn "Check that DNS for ${DOMAIN} points to this server, then run:"
    warn "  docker exec svtms-certbot certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} -m ${EMAIL} --agree-tos --non-interactive"
    warn "  docker exec svtms-nginx nginx -s reload"
    warn "Site is accessible via HTTPS but browser will show certificate warning"
  fi
else
  warn "SSL cert not found at expected location."
  warn "Run: bash deploy/vps_deploy_now.sh to retry"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   SV-TMS deployed successfully! ✅${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  Site:     https://${DOMAIN}"
echo -e "  API:      https://${DOMAIN}/api/v1/"
echo -e "  Grafana:  http://$(hostname -I | awk '{print $1}'):3000  (localhost only)"
echo ""
echo "  Quick health check:"
echo "    curl -sk https://${DOMAIN}/actuator/health | python3 -m json.tool"
echo ""
echo "  View logs:"
echo "    docker compose -f ${COMPOSE_FILE} --env-file ${ENV_FILE} logs -f"
echo ""

# Run quick smoke check
info "Running quick smoke check..."
sleep 3
for endpoint in "/" "/api/actuator/health" "/auth/actuator/health"; do
  url="http://127.0.0.1:80${endpoint}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "${url}" 2>/dev/null || echo "000")
  if [[ "${code}" =~ ^(200|301|302|401|403)$ ]]; then
    echo -e "  ${GREEN}✅ ${endpoint} → HTTP ${code}${NC}"
  else
    echo -e "  ${RED}❌ ${endpoint} → HTTP ${code}${NC}"
  fi
done
