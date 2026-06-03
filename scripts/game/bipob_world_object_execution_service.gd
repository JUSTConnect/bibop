extends RefCounted
class_name BipobWorldObjectExecutionService


const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")


static func execute_world_object_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> Dictionary:
	var action_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(actor, module, world_object, action_id)), world_object, action_id)
	if not bool(action_result.get("success", false)):
		return _build_result(false, str(action_result.get("message", "Action failed.")), world_object, target_position, action_result, "action_failed")
	if not controller.can_spend_action(1, 1):
		return _build_result(false, "Not enough action/energy.", world_object, target_position, action_result, "insufficient_resources")
	if action_id == "insert_fuse" and not controller.consume_held_world_item_if_type("fuse"):
		return _build_result(false, "Manipulator does not contain a fuse.", world_object, target_position, action_result, "fuse_not_held")
	if action_id == "repair" and str(module.get("id", "")) == "repair_kit":
		controller.consume_held_world_item_if_type("repair_kit")
	var moved: bool = bool(controller._apply_world_object_effects(action_result.get("effects", []), world_object, target_position, actor))
	if not moved:
		controller.mission_manager.set_world_object_at_cell(target_position, world_object)
	if action_id == "unlock" and str(world_object.get("object_group", "")) == "door" and WorldObjectCatalogRef.normalize_access_type(world_object.get("access_type", world_object.get("lock_type", ""))) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD and controller.mission_manager.has_method("remove_keycard_if_no_door_references"):
		controller.mission_manager.call("remove_keycard_if_no_door_references", str(world_object.get("required_key_id", "")))
	_apply_explicit_power_event(controller, world_object, action_id, action_result)
	var action_message: String = str(action_result.get("message", "Action complete."))
	if str(world_object.get("object_group", "")) != "door" or action_id not in ["open", "close", "unlock"]:
		action_message = "%s (%s): %s | Action: %s" % [world_object.get("display_name", "Object"), world_object.get("state", "unknown"), action_message, action_id]
	var result: Dictionary = _build_result(true, action_message, world_object, target_position, action_result, "ok")
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["refresh_action_panel"] = true
	result["emit_facing_hint"] = true
	result["clear_selected_action"] = true
	result["pending_paid_action"] = true
	return result


static func finalize_world_object_action(controller: Variant, execution_result: Dictionary) -> void:
	if not bool(execution_result.get("pending_paid_action", false)):
		return
	controller.spend_action(1, 1)
	controller._register_successful_paid_player_action(true)
	execution_result["spent_action"] = true
	execution_result["pending_paid_action"] = false


static func _apply_explicit_power_event(controller: Variant, world_object: Dictionary, action_id: String, action_result: Dictionary) -> void:
	if action_id == "switch":
		var object_type: String = str(world_object.get("object_type", "")).strip_edges().to_lower()
		object_type = object_type.replace(" ", "_").replace("-", "_")
		if object_type in ["light_switch", "circuit_switch", "circuit_breaker", "power_switcher"]:
			var reason := "switch_toggled"
			if object_type == "circuit_breaker":
				reason = "circuit_breaker_toggled"
			var power_filter := ""
			if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
				power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", world_object))
			var apply_report: Dictionary = Dictionary(controller.apply_power_network_after_explicit_power_event(reason, power_filter))
			action_result["power_apply_report"] = apply_report
	elif action_id in ["insert_fuse", "remove_fuse"]:
		var power_filter := ""
		if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
			power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", world_object))
		var power_reason: String = "fuse_inserted" if action_id == "insert_fuse" else "fuse_removed"
		var apply_report: Dictionary = Dictionary(controller.apply_power_network_after_explicit_power_event(power_reason, power_filter))
		action_result["power_apply_report"] = apply_report


static func _build_result(success: bool, message: String, world_object: Dictionary, target_position: Vector2i, action_result: Dictionary, reason: String) -> Dictionary:
	return {
		"handled": true,
		"success": success,
		"message": message,
		"spent_action": false,
		"refresh_overlay": false,
		"refresh_threats": false,
		"refresh_action_panel": false,
		"emit_status": true,
		"emit_facing_hint": false,
		"clear_selected_action": false,
		"world_object": world_object,
		"target_position": target_position,
		"action_result": action_result,
		"pending_paid_action": false,
		"reason": reason
	}
