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
	var platform_id: String = str(platform_data.get("id", "")).strip_edges()
	if platform_id.is_empty():
		platform_id = str(platform_data.get("object_id", platform_data.get("platform_id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = str(platform_data.get("platform_id", "")).strip_edges()
	return platform_id

static func get_mechanism_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("mechanism_id", platform_data.get("platform_mechanism_id", ""))).strip_edges()

static func get_single_mechanism_id(platform_data: Dictionary) -> String:
	var platform_id: String = get_platform_id(platform_data)
	return "single:%s" % platform_id if not platform_id.is_empty() else ""

static func is_platform_data(platform_data: Dictionary) -> bool:
	var nested_data: Dictionary = Dictionary(platform_data.get("data", {}))
	if not nested_data.is_empty() and is_platform_data(nested_data):
		return true
	var type_value: String = str(platform_data.get("object_type", platform_data.get("type", platform_data.get("platform_type", "")))).to_lower().strip_edges()
	var group_value: String = str(platform_data.get("object_group", platform_data.get("group", ""))).to_lower().strip_edges()
	var archetype_value: String = str(platform_data.get("archetype_id", platform_data.get("map_constructor_prefab_id", ""))).to_lower().strip_edges()
	var prefab_value: String = str(platform_data.get("map_constructor_prefab_id", platform_data.get("catalog_id", ""))).to_lower().strip_edges()
	return type_value in ["platform", "lifting_platform", "rotating_platform"] or group_value == "platform" or archetype_value in ["platform", "lifting_platform", "rotating_platform"] or prefab_value in ["platform", "lifting_platform", "rotating_platform"] or platform_data.has("platform_mode") or platform_data.has("platform_type")

static func unwrap_platform_data(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var data: Dictionary = value as Dictionary
	if is_platform_data(data):
		return data
	var nested_data: Dictionary = Dictionary(data.get("data", {}))
	if is_platform_data(nested_data):
		var result: Dictionary = nested_data.duplicate(true)
		if not result.has("id") and data.has("id"):
			result["id"] = data.get("id")
		if not result.has("object_id") and data.has("object_id"):
			result["object_id"] = data.get("object_id")
		if not result.has("position") and data.has("position"):
			result["position"] = data.get("position")
		if not result.has("cell") and data.has("cell"):
			result["cell"] = data.get("cell")
		return result
	return {}

static func collect_platforms_by_mechanism(platforms: Array) -> Dictionary:
	var grouped: Dictionary = {}
	for platform_variant in platforms:
		var platform_data: Dictionary = unwrap_platform_data(platform_variant)
		if platform_data.is_empty() or not is_platform_data(platform_data):
			continue
		var mechanism_id: String = get_mechanism_id(platform_data)
		if mechanism_id.is_empty():
			mechanism_id = get_single_mechanism_id(platform_data)
		if mechanism_id.is_empty():
			continue
		if not grouped.has(mechanism_id):
			grouped[mechanism_id] = []
		var members: Array = Array(grouped.get(mechanism_id, []))
		members.append(platform_data)
		grouped[mechanism_id] = members
	return grouped

static func get_mechanism_members(mechanism_id: String, world_objects_or_members: Array) -> Array[Dictionary]:
	var normalized_mechanism_id: String = mechanism_id.strip_edges()
	var members: Array[Dictionary] = []
	for value in world_objects_or_members:
		var platform_data: Dictionary = unwrap_platform_data(value)
		if platform_data.is_empty() or not is_platform_data(platform_data):
			continue
		var platform_mechanism_id: String = get_mechanism_id(platform_data)
		var platform_single_id: String = get_single_mechanism_id(platform_data)
		if normalized_mechanism_id.is_empty():
			if platform_mechanism_id.is_empty():
				members.append(platform_data)
		elif normalized_mechanism_id == platform_mechanism_id or (platform_mechanism_id.is_empty() and normalized_mechanism_id == platform_single_id):
			members.append(platform_data)
	return members

static func get_member_cells(members: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	for member_variant in members:
		var member_data: Dictionary = unwrap_platform_data(member_variant)
		if member_data.is_empty():
			continue
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
	var platform_members: Array[Dictionary] = get_mechanism_members(mechanism_id, members)
	var cells: Array[Vector2i] = get_member_cells(platform_members)
	if platform_members.is_empty():
		errors.append("Platform mechanism has no members.")
	if cells.is_empty():
		errors.append("Platform mechanism has no valid cells.")
	if cells.size() != platform_members.size():
		warnings.append("Some platform members share the same cell or have invalid cell data.")
	if not are_cells_orthogonally_connected(cells):
		errors.append("Platform mechanism members must be orthogonally connected.")
	var platform_mode: String = PlatformTypesRef.MODE_ELEVATOR
	var platform_kinds: Array[String] = []
	if not platform_members.is_empty():
		platform_mode = str(PlatformTypesRef.normalize_platform_config(platform_members[0]).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
	for member_data in platform_members:
		var member_kind: String = str(PlatformTypesRef.normalize_platform_config(member_data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
		if not platform_kinds.has(member_kind):
			platform_kinds.append(member_kind)
	if platform_kinds.size() > 1:
		errors.append("Platform mechanism mixes elevator and rotating platform types.")
	if PlatformTypesRef.platform_mode_supports_rotator(platform_mode) and not is_square_footprint(cells, true):
		errors.append("Rotating platform mechanisms must form a filled square footprint.")
	if PlatformTypesRef.platform_mode_supports_elevator(platform_mode) and not ground_cells.is_empty() and not has_any_ground_adjacency(cells, ground_cells):
		warnings.append("Elevator platform mechanism has no adjacency to raised ground/top surface.")
	return {"ok": errors.is_empty(), "mechanism_id": mechanism_id, "platform_mode": platform_mode, "member_count": platform_members.size(), "cells": cells, "bounds": get_cell_bounds(cells), "errors": errors, "warnings": warnings}

static func build_mechanism_summary(mechanism_id: String, members: Array) -> Dictionary:
	var platform_members: Array[Dictionary] = []

	for member_variant in members:
		var member_data: Dictionary = unwrap_platform_data(member_variant)

		if member_data.is_empty() or not is_platform_data(member_data):
			continue

		platform_members.append(member_data)

	var cells: Array[Vector2i] = get_member_cells(platform_members)

	var platform_kinds: Array[String] = []
	for member_kind_data in platform_members:
		var member_kind: String = str(PlatformTypesRef.normalize_platform_config(member_kind_data).get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))

		if not platform_kinds.has(member_kind):
			platform_kinds.append(member_kind)

	var platform_ids: Array[String] = []
	for member_data in platform_members:
		var platform_id: String = get_platform_id(member_data)

		if not platform_id.is_empty():
			platform_ids.append(platform_id)

	var summary_errors: Array[String] = []
	if platform_members.is_empty():
		summary_errors.append("Platform mechanism has no members.")

	var summary_warnings: Array[String] = []
	if platform_kinds.size() > 1:
		summary_warnings.append("Mechanism contains mixed platform types; runtime filters members by type.")

	return {
		"ok": not platform_members.is_empty() and platform_kinds.size() <= 1,
		"mechanism_id": mechanism_id,
		"member_count": platform_members.size(),
		"platform_ids": platform_ids,
		"platform_modes": platform_kinds,
		"cells": cells,
		"bounds": get_cell_bounds(cells),
		"is_connected": are_cells_orthogonally_connected(cells),
		"is_square": is_square_footprint(cells, true),
		"errors": summary_errors,
		"warnings": summary_warnings
	}
	
static func get_mechanism_summary(mechanism_id: String, world_objects_or_members: Array) -> Dictionary:
	var members: Array[Dictionary] = get_mechanism_members(mechanism_id, world_objects_or_members)
	return build_mechanism_summary(mechanism_id, members)
