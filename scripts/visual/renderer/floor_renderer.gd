extends RefCounted
class_name FloorRenderer

const GridManagerScript = preload("res://scripts/field/grid_manager.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")

const FLOOR_ASSET_PACK_DIR: String = "res://assets/visual/isometric/floor/"
const FLOOR_TEST_ASSET_KEY: String = "floor_gray_test"
const FLOOR_ASSET_CATALOG: Dictionary = {
	"floor_concrete": "floor_concrete_01.png",
	"floor_steel": "floor_steel_01.png",
	"floor_titan": "floor_titan_01.png",
	"platform_floor": "floor_platform_01.png"
}

const GROUND_ASSET_PACK_DIR: String = "res://assets/visual/isometric/ground/"
const GROUND_ASSET_CATALOG: Dictionary = {
	"ground_low": "ground_low_01.png",
	"ground_halflow": "ground_halflow_01.png"
}

const FLOOR_ASSET_TARGET_FOOTPRINT: Vector2 = IsoProjectionServiceRef.STANDARD_TILE_SIZE
const FLOOR_ASSET_NORMALIZED_OVERLAP: Vector2 = Vector2(1.5, 1.5)
const FLOOR_ASSET_PLACEMENT: Dictionary = {
	"floor_gray_test": {"visible_bounds": Rect2i(0, 162, 512, 286), "target_footprint": FLOOR_ASSET_TARGET_FOOTPRINT, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.11, 0.12, 0.13, 0.98), "draw_safe_base": false},
	"floor_concrete": {"visible_bounds": Rect2i(0, 162, 512, 287), "target_footprint": FLOOR_ASSET_TARGET_FOOTPRINT, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.08, 0.085, 0.09, 0.96)},
	"floor_steel": {"visible_bounds": Rect2i(0, 161, 512, 288), "target_footprint": FLOOR_ASSET_TARGET_FOOTPRINT, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.07, 0.085, 0.1, 0.96)},
	"floor_titan": {"visible_bounds": Rect2i(0, 162, 512, 287), "target_footprint": FLOOR_ASSET_TARGET_FOOTPRINT, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.075, 0.085, 0.11, 0.96)},
	"platform_floor": {"visible_bounds": Rect2i(0, 163, 512, 349), "target_footprint": FLOOR_ASSET_TARGET_FOOTPRINT, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.09, 0.105, 0.12, 0.96)}
}
const GROUND_ASSET_PLACEMENT: Dictionary = {
	"ground_low": {"visible_bounds": Rect2(0, 353, 512, 415), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO},
	"ground_halflow": {"visible_bounds": Rect2(0, 238, 512, 532), "target_base_width": 128.0, "scale": 1.0, "offset": Vector2.ZERO}
}

const FLOOR_ATLAS_COLUMNS: int = 6
const FLOOR_ATLAS_ROWS: int = 7
const FLOOR_ATLAS_BASE_VARIANTS: int = 6
const FLOOR_ATLAS_HEAVY_METAL_VARIANTS: int = 4
const FLOOR_ATLAS_SOURCE_EDGE_PADDING: float = 3.0
const FLOOR_ATLAS_SCREEN_OVERLAP: float = 1.5
const FLOOR_UNDERLAY_OVERLAP: float = 1.25
const FLOOR_ASSET_SCREEN_OVERLAP: float = 2.0
const FLOOR_OVERLAY_INNER_INSET: float = 12.0
const FLOOR_SEAM_SAFE_BASE_VARIANTS: Dictionary = {
	"grate_base": [1],
	"metal_base": [1],
	"concrete_base": [1]
}
const FLOOR_ATLAS_LAYOUT: Dictionary = {
	"grate_base": {"row": 1, "variants": 6, "overlay": false},
	"metal_base": {"row": 2, "variants": 6, "overlay": false},
	"metal_light_wear": {"row": 3, "variants": 6, "overlay": true},
	"metal_heavy_damage": {"row": 4, "variants": FLOOR_ATLAS_HEAVY_METAL_VARIANTS, "overlay": true},
	"concrete_base": {"row": 5, "variants": 6, "overlay": false},
	"concrete_light_wear": {"row": 6, "variants": 6, "overlay": true},
	"concrete_heavy_damage": {"row": 7, "variants": 6, "overlay": true}
}

const FLOOR_VISUAL_PROFILES: Dictionary = {
	"floor_default": {"fill": Color(0.115, 0.125, 0.145, 0.96), "outline": Color(0.2, 0.28, 0.34, 0.78), "panel": Color(0.16, 0.19, 0.22, 0.4), "seam": Color(0.34, 0.39, 0.44, 0.28)},
	"floor_passage": {"fill": Color(0.125, 0.14, 0.162, 0.97), "outline": Color(0.28, 0.4, 0.47, 0.9), "panel": Color(0.19, 0.24, 0.29, 0.48), "seam": Color(0.58, 0.72, 0.8, 0.45)},
	"floor_doorway": {"fill": Color(0.14, 0.15, 0.165, 0.97), "outline": Color(0.34, 0.35, 0.4, 0.88), "panel": Color(0.22, 0.24, 0.28, 0.52), "seam": Color(0.84, 0.7, 0.42, 0.5)},
	"floor_interactive": {"fill": Color(0.12, 0.145, 0.165, 0.97), "outline": Color(0.26, 0.41, 0.47, 0.88), "panel": Color(0.19, 0.26, 0.3, 0.48), "seam": Color(0.46, 0.82, 0.9, 0.42)},
	"floor_exit": {"fill": Color(0.12, 0.15, 0.14, 0.97), "outline": Color(0.24, 0.44, 0.32, 0.88), "panel": Color(0.17, 0.24, 0.2, 0.5), "seam": Color(0.54, 0.86, 0.62, 0.45)},
	"floor_wall_base": {"fill": Color(0.08, 0.09, 0.11, 0.98), "outline": Color(0.14, 0.17, 0.2, 0.72), "panel": Color(0.1, 0.12, 0.14, 0.35), "seam": Color(0.2, 0.23, 0.27, 0.2)}
}

static func is_floor_like_tile(tile_type: int) -> bool:
	return tile_type != GridManagerScript.TILE_WALL

static func get_prototype_color(tile_type: int, cell: Vector2i) -> Color:
	var base_color: Color = Color(0.115, 0.125, 0.145, 0.96)
	if (cell.x + cell.y) % 2 != 0:
		base_color = Color(0.135, 0.145, 0.165, 0.96)
	if tile_type == GridManagerScript.TILE_TERMINAL or tile_type == GridManagerScript.TILE_AIRFLOW_TERMINAL:
		base_color = base_color.lerp(Color(0.16, 0.23, 0.29, 0.98), 0.35)
	elif tile_type == GridManagerScript.TILE_EXIT:
		base_color = base_color.lerp(Color(0.14, 0.24, 0.2, 0.98), 0.4)
	elif tile_type == GridManagerScript.TILE_DIGITAL_DOOR or tile_type == GridManagerScript.TILE_POWERED_GATE:
		base_color = base_color.lerp(Color(0.14, 0.2, 0.27, 0.98), 0.3)
	elif tile_type == GridManagerScript.TILE_DOOR:
		base_color = base_color.lerp(Color(0.2, 0.17, 0.13, 0.98), 0.22)
	elif tile_type == GridManagerScript.TILE_HOT_NODE:
		base_color = base_color.lerp(Color(0.23, 0.16, 0.15, 0.98), 0.25)
	return base_color

static func is_walkable_floor_like_for_passage(tile_type: int) -> bool:
	return tile_type == GridManagerScript.TILE_FLOOR or tile_type == GridManagerScript.TILE_STEPPED_FLOOR

static func is_interactive_floor_tile(tile_type: int) -> bool:
	return tile_type in [
		GridManagerScript.TILE_TERMINAL,
		GridManagerScript.TILE_AIRFLOW_TERMINAL,
		GridManagerScript.TILE_PLATFORM_CONTROL,
		GridManagerScript.TILE_PLATFORM_CONTROL_LEFT,
		GridManagerScript.TILE_PLATFORM_CONTROL_RIGHT,
		GridManagerScript.TILE_FAN_CONTROL,
		GridManagerScript.TILE_FAN_SPEED_UP_CONTROL,
		GridManagerScript.TILE_FAN_SPEED_DOWN_CONTROL,
		GridManagerScript.TILE_SOCKET,
		GridManagerScript.TILE_CABLE_REEL,
		GridManagerScript.TILE_CABLE
	]

static func is_cell_in_bounds(grid_manager: Variant, cell: Vector2i) -> bool:
	return grid_manager != null and grid_manager.has_method("is_in_bounds") and bool(grid_manager.call("is_in_bounds", cell))

static func is_passage_floor_cell(grid_manager: Variant, cell: Vector2i) -> bool:
	if not is_cell_in_bounds(grid_manager, cell):
		return false
	var tile_type: int = int(grid_manager.call("get_tile", cell))
	if not is_walkable_floor_like_for_passage(tile_type):
		return false
	var north: Vector2i = cell + Vector2i(0, -1)
	var south: Vector2i = cell + Vector2i(0, 1)
	var west: Vector2i = cell + Vector2i(-1, 0)
	var east: Vector2i = cell + Vector2i(1, 0)
	var wall_neighbor_count: int = 0
	for neighbor in [north, south, west, east]:
		if not is_cell_in_bounds(grid_manager, neighbor) or int(grid_manager.call("get_tile", neighbor)) == GridManagerScript.TILE_WALL:
			wall_neighbor_count += 1
	var opposite_walls: bool = (
		(not is_cell_in_bounds(grid_manager, north) or int(grid_manager.call("get_tile", north)) == GridManagerScript.TILE_WALL)
		and (not is_cell_in_bounds(grid_manager, south) or int(grid_manager.call("get_tile", south)) == GridManagerScript.TILE_WALL)
	) or (
		(not is_cell_in_bounds(grid_manager, west) or int(grid_manager.call("get_tile", west)) == GridManagerScript.TILE_WALL)
		and (not is_cell_in_bounds(grid_manager, east) or int(grid_manager.call("get_tile", east)) == GridManagerScript.TILE_WALL)
	)
	return opposite_walls or wall_neighbor_count >= 2

static func get_visual_profile_key_for_cell(grid_manager: Variant, cell: Vector2i) -> String:
	if not is_cell_in_bounds(grid_manager, cell):
		return "floor_default"
	var tile_type: int = int(grid_manager.call("get_tile", cell))
	if tile_type == GridManagerScript.TILE_WALL:
		return "floor_wall_base"
	if tile_type == GridManagerScript.TILE_DOOR or tile_type == GridManagerScript.TILE_DIGITAL_DOOR or tile_type == GridManagerScript.TILE_POWERED_GATE:
		return "floor_doorway"
	if is_interactive_floor_tile(tile_type):
		return "floor_interactive"
	if tile_type == GridManagerScript.TILE_EXIT:
		return "floor_exit"
	if is_passage_floor_cell(grid_manager, cell):
		return "floor_passage"
	return "floor_default"

static func get_material_family_for_cell(grid_manager: Variant, cell: Vector2i) -> String:
	if not is_cell_in_bounds(grid_manager, cell):
		return "none"
	var tile_type: int = int(grid_manager.call("get_tile", cell))
	if not is_floor_like_tile(tile_type):
		return "none"
	var profile_key: String = get_visual_profile_key_for_cell(grid_manager, cell)
	if profile_key == "floor_doorway":
		return "doorway"
	if profile_key == "floor_wall_base":
		return "wall_base"
	return "connected_floor"

static func get_visual_profile(profile_key: String) -> Dictionary:
	return Dictionary(FLOOR_VISUAL_PROFILES.get(profile_key, FLOOR_VISUAL_PROFILES["floor_default"]))

static func normalize_material_key(material_key: String) -> String:
	return SurfaceMaterialCatalogRef.normalize_floor_material_id(material_key, "concrete")

static func get_asset_key_for_material_key(material_key: String, use_gray_test_assets: bool) -> String:
	if use_gray_test_assets:
		return FLOOR_TEST_ASSET_KEY
	var normalized_key: String = material_key.strip_edges().to_lower()
	if normalized_key in ["step_1", "ground_low", "ground_low_01", "ground_low_01.png"]:
		return "ground_low"
	if normalized_key in ["step_2", "ground_halflow", "ground_halflow_01", "ground_halflow_01.png"]:
		return "ground_halflow"
	match normalize_material_key(material_key):
		"steel":
			return "floor_steel"
		"titan":
			return "floor_titan"
		_:
			return "floor_concrete"

static func get_asset_key_for_tile(tile_type: int, use_gray_test_assets: bool) -> String:
	if tile_type == GridManagerScript.TILE_WALL:
		return ""
	if use_gray_test_assets and is_floor_like_tile(tile_type):
		return FLOOR_TEST_ASSET_KEY
	if tile_type == GridManagerScript.TILE_DOOR or tile_type == GridManagerScript.TILE_DIGITAL_DOOR or tile_type == GridManagerScript.TILE_POWERED_GATE:
		return "floor_door_underlay"
	if tile_type == GridManagerScript.TILE_FLOOR or is_floor_like_tile(tile_type):
		return "floor_concrete"
	return ""

static func get_asset_key_for_visual_height(value: String) -> String:
	match value.strip_edges().to_lower():
		"step_1", "ground_low", "ground_low_01", "ground_low_01.png", "low":
			return "ground_low"
		"step_2", "ground_halflow", "ground_halflow_01", "ground_halflow_01.png", "halflow", "half_low":
			return "ground_halflow"
	return ""

static func get_asset_key_for_visual_state(grid_manager: Variant, cell: Vector2i) -> String:
	if grid_manager == null or not grid_manager.has_method("get_floor_visual_state"):
		return ""
	var state: Dictionary = _as_dictionary(grid_manager.call("get_floor_visual_state", cell))
	for field_name in ["floor_height_level", "floor_visual_height", "ground_height", "height_level"]:
		var asset_key: String = get_asset_key_for_visual_height(str(state.get(field_name, "")))
		if not asset_key.is_empty():
			return asset_key
	return ""

static func normalize_height_level(value: String) -> String:
	return WallHeightCatalogRef.normalize_floor_height(value, "")

static func get_ground_asset_key_for_floor_height(floor_height: String) -> String:
	match normalize_height_level(floor_height):
		"step_1":
			return "ground_low"
		"step_2":
			return "ground_halflow"
	return ""

static func get_ground_asset_key_for_cell(grid_manager: Variant, mission_manager: Variant, cell: Vector2i) -> String:
	var floor_height_level: String = ""
	if mission_manager != null and mission_manager.has_method("get_map_constructor_floor_material_for_cell"):
		var result: Dictionary = _as_dictionary(mission_manager.call("get_map_constructor_floor_material_for_cell", cell))
		if bool(result.get("ok", false)):
			var override_data: Dictionary = _as_dictionary(result.get("override", {}))
			floor_height_level = normalize_height_level(str(override_data.get("floor_height", override_data.get("floor_visual_height", override_data.get("ground_height", "")))))
	if floor_height_level.is_empty() and grid_manager != null and grid_manager.has_method("get_floor_height_for_cell"):
		floor_height_level = normalize_height_level(str(grid_manager.call("get_floor_height_for_cell", cell)))
	return get_ground_asset_key_for_floor_height(floor_height_level)

static func get_asset_placement(asset_key: String, tile_size: Vector2) -> Dictionary:
	if FLOOR_ASSET_PLACEMENT.has(asset_key):
		return Dictionary(FLOOR_ASSET_PLACEMENT.get(asset_key, {}))
	return {"visible_bounds": Rect2i(0, 0, int(tile_size.x), int(tile_size.y)), "target_footprint": tile_size, "overlap": FLOOR_ASSET_NORMALIZED_OVERLAP, "offset": Vector2.ZERO, "fallback_color": Color(0.08, 0.085, 0.09, 0.96)}

static func get_floor_state_for_cell(grid_manager: Variant, cell: Vector2i) -> Dictionary:
	var fallback: Dictionary = {"family": "metal", "wear": "none", "base_variant": -1, "overlay_variant": -1, "mirror_h": false, "mirror_v": false}
	if grid_manager == null or not grid_manager.has_method("get_floor_visual_state"):
		return fallback
	var state: Dictionary = _as_dictionary(grid_manager.call("get_floor_visual_state", cell))
	return state if not state.is_empty() else fallback

static func get_atlas_cell_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(float(texture.get_width()) / float(FLOOR_ATLAS_COLUMNS), float(texture.get_height()) / float(FLOOR_ATLAS_ROWS))

static func get_atlas_region(texture: Texture2D, row: int, atlas_position: int) -> Rect2:
	var cell_size: Vector2 = get_atlas_cell_size(texture)
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Rect2()
	var safe_row: int = clampi(row, 1, FLOOR_ATLAS_ROWS)
	var safe_position: int = clampi(atlas_position, 1, FLOOR_ATLAS_COLUMNS)
	return Rect2(Vector2(float(safe_position - 1) * cell_size.x, float(safe_row - 1) * cell_size.y), cell_size)

static func get_base_atlas_key(family: String) -> String:
	match family:
		"grate":
			return "grate_base"
		"concrete":
			return "concrete_base"
		_:
			return "metal_base"

static func get_overlay_atlas_key(family: String, wear: String) -> String:
	if wear == "light_wear":
		if family == "concrete":
			return "concrete_light_wear"
		if family == "metal":
			return "metal_light_wear"
	elif wear == "heavy_damage":
		if family == "concrete":
			return "concrete_heavy_damage"
		if family == "metal":
			return "metal_heavy_damage"
	return ""

static func get_atlas_variant_for_cell(cell: Vector2i, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	if max_variants <= 0:
		return 1
	if requested_variant >= 1:
		return clampi(requested_variant, 1, max_variants)
	return ((cell.x * 17 + cell.y * 31 + salt) % max_variants) + 1

static func get_atlas_seam_safe_variant(cell: Vector2i, atlas_key: String, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	if FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key):
		var safe_variants: Array = Array(FLOOR_SEAM_SAFE_BASE_VARIANTS.get(atlas_key, []))
		if safe_variants.is_empty():
			return 1
		var safe_index: int = 0
		if requested_variant < 1 and safe_variants.size() > 1:
			safe_index = (cell.x * 17 + cell.y * 31 + salt) % safe_variants.size()
		return clampi(int(safe_variants[safe_index]), 1, max_variants)
	return get_atlas_variant_for_cell(cell, requested_variant, max_variants, salt)

static func get_atlas_safe_source_rect(source_rect: Rect2) -> Rect2:
	var padding: float = minf(FLOOR_ATLAS_SOURCE_EDGE_PADDING, minf(source_rect.size.x, source_rect.size.y) * 0.25)
	if padding <= 0.0:
		return source_rect
	return Rect2(source_rect.position + Vector2(padding, padding), source_rect.size - Vector2(padding * 2.0, padding * 2.0))

static func get_atlas_destination_rect(half_size: Vector2) -> Rect2:
	var destination_size: Vector2 = half_size * 2.0 + Vector2(FLOOR_ATLAS_SCREEN_OVERLAP * 2.0, FLOOR_ATLAS_SCREEN_OVERLAP * 2.0)
	return Rect2(destination_size * -0.5, destination_size)

static func get_atlas_inner_overlay_points(half_size: Vector2) -> PackedVector2Array:
	var destination_rect: Rect2 = get_atlas_destination_rect(half_size)
	var inset: float = minf(FLOOR_OVERLAY_INNER_INSET, minf(destination_rect.size.x, destination_rect.size.y) * 0.35)
	return PackedVector2Array([
		Vector2(destination_rect.position.x + destination_rect.size.x * 0.5, destination_rect.position.y + inset),
		Vector2(destination_rect.end.x - inset, destination_rect.position.y + destination_rect.size.y * 0.5),
		Vector2(destination_rect.position.x + destination_rect.size.x * 0.5, destination_rect.end.y - inset),
		Vector2(destination_rect.position.x + inset, destination_rect.position.y + destination_rect.size.y * 0.5)
	])

static func get_atlas_uvs_for_destination_points(points: PackedVector2Array, destination_rect: Rect2, source_rect: Rect2) -> PackedVector2Array:
	var uvs: PackedVector2Array = PackedVector2Array()
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return uvs
	for point in points:
		var normalized_point: Vector2 = Vector2((point.x - destination_rect.position.x) / destination_rect.size.x, (point.y - destination_rect.position.y) / destination_rect.size.y)
		uvs.append(source_rect.position + Vector2(normalized_point.x * source_rect.size.x, normalized_point.y * source_rect.size.y))
	return uvs

static func build_draw_entries(grid_manager: Variant, ground_asset_resolver: Callable, origin: Vector2, half_size: Vector2) -> Array[Dictionary]:
	if grid_manager == null:
		return []
	var map_width: int = int(grid_manager.call("get_map_width"))
	var map_height: int = int(grid_manager.call("get_map_height"))
	if map_width <= 0 or map_height <= 0:
		return []
	var entries: Array[Dictionary] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = int(grid_manager.call("get_tile", cell))
			if not is_floor_like_tile(tile_type):
				continue
			var ground_asset_key: String = ""
			if ground_asset_resolver.is_valid():
				ground_asset_key = str(ground_asset_resolver.call(cell))
			entries.append(IsoDrawEntryContractRef.make_entry(
				cell,
				"floor",
				"ground" if not ground_asset_key.is_empty() else "floor",
				IsoProjectionServiceRef.get_depth_key(cell, origin, half_size),
				IsoDrawEntryContractRef.SUB_ORDER_GROUND if not ground_asset_key.is_empty() else IsoDrawEntryContractRef.SUB_ORDER_FLOOR,
				{"tile_type": tile_type}
			))
	return entries

static func _as_dictionary(value: Variant) -> Dictionary:
	return Dictionary(value) if value is Dictionary else {}
