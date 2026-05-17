extends Node2D
class_name GridManager

const TILE_FLOOR := 0
const TILE_WALL := 1
const TILE_DOOR := 2
const TILE_KEY := 3
const TILE_EXIT := 4
const TILE_TERMINAL := 5
const TILE_DIGITAL_DOOR := 6
const TILE_COMPONENT := 7
const TILE_HIDDEN_ROUTE_NODE := 8
const TILE_ROUTE_GATE := 9
const TILE_HOT_NODE := 10
const TILE_AIRFLOW_TERMINAL := 11
const TILE_FAN_PLATFORM := 12
const TILE_PLATFORM_CONTROL := 13
const TILE_FAN_CONTROL := 14
const TILE_AIRFLOW := 15

@export var cell_size: int = 64
@export var fog_enabled: bool = true
@export var reveal_radius: int = 1

var debug_draw_undiscovered_hidden_nodes: bool = false

var visible_cells: Array = []
var explored_cells: Array = []
var discovered_hidden_route_nodes: Dictionary = {}

var map_data: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 2, 1],
	[1, 0, 1, 1, 0, 5, 6, 1],
	[1, 0, 0, 0, 0, 1, 0, 1],
	[1, 0, 0, 3, 0, 1, 7, 1],
	[1, 0, 1, 1, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 4, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]


var mission_initial_map_data: Array = []

var tile_colors := {
	TILE_FLOOR: Color(0.16, 0.16, 0.18),
	TILE_WALL: Color(0.05, 0.05, 0.06),
	TILE_DOOR: Color(0.45, 0.25, 0.08),
	TILE_KEY: Color(0.95, 0.75, 0.15),
	TILE_EXIT: Color(0.15, 0.65, 0.35),
	TILE_TERMINAL: Color(0.6, 0.25, 0.75),
	TILE_DIGITAL_DOOR: Color(0.1, 0.4, 0.85),
	TILE_COMPONENT: Color(0.9, 0.45, 0.15),
	TILE_HIDDEN_ROUTE_NODE: Color(0.16, 0.16, 0.18),
	TILE_ROUTE_GATE: Color(0.12, 0.56, 0.7),
	TILE_HOT_NODE: Color(1.0, 0.25, 0.1),
	TILE_AIRFLOW_TERMINAL: Color(0.75, 0.2, 0.85),
	TILE_FAN_PLATFORM: Color(0.45, 0.47, 0.52),
	TILE_PLATFORM_CONTROL: Color(0.95, 0.8, 0.22),
	TILE_FAN_CONTROL: Color(0.2, 0.8, 1.0),
	TILE_AIRFLOW: Color(0.45, 0.85, 1.0, 0.65),
}

func _ready() -> void:
	cache_initial_mission_layout()
	setup_fog_arrays()
	queue_redraw()


func duplicate_map_layout(layout: Array) -> Array:
	var duplicated_layout: Array = []
	for row_variant in layout:
		var row: Array = row_variant
		duplicated_layout.append(row.duplicate())
	return duplicated_layout

func cache_initial_mission_layout() -> void:
	mission_initial_map_data = duplicate_map_layout(map_data)

func get_mission4_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 7, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, 1, 0, 1],
		[1, 1, 1, 1, 0, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 7, 0, 8, 0, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]

func get_mission6_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, 0, TILE_HOT_NODE, 6, 0, 1],
		[1, 1, 1, 0, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]


func get_mission8_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, TILE_PLATFORM_CONTROL, 0, TILE_FAN_PLATFORM, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, TILE_AIRFLOW_TERMINAL, 1],
		[1, 0, TILE_FAN_CONTROL, 0, 0, 0, TILE_DIGITAL_DOOR, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]

func reset_mission_layout(mission_index: int) -> void:
	if mission_initial_map_data.is_empty():
		cache_initial_mission_layout()

	if mission_index == 4:
		map_data = duplicate_map_layout(get_mission4_layout())
	elif mission_index == 6:
		map_data = duplicate_map_layout(get_mission6_layout())
	elif mission_index == 8:
		map_data = duplicate_map_layout(get_mission8_layout())
	else:
		map_data = duplicate_map_layout(mission_initial_map_data)
	reset_hidden_discoveries()
	queue_redraw()

func reset_fog_of_war() -> void:
	setup_fog_arrays()
	queue_redraw()

func _draw() -> void:
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var grid_position := Vector2i(x, y)
			var tile_type: int = map_data[y][x]
			var cell_position := Vector2(x * cell_size, y * cell_size)
			var rect := Rect2(cell_position, Vector2(cell_size, cell_size))
			
			var color: Color = tile_colors.get(tile_type, Color.MAGENTA)
			if tile_type == TILE_HIDDEN_ROUTE_NODE and not is_hidden_route_node_discovered(grid_position):
				color = tile_colors.get(TILE_FLOOR, Color(0.16, 0.16, 0.18))
			
			draw_rect(rect, color, true)
			if tile_type == TILE_AIRFLOW:
				var floor_color: Color = tile_colors.get(TILE_FLOOR, Color(0.16, 0.16, 0.18))
				draw_rect(rect, floor_color, true)
				var strip_size := Vector2(cell_size * 0.55, cell_size * 0.18)
				var strip_rect := Rect2(rect.get_center() - strip_size * 0.5, strip_size)
				draw_rect(strip_rect, Color(0.62, 0.9, 1.0, 0.9), true)
				draw_circle(rect.get_center(), cell_size * 0.1, Color(0.8, 0.95, 1.0, 0.95))
			draw_rect(rect, Color(0.35, 0.35, 0.38), false, 2.0)
			if tile_type == TILE_HIDDEN_ROUTE_NODE:
				if is_hidden_route_node_discovered(grid_position):
					var discovered_marker_radius := cell_size * 0.15
					draw_circle(rect.get_center(), discovered_marker_radius, Color(0.45, 0.95, 1.0))
				elif debug_draw_undiscovered_hidden_nodes:
					var marker_size := cell_size * 0.14
					var marker_rect := Rect2(rect.get_center() - Vector2(marker_size * 0.5, marker_size * 0.5), Vector2(marker_size, marker_size))
					draw_rect(marker_rect, Color(0.24, 0.08, 0.32, 0.95), false, 2.0)
			
			if fog_enabled:
				draw_fog_for_cell(grid_position, rect)
				
func draw_fog_for_cell(grid_position: Vector2i, rect: Rect2) -> void:
	if is_cell_visible(grid_position):
		return
	
	if is_explored(grid_position):
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.55), true)
	else:
		draw_rect(rect, Color(0.02, 0.02, 0.025, 1.0), true)
		
func get_map_width() -> int:
	if map_data.is_empty():
		return 0
	
	return map_data[0].size()

func get_map_height() -> int:
	return map_data.size()

func is_in_bounds(grid_position: Vector2i) -> bool:
	return (
		grid_position.x >= 0
		and grid_position.y >= 0
		and grid_position.x < get_map_width()
		and grid_position.y < get_map_height()
	)

func get_tile(grid_position: Vector2i) -> int:
	if not is_in_bounds(grid_position):
		return TILE_WALL
	
	return map_data[grid_position.y][grid_position.x]

func is_walkable(grid_position: Vector2i) -> bool:
	var tile_type := get_tile(grid_position)
	
	if tile_type == TILE_WALL:
		return false
	
	if tile_type == TILE_DOOR:
		return false
	
	if tile_type == TILE_DIGITAL_DOOR:
		return false

	if tile_type == TILE_HOT_NODE:
		return false

	if tile_type == TILE_AIRFLOW_TERMINAL:
		return false

	if tile_type == TILE_FAN_PLATFORM:
		return false

	if tile_type == TILE_PLATFORM_CONTROL:
		return false

	if tile_type == TILE_FAN_CONTROL:
		return false

	return true

func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		grid_position.x * cell_size + cell_size / 2.0,
		grid_position.y * cell_size + cell_size / 2.0
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size),
		floori(world_position.y / cell_size)
	)
func set_tile(grid_position: Vector2i, tile_type: int) -> void:
	if not is_in_bounds(grid_position):
		push_error("GridManager: cannot set tile outside map bounds: " + str(grid_position))
		return
	
	map_data[grid_position.y][grid_position.x] = tile_type
	queue_redraw()

func setup_fog_arrays() -> void:
	visible_cells.clear()
	explored_cells.clear()
	
	for y in range(get_map_height()):
		var visible_row: Array = []
		var explored_row: Array = []
		
		for x in range(get_map_width()):
			visible_row.append(false)
			explored_row.append(false)
		
		visible_cells.append(visible_row)
		explored_cells.append(explored_row)

func clear_visible_cells() -> void:
	for y in range(get_map_height()):
		for x in range(get_map_width()):
			visible_cells[y][x] = false

func reveal_cell(grid_position: Vector2i) -> void:
	if not is_in_bounds(grid_position):
		return
	
	visible_cells[grid_position.y][grid_position.x] = true
	explored_cells[grid_position.y][grid_position.x] = true

func reveal_current_cell_only(origin_position: Vector2i) -> void:
	clear_visible_cells()
	reveal_cell(origin_position)
	queue_redraw()

func reveal_around(center_position: Vector2i) -> void:
	clear_visible_cells()
	
	for y_offset in range(-reveal_radius, reveal_radius + 1):
		for x_offset in range(-reveal_radius, reveal_radius + 1):
			var target_position := center_position + Vector2i(x_offset, y_offset)
			reveal_cell(target_position)
	
	queue_redraw()

func is_vision_blocking_tile(tile_type: int) -> bool:
	return tile_type == TILE_WALL

func has_line_of_sight(origin_position: Vector2i, target_position: Vector2i) -> bool:
	if origin_position == target_position:
		return true

	var delta := target_position - origin_position
	var steps := maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return true

	var step_vector := Vector2(float(delta.x) / float(steps), float(delta.y) / float(steps))

	for step in range(1, steps + 1):
		var sample_position := Vector2(origin_position) + step_vector * step
		var check_position := Vector2i(roundi(sample_position.x), roundi(sample_position.y))

		if not is_in_bounds(check_position):
			return false

		if check_position == target_position:
			return true

		if is_vision_blocking_tile(get_tile(check_position)):
			return false

	return false

func reveal_visible_target(origin_position: Vector2i, target_position: Vector2i) -> void:
	if not is_in_bounds(target_position):
		return

	if has_line_of_sight(origin_position, target_position):
		reveal_cell(target_position)

func reveal_by_vision(origin_position: Vector2i, direction_vector: Vector2i, vision_range: int, side_width: int = 0) -> void:
	clear_visible_cells()
	reveal_cell(origin_position)

	var side_vector := Vector2i(-direction_vector.y, direction_vector.x)
	for distance in range(1, vision_range + 1):
		var center_position := origin_position + direction_vector * distance
		reveal_visible_target(origin_position, center_position)

		for offset in range(1, side_width + 1):
			reveal_visible_target(origin_position, center_position + side_vector * offset)
			reveal_visible_target(origin_position, center_position - side_vector * offset)

	queue_redraw()

func get_visible_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(get_map_height()):
		for x in range(get_map_width()):
			if visible_cells[y][x]:
				cells.append(Vector2i(x, y))
	return cells

func get_position_key(position: Vector2i) -> String:
	return str(position.x) + "," + str(position.y)

func is_hidden_route_node_discovered(position: Vector2i) -> bool:
	return discovered_hidden_route_nodes.has(get_position_key(position))

func discover_hidden_route_node(position: Vector2i) -> void:
	if get_tile(position) != TILE_HIDDEN_ROUTE_NODE:
		return
	discovered_hidden_route_nodes[get_position_key(position)] = true
	queue_redraw()

func reset_hidden_discoveries() -> void:
	discovered_hidden_route_nodes.clear()
	queue_redraw()

func place_debug_hidden_route_node(position: Vector2i) -> void:
	if not is_in_bounds(position):
		return
	set_tile(position, TILE_HIDDEN_ROUTE_NODE)
	discovered_hidden_route_nodes.erase(get_position_key(position))
	queue_redraw()
	
func is_cell_visible(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return visible_cells[grid_position.y][grid_position.x]

func is_explored(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return explored_cells[grid_position.y][grid_position.x]	
