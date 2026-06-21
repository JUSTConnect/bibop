extends RefCounted
class_name WallRenderer

const GridManagerScript = preload("res://scripts/field/grid_manager.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")

const ISO_WALL_ASSET_PACK_DIR: String = "res://assets/visual/isometric/wall/"

const ISO_WALL_BREACH_OVERLAY_PACK_DIR: String = "res://assets/visual/isometric/wall/overlay/"

const ISO_WALL_BREACH_OVERLAY_CATALOG: Dictionary = {
	"breach_overlay_concrete_sw": "wall_breach_overlay_concrete_sw_01.png",
	"breach_overlay_brick_sw": "wall_breach_overlay_brick_sw_01.png"
}

const ISO_WALL_ASSET_EXPECTED_SIZE: Vector2 = Vector2(128.0, 120.0)

const ISO_WALL_HEIGHT_LEVELS: Array[String] = WallHeightCatalogRef.WALL_HEIGHT_LEVELS

const ISO_OUTER_WALL_HEIGHT_ORDER: Array[String] = ["tall", "halfmid", "mid", "halflow", "low"]

const ISO_GRATE_WALL_HEIGHT_LEVELS: Array[String] = ["mid", "halfmid", "tall"]

const ISO_TEST_WALL_HEIGHT_ORDER: Array[String] = ["tallest", "tall", "mid", "halfmid", "low"]

const ISO_TEST_WALL_HEIGHT_ASSET_KEYS: Dictionary = {
	"tallest": "wall_gray_tallest",
	"tall": "wall_gray_tall",
	"mid": "wall_gray_mid",
	"halfmid": "wall_gray_halfmid",
	"low": "wall_gray_low"
}

const ISO_WALL_ASSET_CATALOG: Dictionary = {
	"wall_gray_tallest": "wall_gray_tallest_01.png",
	"wall_gray_tall": "wall_gray_tall_01.png",
	"wall_gray_mid": "wall_gray_mid_01.png",
	"wall_gray_halfmid": "wall_gray_halfmid_01.png",
	"wall_gray_low": "wall_gray_low_01.png",
	"wall_default": "concrete/wall_concrete_mid_01.png",
	"wall_concrete_low": "concrete/wall_concrete_low_01.png",
	"wall_concrete_halflow": "concrete/wall_concrete_halflow_01.png",
	"wall_concrete_mid": "concrete/wall_concrete_mid_01.png",
	"wall_concrete_halfmid": "concrete/wall_concrete_halfmid_01.png",
	"wall_concrete_tall": "concrete/wall_concrete_tall_01.png",
	"wall_steel_low": "steel/wall_steel_low_01.png",
	"wall_steel_halflow": "steel/wall_steel_halflow_01.png",
	"wall_steel_mid": "steel/wall_steel_mid_01.png",
	"wall_steel_halfmid": "steel/wall_steel_halfmid_01.png",
	"wall_steel_tall": "steel/wall_steel_tall_01.png",
	"wall_titan_low": "titan/wall_titan_low_01.png",
	"wall_titan_halflow": "titan/wall_titan_halflow_01.png",
	"wall_titan_mid": "titan/wall_titan_mid_01.png",
	"wall_titan_halfmid": "titan/wall_titan_halfmid_01.png",
	"wall_titan_tall": "titan/wall_titan_tall_01.png",
	"wall_reinforced_steel_low": "reinforce_steel/wall_reinforcesteel_low_01.png",
	"wall_reinforced_steel_halflow": "reinforce_steel/wall_reinforcesteel_halflow_01.png",
	"wall_reinforced_steel_mid": "reinforce_steel/wall_reinforcesteel_mid_01.png",
	"wall_reinforced_steel_halfmid": "reinforce_steel/wall_reinforcesteel_halfmid_01.png",
	"wall_reinforced_steel_tall": "reinforce_steel/wall_reinforcesteel_tall_01.png",
	"wall_brick_low": "brick/wall_brick_low_01.png",
	"wall_brick_halflow": "brick/wall_brick_halflow_01.png",
	"wall_brick_mid": "brick/wall_brick_mid_01.png",
	"wall_brick_halfmid": "brick/wall_brick_halfmid_01.png",
	"wall_brick_tall": "brick/wall_brick_tall_01.png",
	"wall_outer_low": "outerwall/wall_outerwall_low_01.png",
	"wall_outer_halflow": "outerwall/wall_outerwall_halflow_01.png",
	"wall_outer_mid": "outerwall/wall_outerwall_mid_01.png",
	"wall_outer_halfmid": "outerwall/wall_outerwall_halfmid_01.png",
	"wall_outer_tall": "outerwall/wall_outerwall_tall_01.png",
	"wall_grate_mid": "grate/wall_grate_mid_01.png",
	"wall_grate_halfmid": "grate/wall_grate_halfmid_01.png",
	"wall_grate_tall": "grate/wall_grate_tall_01.png"
}

const ISO_WALL_BASELINE_VISIBLE_BOUNDS: Rect2 = Rect2(1, 148, 511, 619)

const ISO_WALL_HEIGHT_VISIBLE_BOUNDS: Dictionary = {
	"low": Rect2(0, 353, 512, 415),
	"halflow": Rect2(0, 239, 511, 534),
	"mid": Rect2(1, 148, 511, 619),
	"halfmid": Rect2(1, 63, 511, 704),
	"tall": Rect2(1, 0, 511, 767)
}

const ISO_TEST_WALL_VISIBLE_BOUNDS: Dictionary = {
	"wall_gray_tallest": Rect2(0, 0, 512, 768),
	"wall_gray_tall": Rect2(0, 63, 512, 705),
	"wall_gray_mid": Rect2(0, 150, 512, 618),
	"wall_gray_halfmid": Rect2(0, 238, 512, 532),
	"wall_gray_low": Rect2(0, 353, 512, 415)
}

const ISO_WALL_ASSET_PLACEMENT: Dictionary = {
	"wall_gray_tallest": {"visible_bounds": Rect2(0, 0, 512, 768), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_gray_tall": {"visible_bounds": Rect2(0, 63, 512, 705), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_gray_mid": {"visible_bounds": Rect2(0, 150, 512, 618), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_gray_halfmid": {"visible_bounds": Rect2(0, 238, 512, 532), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_gray_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_default": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_concrete_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_concrete_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_concrete_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_concrete_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_concrete_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_steel_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_steel_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_steel_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_steel_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_steel_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_titan_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_titan_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_titan_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_titan_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_titan_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_reinforced_steel_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_reinforced_steel_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_reinforced_steel_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_reinforced_steel_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_reinforced_steel_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_brick_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_brick_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_brick_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_brick_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_brick_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_outer_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_outer_halflow": {"visible_bounds": Rect2(0, 239, 511, 534), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_outer_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_outer_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_outer_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_grate_mid": {"visible_bounds": Rect2(1, 148, 511, 619), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_grate_halfmid": {"visible_bounds": Rect2(1, 63, 511, 704), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"wall_grate_tall": {"visible_bounds": Rect2(1, 0, 511, 767), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO}
}

const WALL_SIDE_ORDER: Array[String] = ["north", "east", "south", "west"]

const WALL_MASS_RATIO: float = 0.7

const WALL_MOUNT_BAND_RATIO: float = 0.3

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
	# Visual-only mapping layer for procedural wall prototype colors.
	# Keys intentionally mirror planned WorldObjectCatalog wall IDs for future metadata wiring.
	return {
		"default_wall": {
			"label": "Default Wall",
			"top": Color(0.205, 0.225, 0.255, 0.98),
			"left": Color(0.125, 0.14, 0.165, 0.98),
			"right": Color(0.1, 0.115, 0.14, 0.98),
			"outline": Color(0.24, 0.31, 0.36, 0.9),
			"accent": Color(0.29, 0.35, 0.4, 0.5)
		},
		"outer_wall": {
			"label": "Outer Wall",
			"top": Color(0.19, 0.2, 0.22, 0.98),
			"left": Color(0.11, 0.12, 0.14, 0.98),
			"right": Color(0.09, 0.1, 0.12, 0.98),
			"outline": Color(0.24, 0.29, 0.34, 0.9),
			"accent": Color(0.26, 0.31, 0.37, 0.45)
		},
		"grate_wall": {
			"label": "Grate Wall",
			"top": Color(0.15, 0.18, 0.2, 0.8),
			"left": Color(0.07, 0.085, 0.1, 0.72),
			"right": Color(0.06, 0.075, 0.09, 0.72),
			"outline": Color(0.18, 0.24, 0.28, 0.88),
			"accent": Color(0.78, 0.86, 0.92, 0.85)
		},
		"concrete_damaged_wall": {
			"label": "Concrete Damaged Wall",
			"top": Color(0.235, 0.205, 0.195, 0.98),
			"left": Color(0.155, 0.125, 0.115, 0.98),
			"right": Color(0.125, 0.1, 0.095, 0.98),
			"outline": Color(0.36, 0.27, 0.24, 0.9),
			"accent": Color(0.52, 0.28, 0.2, 0.55)
		},
		"brick_damaged_wall": {
			"label": "Brick Damaged Wall",
			"top": Color(0.315, 0.17, 0.135, 0.98),
			"left": Color(0.22, 0.11, 0.09, 0.98),
			"right": Color(0.18, 0.085, 0.075, 0.98),
			"outline": Color(0.42, 0.2, 0.16, 0.92),
			"accent": Color(0.76, 0.48, 0.34, 0.62)
		},
		"damaged_wall": {
			"label": "Concrete Damaged Wall",
			"top": Color(0.235, 0.205, 0.195, 0.98),
			"left": Color(0.155, 0.125, 0.115, 0.98),
			"right": Color(0.125, 0.1, 0.095, 0.98),
			"outline": Color(0.36, 0.27, 0.24, 0.9),
			"accent": Color(0.52, 0.28, 0.2, 0.55)
		},
		"brick_wall": {
			"label": "Brick Wall",
			"top": Color(0.37, 0.21, 0.16, 0.98),
			"left": Color(0.28, 0.14, 0.11, 0.98),
			"right": Color(0.24, 0.12, 0.1, 0.98),
			"outline": Color(0.46, 0.24, 0.18, 0.92),
			"accent": Color(0.82, 0.72, 0.58, 0.64)
		},
		"concrete_wall": {
			"label": "Concrete Wall",
			"top": Color(0.33, 0.34, 0.35, 0.98),
			"left": Color(0.23, 0.24, 0.25, 0.98),
			"right": Color(0.2, 0.21, 0.22, 0.98),
			"outline": Color(0.42, 0.44, 0.45, 0.9),
			"accent": Color(0.68, 0.71, 0.73, 0.52)
		},
		"steel_wall": {
			"label": "Steel Wall",
			"top": Color(0.26, 0.31, 0.36, 0.98),
			"left": Color(0.16, 0.2, 0.25, 0.98),
			"right": Color(0.135, 0.175, 0.22, 0.98),
			"outline": Color(0.3, 0.39, 0.47, 0.92),
			"accent": Color(0.66, 0.76, 0.86, 0.65)
		},
		"reinforced_steel_wall": {
			"label": "Reinforced Steel Wall",
			"top": Color(0.165, 0.195, 0.235, 0.98),
			"left": Color(0.1, 0.125, 0.155, 0.98),
			"right": Color(0.085, 0.11, 0.14, 0.98),
			"outline": Color(0.22, 0.3, 0.36, 0.9),
			"accent": Color(0.28, 0.39, 0.48, 0.5)
		},
		"titanium_wall": {
			"label": "Titanium Wall",
			"top": Color(0.245, 0.265, 0.3, 0.98),
			"left": Color(0.17, 0.185, 0.215, 0.98),
			"right": Color(0.14, 0.155, 0.185, 0.98),
			"outline": Color(0.31, 0.38, 0.45, 0.9),
			"accent": Color(0.45, 0.53, 0.62, 0.55)
		},
		"energy_wall": {
			"label": "Energy Wall",
			"top": Color(0.12, 0.165, 0.205, 0.98),
			"left": Color(0.07, 0.11, 0.145, 0.98),
			"right": Color(0.055, 0.09, 0.125, 0.98),
			"outline": Color(0.2, 0.36, 0.47, 0.9),
			"accent": Color(0.28, 0.83, 0.96, 0.72)
		}
	}

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
