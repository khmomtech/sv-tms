#!/usr/bin/env python3
"""
Transform mysqldump complete-insert data-only SQL into INSERT ... ON DUPLICATE KEY UPDATE form.

Usage:
  python3 transform_insert_to_upsert.py <input.sql> <output.sql>

Behavior:
 - For each INSERT INTO `table` (`col1`,`col2`,...) VALUES (...); line, this script will append
   ON DUPLICATE KEY UPDATE `col2`=VALUES(`col2`), `col3`=VALUES(`col3`), ... excluding the first column
   (assumed primary key `id`). It preserves other lines (comments, SET statements) untouched.

Notes:
 - This is a best-effort transformer; review resulting SQL before running it on production.
 - Works with mysqldump produced `--complete-insert` format.
"""
import re
import sys

def transform_line(line):
    # match INSERT INTO `table` (`col1`, `col2`, ...) VALUES (...);
    m = re.match(r"^(INSERT INTO `(?P<table>[^`]+)` \((?P<cols>[^)]+)\) VALUES \((?P<vals>.*)\);)\s*$", line.strip(), re.DOTALL)
    if not m:
        return line

    cols_raw = m.group('cols')
    cols = [c.strip().strip('`') for c in cols_raw.split(',')]
    if len(cols) <= 1:
        # nothing to update
        return line

    # build update list excluding first column (assume PK `id`)
    update_cols = cols[1:]
    update_clause = ', '.join([f"`{c}`=VALUES(`{c}`)" for c in update_cols])

    # produce final line with ON DUPLICATE KEY UPDATE
    # keep the original INSERT portion (m.group(1) contains full INSERT ... VALUES(...))
    return m.group(1) + " ON DUPLICATE KEY UPDATE " + update_clause + ";\n"

def main():
    if len(sys.argv) != 3:
        print("Usage: transform_insert_to_upsert.py <input.sql> <output.sql>")
        sys.exit(2)

    inp = sys.argv[1]
    out = sys.argv[2]

    with open(inp, 'r', encoding='utf-8') as f_in, open(out, 'w', encoding='utf-8') as f_out:
        for raw in f_in:
            # handle multi-line INSERTs: mysqldump with --complete-insert keeps one INSERT per line
            line = raw
            new = transform_line(line)
            f_out.write(new)

    print(f"Transformed {inp} -> {out}")

if __name__ == '__main__':
    main()
