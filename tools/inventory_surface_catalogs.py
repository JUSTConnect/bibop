#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "scripts/game/mission_manager.gd",
    ROOT / "scripts/field/room_visual_renderer.gd",
    ROOT / "scripts/visual/visual_asset_catalog.gd",
    ROOT / "scripts/game/map_constructor_service.gd",
    ROOT / "scripts/game/map_constructor_preset_service.gd",
]
OUTPUT = ROOT / "docs/surface_catalog_inventory.tmp.md"
MARKERS = (
    "wall_material", "floor_material", "wall_height", "height_level",
    "ISO_PLACEHOLDER_ASSET_PATHS", "FLOOR_TEXTURE_ASSET_ALIASES",
    "WALL_TEXTURE_ASSET_ALIASES", "VISUAL_TEXTURE_ASSET_ALIASES",
    "breachable", "breach_side", "surface_material",
)
NAME_MARKERS = ("material", "height", "texture", "asset", "breach")


def function_ranges(lines: list[str]) -> list[tuple[int, int, str]]:
    starts: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        match = re.match(r"^func\s+([A-Za-z0-9_]+)\s*\(", line)
        if match:
            starts.append((index, match.group(1)))
    result: list[tuple[int, int, str]] = []
    for position, (start, name) in enumerate(starts):
        end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
        result.append((start, end, name))
    return result


def constant_ranges(lines: list[str]) -> list[tuple[int, int, str]]:
    result: list[tuple[int, int, str]] = []
    index = 0
    while index < len(lines):
        match = re.match(r"^const\s+([A-Za-z0-9_]+)\s*", lines[index])
        if not match:
            index += 1
            continue
        start = index
        name = match.group(1)
        braces = lines[index].count("{") - lines[index].count("}")
        brackets = lines[index].count("[") - lines[index].count("]")
        index += 1
        while index < len(lines) and (braces > 0 or brackets > 0):
            braces += lines[index].count("{") - lines[index].count("}")
            brackets += lines[index].count("[") - lines[index].count("]")
            index += 1
        result.append((start, index, name))
    return result


report: list[str] = ["# Temporary surface catalog inventory", ""]
for path in FILES:
    if not path.exists():
        continue
    lines = path.read_text(encoding="utf-8").splitlines()
    relative = path.relative_to(ROOT)
    report.extend([f"## `{relative}`", "", f"Lines: {len(lines)}", ""])

    report.extend(["### Relevant constants", ""])
    selected_constants = 0
    for start, end, name in constant_ranges(lines):
        block = "\n".join(lines[start:end])
        if not any(marker.lower() in name.lower() for marker in NAME_MARKERS) and not any(marker in block for marker in MARKERS):
            continue
        selected_constants += 1
        report.extend([f"#### `{name}` ({start + 1}-{end})", "", "```gdscript", block, "```", ""])
    if selected_constants == 0:
        report.append("None.\n")

    report.extend(["### Relevant functions", ""])
    selected_functions = 0
    for start, end, name in function_ranges(lines):
        block = "\n".join(lines[start:end]).rstrip()
        lower_name = name.lower()
        if not any(marker in lower_name for marker in NAME_MARKERS) and not any(marker in block for marker in MARKERS):
            continue
        selected_functions += 1
        report.extend([f"#### `{name}` ({start + 1}-{end})", "", "```gdscript", block, "```", ""])
    if selected_functions == 0:
        report.append("None.\n")

    report.extend(["### Direct marker occurrences", "", "```text"])
    for number, line in enumerate(lines, start=1):
        if any(marker in line for marker in MARKERS):
            report.append(f"{number}: {line}")
    report.extend(["```", ""])

OUTPUT.write_text("\n".join(report), encoding="utf-8")
print(f"Wrote {OUTPUT.relative_to(ROOT)}")
