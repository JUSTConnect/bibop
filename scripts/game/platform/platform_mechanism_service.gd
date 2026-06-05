extends RefCounted
class_name PlatformMechanismService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

static func normalize_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is Vector2:
		var vector_value: Vector2 = value as Vector2
		return Vector2i(int(round(vector_value.x)), int(round(vector_value.y)))
	if value is Dictionary:
		var data: Dictionary = value as Dictionary
		return Vector2i(int(data.get("x", data.get("cell_x", 0))), int(data.get("y", data.get("cell_y", 0))))
	return Vector2i.ZERO

static func get_platform_cell(platform_data: Dictionary) -> Vector2i:
	if platform_data.has("cell"):
		return normalize_cell(platform_data.get("cell"))
	if platform_data.has("position"):
		return normalize_cell(platform_data.get("position"))
	return Vector2i(int(platform_data.get("x", platform_data.get("cell_x", 0))), int(platform_data.get("y", platform_data.get("cell_y", 0))))

static func get_platform_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("id", platform_data.get("object_id", platform_data.get("platform_id", "")))).strip_edges()

static func get_mechanism_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("mechanism_id", platform_data.get("platform_mechanism_id", ""))).strip_edges()

static func is_platform_data(platform_data: Dictionary) -> bool:
	var type_value: String = str(platform_data.get("object_type", platform_data.get("type", platform_data.get("platform_type", "")))).to_lower().strip_edges()
	var prefab_value: String = str(platform_data.get("map_constructor_prefab_id", platform_data.get("catalog_id", ""))).to_lower().strip_edges()
	return type_value.contains("platform") or prefab_value.contains("platform") or platform_data.has("platform_mode")

static func collect_platforms_by_mechanism(platforms: Array[Dictionary]) -> Dictionary:
	var grouped: Dictionary = {}
	for platform_data in platforms:
		if not is_platform_data(platform_data):
			continue
		var mechanism_id: String = get_mechanism_id(platform_data)
		if mechanism_id.is_empty():
			mechanism_id = "single:%s" % get_platform_id(platform_data)
		if not grouped.has(mechanism_id):
			grouped[mechanism_id] = []
		var members: Array = Array(grouped.get(mechanism_id, []))
		members.append(platform_data)
		grouped[mechanism_id] = members
	return grouped

static func get_member_cells(members: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	for member_variant in members:
		if not member_variant is Dictionary:
			continue
		var member_data: Dictionary = member_variant as Dictionary
		var cell: Vector2i = get_platform_cell(member_data)
		var key: String = "%s:%s" % [cell.x, cell.y]
		if seen.has(key):
			continue
		seen[key] = true
		cells.append(cell)
	return cells

static func get_cell_bounds(cells: Array[Vector2i]) -> Dictionary:
	if cells.is_empty():
		return {"ok": false, "min_x": 0, "max_x": 0, "min_y": 0, "max_y": 0, "width": 0, "height": 0}
	var min_x: int = cells[0].x
	var max_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_y: int = cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	return {"ok": true, "min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y, "width": max_x - min_x + 1, "height": max_y - min_y + 1}

static func are_cells_orthogonally_connected(cells: Array[Vector2i]) -> bool:
	if cells.size() <= 1:
		return true
	var cell_lookup: Dictionary = {}
	for cell in cells:
		cell_lookup["%s:%s" % [cell.x, cell.y]] = true
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [cells[0]]
	visited["%s:%s" % [cells[0].x, cells[0].y]] = true
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction in directions:
			var next_cell: Vector2i = current + direction
			var key: String = "%s:%s" % [next_cell.x, next_cell.y]
			if not cell_lookup.has(key) or visited.has(key):
				continue
			visited[key] = true
			queue.append(next_cell)
	return visited.size() == cells.size()

static func is_square_footprint(cells: Array[Vector2i], require_filled: bool = true) -> bool:
	if cells.is_empty():
		return false
	var bounds: Dictionary = get_cell_bounds(cells)
	var width: int = int(bounds.get("width", 0))
	var height: int = int(bounds.get("height", 0))
	if width <= 0 or height <= 0 or width != height:
		return false
	if not require_filled:
		return true
	return cells.size() == width * height

static func has_any_ground_adjacency(cells: Array[Vector2i], ground_cells: Array[Vector2i]) -> bool:
	if cells.is_empty() or ground_cells.is_empty():
		return false
	var ground_lookup: Dictionary = {}
	for ground_cell in ground_cells:
		ground_lookup["%s:%s" % [ground_cell.x, ground_cell.y]] = true
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	for cell in cells:
		for direction in directions:
			var adjacent: Vector2i = cell + direction
			if ground_lookup.has("%s:%s" % [adjacent.x, adjacent.y]):
				return true
	return false

static func validate_mechanism(mechanism_id: String, members: Array, ground_cells: Array[Vector2i] = []) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var cells: Array[Vector2i] = get_member_cells(members)
	if members.is_empty():
		errors.append("Platform mechanism has no members.")
	if cells.is_empty():
		errors.append("Platform mechanism has no valid cells.")
	if cells.size() != members.size():
		warnings.append("Some platform members share the same cell or have invalid cell data.")
	if not are_cells_orthogonally_connected(cells):
		errors.append("Platform mechanism members must be orthogonally connected.")
	var platform_mode: String = PlatformTypesRef.MODE_ELEVATOR
	if not members.is_empty() and members[0] is Dictionary:
		platform_mode = PlatformTypesRef.normalize_platform_mode(str(Dictionary(members[0]).get("platform_mode", "")))
	if PlatformTypesRef.platform_mode_supports_rotator(platform_mode) and not is_square_footprint(cells, true):
		errors.append("Rotating platform mechanisms must form a filled square footprint.")
	if PlatformTypesRef.platform_mode_supports_elevator(platform_mode) and not ground_cells.is_empty() and not has_any_ground_adjacency(cells, ground_cells):
		warnings.append("Elevator platform mechanism has no adjacency to raised ground/top surface.")
	return {
		"ok": errors.is_empty(),
		"mechanism_id": mechanism_id,
		"platform_mode": platform_mode,
		"member_count": members.size(),
		"cells": cells,
		"bounds": get_cell_bounds(cells),
		"errors": errors,
		"warnings": warnings
	}

static func build_mechanism_summary(mechanism_id: String, members: Array) -> Dictionary:
	var cells: Array[Vector2i] = get_member_cells(members)
	var platform_ids: Array[String] = []
	for member_variant in members:
		if member_variant is Dictionary:
			var platform_id: String = get_platform_id(member_variant as Dictionary)
			if not platform_id.is_empty():
				platform_ids.append(platform_id)
	return {
		"mechanism_id": mechanism_id,
		"member_count": members.size(),
		"platform_ids": platform_ids,
		"cells": cells,
		"bounds": get_cell_bounds(cells),
		"is_connected": are_cells_orthogonally_connected(cells),
		"is_square": is_square_footprint(cells, true)
	}
