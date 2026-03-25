#!/usr/bin/env bash
set -euo pipefail

# SVTMS production backup script (VPS)
# - Backs up: MySQL database, backend folder, safety frontend folder
# - Optional: uploads (both /opt/sv-tms/uploads and /opt/sv-tms/backend/uploads)
#
# Usage:
#   sudo ./deploy/prod_backup_vps.sh
#   sudo ./deploy/prod_backup_vps.sh --with-uploads
#   sudo ./deploy/prod_backup_vps.sh --keep-days 14
#
# Output:
#   /opt/sv-tms/backups/svtms_backup_YYYYmmdd_HHMMSS/

WITH_UPLOADS=false
KEEP_DAYS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-uploads) WITH_UPLOADS=true; shift;;
    --keep-days) KEEP_DAYS="${2:-}"; shift 2;;
    -h|--help)
      sed -n '1,60p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

BASE_DIR="/opt/sv-tms"
BACKUPS_ROOT="${BASE_DIR}/backups"
BACKEND_DIR="${BASE_DIR}/backend"
SAFETY_DIR="${BASE_DIR}/safety-frontend"
UPLOADS_DIR="${BASE_DIR}/uploads"
BACKEND_UPLOADS_DIR="${BACKEND_DIR}/uploads"
APP_PROPS="${BACKEND_DIR}/application.properties"

TS="$(date +%Y%m%d_%H%M%S)"
BKDIR="${BACKUPS_ROOT}/svtms_backup_${TS}"

mkdir -p "${BKDIR}"

read_prop(){
  local key="$1"
  if [[ -f "${APP_PROPS}" ]]; then
    # Trim CRLF and whitespace; take last matching key in file.
    awk -F= -v k="$key" '
      $0 ~ "^\r?$" { next }
      $1==k { v=$2 }
      END{
        gsub(/\r/,"",v);
        sub(/^[ \t]+/,"",v); sub(/[ \t]+$/,"",v);
        print v
      }' "${APP_PROPS}"
  fi
}

DB_URL="$(read_prop 'spring.datasource.url' || true)"
DB_USER="$(read_prop 'spring.datasource.username' || true)"
DB_PASS="$(read_prop 'spring.datasource.password' || true)"

# Best-effort extraction of DB name from JDBC URL.
# Example: jdbc:mysql://localhost:3306/svlogistics_tms_db?useSSL=false
DB_NAME=""
if [[ -n "${DB_URL}" ]]; then
  CANDIDATE="$(printf '%s' "${DB_URL}" | sed -E 's|^jdbc:mysql://[^/]+/([^?]+).*|\1|' || true)"
  if [[ -n "${CANDIDATE}" && "${CANDIDATE}" != "${DB_URL}" && "${CANDIDATE}" != "\\1" ]]; then
    DB_NAME="${CANDIDATE}"
  fi
fi
DB_NAME="${DB_NAME:-svlogistics_tms_db}"
DB_USER="${DB_USER:-root}"

echo "Backup dir: ${BKDIR}"
echo "DB: ${DB_NAME} (user=${DB_USER})"
echo "Backend: ${BACKEND_DIR}"
echo "Safety: ${SAFETY_DIR}"
echo "With uploads: ${WITH_UPLOADS}"

if ! command -v mysqldump >/dev/null 2>&1; then
  echo "ERROR: mysqldump not found on server." >&2
  exit 1
fi

# 1) DB backup
DB_DUMP_GZ="db_${DB_NAME}_${TS}.sql.gz"
if [[ -n "${DB_PASS}" ]]; then
  mysqldump --single-transaction --routines --triggers --events \
    -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" | gzip -1 > "${BKDIR}/${DB_DUMP_GZ}"
else
  # If password is empty, mysqldump may prompt; that's not cron-friendly.
  echo "ERROR: spring.datasource.password not found in ${APP_PROPS}. Aborting (cron-safe)." >&2
  exit 1
fi

# 2) Backend backup (exclude volatile logs)
tar --exclude="backend/logs/*" -czf "${BKDIR}/backend_${TS}.tar.gz" -C "${BASE_DIR}" "backend"

# 3) Safety frontend backup
tar -czf "${BKDIR}/safety_frontend_${TS}.tar.gz" -C "${BASE_DIR}" "safety-frontend"

# 4) Optional uploads backup
if ${WITH_UPLOADS}; then
  # If a path doesn't exist, tar will fail; guard with checks.
  TAR_INPUTS=()
  [[ -d "${UPLOADS_DIR}" ]] && TAR_INPUTS+=("uploads")
  [[ -d "${BACKEND_UPLOADS_DIR}" ]] && TAR_INPUTS+=("backend/uploads")
  if [[ ${#TAR_INPUTS[@]} -gt 0 ]]; then
    tar -czf "${BKDIR}/uploads_${TS}.tar.gz" -C "${BASE_DIR}" "${TAR_INPUTS[@]}"
  else
    echo "WARN: uploads directories not found; skipping uploads archive."
  fi
fi

# 5) Checksums (relative filenames)
(
  cd "${BKDIR}"
  # shellcheck disable=SC2046
  sha256sum $(ls -1 *.tar.gz *.sql.gz 2>/dev/null) > "SHA256SUMS.txt"
)

# 6) Restore helper (uses same mysql creds from application.properties)
cat > "${BKDIR}/RESTORE.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/opt/sv-tms"
BKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PROPS="${BASE_DIR}/backend/application.properties"

read_prop(){
  local key="$1"
  awk -F= -v k="$key" '$1==k { v=$2 } END{ gsub(/\r/,"",v); sub(/^[ \t]+/,"",v); sub(/[ \t]+$/,"",v); print v }' "${APP_PROPS}"
}

DB_URL="$(read_prop 'spring.datasource.url' || true)"
DB_USER="$(read_prop 'spring.datasource.username' || true)"
DB_PASS="$(read_prop 'spring.datasource.password' || true)"

DB_NAME="svlogistics_tms_db"
if [[ -n "${DB_URL}" ]]; then
  CANDIDATE="$(printf '%s' "${DB_URL}" | sed -E 's|^jdbc:mysql://[^/]+/([^?]+).*|\1|' || true)"
  if [[ -n "${CANDIDATE}" && "${CANDIDATE}" != "${DB_URL}" && "${CANDIDATE}" != "\\1" ]]; then
    DB_NAME="${CANDIDATE}"
  fi
fi
DB_USER="${DB_USER:-root}"

echo "Restoring from: ${BKDIR}"
cd "${BKDIR}"

sha256sum -c SHA256SUMS.txt

DB_GZ="$(ls -1 db_*.sql.gz | head -n1)"
BACKEND_TAR="$(ls -1 backend_*.tar.gz | head -n1)"
SAFETY_TAR="$(ls -1 safety_frontend_*.tar.gz | head -n1)"

echo "DB file: ${DB_GZ}"
echo "Backend file: ${BACKEND_TAR}"
echo "Safety file: ${SAFETY_TAR}"

echo "WARNING: This will overwrite live DB + folders under ${BASE_DIR}."
read -r -p "Type RESTORE to continue: " CONFIRM
if [[ "${CONFIRM}" != "RESTORE" ]]; then
  echo "Cancelled."
  exit 0
fi

gunzip -c "${DB_GZ}" | mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"
tar -xzf "${BACKEND_TAR}" -C "${BASE_DIR}"
tar -xzf "${SAFETY_TAR}" -C "${BASE_DIR}"

if systemctl list-units --type=service --all | grep -q '^svtms-backend\\.service'; then
  systemctl restart svtms-backend
fi

if systemctl list-units --type=service --all | grep -q '^nginx\\.service'; then
  systemctl reload nginx || systemctl restart nginx
fi

echo "Restore complete."
EOF
chmod +x "${BKDIR}/RESTORE.sh"

if [[ -n "${KEEP_DAYS}" ]]; then
  if [[ "${KEEP_DAYS}" =~ ^[0-9]+$ ]]; then
    echo "Retention: deleting svtms_backup_* older than ${KEEP_DAYS} days in ${BACKUPS_ROOT}"
    find "${BACKUPS_ROOT}" -maxdepth 1 -type d -name 'svtms_backup_*' -mtime +"${KEEP_DAYS}" -print -exec rm -rf {} \;
  else
    echo "WARN: --keep-days must be an integer; got '${KEEP_DAYS}', skipping retention."
  fi
fi

echo "OK: ${BKDIR}"
