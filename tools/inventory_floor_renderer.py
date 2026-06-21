#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts/field/room_visual_renderer.gd"
OUT_MD = ROOT / "docs/floor_renderer_inventory.tmp.md"
OUT_JSON = ROOT / "docs/floor_renderer_inventory.tmp.json"

text = SOURCE.read_text(encoding="utf-8")
function_re = re.compile(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(")
starts = [(m.start(), m.group(1)) for m in function_re.finditer(text)]
names = {name for _, name in starts}
line_starts = [0]
for line in text.splitlines(keepends=True):
    line_starts.append(line_starts[-1] + len(line))

def line_for(offset: int) -> int:
    lo, hi = 0, len(line_starts)
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if line_starts[mid] <= offset:
            lo = mid
        else:
            hi = mid
    return lo + 1

functions = []
for index, (start, name) in enumerate(starts):
    end = starts[index + 1][0] if index + 1 < len(starts) else len(text)
    body = text[start:end].rstrip()
    calls = sorted(candidate for candidate in names if candidate != name and re.search(rf"\b{re.escape(candidate)}\s*\(", body))
    functions.append({
        "name": name,
        "start": line_for(start),
        "end": line_for(end - 1),
        "body": body,
        "calls": calls,
    })

incoming = {row["name"]: [] for row in functions}
for row in functions:
    for called in row["calls"]:
        incoming[called].append(row["name"])

selected_names = set()
seed_terms = ("floor", "ground", "diamond", "surface_asset", "material_profile")
for row in functions:
    lower = row["name"].lower()
    if any(term in lower for term in seed_terms):
        selected_names.add(row["name"])

# Include direct dependencies and callers so boundary decisions are visible.
for row in functions:
    if row["name"] in selected_names:
        selected_names.update(row["calls"])
        selected_names.update(incoming[row["name"]])

selected = [row for row in functions if row["name"] in selected_names]
for row in selected:
    row["called_by"] = sorted(incoming[row["name"]])

report = [
    "# Temporary FloorRenderer inventory",
    "",
    f"Selected functions: **{len(selected)}**",
    "",
    "| Function | Lines | LOC | Called by | Calls |",
    "|---|---:|---:|---|---|",
]
for row in selected:
    report.append(
        f"| `{row['name']}` | {row['start']}-{row['end']} | {row['end'] - row['start'] + 1} | "
        f"{', '.join(row['called_by']) or '—'} | {', '.join(row['calls']) or '—'} |"
    )

report.extend(["", "## Full bodies", ""])
for row in selected:
    report.extend([
        f"### `{row['name']}` ({row['start']}-{row['end']})",
        "",
        "```gdscript",
        row["body"],
        "```",
        "",
    ])

OUT_MD.write_text("\n".join(report), encoding="utf-8")
OUT_JSON.write_text(json.dumps(selected, indent=2), encoding="utf-8")
print(f"wrote {OUT_MD.relative_to(ROOT)} and {OUT_JSON.relative_to(ROOT)}")
