extends RefCounted
class_name BipobAirflowRuntimeService

const BipobAirflowRuntimeStateRef = preload("res://scripts/game/bipob_airflow_runtime_state.gd")
const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")

const STATE_COOLED: String = "cooled"
const STATE_UNCOOLED: String = "uncooled"
const STATE_BLOCKED: String = "blocked"
const STATE_DISABLED: String = "fan_disabled"


static func apply_generic_airflow_runtime(world_objects: Array[Dictionary], network_filter: String = "") -> Dictionary:
	var report: Dictionary = {"filter": network_filter.strip_edges(), "fans": [], "targets": [], "warnings": []}
	_reset_generic_airflow_runtime_fields(world_objects, network_filter)
	var fans: Array[Dictionary] = _collect_fans(world_objects, network_filter)
	for fan_object in fans:
		var state: BipobAirflowRuntimeState = _build_state_for_fan(fan_object)
		if not state.fan_enabled or state.airflow_range <= 0:
			fan_object["airflow_cells"] = []
			fan_object["blocked_cells"] = []
			fan_object["cooled_target_ids"] = []
			fan_object["cooling_state"] = STATE_DISABLED
			report["fans"].append(state.to_dictionary())
			continue
		_propagate_fan_airflow(fan_object, state, world_objects)
		fan_object["airflow_cells"] = state.airflow_cells.duplicate()
		fan_object["blocked_cells"] = state.blocked_cells.duplicate()
		fan_object["cooled_target_ids"] = state.cooled_target_ids.duplicate()
		if state.cooled_target_ids.is_empty():
			fan_object["cooling_state"] = STATE_UNCOOLED
		else:
			fan_object["cooling_state"] = STATE_COOLED
		report["fans"].append(state.to_dictionary())
	for target_object in world_objects:
		if not _is_generic_cooling_target(target_object):
			continue
		var target_network_id: String = str(target_object.get("airflow_network_id", ""))
		if not network_filter.strip_edges().is_empty() and target_network_id != network_filter.strip_edges():
			continue
		report["targets"].append(_build_target_report(target_object))
	return report


static func _reset_generic_airflow_runtime_fields(world_objects: Array[Dictionary], network_filter: String) -> void:
	var resolved_filter: String = network_filter.strip_edges()
	for object_data in world_objects:
		if not _uses_generic_airflow_runtime(object_data):
			continue
		var network_id: String = str(object_data.get("airflow_network_id", ""))
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		if _is_generic_cooling_target(object_data):
			object_data["is_cooled"] = false
			object_data["cooling_received"] = 0
			object_data["cooling_state"] = STATE_UNCOOLED
			object_data["cooled_by_fan_id"] = ""
			object_data["airflow_cells"] = []
			object_data["blocked_cells"] = []
			object_data["cooling_source_ids"] = []
		if _is_generic_fan(object_data):
			object_data["cooled_target_ids"] = []
			object_data["blocked_cells"] = []
			object_data["airflow_cells"] = []


static func _collect_fans(world_objects: Array[Dictionary], network_filter: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var resolved_filter: String = network_filter.strip_edges()
	for object_data in world_objects:
		if not _is_generic_fan(object_data):
			continue
		var network_id: String = str(object_data.get("airflow_network_id", ""))
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		result.append(object_data)
	return result


static func _build_state_for_fan(fan_object: Dictionary) -> BipobAirflowRuntimeState:
	var state: BipobAirflowRuntimeState = BipobAirflowRuntimeStateRef.new()
	state.airflow_network_id = str(fan_object.get("airflow_network_id", ""))
	state.fan_object_id = str(fan_object.get("id", ""))
	state.fan_speed = maxi(0, int(fan_object.get("fan_speed", fan_object.get("airflow_speed", 0))))
	state.fan_enabled = bool(fan_object.get("fan_enabled", fan_object.get("enabled", state.fan_speed > 0)))
	state.fan_direction = str(fan_object.get("fan_direction", fan_object.get("facing_dir", "right")))
	state.airflow_range = maxi(0, int(fan_object.get("airflow_range", state.fan_speed)))
	if state.fan_enabled and state.fan_speed <= 0:
		state.fan_speed = maxi(1, state.airflow_range)
	if state.fan_enabled and state.airflow_range <= 0:
		state.airflow_range = state.fan_speed
	state.cooling_received = maxi(1, int(fan_object.get("cooling_output", state.fan_speed)))
	return state


static func _propagate_fan_airflow(fan_object: Dictionary, state: BipobAirflowRuntimeState, world_objects: Array[Dictionary]) -> void:
	var fan_position: Vector2i = _to_vector2i(fan_object.get("position", Vector2i.ZERO))
	var direction: Vector2i = _direction_to_vector2i(state.fan_direction)
	var current_cell: Vector2i = fan_position + direction
	for _step_index in range(state.airflow_range):
		var cell_objects: Array[Dictionary] = _get_objects_at_cell(world_objects, current_cell, state.fan_object_id)
		var target_ids_at_cell: Array[String] = _get_coolable_target_ids_at_cell(cell_objects, state.airflow_network_id, fan_object)
		for target_id in target_ids_at_cell:
			_cool_target_by_id(world_objects, target_id, state, current_cell)
		if _cell_blocks_airflow(cell_objects):
			state.blocked_cells.append(current_cell)
			break
		if target_ids_at_cell.is_empty() or _cell_has_path_role(cell_objects):
			state.airflow_cells.append(current_cell)
		current_cell += direction


static func _cool_target_by_id(world_objects: Array[Dictionary], target_id: String, state: BipobAirflowRuntimeState, target_cell: Vector2i) -> void:
	for object_data in world_objects:
		if str(object_data.get("id", "")) != target_id:
			continue
		object_data["is_cooled"] = true
		object_data["cooling_required"] = bool(object_data.get("cooling_required", true))
		object_data["cooling_received"] = maxi(int(object_data.get("cooling_received", 0)), state.cooling_received)
		object_data["cooling_state"] = STATE_COOLED
		object_data["cooled_by_fan_id"] = state.fan_object_id
		object_data["fan_object_id"] = state.fan_object_id
		object_data["airflow_cells"] = state.airflow_cells.duplicate()
		object_data["airflow_cells"].append(target_cell)
		object_data["cooling_source_ids"] = [state.fan_object_id]
		if not state.cooled_target_ids.has(target_id):
			state.cooled_target_ids.append(target_id)
		state.is_cooled = true
		state.cooling_required = true
		state.cooling_state = STATE_COOLED
		return


static func _get_objects_at_cell(world_objects: Array[Dictionary], cell: Vector2i, fan_object_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_data in world_objects:
		if str(object_data.get("id", "")) == fan_object_id:
			continue
		var object_cell: Vector2i = _to_vector2i(object_data.get("position", Vector2i(-99999, -99999)))
		if object_cell == cell:
			result.append(object_data)
	return result


static func _get_coolable_target_ids_at_cell(cell_objects: Array[Dictionary], network_id: String, fan_object: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var linked_ids: Array[String] = _get_linked_target_ids(fan_object)
	for object_data in cell_objects:
		if not _is_generic_cooling_target(object_data):
			continue
		var target_id: String = str(object_data.get("id", ""))
		var target_network_id: String = str(object_data.get("airflow_network_id", ""))
		if target_network_id != network_id:
			continue
		if not linked_ids.is_empty() and not linked_ids.has(target_id):
			continue
		result.append(target_id)
	return result


static func _get_linked_target_ids(fan_object: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for field_name in ["linked_cooling_ids", "linked_target_ids", "cooled_target_ids", "target_object_ids"]:
		var value: Variant = fan_object.get(field_name, [])
		if value is Array:
			for id_variant in Array(value):
				var target_id: String = str(id_variant).strip_edges()
				if not target_id.is_empty() and not result.has(target_id):
					result.append(target_id)
	var single_target_id: String = str(fan_object.get("target_object_id", "")).strip_edges()
	if not single_target_id.is_empty() and not result.has(single_target_id):
		result.append(single_target_id)
	return result


static func _cell_blocks_airflow(cell_objects: Array[Dictionary]) -> bool:
	for object_data in cell_objects:
		if _has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_AIRFLOW_BLOCKER):
			return true
		if bool(object_data.get("blocks_airflow", false)):
			return true
	return false


static func _cell_has_path_role(cell_objects: Array[Dictionary]) -> bool:
	for object_data in cell_objects:
		if PassiveRouteServiceRef.get_kind(object_data) == PassiveRouteServiceRef.KIND_AIR_DUCT:
			return true
		if _has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_AIRFLOW_PATH_CELL):
			return true
	return false


static func _is_generic_fan(object_data: Dictionary) -> bool:
	return _uses_generic_airflow_runtime(object_data) and (_has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_FAN) or _has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_AIRFLOW_SOURCE))


static func _is_generic_cooling_target(object_data: Dictionary) -> bool:
	if not _uses_generic_airflow_runtime(object_data):
		return false
	if _has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_COOLING_TARGET):
		return true
	if _has_airflow_role(object_data, BipobAirflowRuntimeStateRef.ROLE_HEAT_SENSITIVE_TERMINAL):
		return true
	return bool(object_data.get("cooling_required", false))


static func _uses_generic_airflow_runtime(object_data: Dictionary) -> bool:
	if bool(object_data.get("generic_airflow_runtime", false)):
		return true
	if str(object_data.get("airflow_network_id", "")).strip_edges().is_empty():
		return false
	return object_data.has("generic_airflow_role") or object_data.has("airflow_roles") or object_data.has("cooling_required")


static func _has_airflow_role(object_data: Dictionary, role: String) -> bool:
	var single_role: String = str(object_data.get("generic_airflow_role", "")).strip_edges()
	if single_role == role:
		return true
	var roles_variant: Variant = object_data.get("airflow_roles", [])
	if roles_variant is Array:
		for role_variant in Array(roles_variant):
			if str(role_variant).strip_edges() == role:
				return true
	return false


static func _build_target_report(object_data: Dictionary) -> Dictionary:
	return {
		"object_id": str(object_data.get("id", "")),
		"airflow_network_id": str(object_data.get("airflow_network_id", "")),
		"fan_object_id": str(object_data.get("fan_object_id", object_data.get("cooled_by_fan_id", ""))),
		"is_cooled": bool(object_data.get("is_cooled", false)),
		"cooling_required": bool(object_data.get("cooling_required", false)),
		"cooling_received": int(object_data.get("cooling_received", 0)),
		"cooling_state": str(object_data.get("cooling_state", STATE_UNCOOLED)),
		"cooling_source_ids": Array(object_data.get("cooling_source_ids", [])).duplicate(),
	}


static func _direction_to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	var direction_text: String = str(value).strip_edges().to_lower()
	match direction_text:
		"up", "north":
			return Vector2i.UP
		"down", "south":
			return Vector2i.DOWN
		"left", "west":
			return Vector2i.LEFT
		"right", "east":
			return Vector2i.RIGHT
	return Vector2i.RIGHT


static func _to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		var array_value: Array = Array(value)
		return Vector2i(int(array_value[0]), int(array_value[1]))
	if value is Dictionary:
		var dictionary_value: Dictionary = Dictionary(value)
		return Vector2i(int(dictionary_value.get("x", 0)), int(dictionary_value.get("y", 0)))
	return Vector2i.ZERO
