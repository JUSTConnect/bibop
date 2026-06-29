extends RefCounted
class_name PassiveRouteService

const KIND_AIR_DUCT := "air_duct"
const KIND_WATER_PIPE := "water_pipe"
const ROUTING_KINDS: Array[String] = [KIND_AIR_DUCT, KIND_WATER_PIPE]

const MODE_INNER := "inner"
const MODE_OUTER := "outer"
const ROUTING_MODES: Array[String] = [MODE_INNER, MODE_OUTER]

const VALID_SIDES: Array[String] = ["NE", "SE", "SW", "NW"]
const OPPOSITE_SIDE: Dictionary = {"NE":"SW", "SE":"NW", "SW":"NE", "NW":"SE"}
const SIDE_DELTA: Dictionary = {
	"NE": Vector2i(0, -1),
	"SE": Vector2i(1, 0),
	"SW": Vector2i(0, 1),
	"NW": Vector2i(-1, 0)
}

const SHAPE_STRAIGHT := "straight"
const SHAPE_TURN := "turn"

const CODE_VALID := "valid"
const CODE_NOT_PASSIVE_ROUTE := "not_passive_route"
const CODE_INVALID_KIND := "invalid_route_kind"
const CODE_INVALID_MOUNT_SIDE := "invalid_mount_side"
const CODE_ROUTE_SIDE_MISSING := "route_side_missing"
const CODE_ROUTE_SIDE_INVALID := "route_side_invalid"
const CODE_ROUTE_SIDE_DUPLICATE := "route_side_duplicate"
const CODE_ROUTE_PAIR_TOO_MANY := "route_pair_too_many"
const CODE_DISCONNECTED_PORT := "disconnected_port"
const CODE_NEIGHBOR_KIND_MISMATCH := "neighbor_kind_mismatch"
const CODE_NEIGHBOR_MODE_MISMATCH := "neighbor_mode_mismatch"
const CODE_NEIGHBOR_MOUNT_MISMATCH := "neighbor_mount_mismatch"
const CODE_NEIGHBOR_PORT_MISMATCH := "neighbor_port_mismatch"

const FORBIDDEN_STORED_FIELDS: Array[String] = [
	"state", "intent_state", "operational_state", "allowed_states", "status",
	"is_powered", "power_state", "power_mode", "power_network_id", "power_source_id",
	"control_mode", "control_terminal_id", "controlled_by", "access_type", "access_terminal_id",
	"health_state", "durability", "damaged", "broken", "destroyed",
	"flow_state", "blocked_state", "blocked", "is_blocked",
	"connected_device_ids", "connected_object_ids", "linked_object_ids", "linked_cooling_ids",
	"cooling_contour_id", "cooling_contour_mode", "cooling_contour_member_ids",
	"contour_id", "member_ids", "inner_contour_ids", "outer_contour_ids",
	"test_override_enabled", "runtime_test_override", "test_override",
	"generic_airflow_role", "airflow_roles", "generic_airflow_runtime",
	"airflow_network_id", "airflow_cells", "blocked_cells", "cooled_target_ids"
]

static func normalize_kind(value: Variant) -> String:
	var token: String = str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if token in ["external_air_duct", "internal_air_duct", "duct", KIND_AIR_DUCT]:
		return KIND_AIR_DUCT
	if token in ["external_water_pipe", "internal_water_pipe", "pipe", KIND_WATER_PIPE]:
		return KIND_WATER_PIPE
	return token if token in ROUTING_KINDS else ""

static func get_kind(object_data: Dictionary) -> String:
	for value in [
		object_data.get("routing_kind", ""),
		object_data.get("cooling_system_type", ""),
		object_data.get("object_type", object_data.get("type", "")),
		object_data.get("archetype_id", ""),
		object_data.get("map_constructor_prefab_id", "")
	]:
		var kind: String = normalize_kind(value)
		if not kind.is_empty():
			return kind
	return ""

static func is_passive_route(object_data: Dictionary) -> bool:
	return not object_data.is_empty() and not get_kind(object_data).is_empty()

static func normalize_mode(value: Variant) -> String:
	var token: String = str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if token in ["inner", "inside", "internal", "in_wall", "embedded"]:
		return MODE_INNER
	if token in ["outer", "outside", "external", "surface"]:
		return MODE_OUTER
	return MODE_INNER

static func get_mode(object_data: Dictionary) -> String:
	return normalize_mode(object_data.get("route_mode", object_data.get("wall_routing_mode", MODE_INNER)))

static func normalize_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper().replace("-", "").replace("_", "").replace(" ", "")
	match side:
		"NORTHEAST", "EASTNORTH", "NE": return "NE"
		"SOUTHEAST", "EASTSOUTH", "SE": return "SE"
		"SOUTHWEST", "WESTSOUTH", "SW": return "SW"
		"NORTHWEST", "WESTNORTH", "NW": return "NW"
	return ""

static func get_mount_side(object_data: Dictionary) -> String:
	for value in [
		object_data.get("mount_side", ""),
		object_data.get("wall_side", ""),
		object_data.get("interaction_side", ""),
		object_data.get("facing_side", "")
	]:
		var side: String = normalize_side(value)
		if not side.is_empty():
			return side
	return "SW"

static func get_raw_route_sides(object_data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var route_sides_variant: Variant = object_data.get("route_sides", [])
	if route_sides_variant is Array:
		for value in Array(route_sides_variant):
			result.append(normalize_side(value))
	if result.is_empty():
		for field_name in ["route_side_1", "route_side_2", "wall_side_1", "wall_side_2"]:
			if object_data.has(field_name):
				result.append(normalize_side(object_data.get(field_name, "")))
	return result

static func normalize_route_pair(object_data: Dictionary) -> Array[String]:
	var pair: Array[String] = []
	for side in get_raw_route_sides(object_data):
		if not side.is_empty() and not pair.has(side):
			pair.append(side)
	pair.sort_custom(func(a: String, b: String) -> bool: return VALID_SIDES.find(a) < VALID_SIDES.find(b))
	return pair

static func get_route_shape(route_pair: Array[String]) -> String:
	if route_pair.size() != 2:
		return ""
	return SHAPE_STRAIGHT if str(OPPOSITE_SIDE.get(route_pair[0], "")) == route_pair[1] else SHAPE_TURN

static func get_side_delta(side: String) -> Vector2i:
	return Vector2i(SIDE_DELTA.get(normalize_side(side), Vector2i.ZERO))

static func get_object_cell(object_data: Dictionary, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	var value: Variant = object_data.get("position", object_data.get("cell", fallback))
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))
	return fallback

static func normalize_segment(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	var kind: String = get_kind(result)
	if kind.is_empty():
		return result
	var route_pair: Array[String] = normalize_route_pair(result)
	var mount_side: String = get_mount_side(result)
	result["object_group"] = "cooling"
	result["group"] = "cooling"
	result["object_type"] = kind
	result["cooling_system_type"] = kind
	result["routing_kind"] = kind
	result["passive_route"] = true
	result["route_mode"] = get_mode(result)
	result["mount_side"] = mount_side
	result["wall_side"] = mount_side
	result["route_side_1"] = route_pair[0] if route_pair.size() > 0 else ""
	result["route_side_2"] = route_pair[1] if route_pair.size() > 1 else ""
	result["route_shape"] = get_route_shape(route_pair)
	result["blocks_movement"] = false
	result["blocks_vision"] = false
	result["changes_passability"] = false
	for field_name in FORBIDDEN_STORED_FIELDS:
		result.erase(field_name)
	for legacy_field in ["wall_routing_mode", "wall_side_1", "wall_side_2", "route_sides"]:
		result.erase(legacy_field)
	return result

static func validate_segment(object_data: Dictionary) -> Dictionary:
	var issues: Array[Dictionary] = []
	var kind: String = get_kind(object_data)
	if kind.is_empty():
		issues.append(_issue(CODE_NOT_PASSIVE_ROUTE, "Object is not a passive cooling route.", "error"))
		return _validation_result(false, issues, object_data)
	var mount_side: String = get_mount_side(object_data)
	if mount_side.is_empty() or mount_side not in VALID_SIDES:
		issues.append(_issue(CODE_INVALID_MOUNT_SIDE, "Mount side must be NE, SE, SW, or NW.", "error"))
	var raw_sides: Array[String] = get_raw_route_sides(object_data)
	if raw_sides.size() < 2:
		issues.append(_issue(CODE_ROUTE_SIDE_MISSING, "Passive route requires exactly two route sides.", "error"))
	elif raw_sides.size() > 2:
		issues.append(_issue(CODE_ROUTE_PAIR_TOO_MANY, "Passive route cannot form a T-junction or crossing.", "error"))
	for side in raw_sides:
		if side.is_empty():
			issues.append(_issue(CODE_ROUTE_SIDE_INVALID, "Route side must be NE, SE, SW, or NW.", "error"))
	var pair: Array[String] = normalize_route_pair(object_data)
	if raw_sides.size() >= 2 and pair.size() < 2:
		issues.append(_issue(CODE_ROUTE_SIDE_DUPLICATE, "Route sides must be different.", "error"))
	return _validation_result(not _has_error(issues), issues, object_data)

static func build_topology(objects: Array[Dictionary]) -> Dictionary:
	var segments: Dictionary = {}
	var by_cell: Dictionary = {}
	for object_data in objects:
		if not is_passive_route(object_data):
			continue
		var normalized: Dictionary = normalize_segment(object_data)
		var object_id: String = str(normalized.get("id", "")).strip_edges()
		if object_id.is_empty():
			object_id = _anonymous_segment_id(normalized)
		segments[object_id] = normalized
		var cell: Vector2i = get_object_cell(normalized)
		if not by_cell.has(cell):
			by_cell[cell] = []
		Array(by_cell[cell]).append(object_id)

	var previews: Dictionary = {}
	var links: Dictionary = {}
	for object_id in segments.keys():
		links[object_id] = []
		var segment: Dictionary = Dictionary(segments[object_id])
		var validation: Dictionary = validate_segment(segment)
		var issues: Array[Dictionary] = Array(validation.get("issues", [])).duplicate(true)
		var pair: Array[String] = normalize_route_pair(segment)
		var connected_sides: Dictionary = {}
		var neighbor_ids: Array[String] = []
		if bool(validation.get("success", false)):
			for side in pair:
				var probe: Dictionary = _probe_port(object_id, segment, side, segments, by_cell)
				for issue in Array(probe.get("issues", [])):
					issues.append(Dictionary(issue))
				for neighbor_id in Array(probe.get("compatible_neighbor_ids", [])):
					var neighbor_token: String = str(neighbor_id)
					if not neighbor_ids.has(neighbor_token):
						neighbor_ids.append(neighbor_token)
					if not Array(links[object_id]).has(neighbor_token):
						Array(links[object_id]).append(neighbor_token)
					if not links.has(neighbor_token):
						links[neighbor_token] = []
					if not Array(links[neighbor_token]).has(object_id):
						Array(links[neighbor_token]).append(object_id)
				if not Array(probe.get("compatible_neighbor_ids", [])).is_empty():
					connected_sides[side] = true
		previews[object_id] = {
			"object_id": object_id,
			"success": bool(validation.get("success", false)),
			"ok": bool(validation.get("success", false)),
			"code": CODE_VALID if bool(validation.get("success", false)) else str(validation.get("code", CODE_ROUTE_SIDE_INVALID)),
			"reason_code": CODE_VALID if bool(validation.get("success", false)) else str(validation.get("code", CODE_ROUTE_SIDE_INVALID)),
			"routing_kind": get_kind(segment),
			"route_mode": get_mode(segment),
			"mount_side": get_mount_side(segment),
			"route_pair": pair,
			"route_shape": get_route_shape(pair),
			"compatible_neighbor_ids": neighbor_ids,
			"connected_sides": connected_sides,
			"issues": _dedupe_issues(issues),
			"component_id": "",
			"component_member_ids": []
		}

	var components: Dictionary = {}
	var seen: Dictionary = {}
	var sorted_ids: Array = segments.keys()
	sorted_ids.sort()
	for object_id_variant in sorted_ids:
		var object_id: String = str(object_id_variant)
		if seen.has(object_id):
			continue
		var queue: Array[String] = [object_id]
		var members: Array[String] = []
		seen[object_id] = true
		while not queue.is_empty():
			var current: String = queue.pop_front()
			members.append(current)
			var next_ids: Array = Array(links.get(current, [])).duplicate()
			next_ids.sort()
			for next_id_variant in next_ids:
				var next_id: String = str(next_id_variant)
				if not seen.has(next_id):
					seen[next_id] = true
					queue.append(next_id)
		members.sort()
		var component_id: String = _component_id(members, segments)
		components[component_id] = {
			"component_id": component_id,
			"routing_kind": get_kind(Dictionary(segments[members[0]])),
			"route_mode": get_mode(Dictionary(segments[members[0]])),
			"member_ids": members.duplicate(),
			"cells": members.map(func(member_id: String) -> Vector2i: return get_object_cell(Dictionary(segments[member_id])))
		}
		for member_id in members:
			Dictionary(previews[member_id])["component_id"] = component_id
			Dictionary(previews[member_id])["component_member_ids"] = members.duplicate()

	return {
		"segments": segments,
		"previews": previews,
		"components": components,
		"links": links
	}

static func preview_segment(object_data: Dictionary, objects: Array[Dictionary]) -> Dictionary:
	var probe_objects: Array[Dictionary] = []
	var object_id: String = str(object_data.get("id", "")).strip_edges()
	for row in objects:
		if not object_id.is_empty() and str(row.get("id", "")).strip_edges() == object_id:
			continue
		probe_objects.append(row.duplicate(true))
	probe_objects.append(object_data.duplicate(true))
	var topology: Dictionary = build_topology(probe_objects)
	var resolved_id: String = object_id if not object_id.is_empty() else _anonymous_segment_id(normalize_segment(object_data))
	return Dictionary(Dictionary(topology.get("previews", {})).get(resolved_id, validate_segment(object_data))).duplicate(true)

static func get_render_snapshot(object_data: Dictionary, preview: Dictionary = {}) -> Dictionary:
	var normalized: Dictionary = normalize_segment(object_data)
	var pair: Array[String] = normalize_route_pair(normalized)
	return {
		"routing_kind": get_kind(normalized),
		"route_mode": get_mode(normalized),
		"mount_side": get_mount_side(normalized),
		"route_pair": pair,
		"route_shape": get_route_shape(pair),
		"connected_sides": Dictionary(preview.get("connected_sides", {})).duplicate(true),
		"component_id": str(preview.get("component_id", ""))
	}

static func collect_issues(objects: Array[Dictionary]) -> Dictionary:
	var topology: Dictionary = build_topology(objects)
	var result: Dictionary = {}
	for object_id in Dictionary(topology.get("previews", {})).keys():
		result[object_id] = Array(Dictionary(topology["previews"][object_id]).get("issues", [])).duplicate(true)
	return result

static func _probe_port(object_id: String, segment: Dictionary, side: String, segments: Dictionary, by_cell: Dictionary) -> Dictionary:
	var issues: Array[Dictionary] = []
	var compatible: Array[String] = []
	var target_cell: Vector2i = get_object_cell(segment) + get_side_delta(side)
	var candidates: Array = Array(by_cell.get(target_cell, []))
	if candidates.is_empty():
		issues.append(_issue(CODE_DISCONNECTED_PORT, "No neighboring segment on route side %s." % side, "warning", {"side":side, "cell":target_cell}))
		return {"issues":issues, "compatible_neighbor_ids":compatible}
	var saw_kind: bool = false
	var saw_mode: bool = false
	var saw_mount: bool = false
	for candidate_id_variant in candidates:
		var candidate_id: String = str(candidate_id_variant)
		if candidate_id == object_id:
			continue
		var candidate: Dictionary = Dictionary(segments[candidate_id])
		if get_kind(candidate) != get_kind(segment):
			continue
		saw_kind = true
		if get_mode(candidate) != get_mode(segment):
			continue
		saw_mode = true
		if get_mount_side(candidate) != get_mount_side(segment):
			continue
		saw_mount = true
		var opposite: String = str(OPPOSITE_SIDE.get(side, ""))
		if not normalize_route_pair(candidate).has(opposite):
			continue
		compatible.append(candidate_id)
	if compatible.is_empty():
		if not saw_kind:
			issues.append(_issue(CODE_NEIGHBOR_KIND_MISMATCH, "Neighbor route kind is incompatible.", "warning", {"side":side, "cell":target_cell}))
		elif not saw_mode:
			issues.append(_issue(CODE_NEIGHBOR_MODE_MISMATCH, "Neighbor inner/outer route mode is incompatible.", "warning", {"side":side, "cell":target_cell}))
		elif not saw_mount:
			issues.append(_issue(CODE_NEIGHBOR_MOUNT_MISMATCH, "Neighbor mount side is incompatible.", "warning", {"side":side, "cell":target_cell}))
		else:
			issues.append(_issue(CODE_NEIGHBOR_PORT_MISMATCH, "Neighbor has no opposite physical route port.", "warning", {"side":side, "cell":target_cell}))
	return {"issues":issues, "compatible_neighbor_ids":compatible}

static func _validation_result(success: bool, issues: Array[Dictionary], object_data: Dictionary) -> Dictionary:
	var code: String = CODE_VALID
	for issue in issues:
		if str(issue.get("severity", "")) == "error":
			code = str(issue.get("code", CODE_ROUTE_SIDE_INVALID))
			break
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"routing_kind": get_kind(object_data),
		"route_mode": get_mode(object_data),
		"mount_side": get_mount_side(object_data),
		"route_pair": normalize_route_pair(object_data),
		"route_shape": get_route_shape(normalize_route_pair(object_data)),
		"issues": _dedupe_issues(issues)
	}

static func _has_error(issues: Array[Dictionary]) -> bool:
	for issue in issues:
		if str(issue.get("severity", "")) == "error":
			return true
	return false

static func _issue(code: String, message: String, severity: String, details: Dictionary = {}) -> Dictionary:
	return {"code":code, "reason_code":code, "message":message, "severity":severity, "details":details.duplicate(true)}

static func _dedupe_issues(issues: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for issue in issues:
		var key: String = "%s|%s|%s" % [str(issue.get("code", "")), str(issue.get("message", "")), var_to_str(issue.get("details", {}))]
		if seen.has(key):
			continue
		seen[key] = true
		result.append(issue.duplicate(true))
	return result

static func _component_id(members: Array[String], segments: Dictionary) -> String:
	var tokens: Array[String] = []
	for member_id in members:
		var segment: Dictionary = Dictionary(segments[member_id])
		var pair: Array[String] = normalize_route_pair(segment)
		tokens.append("%s@%s,%s:%s:%s:%s" % [member_id, get_object_cell(segment).x, get_object_cell(segment).y, get_kind(segment), get_mode(segment), ",".join(pair)])
	tokens.sort()
	var first: Dictionary = Dictionary(segments[members[0]])
	return "%s_%s_component_%s" % [get_kind(first), get_mode(first), "|".join(tokens).md5_text().substr(0, 10)]

static func _anonymous_segment_id(segment: Dictionary) -> String:
	var pair: Array[String] = normalize_route_pair(segment)
	var cell: Vector2i = get_object_cell(segment)
	return "anonymous_%s_%s_%d_%d_%s" % [get_kind(segment), get_mode(segment), cell.x, cell.y, "_".join(pair)]
