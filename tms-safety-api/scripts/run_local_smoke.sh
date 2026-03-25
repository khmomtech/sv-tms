#!/usr/bin/env bash
# Run local smoke checks and formatting hints
# Usage: ./run_local_smoke.sh <backend_base_url> <reviewer_user> <reviewer_pass>
set -euo pipefail
BASE=${1:-http://localhost:8080}
USER=${2:-reviewer@test.sv}
PASS=${3:-Review!234}

echo "Checking Flutter format (if flutter available)"
if command -v flutter >/dev/null 2>&1; then
  echo "Running flutter format (dry run)"
  (cd driver_app && flutter format --set-exit-if-changed .) || true
else
  echo "Flutter CLI not found in PATH. Skipping format. Run 'flutter format .' locally." >&2
fi

echo "Running backend smoke_check.sh against $BASE"
if [[ -x ./tms-backend/scripts/smoke_check.sh ]]; then
  ./tms-backend/scripts/smoke_check.sh "$BASE" "$USER" "$PASS"
else
  echo "smoke_check.sh missing or not executable. Ensure tms-backend/scripts/smoke_check.sh exists." >&2
  exit 2
fi
