#!/usr/bin/env bash
# ============================================================
# PASTE THIS ENTIRE FILE INTO YOUR LOCAL TERMINAL
#
# It will:
#  1. Sync all source code + scripts to VPS
#  2. Build all Docker images on the VPS (~20-40 min first run)
#  3. Start the full stack
#  4. Verify everything is working
#
# Run from the sv-tms project folder on YOUR machine.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEY="${SCRIPT_DIR}/../infra/deploy_key"
VPS="root@207.180.245.156"
DEPLOY_DIR="/opt/sv-tms"
SRC_DIR="${DEPLOY_DIR}/src"

# Fallback to default SSH key
[[ ! -f "${KEY}" ]] && KEY="${HOME}/.ssh/id_rsa"

SSH_CMD="ssh -i ${KEY} -o StrictHostKeyChecking=no"

echo ""
echo "========================================================"
echo "  SV-TMS Full Deploy (Build + Start)"
echo "========================================================"
echo ""

# ── Test connection ───────────────────────────────────────────────────────────
echo "▶ Testing VPS connection..."
if ! ${SSH_CMD} "${VPS}" "echo 'connected'" &>/dev/null; then
  echo "❌ Cannot connect to VPS. Check your SSH key and VPS status."
  exit 1
fi
echo "  ✅ Connected"

# ── Sync infra/deploy files ───────────────────────────────────────────────────
echo ""
echo "▶ Syncing infra + deploy scripts..."
rsync -az -e "${SSH_CMD}" \
  "${PROJECT_ROOT}/infra/docker-compose.prod.yml" \
  "${VPS}:${DEPLOY_DIR}/infra/"

rsync -az -e "${SSH_CMD}" \
  "${PROJECT_ROOT}/infra/nginx/" \
  "${VPS}:${DEPLOY_DIR}/infra/nginx/"

rsync -az -e "${SSH_CMD}" \
  "${PROJECT_ROOT}/infra/.env" \
  "${VPS}:${DEPLOY_DIR}/infra/"

rsync -az -e "${SSH_CMD}" \
  "${PROJECT_ROOT}/deploy/" \
  "${VPS}:${DEPLOY_DIR}/deploy/"

if [[ -d "${PROJECT_ROOT}/infra/monitoring" ]]; then
  rsync -az -e "${SSH_CMD}" \
    "${PROJECT_ROOT}/infra/monitoring/" \
    "${VPS}:${DEPLOY_DIR}/infra/monitoring/"
fi
echo "  ✅ Infra files synced"

# ── Sync source code ──────────────────────────────────────────────────────────
echo ""
echo "▶ Syncing source code to VPS (this may take a few minutes)..."
${SSH_CMD} "${VPS}" "mkdir -p ${SRC_DIR}"

rsync -az --delete --info=progress2 \
  --exclude='.git/' \
  --exclude='*/target/' \
  --exclude='*/node_modules/' \
  --exclude='*/dist/' \
  --exclude='*/.angular/' \
  --exclude='*.sql' \
  --exclude='*.tar.gz' \
  --exclude='backups/' \
  --exclude='data/' \
  --exclude='uploads/' \
  --exclude='spool/' \
  --exclude='tms_driver_app/' \
  --exclude='tms_customer_app/' \
  --exclude='.DS_Store' \
  -e "${SSH_CMD}" \
  "${PROJECT_ROOT}/" \
  "${VPS}:${SRC_DIR}/" \
  2>&1 | tail -3

echo "  ✅ Source code synced"

# ── Run build + start on VPS ──────────────────────────────────────────────────
echo ""
echo "▶ Building Docker images and starting stack on VPS..."
echo "  ⏱  First build takes 20-40 minutes. Please wait..."
echo ""

${SSH_CMD} "${VPS}" \
  "chmod +x ${DEPLOY_DIR}/deploy/build_on_vps_direct.sh && \
   bash ${DEPLOY_DIR}/deploy/build_on_vps_direct.sh"

echo ""
echo "========================================================"
echo "  Done! Site: https://svtms.svtrucking.biz"
echo "========================================================"
echo ""
