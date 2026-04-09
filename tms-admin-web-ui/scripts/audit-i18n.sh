#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Scanning for likely untranslated UI literals in templates..."
rg -n --glob 'src/app/**/*.html' '>[^<{]*[A-Za-z][^<{]*<|placeholder="[A-Za-z]|title="[A-Za-z]|aria-label="[A-Za-z]' src/app \
  | rg -v "\\| translate|\\{\\{ '\\w|\\[placeholder\\]=|\\[title\\]=|\\[attr\\.aria-label\\]=" || true

echo
echo "Scanning for likely user-facing hardcoded strings in component code..."
rg -n --glob 'src/app/**/*.ts' "errorMessage\\s*=\\s*'[^']*[A-Za-z][^']*'|error\\s*=\\s*'[^']*[A-Za-z][^']*'|successMessage\\s*=\\s*'[^']*[A-Za-z][^']*'|warningMessage\\s*=\\s*'[^']*[A-Za-z][^']*'" src/app || true
