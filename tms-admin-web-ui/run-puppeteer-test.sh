#!/usr/bin/env bash
set -euo pipefail

# Force download of a stable Chrome binary via Puppeteer (idempotent if already present)
# Ensure correct platform (arm64 vs x64) inside Docker on Apple Silicon
ARCH=$(uname -m)
PLATFORM="linux"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  PLATFORM="linux-arm64"
fi
npx puppeteer browsers install chrome@stable --platform=${PLATFORM} || echo "Puppeteer browser install attempt finished"

# Resolve executable path by scanning install directory (workaround for executablePath mismatch)
PUP_PATH=$(ls -d /root/.cache/puppeteer/chrome/${PLATFORM#linux-}*/chrome-linux*/chrome 2>/dev/null | head -n1 || true)
if [ -z "$PUP_PATH" ]; then
  echo "Failed to locate installed Puppeteer Chrome binary" >&2
  find /root/.cache/puppeteer -maxdepth 5 -type f -name chrome 2>/dev/null || true
  exit 1
fi
echo "Using Chrome binary: $PUP_PATH"
export CHROME_BIN="$PUP_PATH"

# Run tests
npm test -- --watch=false
