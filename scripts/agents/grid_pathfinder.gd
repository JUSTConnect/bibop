extends RefCounted

const PassabilitySystemRef = preload("res://scripts/world/passability_system.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

static func find_path(
	start: Vector2i,
	goal: Vector2i,
	repository: RefCounted,
	columns: int,
	rows: int,
	allowed_cells: Array[Vector2i] = []
) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var allowed_lookup: Dictionary = {}
	for cell: Vector2i in allowed_cells:
		allowed_lookup[_key(cell)] = true
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {_key(start): start}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = current + direction
			if not _inside(next, columns, rows):
				continue
			if not allowed_lookup.is_empty() and not allowed_lookup.has(_key(next)):
				continue
			if came_from.has(_key(next)):
				continue
			if not PassabilitySystemRef.is_passable(next, repository):
				continue
			came_from[_key(next)] = current
			if next == goal:
				return _reconstruct(start, goal, came_from)
			frontier.append(next)
	return []

static func _reconstruct(start: Vector2i, goal: Vector2i, came_from: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = [goal]
	var current: Vector2i = goal
	while current != start:
		current = Vector2i(came_from[_key(current)])
		result.push_front(current)
	return result

static func _inside(cell: Vector2i, columns: int, rows: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows

static func _key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
