#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts/field/room_visual_renderer.gd"
REPORT = ROOT / "docs/room_visual_renderer_dependency_map.tmp.md"
DATA = ROOT / "docs/room_visual_renderer_dependency_map.tmp.json"

text = SOURCE.read_text(encoding="utf-8")
lines = text.splitlines()
function_re = re.compile(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(")
starts = [(m.start(), m.group(1)) for m in function_re.finditer(text)]
line_offsets = [0]
for line in text.splitlines(keepends=True):
    line_offsets.append(line_offsets[-1] + len(line))

def line_for_offset(offset: int) -> int:
    lo, hi = 0, len(line_offsets)
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if line_offsets[mid] <= offset:
            lo = mid
        else:
            hi = mid
    return lo + 1

functions: list[dict] = []
name_set = {name for _, name in starts}
for index, (start, name) in enumerate(starts):
    end = starts[index + 1][0] if index + 1 < len(starts) else len(text)
    body = text[start:end].rstrip()
    start_line = line_for_offset(start)
    end_line = line_for_offset(end - 1)
    calls = sorted({candidate for candidate in name_set if candidate != name and re.search(rf"\b{re.escape(candidate)}\s*\(", body)})
    lower = name.lower()
    categories: list[str] = []
    keyword_groups = {
        "floor": ("floor", "ground"),
        "wall": ("wall", "breach", "mount"),
        "object": ("object", "door", "terminal", "item", "light"),
        "route": ("cable", "pipe", "route", "airflow", "cooling", "power_line"),
        "overlay": ("overlay", "debug", "preview", "marker", "outline"),
        "fog": ("fog", "visibility", "visible_cell", "explored"),
        "projection": ("iso", "project", "screen", "depth", "sort", "draw_entry", "queue"),
    }
    for category, keywords in keyword_groups.items():
        if any(keyword in lower for keyword in keywords):
            categories.append(category)
    if not categories:
        categories.append("coordination")
    functions.append({
        "name": name,
        "start_line": start_line,
        "end_line": end_line,
        "loc": end_line - start_line + 1,
        "calls": calls,
        "categories": categories,
    })

reverse: dict[str, list[str]] = defaultdict(list)
for function in functions:
    for called in function["calls"]:
        reverse[called].append(function["name"])
for function in functions:
    function["called_by"] = sorted(reverse.get(function["name"], []))

category_counts = Counter(category for function in functions for category in function["categories"])
category_loc = Counter()
for function in functions:
    for category in function["categories"]:
        category_loc[category] += function["loc"]

report: list[str] = [
    "# Temporary RoomVisualRenderer dependency map",
    "",
    f"- Total lines: **{len(lines)}**",
    f"- Functions: **{len(functions)}**",
    f"- Constants: **{sum(1 for line in lines if line.startswith('const '))}**",
    f"- Exported properties: **{sum(1 for line in lines if line.startswith('@export '))}**",
    "",
    "## Responsibility estimate",
    "",
    "| Category | Functions | Gross LOC* |",
    "|---|---:|---:|",
]
for category in sorted(category_counts):
    report.append(f"| {category} | {category_counts[category]} | {category_loc[category]} |")
report.extend([
    "",
    "\* Functions can belong to more than one category.",
    "",
    "## Largest functions",
    "",
    "| Function | Lines | Categories | Incoming | Outgoing |",
    "|---|---:|---|---:|---:|",
])
for function in sorted(functions, key=lambda row: (-row["loc"], row["name"]))[:80]:
    report.append(
        f"| `{function['name']}` | {function['start_line']}-{function['end_line']} ({function['loc']}) | "
        f"{', '.join(function['categories'])} | {len(function['called_by'])} | {len(function['calls'])} |"
    )

report.extend(["", "## Candidate low-coupling seams", ""])
for function in sorted(functions, key=lambda row: (len(row["called_by"]) + len(row["calls"]), -row["loc"], row["name"])):
    if function["loc"] < 5:
        continue
    if len(function["called_by"]) <= 3 and len(function["calls"]) <= 3:
        report.append(
            f"- `{function['name']}` — {function['loc']} LOC, categories: {', '.join(function['categories'])}; "
            f"called by: {', '.join(function['called_by']) or 'none'}; calls: {', '.join(function['calls']) or 'none'}."
        )

for category in ("projection", "floor", "wall", "object", "route", "overlay", "fog", "coordination"):
    report.extend(["", f"## {category.title()} functions", "", "| Function | Range | LOC | Called by | Calls |", "|---|---:|---:|---|---|"])
    rows = [row for row in functions if category in row["categories"]]
    for function in sorted(rows, key=lambda row: row["start_line"]):
        report.append(
            f"| `{function['name']}` | {function['start_line']}-{function['end_line']} | {function['loc']} | "
            f"{', '.join(function['called_by']) or '—'} | {', '.join(function['calls']) or '—'} |"
        )

REPORT.write_text("\n".join(report) + "\n", encoding="utf-8")
DATA.write_text(json.dumps({"line_count": len(lines), "functions": functions}, indent=2), encoding="utf-8")
print(f"Wrote {REPORT.relative_to(ROOT)} and {DATA.relative_to(ROOT)}")
