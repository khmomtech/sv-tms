#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Build images DIRECTLY on VPS (run this while SSH'd into the VPS)
# =============================================================================
# Usage: SSH into the VPS first, then:
#   ssh root@207.180.245.156
#   bash /opt/sv-tms/deploy/build_on_vps_direct.sh
#
# OR paste this entire script into your SSH session.
#
# Requirements:
#   - Source code must be synced to /opt/sv-tms/src/ first.
#     Run deploy/build_images_on_vps.sh from your LOCAL machine to sync + build,
#     OR manually: git clone <your-repo> /opt/sv-tms/src
# =============================================================================
set -uo pipefail

DEPLOY_DIR="/opt/sv-tms"
SRC_DIR="${DEPLOY_DIR}/src"
ENV_FILE="${DEPLOY_DIR}/infra/.env"
COMPOSE_FILE="${DEPLOY_DIR}/infra/docker-compose.prod.yml"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $*${NC}"; }
info() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; }
fail() { echo -e "  ${RED}❌  $*${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   SV-TMS — VPS Direct Build — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check source exists
if [[ ! -d "${SRC_DIR}" ]]; then
  fail "Source not found at ${SRC_DIR}"
  echo ""
  echo "  You need to sync the source code first. From your LOCAL machine run:"
  echo "    bash deploy/build_images_on_vps.sh"
  echo ""
  echo "  OR clone your git repo directly on the VPS:"
  echo "    git clone https://github.com/YOUR_ORG/sv-tms.git ${SRC_DIR}"
  exit 1
fi

ok "Source found at ${SRC_DIR}"

# Enable BuildKit
export DOCKER_BUILDKIT=1

cd "${SRC_DIR}"

# ── Build all images ──────────────────────────────────────────────────────────
info "Building all Docker images (this takes ~20-40 min first run)..."

PASS=0; FAIL=0; SKIP=0

build_image() {
  local tag="$1" dockerfile="$2" context="$3"
  local name="${tag##*/}"; name="${name%%:*}"

  # Skip existing images unless REBUILD_ALL=true
  if [[ "${REBUILD_ALL:-false}" != "true" ]] && \
     docker image inspect "${tag}" &>/dev/null 2>&1; then
    echo -e "  ${YELLOW}⏭  ${name}: exists — skipping (REBUILD_ALL=true to force)${NC}"
    ((SKIP++))
    return 0
  fi

  echo ""
  echo -e "  ${CYAN}▶ Building: ${name}${NC}"
  local start; start=$(date +%s)

  if docker build \
    --tag "${tag}" \
    --file "${dockerfile}" \
    "${context}" \
    2>&1 | grep -E "^(Step|#[0-9]+|ERROR|error:|Successfully built|writing image)" | tail -20; then
    echo -e "  ${GREEN}✅  ${name}: done in $(( $(date +%s) - start ))s${NC}"
    ((PASS++))
  else
    echo -e "  ${RED}❌  ${name}: FAILED${NC}"
    ((FAIL++))
  fi
}

build_image "local/svtms-core-api:latest"        "tms-core-api/Dockerfile"     "."
build_image "local/svtms-auth-api:latest"         "tms-auth-api/Dockerfile"     "."
build_image "local/svtms-driver-app-api:latest"   "tms-driver-app-api/Dockerfile" "."
build_image "local/svtms-message-api:latest"      "tms-message-api/Dockerfile"  "."
build_image "local/svtms-api-gateway:latest"      "api-gateway/Dockerfile"      "."
build_image "local/svtms-telematics-api:latest"   "tms-telematics-api/Dockerfile" "./tms-telematics-api"
build_image "local/svtms-safety-api:latest"       "tms-safety-api/Dockerfile"   "./tms-safety-api"
build_image "local/svtms-admin-web-ui:latest"     "tms-admin-web-ui/Dockerfile" "./tms-admin-web-ui"

echo ""
echo -e "  Built: ${PASS} | Skipped: ${SKIP} | Failed: ${FAIL}"

# ── Update .env ───────────────────────────────────────────────────────────────
info "Updating .env..."

if [[ -f "${ENV_FILE}" ]]; then
  sed -i 's|^IMAGE_REGISTRY=.*|IMAGE_REGISTRY=local|' "${ENV_FILE}" 2>/dev/null || \
    echo "IMAGE_REGISTRY=local" >> "${ENV_FILE}"
  sed -i 's|^IMAGE_TAG=.*|IMAGE_TAG=latest|' "${ENV_FILE}" 2>/dev/null || \
    echo "IMAGE_TAG=latest" >> "${ENV_FILE}"
  ok ".env: IMAGE_REGISTRY=local, IMAGE_TAG=latest"
else
  warn ".env not found at ${ENV_FILE}"
fi

# ── Restart stack ─────────────────────────────────────────────────────────────
info "Restarting stack..."

if [[ -f "${COMPOSE_FILE}" && -f "${ENV_FILE}" ]]; then
  IMAGE_REGISTRY=local IMAGE_TAG=latest \
    docker compose \
      --env-file "${ENV_FILE}" \
      -f "${COMPOSE_FILE}" \
      up -d --remove-orphans --pull never

  echo ""
  ok "Stack started"
  echo ""
  IMAGE_REGISTRY=local IMAGE_TAG=latest \
    docker compose \
      --env-file "${ENV_FILE}" \
      -f "${COMPOSE_FILE}" \
      ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | head -30
else
  warn "compose file or .env missing — please run emergency_fix.sh first:"
  echo "  bash ${DEPLOY_DIR}/deploy/emergency_fix.sh"
fi

echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}   Build complete!${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "  Spring Boot services take 2-3 min to fully start."
echo ""
echo "  Check status:"
echo "    bash ${DEPLOY_DIR}/deploy/diagnose.sh"
echo ""
echo "  Watch logs:"
echo "    docker compose -f ${COMPOSE_FILE} --env-file ${ENV_FILE} logs -f --tail=30"
echo ""
echo "  Site: https://svtms.svtrucking.biz"
echo ""
