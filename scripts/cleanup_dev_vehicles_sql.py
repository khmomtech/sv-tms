#!/usr/bin/env python3
"""
Post-process merge_legacy_vehicles_per_row_dev_compat.sql to
- remove any remaining `year` column references and `year`=VALUES(...) assignments
- fix double-semicolons and ensure each statement ends with a single semicolon + newline
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DST = ROOT / "merge_legacy_vehicles_per_row_dev_compat.sql"

if not DST.exists():
    print(f"File not found: {DST}")
    raise SystemExit(1)

text = DST.read_text(encoding='utf-8')

# 1) Remove any `year`, occurrences in column lists
text = re.sub(r"`year`\s*,\s*", "", text)
text = re.sub(r",\s*`year`\s*", "", text)

# 2) Remove any `year`=VALUES(`year`) assignments in ON DUPLICATE clauses
text = re.sub(r",?\s*`year`\s*=\s*VALUES\(`year`\)\s*,?", ",", text)

# 3) Collapse repeated commas
text = re.sub(r",\s*,+", ",", text)

# 4) Remove stray commas before closing paren
text = re.sub(r",\s*\)", ")", text)

# 5) Fix double semicolons
text = text.replace(';;', ';')

# 6) Ensure every statement ends with a semicolon followed by a single newline
text = re.sub(r";\s*\n", ";\n", text)
text = re.sub(r";(?=[^\n])", ";\n", text)

# 7) Remove ON DUPLICATE KEY UPDATE if it was left empty (i.e. 'ON DUPLICATE KEY UPDATE ;')
text = re.sub(r"ON DUPLICATE KEY UPDATE\s*;", ";", text, flags=re.IGNORECASE)

# 8) Remove any stray '=VALUES(`year`)' fragments that might have been left behind
text = re.sub(r"=\s*VALUES\(`year`\)", "", text, flags=re.IGNORECASE)

# 9) Remove standalone ON DUPLICATE KEY UPDATE lines that are not attached to an INSERT
#    These can appear if the original ON DUPLICATE was on a separate line and processing
#    split the INSERT and its ON DUPLICATE; it's safer to drop such orphaned update lines.
text = re.sub(r"^\s*ON DUPLICATE KEY UPDATE.*$", "", text, flags=re.IGNORECASE | re.MULTILINE)

# 8) Final cleanup: remove accidental repeated newlines
text = re.sub(r"\n{3,}", "\n\n", text)

DST.write_text(text, encoding='utf-8')
print(f"Cleaned file written: {DST}")
