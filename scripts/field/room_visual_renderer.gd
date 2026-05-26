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
@export var render_iso_wall_prototype: bool = false
@export var debug_draw_iso_cell_outlines: bool = true
@export var debug_draw_iso_wall_outlines: bool = true
@export var iso_tile_width: float = 128.0
@export var iso_tile_height: float = 64.0
@export var iso_wall_height: float = 56.0
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

func sort_cells_by_iso_depth(a: Vector2i, b: Vector2i) -> bool:
	var depth_a: int = get_iso_depth_key(a)
	var depth_b: int = get_iso_depth_key(b)
	if depth_a == depth_b:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	return depth_a < depth_b

func is_floor_like_tile(tile_type: int) -> bool:
	return tile_type != GridManager.TILE_WALL

func is_wall_tile(tile_type: int) -> bool:
	return tile_type == GridManager.TILE_WALL

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
	elif tile_type == GridManager.TILE_DOOR:
		base_color = base_color.lerp(Color(0.2, 0.17, 0.13, 0.98), 0.22)
	elif tile_type == GridManager.TILE_HOT_NODE:
		base_color = base_color.lerp(Color(0.23, 0.16, 0.15, 0.98), 0.25)

	return base_color

func get_wall_prototype_colors(cell: Vector2i) -> Dictionary:
	var parity: int = (cell.x + cell.y) % 2
	var top_color: Color = Color(0.205, 0.225, 0.255, 0.98)
	var left_color: Color = Color(0.125, 0.14, 0.165, 0.98)
	var right_color: Color = Color(0.1, 0.115, 0.14, 0.98)
	if parity != 0:
		top_color = Color(0.225, 0.245, 0.275, 0.98)
		left_color = Color(0.14, 0.155, 0.18, 0.98)
		right_color = Color(0.115, 0.13, 0.155, 0.98)

	return {
		"top": top_color,
		"left": left_color,
		"right": right_color,
		"outline": Color(0.24, 0.31, 0.36, 0.9)
	}

func get_iso_wall_top_points(cell: Vector2i) -> PackedVector2Array:
	var bottom_points: PackedVector2Array = get_iso_diamond_points(cell)
	var top_points: PackedVector2Array = PackedVector2Array()
	var safe_wall_height: float = max(iso_wall_height, 1.0)
	var wall_offset: Vector2 = Vector2(0.0, -safe_wall_height)
	for point in bottom_points:
		top_points.append(point + wall_offset)
	return top_points

func draw_iso_wall_block(cell: Vector2i) -> void:
	var bottom_points: PackedVector2Array = get_iso_diamond_points(cell)
	if bottom_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var colors: Dictionary = get_wall_prototype_colors(cell)
	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], bottom_points[2], bottom_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], bottom_points[1], bottom_points[2]])

	draw_colored_polygon(left_face, colors["left"])
	draw_colored_polygon(right_face, colors["right"])
	draw_colored_polygon(top_face, colors["top"])

	if debug_draw_iso_wall_outlines:
		for edge_idx in range(top_face.size()):
			var top_next_idx: int = (edge_idx + 1) % top_face.size()
			draw_line(top_face[edge_idx], top_face[top_next_idx], colors["outline"], 1.0)

		for edge_idx in range(left_face.size()):
			var left_next_idx: int = (edge_idx + 1) % left_face.size()
			draw_line(left_face[edge_idx], left_face[left_next_idx], colors["outline"], 1.0)

		for edge_idx in range(right_face.size()):
			var right_next_idx: int = (edge_idx + 1) % right_face.size()
			draw_line(right_face[edge_idx], right_face[right_next_idx], colors["outline"], 1.0)

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

func draw_iso_wall_prototype() -> void:
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var wall_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if is_wall_tile(tile_type):
				wall_cells.append(cell)

	wall_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in wall_cells:
		draw_iso_wall_block(cell)

func _draw() -> void:
	if debug_draw_marker:
		draw_circle(Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75))

	if render_iso_floor_prototype:
		draw_iso_floor_prototype()

	if render_iso_wall_prototype:
		draw_iso_wall_prototype()

	if not debug_draw_iso_helper_preview:
		return

	var preview_points: PackedVector2Array = get_iso_diamond_points(Vector2i.ZERO)
	draw_colored_polygon(preview_points, Color(0.2, 0.8, 1.0, 0.15))
	for idx in preview_points.size():
		var next_idx: int = (idx + 1) % preview_points.size()
		draw_line(preview_points[idx], preview_points[next_idx], Color(0.2, 0.8, 1.0, 0.9), 1.0)
