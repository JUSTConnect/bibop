extends RefCounted
class_name BipobCableRuntimeService

const CableRuntimeStateRef = preload("res://scripts/game/bipob_cable_runtime_state.gd")

const ROLE_POWER_SOURCE: String = "power_source"
const ROLE_SOCKET_INPUT: String = "socket_input"
const ROLE_SOCKET_OUTPUT: String = "socket_output"
const ROLE_CABLE_ENDPOINT: String = "cable_endpoint"
const ROLE_CABLE_LINK: String = "cable_link"
const ROLE_CABLE_SEGMENT: String = "cable_segment"
const ROLE_POWER_SINK: String = "power_sink"
const ROLE_POWERED_DEVICE: String = "powered_device"

const POWER_STATE_POWERED: String = "powered"
const POWER_STATE_UNPOWERED: String = "unpowered"
const POWER_STATE_SOURCE_ON: String = "source_on"
const POWER_STATE_SOURCE_OFF: String = "source_off"


## Data-only cable/socket/power runtime helper.
##
## Transition helpers return a cloned BipobCableRuntimeState and leave the input
## state untouched. Generic propagation mutates the supplied world-object
## dictionaries in place.
static func create_empty_state() -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = CableRuntimeStateRef.new()
	return result


static func can_start_drag(state: BipobCableRuntimeState, hand_occupied: bool = false) -> bool:
	if state == null:
		return false
	if hand_occupied:
		return false
	if state.is_cable_connected():
		return false
	return state.has_cable() and not state.is_dragging()


static func start_drag(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_start_drag(result):
		result.state = CableRuntimeStateRef.STATE_DRAGGING
	return result


static func can_extend_path(state: BipobCableRuntimeState, next_cell: Vector2i) -> bool:
	if state == null:
		return false
	if not state.is_dragging():
		return false
	if not state.can_extend_path():
		return false
	var path_size: int = state.path_cells.size()
	if path_size > 0 and state.path_cells[path_size - 1] == next_cell:
		return false
	return true


static func extend_path(state: BipobCableRuntimeState, next_cell: Vector2i) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_extend_path(result, next_cell):
		result.add_path_cell(next_cell)
	return result


static func update_drag_path_for_actor_cell(state: BipobCableRuntimeState, actor_cell: Vector2i) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if result == null or not result.is_dragging():
		return result

	if result.path_cells.is_empty():
		result.path_cells.append(result.reel_position)

	var next_cell: Vector2i = actor_cell
	var tail_index: int = result.path_cells.size() - 1
	var tail_cell: Vector2i = result.path_cells[tail_index]

	if tail_cell == next_cell:
		return result

	if result.path_cells.size() >= 2 and result.path_cells[result.path_cells.size() - 2] == next_cell:
		result.path_cells.pop_back()
		return result

	var existing_index: int = result.path_cells.find(next_cell)
	if existing_index >= 0:
		result.path_cells = result.path_cells.slice(0, existing_index + 1)
		return result

	if _are_grid_adjacent(tail_cell, next_cell):
		if result.max_length <= 0 or result.path_cells.size() < result.max_length:
			result.path_cells.append(next_cell)
		return result

	return result


static func _are_grid_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


static func can_connect_to_socket(state: BipobCableRuntimeState, socket_id: String = "", power_filter: String = "") -> bool:
	if state == null:
		return false
	if not state.is_dragging():
		return false
	if state.is_cable_connected():
		return false
	if not socket_id.is_empty() and not state.socket_id.is_empty() and state.socket_id != socket_id:
		return false
	if not power_filter.is_empty() and not state.power_filter.is_empty() and state.power_filter != power_filter:
		return false
	return true


static func connect_to_socket(state: BipobCableRuntimeState, socket_id: String = "", linked_target_id: String = "") -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if can_connect_to_socket(result, socket_id):
		result.connected = true
		result.state = CableRuntimeStateRef.STATE_CONNECTED
		if not socket_id.is_empty():
			result.socket_id = socket_id
		if not linked_target_id.is_empty():
			result.linked_target_id = linked_target_id
	return result


static func release_cable(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	if not result.is_cable_connected():
		result.state = CableRuntimeStateRef.STATE_RELEASED
	return result


static func clear_path(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = _duplicate_state_or_empty(state)
	result.clear_path()
	return result


static func get_status_text(state: BipobCableRuntimeState) -> String:
	if state == null or not state.has_cable():
		return "No cable selected."
	if state.is_cable_connected():
		return "Cable connected."
	if state.is_dragging():
		return "Cable dragging."
	if state.state == CableRuntimeStateRef.STATE_RELEASED:
		return "Cable released."
	return "Cable idle."


static func apply_generic_power_runtime(objects: Array[Dictionary], network_filter: String = "") -> Dictionary:
	var normalized_filter: String = network_filter.strip_edges()
	var object_by_id: Dictionary = {}
	var candidate_ids: Array[String] = []
	var source_ids: Array[String] = []
	var powered_ids: Dictionary = {}
	var changes: Array[Dictionary] = []
	var warnings: Array[String] = []

	for object_data in objects:
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		object_by_id[object_id] = object_data
		if not _is_generic_runtime_candidate(object_data):
			continue
		if not _matches_network_filter(object_data, normalized_filter):
			continue
		candidate_ids.append(object_id)
		var role: String = get_generic_power_role(object_data)
		object_data["generic_power_role"] = role
		_apply_default_runtime_fields(object_data)
		var source_available: bool = role == ROLE_POWER_SOURCE and _is_object_available_for_power(object_data)
		if source_available:
			source_ids.append(object_id)
			powered_ids[object_id] = true
			_set_runtime_power_state(object_data, true, object_id, POWER_STATE_SOURCE_ON, changes)
		elif role == ROLE_POWER_SOURCE:
			_set_runtime_power_state(object_data, false, "", POWER_STATE_SOURCE_OFF, changes)
		else:
			_set_runtime_power_state(object_data, false, "", POWER_STATE_UNPOWERED, changes)

	var changed: bool = true
	var iteration_count: int = 0
	var iteration_cap: int = maxi(8, candidate_ids.size() * 4)
	while changed and iteration_count < iteration_cap:
		changed = false
		iteration_count += 1
		for candidate_id in candidate_ids:
			if bool(powered_ids.get(candidate_id, false)):
				continue
			var candidate_variant: Variant = object_by_id.get(candidate_id, {})
			if not (candidate_variant is Dictionary):
				continue
			var candidate: Dictionary = Dictionary(candidate_variant)
			if not _is_object_available_for_power(candidate):
				continue
			var upstream_id: String = _find_powered_upstream_id(candidate, candidate_ids, object_by_id, powered_ids)
			if upstream_id.is_empty():
				continue
			powered_ids[candidate_id] = true
			var source_id: String = _resolve_source_id(candidate, upstream_id, object_by_id)
			_set_runtime_power_state(candidate, true, source_id, POWER_STATE_POWERED, changes)
			changed = true

	for candidate_id in candidate_ids:
		if bool(powered_ids.get(candidate_id, false)):
			continue
		var candidate_variant: Variant = object_by_id.get(candidate_id, {})
		if candidate_variant is Dictionary:
			var candidate: Dictionary = Dictionary(candidate_variant)
			if _requires_power(candidate):
				candidate["power_unavailable_reason"] = "generic_chain_incomplete"

	if iteration_count >= iteration_cap and changed:
		warnings.append("generic_cable_runtime_iteration_cap_reached")

	return {
		"ok": warnings.is_empty(),
		"network_filter": normalized_filter,
		"candidate_count": candidate_ids.size(),
		"source_ids": source_ids,
		"powered_ids": powered_ids.keys(),
		"unpowered_ids": _collect_unpowered_ids(candidate_ids, powered_ids),
		"changes": changes,
		"warnings": warnings
	}


static func get_generic_power_role(object_data: Dictionary) -> String:
	var explicit_role: String = str(object_data.get("generic_power_role", object_data.get("power_role", object_data.get("cable_role", "")))).strip_edges().to_lower()
	if explicit_role == "cable_segment":
		return ROLE_CABLE_SEGMENT
	if explicit_role in [ROLE_POWER_SOURCE, ROLE_SOCKET_INPUT, ROLE_SOCKET_OUTPUT, ROLE_CABLE_ENDPOINT, ROLE_CABLE_LINK, ROLE_POWER_SINK, ROLE_POWERED_DEVICE]:
		return explicit_role
	var object_type: String = _normalize_token(object_data.get("object_type", ""))
	if object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]:
		return ROLE_POWER_SOURCE
	if object_type == "power_socket":
		var socket_role: String = str(object_data.get("socket_role", "")).strip_edges().to_lower()
		if socket_role == ROLE_SOCKET_OUTPUT:
			return ROLE_SOCKET_OUTPUT
		return ROLE_SOCKET_INPUT
	if object_type == "power_cable_reel":
		return ROLE_CABLE_ENDPOINT
	if object_type == "power_cable":
		return ROLE_CABLE_LINK
	if bool(object_data.get("power_required", false)) or bool(object_data.get("requires_external_power", false)):
		return ROLE_POWER_SINK
	return ""


static func _duplicate_state_or_empty(state: BipobCableRuntimeState) -> BipobCableRuntimeState:
	var result: BipobCableRuntimeState = create_empty_state()
	if state == null:
		return result
	var state_data: Dictionary = state.to_dictionary()
	result.from_dictionary(state_data)
	return result


static func _is_generic_runtime_candidate(object_data: Dictionary) -> bool:
	if bool(object_data.get("generic_power_runtime", false)):
		return true
	if bool(object_data.get("uses_generic_cable_runtime", false)):
		return true
	if not str(object_data.get("generic_power_role", object_data.get("power_role", object_data.get("cable_role", "")))).strip_edges().is_empty():
		return true
	for field_name in ["connection_id", "source_object_id", "sink_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id"]:
		if not str(object_data.get(field_name, "")).strip_edges().is_empty():
			return true
	return false


static func _apply_default_runtime_fields(object_data: Dictionary) -> void:
	if not object_data.has("power_network_id"):
		object_data["power_network_id"] = ""
	for field_name in ["connection_id", "source_object_id", "sink_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id"]:
		if not object_data.has(field_name):
			object_data[field_name] = ""
	if not object_data.has("is_connected"):
		object_data["is_connected"] = bool(object_data.get("connected", true))
	if not object_data.has("is_powered"):
		object_data["is_powered"] = false
	if not object_data.has("runtime_power_state"):
		object_data["runtime_power_state"] = POWER_STATE_UNPOWERED
	if not object_data.has("runtime_power_required"):
		object_data["runtime_power_required"] = _role_requires_power(get_generic_power_role(object_data))
	if not object_data.has("runtime_power_received"):
		object_data["runtime_power_received"] = 0


static func _set_runtime_power_state(object_data: Dictionary, powered: bool, source_id: String, power_state: String, changes: Array[Dictionary]) -> void:
	var before_powered: bool = bool(object_data.get("is_powered", false))
	var before_state: String = str(object_data.get("runtime_power_state", object_data.get("power_state", "")))
	var power_received_value: int = 0
	if powered:
		power_received_value = 1
	object_data["is_powered"] = powered
	object_data["runtime_power_received"] = power_received_value
	object_data["runtime_power_state"] = power_state
	if powered:
		object_data["resolved_source_id"] = source_id
		var resolved_source_object_id: String = str(object_data.get("source_object_id", source_id))
		if get_generic_power_role(object_data) == ROLE_POWER_SOURCE:
			resolved_source_object_id = source_id
		object_data["source_object_id"] = resolved_source_object_id
		object_data["power_unavailable_reason"] = ""
		_restore_powered_object_state(object_data)
	else:
		if get_generic_power_role(object_data) != ROLE_POWER_SOURCE:
			object_data["resolved_source_id"] = ""
		object_data["runtime_power_received"] = 0
		_apply_unpowered_object_state(object_data)
	var object_id: String = str(object_data.get("id", ""))
	if before_powered != powered or before_state != power_state:
		changes.append({"object_id": object_id, "is_powered_before": before_powered, "is_powered_after": powered, "power_state_before": before_state, "power_state_after": power_state})


static func _restore_powered_object_state(object_data: Dictionary) -> void:
	if not _requires_power(object_data):
		return
	var current_state: String = _normalize_token(object_data.get("state", ""))
	if current_state != "unpowered":
		return
	var restored_state: String = str(object_data.get("state_before_unpowered", "active")).strip_edges()
	if restored_state.is_empty() or restored_state in ["unpowered", "damaged", "broken", "destroyed"]:
		restored_state = "active"
	object_data["state"] = restored_state
	object_data["status"] = restored_state
	object_data.erase("state_before_unpowered")


static func _apply_unpowered_object_state(object_data: Dictionary) -> void:
	if not _requires_power(object_data):
		return
	var current_state: String = _normalize_token(object_data.get("state", "active"))
	if current_state in ["damaged", "broken", "destroyed", "unpowered"]:
		if current_state == "unpowered":
			object_data["status"] = "unpowered"
		return
	object_data["state_before_unpowered"] = current_state
	object_data["state"] = "unpowered"
	object_data["status"] = "unpowered"


static func _find_powered_upstream_id(candidate: Dictionary, candidate_ids: Array[String], object_by_id: Dictionary, powered_ids: Dictionary) -> String:
	var direct_ids: Array[String] = []
	var link_fields: Array[String] = ["source_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id"]
	if _requires_power(candidate):
		link_fields = ["socket_id", "endpoint_a_id", "endpoint_b_id"]
	for field_name in link_fields:
		var linked_id: String = str(candidate.get(field_name, "")).strip_edges()
		if not linked_id.is_empty() and bool(powered_ids.get(linked_id, false)):
			return linked_id
		if not linked_id.is_empty():
			direct_ids.append(linked_id)
	var candidate_id: String = str(candidate.get("id", "")).strip_edges()
	for other_id in candidate_ids:
		if other_id == candidate_id or not bool(powered_ids.get(other_id, false)):
			continue
		var other_variant: Variant = object_by_id.get(other_id, {})
		if not (other_variant is Dictionary):
			continue
		var other: Dictionary = Dictionary(other_variant)
		if _objects_are_explicitly_linked(candidate, other, direct_ids):
			return other_id
	return ""


static func _objects_are_explicitly_linked(candidate: Dictionary, other: Dictionary, direct_ids: Array[String]) -> bool:
	var candidate_id: String = str(candidate.get("id", "")).strip_edges()
	var other_id: String = str(other.get("id", "")).strip_edges()
	if candidate_id.is_empty() or other_id.is_empty():
		return false
	for field_name in ["source_object_id", "sink_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id"]:
		if str(other.get(field_name, "")).strip_edges() == candidate_id:
			return true
	if direct_ids.has(other_id):
		return true
	if _requires_power(candidate):
		return false
	var candidate_connection: String = str(candidate.get("connection_id", "")).strip_edges()
	var other_connection: String = str(other.get("connection_id", "")).strip_edges()
	if not candidate_connection.is_empty() and candidate_connection == other_connection:
		return true
	return false


static func _resolve_source_id(candidate: Dictionary, upstream_id: String, object_by_id: Dictionary) -> String:
	var explicit_source_id: String = str(candidate.get("source_object_id", "")).strip_edges()
	if not explicit_source_id.is_empty() and object_by_id.has(explicit_source_id):
		var explicit_variant: Variant = object_by_id.get(explicit_source_id, {})
		if explicit_variant is Dictionary and get_generic_power_role(Dictionary(explicit_variant)) == ROLE_POWER_SOURCE:
			return explicit_source_id
	var upstream_variant: Variant = object_by_id.get(upstream_id, {})
	if upstream_variant is Dictionary:
		var upstream: Dictionary = Dictionary(upstream_variant)
		if get_generic_power_role(upstream) == ROLE_POWER_SOURCE:
			return upstream_id
		var upstream_source_id: String = str(upstream.get("power_source_id", upstream.get("source_object_id", ""))).strip_edges()
		if not upstream_source_id.is_empty():
			return upstream_source_id
	return upstream_id


static func _requires_power(object_data: Dictionary) -> bool:
	if bool(object_data.get("power_required", false)):
		return true
	return _role_requires_power(get_generic_power_role(object_data))


static func _role_requires_power(role: String) -> bool:
	return role in [ROLE_POWER_SINK, ROLE_POWERED_DEVICE]


static func _is_object_available_for_power(object_data: Dictionary) -> bool:
	var state: String = _normalize_token(object_data.get("state", ""))
	if state in ["cut", "damaged", "broken", "destroyed", "disabled", "off", "switch_off", "overheated"]:
		return false
	if bool(object_data.get("cut", false)) or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		return false
	if object_data.has("is_connected") and not bool(object_data.get("is_connected", false)):
		return false
	if object_data.has("connected") and not bool(object_data.get("connected", true)):
		return false
	return true


static func _matches_network_filter(object_data: Dictionary, network_filter: String) -> bool:
	if network_filter.is_empty():
		return true
	var network_id: String = str(object_data.get("power_network_id", "")).strip_edges()
	var source_id: String = str(object_data.get("source_object_id", object_data.get("power_source_id", ""))).strip_edges()
	return network_id == network_filter or source_id == network_filter


static func _collect_unpowered_ids(candidate_ids: Array[String], powered_ids: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for candidate_id in candidate_ids:
		if not bool(powered_ids.get(candidate_id, false)):
			result.append(candidate_id)
	return result


static func _normalize_token(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
