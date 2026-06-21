extends SceneTree

const GridManagerScript = preload("res://scripts/field/grid_manager.gd")
const WallRendererRef = preload("res://scripts/visual/renderer/wall_renderer.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")

class FakeGrid:
	extends RefCounted
	var map_width: int
	var map_height: int
	var tiles: Dictionary = {}

	func _init(width: int, height: int) -> void:
		map_width = width
		map_height = height

	func get_map_width() -> int:
		return map_width

	func get_map_height() -> int:
		return map_height

	func get_tile(cell: Vector2i) -> int:
		return int(tiles.get(cell, GridManagerScript.TILE_FLOOR))

	func set_tile(cell: Vector2i, tile_type: int) -> void:
		tiles[cell] = tile_type

var failures: Array[String] = []

func _initialize() -> void:
	_check_asset_and_height_policy()
	_check_profiles()
	_check_topology()
	_check_anchor_zones()
	_check_draw_entries()
	_check_connected_base_geometry()
	if failures.is_empty():
		print("WallRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_asset_and_height_policy() -> void:
	_expect(WallRendererRef.normalize_asset_key("wall_brick_tall_01") == "wall_brick_tall", "brick tall asset normalization changed")
	_expect(WallRendererRef.get_asset_key_for_material_and_height("grate", "low") == "wall_grate_mid", "grate low height must normalize to mid")
	_expect(WallRendererRef.get_asset_key_for_material_and_height("titanium", "halfmid") == "wall_titan_halfmid", "titanium wall asset mapping changed")
	_expect(WallRendererRef.normalize_test_height("half_low") == "halfmid", "legacy test height alias changed")
	_expect(WallRendererRef.normalize_height_level("highest") == "tall", "wall height alias changed")
	var bounds: Dictionary = {"min_depth": 0, "max_depth": 4, "wall_count": 5}
	_expect(WallRendererRef.resolve_outer_height(Vector2i.ZERO, bounds) == "tall", "front outer wall height changed")
	_expect(WallRendererRef.resolve_outer_height(Vector2i(2, 2), bounds) == "low", "deep outer wall height changed")
	var explicit_wall: Dictionary = {"material": {"id": "concrete", "wall_height": "halfmid"}}
	_expect(WallRendererRef.get_production_height_level(explicit_wall, Vector2i(1, 1), "wall_concrete", bounds) == "halfmid", "explicit production height changed")
	_expect(WallRendererRef.is_breachable_material_id("breachable_concrete"), "breachable concrete contract changed")
	_expect(WallRendererRef.get_normalized_breachable_height({"wall_height": "halflow"}) == "low", "breachable low-height normalization changed")
	var placement: Dictionary = WallRendererRef.get_asset_placement("wall_concrete_mid", Vector2(512.0, 768.0), Vector2(128.0, 71.0))
	_expect(Rect2(placement.get("visible_bounds", Rect2())) == Rect2(1, 148, 511, 619), "wall placement bounds changed")

func _check_profiles() -> void:
	_expect(WallRendererRef.get_default_visual_profile_key() == "default_wall", "default wall profile changed")
	_expect(WallRendererRef.normalize_visual_profile_key("Concrete Wall") == "concrete_wall", "wall profile normalization changed")
	_expect(WallRendererRef.map_metadata_value_to_profile("breachable_brick") == "brick_wall", "breachable brick profile mapping changed")
	_expect(WallRendererRef.get_profile_from_tags(["service", "reinforced_steel"]) == "reinforced_steel_wall", "tag profile mapping changed")
	_expect(WallRendererRef.get_object_type_for_metadata({"material": "titanium"}) == "titanium_wall", "metadata profile mapping changed")
	var profile: Dictionary = WallRendererRef.get_visual_profile("steel_wall")
	_expect(str(profile.get("label", "")) == "Steel Wall", "steel wall profile changed")

func _check_topology() -> void:
	var grid: FakeGrid = FakeGrid.new(5, 5)
	grid.set_tile(Vector2i(1, 2), GridManagerScript.TILE_WALL)
	grid.set_tile(Vector2i(2, 2), GridManagerScript.TILE_WALL)
	grid.set_tile(Vector2i(3, 2), GridManagerScript.TILE_WALL)
	var straight: Dictionary = WallRendererRef.get_render_topology(grid, Vector2i(2, 2))
	_expect(str(straight.get("shape", "")) == "straight_x", "straight wall topology changed")
	_expect(bool(straight.get("run_x", false)), "straight-x run flag missing")
	_expect(Array(straight.get("cap_sides", [])).has("north") and Array(straight.get("cap_sides", [])).has("south"), "straight-x cap sides changed")
	grid.set_tile(Vector2i(2, 1), GridManagerScript.TILE_WALL)
	var t_junction: Dictionary = WallRendererRef.get_render_topology(grid, Vector2i(2, 2))
	_expect(str(t_junction.get("shape", "")) == "t_junction", "T-junction topology changed")

	var corner_grid: FakeGrid = FakeGrid.new(5, 5)
	corner_grid.set_tile(Vector2i(2, 2), GridManagerScript.TILE_WALL)
	corner_grid.set_tile(Vector2i(2, 1), GridManagerScript.TILE_WALL)
	corner_grid.set_tile(Vector2i(3, 2), GridManagerScript.TILE_WALL)
	_expect(str(WallRendererRef.get_render_topology(corner_grid, Vector2i(2, 2)).get("shape", "")) == "outer_corner_ne", "outer corner topology changed")
	corner_grid.set_tile(Vector2i(3, 1), GridManagerScript.TILE_WALL)
	_expect(str(WallRendererRef.get_render_topology(corner_grid, Vector2i(2, 2)).get("shape", "")) == "inner_corner_ne", "inner corner topology changed")

func _check_anchor_zones() -> void:
	var grid: FakeGrid = FakeGrid.new(5, 5)
	var wall_cell: Vector2i = Vector2i(2, 2)
	grid.set_tile(wall_cell, GridManagerScript.TILE_WALL)
	var zones: Array[Dictionary] = WallRendererRef.get_mounted_anchor_zones(grid, wall_cell, Vector2.ZERO, Vector2(64.0, 35.5))
	_expect(zones.size() == 4, "isolated wall must expose four visible sides")
	for zone in zones:
		_expect(bool(zone.get("mountable", false)), "floor-facing isolated wall side must be mountable")
	grid.set_tile(Vector2i(3, 2), GridManagerScript.TILE_DOOR)
	zones = WallRendererRef.get_mounted_anchor_zones(grid, wall_cell, Vector2.ZERO, Vector2(64.0, 35.5))
	for zone in zones:
		if str(zone.get("wall_side", "")) == "east":
			_expect(not bool(zone.get("mountable", true)), "door-facing wall side must not be mountable")

func _check_draw_entries() -> void:
	var grid: FakeGrid = FakeGrid.new(4, 4)
	grid.set_tile(Vector2i(1, 1), GridManagerScript.TILE_WALL)
	grid.set_tile(Vector2i(2, 1), GridManagerScript.TILE_WALL)
	var entries: Array[Dictionary] = WallRendererRef.build_draw_entries(grid, Vector2.ZERO, Vector2(64.0, 35.5), 8.0)
	_expect(entries.size() == 2, "wall draw-entry count changed")
	for entry in entries:
		_expect(str(entry.get("layer", "")) == "wall", "wall draw-entry layer changed")
		_expect(str(entry.get("kind", "")) == "wall_body", "wall draw-entry kind changed")
		_expect(entry.has("depth_key"), "wall draw-entry depth missing")

func _check_connected_base_geometry() -> void:
	var grid: FakeGrid = FakeGrid.new(5, 5)
	grid.set_tile(Vector2i(1, 2), GridManagerScript.TILE_WALL)
	grid.set_tile(Vector2i(2, 2), GridManagerScript.TILE_WALL)
	grid.set_tile(Vector2i(3, 2), GridManagerScript.TILE_WALL)
	var cell: Vector2i = Vector2i(2, 2)
	var half_size: Vector2 = Vector2(64.0, 35.5)
	var topology: Dictionary = WallRendererRef.get_render_topology(grid, cell)
	var connected: PackedVector2Array = WallRendererRef.get_connected_base_points(cell, topology, Vector2.ZERO, half_size, 8.0)
	var full: PackedVector2Array = IsoProjectionServiceRef.get_diamond_points(cell, Vector2.ZERO, half_size)
	_expect(connected == full, "straight connected wall base must expand to full shared edges")
	var isolated_grid: FakeGrid = FakeGrid.new(5, 5)
	isolated_grid.set_tile(cell, GridManagerScript.TILE_WALL)
	var isolated: PackedVector2Array = WallRendererRef.get_base_points(isolated_grid, cell, Vector2.ZERO, half_size, 8.0)
	var center: Vector2 = IsoProjectionServiceRef.grid_to_iso(cell, Vector2.ZERO, half_size)
	_expect(isolated[0].distance_to(center) < full[0].distance_to(center), "isolated wall base must retain visual inset")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
