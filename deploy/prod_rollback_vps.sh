#!/usr/bin/env bash
set -euo pipefail

# VPS-side rollback script paired with prod_release_vps.sh.

BASE_DIR="/opt/sv-tms"
RELEASES_DIR=""
RELEASE_ID=""
MANIFEST=""

usage() {
  cat <<'EOF'
Usage: sudo ./deploy/prod_rollback_vps.sh [--release-id release_YYYYmmdd_HHMMSS] [--manifest /path/manifest.env] [--base-dir /opt/sv-tms]

If neither --release-id nor --manifest is given, the latest release manifest is used.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir) BASE_DIR="${2:-}"; shift 2;;
    --release-id) RELEASE_ID="${2:-}"; shift 2;;
    --manifest) MANIFEST="${2:-}"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1" >&2; usage;;
  esac
done

RELEASES_DIR="${BASE_DIR}/releases"

if [[ -z "${MANIFEST}" ]]; then
  if [[ -n "${RELEASE_ID}" ]]; then
    MANIFEST="${RELEASES_DIR}/${RELEASE_ID}/manifest.env"
  elif [[ -L "${RELEASES_DIR}/latest" ]]; then
    MANIFEST="$(readlink "${RELEASES_DIR}/latest")/manifest.env"
  else
    MANIFEST="$(ls -1dt "${RELEASES_DIR}"/release_* 2>/dev/null | head -n1)/manifest.env"
  fi
fi

if [[ -z "${MANIFEST}" || ! -f "${MANIFEST}" ]]; then
  echo "ERROR: release manifest not found." >&2
  exit 1
fi

# shellcheck disable=SC1090
. "${MANIFEST}"

required_paths=(
  "${BACKEND_BACKUP_TAR:-}"
  "${FRONTEND_BACKUP_TAR:-}"
)

for path in "${required_paths[@]}"; do
  if [[ -n "${path}" && ! -f "${path}" ]]; then
    echo "ERROR: required backup missing: ${path}" >&2
    exit 1
  fi
done

echo "Rollback manifest: ${MANIFEST}"
echo "This will restore backend, frontend, and the database backup recorded for ${RELEASE_ID:-unknown}."
read -r -p "Type ROLLBACK to continue: " confirm
if [[ "${confirm}" != "ROLLBACK" ]]; then
  echo "Cancelled."
  exit 0
fi

if [[ -n "${BACKEND_SERVICE:-}" ]]; then
  systemctl stop "${BACKEND_SERVICE}" || true
fi

if [[ -n "${DB_DUMP:-}" ]]; then
  if [[ ! -f "${DB_DUMP}" ]]; then
    echo "ERROR: database dump missing: ${DB_DUMP}" >&2
    exit 1
  fi
  if [[ -z "${DB_PASSWORD:-}" ]]; then
    echo "ERROR: DB_PASSWORD missing in manifest." >&2
    exit 1
  fi
  gunzip -c "${DB_DUMP}" | mysql \
    --host="${DB_HOST:-127.0.0.1}" \
    --port="${DB_PORT:-3306}" \
    --user="${DB_USER:-root}" \
    --password="${DB_PASSWORD}" \
    "${DB_NAME:-svlogistics_tms_db}"
fi

if [[ -n "${BACKEND_DIR:-}" && -f "${BACKEND_BACKUP_TAR:-}" ]]; then
  rm -rf "${BACKEND_DIR}"
  mkdir -p "$(dirname "${BACKEND_DIR}")"
  tar -xzf "${BACKEND_BACKUP_TAR}" -C "$(dirname "${BACKEND_DIR}")"
fi

if [[ -n "${FRONTEND_DIR:-}" && -f "${FRONTEND_BACKUP_TAR:-}" ]]; then
  rm -rf "${FRONTEND_DIR}"
  mkdir -p "$(dirname "${FRONTEND_DIR}")"
  tar -xzf "${FRONTEND_BACKUP_TAR}" -C "$(dirname "${FRONTEND_DIR}")"
fi

if [[ -n "${BACKEND_SERVICE:-}" ]]; then
  systemctl restart "${BACKEND_SERVICE}"
fi

if [[ -n "${FRONTEND_RELOAD_SERVICE:-}" ]]; then
  systemctl reload "${FRONTEND_RELOAD_SERVICE}" || systemctl restart "${FRONTEND_RELOAD_SERVICE}" || true
fi

echo "Rollback complete."
