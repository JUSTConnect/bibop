#!/usr/bin/env python3
"""Repo-local visual asset existence check for active visual catalog IDs."""
from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = REPO_ROOT / "scripts/visual/visual_asset_catalog.gd"
WORLD_CATALOG_PATH = REPO_ROOT / "scripts/world/world_object_catalog.gd"
RENDERER_PATH = REPO_ROOT / "scripts/field/room_visual_renderer.gd"

LEGACY_PATHS = {
    "res://assets/visual/isometric/moovable/steel_box_01.png": "res://assets/visual/isometric/moovable/heavy_crate_floor.png",
    "res://assets/visual/isometric/objects/power_switcher_off_01.png": "res://assets/visual/isometric/objects/power_swicher/power_swicher_off_floor.png",
    "res://assets/visual/isometric/objects/power_switcher_on_01.png": "res://assets/visual/isometric/objects/power_swicher/power_swicher_on_floor.png",
    "res://assets/visual/isometric/objects/power_switcher_off_wall_01.png": "res://assets/visual/isometric/objects/power_swicher/power_swicher_off_wall.png",
    "res://assets/visual/isometric/objects/power_switcher_on_wall_01.png": "res://assets/visual/isometric/objects/power_swicher/power_swicher_on_wall.png",
}

SYNTHETIC_DESCRIPTORS = [
    ({"visual_id": "steel_box_01", "texture_path": "res://assets/visual/isometric/moovable/steel_box_01.png"}, "res://assets/visual/isometric/moovable/heavy_crate_floor.png"),
    ({"visual_id": "power_switcher_off_01", "texture_path": "res://assets/visual/isometric/objects/power_switcher_off_01.png"}, "res://assets/visual/isometric/objects/power_swicher/power_swicher_off_floor.png"),
]

ITEM_PATHS = {
    "fuse_floor_01": "res://assets/visual/isometric/items/fuse_floor.png",
    "repair_kit_floor_01": "res://assets/visual/isometric/items/repair_tool_floor.png",
    "reinforcement_floor_01": "res://assets/visual/isometric/items/reinforce_floor.png",
    "parts_floor_01": "res://assets/visual/isometric/items/ditales_floor.png",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _asset_paths(catalog: str) -> dict[str, str]:
    return dict(re.findall(r'"([^"]+)"\s*:\s*"(res://[^"]+)"', catalog))


def _canonical_object_ids(catalog: str) -> list[str]:
    match = re.search(r'CANONICAL_OBJECT_VISUAL_IDS:\s*Array\[String\]\s*=\s*\[(.*?)\]', catalog, re.S)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def _active_palette_asset_ids(world_catalog: str) -> list[str]:
    return re.findall(r'"visual_asset_id"\s*:\s*"([^"]+)"', world_catalog)


def _repo_path(res_path: str) -> Path:
    assert res_path.startswith("res://")
    return REPO_ROOT / res_path.removeprefix("res://")


def _resolve_descriptor(asset_paths: dict[str, str], descriptor: dict[str, str]) -> str:
    visual_id = descriptor.get("visual_id") or descriptor.get("visual_asset_id") or ""
    catalog_path = asset_paths.get(visual_id.strip().lower(), "")
    if catalog_path.endswith(".png") and _repo_path(catalog_path).is_file():
        return catalog_path
    texture_path = descriptor.get("path") or descriptor.get("texture_path") or ""
    return LEGACY_PATHS.get(texture_path, texture_path)


def main() -> int:
    catalog = _read(CATALOG_PATH)
    world_catalog = _read(WORLD_CATALOG_PATH)
    renderer = _read(RENDERER_PATH)
    asset_paths = _asset_paths(catalog)
    active_ids = sorted(set(_canonical_object_ids(catalog) + _active_palette_asset_ids(world_catalog)))
    failures: list[str] = []
    for asset_id in active_ids:
        res_path = asset_paths.get(asset_id, "")
        if not res_path:
            failures.append(f"active:{asset_id} -> no ASSET_PATHS entry")
            continue
        if not _repo_path(res_path).is_file():
            failures.append(f"active:{asset_id} -> missing {res_path}")
    for blocked_id in ["power_switcher_off_01", "steel_box_01"]:
        res_path = asset_paths.get(blocked_id, "")
        if not res_path or not _repo_path(res_path).is_file():
            failures.append(f"blocked-runtime-warning:{blocked_id} -> missing active-compatible path {res_path}")
    for legacy, current in LEGACY_PATHS.items():
        if f'"{legacy}": "{current}"' not in catalog:
            failures.append(f"legacy-migration:{legacy} -> missing migration to {current}")
        if not _repo_path(current).is_file():
            failures.append(f"legacy-migration:{legacy} -> migrated target missing {current}")
    for descriptor, expected in SYNTHETIC_DESCRIPTORS:
        resolved = _resolve_descriptor(asset_paths, descriptor)
        if resolved != expected:
            failures.append(f"synthetic-descriptor:{descriptor['visual_id']} -> resolved {resolved}, expected {expected}")
    for item_id, expected_path in ITEM_PATHS.items():
        resolved_path = asset_paths.get(item_id, "")
        if resolved_path != expected_path:
            failures.append(f"item-path:{item_id} -> resolved {resolved_path}, expected {expected_path}")
        if not _repo_path(expected_path).is_file():
            failures.append(f"item-path:{item_id} -> missing {expected_path}")
    runtime_files = [p for p in REPO_ROOT.rglob("*") if p.is_file() and ".git" not in p.parts and p.suffix in {".gd", ".tscn", ".tres", ".json", ".cfg"}]
    for path in runtime_files:
        text = _read(path)
        for legacy in LEGACY_PATHS:
            if legacy in text and path != CATALOG_PATH:
                failures.append(f"stale-runtime-reference:{path.relative_to(REPO_ROOT)} -> {legacy}")
    if "resolve_visual_texture_path" not in renderer or "duplicate(true)" not in renderer:
        failures.append("renderer: draw-time resolution guard must duplicate descriptors and call resolve_visual_texture_path")
    if 'find("/items/")' not in renderer:
        failures.append("renderer: object PNG resolver must accept authored /items/ PNG paths")
    draw_match = re.search(r"func draw_iso_object_png_texture_asset\(.*?\nfunc ", renderer, re.S)
    draw_body = draw_match.group(0) if draw_match else ""
    if "get_iso_object_png_texture_for_asset_key(normalized_asset_key)" in draw_body:
        failures.append("renderer: draw_iso_object_png_texture_asset must not load by asset key without descriptor/resolved path")
    if "get_iso_object_png_texture_for_resolved_path(normalized_asset_key, texture_path)" not in draw_body:
        failures.append("renderer: draw_iso_object_png_texture_asset must load from the resolved descriptor-aware texture_path")
    if '"power_switcher_off": "power_switcher_off_floor_01"' not in catalog:
        failures.append("alias:power_switcher_off -> not mapped to authored floor asset")
    if '"steel_box": "heavy_crate_floor_01"' not in catalog:
        failures.append("alias:steel_box -> not mapped to authored fallback asset")
    if failures:
        print("Visual asset validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Visual asset validation passed: {len(active_ids)} active visual ids resolve to existing files; stale descriptor paths migrate at draw time.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
