#!/usr/bin/env bash
set -euo pipefail
# Copy local example nginx config to server locations and reload nginx
LOCAL_CONF_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_CONF="$LOCAL_CONF_DIR/nginx-ws-sockjs.conf"
if [ ! -f "$SRC_CONF" ]; then
  echo "Missing local nginx config: $SRC_CONF"
  exit 1
fi
echo "Installing nginx config..."
sudo cp "$SRC_CONF" /etc/nginx/sites-available/svtms-ws.conf
sudo ln -sf /etc/nginx/sites-available/svtms-ws.conf /etc/nginx/sites-enabled/svtms-ws.conf
echo "Testing nginx config..."
sudo nginx -t
echo "Reloading nginx..."
sudo systemctl reload nginx
echo "nginx reloaded."
