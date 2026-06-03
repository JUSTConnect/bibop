extends RefCounted
class_name CableTopologyService

const ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH: String = "3-way and 4-way cable junctions require a circuit switch."
const WARNING_MESSAGE_EXTRA_BRANCH_SKIPPED: String = "Extra same-circuit adjacent cable is not connected. Use a circuit switch for branching."

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
const DIRECTION_ORDER: Array[String] = [DIR_NORTH, DIR_EAST, DIR_SOUTH, DIR_WEST]
const CIRCUIT_ID_KEYS: Array[String] = ["circuit_id", "power_circuit_id", "network_id", "power_network_id", "chain_id", "link_group", "cable_group", "connected_circuit"]
const EXPLICIT_CIRCUIT_ID_KEYS: Array[String] = ["circuit_id", "power_circuit_id", "network_id", "power_network_id", "chain_id", "link_group", "cable_group", "connected_circuit"]

static func normalize_circuit_id(object_data: Dictionary) -> String:
	return get_circuit_id_for_object(object_data)

static func get_circuit_id_for_object(object_data: Dictionary) -> String:
	for key in CIRCUIT_ID_KEYS:
		var value: String = str(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var object_id: String = str(object_data.get("id", object_data.get("object_id", ""))).strip_edges()
	if not object_id.is_empty():
		return object_id
	return "isolated_object"

static func get_cable_circuit_id(object_data: Dictionary) -> String:
	return get_circuit_id_for_object(object_data)

static func classify_cell(cell: Vector2i, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = build_cable_cell_map(world_objects, preview_object)
	if not cable_cells.has(cell):
		return _make_topology(cell, "", {}, _blank_dirs(), _blank_dirs(), {}, 0, "isolated", true, false, "")
	return _classify_cell_with_map(cell, cable_cells, world_objects, preview_object)

static func validate_cell(cell: Vector2i, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var topology: Dictionary = classify_cell(cell, world_objects, preview_object)
	if bool(topology.get("valid", true)):
		return {"ok": true, "message": str(topology.get("message", "OK")) if not str(topology.get("message", "")).is_empty() else "OK", "topology": topology}
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
	var warning_message: String = ""
	for check_cell in cells_to_check:
		if checked_cells.has(check_cell):
			continue
		checked_cells[check_cell] = true
		var topology: Dictionary = classify_cell(check_cell, world_objects, preview_object)
		topologies.append(topology)
		if not bool(topology.get("valid", true)):
			return {"ok": false, "message": ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH, "topologies": topologies, "failed_cell": check_cell, "topology": topology}
		if warning_message.is_empty() and not str(topology.get("message", "")).is_empty():
			warning_message = str(topology.get("message", ""))
	return {"ok": true, "message": warning_message if not warning_message.is_empty() else "OK", "topologies": topologies}

static func detect_adjacent_cable_cells(cell: Vector2i, cable_cells: Dictionary) -> Dictionary:
	if not cable_cells.has(cell):
		return _blank_dirs()
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	var circuit_id: String = str(cell_data.get("circuit_id", ""))
	var neighbors: Dictionary = _blank_dirs()
	for direction in DIRECTION_ORDER:
		var neighbor_cell: Vector2i = cell + Vector2i(NEIGHBOR_DELTAS[direction])
		if not cable_cells.has(neighbor_cell):
			continue
		var neighbor_data: Dictionary = Dictionary(cable_cells.get(neighbor_cell, {}))
		neighbors[direction] = circuit_id == str(neighbor_data.get("circuit_id", ""))
	return neighbors

static func build_cable_cell_map(world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cable_cells: Dictionary = {}
	for object_variant in world_objects:
		if object_variant is Dictionary:
			_add_object_to_cable_cell_map(cable_cells, Dictionary(object_variant))
	if not preview_object.is_empty():
		_add_object_to_cable_cell_map(cable_cells, preview_object)
	return cable_cells

static func build_circuit_object_adjacency(cell: Vector2i, cable_cell_data: Dictionary, world_objects: Array) -> Dictionary:
	var circuit_id: String = str(cable_cell_data.get("circuit_id", "")).strip_edges()
	if circuit_id.is_empty():
		return {}
	var object_links: Dictionary = {}
	for object_variant in world_objects:
		if not object_variant is Dictionary:
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if is_cable_object(object_data) and not is_circuit_switch_object(object_data):
			continue
		if not is_circuit_connectable_object(object_data):
			continue
		if get_circuit_id_for_object(object_data) != circuit_id:
			continue
		var object_cell: Vector2i = get_object_link_cell(object_data)
		if object_cell.x < 0 or object_cell.y < 0:
			continue
		var direction: String = _direction_from_delta(object_cell - cell)
		if direction.is_empty():
			continue
		object_links[direction] = {
			"object_id": str(object_data.get("id", object_data.get("object_id", ""))),
			"object_type": str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))),
			"circuit_id": circuit_id,
			"cell": object_cell
		}
	return object_links

static func is_cable_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).strip_edges().to_lower()
	if object_type == "circuit_switch":
		return true
	return object_type == "power_cable" or object_type == "power_cable_reel" or object_type.contains("cable") or object_type.contains("wire")

static func is_circuit_switch_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	return object_type == "circuit_switch"

static func is_circuit_connectable_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))).strip_edges().to_lower()
	for key in EXPLICIT_CIRCUIT_ID_KEYS:
		if not str(object_data.get(key, "")).strip_edges().is_empty():
			return true
	if object_type in ["power_source", "battery", "terminal", "socket", "circuit_switch", "circuit_breaker", "fuse_box", "light"]:
		return true
	if object_type.contains("door") or object_type.contains("gate"):
		return str(object_data.get("power_type", "")).to_lower() == "external" or str(object_data.get("door_type", "")).to_lower() == "powered" or not str(object_data.get("power_network_id", "")).is_empty()
	if object_type.contains("platform"):
		return bool(object_data.get("is_powered", object_data.get("requires_external_power", false))) or not str(object_data.get("power_network_id", "")).is_empty()
	return false

static func get_object_link_cell(object_data: Dictionary) -> Vector2i:
	var anchor_cell: Vector2i = _try_parse_cell_variant(object_data.get("anchor_floor_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if anchor_cell.x >= 0 and anchor_cell.y >= 0:
		return anchor_cell
	return _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))

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
	var circuit_id: String = get_cable_circuit_id(object_data)
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	cell_data["has_cable"] = true
	cell_data["circuit_id"] = str(cell_data.get("circuit_id", circuit_id)) if not str(cell_data.get("circuit_id", "")).is_empty() else circuit_id
	cell_data["has_circuit_switch"] = bool(cell_data.get("has_circuit_switch", false)) or has_circuit_switch
	var objects: Array = Array(cell_data.get("objects", []))
	objects.append(object_data)
	cell_data["objects"] = objects
	cable_cells[cell] = cell_data

static func _classify_cell_with_map(cell: Vector2i, cable_cells: Dictionary, world_objects: Array, preview_object: Dictionary = {}) -> Dictionary:
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	var circuit_id: String = str(cell_data.get("circuit_id", ""))
	var neighbors: Dictionary = detect_adjacent_cable_cells(cell, cable_cells)
	var selected_dirs: Dictionary = _select_connected_dirs_for_cell(cell, cable_cells)
	var connected_dirs: Dictionary = _blank_dirs()
	var skipped_dirs: Dictionary = _blank_dirs()
	for direction in DIRECTION_ORDER:
		if not bool(neighbors.get(direction, false)):
			continue
		var neighbor_cell: Vector2i = cell + Vector2i(NEIGHBOR_DELTAS[direction])
		var reverse_dir: String = _opposite_direction(direction)
		var neighbor_selected_dirs: Dictionary = _select_connected_dirs_for_cell(neighbor_cell, cable_cells)
		if bool(selected_dirs.get(direction, false)) and bool(neighbor_selected_dirs.get(reverse_dir, false)):
			connected_dirs[direction] = true
		else:
			skipped_dirs[direction] = true
	var cable_connection_count: int = _count_true_neighbors(connected_dirs)
	var is_switch: bool = bool(cell_data.get("has_circuit_switch", false))
	var shape: String = _shape_for_neighbors(connected_dirs, cable_connection_count, is_switch)
	var all_world_objects: Array = _merge_world_objects_with_preview(world_objects, preview_object)
	var object_links: Dictionary = build_circuit_object_adjacency(cell, cell_data, all_world_objects)
	var message: String = WARNING_MESSAGE_EXTRA_BRANCH_SKIPPED if _count_true_neighbors(skipped_dirs) > 0 else ""
	return _make_topology(cell, circuit_id, neighbors, connected_dirs, skipped_dirs, object_links, cable_connection_count, shape, true, is_switch, message)

static func _select_connected_dirs_for_cell(cell: Vector2i, cable_cells: Dictionary) -> Dictionary:
	var selected: Dictionary = _blank_dirs()
	if not cable_cells.has(cell):
		return selected
	var cell_data: Dictionary = Dictionary(cable_cells.get(cell, {}))
	var neighbors: Dictionary = detect_adjacent_cable_cells(cell, cable_cells)
	if bool(cell_data.get("has_circuit_switch", false)):
		return neighbors
	var possible_count: int = _count_true_neighbors(neighbors)
	if possible_count <= 2:
		return neighbors
	var preferred_pair: Array[String] = _preferred_two_dirs(neighbors)
	for direction in preferred_pair:
		selected[direction] = true
	return selected

static func _preferred_two_dirs(neighbors: Dictionary) -> Array[String]:
	if bool(neighbors.get(DIR_NORTH, false)) and bool(neighbors.get(DIR_SOUTH, false)):
		return [DIR_NORTH, DIR_SOUTH]
	if bool(neighbors.get(DIR_WEST, false)) and bool(neighbors.get(DIR_EAST, false)):
		return [DIR_WEST, DIR_EAST]
	var result: Array[String] = []
	for direction in DIRECTION_ORDER:
		if bool(neighbors.get(direction, false)):
			result.append(direction)
			if result.size() >= 2:
				break
	return result

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

static func _make_topology(cell: Vector2i, circuit_id: String, neighbors: Dictionary, connected_dirs: Dictionary, skipped_dirs: Dictionary, object_links: Dictionary, cable_connection_count: int, shape: String, is_valid: bool, has_circuit_switch: bool, message: String) -> Dictionary:
	return {
		"cell": cell,
		"circuit_id": circuit_id,
		"neighbors": neighbors,
		"neighbor_count": _count_true_neighbors(neighbors),
		"connected_dirs": connected_dirs,
		"skipped_dirs": skipped_dirs,
		"object_links": object_links,
		"cable_connection_count": cable_connection_count,
		"shape": shape,
		"valid": is_valid,
		"has_circuit_switch": has_circuit_switch,
		"message": message
	}

static func _blank_dirs() -> Dictionary:
	return {DIR_NORTH: false, DIR_SOUTH: false, DIR_WEST: false, DIR_EAST: false}

static func _count_true_neighbors(neighbors: Dictionary) -> int:
	var count: int = 0
	for value in neighbors.values():
		if bool(value):
			count += 1
	return count

static func _opposite_direction(direction: String) -> String:
	match direction:
		DIR_NORTH:
			return DIR_SOUTH
		DIR_SOUTH:
			return DIR_NORTH
		DIR_WEST:
			return DIR_EAST
		DIR_EAST:
			return DIR_WEST
		_:
			return ""

static func _direction_from_delta(delta: Vector2i) -> String:
	for direction in DIRECTION_ORDER:
		if Vector2i(NEIGHBOR_DELTAS[direction]) == delta:
			return direction
	return ""

static func _merge_world_objects_with_preview(world_objects: Array, preview_object: Dictionary) -> Array:
	var merged: Array = []
	for object_variant in world_objects:
		merged.append(object_variant)
	if not preview_object.is_empty():
		merged.append(preview_object)
	return merged

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
