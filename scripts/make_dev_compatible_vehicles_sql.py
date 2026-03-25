#!/usr/bin/env python3
"""
Make a dev-compatible vehicles SQL file by removing the `year` column and any `year`=VALUES(...) update clauses.

Reads: scripts/merge_legacy_vehicles_per_row.sql
Writes: scripts/merge_legacy_vehicles_per_row_dev_compat.sql

This is a conservative transform: it only modifies lines that start with "INSERT INTO `vehicles`" and the following ON DUPLICATE KEY UPDATE part on the same line.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "merge_legacy_vehicles_per_row.sql"
DST = ROOT / "merge_legacy_vehicles_per_row_dev_compat.sql"

if not SRC.exists():
    print(f"Source file not found: {SRC}")
    raise SystemExit(1)


def split_sql_columns(cols_str: str):
    return [c.strip() for c in cols_str.split(',')]


def split_sql_values(vals_str: str):
    # split a SQL VALUES(...) content into individual value tokens while respecting single-quoted strings
    vals = []
    cur = []
    in_quote = False
    esc = False
    for ch in vals_str:
        if esc:
            cur.append(ch)
            esc = False
            continue
        if ch == "\\":
            cur.append(ch)
            esc = True
            continue
        if ch == "'":
            cur.append(ch)
            in_quote = not in_quote
            continue
        if ch == ',' and not in_quote:
            vals.append(''.join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    if cur:
        vals.append(''.join(cur).strip())
    return vals


def remove_year_from_update_clause(update_clause: str) -> str:
    # remove any `year`=VALUES(`year`) assignments safely
    new = re.sub(r"\,?\s*`year`\s*=\s*VALUES\(`year`\)\s*,?", ",", update_clause, flags=re.IGNORECASE)
    new = re.sub(r",\s*,+", ",", new)
    new = new.strip()
    new = re.sub(r"^,\s*", "", new)
    new = re.sub(r"\s*,\s*$", "", new)
    return new


with SRC.open('r', encoding='utf-8') as fr, DST.open('w', encoding='utf-8') as fw:
    for line in fr:
        if line.lstrip().lower().startswith("insert into `vehicles`"):
            try:
                lower = line.lower()
                insert_pos = lower.find("insert into `vehicles`")
                # find the columns list by scanning for matching parentheses
                col_start = line.find('(', insert_pos)
                if col_start == -1:
                    fw.write(line)
                    continue

                # find matching ')' for columns
                i = col_start + 1
                depth = 1
                while i < len(line) and depth > 0:
                    if line[i] == '(':
                        depth += 1
                    elif line[i] == ')':
                        depth -= 1
                    i += 1
                if depth != 0:
                    # malformed -- fallback
                    fw.write(line)
                    continue
                col_end = i - 1

                cols_str = line[col_start+1:col_end]
                cols = split_sql_columns(cols_str)

                # after col_end, expect VALUES ... find the next '(' that starts the values list
                vals_start = line.find('(', col_end)
                if vals_start == -1:
                    fw.write(line)
                    continue
                # find matching ')' for values list
                j = vals_start + 1
                depth = 1
                while j < len(line) and depth > 0:
                    if line[j] == "'":
                        # skip quoted string
                        j += 1
                        while j < len(line):
                            if line[j] == "'":
                                j += 1
                                break
                            if line[j] == "\\":
                                j += 2
                                continue
                            j += 1
                        continue
                    if line[j] == '(':
                        depth += 1
                    elif line[j] == ')':
                        depth -= 1
                    j += 1
                if depth != 0:
                    fw.write(line)
                    continue
                vals_end = j - 1

                vals_str = line[vals_start+1:vals_end]
                vals = split_sql_values(vals_str)

                # sanity: cols and vals should match; if not, fallback to writing original
                if len(cols) != len(vals):
                    fw.write(line)
                    continue

                # handle 'year' vs 'year_made':
                # - if `year_made` already exists in cols, drop legacy `year`
                # - if `year_made` does not exist but `year` does, rename `year` -> `year_made`
                seen_cols = [c.replace('`','').strip().lower() for c in cols]
                has_year_made = 'year_made' in seen_cols

                new_cols = []
                new_vals = []
                renamed_year = False
                for c, v in zip(cols, vals):
                    name = c.replace('`', '').strip()
                    lname = name.lower()
                    if lname == 'year':
                        if has_year_made:
                            # drop legacy year since year_made already present
                            continue
                        else:
                            # rename to year_made
                            new_cols.append('`year_made`')
                            new_vals.append(v)
                            renamed_year = True
                            continue
                    new_cols.append(c)
                    new_vals.append(v)

                # rebuild prefix and values part
                prefix = line[:col_start+1]
                cols_rebuilt = ', '.join(new_cols)
                values_rebuilt = ', '.join(new_vals)

                # find ON DUPLICATE clause (if any) from vals_end to semicolon
                semicolon_pos = line.rfind(';')
                ondup_clause = ''
                if semicolon_pos != -1 and semicolon_pos > vals_end:
                    tail = line[vals_end+1:semicolon_pos]
                    if 'on duplicate key update' in tail.lower():
                        # strip the leading keyword
                        idx = tail.lower().find('on duplicate key update')
                        ondup_clause = tail[idx+len('on duplicate key update'):]
                # clean ondup clause
                # If we renamed year -> year_made, replace any legacy assignment accordingly.
                new_ondup = ondup_clause
                if renamed_year:
                    # replace `year`=VALUES(`year`) with `year_made`=VALUES(`year_made`)
                    new_ondup = re.sub(r"`year`\s*=\s*VALUES\(`year`\)", "`year_made`=VALUES(`year_made`)", new_ondup, flags=re.IGNORECASE)
                else:
                    new_ondup = remove_year_from_update_clause(new_ondup)

                # build new line
                newline = prefix + cols_rebuilt + ') VALUES (' + values_rebuilt + ')'
                if new_ondup:
                    newline += ' ON DUPLICATE KEY UPDATE ' + new_ondup
                newline = newline.rstrip() + ';\n'
                fw.write(newline)
            except Exception:
                fw.write(line)
        else:
            fw.write(line)

print(f"Wrote dev-compatible vehicles SQL to: {DST}")
