#!/usr/bin/env bash
# =============================================================================
# SV-TMS — Run emergency fix on VPS from your LOCAL machine
# =============================================================================
# Usage (run this from YOUR computer, not the VPS):
#   bash deploy/run_on_vps.sh
#
# Requirements: ssh, scp in PATH (standard on Mac/Linux)
# =============================================================================
set -euo pipefail

VPS_HOST="207.180.245.156"
VPS_USER="root"
DEPLOY_DIR="/opt/sv-tms"
KEY="${BASH_SOURCE%/*}/../infra/deploy_key"

# Fallback: use default SSH key if deploy_key doesn't exist
if [[ ! -f "${KEY}" ]]; then
  KEY="${HOME}/.ssh/id_rsa"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅  $*${NC}"; }
info() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $*${NC}"; }
fail() { echo -e "  ${RED}❌  $*${NC}"; }

SSH="ssh -i ${KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=15 ${VPS_USER}@${VPS_HOST}"

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   SV-TMS Full VPS Fix — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo "  VPS: ${VPS_HOST}"
echo "  Key: ${KEY}"
echo ""

# ── Test SSH connection ────────────────────────────────────────────────────────
info "Connecting to VPS..."
if ! ${SSH} "echo 'SSH OK'" 2>/dev/null; then
  fail "Cannot connect to VPS at ${VPS_HOST}"
  echo ""
  echo "  Check that:"
  echo "    1. The VPS is running"
  echo "    2. The deploy key has access: cat infra/deploy_key.pub"
  echo "       (add to /root/.ssh/authorized_keys on the VPS)"
  echo "    3. Port 22 is open on the VPS firewall"
  exit 1
fi
ok "Connected to VPS as ${VPS_USER}@${VPS_HOST}"

# ── Sync latest files to VPS ──────────────────────────────────────────────────
info "Syncing latest code to VPS..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Sync infra and deploy directories
rsync -az --delete \
  --exclude='.git' \
  --exclude='*.tar.gz' \
  --exclude='frontend_*.tar.gz' \
  -e "ssh -i ${KEY} -o StrictHostKeyChecking=no" \
  "${PROJECT_ROOT}/infra/docker-compose.prod.yml" \
  "${PROJECT_ROOT}/infra/nginx/" \
  "${VPS_USER}@${VPS_HOST}:${DEPLOY_DIR}/infra/" 2>/dev/null || true

rsync -az \
  -e "ssh -i ${KEY} -o StrictHostKeyChecking=no" \
  "${PROJECT_ROOT}/deploy/emergency_fix.sh" \
  "${PROJECT_ROOT}/deploy/diagnose.sh" \
  "${PROJECT_ROOT}/deploy/vps_deploy_now.sh" \
  "${VPS_USER}@${VPS_HOST}:${DEPLOY_DIR}/deploy/" 2>/dev/null || true

# Sync monitoring configs if present
if [[ -d "${PROJECT_ROOT}/infra/monitoring" ]]; then
  rsync -az \
    -e "ssh -i ${KEY} -o StrictHostKeyChecking=no" \
    "${PROJECT_ROOT}/infra/monitoring/" \
    "${VPS_USER}@${VPS_HOST}:${DEPLOY_DIR}/infra/monitoring/" 2>/dev/null || true
fi

ok "Latest files synced to VPS"

# ── Run the emergency fix on VPS ──────────────────────────────────────────────
info "Running emergency fix on VPS (this takes 3-5 minutes)..."
echo "  Streaming output from VPS:"
echo ""

${SSH} "chmod +x ${DEPLOY_DIR}/deploy/emergency_fix.sh && bash ${DEPLOY_DIR}/deploy/emergency_fix.sh"

FIX_EXIT=$?

echo ""
if [[ "${FIX_EXIT}" -eq 0 ]]; then
  info "All done! Testing site in browser..."
  echo ""
  echo -e "  ${GREEN}${BOLD}https://svtms.svtrucking.biz${NC}"
  echo ""

  # Quick external check
  CODE=$(curl -sk --max-time 10 -o /dev/null -w "%{http_code}" "https://svtms.svtrucking.biz/" 2>/dev/null || echo "000")
  if [[ "${CODE}" =~ ^(200|301|302)$ ]]; then
    echo -e "  ${GREEN}✅  Site is LIVE! HTTP ${CODE}${NC}"
  else
    warn "External check returned HTTP ${CODE} — may still be starting up"
    echo "  Wait 2 minutes then visit: https://svtms.svtrucking.biz"
  fi
else
  warn "Fix script exited with code ${FIX_EXIT}"
  echo "  Check VPS logs:"
  echo "    ssh -i infra/deploy_key root@${VPS_HOST} 'bash ${DEPLOY_DIR}/deploy/diagnose.sh'"
fi
