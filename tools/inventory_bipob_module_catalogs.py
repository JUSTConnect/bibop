#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
source = root / "scripts/bipob/bipob_controller.gd"
output = root / "docs/module_catalog_inventory.tmp.md"
lines = source.read_text(encoding="utf-8").splitlines()

starts = []
for index, line in enumerate(lines):
    match = re.match(r"^func\s+([A-Za-z0-9_]+)\s*\(", line)
    if match:
        starts.append((index, match.group(1)))

markers = [
    "EXTERNAL_MODULE_CATALOG",
    "BipobModule.new",
    "module_id",
    "module_type",
    "external_size",
    "allowed_external_sides",
    "internal_size",
    "granted_commands",
]
keywords = ["module", "catalog", "external", "internal", "alias", "hydrate", "factory", "constructor", "storage", "box"]
report = ["# Temporary module catalog inventory", "", f"Source lines: {len(lines)}", "", "## Marker occurrences", "", "```text"]
for number, line in enumerate(lines, start=1):
    if any(marker in line for marker in markers):
        report.append(f"{number}: {line}")
report.extend(["```", "", "## Relevant functions", ""])

for position, (start, name) in enumerate(starts):
    end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
    body = "\n".join(lines[start:end]).rstrip()
    if not any(word in name.lower() for word in keywords) and not any(marker in body for marker in markers):
        continue
    report.extend([f"### {name} ({start + 1}-{end})", "", "```gdscript", body, "```", ""])

output.write_text("\n".join(report), encoding="utf-8")
print(f"Wrote {output}")
