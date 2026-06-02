extends RefCounted
class_name BipobTargetingService


static func get_facing_cell(controller: Variant) -> Vector2i:
	return controller.grid_position + controller.get_direction_vector(controller.direction)


static func get_facing_object(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	return Dictionary(controller.mission_manager.get_world_object_at_cell(get_facing_cell(controller)))


static func get_facing_item(controller: Variant) -> Dictionary:
	if controller.mission_manager == null:
		return {}
	var items: Array = controller.mission_manager.get_items_at_cell(get_facing_cell(controller))
	return Dictionary(items[0]) if not items.is_empty() else {}


static func build_action_target_context(controller: Variant) -> Dictionary:
	var target_position: Vector2i = get_facing_cell(controller)
	var target_object: Dictionary = get_facing_object(controller)
	if target_object.is_empty() and controller.mission_manager != null:
		var items: Array = controller.mission_manager.get_items_at_cell(target_position)
		if items.is_empty() and target_position != controller.grid_position:
			items = controller.mission_manager.get_items_at_cell(controller.grid_position)
			if not items.is_empty():
				target_position = controller.grid_position
		if not items.is_empty():
			target_object = Dictionary(items[0])
	var view_model: Dictionary = controller.build_runtime_action_view_model(target_object, target_position)
	return {"target_position": target_position, "target_object": view_model.get("target", {}), "actions": view_model.get("available_action_ids", []), "action_view_model": view_model}


static func build_connector_target_context(controller: Variant) -> Dictionary:
	return _build_action_context_for_id(build_action_target_context(controller), "connect")


static func build_heavy_claw_target_context(controller: Variant) -> Dictionary:
	return _build_action_context_for_id(build_action_target_context(controller), "push")


static func build_targeting_snapshot(controller: Variant) -> Dictionary:
	var action_target: Dictionary = build_action_target_context(controller)
	return {
		"bipob_cell": controller.grid_position,
		"facing_cell": get_facing_cell(controller),
		"facing_object": get_facing_object(controller),
		"facing_item": get_facing_item(controller),
		"action_target": action_target,
		"connector_target": _build_action_context_for_id(action_target, "connect"),
		"heavy_claw_target": _build_action_context_for_id(action_target, "push")
	}


static func _build_action_context_for_id(action_target: Dictionary, action_id: String) -> Dictionary:
	var view_model: Dictionary = Dictionary(action_target.get("action_view_model", {}))
	for descriptor_variant in Array(view_model.get("actions", [])):
		if descriptor_variant is Dictionary and String(Dictionary(descriptor_variant).get("id", "")) == action_id:
			return {
				"target_position": action_target.get("target_position", Vector2i.ZERO),
				"target_object": action_target.get("target_object", {}),
				"action": Dictionary(descriptor_variant)
			}
	return {}
