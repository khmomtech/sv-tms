#!/usr/bin/env bash
set -euo pipefail

# Usage: ./backup_and_transfer_db.sh \
#   --vps user@host [--port 22] --ssh-key /path/to/key \
#   --db-name name --db-user user [--db-pass pass] [--remote-dir /tmp]

REMOTE_DIR=/tmp
SSH_PORT=22
DB_HOST=127.0.0.1
DB_PORT=3306

print_usage(){
  echo "Usage: $0 --vps user@host --ssh-key /path --db-name NAME --db-user USER [--db-pass PASS] [--remote-dir DIR] [--port PORT]"
  exit 1
}

if [ $# -eq 0 ]; then
  print_usage
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --vps) VPS=$2; shift 2;;
    --ssh-key) SSH_KEY=$2; shift 2;;
    --db-name) DB_NAME=$2; shift 2;;
    --db-user) DB_USER=$2; shift 2;;
    --db-pass) DB_PASS=$2; shift 2;;
    --db-host) DB_HOST=$2; shift 2;;
    --db-port) DB_PORT=$2; shift 2;;
    --remote-dir) REMOTE_DIR=$2; shift 2;;
    --port) SSH_PORT=$2; shift 2;;
    *) echo "Unknown arg: $1"; print_usage;;
  esac
done

if [ -z "${VPS:-}" ] || [ -z "${SSH_KEY:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ]; then
  print_usage
fi

STAMP=$(date +%Y%m%d-%H%M%S)
DUMP_FILE="${DB_NAME}-${STAMP}.sql.gz"

echo "Creating local dump for database $DB_NAME on ${DB_HOST}:${DB_PORT}..."
if [ -n "${DB_PASS:-}" ]; then
  /opt/homebrew/opt/mysql-client/bin/mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" --single-transaction --routines --triggers "$DB_NAME" | gzip > "$DUMP_FILE"
else
  echo "No DB password provided; mysqldump will prompt if required."
  /opt/homebrew/opt/mysql-client/bin/mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" --single-transaction --routines --triggers "$DB_NAME" | gzip > "$DUMP_FILE"
fi

echo "Dump created: $DUMP_FILE"
echo "Transferring dump to $VPS:$REMOTE_DIR ..."
scp -P "$SSH_PORT" -i "$SSH_KEY" "$DUMP_FILE" "$VPS":"$REMOTE_DIR"/

if [ $? -eq 0 ]; then
  echo "Transfer complete: $REMOTE_DIR/$DUMP_FILE on $VPS"
  echo "To import on VPS run (example):"
  echo "  ssh -i $SSH_KEY -p $SSH_PORT $VPS 'gunzip -c $REMOTE_DIR/$DUMP_FILE | mysql -u <user> -p<password> <target_db>'"
else
  echo "Transfer failed"
  exit 2
fi

echo "Local dump preserved as: $DUMP_FILE"
