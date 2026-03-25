#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run_import.sh <import_id> <sqlfile> [created_by]
IMPORT_ID=${1:-import_$(date +%Y%m%d_%H%M%S)}
SQLFILE=${2:-}
CREATED_BY=${3:-automation}
BASE_URL=${BASE_URL:-http://localhost:8080}

if [ -z "$SQLFILE" ]; then
  echo "Usage: $0 <import_id> <sqlfile> [created_by]"
  exit 2
fi

echo "Starting import $IMPORT_ID from $SQLFILE"
curl -s -X POST -H "Content-Type: application/json" -d "{\"importId\": \"$IMPORT_ID\", \"sourceFile\": \"$SQLFILE\", \"rowCount\": 0, \"createdBy\": \"$CREATED_BY\"}" "$BASE_URL/api/admin/imports/start" | jq .

echo "Running pre-import validator"
python3 scripts/pre_import_validator.py "$SQLFILE" || { echo "Validator failed; aborting"; exit 1; }

echo "Applying SQL file to DB (ensure DB env vars set)"
mysql -u ${DB_USER:-driver} -p${DB_PASS:-driverpass} ${DB_NAME:-driverapp} < "$SQLFILE"

echo "Finishing import"
curl -s -X POST -H "Content-Type: application/json" -d "{\"importId\": \"$IMPORT_ID\", \"status\": \"DONE\", \"notes\": \"Imported via run_import.sh\"}" "$BASE_URL/api/admin/imports/finish" | jq .

echo "Import $IMPORT_ID completed"
