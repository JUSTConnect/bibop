extends RefCounted
class_name CableTopologyService

const ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH: String = "3-way and 4-way cable junctions require a circuit switch."

const DIR_NORTH: String = "north"
const DIR_SOUTH: String = "south"
const DIR_WEST: String = "west"
const DIR_EAST: String = "east"

const NEIGHBOR_DELTAS: Dictionary = {
	DIR_NORTH: Vector2i(0, -1),
	DIR_SOUTH: Vector2i(0, 1),
	DIR_WEST: Vector2i(-1, 0),
	DIR_EAST: Vector2i(1, 0)
}

static func classify_cell(cell: Vector2i, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = build_cable_cell_map(world_objects, preview_object)
	if not cable_cells.has(cell):
		return _make_topology(cell, {}, 0, "isolated", true, false)
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	var neighbors: Dictionary = detect_adjacent_cable_cells(cell, cable_cells)
	var neighbor_count: int = _count_true_neighbors(neighbors)
	var is_switch: bool = bool(cell_data.get("has_circuit_switch", false))
	var shape: String = _shape_for_neighbors(neighbors, neighbor_count, is_switch)
	var is_valid: bool = is_switch or neighbor_count < 3
	return _make_topology(cell, neighbors, neighbor_count, shape, is_valid, is_switch)

static func validate_cell(cell: Vector2i, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var topology: Dictionary = classify_cell(cell, world_objects, preview_object)
	if bool(topology.get("valid", true)):
		return {"ok": true, "message": "OK", "topology": topology}
	return {"ok": false, "message": ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH, "topology": topology}

static func validate_placement(cell: Vector2i, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = build_cable_cell_map(world_objects, preview_object)
	if not cable_cells.has(cell):
		return {"ok": true, "message": "OK", "topologies": []}
	var cells_to_check: Array[Vector2i] = [cell]
	for delta in NEIGHBOR_DELTAS.values():
		var neighbor_cell: Vector2i = cell + Vector2i(delta)
		if cable_cells.has(neighbor_cell):
			cells_to_check.append(neighbor_cell)
	return _validate_cells(cells_to_check, world_objects, preview_object)

static func validate_cable_object(world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = build_cable_cell_map([], preview_object)
	var cells_to_check: Array[Vector2i] = []
	for cable_cell_variant in cable_cells.keys():
		var cable_cell: Vector2i = Vector2i(cable_cell_variant)
		cells_to_check.append(cable_cell)
		for delta in NEIGHBOR_DELTAS.values():
			var neighbor_cell: Vector2i = cable_cell + Vector2i(delta)
			cells_to_check.append(neighbor_cell)
	return _validate_cells(cells_to_check, world_objects, preview_object)

static func _validate_cells(cells_to_check: Array[Vector2i], world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var topologies: Array[Dictionary] = []
	var checked_cells: Dictionary = {}
	for check_cell in cells_to_check:
		if checked_cells.has(check_cell):
			continue
		checked_cells[check_cell] = true
		var topology: Dictionary = classify_cell(check_cell, world_objects, preview_object)
		topologies.append(topology)
		if not bool(topology.get("valid", true)):
			return {"ok": false, "message": ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH, "topologies": topologies, "failed_cell": check_cell, "topology": topology}
	return {"ok": true, "message": "OK", "topologies": topologies}

static func detect_adjacent_cable_cells(cell: Vector2i, cable_cells: Dictionary) -> Dictionary:
	return {
		DIR_NORTH: cable_cells.has(cell + Vector2i(NEIGHBOR_DELTAS[DIR_NORTH])),
		DIR_SOUTH: cable_cells.has(cell + Vector2i(NEIGHBOR_DELTAS[DIR_SOUTH])),
		DIR_WEST: cable_cells.has(cell + Vector2i(NEIGHBOR_DELTAS[DIR_WEST])),
		DIR_EAST: cable_cells.has(cell + Vector2i(NEIGHBOR_DELTAS[DIR_EAST]))
	}

static func build_cable_cell_map(world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = {}
	for object_variant in world_objects:
		if object_variant is Dictionary:
			_add_object_to_cable_cell_map(cable_cells, Dictionary(object_variant))
	if not preview_object.is_empty():
		_add_object_to_cable_cell_map(cable_cells, preview_object)
	return cable_cells

static func is_cable_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).strip_edges().to_lower()
	if object_type == "circuit_switch":
		return true
	return object_type == "power_cable" or object_type == "power_cable_reel" or object_type.contains("cable") or object_type.contains("wire")

static func is_circuit_switch_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	return object_type == "circuit_switch"

static func _add_object_to_cable_cell_map(cable_cells: Dictionary, object_data: Dictionary) -> void:
	if not is_cable_object(object_data):
		return
	var is_switch: bool = is_circuit_switch_object(object_data)
	var primary_cell: Vector2i = _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	_add_cable_cell(cable_cells, primary_cell, is_switch, object_data)
	for path_cell_variant in Array(object_data.get("cable_path_cells", [])):
		_add_cable_cell(cable_cells, _try_parse_cell_variant(path_cell_variant, Vector2i(-1, -1)), false, object_data)
	for end_index in range(1, 3):
		for path_cell_variant in Array(object_data.get("end_%d_path_cells" % end_index, [])):
			_add_cable_cell(cable_cells, _try_parse_cell_variant(path_cell_variant, Vector2i(-1, -1)), false, object_data)

static func _add_cable_cell(cable_cells: Dictionary, cell: Vector2i, has_circuit_switch: bool, object_data: Dictionary) -> void:
	if cell.x < 0 or cell.y < 0:
		return
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	cell_data["has_cable"] = true
	cell_data["has_circuit_switch"] = bool(cell_data.get("has_circuit_switch", false)) or has_circuit_switch
	var objects: Array = Array(cell_data.get("objects", []))
	objects.append(object_data)
	cell_data["objects"] = objects
	cable_cells[cell] = cell_data

static func _shape_for_neighbors(neighbors: Dictionary, neighbor_count: int, allow_junction: bool) -> String:
	var north: bool = bool(neighbors.get(DIR_NORTH, false))
	var south: bool = bool(neighbors.get(DIR_SOUTH, false))
	var west: bool = bool(neighbors.get(DIR_WEST, false))
	var east: bool = bool(neighbors.get(DIR_EAST, false))
	if neighbor_count <= 0:
		return "isolated"
	if neighbor_count == 1:
		if north:
			return "end_n"
		if south:
			return "end_s"
		if east:
			return "end_e"
		return "end_w"
	if neighbor_count == 2:
		if west and east:
			return "straight_x"
		if north and south:
			return "straight_y"
		if north and east:
			return "corner_ne"
		if north and west:
			return "corner_nw"
		if south and east:
			return "corner_se"
		return "corner_sw"
	if neighbor_count == 3:
		return "junction_t" if allow_junction else "invalid_t_junction"
	return "junction_cross" if allow_junction else "invalid_cross"

static func _make_topology(cell: Vector2i, neighbors: Dictionary, neighbor_count: int, shape: String, is_valid: bool, has_circuit_switch: bool) -> Dictionary:
	return {
		"cell": cell,
		"neighbors": neighbors,
		"neighbor_count": neighbor_count,
		"shape": shape,
		"valid": is_valid,
		"has_circuit_switch": has_circuit_switch,
		"message": "" if is_valid else ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH
	}

static func _count_true_neighbors(neighbors: Dictionary) -> int:
	var count: int = 0
	for value in neighbors.values():
		if bool(value):
			count += 1
	return count

static func _try_parse_cell_variant(value: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if value is Vector2i or value is Vector2:
		return Vector2i(value)
	if value is Dictionary:
		return Vector2i(int(value.get("x", fallback.x)), int(value.get("y", fallback.y)))
	var text: String = str(value).strip_edges()
	if text.is_empty():
		return fallback
	var parts: PackedStringArray = text.split(",")
	if parts.size() != 2:
		return fallback
	if not parts[0].strip_edges().is_valid_int() or not parts[1].strip_edges().is_valid_int():
		return fallback
	return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
