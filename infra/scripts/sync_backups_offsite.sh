#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT=${1:-${BACKUP_ROOT:-/opt/sv-tms/backups}}
BACKUP_OFFSITE_TARGET=${BACKUP_OFFSITE_TARGET:-}
RCLONE_REMOTE=${RCLONE_REMOTE:-}

if [[ -z "$BACKUP_OFFSITE_TARGET" && -z "$RCLONE_REMOTE" ]]; then
  echo "Set BACKUP_OFFSITE_TARGET (rsync target) or RCLONE_REMOTE to enable off-site sync." >&2
  exit 2
fi

if [[ ! -d "$BACKUP_ROOT" ]]; then
  echo "Backup root not found: $BACKUP_ROOT" >&2
  exit 3
fi

if [[ -n "$BACKUP_OFFSITE_TARGET" ]]; then
  rsync -az --delete "$BACKUP_ROOT"/ "$BACKUP_OFFSITE_TARGET"/
fi

if [[ -n "$RCLONE_REMOTE" ]]; then
  rclone sync "$BACKUP_ROOT" "$RCLONE_REMOTE"
fi
