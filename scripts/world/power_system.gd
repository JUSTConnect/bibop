extends RefCounted
class_name PowerSystem
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const STATE_DRIVEN_POWER_TYPES := {
	"turret": true,
	"light": true,
	"energy_wall": true,
	"energy_door": true,
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
	"light_switch": true
}

static func _is_state_driven_powered_object(obj: Dictionary) -> bool:
	var object_type: String = String(obj.get("object_type", ""))
	var object_group: String = String(obj.get("object_group", ""))
	if object_group == "terminal":
		return true
	if object_group == "threat" and object_type == "turret":
		return true
	return bool(STATE_DRIVEN_POWER_TYPES.get(object_type, false))

static func _normalize_type(value: Variant) -> String:
	return String(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

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
	return source_class + 3

static func _is_power_consumer_object(obj: Dictionary) -> bool:
	if _is_power_source_object(obj):
		return false
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if object_type in ["power_cable", "circuit_switch", "circuit_breaker", "power_breaker", "power_knife_switch", "fuse_box", "fuse_box_empty", "fuse_box_installed", "light_switch"]:
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
	if state in ["damaged", "broken", "destroyed"]:
		return true
	if bool(obj.get("damaged", false)) or bool(obj.get("broken", false)):
		return true
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if object_type in ["fuse_box", "fuse_box_empty", "fuse_block"]:
		return not (bool(obj.get("fuse_installed", false)) or state in ["installed", "ok", "active"] or object_type == "fuse_box_installed")
	if object_type in ["circuit_breaker", "power_breaker", "power_knife_switch"]:
		return state in ["off", "switch_off", "open"] or not bool(obj.get("is_on", state in ["on", "switch_on", "active", "ok"]))
	return false

static func _can_traverse(obj: Dictionary) -> bool:
	var object_type: String = _normalize_type(obj.get("object_type", ""))
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

static func _apply_powered_state(obj: Dictionary, powered: bool) -> void:
	if _is_power_source_object(obj):
		obj["is_powered"] = _is_source_on(obj)
		return
	obj["is_powered"] = powered
	var object_type: String = _normalize_type(obj.get("object_type", ""))
	if _is_state_driven_powered_object(obj):
		var current_state: String = _normalize_type(obj.get("state", ""))
		var object_group: String = String(obj.get("object_group", ""))
		if not powered:
			if current_state != "unpowered" and not bool(NON_RESTORABLE_STATES.get(current_state, false)):
				obj["state_before_unpowered"] = current_state
				if not (object_group == "threat" and object_type == "turret" and current_state in ["destroyed", "hacked", "disabled"]):
					obj["state"] = "unpowered"
			if object_group == "threat" and object_type == "turret" and String(obj.get("state", "")) == "unpowered":
				obj["behavior_state"] = "idle"
				obj.erase("target_position")
		elif current_state == "unpowered":
			var restored_state: String = String(obj.get("state_before_unpowered", "active"))
			if restored_state.is_empty():
				restored_state = "active"
			if not (object_group == "threat" and object_type == "turret" and restored_state in ["destroyed", "hacked", "disabled"]):
				obj["state"] = restored_state
			obj.erase("state_before_unpowered")
	if object_type in ["energy_door", "energy_wall", "powered_gate"] and not powered:
		obj["blocks_movement"] = false
	elif object_type in ["energy_door", "energy_wall", "powered_gate"] and powered and obj.get("state", "") not in ["open", "inactive", "destroyed"]:
		obj["blocks_movement"] = true

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var object_by_cell: Dictionary = {}
	var object_by_id: Dictionary = {}
	for obj in objects:
		var obj_id: String = String(obj.get("id", "")).strip_edges()
		if not obj_id.is_empty():
			object_by_id[obj_id] = obj
		var cell: Vector2i = _cell_from_obj(obj)
		if cell.x >= 0 and cell.y >= 0:
			object_by_cell[cell] = obj
		if network_id.is_empty() or String(obj.get("power_network_id", "")) == network_id or String(obj.get("power_source_id", "")) == network_id:
			if not _is_power_source_object(obj):
				_apply_powered_state(obj, false)
		WorldObjectCatalogRef.update_world_object_heat_state(obj)
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var traversal_cap: int = maxi(64, objects.size() * 8)
	for source in objects:
		if not _is_power_source_object(source):
			continue
		var source_id: String = String(source.get("id", "")).strip_edges()
		if not network_id.is_empty() and String(source.get("power_network_id", source_id)) != network_id and source_id != network_id:
			continue
		var source_on: bool = _is_source_on(source)
		source["is_powered"] = source_on
		source["power_mode"] = "internal"
		source["control_mode"] = "internal"
		source["outlet_capacity"] = _get_power_source_capacity_for_load(source)
		if not source_on:
			continue
		var source_cell: Vector2i = _cell_from_obj(source)
		var queue: Array[Vector2i] = []
		var visited_cells: Dictionary = {}
		for delta in directions:
			queue.append(source_cell + delta)
		var steps: int = 0
		while not queue.is_empty() and steps < traversal_cap:
			steps += 1
			var current_cell: Vector2i = queue.pop_front()
			if visited_cells.has(current_cell):
				continue
			visited_cells[current_cell] = true
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
			for delta in directions:
				queue.append(current_cell + delta)
		# Lighting may be direct logical links without physical wires.
		for obj in objects:
			var obj_type: String = _normalize_type(obj.get("object_type", ""))
			if obj_type == "light" and String(obj.get("power_source_id", obj.get("power_network_id", ""))).strip_edges() == source_id:
				_apply_powered_state(obj, not bool(obj.get("light_switch_off", false)))
		var outlet_count: int = 0
		for obj in objects:
			var obj_type_count: String = _normalize_type(obj.get("object_type", ""))
			if obj_type_count in ["power_socket", "outlet"] and String(obj.get("power_source_id", "")).strip_edges() == source_id:
				outlet_count += 1
		source["source_load"] = outlet_count
		source["source_capacity"] = int(source.get("outlet_capacity", _get_power_source_capacity_for_load(source)))
		source["source_overloaded"] = outlet_count > int(source.get("source_capacity", 4))
		source["heat_from_connections"] = maxi(0, outlet_count - int(source.get("source_capacity", 4)))
		WorldObjectCatalogRef.update_world_object_heat_state(source)
	return objects
