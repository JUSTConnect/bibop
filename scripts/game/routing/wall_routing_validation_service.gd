extends RefCounted
class_name WallRoutingValidationService

const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")

static func is_wall_routing_utility_object(object_data: Dictionary) -> bool:
	return PassiveRouteServiceRef.is_passive_route(object_data)

static func _collect_world_objects(grid_manager: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if grid_manager == null:
		return result
	var value: Variant = grid_manager.get("mission_world_objects")
	if value is Array:
		for row in Array(value):
			if row is Dictionary:
				result.append(Dictionary(row).duplicate(true))
	return result

static func collect_issue_rows(object_data: Dictionary, cell: Vector2i, grid_manager: Node) -> Array[Dictionary]:
	if not is_wall_routing_utility_object(object_data):
		return []
	var selected: Dictionary = object_data.duplicate(true)
	selected["position"] = cell
	if str(selected.get("id", "")).strip_edges().is_empty():
		selected["id"] = "constructor_preview_route"
	var preview: Dictionary = PassiveRouteServiceRef.preview_segment(selected, _collect_world_objects(grid_manager))
	var result: Array[Dictionary] = []
	for issue_variant in Array(preview.get("issues", [])):
		if issue_variant is Dictionary:
			result.append(Dictionary(issue_variant).duplicate(true))
	return result

static func collect_warnings(object_data: Dictionary, cell: Vector2i, grid_manager: Node) -> Array[String]:
	var result: Array[String] = []
	for issue in collect_issue_rows(object_data, cell, grid_manager):
		var code: String = str(issue.get("code", ""))
		var message: String = str(issue.get("message", ""))
		if code.is_empty():
			result.append(message)
		else:
			result.append("[%s] %s" % [code, message])
	return result
