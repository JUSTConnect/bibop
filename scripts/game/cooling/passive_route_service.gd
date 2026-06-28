extends RefCounted
class_name PassiveRouteService

const FORMAT_VERSION: int = 1

const KIND_AIR_DUCT := "air_duct"
const KIND_WATER_PIPE := "water_pipe"
const ROUTING_KINDS: Array[String] = [KIND_AIR_DUCT, KIND_WATER_PIPE]

const MOUNT_INNER := "inner"
const MOUNT_OUTER := "outer"
const MOUNT_SIDES: Array[String] = [MOUNT_INNER, MOUNT_OUTER]

const SIDE_NE := "NE"
const SIDE_SE := "SE"
const SIDE_SW := "SW"
const SIDE_NW := "NW"
const ROUTE_SIDES: Array[String] = [SIDE_NE, SIDE_SE, SIDE_SW, SIDE_NW]
const SIDE_ORDER: Dictionary = {SIDE_NE: 0, SIDE_SE: 1, SIDE_SW: 2, SIDE_NW: 3}
const OPPOSITE_SIDE: Dictionary = {SIDE_NE: SIDE_SW, SIDE_SW: SIDE_NE, SIDE_SE: SIDE_NW, SIDE_NW: SIDE_SE}
const SIDE_DELTA: Dictionary = {
	SIDE_NE: Vector2i(0, -1),
	SIDE_SE: Vector2i(1, 0),
	SIDE_SW: Vector2i(0, 1),
	SIDE_NW: Vector2i(-1, 0)
}

const SHAPE_STRAIGHT := "straight"
const SHAPE_TURN := "turn"

const CODE_VALID := "valid"
const CODE_NOT_PASSIVE_ROUTE := "not_passive_route"
const CODE_INVALID_KIND := "invalid_routing_kind"
const CODE_INVALID_MOUNT_SIDE := "invalid_mount_side"
const CODE_ROUTE_PAIR_MISSING := "route_pair_missing"
const CODE_ROUTE_PAIR_COUNT_INVALID := "route_pair_count_invalid"
const CODE_ROUTE_SIDE_INVALID := "route_side_invalid"
const CODE_ROUTE_SIDE_DUPLICATE := "route_side_duplicate"
const CODE_DISCONNECTED := "disconnected"
const CODE_NEIGHBOR_KIND_INCOMPATIBLE := "neighbor_kind_incompatible"
const CODE_NEIGHBOR_MOUNT_INCOMPATIBLE := "neighbor_mount_incompatible"
const CODE_NEIGHBOR_PORT_MISMATCH := "neighbor_port_mismatch"

const ISSUE_CODES: Array[String] = [
	CODE_VALID,
	CODE_NOT_PASSIVE_ROUTE,
	CODE_INVALID_KIND,
	CODE_INVALID_MOUNT_SIDE,
	CODE_ROUTE_PAIR_MISSING,
	CODE_ROUTE_PAIR_COUNT_INVALID,
	CODE_ROUTE_SIDE_INVALID,
	CODE_ROUTE_SIDE_DUPLICATE,
	CODE_DISCONNECTED,
	CODE_NEIGHBOR_KIND_INCOMPATIBLE,
	CODE_NEIGHBOR_MOUNT_INCOMPATIBLE,
	CODE_NEIGHBOR_PORT_MISMATCH
]

const FORBIDDEN_STORED_FIELDS: Array[String] = [
	"state",
	"intent_state",
	"operational_state",
	"health_state",
	"durability",
	"damaged",
	"broken",
	"destroyed",
	"is_powered",
	"power_state",
	"power_mode",
	"control_mode",
	"access_mode",
	"flow_state",
	"blocked_state",
	"blocked",
	"blocks_airflow",
	"fan_enabled",
	"cooling_contour_id",
	"cooling_contour_mode",
	"cooling_contour_member_ids",
	"contour_id",
	"member_ids",
	"connected_device_ids",
	"connection_ids",
	"neighbors",
	"runtime_test_override",
	"test_override"
]

static func is_passive_route(object_data: Dictionary) -> bool:
	return not get_routing_kind(object_data).is_empty()

static func get_routing_kind(object_data: Dictionary) -> String:
	var kind: String = str(object_data.get("routing_kind", object_data.get("cooling_system_type", ""))).strip_edges().to_lower()
	if kind in ROUTING_KINDS:
		return kind
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	if object_type in ["external_air_duct", "air_duct"]:
		return KIND_AIR_DUCT
	if object_type in ["external_water_pipe", "water_pipe"]:
		return KIND_WATER_PIPE
	return ""

static func normalize_mount_side(value: Variant) -> String:
	var token: String = str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if token in ["inner", "inside", "internal", "in_wall", "embedded"]:
		return MOUNT_INNER
	if token in ["outer", "outside", "external", "surface", "wall_surface"]:
		return MOUNT_OUTER
	return ""

static func get_mount_side(object_data: Dictionary) -> String:
	var canonical: String = normalize_mount_side(object_data.get("mount_side", ""))
	if not canonical.is_empty():
		return canonical
	return normalize_mount_side(object_data.get("route_mode", object_data.get("wall_routing_mode", "")))

static func normalize_route_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper()
	return side if side in ROUTE_SIDES else ""

static func get_route_sides(object_data: Dictionary) -> Array[String]:
	var raw_sides: Array = []
	if object_data.get("route_sides", []) is Array:
		raw_sides = Array(object_data.get("route_sides", [])).duplicate()
	if raw_sides.is_empty():
		raw_sides = [object_data.get("route_side_1", object_data.get("wall_side_1", "")), object_data.get("route_side_2", object_data.get("wall_side_2", ""))]
	var sides: Array[String] = []
	for value in raw_sides:
		var normalized: String = normalize_route_side(value)
		if not normalized.is_empty():
			sides.append(normalized)
	return sides

static func normalize_route_pair(value: Variant) -> Array[String]:
	var raw: Array = Array(value) if value is Array else []
	var sides: Array[String] = []
	for side_value in raw:
		var side: String = normalize_route_side(side_value)
		if not side.is_empty():
			sides.append(side)
	sides.sort_custom(func(a: String, b: String) -> bool: return int(SIDE_ORDER.get(a, 99)) < int(SIDE_ORDER.get(b, 99)))
	return sides

static func get_route_shape(route_sides: Array[String]) -> String:
	if route_sides.size() != 2 or route_sides[0] == route_sides[1]:
		return ""
	return SHAPE_STRAIGHT if str(OPPOSITE_SIDE.get(route_sides[0], "")) == route_sides[1] else SHAPE_TURN

static func canonicalize_segment(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	var kind: String = get_routing_kind(result)
	if kind.is_empty():
		return result
	var mount_side: String = get_mount_side(result)
	if mount_side.is_empty():
		mount_side = MOUNT_INNER
	var sides: Array[String] = normalize_route_pair(get_route_sides(result))
	result["format_version"] = FORMAT_VERSION
	result["entity_type"] = "cooling_system"
	result["routing_kind"] = kind
	result["cooling_system_type"] = kind
	result["mount_side"] = mount_side
	result["route_sides"] = sides
	result["route_shape"] = get_route_shape(sides)
	result["passive_route"] = true
	for field_name in ["route_mode", "wall_routing_mode", "route_side_1", "route_side_2", "wall_side_1", "wall_side_2"]:
		result.erase(field_name)
	for field_name in FORBIDDEN_STORED_FIELDS:
		result.erase(field_name)
	return result

static func validate_segment(object_data: Dictionary) -> Dictionary:
	var kind: String = get_routing_kind(object_data)
	if kind.is_empty():
		return _result(false, CODE_NOT_PASSIVE_ROUTE, object_data, {})
	if kind not in ROUTING_KINDS:
		return _result(false, CODE_INVALID_KIND, object_data, {"routing_kind": kind})
	var mount_side: String = get_mount_side(object_data)
	if mount_side not in MOUNT_SIDES:
		return _result(false, CODE_INVALID_MOUNT_SIDE, object_data, {"mount_side": mount_side})
	var raw_sides: Array[String] = get_route_sides(object_data)
	if raw_sides.is_empty():
		return _result(false, CODE_ROUTE_PAIR_MISSING, object_data, {})
	if raw_sides.size() != 2:
		return _result(false, CODE_ROUTE_PAIR_COUNT_INVALID, object_data, {"count": raw_sides.size()})
	for side in raw_sides:
		if side not in ROUTE_SIDES:
			return _result(false, CODE_ROUTE_SIDE_INVALID, object_data, {"side": side})
	if raw_sides[0] == raw_sides[1]:
		return _result(false, CODE_ROUTE_SIDE_DUPLICATE, object_data, {"side": raw_sides[0]})
	var normalized_pair: Array[String] = normalize_route_pair(raw_sides)
	return _result(true, CODE_VALID, object_data, {
		"routing_kind": kind,
		"mount_side": mount_side,
		"normalized_route_pair": normalized_pair,
		"route_shape": get_route_shape(normalized_pair)
	})

static func build_topology(objects_by_id: Dictionary) -> Dictionary:
	var segments: Dictionary = {}
	var diagnostics: Dictionary = {}
	var ids: Array[String] = []
	for id_value in objects_by_id.keys():
		var object_id: String = str(id_value)
		var object_data: Dictionary = Dictionary(objects_by_id[id_value])
		if not is_passive_route(object_data):
			continue
		var canonical: Dictionary = canonicalize_segment(object_data)
		segments[object_id] = canonical
		ids.append(object_id)
		diagnostics[object_id] = []
	ids.sort()

	var neighbors: Dictionary = {}
	var port_status: Dictionary = {}
	for object_id in ids:
		neighbors[object_id] = []
		port_status[object_id] = {}
		var validation: Dictionary = validate_segment(Dictionary(segments[object_id]))
		if not bool(validation.get("success", false)):
			Array(diagnostics[object_id]).append(_issue(str(validation.get("code", CODE_ROUTE_PAIR_MISSING)), object_id, "", "", Dictionary(validation.get("details", {}))))
			continue
		for side in get_route_sides(Dictionary(segments[object_id])):
			Dictionary(port_status[object_id])[side] = {"state": "disconnected", "neighbor_id": "", "code": CODE_DISCONNECTED}

	for object_id in ids:
		var segment: Dictionary = Dictionary(segments[object_id])
		if not bool(validate_segment(segment).get("success", false)):
			continue
		for side in get_route_sides(segment):
			var expected_cell: Vector2i = get_object_cell(segment) + get_side_delta(side)
			var candidate_ids: Array[String] = _segments_at_cell(ids, segments, expected_cell)
			if candidate_ids.is_empty():
				Array(diagnostics[object_id]).append(_issue(CODE_DISCONNECTED, object_id, "", side, {"expected_cell": expected_cell}))
				continue
			var connected_neighbor_id: String = ""
			var best_issue: Dictionary = {}
			for candidate_id in candidate_ids:
				var candidate: Dictionary = Dictionary(segments[candidate_id])
				var compatibility: Dictionary = validate_neighbor_port(segment, side, candidate)
				if bool(compatibility.get("success", false)):
					connected_neighbor_id = candidate_id
					break
				if best_issue.is_empty():
					best_issue = _issue(str(compatibility.get("code", CODE_NEIGHBOR_PORT_MISMATCH)), object_id, candidate_id, side, Dictionary(compatibility.get("details", {})))
			if connected_neighbor_id.is_empty():
				Array(diagnostics[object_id]).append(best_issue if not best_issue.is_empty() else _issue(CODE_DISCONNECTED, object_id, "", side, {}))
				continue
			if not Array(neighbors[object_id]).has(connected_neighbor_id):
				Array(neighbors[object_id]).append(connected_neighbor_id)
			Array(neighbors[object_id]).sort()
			Dictionary(port_status[object_id])[side] = {"state": "connected", "neighbor_id": connected_neighbor_id, "code": CODE_VALID}

	var components: Array[Dictionary] = _build_components(ids, neighbors, segments)
	var component_by_object_id: Dictionary = {}
	for component in components:
		var component_id: String = str(component.get("component_id", ""))
		for member_id in Array(component.get("members", [])):
			component_by_object_id[str(member_id)] = component_id

	return {
		"ok": true,
		"success": true,
		"code": CODE_VALID,
		"reason_code": CODE_VALID,
		"segments": segments,
		"neighbors": neighbors,
		"port_status": port_status,
		"components": components,
		"component_by_object_id": component_by_object_id,
		"diagnostics": diagnostics
	}

static func preview_segment(object_id: String, object_data: Dictionary, objects_by_id: Dictionary) -> Dictionary:
	var preview_objects: Dictionary = objects_by_id.duplicate(true)
	preview_objects[object_id] = object_data.duplicate(true)
	var validation: Dictionary = validate_segment(object_data)
	var topology: Dictionary = build_topology(preview_objects)
	var canonical: Dictionary = canonicalize_segment(object_data)
	return {
		"ok": bool(validation.get("success", false)),
		"success": bool(validation.get("success", false)),
		"code": str(validation.get("code", CODE_VALID)),
		"reason_code": str(validation.get("reason_code", validation.get("code", CODE_VALID))),
		"object_id": object_id,
		"routing_kind": get_routing_kind(canonical),
		"mount_side": get_mount_side(canonical),
		"normalized_route_pair": normalize_route_pair(get_route_sides(canonical)),
		"route_shape": get_route_shape(normalize_route_pair(get_route_sides(canonical))),
		"compatible_neighbors": Array(Dictionary(topology.get("neighbors", {})).get(object_id, [])).duplicate(),
		"port_status": Dictionary(Dictionary(topology.get("port_status", {})).get(object_id, {})).duplicate(true),
		"component_id": str(Dictionary(topology.get("component_by_object_id", {})).get(object_id, "")),
		"issues": Array(Dictionary(topology.get("diagnostics", {})).get(object_id, [])).duplicate(true),
		"details": Dictionary(validation.get("details", {})).duplicate(true)
	}

static func validate_neighbor_port(segment: Dictionary, side: String, candidate: Dictionary) -> Dictionary:
	var normalized_side: String = normalize_route_side(side)
	if get_routing_kind(segment) != get_routing_kind(candidate):
		return _result(false, CODE_NEIGHBOR_KIND_INCOMPATIBLE, segment, {"neighbor_kind": get_routing_kind(candidate)})
	if get_mount_side(segment) != get_mount_side(candidate):
		return _result(false, CODE_NEIGHBOR_MOUNT_INCOMPATIBLE, segment, {"neighbor_mount_side": get_mount_side(candidate)})
	var opposite: String = str(OPPOSITE_SIDE.get(normalized_side, ""))
	if not get_route_sides(candidate).has(opposite):
		return _result(false, CODE_NEIGHBOR_PORT_MISMATCH, segment, {"required_neighbor_side": opposite})
	return _result(true, CODE_VALID, segment, {"neighbor_side": opposite})

static func get_object_cell(object_data: Dictionary) -> Vector2i:
	var value: Variant = object_data.get("position", object_data.get("cell", Vector2i.ZERO))
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	return Vector2i.ZERO

static func get_side_delta(side: String) -> Vector2i:
	return Vector2i(SIDE_DELTA.get(normalize_route_side(side), Vector2i.ZERO))

static func _segments_at_cell(ids: Array[String], segments: Dictionary, cell: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for object_id in ids:
		if get_object_cell(Dictionary(segments[object_id])) == cell:
			result.append(object_id)
	return result

static func _build_components(ids: Array[String], neighbors: Dictionary, segments: Dictionary) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var components: Array[Dictionary] = []
	for object_id in ids:
		if seen.has(object_id):
			continue
		var queue: Array[String] = [object_id]
		var members: Array[String] = []
		seen[object_id] = true
		while not queue.is_empty():
			var current: String = queue.pop_front()
			members.append(current)
			for neighbor_value in Array(neighbors.get(current, [])):
				var neighbor_id: String = str(neighbor_value)
				if not seen.has(neighbor_id):
					seen[neighbor_id] = true
					queue.append(neighbor_id)
		members.sort()
		var first_segment: Dictionary = Dictionary(segments[members[0]])
		var component_index: int = components.size() + 1
		var component_id: String = "%s_%s_component_%03d" % [get_routing_kind(first_segment), get_mount_side(first_segment), component_index]
		components.append({
			"component_id": component_id,
			"routing_kind": get_routing_kind(first_segment),
			"mount_side": get_mount_side(first_segment),
			"members": members,
			"cells": members.map(func(member_id: String) -> Vector2i: return get_object_cell(Dictionary(segments[member_id])))
		})
	return components

static func _issue(code: String, object_id: String, neighbor_id: String, side: String, details: Dictionary) -> Dictionary:
	return {
		"code": code,
		"reason_code": code,
		"object_id": object_id,
		"neighbor_id": neighbor_id,
		"side": side,
		"details": details.duplicate(true)
	}

static func _result(success: bool, code: String, object_data: Dictionary, details: Dictionary) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"object_id": str(object_data.get("id", "")),
		"details": details.duplicate(true)
	}
