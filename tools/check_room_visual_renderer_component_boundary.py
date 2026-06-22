#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
PROJECTION = ROOT / "scripts/visual/renderer/iso_projection_service.gd"
DRAW_ENTRY = ROOT / "scripts/visual/renderer/iso_draw_entry_contract.gd"
FLOOR = ROOT / "scripts/visual/renderer/floor_renderer.gd"
WALL = ROOT / "scripts/visual/renderer/wall_renderer.gd"
OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required renderer component: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^(?:static\s+)?func {re.escape(name)}\s*\(.*?(?=^(?:static\s+)?func |\Z)", source)
    return match.group(0) if match else ""


renderer = read(RENDERER)
projection = read(PROJECTION)
draw_entry = read(DRAW_ENTRY)
floor = read(FLOOR)
wall = read(WALL)
object_renderer = read(OBJECT)

renderer_lines = len(renderer.splitlines())
if renderer_lines > 6650:
    errors.append(f"RoomVisualRenderer grew beyond object-policy extraction cap: {renderer_lines} > 6650")

for token in (
    'preload("res://scripts/visual/renderer/iso_projection_service.gd")',
    'preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")',
    'preload("res://scripts/visual/renderer/floor_renderer.gd")',
    'preload("res://scripts/visual/renderer/wall_renderer.gd")',
    'preload("res://scripts/visual/renderer/object_renderer.gd")',
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer missing component preload: {token}")

for name, delegate in {
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
}.items():
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

wall_delegates = {
    "is_wall_tile": "WallRendererRef.is_wall_tile",
    "_get_wall_side_delta": "WallRendererRef.get_side_delta",
    "_is_wall_in_bounds": "WallRendererRef.is_in_bounds",
    "_is_wall_cell": "WallRendererRef.is_wall_cell",
    "_get_wall_neighbor_mask": "WallRendererRef.get_neighbor_mask",
    "_is_wall_mount_neighbor_visible": "WallRendererRef.is_mount_neighbor_visible",
    "_is_door_like_tile": "WallRendererRef.is_door_like_tile",
    "is_outer_border_cell": "WallRendererRef.is_outer_border_cell",
    "get_iso_wall_connected_base_points": "WallRendererRef.get_connected_base_points",
    "get_iso_wall_base_points": "WallRendererRef.get_base_points",
    "get_iso_wall_depth_key_for_cell": "WallRendererRef.get_depth_key_for_cell",
    "get_iso_wall_asset_catalog": "WallRendererRef.get_asset_catalog",
    "normalize_wall_asset_key": "WallRendererRef.normalize_asset_key",
    "normalize_wall_height_level": "WallRendererRef.normalize_height_level",
    "get_wall_visual_profiles": "WallRendererRef.get_visual_profiles",
    "get_wall_visual_profile": "WallRendererRef.get_visual_profile",
    "get_wall_visual_profile_key_for_cell": "WallRendererRef.get_visual_profile_key_for_cell",
    "get_wall_object_type_for_cell": "WallRendererRef.get_object_type_for_metadata",
    "get_visible_wall_sides": "WallRendererRef.get_visible_sides",
    "get_wall_mounted_anchor_zones": "WallRendererRef.get_mounted_anchor_zones",
    "get_wall_render_topology": "WallRendererRef.get_render_topology",
    "build_iso_wall_draw_entries": "WallRendererRef.build_draw_entries",
}

if "ObjectRendererRef.get_sub_order" not in function_body(renderer, "get_iso_object_sub_order"):
    errors.append("RoomVisualRenderer get_iso_object_sub_order must delegate to ObjectRenderer")

if "ObjectRendererRef.get_wall_mounted_render_layer" not in function_body(renderer, "get_wall_mounted_render_layer"):
    errors.append("RoomVisualRenderer get_wall_mounted_render_layer must delegate to ObjectRenderer")

if "ObjectRendererRef.make_draw_entry" not in function_body(renderer, "make_iso_object_draw_entry"):
    errors.append("RoomVisualRenderer make_iso_object_draw_entry must delegate to ObjectRenderer")

for name, delegate in wall_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to WallRenderer")

object_delegates = {
    "get_iso_object_asset_key_for_profile": "ObjectRendererRef.get_asset_key_for_profile",
    "get_iso_object_profile_key_for_object_data": "ObjectRendererRef.get_profile_key_for_object_data",
    "is_wall_mounted_runtime_object": "ObjectRendererRef.is_wall_mounted_runtime_object",
    "get_wall_mounted_cardinal_side": "ObjectRendererRef.get_wall_mounted_cardinal_side",
    "_get_object_mount_mode": "ObjectRendererRef.get_mount_mode",
    "_is_object_state_on": "ObjectRendererRef.is_state_on",
    "_is_fuse_present": "ObjectRendererRef.is_fuse_present",
    "get_iso_object_asset_key_for_object_data": "ObjectRendererRef.get_asset_key_for_object_data",
}
for name, delegate in object_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to ObjectRenderer")

if "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):
    errors.append("RoomVisualRenderer draw-entry sorting must delegate to contract")

draw_entry_calls = (
    renderer.count("IsoDrawEntryContractRef.make_entry")
    + floor.count("IsoDrawEntryContractRef.make_entry")
    + wall.count("IsoDrawEntryContractRef.make_entry")
    + object_renderer.count("IsoDrawEntryContractRef.make_entry")
)
if draw_entry_calls < 5:
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
    "ISO_WALL_ASSET_CATALOG",
    "ISO_WALL_ASSET_PLACEMENT",
    "WALL_SIDE_ORDER",
    "WALL_MASS_RATIO",
):
    line = next((row for row in renderer.splitlines() if row.startswith(f"const {constant_name}:")), "")
    if "Ref." not in line:
        errors.append(f"renderer constant {constant_name} must be a component alias")

for forbidden in ("GridManager", "MissionManager", "draw_line(", "draw_polygon(", "queue_redraw("):
    if forbidden in projection:
        errors.append(f"projection component contains forbidden runtime dependency: {forbidden}")

for component_name, component_source in (("FloorRenderer", floor), ("WallRenderer", wall), ("ObjectRenderer", object_renderer)):
    for forbidden in ("draw_line(", "draw_polygon(", "draw_colored_polygon(", "queue_redraw(", "get_node("):
        if forbidden in component_source:
            errors.append(f"{component_name} contains forbidden CanvasItem/runtime dependency: {forbidden}")

for token in (
    "class_name IsoProjectionService",
    "static func grid_to_iso",
    "static func iso_to_grid",
    "static func get_depth_key",
):
    if token not in projection:
        errors.append(f"projection component missing contract: {token}")

for token in (
    "class_name IsoDrawEntryContract",
    "static func make_entry",
    "static func less",
    "static func validate_entry",
):
    if token not in draw_entry:
        errors.append(f"draw-entry component missing contract: {token}")

for token in (
    "class_name FloorRenderer",
    "const FLOOR_ASSET_CATALOG",
    "const FLOOR_ATLAS_LAYOUT",
    "static func get_visual_profile_key_for_cell",
    "static func build_draw_entries",
):
    if token not in floor:
        errors.append(f"FloorRenderer missing contract: {token}")

for token in (
    "class_name WallRenderer",
    "const ISO_WALL_ASSET_CATALOG",
    "const ISO_WALL_ASSET_PLACEMENT",
    "const WALL_SIDE_ORDER",
    "static func get_visual_profiles",
    "static func get_asset_key_for_material_and_height",
    "static func get_render_topology",
    "static func get_mounted_anchor_zones",
    "static func build_draw_entries",
):
    if token not in wall:
        errors.append(f"WallRenderer missing contract: {token}")

for token in (
    "class_name ObjectRenderer",
    "static func get_asset_key_for_profile",
    "static func get_profile_key_for_object_data",
    "static func get_asset_key_for_object_data",
    "static func get_sub_order",
    "static func get_wall_mounted_render_layer",
    "static func get_entry_kind",
    "static func get_layer_bias",
    "static func make_draw_entry",
):
    if token not in object_renderer:
        errors.append(f"ObjectRenderer missing contract: {token}")

if "IsoDrawEntryContractRef.make_entry" not in function_body(object_renderer, "make_draw_entry"):
    errors.append("ObjectRenderer draw-entry policy must use the shared draw-entry contract")

if "func draw_iso_floor_cell" not in renderer or "func draw_iso_wall_block" not in renderer:
    errors.append("stage boundary changed: Canvas floor/wall drawing must remain in RoomVisualRenderer")
if "func draw_iso_floor_cell" in floor:
    errors.append("FloorRenderer must not own Canvas drawing in this stage")
if "func draw_iso_wall_block" in wall:
    errors.append("WallRenderer must not own Canvas drawing in this stage")

if errors:
    print("RoomVisualRenderer component boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"RoomVisualRenderer component boundary audit OK ({renderer_lines} lines)")
