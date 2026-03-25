#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR=${1:-}
BACKUP_ROOT=${BACKUP_ROOT:-/opt/sv-tms/backups}

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)
fi

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
  echo "Backup directory not found" >&2
  exit 2
fi

MANIFEST="$BACKUP_DIR/manifest.txt"
if [[ ! -f "$MANIFEST" ]]; then
  echo "manifest.txt missing in $BACKUP_DIR" >&2
  exit 3
fi

declare -A values
while IFS='=' read -r key value; do
  [[ -z "${key:-}" ]] && continue
  values[$key]=$value
done < "$MANIFEST"

check_file() {
  local rel=$1
  local expected=$2
  local full="$BACKUP_DIR/$rel"
  [[ -f "$full" ]] || { echo "Missing $rel" >&2; exit 4; }
  local actual
  actual=$(sha256sum "$full" | awk '{print $1}')
  [[ "$actual" == "$expected" ]] || { echo "Checksum mismatch for $rel" >&2; exit 5; }
  echo "OK $rel"
}

check_file "${values[mysql_file]}" "${values[mysql_sha256]}"
check_file "${values[postgres_file]}" "${values[postgres_sha256]}"
check_file "${values[mongo_archive]}" "${values[mongo_sha256]}"
check_file "${values[uploads_file]}" "${values[uploads_sha256]}"
check_file "${values[telematics_spool_file]}" "${values[telematics_spool_sha256]}"
check_file "${values[message_api_file]}" "${values[message_api_sha256]}"
check_file "${values[redis_file]}" "${values[redis_sha256]}"
