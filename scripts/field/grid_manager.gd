extends Node2D
class_name GridManager

const TILE_FLOOR := 0
const TILE_WALL := 1
const TILE_DOOR := 2
const TILE_KEY := 3
const TILE_EXIT := 4
const TILE_TERMINAL := 5
const TILE_DIGITAL_DOOR := 6

@export var cell_size: int = 64
@export var fog_enabled: bool = true
@export var reveal_radius: int = 1

var visible_cells: Array = []
var explored_cells: Array = []

var map_data: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 2, 1],
	[1, 0, 1, 1, 0, 5, 6, 1],
	[1, 0, 0, 0, 0, 1, 0, 1],
	[1, 0, 0, 3, 0, 1, 0, 1],
	[1, 0, 1, 1, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 4, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

var tile_colors := {
	TILE_FLOOR: Color(0.16, 0.16, 0.18),
	TILE_WALL: Color(0.05, 0.05, 0.06),
	TILE_DOOR: Color(0.45, 0.25, 0.08),
	TILE_KEY: Color(0.95, 0.75, 0.15),
	TILE_EXIT: Color(0.15, 0.65, 0.35),
	TILE_TERMINAL: Color(0.6, 0.25, 0.75),
	TILE_DIGITAL_DOOR: Color(0.1, 0.4, 0.85),
}

func _ready() -> void:
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
			
			draw_rect(rect, color, true)
			draw_rect(rect, Color(0.35, 0.35, 0.38), false, 2.0)
			
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

func reveal_around(center_position: Vector2i) -> void:
	clear_visible_cells()
	
	for y_offset in range(-reveal_radius, reveal_radius + 1):
		for x_offset in range(-reveal_radius, reveal_radius + 1):
			var target_position := center_position + Vector2i(x_offset, y_offset)
			reveal_cell(target_position)
	
	queue_redraw()

func reveal_by_vision(origin_position: Vector2i, direction_vector: Vector2i, vision_range: int) -> void:
	clear_visible_cells()
	
	reveal_cell(origin_position)
	
	for distance in range(1, vision_range + 1):
		var forward_position := origin_position + direction_vector * distance
		reveal_cell(forward_position)
		
		if distance <= 2:
			var side_vector := Vector2i(-direction_vector.y, direction_vector.x)
			reveal_cell(forward_position + side_vector)
			reveal_cell(forward_position - side_vector)
	
	queue_redraw()
	
func is_cell_visible(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return visible_cells[grid_position.y][grid_position.x]

func is_explored(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return explored_cells[grid_position.y][grid_position.x]	
