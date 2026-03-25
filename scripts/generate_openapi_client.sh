#!/usr/bin/env bash
set -euo pipefail

# Script to generate a Dart OpenAPI client using the OpenAPI Generator CLI jar.
# Usage:
#   ./scripts/generate_openapi_client.sh
# Requirements: Java 11+ installed and internet access to download the CLI jar.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI_JSON="$ROOT_DIR/api/driver-app-openapi.json"
OUT_DIR="$ROOT_DIR/tms_customer_app/lib/api/generated_openapi"
JAR_DIR="$HOME/.openapi-generator-cli"
JAR="$JAR_DIR/openapi-generator-cli.jar"

# Optional override: set API_DOCS_URL to fetch OpenAPI from running backend
# e.g. API_DOCS_URL=http://localhost:8080/v3/api-docs ./scripts/generate_openapi_client.sh
API_DOCS_URL="${API_DOCS_URL:-http://localhost:8080/v3/api-docs}"

# If set to 1, pass --skip-validate-spec to the generator
SKIP_VALIDATE_SPEC="${SKIP_VALIDATE_SPEC:-0}"

mkdir -p "$JAR_DIR"
mkdir -p "$OUT_DIR"

if [ ! -f "$OPENAPI_JSON" ] || [ ! -s "$OPENAPI_JSON" ]; then
  echo "OpenAPI file missing or empty: $OPENAPI_JSON"
  echo "Attempting to fetch OpenAPI from $API_DOCS_URL ..."
  if curl -fsS "$API_DOCS_URL" -o "$OPENAPI_JSON"; then
    echo "Saved OpenAPI to $OPENAPI_JSON"
  else
    echo "Failed to fetch OpenAPI from $API_DOCS_URL"
    echo "Please run the backend and expose /v3/api-docs or provide a valid file at $OPENAPI_JSON"
    exit 1
  fi
fi

# Basic sanity check: ensure the JSON contains key fields
if ! grep -q -E '"openapi"|"swagger"|"paths"' "$OPENAPI_JSON" 2>/dev/null; then
  echo "The OpenAPI file at $OPENAPI_JSON does not look valid (missing openapi/info/paths)."
  echo "You can set SKIP_VALIDATE_SPEC=1 to bypass validation (not recommended):"
  echo "  SKIP_VALIDATE_SPEC=1 ./scripts/generate_openapi_client.sh"
  exit 1
fi

if [ ! -f "$JAR" ]; then
  echo "Downloading openapi-generator-cli.jar to $JAR..."
  curl -sSL "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/6.6.0/openapi-generator-cli-6.6.0.jar" -o "$JAR"
fi

echo "Generating Dart client into $OUT_DIR"
if [ "$SKIP_VALIDATE_SPEC" = "1" ]; then
  java -jar "$JAR" generate -i "$OPENAPI_JSON" -g dart -o "$OUT_DIR" --skip-validate-spec
else
  java -jar "$JAR" generate -i "$OPENAPI_JSON" -g dart -o "$OUT_DIR"
fi

echo "Done. Generated client at $OUT_DIR"
