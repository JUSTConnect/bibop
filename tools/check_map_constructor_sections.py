#!/usr/bin/env python3
"""Verify the source-level order of Map Constructor inspector sections."""

from pathlib import Path
import sys


INSPECTOR_PATH = Path("scripts/ui/map_constructor/map_constructor_inspector.gd")
COVERAGE_PATH = Path("scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd")
PROPERTY_CONTROLS_PATH = Path("scripts/ui/map_constructor/map_constructor_property_controls.gd")
GAME_FACING_LABEL_PATHS = [
    Path("scripts/world"),
    Path("scripts/game"),
    Path("scripts/ui"),
]
FORBIDDEN_GAME_FACING_LABEL_MARKERS = [
    "Floor /",
    "/ Пол",
    "Стена",
    "Дверь",
    "Терминал",
    "Стальной",
    "Базовое покрытие",
    "labels_ru",
    "palette_label_ru",
    "display_name_ru",
]
EXPECTED_SECTIONS = [
    "1. Identity",
    "2. Current Status",
    "3. Circuit",
    "4. Placement",
    "5. Configurable Parameters",
    "6. Links",
    "7. Warnings",
    "7. Floor Coverage",
    "8. Wall Coverage",
]
INSPECTOR_DIRECT_SECTIONS = [
    "1. Identity",
    "2. Current Status",
    "4. Placement",
    "5. Configurable Parameters",
    "6. Links",
    "7. Warnings",
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
        property_controls_source = read_source(PROPERTY_CONTROLS_PATH)
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

    # The inspector adds identity/status/placement/config/link/warning sections directly,
    # delegates the circuit subsection to property controls, and delegates coverage to
    # floor/wall controls. Keep these source-level checks aligned with that split so
    # the gate verifies delegation without forcing behavior back into the inspector.
    previous_index = -1
    section_indexes = {}
    for section in INSPECTOR_DIRECT_SECTIONS:
        marker = f'ui._create_inspector_section("{section}")'
        index = inspector_source.find(marker)
        if index == -1:
            return fail(f'missing Map Constructor inspector section: "{section}".')
        if index <= previous_index:
            return fail(f'Map Constructor inspector section is out of order: "{section}".')
        section_indexes[section] = index
        previous_index = index

    circuit_marker = 'create_inspector_section(ui, "3. Circuit")'
    if circuit_marker not in property_controls_source:
        return fail(f'missing Map Constructor inspector section: "3. Circuit" in {PROPERTY_CONTROLS_PATH}.')
    circuit_call = "MapConstructorPropertyControls.add_circuit_block"
    circuit_call_index = inspector_source.find(circuit_call)
    if circuit_call_index == -1:
        return fail(f"{INSPECTOR_PATH} no longer delegates to {circuit_call}().")
    if not (section_indexes["2. Current Status"] < circuit_call_index < section_indexes["4. Placement"]):
        return fail("Map Constructor circuit section delegation is out of order.")

    for section in ["7. Floor Coverage", "8. Wall Coverage"]:
        marker = f'ui._create_inspector_section("{section}")'
        if marker not in coverage_source:
            return fail(f'missing delegated Map Constructor coverage section: "{section}".')

    print("OK: Map Constructor inspector sections are present in the expected order:")
    for section in EXPECTED_SECTIONS:
        print(f"  - {section}")

    forbidden_matches = []
    for root in GAME_FACING_LABEL_PATHS:
        for path in root.rglob("*.gd"):
            source = read_source(path)
            for line_number, line in enumerate(source.splitlines(), start=1):
                for marker in FORBIDDEN_GAME_FACING_LABEL_MARKERS:
                    if marker in line:
                        forbidden_matches.append(f"{path}:{line_number}: contains {marker!r}")
    if forbidden_matches:
        return fail("game-facing scripts contain forbidden Russian or mixed labels:\n  " + "\n  ".join(forbidden_matches))

    print("OK: Game-facing scripts contain no forbidden Russian or mixed archetype label markers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
