extends RefCounted
class_name WallRoutingValidationService

const VALID_SIDES: Array[String] = ["NE", "NW", "SE", "SW"]

static func _normalize_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper()
	return side if side in VALID_SIDES else ""

static func _opposite_side(side: String) -> String:
	match _normalize_side(side):
		"NE": return "SW"
		"NW": return "SE"
		"SE": return "NW"
		"SW": return "NE"
	return ""

static func _side_delta(side: String) -> Vector2i:
	match _normalize_side(side):
		"NE": return Vector2i(0, -1)
		"NW": return Vector2i(-1, 0)
		"SE": return Vector2i(1, 0)
		"SW": return Vector2i(0, 1)
	return Vector2i.ZERO

static func is_wall_routing_utility_object(object_data: Dictionary) -> bool:
	if bool(object_data.get("wall_routing_visual_enabled", false)):
		return true
	var kind: String = str(object_data.get("routing_kind", "")).strip_edges().to_lower()
	return kind in ["air_duct", "water_pipe"]

static func _route_mode(object_data: Dictionary) -> String:
	var mode: String = str(object_data.get("route_mode", object_data.get("wall_routing_mode", "outer"))).strip_edges().to_lower()
	return "inner" if mode == "inner" else "outer"

static func _route_sides(object_data: Dictionary) -> Array[String]:
	var sides: Array[String] = []
	for key in ["wall_side_1", "wall_side_2"]:
		var side: String = _normalize_side(object_data.get(key, ""))
		if not side.is_empty():
			sides.append(side)
	return sides

static func _object_cell(object_data: Dictionary, fallback: Vector2i) -> Vector2i:
	var value: Variant = object_data.get("position", object_data.get("cell", fallback))
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(int(dict.get("x", fallback.x)), int(dict.get("y", fallback.y)))
	return fallback

static func _objects_at_cell(grid_manager: Node, cell: Vector2i) -> Array[Dictionary]:
	if grid_manager == null:
		return []
	if grid_manager.has_method("get_world_objects_at_cell"):
		var method_rows: Array[Dictionary] = []
		for row in Array(grid_manager.call("get_world_objects_at_cell", cell)):
			if row is Dictionary:
				method_rows.append(Dictionary(row))
		return method_rows
	var world_objects_lookup_variant: Variant = grid_manager.get("world_objects_by_cell")
	if world_objects_lookup_variant is Dictionary:
		var raw: Variant = Dictionary(world_objects_lookup_variant).get(cell, [])
		if raw is Dictionary:
			return [Dictionary(raw)]
		if raw is Array:
			var lookup_rows: Array[Dictionary] = []
			for row in Array(raw):
				if row is Dictionary:
					lookup_rows.append(Dictionary(row))
			return lookup_rows
	var mission_world_objects_variant: Variant = grid_manager.get("mission_world_objects")
	if mission_world_objects_variant is Array:
		var scan_rows: Array[Dictionary] = []
		for row in Array(mission_world_objects_variant):
			if row is Dictionary and _object_cell(Dictionary(row), Vector2i(-9999, -9999)) == cell:
				scan_rows.append(Dictionary(row))
		return scan_rows
	return []

static func collect_warnings(object_data: Dictionary, cell: Vector2i, grid_manager: Node) -> Array[String]:
	var warnings: Array[String] = []
	if not is_wall_routing_utility_object(object_data) or _route_mode(object_data) != "inner":
		return warnings
	var sides: Array[String] = _route_sides(object_data)
	if sides.size() >= 2 and sides[0] == sides[1]:
		warnings.append("Inner routing sides must be different.")
	var kind: String = str(object_data.get("routing_kind", "")).strip_edges().to_lower()
	for side in sides:
		var opposite: String = _opposite_side(side)
		var neighbor_cell: Vector2i = cell + _side_delta(side)
		var found: bool = false
		for neighbor in _objects_at_cell(grid_manager, neighbor_cell):
			if not is_wall_routing_utility_object(neighbor):
				continue
			found = true
			if str(neighbor.get("routing_kind", "")).strip_edges().to_lower() != kind:
				warnings.append("Neighbor routing kind mismatch: expected %s." % kind)
			elif _route_mode(neighbor) != "inner":
				warnings.append("Neighbor routing mode mismatch: expected inner.")
			elif not _route_sides(neighbor).has(opposite):
				warnings.append("Neighbor port side mismatch: expected %s." % opposite)
			break
		if not found:
			warnings.append("No matching neighboring routing port on %s." % opposite)
	return warnings
