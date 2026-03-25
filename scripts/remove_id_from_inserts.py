#!/usr/bin/env python3
"""
Remove `id` column from mysqldump INSERT statements and adjust VALUES tuples accordingly.

Usage:
  python3 remove_id_from_inserts.py <input.sql> <output.sql>

This will transform lines like:
  INSERT INTO `vehicles` (`id`, `license_plate`, ...) VALUES (1,'ABC',...),(...);
into:
  INSERT INTO `vehicles` (`license_plate`, ...) VALUES ('ABC',...),(...);

It preserves other lines untouched. Assumes values tuples don't contain nested unbalanced parentheses.
"""
import re
import sys

def process_insert(line):
    # match INSERT INTO `table` (`col1`, `col2`, ...) VALUES (....);
    m = re.match(r"^(INSERT INTO `(?P<table>[^`]+)` \((?P<cols>[^)]+)\) VALUES (?P<vals>\(.*\));)\s*$", line.strip(), re.DOTALL)
    if not m:
        return line

    cols_raw = m.group('cols')
    cols = [c.strip().strip('`') for c in cols_raw.split(',')]
    if cols[0].lower() != 'id':
        return line

    # remove first column
    new_cols = cols[1:]
    # now we need to strip the first value from every tuple in the VALUES part
    vals_part = m.group('vals').strip()
    # vals_part starts with '(' and ends with ');' ? Our regex includes trailing ; in group, handle accordingly
    # We'll remove the trailing semicolon if present
    if vals_part.endswith(';'):
        vals_part = vals_part[:-1]

    # split tuples by '),(' naive approach: replace '),(' with ')	(' and split on tab
    # This assumes values tuples themselves do not contain '),(' sequence (reasonable for mysqldump)
    tuples = vals_part.strip()
    # remove leading VALUES
    if tuples.upper().startswith('VALUES '):
        tuples = tuples[7:]

    # normalize separators
    parts = re.split(r"\),\s*\(", tuples[1:-1]) if tuples.startswith('(') and tuples.endswith(')') else []
    new_tuples = []
    for p in parts:
        # p is content between parentheses for each tuple
        # split on commas cautiously: we'll rely on mysqldump keeping string quoting with single quotes and no unescaped commas inside strings
        # so simple split works in most cases
        vals = []
        cur = ''
        in_str = False
        esc = False
        for ch in p:
            if ch == "'" and not esc:
                in_str = not in_str
                cur += ch
                continue
            if ch == '\\' and in_str:
                esc = not esc
                cur += ch
                continue
            if ch == ',' and not in_str:
                vals.append(cur)
                cur = ''
            else:
                cur += ch
                esc = False
        if cur != '':
            vals.append(cur)

        # drop first value
        if len(vals) <= 1:
            # nothing to keep
            continue
        new_vals = ','.join(v.strip() for v in vals[1:])
        new_tuples.append('(' + new_vals + ')')

    if not new_tuples:
        return ''

    new_insert = f"INSERT INTO `{m.group('table')}` ({', '.join('`'+c+'`' for c in new_cols)}) VALUES " + ','.join(new_tuples) + ";\n"
    return new_insert

def main():
    if len(sys.argv) != 3:
        print("Usage: remove_id_from_inserts.py <input.sql> <output.sql>")
        sys.exit(2)

    inp = sys.argv[1]
    out = sys.argv[2]

    with open(inp, 'r', encoding='utf-8') as f_in, open(out, 'w', encoding='utf-8') as f_out:
        for raw in f_in:
            new = process_insert(raw)
            if new is None:
                f_out.write(raw)
            else:
                f_out.write(new)

    print(f"Removed id from inserts: {inp} -> {out}")

if __name__ == '__main__':
    main()
