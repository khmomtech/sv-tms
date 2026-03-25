#!/usr/bin/env python3
"""
Transform a per-row vehicles SQL dump into a dev-compatible INSERT/UPSERT file.

This script does conservative, index-preserving transformations:
- Maps legacy column `year` -> `year_made` (dev uses `year_made`).
- Drops columns that are not present in the dev schema (configurable below).
- Removes duplicate columns/values after mapping.
- Cleans the ON DUPLICATE KEY UPDATE clause to include only kept columns.

Usage:
  python3 transform_vehicles_for_dev.py \
    scripts/merge_legacy_vehicles_per_row.sql \
    scripts/merge_legacy_vehicles_per_row_dev.sql

This is a best-effort, text-based transformation. Review the output SQL before applying to production.
"""
import sys
import re

if len(sys.argv) != 3:
    print("Usage: transform_vehicles_for_dev.py <input.sql> <output.sql>")
    sys.exit(2)

in_path = sys.argv[1]
out_path = sys.argv[2]

# Columns present in the dev `vehicles` table (based on recent DESCRIBE output).
# If your dev schema differs, update this set accordingly.
DEV_COLUMNS = {
    'id', 'license_plate', 'fuel_consumption', 'last_inspection_date', 'next_service_due',
    'last_service_date', 'manufacturer', 'mileage', 'model', 'status', 'type', 'truck_size',
    'qty_pallets_capacity', 'assigned_zone', 'available_routes', 'unavailable_routes',
    'gps_device_id', 'remarks', 'created_at', 'updated_at', 'year_made', 'parent_vehicle_id',
    # older dumps may include these; include if present in your dev schema
}

def split_columns(coltext):
    # Input looks like: `id`, `license_plate`, `fuel_consumption`, ...
    cols = [c.strip().strip('`') for c in coltext.split(',')]
    return cols

def split_values(valtext):
    # Very small parser: split on commas but respect simple quoted strings.
    vals = []
    cur = ''
    in_sq = False
    in_dq = False
    esc = False
    for ch in valtext:
        if esc:
            cur += ch
            esc = False
            continue
        if ch == "\\":
            cur += ch
            esc = True
            continue
        if ch == "'" and not in_dq:
            in_sq = not in_sq
            cur += ch
            continue
        if ch == '"' and not in_sq:
            in_dq = not in_dq
            cur += ch
            continue
        if ch == ',' and not in_sq and not in_dq:
            vals.append(cur.strip())
            cur = ''
            continue
        cur += ch
    if cur.strip() != '':
        vals.append(cur.strip())
    return vals

insert_re = re.compile(r"INSERT INTO `vehicles` \((?P<cols>[^)]+)\) VALUES \((?P<vals>.+?)\) ON DUPLICATE KEY UPDATE (?P<update>.+);", re.IGNORECASE)

out_lines = []
with open(in_path, 'r', encoding='utf-8') as inf:
    data = inf.read()

# We'll process line by line but need to handle very long INSERT lines, so rely on regex finditer
pos = 0
for m in insert_re.finditer(data):
    start, end = m.span()
    # copy text before this INSERT
    out_lines.append(data[pos:start])
    pos = end

    cols_text = m.group('cols')
    vals_text = m.group('vals')
    update_text = m.group('update')

    cols = split_columns(cols_text)
    vals = split_values(vals_text)

    if len(cols) != len(vals):
        # fallback: leave statement unchanged if parsing failed
        out_lines.append(m.group(0))
        continue

    # Map `year` -> `year_made` if present
    mapped_cols = []
    mapped_vals = []
    seen = set()
    for c, v in zip(cols, vals):
        target = 'year_made' if c == 'year' else c
        # Skip columns not present in DEV_COLUMNS
        if target not in DEV_COLUMNS:
            # debug: skip unknown column
            continue
        if target in seen:
            # duplicate after mapping; prefer first occurrence (skip this one)
            continue
        seen.add(target)
        mapped_cols.append(target)
        mapped_vals.append(v)

    # Rebuild ON DUPLICATE KEY UPDATE: keep only columns present and map year->year_made
    # Split by comma but keep equality pairs
    updates = []
    for part in re.split(r',\s*(?=`)', update_text):
        # part looks like: `license_plate`=VALUES(`license_plate`)
        up = part.strip().rstrip(',')
        um = re.match(r"`(?P<col>[^`]+)`\s*=\s*VALUES\(`(?P<valcol>[^`]+)`\)", up)
        if not um:
            continue
        col = um.group('col')
        valcol = um.group('valcol')
        if col == 'year':
            col = 'year_made'
            valcol = 'year_made'
        if col in mapped_cols:
            updates.append(f"`{col}`=VALUES(`{valcol}`)")

    # Construct new INSERT statement
    cols_sql = ', '.join(f'`{c}`' for c in mapped_cols)
    vals_sql = ','.join(mapped_vals)
    update_sql = ', '.join(updates)
    new_stmt = f"INSERT INTO `vehicles` ({cols_sql}) VALUES ({vals_sql}) ON DUPLICATE KEY UPDATE {update_sql};\n"
    out_lines.append(new_stmt)

# append tail
out_lines.append(data[pos:])

with open(out_path, 'w', encoding='utf-8') as outf:
    outf.writelines(out_lines)

print(f"Wrote transformed SQL to {out_path}")
