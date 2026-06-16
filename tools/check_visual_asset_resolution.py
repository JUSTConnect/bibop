#!/usr/bin/env python3
"""Repo-local visual asset existence check for active visual catalog IDs."""
from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = REPO_ROOT / "scripts/visual/visual_asset_catalog.gd"
WORLD_CATALOG_PATH = REPO_ROOT / "scripts/world/world_object_catalog.gd"
RENDERER_PATH = REPO_ROOT / "scripts/field/room_visual_renderer.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _asset_paths(catalog: str) -> dict[str, str]:
    return dict(re.findall(r'"([^"]+)"\s*:\s*"res://([^"]+)"', catalog))


def _canonical_object_ids(catalog: str) -> list[str]:
    match = re.search(r'CANONICAL_OBJECT_VISUAL_IDS:\s*Array\[String\]\s*=\s*\[(.*?)\]', catalog, re.S)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def _active_palette_asset_ids(world_catalog: str) -> list[str]:
    return re.findall(r'"visual_asset_id"\s*:\s*"([^"]+)"', world_catalog)


def main() -> int:
    catalog = _read(CATALOG_PATH)
    world_catalog = _read(WORLD_CATALOG_PATH)
    renderer = _read(RENDERER_PATH)
    asset_paths = _asset_paths(catalog)
    active_ids = sorted(set(_canonical_object_ids(catalog) + _active_palette_asset_ids(world_catalog)))
    failures: list[str] = []
    for asset_id in active_ids:
        relative = asset_paths.get(asset_id, "")
        if not relative:
            failures.append(f"active:{asset_id} -> no ASSET_PATHS entry")
            continue
        if not (REPO_ROOT / relative).is_file():
            failures.append(f"active:{asset_id} -> missing {relative}")
    item_asset_ids = ["fuse_floor_01", "repair_kit_floor_01", "reinforcement_floor_01"]
    for item_id in item_asset_ids:
        relative = asset_paths.get(item_id, "")
        if not relative or not relative.startswith("assets/visual/isometric/items/") or not relative.endswith(".png"):
            failures.append(f"item:{item_id} -> not mapped to authored item png {relative}")
        elif not (REPO_ROOT / relative).is_file():
            failures.append(f"item:{item_id} -> missing {relative}")
    renderer_png_resolver = renderer.split("func get_iso_object_png_asset_path", 1)[1].split("func is_iso_object_png_asset_key", 1)[0] if "func get_iso_object_png_asset_path" in renderer else ""
    if '/items/' not in renderer_png_resolver:
        failures.append("renderer:get_iso_object_png_asset_path -> does not accept authored /items/ png paths")
    for placeholder_id in ["object_fuse", "object_repair_kit"]:
        if f'return "{placeholder_id}"' in renderer:
            failures.append(f"renderer:item-placeholder:{placeholder_id} -> item resolution still returns placeholder")
    for blocked_id in ["power_switcher_off_01", "steel_box_01"]:
        relative = asset_paths.get(blocked_id, "")
        if not relative or not (REPO_ROOT / relative).is_file():
            failures.append(f"blocked-runtime-warning:{blocked_id} -> missing active-compatible path {relative}")
    if '"power_switcher_off": "power_switcher_off_floor_01"' not in catalog:
        failures.append("alias:power_switcher_off -> not mapped to authored floor asset")
    if '"steel_box": "heavy_crate_floor_01"' not in catalog:
        failures.append("alias:steel_box -> not mapped to authored fallback asset")
    if failures:
        print("Visual asset validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Visual asset validation passed: {len(active_ids)} active visual ids resolve to existing files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
