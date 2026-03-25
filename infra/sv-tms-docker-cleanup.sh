#!/bin/bash
# sv-tms-docker-cleanup.sh
# Safely clean up Docker containers and volumes before starting the dev stack
# Usage: ./sv-tms-docker-cleanup.sh

set -e

echo "[sv-tms] Stopping and removing all containers in this project..."
docker compose down || true

echo "[sv-tms] Pruning unused containers..."
docker container prune -f || true

echo "[sv-tms] Pruning unused volumes (optional, comment out if you want to keep data)..."
# docker volume prune -f || true

echo "[sv-tms] Cleanup complete. You can now run:"
echo "  docker compose -f docker-compose.dev.yml up -d --build"
#!/bin/bash
# infra/sv-tms-docker-cleanup.sh
# Safely clean up Docker containers and volumes before starting the dev stack
# Usage: ./infra/sv-tms-docker-cleanup.sh

set -e

echo "[sv-tms] Stopping and removing all containers in this project..."
docker compose down || true

echo "[sv-tms] Pruning unused containers..."
docker container prune -f || true

echo "[sv-tms] Pruning unused volumes (optional, comment out if you want to keep data)..."
# docker volume prune -f || true

echo "[sv-tms] Cleanup complete. You can now run:"
echo "  docker compose -f docker-compose.dev.yml up -d --build"
