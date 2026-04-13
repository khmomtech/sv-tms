#!/usr/bin/env bash
# =============================================================================
# DEPLOY_TO_VPS.sh
# Run from your Mac terminal inside the sv-tms folder:
#   bash DEPLOY_TO_VPS.sh
# =============================================================================
set -euo pipefail

VPS="207.180.245.156"
VPS_USER="root"
KEY="$(dirname "$0")/infra/deploy_key"
APP_DIR="/opt/sv-tms"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_ARGS="-f docker-compose.prod.yml -f docker-compose.build-override.yml"
ALL_APP_SERVICES=(core-api auth-api driver-app-api message-api telematics-api safety-api api-gateway admin-web-ui)
SELECTED_SERVICES=()
FORCE_FULL_DEPLOY=false

# SSH/SCP helpers — fall back to password auth if key doesn't exist
ssh_cmd() {
  if [ -f "$KEY" ]; then
    ssh -i "$KEY" -o StrictHostKeyChecking=no "$@"
  else
    ssh -o StrictHostKeyChecking=no "$@"
  fi
}

scp_cmd() {
  if [ -f "$KEY" ]; then
    scp -i "$KEY" -o StrictHostKeyChecking=no "$@"
  else
    scp -o StrictHostKeyChecking=no "$@"
  fi
}

rsync_cmd() {
  if [ -f "$KEY" ]; then
    rsync -e "ssh -i $KEY -o StrictHostKeyChecking=no" "$@"
  else
    rsync -e "ssh -o StrictHostKeyChecking=no" "$@"
  fi
}

shell_escape() {
  printf '%q' "$1"
}

usage() {
  cat <<'EOF'
Usage:
  bash DEPLOY_TO_VPS.sh
  bash DEPLOY_TO_VPS.sh --full
  bash DEPLOY_TO_VPS.sh --service core-api --service admin-web-ui
EOF
}

add_service() {
  local service=$1
  local known=false
  local existing
  for existing in "${ALL_APP_SERVICES[@]}"; do
    if [ "$existing" = "$service" ]; then
      known=true
      break
    fi
  done
  if [ "$known" != true ]; then
    echo "Unknown service: $service" >&2
    usage
    exit 1
  fi
  if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
    for existing in "${SELECTED_SERVICES[@]}"; do
      [ "$existing" = "$service" ] && return 0
    done
  fi
  SELECTED_SERVICES+=("$service")
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --full)
        FORCE_FULL_DEPLOY=true
        ;;
      --service)
        shift
        [ $# -gt 0 ] || { echo "--service requires a value" >&2; exit 1; }
        add_service "$1"
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        add_service "$1"
        ;;
    esac
    shift
  done
}

detect_changed_services() {
  local changed_files
  local file

  if ! command -v git >/dev/null 2>&1 || ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  changed_files="$(
    {
      git -C "$SCRIPT_DIR" diff --name-only HEAD --
      git -C "$SCRIPT_DIR" ls-files --others --exclude-standard
    } | sort -u
  )"

  [ -n "$changed_files" ] || return 0

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    case "$file" in
      pom.xml|DEPLOY_TO_VPS.sh|infra/*|tms-backend-shared/*|device-gateway/*|tms-message-api/*|tms-telematics-api/*)
        FORCE_FULL_DEPLOY=true
        return 0
        ;;
      tms-core-api/*)
        add_service "core-api"
        ;;
      tms-auth-api/*)
        add_service "auth-api"
        ;;
      tms-driver-app-api/*)
        add_service "driver-app-api"
        ;;
      tms-safety-api/*)
        add_service "safety-api"
        ;;
      api-gateway/*)
        add_service "api-gateway"
        ;;
      tms-admin-web-ui/*)
        add_service "admin-web-ui"
        ;;
    esac
  done <<EOF
$changed_files
EOF
}

parse_args "$@"
if [ "$FORCE_FULL_DEPLOY" != true ] && [ ${#SELECTED_SERVICES[@]} -eq 0 ]; then
  detect_changed_services
fi
if [ "$FORCE_FULL_DEPLOY" = true ] || [ ${#SELECTED_SERVICES[@]} -eq 0 ]; then
  SELECTED_SERVICES=("${ALL_APP_SERVICES[@]}")
fi

DEPLOY_TARGETS="${SELECTED_SERVICES[*]}"
REMOTE_ENV_VARS=("DEPLOY_TARGETS=$(shell_escape "$DEPLOY_TARGETS")")
[ -n "${ADMIN_USERNAME:-}" ] && REMOTE_ENV_VARS+=("ADMIN_USERNAME=$(shell_escape "$ADMIN_USERNAME")")
[ -n "${ADMIN_PASSWORD:-}" ] && REMOTE_ENV_VARS+=("ADMIN_PASSWORD=$(shell_escape "$ADMIN_PASSWORD")")
[ -n "${ADMIN_TOKEN:-}" ] && REMOTE_ENV_VARS+=("ADMIN_TOKEN=$(shell_escape "$ADMIN_TOKEN")")
REMOTE_ENV_STRING="${REMOTE_ENV_VARS[*]}"

echo "============================================"
echo "  SV-TMS → Deploying to VPS $VPS"
echo "============================================"
echo "  Services: ${DEPLOY_TARGETS}"

# ── 1. Rsync only what's needed for Docker build ─────────────────────────────
echo "[1/6] Syncing source to VPS (services + infra only)..."
ssh_cmd ${VPS_USER}@${VPS} "mkdir -p ${APP_DIR}/repo"

echo "  → syncing root pom.xml"
rsync_cmd -az "${SCRIPT_DIR}/pom.xml" ${VPS_USER}@${VPS}:${APP_DIR}/repo/pom.xml

for dir in infra api-gateway tms-core-api tms-auth-api tms-telematics-api \
           tms-driver-app-api tms-safety-api tms-message-api tms-admin-web-ui \
           device-gateway tms-backend-shared; do
  [ -d "${SCRIPT_DIR}/${dir}" ] || continue
  echo "  → syncing ${dir}/"
  rsync_cmd -az --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.angular' \
    --exclude='.next' \
    --exclude='dist' \
    --exclude='target' \
    --exclude='.gradle' \
    --exclude='build' \
    --exclude='/uploads' \
    --exclude='/spool' \
    --exclude='/data' \
    --exclude='/backups' \
    --exclude='*.log' \
    "${SCRIPT_DIR}/${dir}/" \
    ${VPS_USER}@${VPS}:${APP_DIR}/repo/${dir}/
done

# ── 2. Copy env + build-override into the right place on VPS ─────────────────
echo "[2/6] Copying env + override files..."
scp_cmd \
  "${SCRIPT_DIR}/infra/.env" \
  "${SCRIPT_DIR}/infra/docker-compose.build-override.yml" \
  ${VPS_USER}@${VPS}:${APP_DIR}/repo/infra/

# ── 3. SSH in and run deployment ──────────────────────────────────────────────
echo "[3/6] Connecting to VPS and running deployment..."
ssh_cmd ${VPS_USER}@${VPS} "${REMOTE_ENV_STRING} bash -s" << 'REMOTE'
set -euo pipefail
APP_DIR="/opt/sv-tms"
COMPOSE_ARGS="-f docker-compose.prod.yml -f docker-compose.build-override.yml"

compose() {
  docker compose ${COMPOSE_ARGS} "$@"
}

get_env_value() {
  local key=$1
  local file="${APP_DIR}/repo/infra/.env"
  local value
  value=$(grep "^${key}=" "$file" | tail -n1 | cut -d= -f2- || true)
  printf '%s' "${value}" | tr -d '[:space:]'
}

# ── Install Docker if missing ─────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker --now
fi

# ── Install docker compose plugin if missing ──────────────────────────────────
if ! docker compose version &>/dev/null 2>&1; then
  echo "Installing Docker Compose plugin..."
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -SL "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

echo "Docker:  $(docker --version)"
echo "Compose: $(docker compose version)"

DOMAIN_VAR=$(get_env_value DOMAIN)
DOMAIN_VAR="${DOMAIN_VAR:-svtms.svtrucking.biz}"
EMAIL_VAR=$(get_env_value EMAIL)
EMAIL_VAR="${EMAIL_VAR:-admin@svtrucking.biz}"
DATA_ROOT=$(get_env_value DATA_ROOT)
DATA_ROOT="${DATA_ROOT:-/srv/svtms}"
CERT_ROOT="${DATA_ROOT}/certs"

# ── Ensure swap space (Maven OOMs without it on small VPS) ───────────────────
if [ "$(swapon --show | wc -l)" -eq 0 ]; then
  echo "No swap detected — creating 4 GB swapfile..."
  fallocate -l 4G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=4096
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl -w vm.swappiness=10
  echo "vm.swappiness=10" >> /etc/sysctl.conf
  echo "Swap: $(free -h | grep Swap)"
else
  echo "Swap already active: $(swapon --show --noheadings)"
fi

# ── Create data directories ───────────────────────────────────────────────────
mkdir -p "${DATA_ROOT}"/{mysql,postgres,redis,mongo,uploads,spool,telematics-spool,message-api,certs,webroot}
mkdir -p "${DATA_ROOT}"/kafka-{1,2,3}
mkdir -p "${DATA_ROOT}"/monitoring/{prometheus,alertmanager,grafana}
mkdir -p "${DATA_ROOT}"/certbot/{work,logs}
mkdir -p /opt/sv-tms/secrets

if [ ! -f /opt/sv-tms/secrets/firebase-service-account.json ]; then
  echo '{}' > /opt/sv-tms/secrets/firebase-service-account.json
fi

# ── Pull infrastructure images ────────────────────────────────────────────────
echo ""
echo "[4/6] Pulling base images (mysql, redis, kafka, nginx...)..."
cd "${APP_DIR}/repo/infra"
compose pull mysql postgres mongo redis kafka-1 kafka-2 kafka-3 nginx prometheus grafana node-exporter certbot 2>/dev/null || true

# ── Build app images (sequential to avoid OOM on small VPS) ──────────────────
echo ""
echo "[5/6] Building application images (${DEPLOY_TARGETS})..."
read -r -a TARGET_SERVICES <<< "${DEPLOY_TARGETS}"
for svc in "${TARGET_SERVICES[@]}"; do
  echo "  → building ${svc}..."
  compose build "${svc}"
done

# ── Start infrastructure, wait for health ────────────────────────────────────
echo ""
echo "[6/6] Starting all services..."
compose up -d mysql postgres mongo redis kafka-1 kafka-2 kafka-3

echo "Waiting 60s for databases and Kafka to be ready..."
sleep 60

# ── Start application services (nginx comes after SSL) ───────────────────────
compose up -d "${TARGET_SERVICES[@]}" || true

# Review-critical APIs should still come up even if Kafka health is currently
# red and Compose refuses to finish the dependency graph. Their containers have
# already been created at this point, so start them directly if needed.
for container in svtms-core-api svtms-auth-api svtms-driver-app-api svtms-api-gateway svtms-admin-web-ui svtms-telematics-api svtms-safety-api svtms-message-api; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    docker start "$container" >/dev/null 2>&1 || true
  fi
done

# If nginx is already running, reload it so Docker DNS names resolve to the
# fresh container IPs after recreate/build cycles. This prevents stale upstream
# addresses from breaking /ws and /ws-sockjs with 502s.
if compose ps nginx 2>/dev/null | grep -q "svtms-nginx"; then
  compose exec -T nginx nginx -s reload || true
fi

# ── SSL certificate bootstrap ─────────────────────────────────────────────────
if [ ! -f "${CERT_ROOT}/live/${DOMAIN_VAR}/fullchain.pem" ]; then
  echo ""
  echo "No SSL certificate found — obtaining via certbot (standalone on :80)..."
  if ! command -v certbot &>/dev/null; then
    apt-get update -qq
    apt-get install -y --no-install-recommends certbot
  fi
  certbot certonly --standalone --non-interactive --agree-tos \
    --config-dir "${CERT_ROOT}" \
    --work-dir "${DATA_ROOT}/certbot/work" \
    --logs-dir "${DATA_ROOT}/certbot/logs" \
    -m "$EMAIL_VAR" -d "$DOMAIN_VAR" || {
      echo "WARNING: certbot failed — check DNS and firewall (port 80 must be open)."
      echo "         Re-run manually: certbot certonly --standalone --config-dir ${CERT_ROOT} --work-dir ${DATA_ROOT}/certbot/work --logs-dir ${DATA_ROOT}/certbot/logs -m $EMAIL_VAR -d $DOMAIN_VAR"
    }
else
  echo "SSL certificate already exists — skipping certbot."
fi

# ── Start nginx ───────────────────────────────────────────────────────────────
if [ -f "${CERT_ROOT}/live/${DOMAIN_VAR}/fullchain.pem" ]; then
  compose up -d nginx
  compose exec -T nginx nginx -s reload || true
else
  echo "Skipping nginx start because certificate is still missing at ${CERT_ROOT}/live/${DOMAIN_VAR}/fullchain.pem"
fi

echo ""
echo "============================================"
echo "  Deployment complete! Checking status..."
echo "============================================"
sleep 15
compose ps

if [ -x "${APP_DIR}/repo/infra/scripts/post_deploy_smoke.sh" ] && [ -f "${CERT_ROOT}/live/${DOMAIN_VAR}/fullchain.pem" ]; then
  echo ""
  echo "Running post-deploy smoke checks..."
  COMPOSE_FILE="${APP_DIR}/repo/infra/docker-compose.prod.yml" \
  ENV_FILE="${APP_DIR}/repo/infra/.env" \
  HTTP_BASE="https://${DOMAIN_VAR}" \
  bash "${APP_DIR}/repo/infra/scripts/post_deploy_smoke.sh"
fi

echo ""
echo "  Admin UI : https://svtms.svtrucking.biz"
echo "  API      : https://svtms.svtrucking.biz/api"
echo "  Grafana  : https://svtms.svtrucking.biz/grafana"
echo ""
echo "  Watch logs:"
echo "  docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \\"
echo "                 -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f"

REMOTE

echo ""
echo "✅ DEPLOY_TO_VPS.sh finished."
echo "   Site should be live at https://svtms.svtrucking.biz in a few minutes."
