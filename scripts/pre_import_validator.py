#!/usr/bin/env python3
"""
Simple pre-import validator for generated SQL files.

Checks performed:
- warns if legacy column name `year` appears (should use `year_made` in current schema)
- warns if `ON DUPLICATE KEY UPDATE` contains `VALUES(`year`)` patterns
- returns non-zero exit code if serious issues found (useful for CI)

This is intentionally lightweight; extend with schema-aware checks later.
"""
import argparse
import re
import sys


def scan_file(path):
    with open(path, "r", encoding="utf-8") as f:
        s = f.read()
    issues = []
    # detect bare column name year (word boundary)
    if re.search(r"\byear\b", s, flags=re.IGNORECASE):
        issues.append(("WARN", "Found token 'year' in SQL. Consider mapping to 'year_made' to match schema."))
    # detect VALUES(`year`) or =VALUES(`year`)
    if re.search(r"VALUES\s*\(\s*`?year`?\s*\)", s, flags=re.IGNORECASE):
        issues.append(("ERROR", "Found VALUES(year) patterns in ON DUPLICATE clauses — cleanup needed."))
    if re.search(r"=\s*VALUES\s*\(\s*`?year`?\s*\)", s, flags=re.IGNORECASE):
        issues.append(("ERROR", "Found '= VALUES(year)' usage — please remove or rewrite to use explicit assignments.") )
    # detect suspicious multi-row INSERT WITHOUT ON DUPLICATE
    multi_row_inserts = re.findall(r"INSERT\s+INTO\s+`?vehicles`?\s+.*?VALUES\s*\((?:[^;]+?)\)\s*,\s*\(", s, flags=re.IGNORECASE|re.DOTALL)
    if multi_row_inserts:
        issues.append(("WARN", f"Detected {len(multi_row_inserts)} multi-row INSERT(s) into vehicles — consider per-row upserts for idempotency."))
    return issues


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sqlfile", help="SQL file to validate")
    args = p.parse_args()
    issues = scan_file(args.sqlfile)
    if not issues:
        print("OK: No issues detected (basic checks)")
        return 0
    level = "OK"
    for sev, msg in issues:
        print(f"{sev}: {msg}")
        if sev == "ERROR":
            level = "ERROR"
    return 1 if level == "ERROR" else 0


if __name__ == '__main__':
    sys.exit(main())
