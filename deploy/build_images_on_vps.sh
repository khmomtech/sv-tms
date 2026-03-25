#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Build all Docker images DIRECTLY on the VPS from source code
# =============================================================================
# Run this from YOUR LOCAL machine (not the VPS):
#   bash deploy/build_images_on_vps.sh
#
# What it does:
#   1. Rsyncs the source code to the VPS (excluding compiled artifacts)
#   2. Builds all 8 Docker images on the VPS using docker build
#   3. Tags them as local/svtms-*:latest (matching docker-compose.prod.yml)
#   4. Updates .env to use IMAGE_REGISTRY=local IMAGE_TAG=latest
#   5. Restarts the full stack with the newly built images
#   6. Verifies all services are healthy
#
# Build time: ~20-40 minutes (first run; ~10 min with Docker layer cache)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEY="${PROJECT_ROOT}/infra/deploy_key"
VPS_HOST="207.180.245.156"
VPS_USER="root"
DEPLOY_DIR="/opt/sv-tms"
SRC_DIR="${DEPLOY_DIR}/src"
LOG_FILE="/tmp/svtms-build-$(date +%Y%m%d-%H%M%S).log"

# Fallback to default SSH key
if [[ ! -f "${KEY}" ]]; then
  KEY="${HOME}/.ssh/id_rsa"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $*${NC}"; }
info() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; }
fail() { echo -e "  ${RED}❌  $*${NC}"; }

SSH="ssh -i ${KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=20 ${VPS_USER}@${VPS_HOST}"

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   SV-TMS — Build Images on VPS — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo "  VPS:  ${VPS_HOST}"
echo "  Key:  ${KEY}"
echo "  Log:  ${LOG_FILE}"
echo ""

# ── Test SSH connection ────────────────────────────────────────────────────────
info "Step 1/6 — Testing VPS connection..."
if ! ${SSH} "echo 'connected'" &>/dev/null; then
  fail "Cannot connect to VPS at ${VPS_HOST}"
  echo ""
  echo "  Check that:"
  echo "    1. VPS is running"
  echo "    2. deploy key is authorised: ssh -i ${KEY} ${VPS_USER}@${VPS_HOST}"
  echo "    3. Port 22 is open on the firewall"
  exit 1
fi
ok "Connected to VPS"

# ── Sync source code to VPS ───────────────────────────────────────────────────
info "Step 2/6 — Syncing source code to VPS (excluding build artifacts)..."
echo "  This may take a few minutes on first run..."

# Create src directory on VPS
${SSH} "mkdir -p ${SRC_DIR}"

# Rsync all source code, excluding compiled output + large non-code files
rsync -az --info=progress2 \
  --delete \
  --exclude='.git/' \
  --exclude='*/target/' \
  --exclude='*/node_modules/' \
  --exclude='*/dist/' \
  --exclude='*/.angular/' \
  --exclude='*/.cache/' \
  --exclude='*.sql' \
  --exclude='*.tar.gz' \
  --exclude='*.zip' \
  --exclude='backups/' \
  --exclude='data/' \
  --exclude='uploads/' \
  --exclude='spool/' \
  --exclude='tms_driver_app/' \
  --exclude='tms_customer_app/' \
  --exclude='tms_pre_load_safety_check/' \
  --exclude='sv_loading_app/' \
  --exclude='migration-extracts/' \
  --exclude='.DS_Store' \
  --exclude='deploy/build_images_on_vps.sh' \
  -e "ssh -i ${KEY} -o StrictHostKeyChecking=no" \
  "${PROJECT_ROOT}/" \
  "${VPS_USER}@${VPS_HOST}:${SRC_DIR}/" \
  2>&1 | tail -5

ok "Source code synced to ${SRC_DIR}"

# ── Build all Docker images on VPS ────────────────────────────────────────────
info "Step 3/6 — Building Docker images on VPS..."
echo "  ⏱  First build: ~25-40 minutes (Maven + npm)"
echo "  ⏱  Subsequent builds: ~5-15 minutes (with layer cache)"
echo "  Output is streamed live..."
echo ""

${SSH} "bash -s" << 'BUILD_SCRIPT'
set -uo pipefail

SRC_DIR="/opt/sv-tms/src"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $*${NC}"; }
info() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; }
fail() { echo -e "  ${RED}❌  $*${NC}"; }

# Enable Docker BuildKit for better caching
export DOCKER_BUILDKIT=1

cd "${SRC_DIR}"

# ── Image build configuration ─────────────────────────────────────────────────
# Format: "image-tag|dockerfile|build-context"
declare -a IMAGES=(
  "local/svtms-core-api:latest|tms-core-api/Dockerfile|."
  "local/svtms-auth-api:latest|tms-auth-api/Dockerfile|."
  "local/svtms-driver-app-api:latest|tms-driver-app-api/Dockerfile|."
  "local/svtms-message-api:latest|tms-message-api/Dockerfile|."
  "local/svtms-api-gateway:latest|api-gateway/Dockerfile|."
  "local/svtms-telematics-api:latest|tms-telematics-api/Dockerfile|./tms-telematics-api"
  "local/svtms-safety-api:latest|tms-safety-api/Dockerfile|./tms-safety-api"
  "local/svtms-admin-web-ui:latest|tms-admin-web-ui/Dockerfile|./tms-admin-web-ui"
)

PASS=0; FAIL=0; SKIP=0
START_TOTAL=$(date +%s)

for entry in "${IMAGES[@]}"; do
  IFS='|' read -r image_tag dockerfile context <<< "${entry}"
  image_name="${image_tag%%:*}"
  short_name="${image_name##*/}"

  # Skip if image already exists locally (use --no-cache flag to force rebuild)
  if [[ "${REBUILD_ALL:-false}" != "true" ]] && \
     docker image inspect "${image_tag}" &>/dev/null 2>&1; then
    echo -e "  ${YELLOW}⏭  ${short_name}: already exists — skipping (set REBUILD_ALL=true to force)${NC}"
    ((SKIP++))
    continue
  fi

  info "Building ${short_name}..."
  START=$(date +%s)

  if docker build \
    --tag "${image_tag}" \
    --file "${dockerfile}" \
    --progress=plain \
    "${context}" \
    2>&1 | \
    grep -E "^(Step|#[0-9]|ERROR|error:|WARN|Successfully|==>|RUN|COPY|FROM|writing image)" | \
    tail -30; then

    ELAPSED=$(( $(date +%s) - START ))
    ok "${short_name}: built in ${ELAPSED}s"
    ((PASS++))
  else
    fail "${short_name}: BUILD FAILED"
    ((FAIL++))
    echo "  Check logs above for the build error."
  fi
done

END_TOTAL=$(date +%s)
TOTAL=$(( END_TOTAL - START_TOTAL ))

echo ""
echo -e "${BOLD}${CYAN}═══════════════ Build Summary ═══════════════${NC}"
echo -e "  ✅  Built:   ${PASS}"
echo -e "  ⏭  Skipped: ${SKIP}"
echo -e "  ❌  Failed:  ${FAIL}"
echo -e "  ⏱  Total:   ${TOTAL}s"
echo ""

if [[ "${FAIL}" -gt 0 ]]; then
  echo "Some images failed to build. The stack will start with existing cached images."
  exit 1
fi

exit 0
BUILD_SCRIPT

BUILD_EXIT=$?

if [[ "${BUILD_EXIT}" -ne 0 ]]; then
  warn "Some images failed to build — check errors above"
  echo "  You can fix errors and rerun just the failed images"
else
  ok "All images built successfully"
fi

# ── Update .env on VPS ────────────────────────────────────────────────────────
info "Step 4/6 — Updating IMAGE_REGISTRY in VPS .env..."

${SSH} "bash -s" << 'ENV_SCRIPT'
ENV_FILE="/opt/sv-tms/infra/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "  .env not found — skipping"
  exit 0
fi

# Update IMAGE_REGISTRY to local
if grep -q '^IMAGE_REGISTRY=' "${ENV_FILE}"; then
  sed -i 's|^IMAGE_REGISTRY=.*|IMAGE_REGISTRY=local|' "${ENV_FILE}"
else
  echo "IMAGE_REGISTRY=local" >> "${ENV_FILE}"
fi

# Update IMAGE_TAG to latest
if grep -q '^IMAGE_TAG=' "${ENV_FILE}"; then
  sed -i 's|^IMAGE_TAG=.*|IMAGE_TAG=latest|' "${ENV_FILE}"
else
  echo "IMAGE_TAG=latest" >> "${ENV_FILE}"
fi

echo "  IMAGE_REGISTRY=$(grep '^IMAGE_REGISTRY=' ${ENV_FILE} | cut -d= -f2)"
echo "  IMAGE_TAG=$(grep '^IMAGE_TAG=' ${ENV_FILE} | cut -d= -f2)"
ENV_SCRIPT

ok ".env updated: IMAGE_REGISTRY=local, IMAGE_TAG=latest"

# ── Restart the stack ─────────────────────────────────────────────────────────
info "Step 5/6 — Restarting the stack with newly built images..."

${SSH} "bash -s" << 'RESTART_SCRIPT'
DEPLOY_DIR="/opt/sv-tms"
ENV_FILE="${DEPLOY_DIR}/infra/.env"
COMPOSE_FILE="${DEPLOY_DIR}/infra/docker-compose.prod.yml"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

if [[ ! -f "${ENV_FILE}" ]] || [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "  Missing .env or compose file — running emergency_fix.sh first..."
  bash "${DEPLOY_DIR}/deploy/emergency_fix.sh"
  exit $?
fi

# Pull policy: never — use only local images we just built
IMAGE_REGISTRY=local IMAGE_TAG=latest \
  docker compose \
    --env-file "${ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    up -d \
    --remove-orphans \
    --pull never

echo ""
echo -e "${BOLD}${CYAN}Container status:${NC}"
IMAGE_REGISTRY=local IMAGE_TAG=latest \
  docker compose \
    --env-file "${ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | head -30
RESTART_SCRIPT

ok "Stack restarted"

# ── Verify services ───────────────────────────────────────────────────────────
info "Step 6/6 — Waiting for services and verifying..."
echo "  Spring Boot services need ~2-3 minutes to start..."
echo "  Waiting 90 seconds..."
sleep 90

${SSH} "bash ${DEPLOY_DIR}/deploy/diagnose.sh 2>/dev/null | tail -60" || \
${SSH} "bash /opt/sv-tms/deploy/diagnose.sh" || true

echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}   Build & Deploy Complete!${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  🌐  Site:    https://svtms.svtrucking.biz"
echo "  📊  Grafana: http://${VPS_HOST}:3000  (admin / SvTms@2026Secure!)"
echo ""
echo "  If Spring Boot services are still starting, wait 3 minutes and visit:"
echo "  https://svtms.svtrucking.biz"
echo ""
echo "  To watch logs live on VPS:"
echo "  ssh -i ${KEY} ${VPS_USER}@${VPS_HOST} \\"
echo "    'docker compose -f /opt/sv-tms/infra/docker-compose.prod.yml \\"
echo "     --env-file /opt/sv-tms/infra/.env logs -f --tail=50'"
echo ""
