chmod +x /Users/sotheakh/Documents/develop/sv-tms/infra/quick_deploy.sh || true
#!/usr/bin/env bash
set -euo pipefail

# infra/quick_deploy.sh
# Usage: ./infra/quick_deploy.sh root@207.180.245.156
# Builds the backend jar locally, copies it to the server, and restarts the systemd service.

SERVER=${1:-}
if [ -z "$SERVER" ]; then
  echo "Usage: $0 user@host"
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAR_GLOB="$REPO_ROOT/tms-backend/target/*.jar"
REMOTE_RELEASES="/opt/sv-tms/releases"
REMOTE_INFRA="/opt/sv-tms/infra"

echo "Building backend jar..."
cd "$REPO_ROOT/tms-backend"
if [ -x ./mvnw ]; then
  ./mvnw clean package -DskipTests
else
  mvn clean package -DskipTests
fi

echo "Copying jar and env to ${SERVER}..."
scp $JAR_GLOB "${SERVER}:${REMOTE_RELEASES}/app.jar"
if [ -f "$REPO_ROOT/infra/backend.env" ]; then
  scp "$REPO_ROOT/infra/backend.env" "${SERVER}:${REMOTE_INFRA}/backend.env"
else
  echo "Warning: infra/backend.env not found locally; ensure server has correct env file." >&2
fi

echo "Reloading and restarting service on ${SERVER}"
ssh "$SERVER" 'sudo systemctl daemon-reload && sudo systemctl restart sv-tms-backend && sudo journalctl -u sv-tms-backend -n 200 --no-hostname --no-pager'

echo "Done. Check logs above; to follow live logs: ssh ${SERVER} 'sudo journalctl -u sv-tms-backend -f'"
