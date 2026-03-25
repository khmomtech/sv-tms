#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/tms_driver_app"

FLAVOR="${FLAVOR:-dev}"
DEVICE="${DEVICE:-}"

if [[ -z "${API_BASE_URL:-}" ]]; then
  if [[ -n "${MAC_IP:-}" ]]; then
    API_BASE_URL="http://${MAC_IP}:8080/api"
  else
    IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
    if [[ -z "$IP" ]]; then
      IP="$(ipconfig getifaddr en1 2>/dev/null || true)"
    fi
    if [[ -z "$IP" ]]; then
      IP="192.168.1.10"
    fi
    API_BASE_URL="http://$IP:8080/api"
  fi
fi

cd "$APP_DIR"

if [[ -z "$DEVICE" ]]; then
  DEVICE="$(flutter devices 2>/dev/null | awk '/android/{print $1; exit}')"
fi

if [[ -z "$DEVICE" ]]; then
  echo "No Android device detected. Make sure USB debugging is enabled and adb sees the device."
  exit 1
fi

echo "Running driver app (physical device)"
echo "  Device: $DEVICE"
echo "  Flavor: $FLAVOR"
echo "  API_BASE_URL: $API_BASE_URL"
echo

flutter run -d "$DEVICE" --flavor "$FLAVOR" -t lib/main.dart --dart-define=API_BASE_URL="$API_BASE_URL"
