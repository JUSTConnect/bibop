extends RefCounted
class_name PowerControlResolver

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const BindingStoreContractRef = preload("res://scripts/world/world_binding_store_contract.gd")

const POWER_MODE_NONE := "none"
const POWER_MODE_INTERNAL := "internal"
const POWER_MODE_EXTERNAL := "external"
const POWER_MODES: Array[String] = [POWER_MODE_NONE, POWER_MODE_INTERNAL, POWER_MODE_EXTERNAL]

const POWER_STATE_NONE := "none"
const POWER_STATE_POWERED := "powered"
const POWER_STATE_UNPOWERED := "unpowered"
const POWER_STATE_AMBIGUOUS := "ambiguous"
const POWER_STATE_INVALID := "invalid"

const CONTROL_MODE_NONE := "none"
const CONTROL_MODE_INTERNAL := "internal"
const CONTROL_MODE_EXTERNAL := "external"
const CONTROL_MODES: Array[String] = [CONTROL_MODE_NONE, CONTROL_MODE_INTERNAL, CONTROL_MODE_EXTERNAL]

const CONTROL_LOSS_KEEP_LAST_STATE := "keep_last_state"
const CONTROL_LOSS_SAFE_OFF := "safe_off"
const CONTROL_LOSS_LOCK := "lock"
const CONTROL_LOSS_STOP_CURRENT_ACTION := "stop_current_action"
const CONTROL_LOSS_CUSTOM := "custom"
const CONTROL_LOSS_BEHAVIORS: Array[String] = [
	CONTROL_LOSS_KEEP_LAST_STATE,
	CONTROL_LOSS_SAFE_OFF,
	CONTROL_LOSS_LOCK,
	CONTROL_LOSS_STOP_CURRENT_ACTION,
	CONTROL_LOSS_CUSTOM
]

const POWER_SOURCE_TYPES: Array[String] = [
	"power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"
]
const POWER_ROUTE_TYPES: Array[String] = [
	"power_cable", "power_socket", "outlet", "socket",
	"circuit_switch", "circuit_breaker", "power_breaker", "power_knife_switch",
	"fuse_box", "fuse_box_installed", "fuse_box_empty", "fuse_block",
	"light_switch", "power_switcher"
]
const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func resolve_world(objects: Array[Dictionary], bindings: Array[Dictionary] = [], options: Dictionary = {}) -> Dictionary:
	var objects_by_id: Dictionary = _index_objects(objects)
	var candidates_by_entity: Dictionary = _collect_reachable_sources(objects, objects_by_id)
	var power_results: Dictionary = {}
	var source_loads: Dictionary = {}
	var ids: Array = objects_by_id.keys()
	ids.sort()
	for id_value in ids:
		var entity_id: String = str(id_value)
		var object_data: Dictionary = Dictionary(objects_by_id[entity_id])
		var candidates: Array[String] = _string_array(candidates_by_entity.get(entity_id, []))
		var power_result: Dictionary = resolve_power(object_data, candidates, bindings, objects_by_id)
		power_results[entity_id] = power_result
		var selected_source_id: String = str(power_result.get("resolved_source_id", ""))
		if bool(power_result.get("is_powered", false)) and not selected_source_id.is_empty() and _is_load_consumer(object_data):
			source_loads[selected_source_id] = int(source_loads.get(selected_source_id, 0)) + 1
	var control_results: Dictionary = {}
	for id_value in ids:
		var entity_id: String = str(id_value)
		control_results[entity_id] = resolve_control(
			Dictionary(objects_by_id[entity_id]),
			bindings,
			objects_by_id,
			power_results
		)
	var selected_ids: Array[String] = _select_entity_ids(objects_by_id, power_results, options)
	return {
		"ok": true,
		"success": true,
		"code": "power_control.resolved",
		"reason_code": "power_control.resolved",
		"power_results": power_results,
		"control_results": control_results,
		"source_loads": source_loads,
		"selected_entity_ids": selected_ids,
		"details": {"entity_count": ids.size(), "selected_count": selected_ids.size()}
	}

static func resolve_power(object_data: Dictionary, reachable_source_ids: Array[String], bindings: Array[Dictionary], objects_by_id: Dictionary) -> Dictionary:
	var entity_id: String = str(object_data.get("id", "")).strip_edges()
	if entity_id.is_empty():
		return _power_result("power.invalid", entity_id, POWER_MODE_NONE, POWER_STATE_INVALID, false, "", "", [], "")
	var mode: String = power_mode_for(object_data)
	if mode not in POWER_MODES:
		return _power_result("power.invalid_mode", entity_id, mode, POWER_STATE_INVALID, false, "", "", reachable_source_ids, "")
	if mode == POWER_MODE_NONE:
		return _power_result("power.none", entity_id, mode, POWER_STATE_NONE, true, "", "", [], "")
	if mode == POWER_MODE_INTERNAL:
		return _power_result("power.internal", entity_id, mode, POWER_STATE_POWERED, true, "", "internal", [], "")
	if _has_active_runtime_reel_feed(object_data):
		var reel_source_id: String = str(object_data.get("resolved_source_id", "")).strip_edges()
		if not reel_source_id.is_empty():
			return _power_result("power.powered", entity_id, mode, POWER_STATE_POWERED, true, reel_source_id, "main", [reel_source_id], "")
		return _power_result("power.unpowered", entity_id, mode, POWER_STATE_UNPOWERED, false, "", "main", [], str(object_data.get("power_unavailable_reason", "power.reel_source_missing")))
	var candidates: Array[String] = []
	for source_id in reachable_source_ids:
		if not objects_by_id.has(source_id):
			continue
		var source: Dictionary = Dictionary(objects_by_id[source_id])
		if _is_power_source(source) and _source_is_operational(source) and not candidates.has(source_id):
			candidates.append(source_id)
	candidates.sort()
	if candidates.is_empty():
		return _power_result("power.unpowered", entity_id, mode, POWER_STATE_UNPOWERED, false, "", _resolved_circuit_id(object_data, ""), [], "power.no_reachable_source")
	if candidates.size() == 1:
		var source_id: String = candidates[0]
		return _power_result("power.powered", entity_id, mode, POWER_STATE_POWERED, true, source_id, _resolved_circuit_id(object_data, source_id, objects_by_id), candidates, "")
	var preferred_source_id: String = _preferred_source_from_bindings(entity_id, candidates, bindings)
	if not preferred_source_id.is_empty():
		return _power_result("power.powered", entity_id, mode, POWER_STATE_POWERED, true, preferred_source_id, _resolved_circuit_id(object_data, preferred_source_id, objects_by_id), candidates, "")
	return _power_result("power.ambiguous", entity_id, mode, POWER_STATE_AMBIGUOUS, false, "", _resolved_circuit_id(object_data, ""), candidates, "power.preferred_source_required")

static func resolve_control(object_data: Dictionary, bindings: Array[Dictionary], objects_by_id: Dictionary, power_results: Dictionary = {}) -> Dictionary:
	var entity_id: String = str(object_data.get("id", "")).strip_edges()
	var mode: String = control_mode_for(object_data)
	var loss_behavior: String = control_loss_behavior_for(object_data)
	if entity_id.is_empty():
		return _control_result("control.invalid", entity_id, mode, false, false, false, "", loss_behavior)
	if mode not in CONTROL_MODES:
		return _control_result("control.invalid_mode", entity_id, mode, false, false, false, "", loss_behavior)
	if mode == CONTROL_MODE_NONE:
		return _control_result("control.none", entity_id, mode, false, false, false, "", loss_behavior)
	var entity_power: Dictionary = Dictionary(power_results.get(entity_id, {}))
	if entity_power.is_empty():
		entity_power = resolve_power(object_data, [], bindings, objects_by_id)
	if not bool(entity_power.get("is_powered", true)):
		return _control_result("control.target_unpowered", entity_id, mode, false, false, false, "", loss_behavior)
	if not _entity_is_operational(object_data):
		return _control_result("control.target_inactive", entity_id, mode, false, false, false, "", loss_behavior)
	if mode == CONTROL_MODE_INTERNAL:
		return _control_result("control.available", entity_id, mode, true, true, false, entity_id, loss_behavior)
	var matching_bindings: Array[Dictionary] = []
	for binding in bindings:
		if str(binding.get("role", "")).strip_edges().to_lower() != BindingStoreContractRef.ROLE_CONTROL_TERMINAL:
			continue
		if str(binding.get("target_id", "")).strip_edges() == entity_id:
			matching_bindings.append(binding.duplicate(true))
	if matching_bindings.is_empty():
		return _control_result("control.binding_missing", entity_id, mode, false, false, false, "", loss_behavior)
	if matching_bindings.size() > 1:
		return _control_result("control.binding_ambiguous", entity_id, mode, false, false, false, "", loss_behavior)
	var controller_id: String = str(matching_bindings[0].get("source_id", "")).strip_edges()
	if controller_id.is_empty() or not objects_by_id.has(controller_id):
		return _control_result("control.controller_missing", entity_id, mode, false, false, false, controller_id, loss_behavior)
	var controller: Dictionary = Dictionary(objects_by_id[controller_id])
	if not _is_terminal(controller):
		return _control_result("control.controller_wrong_type", entity_id, mode, false, false, false, controller_id, loss_behavior)
	var controller_power: Dictionary = Dictionary(power_results.get(controller_id, {}))
	if controller_power.is_empty():
		controller_power = resolve_power(controller, [], bindings, objects_by_id)
	if not bool(controller_power.get("is_powered", true)):
		return _control_result("control.controller_unpowered", entity_id, mode, false, false, false, controller_id, loss_behavior)
	if not _entity_is_operational(controller):
		return _control_result("control.controller_inactive", entity_id, mode, false, false, false, controller_id, loss_behavior)
	return _control_result("control.available", entity_id, mode, true, false, true, controller_id, loss_behavior)

static func apply_world_results(objects: Array[Dictionary], bindings: Array[Dictionary] = [], options: Dictionary = {}) -> Dictionary:
	var resolution: Dictionary = resolve_world(objects, bindings, options)
	var selected_ids: Array[String] = _string_array(resolution.get("selected_entity_ids", []))
	var selected_lookup: Dictionary = {}
	for entity_id in selected_ids:
		selected_lookup[entity_id] = true
	var power_results: Dictionary = Dictionary(resolution.get("power_results", {}))
	var control_results: Dictionary = Dictionary(resolution.get("control_results", {}))
	var source_loads: Dictionary = Dictionary(resolution.get("source_loads", {}))
	var changed_ids: Array[String] = []
	for index in range(objects.size()):
		var object_data: Dictionary = Dictionary(objects[index]).duplicate(true)
		var entity_id: String = str(object_data.get("id", "")).strip_edges()
		if entity_id.is_empty() or not selected_lookup.has(entity_id):
			continue
		var before: String = var_to_str(_computed_snapshot(object_data))
		var power_result: Dictionary = Dictionary(power_results.get(entity_id, {}))
		var control_result: Dictionary = Dictionary(control_results.get(entity_id, {}))
		_apply_power_result(object_data, power_result)
		_apply_control_result(object_data, control_result)
		if _is_power_source(object_data):
			var load: int = int(source_loads.get(entity_id, 0))
			var capacity: int = _source_capacity(object_data)
			object_data["source_load"] = load
			object_data["source_capacity"] = capacity
			object_data["source_overloaded"] = load > capacity
			object_data["heat_from_connections"] = maxi(0, load - capacity)
		objects[index] = object_data
		if before != var_to_str(_computed_snapshot(object_data)):
			changed_ids.append(entity_id)
	resolution["changed_entity_ids"] = changed_ids
	return resolution

static func apply_scoped_event(objects: Array[Dictionary], bindings: Array[Dictionary], event: Dictionary) -> Dictionary:
	var options: Dictionary = event.duplicate(true)
	var event_type: String = str(event.get("event_type", event.get("type", "power.explicit"))).strip_edges().to_lower()
	if event_type.is_empty():
		event_type = "power.explicit"
	var result: Dictionary = apply_world_results(objects, bindings, options)
	result["event_type"] = event_type
	result["affected_entity_ids"] = Array(result.get("selected_entity_ids", [])).duplicate(true)
	return result

static func build_control_loss_patch(object_data: Dictionary, control_result: Dictionary) -> Dictionary:
	var behavior: String = control_loss_behavior_for(object_data)
	if bool(control_result.get("available", false)) or control_mode_for(object_data) != CONTROL_MODE_EXTERNAL:
		return {"ok":true, "success":true, "code":"control.loss_not_applicable", "reason_code":"control.loss_not_applicable", "behavior":behavior, "patch":{}, "custom_handler_required":false}
	var patch: Dictionary = {}
	var custom_handler_required: bool = false
	match behavior:
		CONTROL_LOSS_KEEP_LAST_STATE:
			pass
		CONTROL_LOSS_SAFE_OFF:
			patch["intent_state"] = "off"
		CONTROL_LOSS_LOCK:
			patch["operational_state"] = "locked"
		CONTROL_LOSS_STOP_CURRENT_ACTION:
			patch["current_action"] = ""
			patch["action_in_progress"] = false
		CONTROL_LOSS_CUSTOM:
			custom_handler_required = true
	return {"ok":true, "success":true, "code":"control.loss_patch_ready", "reason_code":"control.loss_patch_ready", "behavior":behavior, "patch":patch, "custom_handler_required":custom_handler_required}

static func power_mode_for(object_data: Dictionary) -> String:
	if _is_power_source(object_data):
		return POWER_MODE_INTERNAL
	var raw_mode: String = _normalize_mode(object_data.get("power_mode", object_data.get("power_type", "")))
	if raw_mode in POWER_MODES:
		return raw_mode
	var contract: Dictionary = WorldObjectCatalogRef.get_entity_definition_contract_for_object(object_data)
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {}))
	if not bool(capabilities.get("power", false)):
		return POWER_MODE_NONE
	if bool(object_data.get("requires_external_power", false)) or not _explicit_circuit_id(object_data).is_empty() or _has_runtime_reel_profile(object_data):
		return POWER_MODE_EXTERNAL
	return POWER_MODE_INTERNAL

static func control_mode_for(object_data: Dictionary) -> String:
	var raw_mode: String = _normalize_mode(object_data.get("control_mode", object_data.get("control_type", "")))
	if raw_mode in CONTROL_MODES:
		return raw_mode
	var contract: Dictionary = WorldObjectCatalogRef.get_entity_definition_contract_for_object(object_data)
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {}))
	if not bool(capabilities.get("control", false)):
		return CONTROL_MODE_NONE
	return CONTROL_MODE_INTERNAL

static func control_loss_behavior_for(object_data: Dictionary) -> String:
	var behavior: String = str(object_data.get("control_loss_behavior", CONTROL_LOSS_KEEP_LAST_STATE)).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if behavior not in CONTROL_LOSS_BEHAVIORS:
		return CONTROL_LOSS_KEEP_LAST_STATE
	return behavior

static func _collect_reachable_sources(objects: Array[Dictionary], objects_by_id: Dictionary) -> Dictionary:
	var buckets: Dictionary = _build_cell_buckets(objects)
	var result: Dictionary = {}
	var source_ids: Array[String] = []
	for object_data in objects:
		var entity_id: String = str(object_data.get("id", "")).strip_edges()
		if not entity_id.is_empty():
			result[entity_id] = []
		if _is_power_source(object_data) and _source_is_operational(object_data):
			source_ids.append(entity_id)
	source_ids.sort()
	for source_id in source_ids:
		if not objects_by_id.has(source_id):
			continue
		var source: Dictionary = Dictionary(objects_by_id[source_id])
		var source_cell: Vector2i = _cell(source)
		if not _valid_cell(source_cell):
			continue
		var queue: Array[Dictionary] = [{"object_id":source_id, "from_cell":Vector2i(-999999, -999999)}]
		var visited: Dictionary = {}
		while not queue.is_empty():
			var entry: Dictionary = Dictionary(queue.pop_front())
			var current_id: String = str(entry.get("object_id", ""))
			var from_cell: Vector2i = Vector2i(entry.get("from_cell", Vector2i(-999999, -999999)))
			if not objects_by_id.has(current_id):
				continue
			var current: Dictionary = Dictionary(objects_by_id[current_id])
			var current_cell: Vector2i = _cell(current)
			var visit_key: String = "%s|%d,%d" % [current_id, from_cell.x, from_cell.y]
			if visited.has(visit_key):
				continue
			visited[visit_key] = true
			var candidate_ids: Array[String] = _neighbor_candidate_ids(current_cell, buckets)
			for candidate_id in candidate_ids:
				if candidate_id == current_id or not objects_by_id.has(candidate_id):
					continue
				var candidate: Dictionary = Dictionary(objects_by_id[candidate_id])
				var candidate_cell: Vector2i = _cell(candidate)
				if not _circuit_compatible(current, candidate):
					continue
				if _is_power_source(current) and not _is_route_node(candidate):
					continue
				if _is_route_node(current) and not _switch_allows_transition(current, from_cell, candidate_cell, objects_by_id):
					continue
				if not _can_receive_external_power(candidate) and not _is_route_node(candidate) and not _is_power_source(candidate):
					continue
				if not _is_power_source(candidate):
					_append_unique_string(result, candidate_id, source_id)
				if _is_route_node(candidate) and not _route_is_blocked(candidate):
					queue.append({"object_id":candidate_id, "from_cell":current_cell})
	return result

static func _neighbor_candidate_ids(cell: Vector2i, buckets: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for id_value in Array(buckets.get(cell, [])):
		var same_id: String = str(id_value)
		if not result.has(same_id):
			result.append(same_id)
	for delta in CARDINAL_DIRECTIONS:
		for id_value in Array(buckets.get(cell + delta, [])):
			var neighbor_id: String = str(id_value)
			if not result.has(neighbor_id):
				result.append(neighbor_id)
	result.sort()
	return result

static func _switch_allows_transition(switch_object: Dictionary, entered_from_cell: Vector2i, next_cell: Vector2i, objects_by_id: Dictionary) -> bool:
	var object_type: String = _object_type(switch_object)
	var switch_cell: Vector2i = _cell(switch_object)
	if object_type == "circuit_switch" and _has_circuit_switch_metadata(switch_object):
		var input_cell: Vector2i = _resolve_switch_cell(switch_object, "input", switch_cell, objects_by_id)
		var active_index: int = int(switch_object.get("active_output_index", 0))
		var output_cell: Vector2i = _resolve_switch_cell(switch_object, "output_%d" % active_index, switch_cell, objects_by_id)
		return (entered_from_cell == input_cell and next_cell == output_cell) or (entered_from_cell == output_cell and next_cell == input_cell)
	if object_type == "power_switcher" and not Array(WorldObjectCatalogRef.normalize_switcher_lines(switch_object)).is_empty():
		var input_delta: Vector2i = _direction_delta(str(switch_object.get("input_direction", "")))
		var input_cell: Vector2i = switch_cell + input_delta
		var lines: Array[Dictionary] = WorldObjectCatalogRef.normalize_switcher_lines(switch_object)
		var active_line_id: String = str(switch_object.get("active_line_id", "")).strip_edges()
		var active_delta: Vector2i = Vector2i.ZERO
		for line in lines:
			if active_line_id.is_empty() or str(line.get("line_id", "")) == active_line_id:
				active_delta = _direction_delta(str(line.get("direction", "")))
				break
		var output_cell: Vector2i = switch_cell + active_delta
		return (entered_from_cell == input_cell and next_cell == output_cell) or (entered_from_cell == output_cell and next_cell == input_cell)
	return true

static func _has_circuit_switch_metadata(object_data: Dictionary) -> bool:
	if object_data.has("active_output_index") or object_data.has("input_wire_id") or object_data.has("input_direction"):
		return true
	for output_index in range(1, 4):
		if object_data.has("output_%d_wire_id" % output_index) or object_data.has("output_%d_direction" % output_index):
			return true
	return false

static func _resolve_switch_cell(object_data: Dictionary, prefix: String, switch_cell: Vector2i, objects_by_id: Dictionary) -> Vector2i:
	var wire_id: String = str(object_data.get("%s_wire_id" % prefix, "")).strip_edges()
	if not wire_id.is_empty() and objects_by_id.has(wire_id):
		return _cell(Dictionary(objects_by_id[wire_id]))
	var delta: Vector2i = _direction_delta(str(object_data.get("%s_direction" % prefix, "")))
	if delta != Vector2i.ZERO:
		return switch_cell + delta
	return Vector2i(-999999, -999999)

static func _route_is_blocked(object_data: Dictionary) -> bool:
	var state: String = str(object_data.get("operational_state", object_data.get("state", ""))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	var health: String = str(object_data.get("health_state", "")).strip_edges().to_lower()
	if health == "broken" or state in ["cut", "damaged", "broken", "destroyed", "invalid_path"]:
		return true
	if bool(object_data.get("cut", false)) or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		return true
	var object_type: String = _object_type(object_data)
	if object_type == "power_cable":
		if object_data.has("connected") and not bool(object_data.get("connected", true)):
			return true
		if object_data.has("is_connected") and not bool(object_data.get("is_connected", true)):
			return true
	if object_type in ["fuse_box", "fuse_box_empty", "fuse_block"]:
		var has_fuse: bool = bool(object_data.get("has_fuse", object_data.get("fuse_present", object_data.get("fuse_installed", state in ["installed", "ok", "active"] or object_type == "fuse_box_installed"))))
		return not has_fuse
	if object_type in ["circuit_switch", "circuit_breaker", "power_breaker", "power_knife_switch", "power_switcher"]:
		var intent: String = str(object_data.get("intent_state", "")).strip_edges().to_lower()
		if intent in ["on", "off"]:
			return intent == "off"
		return state in ["off", "switch_off", "open"] or not bool(object_data.get("is_on", state in ["on", "switch_on", "active", "ok"]))
	return false

static func _source_is_operational(source: Dictionary) -> bool:
	if str(source.get("health_state", "healthy")).strip_edges().to_lower() == "broken":
		return false
	if str(source.get("thermal_state", "normal")).strip_edges().to_lower() == "overheated":
		return false
	if str(source.get("intent_state", "on")).strip_edges().to_lower() == "off":
		return false
	if bool(source.get("damaged", false)) or bool(source.get("broken", false)) or bool(source.get("destroyed", false)):
		return false
	var legacy_state: String = str(source.get("state", "on")).strip_edges().to_lower()
	return legacy_state not in ["off", "broken", "damaged", "destroyed", "overheated", "unpowered"]

static func _entity_is_operational(object_data: Dictionary) -> bool:
	if str(object_data.get("health_state", "healthy")).strip_edges().to_lower() == "broken":
		return false
	if str(object_data.get("thermal_state", "normal")).strip_edges().to_lower() == "overheated":
		return false
	if str(object_data.get("intent_state", "on")).strip_edges().to_lower() == "off":
		return false
	var operational: String = str(object_data.get("operational_state", object_data.get("state", "operational"))).strip_edges().to_lower()
	return operational not in ["broken", "damaged", "destroyed", "disabled", "jammed", "invalid"]

static func _preferred_source_from_bindings(entity_id: String, candidates: Array[String], bindings: Array[Dictionary]) -> String:
	var matches: Array[String] = []
	for binding in bindings:
		if str(binding.get("role", "")).strip_edges().to_lower() != BindingStoreContractRef.ROLE_PREFERRED_POWER_SOURCE:
			continue
		if str(binding.get("source_id", "")).strip_edges() != entity_id:
			continue
		var target_id: String = str(binding.get("target_id", "")).strip_edges()
		if candidates.has(target_id) and not matches.has(target_id):
			matches.append(target_id)
	matches.sort()
	return matches[0] if matches.size() == 1 else ""

static func _select_entity_ids(objects_by_id: Dictionary, power_results: Dictionary, options: Dictionary) -> Array[String]:
	var explicit_ids: Array[String] = _string_array(options.get("entity_ids", []))
	for field_name in ["entity_id", "object_id", "source_id", "socket_id", "target_id"]:
		var value: String = str(options.get(field_name, "")).strip_edges()
		if not value.is_empty() and not explicit_ids.has(value):
			explicit_ids.append(value)
	var network_id: String = str(options.get("network_id", options.get("circuit_id", ""))).strip_edges()
	if explicit_ids.is_empty() and network_id.is_empty():
		explicit_ids = _string_array(objects_by_id.keys())
	elif not network_id.is_empty():
		for id_value in objects_by_id.keys():
			var entity_id: String = str(id_value)
			var object_data: Dictionary = Dictionary(objects_by_id[entity_id])
			var power_result: Dictionary = Dictionary(power_results.get(entity_id, {}))
			if _explicit_circuit_id(object_data) == network_id or str(power_result.get("resolved_circuit_id", "")) == network_id or str(power_result.get("resolved_source_id", "")) == network_id:
				if not explicit_ids.has(entity_id):
					explicit_ids.append(entity_id)
	if not explicit_ids.is_empty():
		var expanded: Array[String] = explicit_ids.duplicate()
		for seed_id in explicit_ids:
			var seed_result: Dictionary = Dictionary(power_results.get(seed_id, {}))
			var seed_source: String = str(seed_result.get("resolved_source_id", ""))
			var seed_circuit: String = str(seed_result.get("resolved_circuit_id", ""))
			for id_value in power_results.keys():
				var entity_id: String = str(id_value)
				var candidate: Dictionary = Dictionary(power_results[entity_id])
				if (not seed_source.is_empty() and str(candidate.get("resolved_source_id", "")) == seed_source) or (not seed_circuit.is_empty() and str(candidate.get("resolved_circuit_id", "")) == seed_circuit):
					if not expanded.has(entity_id):
						expanded.append(entity_id)
		explicit_ids = expanded
	explicit_ids.sort()
	return explicit_ids

static func _apply_power_result(object_data: Dictionary, result: Dictionary) -> void:
	object_data["power_state"] = str(result.get("power_state", POWER_STATE_NONE))
	object_data["is_powered"] = bool(result.get("is_powered", true))
	object_data["resolved_source_id"] = str(result.get("resolved_source_id", ""))
	object_data["resolved_circuit_id"] = str(result.get("resolved_circuit_id", ""))
	object_data["physical_connection_source_id"] = str(result.get("physical_connection_source_id", ""))
	object_data["power_unavailable_reason"] = "" if bool(result.get("is_powered", false)) else str(result.get("reason_code", ""))

static func _apply_control_result(object_data: Dictionary, result: Dictionary) -> void:
	object_data["control_state"] = str(result.get("control_state", "none"))
	object_data["control_available"] = bool(result.get("available", false))
	object_data["local_control_available"] = bool(result.get("local_control_available", false))
	object_data["remote_control_available"] = bool(result.get("remote_control_available", false))
	object_data["resolved_controller_id"] = str(result.get("resolved_controller_id", ""))
	object_data["control_reason_code"] = str(result.get("reason_code", ""))

static func _power_result(code: String, entity_id: String, mode: String, state: String, powered: bool, source_id: String, circuit_id: String, reachable_sources: Array[String], unavailable_reason: String) -> Dictionary:
	return {
		"ok": state != POWER_STATE_INVALID,
		"success": state != POWER_STATE_INVALID,
		"code": code,
		"reason_code": unavailable_reason if not unavailable_reason.is_empty() else code,
		"entity_id": entity_id,
		"power_mode": mode,
		"power_state": state,
		"is_powered": powered,
		"resolved_source_id": source_id,
		"resolved_circuit_id": circuit_id,
		"physical_connection_source_id": source_id if powered else "",
		"reachable_source_ids": reachable_sources.duplicate(),
		"details": {"reachable_source_count": reachable_sources.size()}
	}

static func _control_result(code: String, entity_id: String, mode: String, available: bool, local_available: bool, remote_available: bool, controller_id: String, loss_behavior: String) -> Dictionary:
	return {
		"ok": not code in ["control.invalid", "control.invalid_mode"],
		"success": available,
		"code": code,
		"reason_code": code,
		"entity_id": entity_id,
		"control_mode": mode,
		"control_state": "available" if available else "unavailable" if mode != CONTROL_MODE_NONE else "none",
		"available": available,
		"local_control_available": local_available,
		"remote_control_available": remote_available,
		"resolved_controller_id": controller_id,
		"control_loss_behavior": loss_behavior,
		"details": {}
	}

static func _computed_snapshot(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in ["power_state", "is_powered", "resolved_source_id", "resolved_circuit_id", "physical_connection_source_id", "power_unavailable_reason", "source_load", "source_capacity", "source_overloaded", "heat_from_connections", "control_state", "control_available", "local_control_available", "remote_control_available", "resolved_controller_id", "control_reason_code"]:
		result[key] = object_data.get(key, null)
	return result

static func _is_power_source(object_data: Dictionary) -> bool:
	return _object_type(object_data) in POWER_SOURCE_TYPES or str(object_data.get("generic_power_role", "")).strip_edges().to_lower() == "power_source"

static func _is_route_node(object_data: Dictionary) -> bool:
	return _object_type(object_data) in POWER_ROUTE_TYPES and not _route_is_blocked(object_data)

static func _is_load_consumer(object_data: Dictionary) -> bool:
	return power_mode_for(object_data) == POWER_MODE_EXTERNAL and not _is_route_node(object_data) and not _is_power_source(object_data)

static func _can_receive_external_power(object_data: Dictionary) -> bool:
	return power_mode_for(object_data) == POWER_MODE_EXTERNAL or _is_route_node(object_data)

static func _is_terminal(object_data: Dictionary) -> bool:
	return str(object_data.get("object_group", "")).strip_edges().to_lower() == "terminal" or _object_type(object_data) in ["terminal", "information_terminal", "control_terminal", "access_terminal"]

static func _has_runtime_reel_profile(object_data: Dictionary) -> bool:
	if bool(object_data.get("runtime_reel_feed", false)) or bool(object_data.get("accepts_runtime_power_reel", false)):
		return true
	if str(object_data.get("power_input_profile", "")).strip_edges().to_lower() == "runtime_reel_feed":
		return true
	return Array(object_data.get("power_input_profiles", [])).has("runtime_reel_feed")

static func _has_active_runtime_reel_feed(object_data: Dictionary) -> bool:
	return _has_runtime_reel_profile(object_data) and bool(object_data.get("runtime_reel_feed_active", false))

static func _source_capacity(source: Dictionary) -> int:
	if source.has("outlet_capacity"):
		return maxi(1, int(source.get("outlet_capacity", 1)))
	var source_class: int = clampi(int(source.get("power_source_class", source.get("source_class", 1))), 1, 3)
	var object_type: String = _object_type(source)
	if object_type.ends_with("class_2"):
		source_class = 2
	elif object_type.ends_with("class_3"):
		source_class = 3
	return source_class + 3

static func _resolved_circuit_id(object_data: Dictionary, source_id: String, objects_by_id: Dictionary = {}) -> String:
	var own_circuit: String = _explicit_circuit_id(object_data)
	if not own_circuit.is_empty():
		return own_circuit
	if not source_id.is_empty() and objects_by_id.has(source_id):
		var source_circuit: String = _explicit_circuit_id(Dictionary(objects_by_id[source_id]))
		if not source_circuit.is_empty():
			return source_circuit
	return "physical:%s" % source_id if not source_id.is_empty() else ""

static func _explicit_circuit_id(object_data: Dictionary) -> String:
	for key in ["circuit_id", "power_circuit_id", "power_network_id", "network_id", "chain_id", "link_group", "cable_group", "connected_circuit"]:
		var value: String = str(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

static func _circuit_compatible(left: Dictionary, right: Dictionary) -> bool:
	var left_id: String = _explicit_circuit_id(left)
	var right_id: String = _explicit_circuit_id(right)
	return left_id.is_empty() or right_id.is_empty() or left_id == right_id

static func _build_cell_buckets(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var entity_id: String = str(object_data.get("id", "")).strip_edges()
		var cell: Vector2i = _cell(object_data)
		if entity_id.is_empty() or not _valid_cell(cell):
			continue
		var ids: Array = Array(result.get(cell, []))
		ids.append(entity_id)
		result[cell] = ids
	return result

static func _index_objects(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var entity_id: String = str(object_data.get("id", "")).strip_edges()
		if not entity_id.is_empty():
			result[entity_id] = object_data
	return result

static func _append_unique_string(target: Dictionary, key: String, value: String) -> void:
	var values: Array[String] = _string_array(target.get(key, []))
	if not values.has(value):
		values.append(value)
		values.sort()
	target[key] = values

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text: String = str(item)
			if not text.is_empty() and not result.has(text):
				result.append(text)
	result.sort()
	return result

static func _object_type(object_data: Dictionary) -> String:
	return str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _normalize_mode(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_").trim_suffix("_power").trim_suffix("_control")

static func _cell(object_data: Dictionary) -> Vector2i:
	var value: Variant = object_data.get("anchor_floor_cell", object_data.get("position", Vector2i(-1, -1)))
	if value is Vector2i or value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	return Vector2i(-1, -1)

static func _valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0

static func _direction_delta(direction: String) -> Vector2i:
	match direction.strip_edges().to_lower():
		"north", "up":
			return Vector2i.UP
		"east", "right":
			return Vector2i.RIGHT
		"south", "down":
			return Vector2i.DOWN
		"west", "left":
			return Vector2i.LEFT
	return Vector2i.ZERO
