#!/usr/bin/env bash
set -euo pipefail

# Install daily cron job on VPS to run SVTMS backups locally.
# Usage (run locally, requires SSH access):
#   SSHPASS='...' sshpass -e ssh root@HOST "bash -s" < deploy/prod_install_backup_cron_vps.sh
#
# Or run directly on the VPS:
#   sudo bash deploy/prod_install_backup_cron_vps.sh
#
# What it does:
# - Writes /opt/sv-tms/backup/svtms_backup.sh
# - Installs /etc/cron.d/svtms-backup (daily 02:15)
# - Keeps 14 days of backups by default

KEEP_DAYS="${KEEP_DAYS:-14}"
CRON_TIME="${CRON_TIME:-15 2 * * *}" # min hour dom mon dow

BASE_DIR="/opt/sv-tms"
SCRIPT_DIR="${BASE_DIR}/backup"
LOG_DIR="${BASE_DIR}/logs"

mkdir -p "${SCRIPT_DIR}" "${LOG_DIR}"

cat > "${SCRIPT_DIR}/svtms_backup.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

KEEP_DAYS="${KEEP_DAYS:-14}"

BASE_DIR="/opt/sv-tms"
REPO_SCRIPT="${BASE_DIR}/prod_backup_vps.sh"
LOCAL_SCRIPT="${BASE_DIR}/backup/prod_backup_vps.sh"

if [[ -x "${LOCAL_SCRIPT}" ]]; then
  exec "${LOCAL_SCRIPT}" --keep-days "${KEEP_DAYS}"
elif [[ -x "${REPO_SCRIPT}" ]]; then
  exec "${REPO_SCRIPT}" --keep-days "${KEEP_DAYS}"
else
  echo "ERROR: backup script not found at ${LOCAL_SCRIPT} or ${REPO_SCRIPT}" >&2
  exit 1
fi
EOF
chmod +x "${SCRIPT_DIR}/svtms_backup.sh"

# Place the actual implementation next to it (single source of truth on VPS).
cat > "${SCRIPT_DIR}/prod_backup_vps.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WITH_UPLOADS=false
KEEP_DAYS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-uploads) WITH_UPLOADS=true; shift;;
    --keep-days) KEEP_DAYS="${2:-}"; shift 2;;
    -h|--help) sed -n '1,60p' "$0"; exit 0;;
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
    awk -F= -v k="$key" '
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

if ! command -v mysqldump >/dev/null 2>&1; then
  echo "ERROR: mysqldump not found on server." >&2
  exit 1
fi

DB_DUMP_GZ="db_${DB_NAME}_${TS}.sql.gz"
if [[ -n "${DB_PASS}" ]]; then
  mysqldump --single-transaction --routines --triggers --events \
    -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" | gzip -1 > "${BKDIR}/${DB_DUMP_GZ}"
else
  echo "ERROR: spring.datasource.password not found in ${APP_PROPS}. Aborting (cron-safe)." >&2
  exit 1
fi

tar --exclude="backend/logs/*" -czf "${BKDIR}/backend_${TS}.tar.gz" -C "${BASE_DIR}" "backend"
tar -czf "${BKDIR}/safety_frontend_${TS}.tar.gz" -C "${BASE_DIR}" "safety-frontend"

if ${WITH_UPLOADS}; then
  TAR_INPUTS=()
  [[ -d "${UPLOADS_DIR}" ]] && TAR_INPUTS+=("uploads")
  [[ -d "${BACKEND_UPLOADS_DIR}" ]] && TAR_INPUTS+=("backend/uploads")
  if [[ ${#TAR_INPUTS[@]} -gt 0 ]]; then
    tar -czf "${BKDIR}/uploads_${TS}.tar.gz" -C "${BASE_DIR}" "${TAR_INPUTS[@]}"
  fi
fi

(
  cd "${BKDIR}"
  sha256sum *.tar.gz *.sql.gz > "SHA256SUMS.txt"
)

cat > "${BKDIR}/RESTORE.sh" <<'EOS'
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

cd "${BKDIR}"
sha256sum -c SHA256SUMS.txt

DB_GZ="$(ls -1 db_*.sql.gz | head -n1)"
BACKEND_TAR="$(ls -1 backend_*.tar.gz | head -n1)"
SAFETY_TAR="$(ls -1 safety_frontend_*.tar.gz | head -n1)"

echo "WARNING: overwrite live DB + folders under ${BASE_DIR}"
read -r -p "Type RESTORE to continue: " CONFIRM
[[ "${CONFIRM}" == "RESTORE" ]] || exit 0

gunzip -c "${DB_GZ}" | mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"
tar -xzf "${BACKEND_TAR}" -C "${BASE_DIR}"
tar -xzf "${SAFETY_TAR}" -C "${BASE_DIR}"

systemctl restart svtms-backend || true
systemctl reload nginx || systemctl restart nginx || true
echo "Restore complete."
EOS
chmod +x "${BKDIR}/RESTORE.sh"

if [[ -n "${KEEP_DAYS}" && "${KEEP_DAYS}" =~ ^[0-9]+$ ]]; then
  find "${BACKUPS_ROOT}" -maxdepth 1 -type d -name 'svtms_backup_*' -mtime +"${KEEP_DAYS}" -exec rm -rf {} \;
fi

# Best-effort: set ownership so svtms can read backups
if id svtms >/dev/null 2>&1; then
  chown -R svtms:svtms "${BKDIR}" || true
fi
EOF
chmod +x "${SCRIPT_DIR}/prod_backup_vps.sh"

# Install cron.d entry (root)
CRON_FILE="/etc/cron.d/svtms-backup"
cat > "${CRON_FILE}" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# SVTMS backup (daily). Logs to /opt/sv-tms/logs/backup.log
${CRON_TIME} root KEEP_DAYS=${KEEP_DAYS} flock -n /var/lock/svtms-backup.lock /opt/sv-tms/backup/svtms_backup.sh >>/opt/sv-tms/logs/backup.log 2>&1
EOF

chmod 644 "${CRON_FILE}"

echo "Installed:"
echo "- ${SCRIPT_DIR}/svtms_backup.sh"
echo "- ${SCRIPT_DIR}/prod_backup_vps.sh"
echo "- ${CRON_FILE} (${CRON_TIME}, KEEP_DAYS=${KEEP_DAYS})"
