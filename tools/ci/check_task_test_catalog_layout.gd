extends SceneTree

const GridManagerRef = preload("res://scripts/field/grid_manager.gd")
const MissionContentCatalogRef = preload("res://scripts/game/mission_content_catalog.gd")
const MissionIdsRef = preload("res://scripts/game/mission_ids.gd")

var failures: Array[String] = []

func _init() -> void:
	var catalog = MissionContentCatalogRef.new()
	var grid = GridManagerRef.new()
	root.add_child(grid)
	await process_frame

	var canonical_layout: Array = catalog.get_mission_layout(MissionIdsRef.TASK_TEST_LAYOUT_ID)
	var alias_layout: Array = catalog.get_mission_layout(MissionIdsRef.TASK_TEST_COMPAT_MISSION_ID)
	_expect(not canonical_layout.is_empty(), "task_test catalog layout must exist")
	_expect(var_to_str(canonical_layout) == var_to_str(alias_layout), "mission_10 alias must resolve to canonical task_test layout")
	_expect(catalog.get_mission_layout_size(MissionIdsRef.TASK_TEST_LAYOUT_ID) == Vector2i(16, 10), "task_test layout must remain 16x10")
	_expect(catalog.get_mission_start_cell(MissionIdsRef.TASK_TEST_COMPAT_MISSION_ID) == Vector2i(1, 1), "mission_10 alias must preserve start cell")
	_expect(catalog.get_mission_exit_cells(MissionIdsRef.TASK_TEST_LAYOUT_ID).has(Vector2i(14, 7)), "task_test layout must preserve exit cell")
	_expect(not grid.has_method("get_mission10_layout"), "GridManager must not expose TASK TEST fallback layout")

	var initial_snapshot := var_to_str(grid.map_data)
	_expect(grid.apply_mission_layout(canonical_layout), "GridManager must accept canonical catalog layout")
	_expect(var_to_str(grid.map_data) == var_to_str(canonical_layout), "canonical layout must be applied exactly")
	_expect(initial_snapshot != var_to_str(grid.map_data), "catalog layout must replace initial map")

	var applied_snapshot := var_to_str(grid.map_data)
	var absent_layout: Array = catalog.get_mission_layout("absent_layout_fixture")
	_expect(absent_layout.is_empty(), "unknown layout must resolve empty")
	_expect(not grid.apply_mission_layout(absent_layout), "missing layout must fail closed")
	_expect(var_to_str(grid.map_data) == applied_snapshot, "missing layout must not mutate grid")

	var malformed_layout: Array = [[1, 1, 1], [1, 0]]
	_expect(not grid.apply_mission_layout(malformed_layout), "non-rectangular layout must fail closed")
	_expect(var_to_str(grid.map_data) == applied_snapshot, "malformed layout must not mutate grid")

	grid.reset_mission_layout(4)
	_expect(grid.map_data.size() == 8 and Array(grid.map_data[0]).size() == 8, "mission 4 reset must remain available")
	grid.reset_mission_layout(6)
	_expect(grid.get_tile(Vector2i(4, 3)) == GridManager.TILE_HOT_NODE, "mission 6 reset must remain unchanged")
	grid.reset_mission_layout(9)
	_expect(grid.get_tile(Vector2i(3, 3)) == GridManager.TILE_STEPPED_FLOOR, "mission 9 reset must remain unchanged")

	grid.free()
	if failures.is_empty():
		print("TASK TEST catalog layout contract OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
