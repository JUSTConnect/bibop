extends RefCounted
class_name PowerSystem
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const STATE_DRIVEN_POWER_TYPES := {
	"turret": true,
	"light": true,
	"energy_wall": true,
	"cooling_block": true,
	"alarm": true,
	"camera": true,
	"lift": true,
	"platform": true
}

const NON_RESTORABLE_STATES := {
	"damaged": true,
	"destroyed": true,
	"broken": true
}

const POWER_TRAVERSAL_TYPES := {
	"power_cable": true,
	"power_socket": true,
	"circuit_switch": true,
	"circuit_breaker": true,
	"power_breaker": true,
	"power_knife_switch": true,
	"fuse_box": true,
	"fuse_box_installed": true,
	"fuse_box_empty": true,
	"fuse_block": true,
	"light_switch": true,
	"power_switcher": true
}

static func _is_state_driven_powered_object(obj: Dictionary) -> bool:
	var object_type: String = str(obj.get("object_type", ""))
	var object_group: String = str(obj.get("object_group", ""))
	if object_group == "terminal":
		return true
	if object_group == "door":
		return str(obj.get("material", "")) == WorldObjectCatalogRef.DOOR_MATERIAL_ENERGY or str(obj.get("power_behavior", "none")) != WorldObjectCatalogRef.POWER_BEHAVIOR_NONE or bool(obj.get("requires_external_power", false))
	if object_group == "threat" and object_type == "turret":
		return true
	return bool(STATE_DRIVEN_POWER_TYPES.get(object_type, false))

static func _normalize_type(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _is_power_source_object(obj: Dictionary) -> bool:
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	return object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]

static func _get_power_source_capacity_for_load(source: Dictionary) -> int:
	var source_class: int = int(source.get("power_source_class", source.get("source_class", 1)))
	var object_type: String = _normalize_type(source.get("object_type", ""))
	if object_type.ends_with("class_2"):
		source_class = 2
	elif object_type.ends_with("class_3"):
		source_class = 3
	source_class = clampi(source_class, 1, 3)
	var canonical_capacity: int = source_class + 3
	if source.has("outlet_capacity"):
		return maxi(1, int(source.get("outlet_capacity", canonical_capacity)))
	return canonical_capacity

static func _is_power_consumer_object(obj: Dictionary) -> bool:
	if _is_power_source_object(obj):
		return false
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if object_type in ["power_cable", "circuit_switch", "circuit_breaker", "power_breaker", "power_knife_switch", "fuse_box", "fuse_box_empty", "fuse_box_installed", "fuse_block", "light_switch", "power_switcher"]:
		return false
	if _is_state_driven_powered_object(obj):
		return true
	return bool(obj.get("is_powered", false))

static func _is_source_on(source: Dictionary) -> bool:
	var state: String = _normalize_type(source.get("state", "on"))
	if state == "active":
		state = "on"
	return state == "on" and not bool(source.get("damaged", false)) and not bool(source.get("broken", false))

static func _is_segment_blocked(obj: Dictionary) -> bool:
	var state: String = _normalize_type(obj.get("state", "ok"))
	if state in ["cut", "damaged", "broken", "destroyed"]:
		return true
	if bool(obj.get("cut", false)) or bool(obj.get("damaged", false)) or bool(obj.get("broken", false)):
		return true
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if object_type == "power_cable":
		if obj.has("connected_side") and not bool(obj.get("connected_side", false)):
			return true
		if obj.has("connected") and not bool(obj.get("connected", false)):
			return true
	if object_type in ["fuse_box", "fuse_box_empty", "fuse_block"]:
		return not (bool(obj.get("fuse_installed", false)) or state in ["installed", "ok", "active"] or object_type == "fuse_box_installed")
	if object_type == "power_switcher":
		var switcher_type: String = WorldObjectCatalogRef.normalize_switcher_type(obj)
		if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_LIGHT:
			return true
		if switcher_type == WorldObjectCatalogRef.SWITCHER_TYPE_POWER_SWITCHER:
			return Array(obj.get("switcher_lines", [])).is_empty()
	if object_type in ["circuit_breaker", "power_breaker", "power_knife_switch", "power_switcher"]:
		return state in ["off", "switch_off", "open"] or not bool(obj.get("is_on", state in ["on", "switch_on", "active", "ok"]))
	return false

static func _can_traverse(obj: Dictionary) -> bool:
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if object_type == "power_switcher" and WorldObjectCatalogRef.normalize_switcher_type(obj) == WorldObjectCatalogRef.SWITCHER_TYPE_LIGHT:
		return false
	if bool(POWER_TRAVERSAL_TYPES.get(object_type, false)):
		return not _is_segment_blocked(obj)
	if _is_power_consumer_object(obj):
		return not _is_segment_blocked(obj)
	return false

static func _cell_from_obj(obj: Dictionary) -> Vector2i:
	var position_value: Variant = obj.get("position", Vector2i(-1, -1))
	if position_value is Vector2i or position_value is Vector2:
		return Vector2i(position_value)
	if position_value is Array and Array(position_value).size() >= 2:
		return Vector2i(int(Array(position_value)[0]), int(Array(position_value)[1]))
	return Vector2i(-1, -1)


static func _direction_to_delta(direction: String) -> Vector2i:
	match direction.strip_edges().to_lower():
		"north", "up":
			return Vector2i.UP
		"south", "down":
			return Vector2i.DOWN
		"west", "left":
			return Vector2i.LEFT
		"east", "right":
			return Vector2i.RIGHT
	return Vector2i.ZERO

static func _resolve_switch_connection_cell(switch_obj: Dictionary, field_prefix: String, switch_cell: Vector2i, object_by_id: Dictionary) -> Vector2i:
	var wire_id: String = str(switch_obj.get("%s_wire_id" % field_prefix, "")).strip_edges()
	if not wire_id.is_empty() and object_by_id.has(wire_id):
		var wire_value: Variant = object_by_id.get(wire_id, {})
		if wire_value is Dictionary:
			return _cell_from_obj(wire_value)
	var direction: String = str(switch_obj.get("%s_direction" % field_prefix, "")).strip_edges()
	var delta: Vector2i = _direction_to_delta(direction)
	if delta != Vector2i.ZERO:
		return switch_cell + delta
	return Vector2i(-1, -1)

static func _has_circuit_switch_routing_metadata(switch_obj: Dictionary) -> bool:
	if switch_obj.has("active_output_index") or switch_obj.has("input_wire_id") or switch_obj.has("input_direction"):
		return true
	for output_index in range(1, 4):
		if switch_obj.has("output_%d_wire_id" % output_index) or switch_obj.has("output_%d_direction" % output_index):
			return true
	return false


static func _get_circuit_switch_next_cells(switch_obj: Dictionary, switch_cell: Vector2i, entered_from_cell: Vector2i, object_by_id: Dictionary) -> Array[Vector2i]:
	var next_cells: Array[Vector2i] = []
	var input_cell: Vector2i = _resolve_switch_connection_cell(switch_obj, "input", switch_cell, object_by_id)
	if input_cell.x < 0 or input_cell.y < 0:
		return next_cells
	if entered_from_cell != input_cell:
		return next_cells
	var active_output_index: int = int(switch_obj.get("active_output_index", 0))
	if active_output_index < 1 or active_output_index > 3:
		return next_cells
	var output_cell: Vector2i = _resolve_switch_connection_cell(switch_obj, "output_%d" % active_output_index, switch_cell, object_by_id)
	if output_cell.x < 0 or output_cell.y < 0:
		return next_cells
	next_cells.append(output_cell)
	return next_cells

static func _has_power_switcher_routing_metadata(switch_obj: Dictionary) -> bool:
	return WorldObjectCatalogRef.normalize_switcher_type(switch_obj) == WorldObjectCatalogRef.SWITCHER_TYPE_POWER_SWITCHER and not WorldObjectCatalogRef.normalize_switcher_lines(switch_obj).is_empty()

static func _get_power_switcher_next_cells(switch_obj: Dictionary, switch_cell: Vector2i, entered_from_cell: Vector2i) -> Array[Vector2i]:
	var next_cells: Array[Vector2i] = []
	var switcher_lines: Array[Dictionary] = WorldObjectCatalogRef.normalize_switcher_lines(switch_obj)
	if switcher_lines.is_empty():
		return next_cells
	var active_line_id: String = str(switch_obj.get("active_line_id", "")).strip_edges()
	if active_line_id.is_empty():
		active_line_id = str(switcher_lines[0].get("line_id", ""))
	var active_line: Dictionary = {}
	for line in switcher_lines:
		if str(line.get("line_id", "")) == active_line_id:
			active_line = line
			break
	if active_line.is_empty():
		active_line = switcher_lines[0]
	var active_delta: Vector2i = _direction_to_delta(str(active_line.get("direction", "")))
	if active_delta == Vector2i.ZERO:
		return next_cells
	var active_cell: Vector2i = switch_cell + active_delta
	var input_delta: Vector2i = _direction_to_delta(str(switch_obj.get("input_direction", "")))
	if input_delta != Vector2i.ZERO:
		var input_cell: Vector2i = switch_cell + input_delta
		if entered_from_cell == input_cell and active_cell != entered_from_cell:
			next_cells.append(active_cell)
		elif entered_from_cell == active_cell and input_cell != entered_from_cell:
			next_cells.append(input_cell)
		return next_cells
	if active_cell != entered_from_cell:
		next_cells.append(active_cell)
	return next_cells

static func _apply_powered_state(obj: Dictionary, powered: bool) -> void:
	var power_mode: String = str(obj.get("power_type", obj.get("power_mode", "external"))).trim_suffix("_power")
	if power_mode == "internal":
		powered = true
	if _is_power_source_object(obj):
		obj["is_powered"] = _is_source_on(obj)
		return
	if bool(obj.get("test_override_enabled", false)):
		return
	obj["is_powered"] = powered
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	var object_group: String = str(obj.get("object_group", ""))
	var power_behavior: String = str(obj.get("power_behavior", WorldObjectCatalogRef.POWER_BEHAVIOR_NONE))
	if object_group == "door" and power_behavior == WorldObjectCatalogRef.POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN:
		var door_state: String = _normalize_type(obj.get("state", ""))
		if not powered:
			if door_state != "unpowered" and door_state != "jammed" and not bool(NON_RESTORABLE_STATES.get(door_state, false)):
				obj["state_before_unpowered"] = door_state
				obj["state"] = "unpowered"
		elif door_state == "unpowered":
			var restored_door_state: String = str(obj.get("state_before_unpowered", "closed"))
			if restored_door_state.is_empty() or restored_door_state in ["unpowered", "damaged", "broken", "destroyed", "jammed"]:
				restored_door_state = "closed"
			obj["state"] = restored_door_state
			obj.erase("state_before_unpowered")
		WorldObjectCatalogRef.normalize_door_state_fields(obj)
		return
	if _is_state_driven_powered_object(obj):
		var current_state: String = _normalize_type(obj.get("state", ""))
		if not powered:
			if current_state != "unpowered" and not bool(NON_RESTORABLE_STATES.get(current_state, false)):
				obj["state_before_unpowered"] = current_state
				if not (object_group == "threat" and object_type == "turret" and current_state in ["destroyed", "hacked", "disabled"]):
					obj["state"] = "unpowered"
			if object_group == "threat" and object_type == "turret" and str(obj.get("state", "")) == "unpowered":
				obj["behavior_state"] = "idle"
				obj.erase("target_position")
		elif current_state == "unpowered":
			var restored_state: String = str(obj.get("state_before_unpowered", "active"))
			if restored_state.is_empty():
				restored_state = "active"
			if not (object_group == "threat" and object_type == "turret" and restored_state in ["destroyed", "hacked", "disabled"]):
				obj["state"] = restored_state
			obj.erase("state_before_unpowered")
		if object_group == "terminal":
			obj["status"] = str(obj.get("state", "active"))
	if object_group == "door" and str(obj.get("power_behavior", "none")) == WorldObjectCatalogRef.POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED:
		obj["state"] = "open" if not powered else str(obj.get("state", "closed"))
		WorldObjectCatalogRef.normalize_door_state_fields(obj)
	elif object_type == "energy_wall":
		obj["blocks_movement"] = powered and obj.get("state", "") not in ["open", "inactive", "destroyed"]

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var object_by_cell: Dictionary = {}
	var object_by_id: Dictionary = {}
	for obj in objects:
		var obj_id: String = str(obj.get("id", "")).strip_edges()
		if not obj_id.is_empty():
			object_by_id[obj_id] = obj
		var cell: Vector2i = _cell_from_obj(obj)
		if cell.x >= 0 and cell.y >= 0:
			object_by_cell[cell] = obj
		if network_id.is_empty() or str(obj.get("power_network_id", "")) == network_id or str(obj.get("power_source_id", "")) == network_id:
			if not _is_power_source_object(obj):
				_apply_powered_state(obj, false)
				obj["physical_connection_source_id"] = ""
		WorldObjectCatalogRef.update_world_object_heat_state(obj)
	# main_power_net is the explicit virtual-network exception. Every other
	# source-owned network must earn physical provenance through traversal.
	if network_id == "main_power_net":
		for virtual_obj in objects:
			if str(virtual_obj.get("power_network_id", "")).strip_edges() == "main_power_net" and not _is_power_source_object(virtual_obj):
				_apply_powered_state(virtual_obj, true)
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var traversal_cap: int = maxi(64, objects.size() * 8)
	for source in objects:
		if not _is_power_source_object(source):
			continue
		var source_id: String = str(source.get("id", "")).strip_edges()
		if not network_id.is_empty() and str(source.get("power_network_id", source_id)) != network_id and source_id != network_id:
			continue
		var source_on: bool = _is_source_on(source)
		source["is_powered"] = source_on
		source["power_mode"] = "internal"
		source["control_mode"] = "internal"
		source["power_source_class"] = clampi(int(source.get("power_source_class", source.get("source_class", 1))), 1, 3)
		source["outlet_capacity"] = _get_power_source_capacity_for_load(source)
		if not source_on:
			continue
		var source_cell: Vector2i = _cell_from_obj(source)
		var queue: Array[Dictionary] = []
		var visited_edges: Dictionary = {}
		for delta in directions:
			queue.append({"cell": source_cell + delta, "from_cell": source_cell})
		var steps: int = 0
		while not queue.is_empty() and steps < traversal_cap:
			steps += 1
			var entry: Dictionary = Dictionary(queue.pop_front())
			var current_cell: Vector2i = Vector2i(entry.get("cell", Vector2i(-1, -1)))
			var from_cell: Vector2i = Vector2i(entry.get("from_cell", Vector2i(-1, -1)))
			var edge_key: String = "%d,%d<-%d,%d" % [current_cell.x, current_cell.y, from_cell.x, from_cell.y]
			if visited_edges.has(edge_key):
				continue
			visited_edges[edge_key] = true
			if not object_by_cell.has(current_cell):
				continue
			var current_obj: Dictionary = Dictionary(object_by_cell[current_cell])
			if current_obj.is_empty() or _is_power_source_object(current_obj):
				continue
			if not _can_traverse(current_obj):
				continue
			current_obj["power_source_id"] = source_id
			current_obj["physical_connection_source_id"] = source_id
			_apply_powered_state(current_obj, true)
			var current_type: String = _normalize_type(current_obj.get("object_type", ""))
			var next_cells: Array[Vector2i] = []
			if current_type == "circuit_switch" and _has_circuit_switch_routing_metadata(current_obj):
				next_cells = _get_circuit_switch_next_cells(current_obj, current_cell, from_cell, object_by_id)
			elif current_type == "power_switcher" and _has_power_switcher_routing_metadata(current_obj):
				next_cells = _get_power_switcher_next_cells(current_obj, current_cell, from_cell)
			else:
				for delta in directions:
					var next_cell: Vector2i = current_cell + delta
					if next_cell != from_cell:
						next_cells.append(next_cell)
			for next_cell in next_cells:
				queue.append({"cell": next_cell, "from_cell": current_cell})
		# Lighting may be direct logical links without physical wires.
		for obj in objects:
			var obj_type: String = _normalize_type(obj.get("object_type", ""))
			if obj_type == "light" and str(obj.get("power_source_id", obj.get("power_network_id", ""))).strip_edges() == source_id:
				_apply_powered_state(obj, not bool(obj.get("light_switch_off", false)))
		var outlet_count: int = 0
		for obj in objects:
			var obj_type_count: String = _normalize_type(obj.get("object_type", ""))
			if obj_type_count in ["power_socket", "outlet"] and str(obj.get("power_source_id", obj.get("connected_power_source_id", ""))).strip_edges() == source_id:
				outlet_count += 1
		source["source_load"] = outlet_count
		source["source_capacity"] = int(source.get("outlet_capacity", _get_power_source_capacity_for_load(source)))
		source["source_overloaded"] = outlet_count > int(source.get("source_capacity", 4))
		source["heat_from_connections"] = maxi(0, outlet_count - int(source.get("source_capacity", 4)))
		WorldObjectCatalogRef.update_world_object_heat_state(source)
	return objects
