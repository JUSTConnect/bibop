#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRID_MANAGER = ROOT / "scripts/field/grid_manager.gd"
MISSION_CATALOG = ROOT / "scripts/game/mission_content_catalog.gd"
MISSION_MANAGER = ROOT / "scripts/game/mission_manager.gd"
WORKFLOW = ROOT / ".github/workflows/godot-parser-gate.yml"

errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def expect(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def strip_comments_and_strings(source: str) -> str:
    out: list[str] = []
    i = 0
    in_string: str | None = None
    while i < len(source):
        char = source[i]
        if in_string is not None:
            if char == "\\":
                out.extend("  ")
                i += 2
                continue
            if char == in_string:
                in_string = None
            out.append("\n" if char == "\n" else " ")
            i += 1
            continue
        if char in ('"', "'"):
            in_string = char
            out.append(" ")
            i += 1
            continue
        if char == "#":
            while i < len(source) and source[i] != "\n":
                out.append(" ")
                i += 1
            continue
        out.append(char)
        i += 1
    return "".join(out)


grid_source = read(GRID_MANAGER)
catalog_source = read(MISSION_CATALOG)
manager_source = read(MISSION_MANAGER)
workflow_source = read(WORKFLOW)

expect("func get_mission10_layout" not in grid_source, "GridManager still defines get_mission10_layout()")
expect("TASK TEST emergency layout fallback" not in grid_source, "GridManager still contains TASK TEST fallback documentation/data")
expect(
    re.search(r"(?:if|elif)\s+mission_index\s*==\s*10\b", strip_comments_and_strings(grid_source)) is None,
    "GridManager.reset_mission_layout() still has a mission_index == 10 branch",
)

for path in sorted((ROOT / "scripts").rglob("*.gd")):
    clean = strip_comments_and_strings(path.read_text(encoding="utf-8"))
    relative = path.relative_to(ROOT).as_posix()
    forbidden_calls = [
        r"\bget_mission10_layout\s*\(",
        r"\breset_mission_layout\s*\(\s*(?:10|TASK_TEST_INDEX|TASK_TEST_MISSION_INDEX|MissionIdsRef\.TASK_TEST_INDEX)\b",
        r"call\s*\(\s*[\"']reset_mission_layout[\"']\s*,\s*(?:10|TASK_TEST_INDEX|TASK_TEST_MISSION_INDEX|MissionIdsRef\.TASK_TEST_INDEX)\b",
    ]
    for pattern in forbidden_calls:
        if re.search(pattern, clean):
            errors.append(f"retired TASK TEST GridManager fallback call remains in {relative}: {pattern}")

for required in [
    "TASK_TEST_LAYOUT_ID",
    '"layout_source": "mission_content_catalog"',
    '"layout": [',
    "MissionIdsRef.resolve_task_test_alias",
]:
    expect(required in catalog_source, f"MissionContentCatalog missing canonical TASK TEST contract: {required}")

for required in [
    "func apply_catalog_mission_layout_to_grid",
    "MissionContentCatalogRef.new()",
    "has_mission_layout",
    "get_mission_layout",
    'grid_manager.call("apply_mission_layout"',
    "validate_task_test_catalog_layout_runtime_source",
]:
    expect(required in manager_source, f"MissionManager missing catalog-first TASK TEST runtime contract: {required}")

expect("python tools/check_task_test_layout_source.py" in workflow_source, "TASK TEST layout static audit is not wired into CI")
expect("check_task_test_catalog_layout.gd" in workflow_source, "TASK TEST catalog behavior gate is not wired into CI")

if errors:
    print("TASK TEST layout source audit FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("TASK TEST layout source audit OK")
