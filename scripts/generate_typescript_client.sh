#!/usr/bin/env bash
set -euo pipefail

# Generate a TypeScript Angular client using OpenAPI Generator CLI
# Usage: API_DOCS_URL or ensure api/driver-app-openapi.json exists

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI_JSON="$ROOT_DIR/api/driver-app-openapi.json"
OUT_DIR="$ROOT_DIR/tms-frontend/src/app/api/generated_openapi"
JAR_DIR="$HOME/.openapi-generator-cli"
JAR="$JAR_DIR/openapi-generator-cli.jar"

API_DOCS_URL="${API_DOCS_URL:-http://localhost:8080/v3/api-docs}"

mkdir -p "$JAR_DIR"
mkdir -p "$OUT_DIR"

if [ ! -f "$OPENAPI_JSON" ] || [ ! -s "$OPENAPI_JSON" ]; then
  echo "OpenAPI file missing or empty: $OPENAPI_JSON"
  echo "Attempting to fetch OpenAPI from $API_DOCS_URL ..."
  if curl -fsS "$API_DOCS_URL" -o "$OPENAPI_JSON"; then
    echo "Saved OpenAPI to $OPENAPI_JSON"
  else
    echo "Failed to fetch OpenAPI from $API_DOCS_URL"
    exit 1
  fi
fi

if ! grep -q -E '"openapi"|"swagger"|"paths"' "$OPENAPI_JSON" 2>/dev/null; then
  echo "The OpenAPI file at $OPENAPI_JSON does not look valid."
  exit 1
fi

if [ ! -f "$JAR" ]; then
  echo "Downloading openapi-generator-cli.jar to $JAR..."
  curl -sSL "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/6.6.0/openapi-generator-cli-6.6.0.jar" -o "$JAR"
fi

echo "Generating TypeScript Angular client into $OUT_DIR"
java -jar "$JAR" generate -i "$OPENAPI_JSON" -g typescript-angular -o "$OUT_DIR" \
  --additional-properties=npmName=@sv/logistics-api,npmVersion=1.0.0

echo "Done. Generated client at $OUT_DIR"
