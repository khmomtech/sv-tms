#!/usr/bin/env bash
# =============================================================================
# deploy-local-build.sh <service>
#
# Builds the Docker image on your Mac (fast) and streams it to VPS via SSH.
# No Maven build on VPS — saves 5-8 minutes per deploy.
#
# Usage:
#   bash deploy-local-build.sh core-api
#   bash deploy-local-build.sh auth-api
#   bash deploy-local-build.sh driver-app-api
#   bash deploy-local-build.sh api-gateway
# =============================================================================
set -euo pipefail

SERVICE="${1:-}"
if [ -z "$SERVICE" ]; then
  echo "Usage: bash deploy-local-build.sh <service>"
  echo "  Services: core-api auth-api driver-app-api api-gateway safety-api"
  exit 1
fi

VPS="207.180.245.156"
VPS_USER="root"
KEY="$(dirname "$0")/infra/deploy_key"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE="svtms-${SERVICE}:local"
COMPOSE_FILES="-f /opt/sv-tms/repo/infra/docker-compose.prod.yml -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml"

SSH="ssh -i $KEY -o StrictHostKeyChecking=no $VPS_USER@$VPS"

# Map service → Dockerfile
case "$SERVICE" in
  core-api)        DOCKERFILE="tms-core-api/Dockerfile" ;;
  auth-api)        DOCKERFILE="tms-auth-api/Dockerfile" ;;
  driver-app-api)  DOCKERFILE="tms-driver-app-api/Dockerfile" ;;
  api-gateway)     DOCKERFILE="api-gateway/Dockerfile" ;;
  safety-api)      DOCKERFILE="tms-safety-api/Dockerfile" ;;
  *)
    echo "Unknown service: $SERVICE"
    echo "Supported: core-api auth-api driver-app-api api-gateway safety-api"
    exit 1
    ;;
esac

echo "============================================"
echo "  Building $SERVICE locally → push to VPS"
echo "============================================"

echo "[1/3] Building image $IMAGE locally..."
cd "$SCRIPT_DIR"
docker build \
  --platform linux/amd64 \
  -t "$IMAGE" \
  -f "$DOCKERFILE" \
  .

echo ""
echo "[2/3] Streaming image to VPS (may take 1-2 min)..."
docker save "$IMAGE" | \
  ssh -i "$KEY" -o StrictHostKeyChecking=no \
      -o Compression=no \
      "$VPS_USER@$VPS" \
  "docker load"

echo ""
echo "[3/3] Restarting $SERVICE on VPS..."
$SSH "cd /opt/sv-tms/repo/infra && \
  docker compose $COMPOSE_FILES up -d --no-build $SERVICE && \
  sleep 5 && \
  docker compose $COMPOSE_FILES ps $SERVICE"

echo ""
echo "Done. Tailing logs (Ctrl+C to stop):"
$SSH "docker logs --tail=30 -f svtms-$SERVICE 2>&1" || true
