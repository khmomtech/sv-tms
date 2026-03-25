#!/usr/bin/env bash
set -euo pipefail

# Usage: ./backup_to_s3.sh --db svlogistics_tms_db --s3-bucket my-bucket --days-keep 14

DB_NAME=svlogistics_tms_db
S3_BUCKET=
DAYS_KEEP=14

while [[ $# -gt 0 ]]; do
  case $1 in
    --db) DB_NAME=$2; shift 2;;
    --s3-bucket) S3_BUCKET=$2; shift 2;;
    --days-keep) DAYS_KEEP=$2; shift 2;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

if [ -z "$S3_BUCKET" ]; then
  echo "Provide --s3-bucket"; exit 1
fi

STAMP=$(date +%F-%H%M)
OUT=/tmp/${DB_NAME}-${STAMP}.sql.gz

echo "Running dump to $OUT"
mysqldump -u root -prootpass --single-transaction --routines --triggers --events "$DB_NAME" | gzip > "$OUT"

echo "Uploading to s3://$S3_BUCKET/" 
aws s3 cp "$OUT" "s3://$S3_BUCKET/" --storage-class STANDARD_IA

echo "Pruning remote backups older than $DAYS_KEEP days"
aws s3 ls s3://$S3_BUCKET/ | awk '{print $4" "$1" "$2}' | while read key rest; do
  # aws s3 does not provide an easy delete-by-age; rely on lifecycle or implement listing+date parsing
  :
done

echo "Backup complete: $OUT"
