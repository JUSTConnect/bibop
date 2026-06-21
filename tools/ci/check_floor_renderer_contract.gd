extends SceneTree

const FloorRendererRef = preload("res://scripts/visual/renderer/floor_renderer.gd")
const GridManagerScript = preload("res://scripts/field/grid_manager.gd")

class FakeGrid:
	extends RefCounted
	var width: int = 3
	var height: int = 2
	var cells: Dictionary = {}
	var heights: Dictionary = {}
	var states: Dictionary = {}

	func get_map_width() -> int:
		return width

	func get_map_height() -> int:
		return height

	func is_in_bounds(cell: Vector2i) -> bool:
		return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

	func get_tile(cell: Vector2i) -> int:
		return int(cells.get(cell, GridManagerScript.TILE_FLOOR))

	func get_floor_height_for_cell(cell: Vector2i) -> String:
		return str(heights.get(cell, ""))

	func get_floor_visual_state(cell: Vector2i) -> Dictionary:
		return Dictionary(states.get(cell, {}))

class FakeMission:
	extends RefCounted
	var overrides: Dictionary = {}

	func get_map_constructor_floor_material_for_cell(cell: Vector2i) -> Dictionary:
		if not overrides.has(cell):
			return {"ok": false}
		return {"ok": true, "override": Dictionary(overrides[cell])}

var failures: Array[String] = []
var raised_cells: Dictionary = {Vector2i(2, 1): true}

func _initialize() -> void:
	_check_profiles_and_assets()
	_check_runtime_floor_classification()
	_check_atlas_policy()
	_check_draw_entries()
	if failures.is_empty():
		print("FloorRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_profiles_and_assets() -> void:
	_expect(not FloorRendererRef.is_floor_like_tile(GridManagerScript.TILE_WALL), "wall must not be floor-like")
	_expect(FloorRendererRef.is_floor_like_tile(GridManagerScript.TILE_FLOOR), "floor must remain floor-like")
	_expect(FloorRendererRef.get_asset_key_for_material_key("steel", false) == "floor_steel", "steel mapping changed")
	_expect(FloorRendererRef.get_asset_key_for_material_key("titan", false) == "floor_titan", "titan mapping changed")
	_expect(FloorRendererRef.get_asset_key_for_material_key("step_1", false) == "ground_low", "step_1 material mapping changed")
	_expect(FloorRendererRef.get_asset_key_for_material_key("anything", true) == FloorRendererRef.FLOOR_TEST_ASSET_KEY, "gray-room override changed")
	_expect(FloorRendererRef.get_asset_key_for_tile(GridManagerScript.TILE_DOOR, false) == "floor_door_underlay", "door underlay mapping changed")
	_expect(FloorRendererRef.get_ground_asset_key_for_floor_height("step_2") == "ground_halflow", "step_2 ground mapping changed")
	_expect(FloorRendererRef.get_visual_profile("missing") == FloorRendererRef.get_visual_profile("floor_default"), "profile fallback changed")

func _check_runtime_floor_classification() -> void:
	var grid := FakeGrid.new()
	grid.cells[Vector2i(0, 0)] = GridManagerScript.TILE_WALL
	grid.cells[Vector2i(1, 0)] = GridManagerScript.TILE_FLOOR
	grid.cells[Vector2i(2, 0)] = GridManagerScript.TILE_WALL
	grid.cells[Vector2i(1, 1)] = GridManagerScript.TILE_TERMINAL
	_expect(FloorRendererRef.get_visual_profile_key_for_cell(grid, Vector2i(0, 0)) == "floor_wall_base", "wall base profile changed")
	_expect(FloorRendererRef.get_visual_profile_key_for_cell(grid, Vector2i(1, 0)) == "floor_passage", "passage detection changed")
	_expect(FloorRendererRef.get_visual_profile_key_for_cell(grid, Vector2i(1, 1)) == "floor_interactive", "interactive profile changed")
	grid.heights[Vector2i(2, 1)] = "step_1"
	var mission := FakeMission.new()
	mission.overrides[Vector2i(2, 1)] = {"floor_height": "step_2"}
	_expect(FloorRendererRef.get_ground_asset_key_for_cell(grid, mission, Vector2i(2, 1)) == "ground_halflow", "mission floor-height override must win")
	_expect(FloorRendererRef.get_ground_asset_key_for_cell(grid, null, Vector2i(2, 1)) == "ground_low", "grid floor-height fallback changed")

func _check_atlas_policy() -> void:
	_expect(FloorRendererRef.get_base_atlas_key("grate") == "grate_base", "grate atlas mapping changed")
	_expect(FloorRendererRef.get_overlay_atlas_key("metal", "heavy_damage") == "metal_heavy_damage", "metal damage atlas mapping changed")
	_expect(FloorRendererRef.get_atlas_seam_safe_variant(Vector2i(3, 4), "metal_base", -1, 6) == 1, "seam-safe base variant changed")
	var safe_rect := FloorRendererRef.get_atlas_safe_source_rect(Rect2(0, 0, 100, 100))
	_expect(safe_rect == Rect2(3, 3, 94, 94), "atlas source padding changed")
	var destination := FloorRendererRef.get_atlas_destination_rect(Vector2(64, 35.5))
	_expect(destination.size == Vector2(131, 74), "atlas destination footprint changed")
	_expect(FloorRendererRef.get_atlas_inner_overlay_points(Vector2(64, 35.5)).size() == 4, "atlas overlay diamond changed")

func _check_draw_entries() -> void:
	var grid := FakeGrid.new()
	grid.cells[Vector2i(0, 0)] = GridManagerScript.TILE_WALL
	var entries: Array[Dictionary] = FloorRendererRef.build_draw_entries(grid, Callable(self, "_ground_for_cell"), Vector2.ZERO, Vector2(64, 35.5))
	_expect(entries.size() == 5, "floor draw-entry count changed")
	var found_ground: bool = false
	for entry in entries:
		_expect(str(entry.get("layer", "")) == "floor", "floor entry layer changed")
		_expect(entry.has("depth_key") and entry.has("sub_order") and entry.has("payload"), "floor entry contract incomplete")
		if Vector2i(entry.get("cell", Vector2i(-1, -1))) == Vector2i(2, 1):
			found_ground = str(entry.get("kind", "")) == "ground"
	_expect(found_ground, "raised floor must use ground entry kind")

func _ground_for_cell(cell: Vector2i) -> String:
	return "ground_low" if raised_cells.has(cell) else ""

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
