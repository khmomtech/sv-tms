#!/usr/bin/env bash
# Simple smoke test runner for local/manual testing.
# Usage:
#   ./scripts/smoke_test.sh https://test-api.example.com "testuser" "P@ssw0rd" "device-id-if-needed"
# This will start the app on the default connected device/emulator with the
# provided API_BASE_URL and print next steps. It does NOT automate UI input.

set -euo pipefail
API_URL=${1:-}
TEST_USER=${2:-}
TEST_PASS=${3:-}
DEVICE=${4:-}

if [ -z "$API_URL" ]; then
  echo "Usage: $0 <API_BASE_URL> <TEST_USERNAME> <TEST_PASSWORD> [device-id]"
  exit 2
fi

echo "Starting smoke test with API_BASE_URL=$API_URL"

# Make sure dependencies are installed
flutter pub get

# Launch app with runtime override. Use provided device if set.
if [ -n "$DEVICE" ]; then
  flutter run -d "$DEVICE" --dart-define=API_BASE_URL="$API_URL"
else
  flutter run --dart-define=API_BASE_URL="$API_URL"
fi

# After launch, follow these manual steps:
# 1. Accept consent (Essential required). Disable Marketing if prompted.
# 2. Tap "Create Account" and register with Test credentials or use existing.
# 3. Return to Login and sign in with that account.
# 4. Verify you reach the dashboard and no device-approval blocking occurs.

echo "Smoke test launcher finished. Perform manual UI checks as described above."