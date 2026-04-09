#!/usr/bin/env python3
"""
Parse Checkstyle XML output and produce a JSON summary grouped by rule and by file.

Usage:
  python3 tools/parse_checkstyle.py [input_xml] [output_json]

If input_xml is omitted, the script will look for common locations:
 - target/checkstyle-result.xml
 - target/site/checkstyle-result.xml
 - target/site/checkstyle.html (not XML)

Output JSON schema:
{
  "totalViolations": int,
  "byRule": { ruleId: count },
  "byFile": { filePath: count },
  "topFiles": [ {"file": filePath, "count": int, "violations": [{"line":int,"message":str,"rule":str}]} ]
}

"""
import sys
import os
import json
import xml.etree.ElementTree as ET
from collections import defaultdict


def find_input_path():
    candidates = [
        'target/checkstyle-result.xml',
        'target/site/checkstyle-result.xml',
        'target/site/checkstyle.xml',
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    return None


def short_rule_from_source(src):
    # src looks like com.puppycrawl.tools.checkstyle.checks.imports.AvoidStarImportCheck
    if not src:
        return 'UnknownRule'
    parts = src.split('.')
    last = parts[-1]
    return last


def parse_checkstyle(xml_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    total = 0
    byRule = defaultdict(int)
    byFile = defaultdict(int)
    file_entries = {}

    # Checkstyle output format: <checkstyle version="..."> <file name="..."> <error line="..." severity="..." message="..." source="..."/> ...
    for file_elem in root.findall('file'):
        file_name = file_elem.get('name')
        if file_name is None:
            continue
        violations = []
        for err in file_elem.findall('error'):
            total += 1
            line = err.get('line')
            try:
                line = int(line) if line is not None else None
            except Exception:
                line = None
            msg = err.get('message') or ''
            src = err.get('source') or ''
            rule = short_rule_from_source(src)
            byRule[rule] += 1
            byFile[file_name] += 1
            violations.append({'line': line, 'message': msg, 'rule': rule})
        if violations:
            file_entries[file_name] = violations

    # Compute top files by count
    top_files = sorted(byFile.items(), key=lambda kv: kv[1], reverse=True)[:50]
    top_files_list = []
    for f, cnt in top_files:
        vs = file_entries.get(f, [])[:50]
        top_files_list.append({'file': f, 'count': cnt, 'violations': vs})

    return {
        'totalViolations': total,
        'byRule': dict(sorted(byRule.items(), key=lambda kv: kv[1], reverse=True)),
        'byFile': dict(sorted(byFile.items(), key=lambda kv: kv[1], reverse=True)),
        'topFiles': top_files_list,
    }


def main():
    in_path = None
    out_path = 'reports/checkstyle-summary.json'
    if len(sys.argv) >= 2:
        in_path = sys.argv[1]
    if len(sys.argv) >= 3:
        out_path = sys.argv[2]

    if not in_path:
        in_path = find_input_path()
        if not in_path:
            print('No checkstyle XML found. Please run `mvn checkstyle:checkstyle` first or pass the XML path.', file=sys.stderr)
            sys.exit(2)

    if not os.path.exists(in_path):
        print(f'Input file not found: {in_path}', file=sys.stderr)
        sys.exit(2)

    summary = parse_checkstyle(in_path)

    out_dir = os.path.dirname(out_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2)

    print(f'Wrote summary to {out_path} (totalViolations={summary["totalViolations"]})')


if __name__ == '__main__':
    main()
