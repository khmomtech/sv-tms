#!/usr/bin/env bash
set -euo pipefail

# Simple pre-commit: run mvn verify (without tests) and spotbugs/checkstyle quick checks
echo "Running pre-commit checks..."
./mvnw -q -DskipTests=true verify
echo "Pre-commit checks passed."
