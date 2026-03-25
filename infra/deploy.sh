ssh "$SERVER" bash -s <<'REMOTE'
set -euo pipefail
REMOTE_DIR=/opt/sv-tms
cd $REMOTE_DIR

echo "===== CLEAN OLD SYSTEM ====="

# Stop old system services (ignore errors)
systemctl stop mysql || true
systemctl stop nginx || true
systemctl stop apache2 || true

# Disable auto-start
systemctl disable mysql || true
systemctl disable nginx || true
systemctl disable apache2 || true

# Remove old MySQL (optional but recommended)
apt purge mysql-server mysql-client mysql-common -y || true
apt autoremove -y || true
rm -rf /var/lib/mysql || true
rm -rf /etc/mysql || true

echo "===== CLEAN OLD DOCKER ====="

# Stop old containers
docker compose down -v || true

# Clean docker
docker system prune -a -f || true
docker volume prune -f || true

echo "===== INSTALL DOCKER ====="

# Install prerequisites
apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release

# Install Docker if not exists
if ! command -v docker >/dev/null 2>&1; then
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
fi

echo "===== FIREWALL ====="

# Firewall
if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH
  ufw allow 'Nginx Full' || true
  ufw --force enable
fi

echo "===== DEPLOY SYSTEM ====="

# Ensure compose file exists
if [[ ! -f infra/docker-compose.prod.yml ]]; then
  echo "infra/docker-compose.prod.yml not found"
  exit 1
fi

# Deploy
docker compose --env-file infra/.env -f infra/docker-compose.prod.yml up -d --build --remove-orphans

echo "===== DONE ====="
REMOTE