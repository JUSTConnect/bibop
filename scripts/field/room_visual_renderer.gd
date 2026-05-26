extends Node2D
class_name RoomVisualRenderer

# GridManager remains the gameplay grid source.
# RoomVisualRenderer is a future visual projection layer.
# Gameplay cells remain Vector2i in GridManager logic.
# The helpers in this script are visual projection helpers only.
# Future PRs will use them for floor, wall, object, fog, and overlay rendering.
@export var debug_draw_marker: bool = false
@export var debug_draw_iso_helper_preview: bool = false
@export var render_iso_floor_prototype: bool = false
@export var debug_draw_iso_cell_outlines: bool = true
@export var iso_tile_width: float = 128.0
@export var iso_tile_height: float = 64.0
@export var iso_origin: Vector2 = Vector2.ZERO

var _grid_manager: GridManager = null
var _rebuild_requested: bool = false

func set_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid
	request_rebuild()

func initialize_from_grid(grid: GridManager) -> void:
	set_grid_manager(grid)

func request_rebuild() -> void:
	_rebuild_requested = true
	rebuild_visuals()
	queue_redraw()

func clear_visuals() -> void:
	_rebuild_requested = false
	queue_redraw()

func rebuild_visuals() -> void:
	if _grid_manager == null:
		_rebuild_requested = false
		return
	# Placeholder only: future PRs will build projected room visuals here.
	_rebuild_requested = false

func get_iso_tile_half_size() -> Vector2:
	# Visual safety clamp to avoid invalid projection values.
	var safe_width: float = max(iso_tile_width, 1.0)
	var safe_height: float = max(iso_tile_height, 1.0)
	return Vector2(safe_width * 0.5, safe_height * 0.5)

func grid_to_iso(cell: Vector2i) -> Vector2:
	# Converts gameplay grid coordinates (Vector2i) into visual isometric space.
	var half_size: Vector2 = get_iso_tile_half_size()
	var iso_x: float = float(cell.x - cell.y) * half_size.x
	var iso_y: float = float(cell.x + cell.y) * half_size.y
	return iso_origin + Vector2(iso_x, iso_y)

func iso_to_grid(iso_position: Vector2) -> Vector2i:
	# Converts visual isometric position back to an approximate gameplay cell.
	# This is intended for future selection/click helpers, not movement logic.
	var half_size: Vector2 = get_iso_tile_half_size()
	var local_iso: Vector2 = iso_position - iso_origin
	var grid_x: float = (local_iso.x / half_size.x + local_iso.y / half_size.y) * 0.5
	var grid_y: float = (local_iso.y / half_size.y - local_iso.x / half_size.x) * 0.5
	return Vector2i(int(round(grid_x)), int(round(grid_y)))

func get_iso_diamond_points(cell: Vector2i) -> PackedVector2Array:
	var center_point: Vector2 = grid_to_iso(cell)
	var half_size: Vector2 = get_iso_tile_half_size()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(center_point + Vector2(0.0, -half_size.y))
	points.append(center_point + Vector2(half_size.x, 0.0))
	points.append(center_point + Vector2(0.0, half_size.y))
	points.append(center_point + Vector2(-half_size.x, 0.0))
	return points

func get_iso_depth_key(cell: Vector2i) -> int:
	return cell.x + cell.y

func is_floor_like_tile(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_WALL:
		return false

	return (
		tile_type == GridManager.TILE_FLOOR
		or tile_type == GridManager.TILE_KEY
		or tile_type == GridManager.TILE_EXIT
		or tile_type == GridManager.TILE_TERMINAL
		or tile_type == GridManager.TILE_DIGITAL_DOOR
		or tile_type == GridManager.TILE_COMPONENT
		or tile_type == GridManager.TILE_HIDDEN_ROUTE_NODE
		or tile_type == GridManager.TILE_ROUTE_GATE
		or tile_type == GridManager.TILE_HOT_NODE
		or tile_type == GridManager.TILE_AIRFLOW_TERMINAL
		or tile_type == GridManager.TILE_FAN_PLATFORM
		or tile_type == GridManager.TILE_PLATFORM_CONTROL
		or tile_type == GridManager.TILE_FAN_CONTROL
		or tile_type == GridManager.TILE_AIRFLOW
		or tile_type == GridManager.TILE_PLATFORM_CONTROL_LEFT
		or tile_type == GridManager.TILE_PLATFORM_CONTROL_RIGHT
		or tile_type == GridManager.TILE_FAN_SPEED_UP_CONTROL
		or tile_type == GridManager.TILE_FAN_SPEED_DOWN_CONTROL
		or tile_type == GridManager.TILE_CABLE_REEL
		or tile_type == GridManager.TILE_SOCKET
		or tile_type == GridManager.TILE_POWERED_GATE
		or tile_type == GridManager.TILE_CABLE
		or tile_type == GridManager.TILE_STEPPED_FLOOR
	)

func get_floor_prototype_color(tile_type: int, cell: Vector2i) -> Color:
	# Procedural prototype floor colors for dark industrial sci-fi paneling.
	# Final assets / TileSet-driven rendering will replace this in future PRs.
	var base_color: Color = Color(0.115, 0.125, 0.145, 0.96)
	var parity: int = (cell.x + cell.y) % 2
	if parity != 0:
		base_color = Color(0.135, 0.145, 0.165, 0.96)

	if tile_type == GridManager.TILE_TERMINAL or tile_type == GridManager.TILE_AIRFLOW_TERMINAL:
		base_color = base_color.lerp(Color(0.16, 0.23, 0.29, 0.98), 0.35)
	elif tile_type == GridManager.TILE_EXIT:
		base_color = base_color.lerp(Color(0.14, 0.24, 0.2, 0.98), 0.4)
	elif tile_type == GridManager.TILE_DIGITAL_DOOR or tile_type == GridManager.TILE_POWERED_GATE:
		base_color = base_color.lerp(Color(0.14, 0.2, 0.27, 0.98), 0.3)
	elif tile_type == GridManager.TILE_HOT_NODE:
		base_color = base_color.lerp(Color(0.23, 0.16, 0.15, 0.98), 0.25)

	return base_color

func draw_iso_floor_prototype() -> void:
	# Procedural prototype floor renderer for early isometric look exploration.
	# Gameplay remains square-grid based in GridManager; this is visual-only.
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if not is_floor_like_tile(tile_type):
				continue

			var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
			var fill_color: Color = get_floor_prototype_color(tile_type, cell)
			draw_colored_polygon(diamond_points, fill_color)
			if debug_draw_iso_cell_outlines:
				for edge_index in range(diamond_points.size()):
					var next_index: int = (edge_index + 1) % diamond_points.size()
					draw_line(diamond_points[edge_index], diamond_points[next_index], Color(0.21, 0.33, 0.39, 0.85), 1.0)

func _draw() -> void:
	if debug_draw_marker:
		draw_circle(Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75))

	if render_iso_floor_prototype:
		draw_iso_floor_prototype()

	if not debug_draw_iso_helper_preview:
		return

	var preview_points: PackedVector2Array = get_iso_diamond_points(Vector2i.ZERO)
	draw_colored_polygon(preview_points, Color(0.2, 0.8, 1.0, 0.15))
	for idx in preview_points.size():
		var next_idx: int = (idx + 1) % preview_points.size()
		draw_line(preview_points[idx], preview_points[next_idx], Color(0.2, 0.8, 1.0, 0.9), 1.0)
