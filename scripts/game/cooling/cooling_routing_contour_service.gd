extends RefCounted
class_name CoolingRoutingContourService

# Compatibility facade. PassiveRouteService is the only topology resolver.

const PassiveRouteServiceRef = preload("res://scripts/game/cooling/passive_route_service.gd")

static func build_contours(objects_by_id: Dictionary) -> Dictionary:
	var topology: Dictionary = PassiveRouteServiceRef.build_topology(objects_by_id)
	var result: Dictionary = {
		PassiveRouteServiceRef.KIND_AIR_DUCT: {},
		PassiveRouteServiceRef.KIND_WATER_PIPE: {}
	}
	for component_value in Array(topology.get("components", [])):
		var component: Dictionary = Dictionary(component_value)
		var kind: String = str(component.get("routing_kind", ""))
		var component_id: String = str(component.get("component_id", ""))
		if kind in PassiveRouteServiceRef.ROUTING_KINDS and not component_id.is_empty():
			result[kind][component_id] = component.duplicate(true)
	return result

static func get_object_contour_id(object_data: Dictionary, object_id: String, computed_contours: Dictionary) -> String:
	var kind: String = PassiveRouteServiceRef.get_routing_kind(object_data)
	for contour_id_value in Dictionary(computed_contours.get(kind, {})).keys():
		var contour_id: String = str(contour_id_value)
		var contour: Dictionary = Dictionary(Dictionary(computed_contours.get(kind, {})).get(contour_id, {}))
		if Array(contour.get("members", [])).has(object_id):
			return contour_id
	return ""

static func collect_route_issues(objects_by_id: Dictionary) -> Dictionary:
	var topology: Dictionary = PassiveRouteServiceRef.build_topology(objects_by_id)
	return Dictionary(topology.get("diagnostics", {})).duplicate(true)

static func collect_contour_warnings(objects_by_id: Dictionary) -> Dictionary:
	var issues_by_id: Dictionary = collect_route_issues(objects_by_id)
	var warnings_by_id: Dictionary = {}
	for object_id_value in issues_by_id.keys():
		var object_id: String = str(object_id_value)
		var warnings: Array[String] = []
		for issue_value in Array(issues_by_id[object_id_value]):
			var issue: Dictionary = Dictionary(issue_value)
			warnings.append(_format_issue(issue))
		warnings_by_id[object_id] = warnings
	return warnings_by_id

static func preview_route(object_id: String, object_data: Dictionary, objects_by_id: Dictionary) -> Dictionary:
	return PassiveRouteServiceRef.preview_segment(object_id, object_data, objects_by_id)

static func canonicalize_route(object_data: Dictionary) -> Dictionary:
	return PassiveRouteServiceRef.canonicalize_segment(object_data)

static func _format_issue(issue: Dictionary) -> String:
	var code: String = str(issue.get("code", ""))
	var side: String = str(issue.get("side", ""))
	match code:
		PassiveRouteServiceRef.CODE_DISCONNECTED:
			return "Disconnected route port%s." % (" on %s" % side if not side.is_empty() else "")
		PassiveRouteServiceRef.CODE_NEIGHBOR_KIND_INCOMPATIBLE:
			return "Neighbor routing kind is incompatible%s." % (" on %s" % side if not side.is_empty() else "")
		PassiveRouteServiceRef.CODE_NEIGHBOR_MOUNT_INCOMPATIBLE:
			return "Neighbor mount side is incompatible%s." % (" on %s" % side if not side.is_empty() else "")
		PassiveRouteServiceRef.CODE_NEIGHBOR_PORT_MISMATCH:
			return "Neighbor has no matching route port%s." % (" on %s" % side if not side.is_empty() else "")
		PassiveRouteServiceRef.CODE_ROUTE_PAIR_MISSING:
			return "Route pair is missing."
		PassiveRouteServiceRef.CODE_ROUTE_PAIR_COUNT_INVALID:
			return "Passive route requires exactly two route sides."
		PassiveRouteServiceRef.CODE_ROUTE_SIDE_DUPLICATE:
			return "Route sides must be different."
		PassiveRouteServiceRef.CODE_INVALID_MOUNT_SIDE:
			return "Mount side must be inner or outer."
		_:
			return code
