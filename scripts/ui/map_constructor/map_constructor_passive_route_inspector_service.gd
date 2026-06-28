extends RefCounted
class_name MapConstructorPassiveRouteInspectorService

const PassiveRouteServiceRef = preload("res://scripts/game/cooling/passive_route_service.gd")

static func build_objects_by_id(mission_objects: Variant, selected_id: String, selected_data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if mission_objects is Array:
		for value in Array(mission_objects):
			if not (value is Dictionary):
				continue
			var object_data: Dictionary = Dictionary(value)
			var object_id: String = str(object_data.get("id", object_data.get("object_id", ""))).strip_edges()
			if object_id.is_empty() or not PassiveRouteServiceRef.is_passive_route(object_data):
				continue
			result[object_id] = PassiveRouteServiceRef.canonicalize_segment(object_data)
	result[selected_id] = PassiveRouteServiceRef.canonicalize_segment(selected_data)
	return result

static func get_route_pair(data: Dictionary) -> Array[String]:
	var sides: Array[String] = PassiveRouteServiceRef.normalize_route_pair(PassiveRouteServiceRef.get_route_sides(data))
	if sides.size() != 2:
		return [PassiveRouteServiceRef.SIDE_NW, PassiveRouteServiceRef.SIDE_SE]
	return sides

static func get_port_options(other_side: String, first_port: bool) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for side in PassiveRouteServiceRef.ROUTE_SIDES:
		options.append({
			"label": side,
			"value": side.to_lower(),
			"updates": {"route_sides": [side, other_side] if first_port else [other_side, side]},
			"disabled": side == other_side,
			"disabled_reason": "Route ports must use different sides."
		})
	return options

static func format_kind(kind: String) -> String:
	if kind == PassiveRouteServiceRef.KIND_AIR_DUCT:
		return "air duct"
	if kind == PassiveRouteServiceRef.KIND_WATER_PIPE:
		return "water pipe"
	return "unknown"

static func format_issue_lines(issues: Array) -> Array[String]:
	var result: Array[String] = []
	for value in issues:
		if not (value is Dictionary):
			continue
		var issue: Dictionary = Dictionary(value)
		var line: String = str(issue.get("code", "unknown_issue"))
		var side: String = str(issue.get("side", ""))
		var neighbor_id: String = str(issue.get("neighbor_id", ""))
		if not side.is_empty():
			line += " [%s]" % side
		if not neighbor_id.is_empty():
			line += " -> %s" % neighbor_id
		result.append(line)
	return result
