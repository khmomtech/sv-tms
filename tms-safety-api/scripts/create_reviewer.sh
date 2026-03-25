#!/usr/bin/env bash
# Script: create_reviewer.sh
# Usage: ./create_reviewer.sh <backend-url> <secret> <username> <password>
# Example: ./create_reviewer.sh http://localhost:8080 'mysecret' reviewer@test.sv 'a-strong-password'

set -euo pipefail
BASE_URL=${1:-http://localhost:8080}
SECRET=${2:-}
USERNAME=${3:-}
PASSWORD=${4:-}

if [[ -z "$SECRET" ]]; then
  echo "Error: missing secret. Provide the create secret as the 2nd argument."
  exit 1
fi

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
  echo "Error: missing username/password. Usage: ./create_reviewer.sh <backend-url> <secret> <username> <password>"
  exit 1
fi

echo "Calling ${BASE_URL}/api/auth/create-reviewer with username=${USERNAME}"
curl -s -X POST "${BASE_URL}/api/auth/create-reviewer" \
  -H "Content-Type: application/json" \
  -H "X-Reviewer-Create-Secret: ${SECRET}" \
  -d "{ \"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\" }" | jq '.'

echo "Done. Verify reviewer login via driver login endpoint."
