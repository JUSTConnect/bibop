extends RefCounted
class_name WallRenderer

const GridManagerScript = preload("res://scripts/field/grid_manager.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")

const ISO_WALL_ASSET_PACK_DIR: String   = WallRendererRef.ISO_WALL_ASSET_PACK_DIR

const ISO_WALL_BREACH_OVERLAY_PACK_DIR: String   = WallRendererRef.ISO_WALL_BREACH_OVERLAY_PACK_DIR

const ISO_WALL_BREACH_OVERLAY_CATALOG: Dictionary   = WallRendererRef.ISO_WALL_BREACH_OVERLAY_CATALOG

const ISO_WALL_ASSET_EXPECTED_SIZE: Vector2   = WallRendererRef.ISO_WALL_ASSET_EXPECTED_SIZE

const ISO_WALL_HEIGHT_LEVELS: Array[String]   = WallRendererRef.ISO_WALL_HEIGHT_LEVELS

const ISO_OUTER_WALL_HEIGHT_ORDER: Array[String]   = WallRendererRef.ISO_OUTER_WALL_HEIGHT_ORDER

const ISO_GRATE_WALL_HEIGHT_LEVELS: Array[String]   = WallRendererRef.ISO_GRATE_WALL_HEIGHT_LEVELS

const ISO_TEST_WALL_HEIGHT_ORDER: Array[String]   = WallRendererRef.ISO_TEST_WALL_HEIGHT_ORDER

const ISO_TEST_WALL_HEIGHT_ASSET_KEYS: Dictionary   = WallRendererRef.ISO_TEST_WALL_HEIGHT_ASSET_KEYS

const ISO_WALL_ASSET_CATALOG: Dictionary   = WallRendererRef.ISO_WALL_ASSET_CATALOG

const ISO_WALL_BASELINE_VISIBLE_BOUNDS: Rect2   = WallRendererRef.ISO_WALL_BASELINE_VISIBLE_BOUNDS

const ISO_WALL_HEIGHT_VISIBLE_BOUNDS: Dictionary   = WallRendererRef.ISO_WALL_HEIGHT_VISIBLE_BOUNDS

const ISO_TEST_WALL_VISIBLE_BOUNDS: Dictionary   = WallRendererRef.ISO_TEST_WALL_VISIBLE_BOUNDS

const ISO_WALL_ASSET_PLACEMENT: Dictionary   = WallRendererRef.ISO_WALL_ASSET_PLACEMENT

const WALL_SIDE_ORDER: Array[String]   = WallRendererRef.WALL_SIDE_ORDER

const WALL_MASS_RATIO: float   = WallRendererRef.WALL_MASS_RATIO

const WALL_MOUNT_BAND_RATIO: float   = WallRendererRef.WALL_MOUNT_BAND_RATIO

static func is_wall_tile(tile_type: int) -> bool:
	return tile_type == GridManagerScript.TILE_WALL

static func is_in_bounds(grid_manager: Variant, cell: Vector2i) -> bool:
	if grid_manager == null:
		return false
	return cell.x >= 0 and cell.y >= 0 and cell.x < int(grid_manager.call("get_map_width")) and cell.y < int(grid_manager.call("get_map_height"))

static func is_wall_cell(grid_manager: Variant, cell: Vector2i) -> bool:
	return is_in_bounds(grid_manager, cell) and int(grid_manager.call("get_tile", cell)) == GridManagerScript.TILE_WALL

static func get_side_delta(side: String) -> Vector2i:
	match side:
		"north": return Vector2i(0, -1)
		"east": return Vector2i(1, 0)
		"south": return Vector2i(0, 1)
		"west": return Vector2i(-1, 0)
	return Vector2i.ZERO

static func is_mount_neighbor_visible(tile_type: int) -> bool:
	return tile_type in [
		GridManagerScript.TILE_FLOOR,
		GridManagerScript.TILE_STEPPED_FLOOR,
		GridManagerScript.TILE_DOOR,
		GridManagerScript.TILE_DIGITAL_DOOR,
		GridManagerScript.TILE_POWERED_GATE,
	]

static func is_door_like_tile(tile_type: int) -> bool:
	return tile_type in [GridManagerScript.TILE_DOOR, GridManagerScript.TILE_DIGITAL_DOOR, GridManagerScript.TILE_POWERED_GATE]

static func get_neighbor_mask(grid_manager: Variant, cell: Vector2i) -> Dictionary:
	var mask: Dictionary = {"north": false, "east": false, "south": false, "west": false}
	for side in WALL_SIDE_ORDER:
		mask[side] = is_wall_cell(grid_manager, cell + get_side_delta(side))
	return mask

static func is_outer_border_cell(grid_manager: Variant, cell: Vector2i) -> bool:
	if grid_manager == null:
		return false
	var max_x: int = int(grid_manager.call("get_map_width")) - 1
	var max_y: int = int(grid_manager.call("get_map_height")) - 1
	if max_x < 0 or max_y < 0:
		return false
	return cell.x <= 0 or cell.y <= 0 or cell.x >= max_x or cell.y >= max_y

static func get_connected_base_points(cell: Vector2i, topology: Dictionary, origin: Vector2, half_size: Vector2, inset: float) -> PackedVector2Array:
	var full_points: PackedVector2Array = IsoProjectionServiceRef.get_diamond_points(cell, origin, half_size)
	var tight_points: PackedVector2Array = IsoProjectionServiceRef.get_inset_diamond_points(cell, maxf(inset, 0.0), origin, half_size)
	if full_points.size() < 4 or tight_points.size() < 4:
		return full_points
	var result: PackedVector2Array = tight_points.duplicate()
	var neighbors: Dictionary = Dictionary(topology.get("neighbors", {}))
	if bool(neighbors.get("north", false)):
		result[3] = full_points[3]; result[0] = full_points[0]
	if bool(neighbors.get("east", false)):
		result[0] = full_points[0]; result[1] = full_points[1]
	if bool(neighbors.get("south", false)):
		result[1] = full_points[1]; result[2] = full_points[2]
	if bool(neighbors.get("west", false)):
		result[2] = full_points[2]; result[3] = full_points[3]
	return result

static func get_base_points(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2, inset: float) -> PackedVector2Array:
	return get_connected_base_points(cell, get_render_topology(grid_manager, cell), origin, half_size, inset)

static func get_depth_key_for_cell(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2, inset: float) -> float:
	var depth_y: float = IsoProjectionServiceRef.grid_to_iso(cell, origin, half_size).y + half_size.y
	for point in get_base_points(grid_manager, cell, origin, half_size, inset):
		depth_y = maxf(depth_y, point.y)
	return depth_y

static func get_asset_catalog() -> Dictionary:
	return ISO_WALL_ASSET_CATALOG.duplicate(true)

static func normalize_material_asset_base_key(profile_key: String) -> String:
	return VisualAssetCatalogRef.resolve_wall_material_base_asset_key(profile_key)

static func normalize_asset_key(profile_key: String) -> String:
	var key: String = profile_key.strip_edges().to_lower().replace(" ", "_").replace("-", "_").replace("_01", "")
	match key:
		"gray_tallest", "wall_gray_tallest": return "wall_gray_tallest"
		"gray_tall", "wall_gray_tall": return "wall_gray_tall"
		"gray_mid", "wall_gray_mid": return "wall_gray_mid"
		"gray_halfmid", "wall_gray_halfmid": return "wall_gray_halfmid"
		"gray_low", "wall_gray_low": return "wall_gray_low"
	if ISO_WALL_ASSET_CATALOG.has(key):
		return key
	return get_asset_key_for_material_and_height(normalize_material_asset_base_key(key), "mid")

static func get_material_base_key_for_row(material_row: Dictionary, fallback_profile_key: String) -> String:
	var texture_asset_id: String = str(material_row.get("texture_asset_id", "")).strip_edges()
	if texture_asset_id.begins_with("wall_"):
		return normalize_material_asset_base_key(texture_asset_id)
	var material_id: String = str(material_row.get("id", "")).strip_edges()
	return normalize_material_asset_base_key(material_id if not material_id.is_empty() else fallback_profile_key)

static func get_asset_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:
	var base_key: String = get_material_base_key_for_row(material_row, fallback_profile_key)
	var height: String = normalize_height_level(str(material_row.get("wall_height", material_row.get("wall_visual_height", ""))))
	return get_asset_key_for_material_and_height(base_key, "mid" if height.is_empty() else height)

static func normalize_test_height(value: String) -> String:
	var key: String = value.strip_edges().to_lower().replace(" ", "").replace("-", "").replace("_", "")
	match key:
		"auto", "", "default": return ""
		"highest", "tallest": return "tallest"
		"high", "tall": return "tall"
		"medium", "middle", "mid": return "mid"
		"halfmid", "halfmedium", "half", "halflow", "halflowmedium", "halflowest", "halflowheight": return "halfmid"
		"short", "lowest", "low": return "low"
	return ""

static func normalize_height_level(value: String) -> String:
	return WallHeightCatalogRef.normalize_wall_height(value, "")

static func normalize_height_for_material(base_key: String, height_level: String) -> String:
	return VisualAssetCatalogRef.normalize_wall_height_for_asset_base(base_key, normalize_height_level(height_level))

static func get_asset_key_for_material_and_height(material_asset_key: String, height_level: String) -> String:
	return VisualAssetCatalogRef.resolve_wall_asset_key_for_material_and_height(material_asset_key, normalize_height_level(height_level))

static func get_raw_height_value(wall_data: Dictionary) -> String:
	var material_data: Dictionary = Dictionary(wall_data.get("material", {}))
	var override_data: Dictionary = Dictionary(wall_data.get("override", {}))
	var raw_height: String = str(material_data.get("wall_height", material_data.get("wall_visual_height", "")))
	if raw_height.is_empty(): raw_height = str(override_data.get("wall_height", override_data.get("wall_visual_height", "")))
	if raw_height.is_empty(): raw_height = str(wall_data.get("wall_height", wall_data.get("wall_visual_height", "")))
	return raw_height

static func get_depth_bounds(grid_manager: Variant) -> Dictionary:
	if grid_manager == null:
		return {"min_depth": 0, "max_depth": 0, "wall_count": 0}
	var min_depth: int = 0
	var max_depth: int = 0
	var wall_count: int = 0
	for y in range(int(grid_manager.call("get_map_height"))):
		for x in range(int(grid_manager.call("get_map_width"))):
			var cell: Vector2i = Vector2i(x, y)
			if not is_wall_cell(grid_manager, cell): continue
			var depth: int = x + y
			if wall_count == 0: min_depth = depth; max_depth = depth
			else: min_depth = mini(min_depth, depth); max_depth = maxi(max_depth, depth)
			wall_count += 1
	return {"min_depth": min_depth, "max_depth": max_depth, "wall_count": wall_count}

static func _resolve_depth_band(cell: Vector2i, bounds: Dictionary, order: Array[String], fallback: String) -> String:
	var min_depth: int = int(bounds.get("min_depth", cell.x + cell.y))
	var max_depth: int = int(bounds.get("max_depth", cell.x + cell.y))
	var span: int = maxi(max_depth - min_depth, 0)
	if span <= 0: return fallback
	var index: int = clampi(cell.x + cell.y - min_depth, 0, span)
	var band: int = clampi(int(floor(float(index) * float(order.size()) / float(span + 1))), 0, order.size() - 1)
	return order[band]

static func resolve_auto_test_height(cell: Vector2i, bounds: Dictionary) -> String:
	return _resolve_depth_band(cell, bounds, ISO_TEST_WALL_HEIGHT_ORDER, "mid")

static func resolve_outer_height(cell: Vector2i, bounds: Dictionary) -> String:
	return _resolve_depth_band(cell, bounds, ISO_OUTER_WALL_HEIGHT_ORDER, "mid")

static func get_production_height_level(wall_data: Dictionary, cell: Vector2i, material_asset_key: String, bounds: Dictionary) -> String:
	var height: String = normalize_height_level(get_raw_height_value(wall_data))
	var base_key: String = normalize_material_asset_base_key(material_asset_key)
	if height.is_empty(): height = resolve_outer_height(cell, bounds) if base_key == "wall_outer" else "mid"
	return normalize_height_for_material(base_key, height)

static func get_production_asset_key(wall_data: Dictionary, cell: Vector2i, fallback_profile_key: String, bounds: Dictionary) -> String:
	var base_key: String = get_material_base_key_for_row(Dictionary(wall_data.get("material", {})), fallback_profile_key)
	return get_asset_key_for_material_and_height(base_key, get_production_height_level(wall_data, cell, base_key, bounds))

static func get_test_height_asset_key(wall_data: Dictionary, cell: Vector2i, bounds: Dictionary) -> String:
	var height: String = normalize_test_height(get_raw_height_value(wall_data))
	if height.is_empty(): height = resolve_auto_test_height(cell, bounds)
	return str(ISO_TEST_WALL_HEIGHT_ASSET_KEYS.get(height, "wall_gray_mid"))

static func get_asset_placement(asset_key: String, source_size: Vector2, tile_size: Vector2) -> Dictionary:
	var placement: Dictionary = Dictionary(ISO_WALL_ASSET_PLACEMENT.get(normalize_asset_key(asset_key), {})).duplicate(true)
	if placement.is_empty():
		placement = {"visible_bounds": Rect2(Vector2.ZERO, source_size), "target_base_width": tile_size.x, "target_height": ISO_WALL_ASSET_EXPECTED_SIZE.y, "scale": 1.0, "offset": Vector2.ZERO}
	return placement

static func should_mirror_asset_for_topology(_topology: Dictionary) -> bool:
	return false

static func is_breachable_material_id(material_id: String) -> bool:
	return SurfaceMaterialCatalogRef.is_breachable_wall_material(material_id)

static func get_normalized_breachable_height(wall_data: Dictionary) -> String:
	var height: String = normalize_height_level(get_raw_height_value(wall_data))
	if height.is_empty(): height = "mid"
	return "low" if height in ["low", "halflow"] else height

static func get_default_visual_profile_key() -> String:
	return "default_wall"

static func get_visual_profiles() -> Dictionary:
	return WallRendererRef.get_visual_profiles()

static func normalize_visual_profile_key(profile_key: String) -> String:
	var key: String = profile_key.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	return key if get_visual_profiles().has(key) else get_default_visual_profile_key()

static func get_visual_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = get_visual_profiles()
	return Dictionary(profiles.get(normalize_visual_profile_key(profile_key), profiles[get_default_visual_profile_key()])).duplicate(true)

static func map_metadata_value_to_profile(raw_value: String) -> String:
	var value: String = raw_value.strip_edges().to_lower()
	var direct_map: Dictionary = {
		"outer_wall":"outer_wall", "grate_wall":"grate_wall", "brick_wall":"brick_wall", "concrete_wall":"concrete_wall",
		"steel_wall":"steel_wall", "reinforced_steel_wall":"reinforced_steel_wall", "titanium_wall":"titanium_wall",
		"energy_wall":"energy_wall", "damaged_wall":"damaged_wall", "brick":"brick_wall", "breachable_brick":"brick_wall",
		"concrete":"concrete_wall", "breachable_concrete":"concrete_wall", "steel":"steel_wall",
		"reinforced_steel":"reinforced_steel_wall", "titanium":"titanium_wall", "energy_flow":"energy_wall"
	}
	return str(direct_map.get(value, ""))

static func get_profile_from_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array): return ""
	for value in Array(tags_variant):
		var mapped: String = map_metadata_value_to_profile(str(value))
		if not mapped.is_empty(): return mapped
	return ""

static func get_object_type_for_metadata(metadata: Dictionary) -> String:
	if metadata.is_empty(): return ""
	var tag_profile: String = get_profile_from_tags(metadata.get("tags", []))
	if not tag_profile.is_empty(): return tag_profile
	for candidate in [metadata.get("visual_profile", ""), metadata.get("wall_type", ""), metadata.get("object_type", ""), metadata.get("type", ""), metadata.get("catalog_id", ""), metadata.get("id", ""), metadata.get("material", "")]:
		var mapped: String = map_metadata_value_to_profile(str(candidate))
		if not mapped.is_empty(): return mapped
	return ""

static func get_visual_profile_key_for_cell(grid_manager: Variant, cell: Vector2i, metadata: Dictionary = {}) -> String:
	if not is_wall_cell(grid_manager, cell): return ""
	var object_type: String = get_object_type_for_metadata(metadata)
	if not object_type.is_empty(): return object_type
	return "outer_wall" if is_outer_border_cell(grid_manager, cell) else "concrete_wall"

static func get_visible_sides(grid_manager: Variant, cell: Vector2i) -> Array[String]:
	var sides: Array[String] = []
	if not is_wall_cell(grid_manager, cell): return sides
	for side in WALL_SIDE_ORDER:
		var neighbor: Vector2i = cell + get_side_delta(side)
		if not is_in_bounds(grid_manager, neighbor): sides.append(side); continue
		var tile_type: int = int(grid_manager.call("get_tile", neighbor))
		if tile_type != GridManagerScript.TILE_WALL and is_mount_neighbor_visible(tile_type): sides.append(side)
	return sides

static func get_mounted_anchor_zones(grid_manager: Variant, cell: Vector2i, origin: Vector2, half_size: Vector2) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	if not is_wall_cell(grid_manager, cell): return zones
	for side in get_visible_sides(grid_manager, cell):
		var delta: Vector2i = get_side_delta(side)
		var neighbor: Vector2i = cell + delta
		var mountable: bool = false
		if is_in_bounds(grid_manager, neighbor):
			var tile_type: int = int(grid_manager.call("get_tile", neighbor))
			mountable = is_mount_neighbor_visible(tile_type) and not is_door_like_tile(tile_type)
		var wall_center: Vector2 = IsoProjectionServiceRef.grid_to_iso(cell, origin, half_size)
		var axis: Vector2 = Vector2(float(delta.x) * half_size.x * 0.65, float(delta.y) * half_size.y * 0.65)
		var center: Vector2 = wall_center + axis
		var tangent: Vector2 = Vector2(-axis.y, axis.x).normalized() * 7.0
		var normal: Vector2 = axis.normalized() * 5.0
		zones.append({"attached_wall_cell":cell, "anchor_floor_cell":neighbor, "wall_side":side, "visible":true, "mountable":mountable, "wall_mass_ratio":WALL_MASS_RATIO, "mount_band_ratio":WALL_MOUNT_BAND_RATIO, "mount_zone_center":center, "mount_zone_polygon":PackedVector2Array([center-tangent-normal, center+tangent-normal, center+tangent+normal, center-tangent+normal]), "interaction_cell":neighbor})
	return zones

static func get_render_topology(grid_manager: Variant, cell: Vector2i) -> Dictionary:
	var neighbors: Dictionary = get_neighbor_mask(grid_manager, cell)
	var visible_sides: Array[String] = get_visible_sides(grid_manager, cell)
	var cap_sides: Array[String] = []
	var mountable_sides: Array[String] = []
	if not is_wall_cell(grid_manager, cell): return {"cell":cell, "neighbors":neighbors, "run_x":false, "run_y":false, "shape":"unknown", "visible_sides":visible_sides, "cap_sides":cap_sides, "mountable_sides":mountable_sides}
	var north: bool = bool(neighbors.north); var east: bool = bool(neighbors.east); var south: bool = bool(neighbors.south); var west: bool = bool(neighbors.west)
	var count: int = int(north) + int(east) + int(south) + int(west)
	var run_x: bool = east and west; var run_y: bool = north and south; var shape: String = "isolated"
	for side in WALL_SIDE_ORDER:
		if not bool(neighbors.get(side, false)): cap_sides.append(side)
	for side in visible_sides:
		var neighbor_cell: Vector2i = cell + get_side_delta(side)
		if not is_in_bounds(grid_manager, neighbor_cell): continue
		var tile_type: int = int(grid_manager.call("get_tile", neighbor_cell))
		if is_mount_neighbor_visible(tile_type) and not is_door_like_tile(tile_type): mountable_sides.append(side)
	if count == 4: shape = "cross"
	elif count == 3: shape = "t_junction"
	elif count == 1: shape = "end_cap_south" if north else ("end_cap_west" if east else ("end_cap_north" if south else "end_cap_east"))
	elif run_x: shape = "straight_x"
	elif run_y: shape = "straight_y"
	elif north and east: shape = "inner_corner_ne" if is_wall_cell(grid_manager, cell + Vector2i(1, -1)) else "outer_corner_ne"
	elif north and west: shape = "inner_corner_nw" if is_wall_cell(grid_manager, cell + Vector2i(-1, -1)) else "outer_corner_nw"
	elif south and east: shape = "inner_corner_se" if is_wall_cell(grid_manager, cell + Vector2i(1, 1)) else "outer_corner_se"
	elif south and west: shape = "inner_corner_sw" if is_wall_cell(grid_manager, cell + Vector2i(-1, 1)) else "outer_corner_sw"
	return {"cell":cell, "neighbors":neighbors, "run_x":run_x, "run_y":run_y, "shape":shape, "visible_sides":visible_sides, "cap_sides":cap_sides, "mountable_sides":mountable_sides}

static func build_draw_entries(grid_manager: Variant, origin: Vector2, half_size: Vector2, inset: float) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if grid_manager == null: return entries
	for y in range(int(grid_manager.call("get_map_height"))):
		for x in range(int(grid_manager.call("get_map_width"))):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = int(grid_manager.call("get_tile", cell))
			if not is_wall_tile(tile_type): continue
			entries.append(IsoDrawEntryContractRef.make_entry(cell, "wall", "wall_body", get_depth_key_for_cell(grid_manager, cell, origin, half_size, inset), IsoDrawEntryContractRef.SUB_ORDER_WALL_BODY, {"tile_type":tile_type}, IsoDrawEntryContractRef.LAYER_BIAS_WALL))
	return entries
