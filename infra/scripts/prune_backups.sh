#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT=${1:-${BACKUP_ROOT:-/opt/sv-tms/backups}}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-14}

mkdir -p "$BACKUP_ROOT"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$BACKUP_RETENTION_DAYS" -print -exec rm -rf {} +
