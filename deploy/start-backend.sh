#!/usr/bin/env bash
set -euo pipefail
# Start the backend either via docker compose or systemd
COMPOSE_FILE="/opt/sv-tms/docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
  echo "Starting backend via docker compose..."
  docker compose -f "$COMPOSE_FILE" up -d --no-build tms-backend || docker compose -f "$COMPOSE_FILE" up -d --no-build
  echo "Docker compose start requested."
else
  echo "No docker-compose file found at $COMPOSE_FILE. Trying systemd..."
  if systemctl list-units --type=service --all | grep -q tms-backend; then
    sudo systemctl start tms-backend
    sudo systemctl status tms-backend --no-pager
  else
    echo "No docker-compose or systemd service found. Start backend manually."
    exit 2
  fi
fi
