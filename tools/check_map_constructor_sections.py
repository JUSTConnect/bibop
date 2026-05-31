#!/usr/bin/env python3
"""Verify the source-level order of Map Constructor inspector sections."""

from pathlib import Path
import sys


INSPECTOR_PATH = Path("scripts/ui/map_constructor/map_constructor_inspector.gd")
COVERAGE_PATH = Path("scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd")
EXPECTED_SECTIONS = [
    "1. Object Identity",
    "2. Current Status",
    "3. Placement",
    "4. Configurable Parameters",
    "5. Links",
    "6. Warnings",
    "7. Floor Coverage",
    "8. Wall Coverage",
]


def fail(message: str) -> int:
    print(f"FAIL: {message}")
    return 1


def read_source(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise RuntimeError(f"could not read {path}: {error}") from error


def main() -> int:
    try:
        inspector_source = read_source(INSPECTOR_PATH)
        coverage_source = read_source(COVERAGE_PATH)
    except RuntimeError as error:
        return fail(str(error))

    coverage_call = "MapConstructorFloorWallControls.add_coverage_sections"
    if coverage_call not in inspector_source:
        return fail(f"{INSPECTOR_PATH} no longer delegates to {coverage_call}().")

    floor_call = "add_floor_coverage_section(ui, parent)"
    wall_call = "add_wall_coverage_section(ui, parent, entity_info, cell, data, entity_kind, entity_id, type_group)"
    floor_call_index = coverage_source.find(floor_call)
    wall_call_index = coverage_source.find(wall_call)
    if floor_call_index == -1 or wall_call_index == -1 or floor_call_index >= wall_call_index:
        return fail(f"{COVERAGE_PATH} must add floor coverage before wall coverage.")

    # The inspector adds sections 1-6 directly, then delegates sections 7-8.
    logical_source = inspector_source + "\n" + coverage_source
    previous_index = -1
    for section in EXPECTED_SECTIONS:
        marker = f'ui._create_inspector_section("{section}")'
        index = logical_source.find(marker)
        if index == -1:
            return fail(f'missing Map Constructor inspector section: "{section}".')
        if index <= previous_index:
            return fail(f'Map Constructor inspector section is out of order: "{section}".')
        previous_index = index

    print("OK: Map Constructor inspector sections are present in the expected order:")
    for section in EXPECTED_SECTIONS:
        print(f"  - {section}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
