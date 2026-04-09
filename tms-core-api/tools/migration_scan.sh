#!/usr/bin/env bash
set -euo pipefail

DUMP_PATH=${1:-}
OUT_PATH=${2:-driver-app/tmp/sv_dump_summary_ci.txt}

mkdir -p "$(dirname "$OUT_PATH")"

if [ -z "$DUMP_PATH" ] || [ ! -f "$DUMP_PATH" ]; then
  echo "Dump file not found: $DUMP_PATH" >&2
  echo "FILE: $DUMP_PATH" > "$OUT_PATH"
  echo "ERROR: dump missing" >> "$OUT_PATH"
  exit 1
fi

f="$DUMP_PATH"
echo "FILE: $f" > "$OUT_PATH"
wc -c "$f" >> "$OUT_PATH" 2>/dev/null || true
wc -l "$f" >> "$OUT_PATH" 2>/dev/null || true

echo '---CREATE_TABLE_COUNT---' >> "$OUT_PATH"
grep -i '^CREATE TABLE' "$f" | wc -l >> "$OUT_PATH" 2>/dev/null || true

echo '---TABLES_SAMPLE(100)---' >> "$OUT_PATH"
grep -i '^CREATE TABLE' "$f" | sed -E 's/CREATE TABLE `([^`]*)`.*/\1/' | head -n 100 >> "$OUT_PATH" 2>/dev/null || true

echo '---TOP_INSERT_20---' >> "$OUT_PATH"
grep -o 'INSERT INTO `[^`]*`' "$f" | sed -E 's/INSERT INTO `([^`]*)`/\1/' | sort | uniq -c | sort -nr | head -n 20 >> "$OUT_PATH" 2>/dev/null || true

echo '---ALTER_COUNT---' >> "$OUT_PATH"
grep -i '^ALTER TABLE' "$f" | wc -l >> "$OUT_PATH" 2>/dev/null || true

echo '---ALTER_SAMPLE---' >> "$OUT_PATH"
grep -i '^ALTER TABLE' "$f" | head -n 50 >> "$OUT_PATH" 2>/dev/null || true

echo '---UPDATE_COUNT---' >> "$OUT_PATH"
grep -i '^UPDATE ' "$f" | wc -l >> "$OUT_PATH" 2>/dev/null || true

echo '---UPDATE_SAMPLE---' >> "$OUT_PATH"
grep -i '^UPDATE ' "$f" | head -n 50 >> "$OUT_PATH" 2>/dev/null || true

echo '---ENUM_SAMPLE---' >> "$OUT_PATH"
grep -n 'ENUM(' "$f" | head -n 200 >> "$OUT_PATH" 2>/dev/null || true

echo '---FK_INDEX_SAMPLE---' >> "$OUT_PATH"
grep -n -i -E 'FOREIGN KEY|ADD CONSTRAINT|CREATE INDEX|KEY ' "$f" | head -n 200 >> "$OUT_PATH" 2>/dev/null || true

echo 'WROTE: ' "$OUT_PATH"
