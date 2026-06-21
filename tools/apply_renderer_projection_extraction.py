from pathlib import Path
import re

path = Path(__file__).resolve().parents[1] / "scripts/field/room_visual_renderer.gd"
source = path.read_text(encoding="utf-8")

preload_marker = 'const VisualAssetCatalogScript = preload("res://scripts/visual/visual_asset_catalog.gd")\n'
preloads = '''const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
'''
assert preload_marker in source
if preloads not in source:
    source = source.replace(preload_marker, preload_marker + preloads, 1)

old_constants = '''const ISO_PROJECTION_STANDARD: String = "standard_128x71"
const ISO_PROJECTION_CLASSIC: String = "classic_128x64" # Legacy visual option only.
const ISO_PROJECTION_PREVIEW_181: String = "preview_128x71" # Legacy serialized alias for standard_128x71.
const ISO_PROJECTION_CUSTOM: String = "custom_export_values"
const ISO_STANDARD_TILE_SIZE: Vector2 = Vector2(128.0, 71.0)
const ISO_CLASSIC_TILE_SIZE: Vector2 = Vector2(128.0, 64.0)
'''
new_constants = '''const ISO_PROJECTION_STANDARD: String = IsoProjectionServiceRef.PROJECTION_STANDARD
const ISO_PROJECTION_CLASSIC: String = IsoProjectionServiceRef.PROJECTION_CLASSIC # Legacy visual option only.
const ISO_PROJECTION_PREVIEW_181: String = IsoProjectionServiceRef.PROJECTION_PREVIEW_181 # Legacy serialized alias for standard_128x71.
const ISO_PROJECTION_CUSTOM: String = IsoProjectionServiceRef.PROJECTION_CUSTOM
const ISO_STANDARD_TILE_SIZE: Vector2 = IsoProjectionServiceRef.STANDARD_TILE_SIZE
const ISO_CLASSIC_TILE_SIZE: Vector2 = IsoProjectionServiceRef.CLASSIC_TILE_SIZE
'''
assert old_constants in source
source = source.replace(old_constants, new_constants, 1)

def replace_function(text: str, name: str, replacement: str) -> str:
    start = re.search(rf"(?m)^func {re.escape(name)}\s*\(", text)
    assert start, name
    next_function = re.search(r"(?m)^func [A-Za-z0-9_]+\s*\(", text[start.end():])
    end = start.end() + next_function.start() if next_function else len(text)
    return text[:start.start()] + replacement.rstrip() + "\n\n" + text[end:]

replacements = {
    "get_iso_projection_mode": '''func get_iso_projection_mode() -> String:
\treturn IsoProjectionServiceRef.normalize_mode(iso_projection_mode)''',
    "get_iso_tile_size": '''func get_iso_tile_size() -> Vector2:
\treturn IsoProjectionServiceRef.get_tile_size(iso_projection_mode, iso_tile_width, iso_tile_height)''',
    "get_iso_exported_tile_size_matches_active_mode": '''func get_iso_exported_tile_size_matches_active_mode() -> bool:
\treturn IsoProjectionServiceRef.exported_tile_size_matches_active_mode(iso_projection_mode, iso_tile_width, iso_tile_height)''',
    "get_iso_tile_half_size": '''func get_iso_tile_half_size() -> Vector2:
\treturn IsoProjectionServiceRef.get_tile_half_size(get_iso_tile_size(), iso_floor_projection_pitch_correction_degrees)''',
    "grid_to_iso": '''func grid_to_iso(cell: Vector2i) -> Vector2:
\treturn IsoProjectionServiceRef.grid_to_iso(cell, iso_origin, get_iso_tile_half_size())''',
    "iso_to_grid": '''func iso_to_grid(iso_position: Vector2) -> Vector2i:
\treturn IsoProjectionServiceRef.iso_to_grid(iso_position, iso_origin, get_iso_tile_half_size())''',
    "get_iso_diamond_points": '''func get_iso_diamond_points(cell: Vector2i) -> PackedVector2Array:
\treturn IsoProjectionServiceRef.get_diamond_points(cell, iso_origin, get_iso_tile_half_size())''',
    "get_iso_inset_diamond_points": '''func get_iso_inset_diamond_points(cell: Vector2i, inset: float) -> PackedVector2Array:
\treturn IsoProjectionServiceRef.get_inset_diamond_points(cell, inset, iso_origin, get_iso_tile_half_size())''',
    "get_iso_depth_key": '''func get_iso_depth_key(cell: Vector2i, local_bias: float = 0.0) -> float:
\treturn IsoProjectionServiceRef.get_depth_key(cell, iso_origin, get_iso_tile_half_size(), local_bias)''',
    "get_iso_floor_depth_key": '''func get_iso_floor_depth_key(cell: Vector2i) -> float:
\treturn IsoProjectionServiceRef.get_depth_key(cell, iso_origin, get_iso_tile_half_size())''',
    "sort_cells_by_iso_depth": '''func sort_cells_by_iso_depth(a: Vector2i, b: Vector2i) -> bool:
\treturn IsoProjectionServiceRef.sort_cells_by_depth(a, b, iso_origin, get_iso_tile_half_size())''',
}
for function_name, replacement in replacements.items():
    source = replace_function(source, function_name, replacement)

path.write_text(source, encoding="utf-8")
print("Applied RoomVisualRenderer projection extraction")
