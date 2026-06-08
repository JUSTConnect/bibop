extends RefCounted
class_name BipobTargetingService

const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const DEBUG_RUNTIME_ACTION_TARGET_TRACE := false


static func _trace_runtime_action_target(payload: Dictionary) -> void:
	if not DEBUG_RUNTIME_ACTION_TARGET_TRACE:
		return
	print("[RuntimeActionTarget] %s" % JSON.stringify(payload))


static func get_facing_cell(controller: Variant) -> Vector2i:
	return controller.grid_position + controller.get_direction_vector(controller.direction)


static func get_facing_object(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	var facing_cell: Vector2i = get_facing_cell(controller)
	var world_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(facing_cell))
	return resolve_runtime_action_target_for_cell(controller, facing_cell, world_object)


static func _get_wall_mounted_object_candidate(controller: Variant, target_cell: Vector2i) -> Dictionary:
	if controller == null or controller.mission_manager == null or not controller.mission_manager.has_method("get_wall_mounted_world_object_at_cell"):
		return {}
	return Dictionary(controller.mission_manager.call("get_wall_mounted_world_object_at_cell", target_cell))


static func resolve_runtime_action_target_for_cell(controller: Variant, target_cell: Vector2i, world_object: Dictionary = {}) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return world_object
	var wall_mounted_candidate: Dictionary = _get_wall_mounted_object_candidate(controller, target_cell)
	if not wall_mounted_candidate.is_empty():
		return wall_mounted_candidate
	var breachable_wall_target: Dictionary = {}
	if controller.mission_manager.has_method("get_breachable_wall_action_target_at_cell"):
		breachable_wall_target = Dictionary(controller.mission_manager.call("get_breachable_wall_action_target_at_cell", target_cell))
	if breachable_wall_target.is_empty():
		return world_object
	if world_object.is_empty():
		return breachable_wall_target
	if BreachableWallServiceRef.is_active_breachable_wall_data(world_object):
		return world_object
	var object_group: String = str(world_object.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(world_object.get("object_type", "")).strip_edges().to_lower()
	if object_group == "wall" or object_type == "wall" or object_type == "breachable_wall":
		return breachable_wall_target
	return world_object


static func get_facing_item(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	var items: Array = controller.mission_manager.get_items_at_cell(get_facing_cell(controller))
	return Dictionary(items[0]) if not items.is_empty() else {}


static func build_action_target_context(controller: Variant) -> Dictionary:
	var target_position: Vector2i = get_facing_cell(controller)
	var raw_world_object: Dictionary = {}
	if controller.mission_manager != null:
		raw_world_object = Dictionary(controller.mission_manager.get_world_object_at_cell(target_position))
	var wall_mounted_candidate: Dictionary = _get_wall_mounted_object_candidate(controller, target_position)
	var breachable_wall_candidate: Dictionary = {}
	if controller.mission_manager != null and controller.mission_manager.has_method("get_breachable_wall_action_target_at_cell"):
		breachable_wall_candidate = Dictionary(controller.mission_manager.call("get_breachable_wall_action_target_at_cell", target_position))
	var target_object: Dictionary = resolve_runtime_action_target_for_cell(controller, target_position, raw_world_object)
	if target_object.is_empty() and controller.mission_manager != null:
		var items: Array = controller.mission_manager.get_items_at_cell(target_position)
		if items.is_empty() and target_position != controller.grid_position:
			items = controller.mission_manager.get_items_at_cell(controller.grid_position)
			if not items.is_empty():
				target_position = controller.grid_position
		if not items.is_empty():
			target_object = Dictionary(items[0])
	var view_model: Dictionary = controller.build_runtime_action_view_model(target_object, target_position)
	var resolved_target: Dictionary = Dictionary(view_model.get("target", target_object))
	var direction_text: String = ""
	if controller.has_method("get_direction"):
		direction_text = str(controller.get_direction())
	_trace_runtime_action_target({
		"bipob_cell": str(controller.grid_position),
		"facing_cell": str(target_position),
		"direction": direction_text,
		"raw_object": {
			"id": str(raw_world_object.get("id", "")),
			"object_type": str(raw_world_object.get("object_type", "")),
			"object_group": str(raw_world_object.get("object_group", "")),
			"state": str(raw_world_object.get("state", "")),
			"placement_mode": str(raw_world_object.get("placement_mode", raw_world_object.get("placement", "")))
		},
		"normalized_object": {
			"id": str(resolved_target.get("id", target_object.get("id", ""))),
			"object_type": str(resolved_target.get("object_type", target_object.get("object_type", ""))),
			"object_group": str(resolved_target.get("object_group", target_object.get("object_group", ""))),
			"state": str(resolved_target.get("state", target_object.get("state", ""))),
			"placement_mode": str(resolved_target.get("placement_mode", resolved_target.get("placement", target_object.get("placement_mode", target_object.get("placement", "")))))
		},
		"raw_object_dump": var_to_str(raw_world_object),
		"wall_mounted_candidate": {
			"id": str(wall_mounted_candidate.get("id", "")),
			"object_type": str(wall_mounted_candidate.get("object_type", "")),
			"object_group": str(wall_mounted_candidate.get("object_group", "")),
			"placement_mode": str(wall_mounted_candidate.get("placement_mode", wall_mounted_candidate.get("placement", "")))
		},
		"breachable_wall_candidate": {
			"id": str(breachable_wall_candidate.get("id", "")),
			"object_type": str(breachable_wall_candidate.get("object_type", "")),
			"object_group": str(breachable_wall_candidate.get("object_group", "")),
			"placement_mode": str(breachable_wall_candidate.get("placement_mode", breachable_wall_candidate.get("placement", "")))
		},
		"actions_returned_by_get_available_world_actions": Array(view_model.get("raw_action_ids", [])),
		"actions_after_filtering": Array(view_model.get("available_action_ids", [])),
		"action_descriptors": Array(view_model.get("actions", []))
	})
	return {"target_position": target_position, "target_object": view_model.get("target", {}), "actions": view_model.get("raw_action_ids", []), "available_action_ids": view_model.get("available_action_ids", []), "action_view_model": view_model}


static func build_connector_target_context(controller: Variant) -> Dictionary:
	return _build_action_context_for_id(build_action_target_context(controller), "connect")


static func build_heavy_claw_target_context(controller: Variant) -> Dictionary:
	var action_target: Dictionary = build_action_target_context(controller)
	var breach_context: Dictionary = _build_action_context_for_id(action_target, "break_breachable_wall")
	return breach_context if not breach_context.is_empty() else _build_action_context_for_id(action_target, "push")


static func build_targeting_snapshot(controller: Variant) -> Dictionary:
	var action_target: Dictionary = build_action_target_context(controller)
	return {
		"bipob_cell": controller.grid_position,
		"facing_cell": get_facing_cell(controller),
		"facing_object": get_facing_object(controller),
		"facing_item": get_facing_item(controller),
		"action_target": action_target,
		"connector_target": _build_action_context_for_id(action_target, "connect"),
		"heavy_claw_target": build_heavy_claw_target_context(controller)
	}


static func _build_action_context_for_id(action_target: Dictionary, action_id: String) -> Dictionary:
	var view_model: Dictionary = Dictionary(action_target.get("action_view_model", {}))
	for descriptor_variant in Array(view_model.get("actions", [])):
		if descriptor_variant is Dictionary and str(Dictionary(descriptor_variant).get("id", "")) == action_id:
			return {
				"target_position": action_target.get("target_position", Vector2i.ZERO),
				"target_object": action_target.get("target_object", {}),
				"action": Dictionary(descriptor_variant)
			}
	return {}
