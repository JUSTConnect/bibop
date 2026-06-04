#!/usr/bin/env python3
"""Repo-local visual asset existence check for the iso renderer hotfix.

This intentionally avoids the Godot CLI: it verifies the canonical floor and
object visual IDs against the exact case-sensitive paths in this repository.
"""
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]

CANONICAL_FLOOR_ASSETS = {
    "floor_concrete": "assets/visual/isometric/floor/floor_concrete_01.png",
    "floor_steel": "assets/visual/isometric/floor/floor_steel_01.png",
    "floor_titan": "assets/visual/isometric/floor/floor_titan_01.png",
}

CANONICAL_OBJECT_ASSETS = {
    "cabel_reel_01": "assets/visual/isometric/objects/cabel_reel_01.png",
    "cabel_reel_02": "assets/visual/isometric/objects/cabel_reel_02.png",
    "fuse_box_in_01": "assets/visual/isometric/objects/fuse_box_in_01.png",
    "fuse_box_out_01": "assets/visual/isometric/objects/fuse_box_out_01.png",
    "fuse_box_in_wall_01": "assets/visual/isometric/objects/fuse_box_in_wall_01.png",
    "fuse_box_out_wall_01": "assets/visual/isometric/objects/fuse_box_out_wall_01.png",
    "light_01": "assets/visual/isometric/objects/light_01.png",
    "power_source_01": "assets/visual/isometric/objects/power_source_01.png",
    "power_switcher_off_01": "assets/visual/isometric/objects/power_switcher_off_01.png",
    "power_switcher_off_wall_01": "assets/visual/isometric/objects/power_switcher_off_wall_01.png",
    "power_switcher_on_01": "assets/visual/isometric/objects/power_switcher_on_01.png",
    "power_switcher_on_wall_01": "assets/visual/isometric/objects/power_switcher_on_wall_01.png",
    "radiator_01": "assets/visual/isometric/objects/radiator_01.png",
    "terminal_01": "assets/visual/isometric/objects/terminal_01.png",
    "barrel_01": "assets/visual/isometric/moovable/barrel_01.png",
    "case_01": "assets/visual/isometric/objects/case_01.png",
    "steel_box_01": "assets/visual/isometric/moovable/steel_box_01.png",
    "fire_barrel_01": "assets/visual/isometric/moovable/fire_barrel_01.png",
}

# These are logical/canonical resolver IDs expected by gameplay objects. They
# intentionally preserve gameplay IDs while pointing to the valid uploaded PNGs.
EXPECTED_LOGICAL_VARIANTS = {
    "power_switcher_floor_off": "power_switcher_off_01",
    "power_switcher_wall_off": "power_switcher_off_wall_01",
    "power_switcher_floor_on": "power_switcher_on_01",
    "power_switcher_wall_on": "power_switcher_on_wall_01",
    "fuse_box_floor_present": "fuse_box_in_01",
    "fuse_box_floor_empty": "fuse_box_out_01",
    "fuse_box_wall_present": "fuse_box_in_wall_01",
    "fuse_box_wall_empty": "fuse_box_out_wall_01",
    "barrel_normal": "barrel_01",
    "barrel_fire": "fire_barrel_01",
    "cable_reel_floor": "cabel_reel_01",
    "cable_reel_wall": "cabel_reel_02",
}


def check_paths(group_name: str, catalog: dict[str, str]) -> list[str]:
    failures: list[str] = []
    for asset_id, relative_path in sorted(catalog.items()):
        path = REPO_ROOT / relative_path
        if not path.is_file():
            failures.append(f"{group_name}:{asset_id} -> missing {relative_path}")
    return failures


def main() -> int:
    failures: list[str] = []
    failures.extend(check_paths("floor", CANONICAL_FLOOR_ASSETS))
    failures.extend(check_paths("object", CANONICAL_OBJECT_ASSETS))
    for logical_id, canonical_id in sorted(EXPECTED_LOGICAL_VARIANTS.items()):
        if canonical_id not in CANONICAL_OBJECT_ASSETS:
            failures.append(f"logical:{logical_id} -> unknown canonical id {canonical_id}")
    if failures:
        print("Visual asset validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Visual asset validation passed: {len(CANONICAL_FLOOR_ASSETS)} floor assets, {len(CANONICAL_OBJECT_ASSETS)} object assets, {len(EXPECTED_LOGICAL_VARIANTS)} logical variants.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
