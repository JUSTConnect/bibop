extends SceneTree

const GridManagerScene = preload("res://scripts/field/grid_manager.gd")
const RoomVisualRendererScene = preload("res://scripts/field/room_visual_renderer.gd")
const MissionContentCatalogRef = preload("res://scripts/game/mission_content_catalog.gd")
const MissionIdsRef = preload("res://scripts/game/mission_ids.gd")

var failures: Array[String] = []
var invalidations: Array[Dictionary] = []

func _init() -> void:
	var grid: GridManager = GridManagerScene.new()
	var renderer: RoomVisualRenderer = RoomVisualRendererScene.new()
	root.add_child(grid)
	grid.add_child(renderer)
	await process_frame
	grid.grid_visual_invalidated.connect(_on_grid_invalidated)

	var grid_source := FileAccess.open("res://scripts/field/grid_manager.gd", FileAccess.READ).get_as_text()
	_expect(not grid_source.contains("func _draw("), "GridManager must not expose legacy _draw fallback")
	_expect(not grid_source.contains("func get_mission10_layout("), "GridManager must not contain a TASK TEST layout fallback")
	_expect(not grid_source.contains("mission_index == 10"), "GridManager must not contain a TASK TEST reset branch")
	_expect(not grid.has_method("get_mission10_layout"), "GridManager must not expose get_mission10_layout")

	var catalog: MissionContentCatalog = MissionContentCatalogRef.new()
	var canonical_layout: Array = catalog.get_mission_layout(MissionIdsRef.TASK_TEST_LAYOUT_ID)
	var alias_layout: Array = catalog.get_mission_layout(MissionIdsRef.TASK_TEST_COMPAT_MISSION_ID)
	_expect(not canonical_layout.is_empty(), "task_test catalog layout must exist")
	_expect(var_to_str(canonical_layout) == var_to_str(alias_layout), "mission_10 alias must resolve to canonical task_test layout")
	_expect(catalog.get_mission_layout_size(MissionIdsRef.TASK_TEST_LAYOUT_ID) == Vector2i(16, 10), "task_test catalog layout must remain 16x10")
	_expect(catalog.get_mission_start_cell(MissionIdsRef.TASK_TEST_COMPAT_MISSION_ID) == Vector2i(1, 1), "mission_10 alias must preserve start cell")
	_expect(catalog.get_mission_exit_cells(MissionIdsRef.TASK_TEST_LAYOUT_ID).has(Vector2i(14, 7)), "task_test catalog must preserve exit cell")

	_expect(grid.apply_mission_layout(canonical_layout), "GridManager must accept canonical catalog layout")
	var applied_snapshot := var_to_str(grid.map_data)
	_expect(applied_snapshot == var_to_str(canonical_layout), "canonical catalog layout must be applied exactly")
	var absent_layout: Array = catalog.get_mission_layout("absent_layout_fixture")
	_expect(absent_layout.is_empty(), "unknown catalog layout must resolve empty")
	_expect(not grid.apply_mission_layout(absent_layout), "missing catalog layout must fail closed")
	_expect(var_to_str(grid.map_data) == applied_snapshot, "missing catalog layout must not mutate active grid")
	var malformed_layout: Array = [[1, 1, 1], [1, 0]]
	_expect(not grid.apply_mission_layout(malformed_layout), "malformed catalog layout must fail closed")
	_expect(var_to_str(grid.map_data) == applied_snapshot, "malformed catalog layout must not mutate active grid")

	grid.reset_mission_layout(4)
	_expect(grid.map_data.size() == 8 and Array(grid.map_data[0]).size() == 8, "legacy mission 4 reset must remain available")
	grid.reset_mission_layout(6)
	_expect(grid.get_tile(Vector2i(4, 3)) == GridManager.TILE_HOT_NODE, "legacy mission 6 reset must remain unchanged")
	grid.reset_mission_layout(9)
	_expect(grid.get_tile(Vector2i(3, 3)) == GridManager.TILE_STEPPED_FLOOR, "legacy mission 9 reset must remain unchanged")
	grid.reset_mission_layout(4)
	invalidations.clear()

	var cell := Vector2i(2, 2)
	grid.set_tile(cell, GridManager.TILE_COMPONENT)
	_expect(grid.get_tile(cell) == GridManager.TILE_COMPONENT, "set_tile must update domain map data")
	_expect(_has_invalidation("tile", cell), "set_tile must emit tile invalidation")

	invalidations.clear()
	grid.reveal_current_cell_only(cell)
	_expect(grid.is_cell_visible(cell), "visibility mutation must set visible state")
	_expect(grid.is_explored(cell), "visibility mutation must set explored state")
	_expect(_has_invalidation("visual_state", cell) or invalidations.size() == 1, "visibility mutation must emit invalidation")

	var floor_state := grid.make_floor_visual_state(GridManager.FLOOR_FAMILY_CONCRETE, GridManager.FLOOR_WEAR_LIGHT, 2, 1, true, false, GridManager.FLOOR_HEIGHT_STEP_1)
	invalidations.clear()
	grid.set_floor_visual_state(cell, floor_state)
	var read_floor := grid.get_floor_visual_state(cell)
	_expect(str(read_floor.get("family", "")) == GridManager.FLOOR_FAMILY_CONCRETE, "floor visual state family must round-trip")
	_expect(bool(read_floor.get("mirror_h", false)), "floor visual state mirror flag must round-trip")
	_expect(invalidations.size() == 1, "floor visual mutation must emit one invalidation")

	invalidations.clear()
	grid.set_world_overlay_markers({cell: "!"})
	grid.set_fan_platform_marker(cell, Vector2i.UP)
	_expect(grid.get_world_overlay_marker(cell) == "!", "overlay marker must be readable through query API")
	var fan_marker := grid.get_fan_platform_marker()
	_expect(bool(fan_marker.get("active", false)) and Vector2i(fan_marker.get("position")) == cell, "fan marker must be readable through query API")

	_expect(renderer.is_grid_visual_invalidation_connected(), "RoomVisualRenderer must subscribe to GridManager invalidation")
	var before_count: int = renderer.debug_rebuild_request_count
	invalidations.clear()
	grid.set_tile(Vector2i(3, 3), GridManager.TILE_KEY)
	_expect(renderer.debug_rebuild_request_count == before_count + 1, "one invalidation must invoke one renderer rebuild path")

	_expect(not grid_source.contains("queue_redraw("), "GridManager source must not call Canvas redraw")

	var projected_right: Vector2 = renderer.get_projected_grid_direction(cell, Vector2i.RIGHT)
	var expected_right: Vector2 = (renderer.grid_to_iso(cell + Vector2i.RIGHT) - renderer.grid_to_iso(cell)).normalized()
	_expect(_vectors_nearly_equal(projected_right, expected_right), "fan marker RIGHT direction must use iso screen-space projection")

	grid.remove_child(renderer)
	await process_frame
	_expect(not renderer.is_grid_visual_invalidation_connected(), "renderer must disconnect invalidation signal after leaving tree")

	grid.add_child(renderer)
	await process_frame
	_expect(renderer.is_grid_visual_invalidation_connected(), "renderer must reconnect invalidation signal after re-entering tree")
	before_count = renderer.debug_rebuild_request_count
	invalidations.clear()
	grid.set_tile(Vector2i(4, 4), GridManager.TILE_EXIT)
	_expect(renderer.debug_rebuild_request_count == before_count + 1, "reconnected renderer must rebuild exactly once for next invalidation")

	invalidations.clear()
	var debug_cell := Vector2i(5, 4)
	grid.place_debug_hidden_route_node(debug_cell)
	_expect(invalidations.size() == 1, "place_debug_hidden_route_node must emit exactly one invalidation")
	_expect(_has_invalidation("hidden_route_node", debug_cell), "place_debug_hidden_route_node invalidation must include changed cell")

	grid.remove_child(renderer)
	renderer.queue_free()
	await process_frame
	invalidations.clear()
	grid.set_tile(Vector2i(4, 5), GridManager.TILE_EXIT)
	_expect(invalidations.size() == 1, "cleanup must leave only test callback connected")

	grid.queue_free()
	if failures.is_empty():
		print("GridManager renderer and TASK TEST catalog contract OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _on_grid_invalidated(reason: String, changed_cells: Array) -> void:
	invalidations.append({"reason": reason, "changed_cells": changed_cells.duplicate()})

func _has_invalidation(reason: String, cell: Vector2i) -> bool:
	for event in invalidations:
		if str(event.get("reason", "")) != reason:
			continue
		if Array(event.get("changed_cells", [])).has(cell):
			return true
	return false

func _vectors_nearly_equal(a: Vector2, b: Vector2, epsilon: float = 0.001) -> bool:
	return a.distance_to(b) <= epsilon

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
