#!/usr/bin/env bash
set -euo pipefail

# run_full_debug.sh
# Convenience script to run driver creation, tail backend logs, and launch Flutter web.
# Usage: API_BASE=http://localhost:8080/api ./scripts/run_full_debug.sh

API_BASE=${API_BASE:-http://localhost:8080/api}
SCRIPT_DIR=$(dirname "$0")

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required (brew install jq)" >&2; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "flutter is required" >&2; exit 1; }

echo "API base: $API_BASE"

echo "1) Ensure backend is running (docker compose)..."
docker compose -f docker-compose.dev.yml ps

echo "2) (Optional) Start Angular dev server in a separate terminal if you need the web admin UI."
echo "   cd tms-frontend && npm ci --legacy-peer-deps && npm run start -- --host 0.0.0.0 --port 4201"

echo "3) Create test driver (admin -> create driver -> verify)"
chmod +x "$SCRIPT_DIR/create_test_driver.sh"
API_BASE="$API_BASE" "$SCRIPT_DIR/create_test_driver.sh"

echo "4) Tailing backend logs (will run in background)"
docker compose -f docker-compose.dev.yml logs -f backend &
TAIL_PID=$!

echo "5) Launching Flutter web (Chrome). Close this process to stop tailing logs." 
echo "   If you prefer iOS simulator, run the flutter ios command manually instead."

pushd driver_app >/dev/null
flutter clean || true
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL="$API_BASE"
popd >/dev/null

echo "Flutter exited, stopping backend log tail (pid=$TAIL_PID)"
kill $TAIL_PID 2>/dev/null || true

echo "Done."
