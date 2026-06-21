#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
PROJECTION = ROOT / "scripts/visual/renderer/iso_projection_service.gd"
DRAW_ENTRY = ROOT / "scripts/visual/renderer/iso_draw_entry_contract.gd"
FLOOR = ROOT / "scripts/visual/renderer/floor_renderer.gd"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required renderer component: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)", source)
    return match.group(0) if match else ""


renderer = read(RENDERER)
projection = read(PROJECTION)
draw_entry = read(DRAW_ENTRY)
floor = read(FLOOR)

renderer_lines = len(renderer.splitlines())
if renderer_lines > 7460:
    errors.append(f"RoomVisualRenderer grew beyond floor-extraction cap: {renderer_lines} > 7460")

for token in (
    'preload("res://scripts/visual/renderer/iso_projection_service.gd")',
    'preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")',
    'preload("res://scripts/visual/renderer/floor_renderer.gd")',
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer missing component preload: {token}")

projection_delegates = {
    "get_iso_projection_mode": "IsoProjectionServiceRef.normalize_mode",
    "get_iso_tile_size": "IsoProjectionServiceRef.get_tile_size",
    "get_iso_exported_tile_size_matches_active_mode": "IsoProjectionServiceRef.exported_tile_size_matches_active_mode",
    "get_iso_tile_half_size": "IsoProjectionServiceRef.get_tile_half_size",
    "grid_to_iso": "IsoProjectionServiceRef.grid_to_iso",
    "iso_to_grid": "IsoProjectionServiceRef.iso_to_grid",
    "get_iso_diamond_points": "IsoProjectionServiceRef.get_diamond_points",
    "get_iso_inset_diamond_points": "IsoProjectionServiceRef.get_inset_diamond_points",
    "get_iso_depth_key": "IsoProjectionServiceRef.get_depth_key",
    "get_iso_floor_depth_key": "IsoProjectionServiceRef.get_depth_key",
    "sort_cells_by_iso_depth": "IsoProjectionServiceRef.sort_cells_by_depth",
}
for name, delegate in projection_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to projection component")

floor_delegates = {
    "is_floor_like_tile": "FloorRendererRef.is_floor_like_tile",
    "get_floor_prototype_color": "FloorRendererRef.get_prototype_color",
    "is_walkable_floor_like_for_iso_passage": "FloorRendererRef.is_walkable_floor_like_for_passage",
    "is_iso_interactive_floor_tile": "FloorRendererRef.is_interactive_floor_tile",
    "is_iso_passage_floor_cell": "FloorRendererRef.is_passage_floor_cell",
    "get_iso_floor_visual_profile_key_for_cell": "FloorRendererRef.get_visual_profile_key_for_cell",
    "get_iso_floor_material_family_for_cell": "FloorRendererRef.get_material_family_for_cell",
    "get_iso_floor_visual_profile": "FloorRendererRef.get_visual_profile",
    "normalize_floor_material_key": "FloorRendererRef.normalize_material_key",
    "get_iso_floor_asset_key_for_material_key": "FloorRendererRef.get_asset_key_for_material_key",
    "get_iso_floor_asset_key_for_tile": "FloorRendererRef.get_asset_key_for_tile",
    "get_iso_floor_asset_key_for_visual_height": "FloorRendererRef.get_asset_key_for_visual_height",
    "get_iso_floor_asset_key_for_visual_state": "FloorRendererRef.get_asset_key_for_visual_state",
    "get_iso_floor_asset_placement": "FloorRendererRef.get_asset_placement",
    "normalize_floor_height_level": "FloorRendererRef.normalize_height_level",
    "get_iso_ground_asset_key_for_floor_height": "FloorRendererRef.get_ground_asset_key_for_floor_height",
    "get_ground_asset_key_for_cell": "FloorRendererRef.get_ground_asset_key_for_cell",
    "get_floor_atlas_cell_size": "FloorRendererRef.get_atlas_cell_size",
    "get_floor_atlas_region": "FloorRendererRef.get_atlas_region",
    "get_floor_state_for_cell": "FloorRendererRef.get_floor_state_for_cell",
    "get_floor_base_atlas_key": "FloorRendererRef.get_base_atlas_key",
    "get_floor_overlay_atlas_key": "FloorRendererRef.get_overlay_atlas_key",
    "get_floor_atlas_variant_for_cell": "FloorRendererRef.get_atlas_variant_for_cell",
    "get_floor_atlas_seam_safe_variant": "FloorRendererRef.get_atlas_seam_safe_variant",
    "get_floor_atlas_safe_source_rect": "FloorRendererRef.get_atlas_safe_source_rect",
    "get_floor_atlas_destination_rect": "FloorRendererRef.get_atlas_destination_rect",
    "get_floor_atlas_inner_overlay_points": "FloorRendererRef.get_atlas_inner_overlay_points",
    "get_floor_atlas_uvs_for_destination_points": "FloorRendererRef.get_atlas_uvs_for_destination_points",
    "build_iso_floor_draw_entries": "FloorRendererRef.build_draw_entries",
}
for name, delegate in floor_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to FloorRenderer")

if "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):
    errors.append("RoomVisualRenderer draw-entry sorting must delegate to contract")

if renderer.count("IsoDrawEntryContractRef.make_entry") + floor.count("IsoDrawEntryContractRef.make_entry") < 5:
    errors.append("renderer components must use the shared draw-entry contract")

for constant_name in (
    "ISO_PROJECTION_STANDARD",
    "ISO_PROJECTION_CLASSIC",
    "ISO_STANDARD_TILE_SIZE",
    "ISO_LAYER_BIAS_WALL",
    "ISO_DRAW_SUB_ORDER_FLOOR",
    "ISO_FLOOR_TEST_ASSET_KEY",
    "ISO_FLOOR_ASSET_CATALOG",
    "ISO_FLOOR_ATLAS_LAYOUT",
):
    line = next((row for row in renderer.splitlines() if row.startswith(f"const {constant_name}:")), "")
    if "Ref." not in line:
        errors.append(f"renderer constant {constant_name} must be a component alias")

for forbidden in ("GridManager", "MissionManager", "draw_line(", "draw_polygon(", "queue_redraw("):
    if forbidden in projection:
        errors.append(f"projection component contains forbidden runtime dependency: {forbidden}")

for forbidden in ("draw_line(", "draw_polygon(", "draw_colored_polygon(", "queue_redraw(", "get_node("):
    if forbidden in floor:
        errors.append(f"FloorRenderer contains forbidden CanvasItem/runtime dependency: {forbidden}")

for token in (
    "class_name IsoProjectionService",
    "static func normalize_mode",
    "static func grid_to_iso",
    "static func iso_to_grid",
    "static func get_diamond_points",
    "static func get_depth_key",
    "static func sort_cells_by_depth",
):
    if token not in projection:
        errors.append(f"projection component missing contract: {token}")

for token in (
    "class_name IsoDrawEntryContract",
    "const KEY_DEPTH",
    "const LAYER_BIAS_WALL",
    "const SUB_ORDER_FLOOR",
    "static func make_entry",
    "static func less",
    "static func validate_entry",
):
    if token not in draw_entry:
        errors.append(f"draw-entry component missing contract: {token}")

for token in (
    "class_name FloorRenderer",
    "const FLOOR_ASSET_CATALOG",
    "const GROUND_ASSET_CATALOG",
    "const FLOOR_ATLAS_LAYOUT",
    "const FLOOR_VISUAL_PROFILES",
    "static func get_visual_profile_key_for_cell",
    "static func get_asset_key_for_material_key",
    "static func get_ground_asset_key_for_cell",
    "static func get_atlas_seam_safe_variant",
    "static func build_draw_entries",
):
    if token not in floor:
        errors.append(f"FloorRenderer missing contract: {token}")

if "func draw_iso_floor_cell" not in renderer:
    errors.append("stage boundary changed: Canvas floor drawing must remain in RoomVisualRenderer for this stage")
if "func draw_iso_floor_cell" in floor:
    errors.append("FloorRenderer must not own Canvas drawing in this stage")

if errors:
    print("RoomVisualRenderer component boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"RoomVisualRenderer component boundary audit OK ({renderer_lines} lines)")
