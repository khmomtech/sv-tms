#!/usr/bin/env python3
"""
Generate per-row INSERT ... ON DUPLICATE KEY UPDATE SQL from a mysqldump data file.

This handles multi-row VALUES (...) , (...), ...; statements by splitting into
single-row INSERTs and appending a safe ON DUPLICATE KEY UPDATE clause.

Usage:
  python3 generate_per_row_upserts.py <input.sql> <output.sql>

Notes:
 - The script tries to be robust to quoted strings and escaped quotes inside
   value tuples. It is still recommended to review the produced SQL before
   running it on production.
 - Works with mysqldump --complete-insert format where INSERT INTO `table`
   (`col1`, `col2`, ...) VALUES (...),(...); appears on one or multiple lines.
"""
import re
import sys


def split_top_level_tuples(values_text):
    """Split the content after VALUES into a list of tuple strings.

    values_text is the substring that starts at the first '(' of the first tuple
    and ends at the matching ')' for the last tuple (not including trailing semicolon).
    This function returns a list like ['(... )', '(... )', ...] each including surrounding parens.
    The parser respects single-quoted strings and backslash escapes.
    """
    tuples = []
    i = 0
    n = len(values_text)
    in_quote = False
    escape = False
    depth = 0
    start = None

    while i < n:
        ch = values_text[i]
        if in_quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_quote = False
        else:
            if ch == "'":
                in_quote = True
            elif ch == '(':
                if depth == 0:
                    start = i
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0 and start is not None:
                    # include from start to i (inclusive)
                    tuples.append(values_text[start:i+1])
                    start = None
        i += 1

    return tuples


def build_upsert(insert_prefix, cols_list, tuple_text):
    # exclude first column from update (assume PK), but if there is only one col, no update
    if len(cols_list) <= 1:
        update_clause = ''
    else:
        update_cols = cols_list[1:]
        update_clause = ' ON DUPLICATE KEY UPDATE ' + ', '.join([f"`{c}`=VALUES(`{c}`)" for c in update_cols])

    return f"{insert_prefix} VALUES {tuple_text}{update_clause};\n"


def process_file(inp_path, out_path):
    insert_re = re.compile(r"INSERT INTO `(?P<table>[^`]+)` \((?P<cols>[^)]+)\) VALUES\s*(?P<rest>.*);\s*$", re.IGNORECASE | re.DOTALL)

    with open(inp_path, 'r', encoding='utf-8') as f_in, open(out_path, 'w', encoding='utf-8') as f_out:
        buffer = ''
        for raw in f_in:
            line = raw
            # accumulate because INSERT might span multiple lines
            buffer += line
            # try to match a complete INSERT (ends with semicolon)
            if ';' not in buffer:
                continue

            # process any complete statements inside buffer
            while ';' in buffer:
                stmt, rest = buffer.split(';', 1)
                stmt = stmt + ';'
                buffer = rest

                m = insert_re.match(stmt.strip())
                if not m:
                    # not an INSERT INTO ... VALUES ... ; -> write as-is
                    f_out.write(stmt + '\n')
                    continue

                table = m.group('table')
                cols_raw = m.group('cols')
                cols = [c.strip().strip('`') for c in cols_raw.split(',')]

                # find the position of the VALUES keyword (case-insensitive)
                idx = stmt.upper().find('VALUES')
                insert_prefix = stmt[:idx].strip()

                # extract the values substring between the first '(' after VALUES and the ending semicolon
                values_part = stmt[idx+6:].strip()  # after VALUES
                # remove trailing semicolon if present
                if values_part.endswith(';'):
                    values_part = values_part[:-1]

                # Trim leading whitespace/newlines
                values_part = values_part.strip()

                # At this point values_part should begin with '(' and contain one or many tuples
                tuples = split_top_level_tuples(values_part)
                if not tuples:
                    # fallback: write original
                    f_out.write(stmt + '\n')
                    continue

                for t in tuples:
                    out = build_upsert(insert_prefix, cols, t)
                    f_out.write(out)

        # any leftover buffer: write it
        if buffer.strip():
            f_out.write(buffer)


def main():
    if len(sys.argv) != 3:
        print('Usage: generate_per_row_upserts.py <input.sql> <output.sql>')
        sys.exit(2)

    inp = sys.argv[1]
    out = sys.argv[2]
    process_file(inp, out)
    print(f'Generated per-row upserts: {out}')


if __name__ == '__main__':
    main()
