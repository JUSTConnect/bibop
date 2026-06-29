extends RefCounted
class_name CoolingRoutingContourService

const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")

static func _objects_array(objects_by_id: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array = objects_by_id.keys()
	ids.sort()
	for id_variant in ids:
		var value: Variant = objects_by_id[id_variant]
		if not value is Dictionary:
			continue
		var object_data: Dictionary = Dictionary(value).duplicate(true)
		if str(object_data.get("id", "")).strip_edges().is_empty():
			object_data["id"] = str(id_variant)
		result.append(object_data)
	return result

static func build_contours(objects_by_id: Dictionary) -> Dictionary:
	var topology: Dictionary = PassiveRouteServiceRef.build_topology(_objects_array(objects_by_id))
	var result: Dictionary = {"air_duct": {}, "water_pipe": {}}
	for component_id in Dictionary(topology.get("components", {})).keys():
		var component: Dictionary = Dictionary(topology["components"][component_id])
		var kind: String = str(component.get("routing_kind", ""))
		if not result.has(kind):
			continue
		result[kind][component_id] = {
			"routing_kind": kind,
			"route_mode": str(component.get("route_mode", "")),
			"members": Array(component.get("member_ids", [])).duplicate(),
			"cells": Array(component.get("cells", [])).duplicate(),
			"computed": true
		}
	return result

static func get_object_contour_id(object_data: Dictionary, object_id: String, computed_contours: Dictionary) -> String:
	var kind: String = PassiveRouteServiceRef.get_kind(object_data)
	for component_id in Dictionary(computed_contours.get(kind, {})).keys():
		var members: Array = Array(Dictionary(computed_contours[kind][component_id]).get("members", []))
		if members.has(object_id):
			return str(component_id)
	return ""

static func collect_contour_issues(objects_by_id: Dictionary) -> Dictionary:
	return PassiveRouteServiceRef.collect_issues(_objects_array(objects_by_id))

static func collect_contour_warnings(objects_by_id: Dictionary) -> Dictionary:
	var issues_by_id: Dictionary = collect_contour_issues(objects_by_id)
	var result: Dictionary = {}
	for object_id in issues_by_id.keys():
		var messages: Array[String] = []
		for issue_variant in Array(issues_by_id[object_id]):
			var issue: Dictionary = Dictionary(issue_variant)
			var code: String = str(issue.get("code", ""))
			var message: String = str(issue.get("message", ""))
			if code.is_empty():
				messages.append(message)
			else:
				messages.append("[%s] %s" % [code, message])
		result[object_id] = messages
	return result
