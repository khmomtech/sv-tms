#!/usr/bin/env bash
set -euo pipefail

# Generate Angular (TypeScript) and Flutter (Dart+Dio) API clients
# from api/driver-app-openapi.json using OpenAPI Generator CLI.
#
# Prereqs: Node.js available for npx (no global install needed)
# Usage: ./scripts/generate-clients.sh

ROOT_DIR="$(cd "$(dirname "$0")/.. && pwd)"
SPEC="$ROOT_DIR/api/driver-app-openapi.json"
ANG_OUT="$ROOT_DIR/tms-frontend/src/app/generated-api"
DART_OUT="$ROOT_DIR/driver_app/lib/generated/openapi"

if [ ! -f "$SPEC" ]; then
  echo "OpenAPI spec not found at $SPEC. Run ./scripts/export-openapi.sh first." >&2
  exit 1
fi

# Ensure output directories exist
mkdir -p "$ANG_OUT" "$DART_OUT"

# Angular client (HttpClient based)
echo "Generating Angular client to $ANG_OUT ..."
npx --yes @openapitools/openapi-generator-cli generate \
  -i "$SPEC" \
  -g typescript-angular \
  -o "$ANG_OUT" \
  --additional-properties="ngVersion=17,withInterfaces=true,serviceSuffix=ApiService,providedInRoot=true,stringEnums=true"

echo "Done: Angular client generated."

# Flutter/Dart client (dio)
echo "Generating Dart (dio) client to $DART_OUT ..."
npx --yes @openapitools/openapi-generator-cli generate \
  -i "$SPEC" \
  -g dart-dio \
  -o "$DART_OUT" \
  --additional-properties="pubName=sv_tms_api,pubVersion=0.1.0,sourceFolder=lib,useEnumExtension=true,nullableFields=true,withoutJson=true"

echo "Done: Dart client generated."

echo "\nNext steps:"
echo "- Angular: import APIs from src/app/generated-api into services and use via dependency injection."
echo "- Flutter: add generated package files under lib/generated/openapi to your project and wire minimal usage."
