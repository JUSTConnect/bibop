#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "scripts/field/room_visual_renderer.gd"
source = PATH.read_text(encoding="utf-8")

preload_marker = 'const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")\n'
preload_line = 'const FloorRendererRef = preload("res://scripts/visual/renderer/floor_renderer.gd")\n'
assert preload_marker in source
if preload_line not in source:
    source = source.replace(preload_marker, preload_marker + preload_line, 1)

floor_asset_pattern = re.compile(
    r'const ISO_FLOOR_ASSET_PACK_DIR: String = .*?\n'
    r'const ISO_GROUND_ASSET_PLACEMENT: Dictionary = \{.*?\n\}\n\n'
    r'(?=# Wall PNGs)',
    re.S,
)
floor_asset_aliases = '''const ISO_FLOOR_ASSET_PACK_DIR: String = FloorRendererRef.FLOOR_ASSET_PACK_DIR
const ISO_FLOOR_TEST_ASSET_KEY: String = FloorRendererRef.FLOOR_TEST_ASSET_KEY
const ISO_FLOOR_ASSET_CATALOG: Dictionary = FloorRendererRef.FLOOR_ASSET_CATALOG
const ISO_GROUND_ASSET_PACK_DIR: String = FloorRendererRef.GROUND_ASSET_PACK_DIR
const ISO_GROUND_ASSET_CATALOG: Dictionary = FloorRendererRef.GROUND_ASSET_CATALOG
const ISO_FLOOR_ASSET_TARGET_FOOTPRINT: Vector2 = FloorRendererRef.FLOOR_ASSET_TARGET_FOOTPRINT
const ISO_FLOOR_ASSET_NORMALIZED_OVERLAP: Vector2 = FloorRendererRef.FLOOR_ASSET_NORMALIZED_OVERLAP
const ISO_FLOOR_ASSET_PLACEMENT: Dictionary = FloorRendererRef.FLOOR_ASSET_PLACEMENT
const ISO_GROUND_ASSET_PLACEMENT: Dictionary = FloorRendererRef.GROUND_ASSET_PLACEMENT

'''
source, count = floor_asset_pattern.subn(floor_asset_aliases, source, count=1)
assert count == 1, "floor asset constant block not found"

atlas_pattern = re.compile(
    r'const ISO_FLOOR_ATLAS_COLUMNS: int = .*?\n'
    r'const ISO_FLOOR_ATLAS_LAYOUT: Dictionary = \{.*?\n\}\n\n'
    r'(?=const ISO_ASSET_ALIGNMENT_RULES)',
    re.S,
)
atlas_aliases = '''const ISO_FLOOR_ATLAS_COLUMNS: int = FloorRendererRef.FLOOR_ATLAS_COLUMNS
const ISO_FLOOR_ATLAS_ROWS: int = FloorRendererRef.FLOOR_ATLAS_ROWS
const ISO_FLOOR_ATLAS_BASE_VARIANTS: int = FloorRendererRef.FLOOR_ATLAS_BASE_VARIANTS
const ISO_FLOOR_ATLAS_HEAVY_METAL_VARIANTS: int = FloorRendererRef.FLOOR_ATLAS_HEAVY_METAL_VARIANTS
const ISO_FLOOR_ATLAS_SOURCE_EDGE_PADDING: float = FloorRendererRef.FLOOR_ATLAS_SOURCE_EDGE_PADDING
const ISO_FLOOR_ATLAS_SCREEN_OVERLAP: float = FloorRendererRef.FLOOR_ATLAS_SCREEN_OVERLAP
const ISO_FLOOR_UNDERLAY_OVERLAP: float = FloorRendererRef.FLOOR_UNDERLAY_OVERLAP
const ISO_FLOOR_ASSET_SCREEN_OVERLAP: float = FloorRendererRef.FLOOR_ASSET_SCREEN_OVERLAP
const ISO_FLOOR_OVERLAY_INNER_INSET: float = FloorRendererRef.FLOOR_OVERLAY_INNER_INSET
const ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS: Dictionary = FloorRendererRef.FLOOR_SEAM_SAFE_BASE_VARIANTS
const ISO_FLOOR_ATLAS_LAYOUT: Dictionary = FloorRendererRef.FLOOR_ATLAS_LAYOUT

'''
source, count = atlas_pattern.subn(atlas_aliases, source, count=1)
assert count == 1, "floor atlas constant block not found"


def replace_function(text: str, name: str, replacement: str) -> str:
    start = re.search(rf"(?m)^func {re.escape(name)}\s*\(", text)
    assert start, name
    next_function = re.search(r"(?m)^func [A-Za-z0-9_]+\s*\(", text[start.end():])
    end = start.end() + next_function.start() if next_function else len(text)
    return text[:start.start()] + replacement.rstrip() + "\n\n" + text[end:]

replacements = {
    "is_floor_like_tile": '''func is_floor_like_tile(tile_type: int) -> bool:
\treturn FloorRendererRef.is_floor_like_tile(tile_type)''',
    "get_floor_prototype_color": '''func get_floor_prototype_color(tile_type: int, cell: Vector2i) -> Color:
\treturn FloorRendererRef.get_prototype_color(tile_type, cell)''',
    "is_walkable_floor_like_for_iso_passage": '''func is_walkable_floor_like_for_iso_passage(tile_type: int) -> bool:
\treturn FloorRendererRef.is_walkable_floor_like_for_passage(tile_type)''',
    "is_iso_interactive_floor_tile": '''func is_iso_interactive_floor_tile(tile_type: int) -> bool:
\treturn FloorRendererRef.is_interactive_floor_tile(tile_type)''',
    "is_iso_passage_floor_cell": '''func is_iso_passage_floor_cell(cell: Vector2i) -> bool:
\treturn FloorRendererRef.is_passage_floor_cell(_grid_manager, cell)''',
    "get_iso_floor_visual_profile_key_for_cell": '''func get_iso_floor_visual_profile_key_for_cell(cell: Vector2i) -> String:
\treturn FloorRendererRef.get_visual_profile_key_for_cell(_grid_manager, cell)''',
    "get_iso_floor_material_family_for_cell": '''func get_iso_floor_material_family_for_cell(cell: Vector2i) -> String:
\treturn FloorRendererRef.get_material_family_for_cell(_grid_manager, cell)''',
    "get_iso_floor_visual_profile": '''func get_iso_floor_visual_profile(profile_key: String) -> Dictionary:
\treturn FloorRendererRef.get_visual_profile(profile_key)''',
    "normalize_floor_material_key": '''func normalize_floor_material_key(material_key: String) -> String:
\treturn FloorRendererRef.normalize_material_key(material_key)''',
    "get_iso_floor_asset_key_for_material_key": '''func get_iso_floor_asset_key_for_material_key(material_key: String) -> String:
\treturn FloorRendererRef.get_asset_key_for_material_key(material_key, use_gray_room_visual_test_assets)''',
    "get_iso_floor_asset_key_for_tile": '''func get_iso_floor_asset_key_for_tile(tile_type: int) -> String:
\treturn FloorRendererRef.get_asset_key_for_tile(tile_type, use_gray_room_visual_test_assets)''',
    "get_iso_floor_asset_key_for_visual_height": '''func get_iso_floor_asset_key_for_visual_height(value: String) -> String:
\treturn FloorRendererRef.get_asset_key_for_visual_height(value)''',
    "get_iso_floor_asset_key_for_visual_state": '''func get_iso_floor_asset_key_for_visual_state(cell: Vector2i) -> String:
\treturn FloorRendererRef.get_asset_key_for_visual_state(_grid_manager, cell)''',
    "get_iso_floor_asset_placement": '''func get_iso_floor_asset_placement(asset_key: String) -> Dictionary:
\treturn FloorRendererRef.get_asset_placement(asset_key, get_iso_tile_size())''',
    "normalize_floor_height_level": '''func normalize_floor_height_level(value: String) -> String:
\treturn FloorRendererRef.normalize_height_level(value)''',
    "get_iso_ground_asset_key_for_floor_height": '''func get_iso_ground_asset_key_for_floor_height(floor_height: String) -> String:
\treturn FloorRendererRef.get_ground_asset_key_for_floor_height(floor_height)''',
    "get_ground_asset_key_for_cell": '''func get_ground_asset_key_for_cell(cell: Vector2i) -> String:
\treturn FloorRendererRef.get_ground_asset_key_for_cell(_grid_manager, get_mission_manager_ref(), cell)''',
    "get_floor_atlas_cell_size": '''func get_floor_atlas_cell_size() -> Vector2:
\treturn FloorRendererRef.get_atlas_cell_size(iso_floor_atlas_texture)''',
    "get_floor_atlas_region": '''func get_floor_atlas_region(row: int, atlas_position: int) -> Rect2:
\treturn FloorRendererRef.get_atlas_region(iso_floor_atlas_texture, row, atlas_position)''',
    "get_floor_state_for_cell": '''func get_floor_state_for_cell(cell: Vector2i) -> Dictionary:
\treturn FloorRendererRef.get_floor_state_for_cell(_grid_manager, cell)''',
    "get_floor_base_atlas_key": '''func get_floor_base_atlas_key(family: String) -> String:
\treturn FloorRendererRef.get_base_atlas_key(family)''',
    "get_floor_overlay_atlas_key": '''func get_floor_overlay_atlas_key(family: String, wear: String) -> String:
\treturn FloorRendererRef.get_overlay_atlas_key(family, wear)''',
    "get_floor_atlas_variant_for_cell": '''func get_floor_atlas_variant_for_cell(cell: Vector2i, requested_variant: int, max_variants: int, salt: int = 0) -> int:
\treturn FloorRendererRef.get_atlas_variant_for_cell(cell, requested_variant, max_variants, salt)''',
    "get_floor_atlas_seam_safe_variant": '''func get_floor_atlas_seam_safe_variant(cell: Vector2i, atlas_key: String, requested_variant: int, max_variants: int, salt: int = 0) -> int:
\treturn FloorRendererRef.get_atlas_seam_safe_variant(cell, atlas_key, requested_variant, max_variants, salt)''',
    "get_floor_atlas_safe_source_rect": '''func get_floor_atlas_safe_source_rect(source_rect: Rect2) -> Rect2:
\treturn FloorRendererRef.get_atlas_safe_source_rect(source_rect)''',
    "get_floor_atlas_destination_rect": '''func get_floor_atlas_destination_rect() -> Rect2:
\treturn FloorRendererRef.get_atlas_destination_rect(get_iso_tile_half_size())''',
    "get_floor_atlas_inner_overlay_points": '''func get_floor_atlas_inner_overlay_points() -> PackedVector2Array:
\treturn FloorRendererRef.get_atlas_inner_overlay_points(get_iso_tile_half_size())''',
    "get_floor_atlas_uvs_for_destination_points": '''func get_floor_atlas_uvs_for_destination_points(points: PackedVector2Array, destination_rect: Rect2, source_rect: Rect2) -> PackedVector2Array:
\treturn FloorRendererRef.get_atlas_uvs_for_destination_points(points, destination_rect, source_rect)''',
    "build_iso_floor_draw_entries": '''func build_iso_floor_draw_entries() -> Array[Dictionary]:
\treturn FloorRendererRef.build_draw_entries(
\t\t_grid_manager,
\t\tCallable(self, "get_ground_asset_key_for_cell"),
\t\tiso_origin,
\t\tget_iso_tile_half_size()
\t)''',
}

for function_name, replacement in replacements.items():
    source = replace_function(source, function_name, replacement)

PATH.write_text(source, encoding="utf-8")
print("Applied FloorRenderer extraction")
