extends RefCounted
class_name PowerCableReelService

const FORMAT_VERSION: int = 1
const CIRCUIT_MAIN := "main"

const END_1 := "end_1"
const END_2 := "end_2"
const END_NAMES: Array[String] = [END_1, END_2]
const END_ON_REEL := "on_reel"
const END_HELD := "held"
const END_CONNECTED := "connected"
const END_STATES: Array[String] = [END_ON_REEL, END_HELD, END_CONNECTED]

const CONNECTION_DISCONNECTED := "disconnected"
const CONNECTION_PARTIAL := "partial"
const CONNECTION_COMPLETE := "complete"
const CONNECTION_INVALID := "invalid"
const CONNECTION_BROKEN := "broken"

const ACTION_HOLD_END := "hold_end"
const ACTION_RELEASE_END := "release_end"
const ACTION_CONNECT_END := "connect_end"
const ACTION_DISCONNECT_END := "disconnect_end"
const ACTION_SET_PATH := "set_path"
const ACTION_DAMAGE := "damage"
const ACTION_REPAIR := "repair"
const ACTION_RECONNECT := "reconnect"
const ACTIONS: Array[String] = [
	ACTION_HOLD_END,
	ACTION_RELEASE_END,
	ACTION_CONNECT_END,
	ACTION_DISCONNECT_END,
	ACTION_SET_PATH,
	ACTION_DAMAGE,
	ACTION_REPAIR,
	ACTION_RECONNECT
]

const CODE_VALID := "valid"
const CODE_REEL_MISSING := "reel_missing"
const CODE_WRONG_REEL_TYPE := "wrong_reel_type"
const CODE_END_INVALID := "end_invalid"
const CODE_END_NOT_HELD := "end_not_held"
const CODE_END_NOT_CONNECTED := "end_not_connected"
const CODE_ENDPOINT_MISSING := "endpoint_missing"
const CODE_ENDPOINT_OCCUPIED := "endpoint_occupied"
const CODE_SOCKET_MISSING := "socket_missing"
const CODE_SOCKET_WRONG_TYPE := "socket_wrong_type"
const CODE_TARGET_MISSING := "target_missing"
const CODE_TARGET_INCOMPATIBLE := "target_incompatible"
const CODE_SOCKET_UNPOWERED := "socket_unpowered"
const CODE_SOCKET_SOURCE_MISSING := "socket_source_missing"
const CODE_PATH_EMPTY := "path_empty"
const CODE_PATH_INVALID := "path_invalid"
const CODE_PATH_BLOCKED := "path_blocked"
const CODE_PATH_TOO_LONG := "path_too_long"
const CODE_REEL_BROKEN := "reel_broken"
const CODE_RECONNECT_REQUIRED := "reconnect_required"
const CODE_PARTIAL := "partial"
const CODE_COMPLETE := "complete"
const CODE_DISCONNECTED := "disconnected"
const CODE_ACTION_INVALID := "action_invalid"

const RESULT_CODES: Array[String] = [
	CODE_VALID,
	CODE_REEL_MISSING,
	CODE_WRONG_REEL_TYPE,
	CODE_END_INVALID,
	CODE_END_NOT_HELD,
	CODE_END_NOT_CONNECTED,
	CODE_ENDPOINT_MISSING,
	CODE_ENDPOINT_OCCUPIED,
	CODE_SOCKET_MISSING,
	CODE_SOCKET_WRONG_TYPE,
	CODE_TARGET_MISSING,
	CODE_TARGET_INCOMPATIBLE,
	CODE_SOCKET_UNPOWERED,
	CODE_SOCKET_SOURCE_MISSING,
	CODE_PATH_EMPTY,
	CODE_PATH_INVALID,
	CODE_PATH_BLOCKED,
	CODE_PATH_TOO_LONG,
	CODE_REEL_BROKEN,
	CODE_RECONNECT_REQUIRED,
	CODE_PARTIAL,
	CODE_COMPLETE,
	CODE_DISCONNECTED,
	CODE_ACTION_INVALID
]

static func canonicalize_reel(reel: Dictionary) -> Dictionary:
	var result: Dictionary = reel.duplicate(true)
	result["format_version"] = FORMAT_VERSION
	result["runtime_power_profile"] = "power_cable_reel"
	result[END_1] = _canonical_endpoint(
		result.get(END_1, {}),
		result.get("end_1_state", END_ON_REEL),
		result.get("end_1_target_id", "")
	)
	result[END_2] = _canonical_endpoint(
		result.get(END_2, {}),
		result.get("end_2_state", END_ON_REEL),
		result.get("end_2_target_id", "")
	)
	var raw_path: Variant = result.get("path_cells", result.get("cable_path_cells", []))
	result["path_cells"] = _to_cells(raw_path)
	result["connection_state"] = str(result.get("connection_state", CONNECTION_DISCONNECTED)).strip_edges().to_lower()
	if str(result.get("connection_state", "")) not in [CONNECTION_DISCONNECTED, CONNECTION_PARTIAL, CONNECTION_COMPLETE, CONNECTION_INVALID, CONNECTION_BROKEN]:
		result["connection_state"] = CONNECTION_INVALID
	result["reconnect_required"] = bool(result.get("reconnect_required", false))
	_sync_legacy_aliases(result)
	return result

static func make_default_reel(reel_id: String, max_length: int = 0) -> Dictionary:
	return canonicalize_reel({
		"id": reel_id,
		"object_group": "item",
		"object_type": "power_cable_reel",
		"state": CONNECTION_DISCONNECTED,
		"health_state": "healthy",
		"broken": false,
		"cut": false,
		"max_cable_length": maxi(0, max_length),
		END_1: {"state": END_ON_REEL, "target_id": ""},
		END_2: {"state": END_ON_REEL, "target_id": ""},
		"path_cells": [],
		"connection_state": CONNECTION_DISCONNECTED
	})

static func preview_action(objects: Array[Dictionary], reel_id: String, action: String, parameters: Dictionary = {}, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var object_by_id: Dictionary = _index_objects(objects)
	if not object_by_id.has(reel_id):
		return _result(false, CODE_REEL_MISSING, {"id": reel_id}, {"preview": true})
	var reel: Dictionary = canonicalize_reel(Dictionary(object_by_id[reel_id]))
	if not _is_reel(reel):
		return _result(false, CODE_WRONG_REEL_TYPE, reel, {"preview": true})
	var normalized_action: String = action.strip_edges().to_lower()
	if normalized_action not in ACTIONS:
		return _result(false, CODE_ACTION_INVALID, reel, {"preview": true, "action": normalized_action})
	var mutation: Dictionary = _preview_mutation(reel, normalized_action, parameters, objects, object_by_id, blocked_cells)
	if not bool(mutation.get("success", false)):
		mutation["preview"] = true
		return mutation
	var next_reel: Dictionary = canonicalize_reel(Dictionary(mutation.get("next_reel", reel)))
	var next_index: Dictionary = object_by_id.duplicate()
	next_index[reel_id] = next_reel
	var resolution: Dictionary = resolve_connection(next_reel, next_index, blocked_cells)
	var result: Dictionary = resolution.duplicate(true)
	result["success"] = true
	result["ok"] = true
	result["preview"] = true
	result["action"] = normalized_action
	result["next_reel"] = next_reel.duplicate(true)
	result["action_details"] = Dictionary(mutation.get("details", {})).duplicate(true)
	return result

static func apply_action_to_world(objects: Array[Dictionary], reel_id: String, action: String, parameters: Dictionary = {}, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var preview: Dictionary = preview_action(objects, reel_id, action, parameters, blocked_cells)
	if not bool(preview.get("success", false)):
		preview["preview"] = false
		return preview
	var reel_index: int = _find_object_index(objects, reel_id)
	if reel_index < 0:
		return _result(false, CODE_REEL_MISSING, {"id": reel_id}, {"preview": false})
	objects[reel_index] = Dictionary(preview.get("next_reel", {})).duplicate(true)
	var recalculation: Dictionary = recalculate_world(objects, reel_id, blocked_cells)
	var resolution_success: bool = bool(recalculation.get("success", false))
	var resolution_code: String = str(recalculation.get("code", ""))
	recalculation["preview"] = false
	recalculation["action"] = action.strip_edges().to_lower()
	recalculation["action_code"] = str(preview.get("code", ""))
	recalculation["resolution_success"] = resolution_success
	recalculation["resolution_code"] = resolution_code
	recalculation["success"] = true
	recalculation["ok"] = true
	recalculation["code"] = str(preview.get("code", CODE_VALID))
	recalculation["reason_code"] = str(preview.get("reason_code", recalculation.get("code", CODE_VALID)))
	return recalculation

static func resolve_connection(reel: Dictionary, object_by_id: Dictionary, blocked_cells: Array[Vector2i] = [], ignore_reconnect_required: bool = false) -> Dictionary:
	var canonical: Dictionary = canonicalize_reel(reel)
	if not _is_reel(canonical):
		return _result(false, CODE_WRONG_REEL_TYPE, canonical)
	if _is_reel_broken(canonical):
		return _connection_result(false, CODE_REEL_BROKEN, canonical, CONNECTION_BROKEN, {})
	var connected_ends: Array[String] = []
	for end_name in END_NAMES:
		var endpoint: Dictionary = Dictionary(canonical.get(end_name, {}))
		if str(endpoint.get("state", END_ON_REEL)) == END_CONNECTED:
			connected_ends.append(end_name)
	if connected_ends.is_empty():
		return _connection_result(true, CODE_DISCONNECTED, canonical, CONNECTION_DISCONNECTED, {})
	if connected_ends.size() == 1:
		var only_end: String = connected_ends[0]
		var only_endpoint: Dictionary = Dictionary(canonical.get(only_end, {}))
		var only_target_id: String = str(only_endpoint.get("target_id", "")).strip_edges()
		if only_target_id.is_empty() or not object_by_id.has(only_target_id):
			return _connection_result(false, CODE_ENDPOINT_MISSING, canonical, CONNECTION_INVALID, {"end": only_end, "target_id": only_target_id})
		return _connection_result(true, CODE_PARTIAL, canonical, CONNECTION_PARTIAL, {"connected_end": only_end})
	if bool(canonical.get("reconnect_required", false)) and not ignore_reconnect_required:
		var reconnect_endpoints: Dictionary = _classify_connected_endpoints(canonical, object_by_id)
		return _connection_result(true, CODE_RECONNECT_REQUIRED, canonical, CONNECTION_INVALID, reconnect_endpoints)
	var endpoints: Dictionary = _classify_connected_endpoints(canonical, object_by_id)
	if not bool(endpoints.get("success", false)):
		return _connection_result(false, str(endpoints.get("code", CODE_ENDPOINT_MISSING)), canonical, CONNECTION_INVALID, endpoints)
	var socket_id: String = str(endpoints.get("socket_id", ""))
	var target_id: String = str(endpoints.get("target_id", ""))
	var socket: Dictionary = Dictionary(object_by_id.get(socket_id, {}))
	var target: Dictionary = Dictionary(object_by_id.get(target_id, {}))
	var path_result: Dictionary = _validate_complete_path(canonical, socket, target, blocked_cells)
	if not bool(path_result.get("success", false)):
		var path_details: Dictionary = endpoints.duplicate(true)
		path_details.merge(Dictionary(path_result.get("details", {})), true)
		return _connection_result(false, str(path_result.get("code", CODE_PATH_INVALID)), canonical, CONNECTION_INVALID, path_details)
	var resolved_source_id: String = str(socket.get("resolved_source_id", "")).strip_edges()
	var details: Dictionary = endpoints.duplicate(true)
	details["resolved_source_id"] = resolved_source_id
	details["resolved_circuit_id"] = CIRCUIT_MAIN
	if str(socket.get("power_state", "")).strip_edges().to_lower() != "powered":
		return _connection_result(true, CODE_SOCKET_UNPOWERED, canonical, CONNECTION_COMPLETE, details, false)
	if resolved_source_id.is_empty():
		return _connection_result(false, CODE_SOCKET_SOURCE_MISSING, canonical, CONNECTION_COMPLETE, details, false)
	return _connection_result(true, CODE_COMPLETE, canonical, CONNECTION_COMPLETE, details, true)

static func recalculate_world(objects: Array[Dictionary], reel_id: String, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var object_by_id: Dictionary = _index_objects(objects)
	if not object_by_id.has(reel_id):
		return _result(false, CODE_REEL_MISSING, {"id": reel_id})
	var reel: Dictionary = canonicalize_reel(Dictionary(object_by_id[reel_id]))
	var resolution: Dictionary = resolve_connection(reel, object_by_id, blocked_cells)
	reel["connection_state"] = str(resolution.get("connection_state", CONNECTION_INVALID))
	_sync_legacy_aliases(reel)
	var reel_index: int = _find_object_index(objects, reel_id)
	if reel_index >= 0:
		objects[reel_index] = reel
	object_by_id[reel_id] = reel
	var target_id: String = str(resolution.get("target_id", ""))
	var physically_complete: bool = str(resolution.get("connection_state", "")) == CONNECTION_COMPLETE
	var affected_target_ids: Dictionary = {}
	if not target_id.is_empty():
		affected_target_ids[target_id] = true
	for object_data in objects:
		if str(object_data.get("runtime_reel_feed_id", "")) == reel_id:
			affected_target_ids[str(object_data.get("id", ""))] = true
	var changes: Array[Dictionary] = []
	var affected_ids: Array[String] = [reel_id]
	var sorted_target_ids: Array = affected_target_ids.keys()
	sorted_target_ids.sort()
	for target_id_value in sorted_target_ids:
		var candidate_target_id: String = str(target_id_value)
		var target_index: int = _find_object_index(objects, candidate_target_id)
		if target_index < 0:
			continue
		var target: Dictionary = Dictionary(objects[target_index]).duplicate(true)
		var before: Dictionary = _target_runtime_snapshot(target)
		if candidate_target_id == target_id and physically_complete:
			_apply_target_feed(target, reel_id, resolution)
		else:
			_clear_target_feed(target, reel_id, str(resolution.get("code", CODE_DISCONNECTED)))
		objects[target_index] = target
		var after: Dictionary = _target_runtime_snapshot(target)
		if before != after:
			changes.append({"object_id": candidate_target_id, "before": before, "after": after})
		if not affected_ids.has(candidate_target_id):
			affected_ids.append(candidate_target_id)
	var result: Dictionary = resolution.duplicate(true)
	result["reel"] = reel.duplicate(true)
	result["changes"] = changes
	result["affected_ids"] = affected_ids
	result["notification_event"] = {}
	return result

static func recalculate_for_socket(objects: Array[Dictionary], socket_id: String, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var reel_ids: Array[String] = []
	for object_data in objects:
		if not _is_reel(object_data):
			continue
		var reel: Dictionary = canonicalize_reel(object_data)
		for end_name in END_NAMES:
			var endpoint: Dictionary = Dictionary(reel.get(end_name, {}))
			if str(endpoint.get("state", "")) == END_CONNECTED and str(endpoint.get("target_id", "")) == socket_id:
				reel_ids.append(str(reel.get("id", "")))
				break
	reel_ids.sort()
	var results: Array[Dictionary] = []
	var affected_ids: Array[String] = []
	var changes: Array[Dictionary] = []
	for reel_id in reel_ids:
		var reel_result: Dictionary = recalculate_world(objects, reel_id, blocked_cells)
		results.append(reel_result)
		for affected_id_value in Array(reel_result.get("affected_ids", [])):
			var affected_id: String = str(affected_id_value)
			if not affected_ids.has(affected_id):
				affected_ids.append(affected_id)
		changes.append_array(Array(reel_result.get("changes", [])))
	return {
		"ok": true,
		"success": true,
		"code": CODE_VALID,
		"reason_code": CODE_VALID,
		"socket_id": socket_id,
		"reel_ids": reel_ids,
		"results": results,
		"changes": changes,
		"affected_ids": affected_ids,
		"notification_event": {}
	}

static func _preview_mutation(reel: Dictionary, action: String, parameters: Dictionary, objects: Array[Dictionary], object_by_id: Dictionary, blocked_cells: Array[Vector2i]) -> Dictionary:
	var next_reel: Dictionary = reel.duplicate(true)
	var end_name: String = str(parameters.get("end", parameters.get("end_name", ""))).strip_edges().to_lower()
	if action in [ACTION_HOLD_END, ACTION_RELEASE_END, ACTION_CONNECT_END, ACTION_DISCONNECT_END] and end_name not in END_NAMES:
		return _result(false, CODE_END_INVALID, reel, {"end": end_name, "action": action})
	if action == ACTION_HOLD_END:
		var hold_endpoint: Dictionary = Dictionary(next_reel.get(end_name, {})).duplicate(true)
		if str(hold_endpoint.get("state", END_ON_REEL)) == END_CONNECTED:
			return _result(false, CODE_ENDPOINT_OCCUPIED, reel, {"end": end_name})
		hold_endpoint["state"] = END_HELD
		hold_endpoint["target_id"] = ""
		next_reel[end_name] = hold_endpoint
	elif action == ACTION_RELEASE_END:
		var release_endpoint: Dictionary = Dictionary(next_reel.get(end_name, {})).duplicate(true)
		if str(release_endpoint.get("state", END_ON_REEL)) != END_HELD:
			return _result(false, CODE_END_NOT_HELD, reel, {"end": end_name})
		release_endpoint["state"] = END_ON_REEL
		release_endpoint["target_id"] = ""
		next_reel[end_name] = release_endpoint
	elif action == ACTION_CONNECT_END:
		var connect_endpoint: Dictionary = Dictionary(next_reel.get(end_name, {})).duplicate(true)
		if str(connect_endpoint.get("state", END_ON_REEL)) != END_HELD:
			return _result(false, CODE_END_NOT_HELD, reel, {"end": end_name})
		var target_id: String = str(parameters.get("target_id", "")).strip_edges()
		if target_id.is_empty() or not object_by_id.has(target_id):
			return _result(false, CODE_ENDPOINT_MISSING, reel, {"end": end_name, "target_id": target_id})
		var target: Dictionary = Dictionary(object_by_id[target_id])
		if not _is_socket(target) and not _target_accepts_feed(target):
			return _result(false, CODE_TARGET_INCOMPATIBLE, reel, {"end": end_name, "target_id": target_id})
		var occupied: Dictionary = _find_endpoint_occupant(objects, target_id, str(reel.get("id", "")), end_name)
		if not occupied.is_empty():
			return _result(false, CODE_ENDPOINT_OCCUPIED, reel, {"end": end_name, "target_id": target_id, "occupied_by": occupied})
		connect_endpoint["state"] = END_CONNECTED
		connect_endpoint["target_id"] = target_id
		next_reel[end_name] = connect_endpoint
		next_reel["reconnect_required"] = false
	elif action == ACTION_DISCONNECT_END:
		var disconnect_endpoint: Dictionary = Dictionary(next_reel.get(end_name, {})).duplicate(true)
		if str(disconnect_endpoint.get("state", END_ON_REEL)) != END_CONNECTED:
			return _result(false, CODE_END_NOT_CONNECTED, reel, {"end": end_name})
		disconnect_endpoint["state"] = END_HELD
		disconnect_endpoint["target_id"] = ""
		next_reel[end_name] = disconnect_endpoint
		next_reel["reconnect_required"] = false
	elif action == ACTION_SET_PATH:
		var path_cells: Array[Vector2i] = _to_cells(parameters.get("path_cells", []))
		var shape_result: Dictionary = _validate_path_shape(path_cells, int(next_reel.get("max_cable_length", next_reel.get("max_length", 0))), blocked_cells)
		if not bool(shape_result.get("success", false)):
			return _result(false, str(shape_result.get("code", CODE_PATH_INVALID)), reel, Dictionary(shape_result.get("details", {})))
		next_reel["path_cells"] = path_cells
	elif action == ACTION_DAMAGE:
		if _is_reel_broken(next_reel):
			return _result(false, CODE_REEL_BROKEN, reel)
		next_reel["health_state"] = "broken"
		next_reel["broken"] = true
		next_reel["reconnect_required"] = true
	elif action == ACTION_REPAIR:
		if not _is_reel_broken(next_reel):
			return _result(false, CODE_ACTION_INVALID, reel, {"reason": "reel_not_broken"})
		next_reel["health_state"] = "healthy"
		next_reel["broken"] = false
		next_reel["cut"] = false
		next_reel["damaged"] = false
		next_reel["reconnect_required"] = _both_ends_connected(next_reel)
	elif action == ACTION_RECONNECT:
		if _is_reel_broken(next_reel):
			return _result(false, CODE_REEL_BROKEN, reel)
		if not bool(next_reel.get("reconnect_required", false)):
			return _result(false, CODE_ACTION_INVALID, reel, {"reason": "reconnect_not_required"})
		var reconnect_index: Dictionary = object_by_id.duplicate()
		reconnect_index[str(next_reel.get("id", ""))] = next_reel
		var reconnect_resolution: Dictionary = resolve_connection(next_reel, reconnect_index, blocked_cells, true)
		if str(reconnect_resolution.get("connection_state", "")) != CONNECTION_COMPLETE:
			return _result(false, str(reconnect_resolution.get("code", CODE_PATH_INVALID)), reel, Dictionary(reconnect_resolution.get("details", {})))
		next_reel["reconnect_required"] = false
	_sync_legacy_aliases(next_reel)
	return {
		"ok": true,
		"success": true,
		"code": CODE_VALID,
		"reason_code": CODE_VALID,
		"reel_id": str(reel.get("id", "")),
		"next_reel": next_reel,
		"details": {"action": action, "end": end_name}
	}

static func _classify_connected_endpoints(reel: Dictionary, object_by_id: Dictionary) -> Dictionary:
	var socket_end: String = ""
	var socket_id: String = ""
	var target_end: String = ""
	var target_id: String = ""
	for end_name in END_NAMES:
		var endpoint: Dictionary = Dictionary(reel.get(end_name, {}))
		if str(endpoint.get("state", "")) != END_CONNECTED:
			continue
		var endpoint_target_id: String = str(endpoint.get("target_id", "")).strip_edges()
		if endpoint_target_id.is_empty() or not object_by_id.has(endpoint_target_id):
			return {"success": false, "code": CODE_ENDPOINT_MISSING, "end": end_name, "endpoint_target_id": endpoint_target_id}
		var endpoint_target: Dictionary = Dictionary(object_by_id[endpoint_target_id])
		if _is_socket(endpoint_target):
			if not socket_id.is_empty():
				return {"success": false, "code": CODE_SOCKET_WRONG_TYPE, "reason": "multiple_socket_ends"}
			socket_end = end_name
			socket_id = endpoint_target_id
		elif _target_accepts_feed(endpoint_target):
			if not target_id.is_empty():
				return {"success": false, "code": CODE_TARGET_INCOMPATIBLE, "reason": "multiple_target_ends"}
			target_end = end_name
			target_id = endpoint_target_id
		else:
			return {"success": false, "code": CODE_TARGET_INCOMPATIBLE, "end": end_name, "endpoint_target_id": endpoint_target_id}
	if socket_id.is_empty():
		return {"success": false, "code": CODE_SOCKET_MISSING}
	if target_id.is_empty():
		return {"success": false, "code": CODE_TARGET_MISSING}
	return {
		"success": true,
		"socket_end": socket_end,
		"socket_id": socket_id,
		"target_end": target_end,
		"target_id": target_id
	}

static func _validate_complete_path(reel: Dictionary, socket: Dictionary, target: Dictionary, blocked_cells: Array[Vector2i]) -> Dictionary:
	var path_cells: Array[Vector2i] = _to_cells(reel.get("path_cells", []))
	var max_length: int = int(reel.get("max_cable_length", reel.get("max_length", 0)))
	var shape_result: Dictionary = _validate_path_shape(path_cells, max_length, blocked_cells)
	if not bool(shape_result.get("success", false)):
		return shape_result
	var socket_cell: Vector2i = _entity_cell(socket)
	var target_cell: Vector2i = _entity_cell(target)
	var start_cell: Vector2i = path_cells[0]
	var end_cell: Vector2i = path_cells[path_cells.size() - 1]
	var direct_order: bool = start_cell == socket_cell and end_cell == target_cell
	var reverse_order: bool = start_cell == target_cell and end_cell == socket_cell
	if not direct_order and not reverse_order:
		return {"success": false, "code": CODE_PATH_INVALID, "details": {"reason": "path_endpoints_mismatch", "socket_cell": socket_cell, "target_cell": target_cell}}
	return {"success": true, "code": CODE_VALID, "details": {"path_length": maxi(0, path_cells.size() - 1)}}

static func _validate_path_shape(path_cells: Array[Vector2i], max_length: int, blocked_cells: Array[Vector2i]) -> Dictionary:
	if path_cells.is_empty():
		return {"success": false, "code": CODE_PATH_EMPTY, "details": {}}
	if path_cells.size() < 2:
		return {"success": false, "code": CODE_PATH_INVALID, "details": {"reason": "path_too_short"}}
	var segment_count: int = path_cells.size() - 1
	if max_length > 0 and segment_count > max_length:
		return {"success": false, "code": CODE_PATH_TOO_LONG, "details": {"max_length": max_length, "path_length": segment_count}}
	var seen: Dictionary = {}
	for index in range(path_cells.size()):
		var cell: Vector2i = path_cells[index]
		if seen.has(cell):
			return {"success": false, "code": CODE_PATH_INVALID, "details": {"reason": "path_repeats_cell", "cell": cell}}
		seen[cell] = true
		if index > 0 and not _adjacent(path_cells[index - 1], cell):
			return {"success": false, "code": CODE_PATH_INVALID, "details": {"reason": "path_not_contiguous", "from": path_cells[index - 1], "to": cell}}
		if index > 0 and index < path_cells.size() - 1 and blocked_cells.has(cell):
			return {"success": false, "code": CODE_PATH_BLOCKED, "details": {"cell": cell}}
	return {"success": true, "code": CODE_VALID, "details": {"path_length": segment_count}}

static func _apply_target_feed(target: Dictionary, reel_id: String, resolution: Dictionary) -> void:
	var powered: bool = bool(resolution.get("powered", false))
	target["runtime_reel_feed_id"] = reel_id
	target["runtime_reel_socket_id"] = str(resolution.get("socket_id", ""))
	target["runtime_reel_connection_state"] = str(resolution.get("connection_state", CONNECTION_INVALID))
	target["runtime_reel_feed_active"] = powered
	target["resolved_source_id"] = str(resolution.get("resolved_source_id", ""))
	target["resolved_circuit_id"] = CIRCUIT_MAIN
	target["is_powered"] = powered
	target["power_received"] = 1 if powered else 0
	target["power_state"] = "powered" if powered else "unpowered"
	target["power_unavailable_reason"] = "" if powered else str(resolution.get("code", CODE_SOCKET_UNPOWERED))

static func _clear_target_feed(target: Dictionary, reel_id: String, reason_code: String) -> void:
	if str(target.get("runtime_reel_feed_id", "")) != reel_id:
		return
	target["runtime_reel_feed_active"] = false
	target["runtime_reel_connection_state"] = CONNECTION_INVALID
	target["resolved_source_id"] = ""
	target["resolved_circuit_id"] = ""
	target["is_powered"] = false
	target["power_received"] = 0
	target["power_state"] = "unpowered"
	target["power_unavailable_reason"] = reason_code
	target.erase("runtime_reel_feed_id")
	target.erase("runtime_reel_socket_id")

static func _target_runtime_snapshot(target: Dictionary) -> Dictionary:
	return {
		"runtime_reel_feed_id": str(target.get("runtime_reel_feed_id", "")),
		"runtime_reel_socket_id": str(target.get("runtime_reel_socket_id", "")),
		"runtime_reel_connection_state": str(target.get("runtime_reel_connection_state", "")),
		"runtime_reel_feed_active": bool(target.get("runtime_reel_feed_active", false)),
		"resolved_source_id": str(target.get("resolved_source_id", "")),
		"resolved_circuit_id": str(target.get("resolved_circuit_id", "")),
		"is_powered": bool(target.get("is_powered", false)),
		"power_received": int(target.get("power_received", 0)),
		"power_state": str(target.get("power_state", "")),
		"power_unavailable_reason": str(target.get("power_unavailable_reason", "")),
		"intent_state": target.get("intent_state", null),
		"operational_state": target.get("operational_state", null),
		"preferred_source_id": target.get("preferred_source_id", null)
	}

static func _connection_result(success: bool, code: String, reel: Dictionary, connection_state: String, details: Dictionary, powered: bool = false) -> Dictionary:
	var result: Dictionary = _result(success, code, reel, details)
	result["connection_state"] = connection_state
	result["powered"] = powered
	result["socket_end"] = str(details.get("socket_end", ""))
	result["socket_id"] = str(details.get("socket_id", ""))
	result["target_end"] = str(details.get("target_end", ""))
	result["target_id"] = str(details.get("target_id", ""))
	result["resolved_source_id"] = str(details.get("resolved_source_id", ""))
	result["resolved_circuit_id"] = str(details.get("resolved_circuit_id", ""))
	return result

static func _result(success: bool, code: String, reel: Dictionary, details: Dictionary = {}) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"reel_id": str(reel.get("id", "")),
		"connection_state": str(reel.get("connection_state", CONNECTION_INVALID)),
		"socket_end": "",
		"socket_id": "",
		"target_end": "",
		"target_id": "",
		"resolved_source_id": "",
		"resolved_circuit_id": "",
		"powered": false,
		"details": details.duplicate(true),
		"notification_event": {}
	}

static func _canonical_endpoint(value: Variant, legacy_state: Variant, legacy_target_id: Variant) -> Dictionary:
	var endpoint: Dictionary = {}
	if value is Dictionary:
		endpoint = Dictionary(value).duplicate(true)
	var state: String = str(endpoint.get("state", legacy_state)).strip_edges().to_lower()
	if state not in END_STATES:
		state = END_ON_REEL
	var target_id: String = str(endpoint.get("target_id", legacy_target_id)).strip_edges()
	if state != END_CONNECTED:
		target_id = ""
	return {"state": state, "target_id": target_id}

static func _sync_legacy_aliases(reel: Dictionary) -> void:
	var end_1: Dictionary = Dictionary(reel.get(END_1, {}))
	var end_2: Dictionary = Dictionary(reel.get(END_2, {}))
	reel["end_1_state"] = str(end_1.get("state", END_ON_REEL))
	reel["end_1_target_id"] = str(end_1.get("target_id", ""))
	reel["end_2_state"] = str(end_2.get("state", END_ON_REEL))
	reel["end_2_target_id"] = str(end_2.get("target_id", ""))
	reel["cable_path_cells"] = Array(reel.get("path_cells", [])).duplicate()
	reel["cable_length"] = maxi(0, Array(reel.get("path_cells", [])).size() - 1)
	reel["connected_side_1"] = str(end_1.get("state", "")) == END_CONNECTED
	reel["connected_side_2"] = str(end_2.get("state", "")) == END_CONNECTED
	reel["is_connected"] = _both_ends_connected(reel)
	reel["connected"] = bool(reel.get("is_connected", false))
	reel["disconnected"] = not bool(reel.get("is_connected", false))

static func _find_endpoint_occupant(objects: Array[Dictionary], target_id: String, excluding_reel_id: String, excluding_end: String) -> Dictionary:
	for object_data in objects:
		if not _is_reel(object_data):
			continue
		var reel: Dictionary = canonicalize_reel(object_data)
		var reel_id: String = str(reel.get("id", ""))
		for end_name in END_NAMES:
			if reel_id == excluding_reel_id and end_name == excluding_end:
				continue
			var endpoint: Dictionary = Dictionary(reel.get(end_name, {}))
			if str(endpoint.get("state", "")) == END_CONNECTED and str(endpoint.get("target_id", "")) == target_id:
				return {"reel_id": reel_id, "end": end_name}
	return {}

static func _index_objects(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if not object_id.is_empty():
			result[object_id] = object_data
	return result

static func _find_object_index(objects: Array[Dictionary], object_id: String) -> int:
	for index in range(objects.size()):
		if str(objects[index].get("id", "")) == object_id:
			return index
	return -1

static func _is_reel(object_data: Dictionary) -> bool:
	return _object_type(object_data) == "power_cable_reel" or str(object_data.get("runtime_power_profile", "")) == "power_cable_reel"

static func _is_socket(object_data: Dictionary) -> bool:
	if _object_type(object_data) == "power_socket":
		return true
	return str(object_data.get("generic_power_role", object_data.get("socket_role", ""))).strip_edges().to_lower() in ["socket_input", "socket_output"]

static func _target_accepts_feed(object_data: Dictionary) -> bool:
	if bool(object_data.get("runtime_reel_feed", false)) or bool(object_data.get("accepts_runtime_power_reel", false)):
		return true
	var profiles: Variant = object_data.get("power_input_profiles", [])
	if profiles is Array and Array(profiles).has("runtime_reel_feed"):
		return true
	return str(object_data.get("power_input_profile", "")).strip_edges().to_lower() == "runtime_reel_feed"

static func _is_reel_broken(reel: Dictionary) -> bool:
	var health_state: String = str(reel.get("health_state", reel.get("cable_health_state", ""))).strip_edges().to_lower()
	return health_state in ["broken", "cut"] or bool(reel.get("broken", false)) or bool(reel.get("cut", false))

static func _both_ends_connected(reel: Dictionary) -> bool:
	for end_name in END_NAMES:
		if str(Dictionary(reel.get(end_name, {})).get("state", "")) != END_CONNECTED:
			return false
	return true

static func _object_type(object_data: Dictionary) -> String:
	return str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))).strip_edges().to_lower()

static func _entity_cell(object_data: Dictionary) -> Vector2i:
	return _to_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))

static func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1

static func _to_cell(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var value_dictionary: Dictionary = Dictionary(value)
		return Vector2i(int(value_dictionary.get("x", fallback.x)), int(value_dictionary.get("y", fallback.y)))
	return fallback

static func _to_cells(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not (value is Array):
		return result
	for cell_value in Array(value):
		result.append(_to_cell(cell_value, Vector2i.ZERO))
	return result
