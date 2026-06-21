#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
COMPONENT = ROOT / "scripts/visual/renderer/wall_renderer.gd"
source = RENDERER.read_text(encoding="utf-8")


def extract_const(name: str) -> str:
    match = re.search(rf"(?m)^const {re.escape(name)}(?::[^=]+)?\s*=", source)
    if not match:
        raise RuntimeError(f"missing const {name}")
    start = match.start()
    line_end = source.find("\n", match.end())
    if line_end < 0:
        return source[start:]
    block = source[start:line_end]
    braces = block.count("{") - block.count("}")
    brackets = block.count("[") - block.count("]")
    cursor = line_end + 1
    while braces > 0 or brackets > 0:
        next_end = source.find("\n", cursor)
        if next_end < 0:
            next_end = len(source)
        line = source[cursor:next_end]
        block += "\n" + line
        braces += line.count("{") - line.count("}")
        brackets += line.count("[") - line.count("]")
        cursor = next_end + 1
    return block


def extract_func(name: str) -> str:
    match = re.search(rf"(?m)^func {re.escape(name)}\s*\(", source)
    if not match:
        raise RuntimeError(f"missing func {name}")
    next_match = re.search(r"(?m)^func [A-Za-z0-9_]+\s*\(", source[match.end():])
    end = match.end() + next_match.start() if next_match else len(source)
    return source[match.start():end].rstrip()

constant_names = [
    "ISO_WALL_ASSET_PACK_DIR",
    "ISO_WALL_BREACH_OVERLAY_PACK_DIR",
    "ISO_WALL_BREACH_OVERLAY_CATALOG",
    "ISO_WALL_ASSET_EXPECTED_SIZE",
    "ISO_WALL_HEIGHT_LEVELS",
    "ISO_OUTER_WALL_HEIGHT_ORDER",
    "ISO_GRATE_WALL_HEIGHT_LEVELS",
    "ISO_TEST_WALL_HEIGHT_ORDER",
    "ISO_TEST_WALL_HEIGHT_ASSET_KEYS",
    "ISO_WALL_ASSET_CATALOG",
    "ISO_WALL_BASELINE_VISIBLE_BOUNDS",
    "ISO_WALL_HEIGHT_VISIBLE_BOUNDS",
    "ISO_TEST_WALL_VISIBLE_BOUNDS",
    "ISO_WALL_ASSET_PLACEMENT",
    "WALL_SIDE_ORDER",
    "WALL_MASS_RATIO",
    "WALL_MOUNT_BAND_RATIO",
]
constants = "\n\n".join(extract_const(name) for name in constant_names)
profiles = extract_func("get_wall_visual_profiles").replace("func get_wall_visual_profiles", "static func get_visual_profiles", 1)

component = f'''extends RefCounted
class_name WallRenderer

const GridManagerScript = preload("res://scripts/field/grid_manager.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")

{constants}

static func is_wall_tile(tile_type: int) -> bool:
\treturn tile_type == GridManagerScript.TILE_WALL

static func is_in_bounds(grid_manager: Variant, cell: Vector2i) -> bool:
\tif grid_manager == null:
\t\treturn false
\treturn cell.x >= 0 and cell.y >= 0 and cell.x < int(grid_manager.call("get_map_width")) and cell.y < int(grid_manager.call("get_map_height"))

static func is_wall_cell(grid_manager: Variant, cell: Vector2i) -> bool:
\treturn is_in_bounds(grid_manager, cell) and int(grid_manager.call("get_tile", cell)) == GridManagerScript.TILE_WALL

static func get_side_delta(side: String) -> Vector2i:
\tmatch side:
\t\t"north": return Vector2i(0, -1)
\t\t"east": return Vector2i(1, 0)
\t\t"south": return Vector2i(0, 1)
\t\t"west": return Vector2i(-1, 0)
\treturn Vector2i.ZERO

static func is_mount_neighbor_visible(tile_type: int) -> bool:
\treturn tile_type in [
\t\tGridManagerScript.TILE_FLOOR,
\t\tGridManagerScript.TILE_STEPPED_FLOOR,
\t\tGridManagerScript.TILE_DOOR,
\t\tGridManagerScript.TILE_DIGITAL_DOOR,
\t\tGridManagerScript.TILE_POWERED_GATE,
\t]

static func is_door_like_tile(tile_type: int) -> bool:
\treturn tile_type in [GridManagerScript.TILE_DOOR, GridManagerScript.TILE_DIGITAL_DOOR, GridManagerScript.TILE_POWERED_GATE]

static func get_neighbor_mask(grid_manager: Variant, cell: Vector2i) -> Dictionary:
\tvar mask: Dictionary = {{"north": false, "east": false, "south": false, "west": false}}
\tfor side in WALL_SIDE_ORDER:
\t\tmask[side] = is_wall_cell(grid_manager, cell + get_side_delta(side))
\treturn mask

static func is_outer_border_cell(grid_manager: Variant, cell: Vector2i) -> bool:
\tif grid_manager == null:
\t\treturn false
\tvar max_x: int = int(grid_manager.call("get_map_width")) - 1
\tvar max_y: int = int(grid_manager.call("get_map_height")) - 1
\tif max_x < 0 or max_y < 0:
\t\treturn false
\treturn cell.x <= 0 or cell.y <= 0 or cell.x >= max_x or cell.y >= max_y

static func get_connected_base_points(cell: Vector2i, topology: Dictionary, origin: Vector2, half_size: Vector2, inset: float) -> PackedVector2Array:
\tvar full_points: PackedVector2Array = IsoProjectionServiceRef.get_diamond_points(cell, origin, half_size)
\tvar tight_points: PackedVector2Array = IsoProjectionServiceRef.get_inset_diamond_points(cell, maxf(inset, 0.0), origin, half_size)
\tif full_points.size() < 4 or tight_points.size() < 4:
\t\treturn full_points
\tvar result: PackedVector2Array = tight_points.duplicate()
\tvar neighbors: Dictionary = Dictionary(topology.get("neighbors", {{}}))
\tif bool(neighbors.get("north", false)):
\t\tresult[3] = full_points[3]; result[0] = full_points[0]
\tif bool(neighbors.get("east", false)):
\t\tresult[0] = full_points[0]; result[1] = full_points[1]
\tif bool(neighbors.get("south", false)):
\t\tresult[1] = full_points[1]; result[2] = full_points[2]
\tif bool(neighbors.get("west", false)):
\t\tresult[2] = full_points[2]; result[3] = full_points[3]
\treturn result

static func get_base_points(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2, inset: float) -> PackedVector2Array:
\treturn get_connected_base_points(cell, get_render_topology(grid_manager, cell), origin, half_size, inset)

static func get_depth_key_for_cell(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2, inset: float) -> float:
\tvar depth_y: float = IsoProjectionServiceRef.grid_to_iso(cell, origin, half_size).y + half_size.y
\tfor point in get_base_points(grid_manager, cell, origin, half_size, inset):
\t\tdepth_y = maxf(depth_y, point.y)
\treturn depth_y

static func get_asset_catalog() -> Dictionary:
\treturn ISO_WALL_ASSET_CATALOG.duplicate(true)

static func normalize_material_asset_base_key(profile_key: String) -> String:
\treturn VisualAssetCatalogRef.resolve_wall_material_base_asset_key(profile_key)

static func normalize_asset_key(profile_key: String) -> String:
\tvar key: String = profile_key.strip_edges().to_lower().replace(" ", "_").replace("-", "_").replace("_01", "")
\tmatch key:
\t\t"gray_tallest", "wall_gray_tallest": return "wall_gray_tallest"
\t\t"gray_tall", "wall_gray_tall": return "wall_gray_tall"
\t\t"gray_mid", "wall_gray_mid": return "wall_gray_mid"
\t\t"gray_halfmid", "wall_gray_halfmid": return "wall_gray_halfmid"
\t\t"gray_low", "wall_gray_low": return "wall_gray_low"
\tif ISO_WALL_ASSET_CATALOG.has(key):
\t\treturn key
\treturn get_asset_key_for_material_and_height(normalize_material_asset_base_key(key), "mid")

static func get_material_base_key_for_row(material_row: Dictionary, fallback_profile_key: String) -> String:
\tvar texture_asset_id: String = str(material_row.get("texture_asset_id", "")).strip_edges()
\tif texture_asset_id.begins_with("wall_"):
\t\treturn normalize_material_asset_base_key(texture_asset_id)
\tvar material_id: String = str(material_row.get("id", "")).strip_edges()
\treturn normalize_material_asset_base_key(material_id if not material_id.is_empty() else fallback_profile_key)

static func get_asset_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:
\tvar base_key: String = get_material_base_key_for_row(material_row, fallback_profile_key)
\tvar height: String = normalize_height_level(str(material_row.get("wall_height", material_row.get("wall_visual_height", ""))))
\treturn get_asset_key_for_material_and_height(base_key, "mid" if height.is_empty() else height)

static func normalize_test_height(value: String) -> String:
\tvar key: String = value.strip_edges().to_lower().replace(" ", "").replace("-", "").replace("_", "")
\tmatch key:
\t\t"auto", "", "default": return ""
\t\t"highest", "tallest": return "tallest"
\t\t"high", "tall": return "tall"
\t\t"medium", "middle", "mid": return "mid"
\t\t"halfmid", "halfmedium", "half", "halflow", "halflowmedium", "halflowest", "halflowheight": return "halfmid"
\t\t"short", "lowest", "low": return "low"
\treturn ""

static func normalize_height_level(value: String) -> String:
\treturn WallHeightCatalogRef.normalize_wall_height(value, "")

static func normalize_height_for_material(base_key: String, height_level: String) -> String:
\treturn VisualAssetCatalogRef.normalize_wall_height_for_asset_base(base_key, normalize_height_level(height_level))

static func get_asset_key_for_material_and_height(material_asset_key: String, height_level: String) -> String:
\treturn VisualAssetCatalogRef.resolve_wall_asset_key_for_material_and_height(material_asset_key, normalize_height_level(height_level))

static func get_raw_height_value(wall_data: Dictionary) -> String:
\tvar material_data: Dictionary = Dictionary(wall_data.get("material", {{}}))
\tvar override_data: Dictionary = Dictionary(wall_data.get("override", {{}}))
\tvar raw_height: String = str(material_data.get("wall_height", material_data.get("wall_visual_height", "")))
\tif raw_height.is_empty(): raw_height = str(override_data.get("wall_height", override_data.get("wall_visual_height", "")))
\tif raw_height.is_empty(): raw_height = str(wall_data.get("wall_height", wall_data.get("wall_visual_height", "")))
\treturn raw_height

static func get_depth_bounds(grid_manager: Variant) -> Dictionary:
\tif grid_manager == null:
\t\treturn {{"min_depth": 0, "max_depth": 0, "wall_count": 0}}
\tvar min_depth: int = 0
\tvar max_depth: int = 0
\tvar wall_count: int = 0
\tfor y in range(int(grid_manager.call("get_map_height"))):
\t\tfor x in range(int(grid_manager.call("get_map_width"))):
\t\t\tvar cell: Vector2i = Vector2i(x, y)
\t\t\tif not is_wall_cell(grid_manager, cell): continue
\t\t\tvar depth: int = x + y
\t\t\tif wall_count == 0: min_depth = depth; max_depth = depth
\t\t\telse: min_depth = mini(min_depth, depth); max_depth = maxi(max_depth, depth)
\t\t\twall_count += 1
\treturn {{"min_depth": min_depth, "max_depth": max_depth, "wall_count": wall_count}}

static func _resolve_depth_band(cell: Vector2i, bounds: Dictionary, order: Array[String], fallback: String) -> String:
\tvar min_depth: int = int(bounds.get("min_depth", cell.x + cell.y))
\tvar max_depth: int = int(bounds.get("max_depth", cell.x + cell.y))
\tvar span: int = maxi(max_depth - min_depth, 0)
\tif span <= 0: return fallback
\tvar index: int = clampi(cell.x + cell.y - min_depth, 0, span)
\tvar band: int = clampi(int(floor(float(index) * float(order.size()) / float(span + 1))), 0, order.size() - 1)
\treturn order[band]

static func resolve_auto_test_height(cell: Vector2i, bounds: Dictionary) -> String:
\treturn _resolve_depth_band(cell, bounds, ISO_TEST_WALL_HEIGHT_ORDER, "mid")

static func resolve_outer_height(cell: Vector2i, bounds: Dictionary) -> String:
\treturn _resolve_depth_band(cell, bounds, ISO_OUTER_WALL_HEIGHT_ORDER, "mid")

static func get_production_height_level(wall_data: Dictionary, cell: Vector2i, material_asset_key: String, bounds: Dictionary) -> String:
\tvar height: String = normalize_height_level(get_raw_height_value(wall_data))
\tvar base_key: String = normalize_material_asset_base_key(material_asset_key)
\tif height.is_empty(): height = resolve_outer_height(cell, bounds) if base_key == "wall_outer" else "mid"
\treturn normalize_height_for_material(base_key, height)

static func get_production_asset_key(wall_data: Dictionary, cell: Vector2i, fallback_profile_key: String, bounds: Dictionary) -> String:
\tvar base_key: String = get_material_base_key_for_row(Dictionary(wall_data.get("material", {{}})), fallback_profile_key)
\treturn get_asset_key_for_material_and_height(base_key, get_production_height_level(wall_data, cell, base_key, bounds))

static func get_test_height_asset_key(wall_data: Dictionary, cell: Vector2i, bounds: Dictionary) -> String:
\tvar height: String = normalize_test_height(get_raw_height_value(wall_data))
\tif height.is_empty(): height = resolve_auto_test_height(cell, bounds)
\treturn str(ISO_TEST_WALL_HEIGHT_ASSET_KEYS.get(height, "wall_gray_mid"))

static func get_asset_placement(asset_key: String, source_size: Vector2, tile_size: Vector2) -> Dictionary:
\tvar placement: Dictionary = Dictionary(ISO_WALL_ASSET_PLACEMENT.get(normalize_asset_key(asset_key), {{}})).duplicate(true)
\tif placement.is_empty():
\t\tplacement = {{"visible_bounds": Rect2(Vector2.ZERO, source_size), "target_base_width": tile_size.x, "target_height": ISO_WALL_ASSET_EXPECTED_SIZE.y, "scale": 1.0, "offset": Vector2.ZERO}}
\treturn placement

static func should_mirror_asset_for_topology(_topology: Dictionary) -> bool:
\treturn false

static func is_breachable_material_id(material_id: String) -> bool:
\treturn SurfaceMaterialCatalogRef.is_breachable_wall_material(material_id)

static func get_normalized_breachable_height(wall_data: Dictionary) -> String:
\tvar height: String = normalize_height_level(get_raw_height_value(wall_data))
\tif height.is_empty(): height = "mid"
\treturn "low" if height in ["low", "halflow"] else height

static func get_default_visual_profile_key() -> String:
\treturn "default_wall"

{profiles}

static func normalize_visual_profile_key(profile_key: String) -> String:
\tvar key: String = profile_key.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
\treturn key if get_visual_profiles().has(key) else get_default_visual_profile_key()

static func get_visual_profile(profile_key: String) -> Dictionary:
\tvar profiles: Dictionary = get_visual_profiles()
\treturn Dictionary(profiles.get(normalize_visual_profile_key(profile_key), profiles[get_default_visual_profile_key()])).duplicate(true)

static func map_metadata_value_to_profile(raw_value: String) -> String:
\tvar value: String = raw_value.strip_edges().to_lower()
\tvar direct_map: Dictionary = {{
\t\t"outer_wall":"outer_wall", "grate_wall":"grate_wall", "brick_wall":"brick_wall", "concrete_wall":"concrete_wall",
\t\t"steel_wall":"steel_wall", "reinforced_steel_wall":"reinforced_steel_wall", "titanium_wall":"titanium_wall",
\t\t"energy_wall":"energy_wall", "damaged_wall":"damaged_wall", "brick":"brick_wall", "breachable_brick":"brick_wall",
\t\t"concrete":"concrete_wall", "breachable_concrete":"concrete_wall", "steel":"steel_wall",
\t\t"reinforced_steel":"reinforced_steel_wall", "titanium":"titanium_wall", "energy_flow":"energy_wall"
\t}}
\treturn str(direct_map.get(value, ""))

static func get_profile_from_tags(tags_variant: Variant) -> String:
\tif not (tags_variant is Array): return ""
\tfor value in Array(tags_variant):
\t\tvar mapped: String = map_metadata_value_to_profile(str(value))
\t\tif not mapped.is_empty(): return mapped
\treturn ""

static func get_object_type_for_metadata(metadata: Dictionary) -> String:
\tif metadata.is_empty(): return ""
\tvar tag_profile: String = get_profile_from_tags(metadata.get("tags", []))
\tif not tag_profile.is_empty(): return tag_profile
\tfor candidate in [metadata.get("visual_profile", ""), metadata.get("wall_type", ""), metadata.get("object_type", ""), metadata.get("type", ""), metadata.get("catalog_id", ""), metadata.get("id", ""), metadata.get("material", "")]:
\t\tvar mapped: String = map_metadata_value_to_profile(str(candidate))
\t\tif not mapped.is_empty(): return mapped
\treturn ""

static func get_visual_profile_key_for_cell(grid_manager: Variant, cell: Vector2i, metadata: Dictionary = {{}}) -> String:
\tif not is_wall_cell(grid_manager, cell): return ""
\tvar object_type: String = get_object_type_for_metadata(metadata)
\tif not object_type.is_empty(): return object_type
\treturn "outer_wall" if is_outer_border_cell(grid_manager, cell) else "concrete_wall"

static func get_visible_sides(grid_manager: Variant, cell: Vector2i) -> Array[String]:
\tvar sides: Array[String] = []
\tif not is_wall_cell(grid_manager, cell): return sides
\tfor side in WALL_SIDE_ORDER:
\t\tvar neighbor: Vector2i = cell + get_side_delta(side)
\t\tif not is_in_bounds(grid_manager, neighbor): sides.append(side); continue
\t\tvar tile_type: int = int(grid_manager.call("get_tile", neighbor))
\t\tif tile_type != GridManagerScript.TILE_WALL and is_mount_neighbor_visible(tile_type): sides.append(side)
\treturn sides

static func get_mounted_anchor_zones(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2) -> Array[Dictionary]:
\tvar zones: Array[Dictionary] = []
\tif not is_wall_cell(grid_manager, cell): return zones
\tfor side in get_visible_sides(grid_manager, cell):
\t\tvar delta: Vector2i = get_side_delta(side)
\t\tvar neighbor: Vector2i = cell + delta
\t\tvar mountable: bool = false
\t\tif is_in_bounds(grid_manager, neighbor):
\t\t\tvar tile_type: int = int(grid_manager.call("get_tile", neighbor))
\t\t\tmountable = is_mount_neighbor_visible(tile_type) and not is_door_like_tile(tile_type)
\t\tvar wall_center: Vector2 = IsoProjectionServiceRef.grid_to_iso(cell, origin, half_size)
\t\tvar axis: Vector2 = Vector2(float(delta.x) * half_size.x * 0.65, float(delta.y) * half_size.y * 0.65)
\t\tvar center: Vector2 = wall_center + axis
\t\tvar tangent: Vector2 = Vector2(-axis.y, axis.x).normalized() * 7.0
\t\tvar normal: Vector2 = axis.normalized() * 5.0
\t\tzones.append({{"attached_wall_cell":cell, "anchor_floor_cell":neighbor, "wall_side":side, "visible":true, "mountable":mountable, "wall_mass_ratio":WALL_MASS_RATIO, "mount_band_ratio":WALL_MOUNT_BAND_RATIO, "mount_zone_center":center, "mount_zone_polygon":PackedVector2Array([center-tangent-normal, center+tangent-normal, center+tangent+normal, center-tangent+normal]), "interaction_cell":neighbor}})
\treturn zones

static func get_render_topology(grid_manager: Variant, cell: Vector2i) -> Dictionary:
\tvar neighbors: Dictionary = get_neighbor_mask(grid_manager, cell)
\tvar visible_sides: Array[String] = get_visible_sides(grid_manager, cell)
\tvar cap_sides: Array[String] = []
\tvar mountable_sides: Array[String] = []
\tif not is_wall_cell(grid_manager, cell): return {{"cell":cell, "neighbors":neighbors, "run_x":false, "run_y":false, "shape":"unknown", "visible_sides":visible_sides, "cap_sides":cap_sides, "mountable_sides":mountable_sides}}
\tvar north: bool = bool(neighbors.north); var east: bool = bool(neighbors.east); var south: bool = bool(neighbors.south); var west: bool = bool(neighbors.west)
\tvar count: int = int(north) + int(east) + int(south) + int(west)
\tvar run_x: bool = east and west; var run_y: bool = north and south; var shape: String = "isolated"
\tfor side in WALL_SIDE_ORDER:
\t\tif not bool(neighbors.get(side, false)): cap_sides.append(side)
\tfor side in visible_sides:
\t\tvar neighbor_cell: Vector2i = cell + get_side_delta(side)
\t\tif not is_in_bounds(grid_manager, neighbor_cell): continue
\t\tvar tile_type: int = int(grid_manager.call("get_tile", neighbor_cell))
\t\tif is_mount_neighbor_visible(tile_type) and not is_door_like_tile(tile_type): mountable_sides.append(side)
\tif count == 4: shape = "cross"
\telif count == 3: shape = "t_junction"
\telif count == 1: shape = "end_cap_south" if north else ("end_cap_west" if east else ("end_cap_north" if south else "end_cap_east"))
\telif run_x: shape = "straight_x"
\telif run_y: shape = "straight_y"
\telif north and east: shape = "inner_corner_ne" if is_wall_cell(grid_manager, cell + Vector2i(1, -1)) else "outer_corner_ne"
\telif north and west: shape = "inner_corner_nw" if is_wall_cell(grid_manager, cell + Vector2i(-1, -1)) else "outer_corner_nw"
\telif south and east: shape = "inner_corner_se" if is_wall_cell(grid_manager, cell + Vector2i(1, 1)) else "outer_corner_se"
\telif south and west: shape = "inner_corner_sw" if is_wall_cell(grid_manager, cell + Vector2i(-1, 1)) else "outer_corner_sw"
\treturn {{"cell":cell, "neighbors":neighbors, "run_x":run_x, "run_y":run_y, "shape":shape, "visible_sides":visible_sides, "cap_sides":cap_sides, "mountable_sides":mountable_sides}}

static func build_draw_entries(grid_manager: Variant, origin: Vector2, half_size: Vector2, inset: float) -> Array[Dictionary]:
\tvar entries: Array[Dictionary] = []
\tif grid_manager == null: return entries
\tfor y in range(int(grid_manager.call("get_map_height"))):
\t\tfor x in range(int(grid_manager.call("get_map_width"))):
\t\t\tvar cell: Vector2i = Vector2i(x, y)
\t\t\tvar tile_type: int = int(grid_manager.call("get_tile", cell))
\t\t\tif not is_wall_tile(tile_type): continue
\t\t\tentries.append(IsoDrawEntryContractRef.make_entry(cell, "wall", "wall_body", get_depth_key_for_cell(grid_manager, cell, origin, half_size, inset), IsoDrawEntryContractRef.SUB_ORDER_WALL_BODY, {{"tile_type":tile_type}}, IsoDrawEntryContractRef.LAYER_BIAS_WALL))
\treturn entries
'''

COMPONENT.parent.mkdir(parents=True, exist_ok=True)
COMPONENT.write_text(component, encoding="utf-8")

# Patch coordinator.
preload_marker = 'const FloorRendererRef = preload("res://scripts/visual/renderer/floor_renderer.gd")\n'
if 'wall_renderer.gd' not in source:
    source = source.replace(preload_marker, preload_marker + 'const WallRendererRef = preload("res://scripts/visual/renderer/wall_renderer.gd")\n', 1)


def replace_const(text: str, name: str) -> str:
    block = extract_const(name)
    type_match = re.match(rf"const {re.escape(name)}(?P<type>:[^=]+)?\s*=", block)
    type_text = type_match.group("type") or ""
    return text.replace(block, f"const {name}{type_text} = WallRendererRef.{name}", 1)

for name in constant_names:
    source = replace_const(source, name)


def replace_func(text: str, name: str, replacement: str) -> str:
    old = extract_func(name)
    if old not in text:
        raise RuntimeError(f"function block missing during patch: {name}")
    return text.replace(old, replacement.rstrip(), 1)

delegates = {
    "is_wall_tile": '''func is_wall_tile(tile_type: int) -> bool:\n\treturn WallRendererRef.is_wall_tile(tile_type)''',
    "_get_wall_side_delta": '''func _get_wall_side_delta(side: String) -> Vector2i:\n\treturn WallRendererRef.get_side_delta(side)''',
    "_is_wall_in_bounds": '''func _is_wall_in_bounds(cell: Vector2i) -> bool:\n\treturn WallRendererRef.is_in_bounds(_grid_manager, cell)''',
    "_is_wall_cell": '''func _is_wall_cell(cell: Vector2i) -> bool:\n\treturn WallRendererRef.is_wall_cell(_grid_manager, cell)''',
    "_get_wall_neighbor_mask": '''func _get_wall_neighbor_mask(cell: Vector2i) -> Dictionary:\n\treturn WallRendererRef.get_neighbor_mask(_grid_manager, cell)''',
    "_is_wall_mount_neighbor_visible": '''func _is_wall_mount_neighbor_visible(tile_type: int) -> bool:\n\treturn WallRendererRef.is_mount_neighbor_visible(tile_type)''',
    "_is_door_like_tile": '''func _is_door_like_tile(tile_type: int) -> bool:\n\treturn WallRendererRef.is_door_like_tile(tile_type)''',
    "is_outer_border_cell": '''func is_outer_border_cell(cell: Vector2i) -> bool:\n\treturn WallRendererRef.is_outer_border_cell(_grid_manager, cell)''',
    "get_iso_wall_connected_base_points": '''func get_iso_wall_connected_base_points(cell: Vector2i, topology: Dictionary) -> PackedVector2Array:\n\treturn WallRendererRef.get_connected_base_points(cell, topology, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)''',
    "get_iso_wall_base_points": '''func get_iso_wall_base_points(cell: Vector2i) -> PackedVector2Array:\n\treturn WallRendererRef.get_base_points(_grid_manager, cell, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)''',
    "get_iso_wall_depth_key_for_cell": '''func get_iso_wall_depth_key_for_cell(cell: Vector2i) -> float:\n\treturn WallRendererRef.get_depth_key_for_cell(_grid_manager, cell, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)''',
    "get_iso_wall_asset_key_for_profile": '''func get_iso_wall_asset_key_for_profile(profile_key: String) -> String:\n\treturn WallRendererRef.normalize_asset_key(profile_key)''',
    "get_iso_wall_asset_catalog": '''func get_iso_wall_asset_catalog() -> Dictionary:\n\treturn WallRendererRef.get_asset_catalog()''',
    "normalize_wall_material_asset_base_key": '''func normalize_wall_material_asset_base_key(profile_key: String) -> String:\n\treturn WallRendererRef.normalize_material_asset_base_key(profile_key)''',
    "normalize_wall_asset_key": '''func normalize_wall_asset_key(profile_key: String) -> String:\n\treturn WallRendererRef.normalize_asset_key(profile_key)''',
    "get_iso_wall_material_base_key_for_material_row": '''func get_iso_wall_material_base_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:\n\treturn WallRendererRef.get_material_base_key_for_row(material_row, fallback_profile_key)''',
    "get_iso_wall_asset_key_for_material_row": '''func get_iso_wall_asset_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:\n\treturn WallRendererRef.get_asset_key_for_material_row(material_row, fallback_profile_key)''',
    "normalize_test_wall_height": '''func normalize_test_wall_height(value: String) -> String:\n\treturn WallRendererRef.normalize_test_height(value)''',
    "normalize_wall_height_level": '''func normalize_wall_height_level(value: String) -> String:\n\treturn WallRendererRef.normalize_height_level(value)''',
    "normalize_wall_height_level_for_material": '''func normalize_wall_height_level_for_material(base_key: String, height_level: String) -> String:\n\treturn WallRendererRef.normalize_height_for_material(base_key, height_level)''',
    "get_wall_asset_key_for_material_and_height": '''func get_wall_asset_key_for_material_and_height(material_asset_key: String, height_level: String) -> String:\n\treturn WallRendererRef.get_asset_key_for_material_and_height(material_asset_key, height_level)''',
    "get_raw_wall_height_value": '''func get_raw_wall_height_value(wall_data: Dictionary) -> String:\n\treturn WallRendererRef.get_raw_height_value(wall_data)''',
    "get_iso_wall_depth_bounds": '''func get_iso_wall_depth_bounds() -> Dictionary:\n\treturn WallRendererRef.get_depth_bounds(_grid_manager)''',
    "resolve_auto_test_wall_height": '''func resolve_auto_test_wall_height(cell: Vector2i, map_bounds: Dictionary = {}) -> String:\n\treturn WallRendererRef.resolve_auto_test_height(cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())''',
    "resolve_outer_wall_height_level": '''func resolve_outer_wall_height_level(cell: Vector2i, map_bounds: Dictionary = {}) -> String:\n\treturn WallRendererRef.resolve_outer_height(cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())''',
    "get_production_wall_height_level": '''func get_production_wall_height_level(wall_data: Dictionary, cell: Vector2i, material_asset_key: String, map_bounds: Dictionary = {}) -> String:\n\treturn WallRendererRef.get_production_height_level(wall_data, cell, material_asset_key, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())''',
    "get_production_wall_asset_key": '''func get_production_wall_asset_key(wall_data: Dictionary, cell: Vector2i, fallback_profile_key: String, map_bounds: Dictionary = {}) -> String:\n\treturn WallRendererRef.get_production_asset_key(wall_data, cell, fallback_profile_key, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())''',
    "get_test_wall_height_asset_key": '''func get_test_wall_height_asset_key(wall_data: Dictionary, cell: Vector2i, map_bounds: Dictionary = {}) -> String:\n\treturn WallRendererRef.get_test_height_asset_key(wall_data, cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())''',
    "get_iso_wall_asset_placement": '''func get_iso_wall_asset_placement(asset_key: String, source_size: Vector2) -> Dictionary:\n\treturn WallRendererRef.get_asset_placement(asset_key, source_size, get_iso_tile_size())''',
    "should_mirror_iso_wall_asset_for_topology": '''func should_mirror_iso_wall_asset_for_topology(topology: Dictionary) -> bool:\n\treturn WallRendererRef.should_mirror_asset_for_topology(topology)''',
    "is_breachable_wall_material_id": '''func is_breachable_wall_material_id(material_id: String) -> bool:\n\treturn WallRendererRef.is_breachable_material_id(material_id)''',
    "get_normalized_breachable_wall_height": '''func get_normalized_breachable_wall_height(wall_data: Dictionary) -> String:\n\treturn WallRendererRef.get_normalized_breachable_height(wall_data)''',
    "get_default_wall_visual_profile_key": '''func get_default_wall_visual_profile_key() -> String:\n\treturn WallRendererRef.get_default_visual_profile_key()''',
    "normalize_wall_visual_profile_key": '''func normalize_wall_visual_profile_key(profile_key: String) -> String:\n\treturn WallRendererRef.normalize_visual_profile_key(profile_key)''',
    "get_wall_visual_profiles": '''func get_wall_visual_profiles() -> Dictionary:\n\treturn WallRendererRef.get_visual_profiles()''',
    "get_wall_visual_profile": '''func get_wall_visual_profile(profile_key: String) -> Dictionary:\n\treturn WallRendererRef.get_visual_profile(profile_key)''',
    "map_wall_metadata_value_to_profile": '''func map_wall_metadata_value_to_profile(raw_value: String) -> String:\n\treturn WallRendererRef.map_metadata_value_to_profile(raw_value)''',
    "get_wall_profile_from_tags": '''func get_wall_profile_from_tags(tags_variant: Variant) -> String:\n\treturn WallRendererRef.get_profile_from_tags(tags_variant)''',
    "get_wall_object_type_for_cell": '''func get_wall_object_type_for_cell(cell: Vector2i) -> String:\n\treturn WallRendererRef.get_object_type_for_metadata(get_wall_metadata_for_cell(cell))''',
    "get_wall_visual_profile_key_for_cell": '''func get_wall_visual_profile_key_for_cell(cell: Vector2i) -> String:\n\treturn WallRendererRef.get_visual_profile_key_for_cell(_grid_manager, cell, get_wall_metadata_for_cell(cell))''',
    "get_visible_wall_sides": '''func get_visible_wall_sides(cell: Vector2i) -> Array[String]:\n\treturn WallRendererRef.get_visible_sides(_grid_manager, cell)''',
    "get_wall_mounted_anchor_zones": '''func get_wall_mounted_anchor_zones(cell: Vector2i) -> Array[Dictionary]:\n\treturn WallRendererRef.get_mounted_anchor_zones(_grid_manager, cell, iso_origin, get_iso_tile_half_size())''',
    "get_wall_render_topology": '''func get_wall_render_topology(cell: Vector2i) -> Dictionary:\n\treturn WallRendererRef.get_render_topology(_grid_manager, cell)''',
    "build_iso_wall_draw_entries": '''func build_iso_wall_draw_entries() -> Array[Dictionary]:\n\treturn WallRendererRef.build_draw_entries(_grid_manager, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)''',
}
for name, replacement in delegates.items():
    source = replace_func(source, name, replacement)

RENDERER.write_text(source, encoding="utf-8")
print("Generated WallRenderer and patched RoomVisualRenderer")
