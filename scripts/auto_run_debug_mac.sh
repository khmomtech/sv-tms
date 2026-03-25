#!/usr/bin/env bash
set -euo pipefail

# auto_run_debug_mac.sh
# macOS helper that opens Terminal tabs to run the full debug workflow:
#  - Start docker compose (background)
#  - Tail backend logs
#  - Start Angular dev server
#  - Run create_test_driver script
#  - Launch Flutter web (Chrome)
#
# Usage:
#   chmod +x scripts/auto_run_debug_mac.sh
#   API_BASE=http://localhost:8080/api ./scripts/auto_run_debug_mac.sh

API_BASE=${API_BASE:-http://localhost:8080/api}
WORKDIR="$(cd "$(dirname "$0")/.." && pwd)"

command -v osascript >/dev/null 2>&1 || { echo "osascript (AppleScript) is required on macOS" >&2; exit 1; }

echo "Preparing to open Terminal tabs and start the dev workflow in: $WORKDIR"
echo "API_BASE=$API_BASE"

echo "About to open Terminal tabs and run: docker-compose, backend logs, angular, create driver, flutter." 
read -r -p "Proceed? (y/N): " confirm
if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
    echo "Aborted by user."; exit 0
fi

# Allow using iTerm instead of Terminal by exporting USE_ITERM=yes
APP_NAME="Terminal"
if [[ "${USE_ITERM:-}" == "yes" ]]; then
    APP_NAME="iTerm"
fi

osascript <<EOF
tell application "${APP_NAME}"
        activate
        -- Tab 1: start docker-compose services (detached)
        do script "cd '$WORKDIR' && docker compose -f docker-compose.dev.yml up --build -d; echo 'docker compose started'"
        delay 1
        -- Tab 2: tail backend logs
        do script "cd '$WORKDIR' && docker compose -f docker-compose.dev.yml logs -f backend"
        delay 0.5
        -- Tab 3: start Angular dev server
        do script "cd '$WORKDIR/tms-frontend' && npm ci --legacy-peer-deps && npm run start -- --host 0.0.0.0 --port 4201"
        delay 0.5
        -- Tab 4: run create_test_driver script
        do script "cd '$WORKDIR' && chmod +x scripts/create_test_driver.sh && API_BASE=$API_BASE scripts/create_test_driver.sh; echo 'create_test_driver finished'"
        delay 0.5
        -- Tab 5: launch Flutter web
        do script "cd '$WORKDIR/driver_app' && flutter clean || true && flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=\"$API_BASE\""
end tell
EOF

echo "Started Terminal tabs. Check ${APP_NAME} for progress."
