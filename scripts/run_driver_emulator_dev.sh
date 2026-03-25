#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/tms_driver_app"

FLAVOR="${FLAVOR:-dev}"
DEVICE="${DEVICE:-}"
API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:8080/api}"

cd "$APP_DIR"

if [[ -z "$DEVICE" ]]; then
  DEVICE="$(flutter devices 2>/dev/null | awk '/emulator-/{print $1; exit}')"
fi

if [[ -z "$DEVICE" ]]; then
  DEVICE="emulator-5554"
fi

echo "Running driver app"
echo "  Device: $DEVICE"
echo "  Flavor: $FLAVOR"
echo "  API_BASE_URL: $API_BASE_URL"
echo

flutter run -d "$DEVICE" --flavor "$FLAVOR" -t lib/main.dart --dart-define=API_BASE_URL="$API_BASE_URL"
