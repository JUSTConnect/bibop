extends RefCounted
class_name BipobActionController

const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const BipobActionViewModelServiceRef = preload("res://scripts/game/bipob_action_view_model_service.gd")
const BipobHeavyClawExecutionServiceRef = preload("res://scripts/game/bipob_heavy_claw_execution_service.gd")
const BipobItemPickupExecutionServiceRef = preload("res://scripts/game/bipob_item_pickup_execution_service.gd")
const BipobRuntimeActionActorServiceRef = preload("res://scripts/game/bipob_runtime_action_actor_service.gd")
const BipobTargetingServiceRef = preload("res://scripts/game/bipob_targeting_service.gd")
const BipobTerminalControlExecutionServiceRef = preload("res://scripts/game/bipob_terminal_control_execution_service.gd")
const BipobWorldObjectExecutionServiceRef = preload("res://scripts/game/bipob_world_object_execution_service.gd")


static func get_facing_world_action_target(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.build_action_target_context(controller)


static func get_facing_world_object(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.get_facing_object(controller)


static func get_facing_world_item(controller: Variant) -> Dictionary:
	return BipobTargetingServiceRef.get_facing_item(controller)


static func build_runtime_action_actor(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	return BipobRuntimeActionActorServiceRef.build_runtime_action_actor(controller, target_object, target_position)


static func build_runtime_action_view_model(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	return BipobActionViewModelServiceRef.build_runtime_action_view_model(controller, target_object, target_position)


static func validate_runtime_action_view_model(view_model: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var actions: Array = view_model.get("actions", [])
	var action_ids: Array[String] = []
	for action_variant in actions:
		if not action_variant is Dictionary:
			warnings.append("Action descriptor is not a dictionary.")
			continue
		var action: Dictionary = action_variant
		for required_field in ["id", "label", "enabled", "reason"]:
			if not action.has(required_field):
				warnings.append("Action descriptor missing %s." % required_field)
		var action_id: String = str(action.get("id", ""))
		if action_id.is_empty():
			warnings.append("Action descriptor has no executable id.")
		else:
			action_ids.append(action_id)
		if not bool(action.get("enabled", false)) and str(action.get("reason", "")).is_empty():
			warnings.append("Disabled action %s has no reason." % action_id)
	var primary_action_id: String = str(view_model.get("primary_action_id", ""))
	if not primary_action_id.is_empty() and not action_ids.has(primary_action_id):
		warnings.append("Primary action is absent from actions.")
	return warnings


static func set_selected_world_action(controller: Variant, action_id: String) -> void:
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var actions: Array[String] = target_data.get("actions", [])
	if action_id.is_empty() or actions.is_empty() or not actions.has(action_id):
		controller.selected_world_action = ""
		if not action_id.is_empty():
			controller.hint_requested.emit("Selected action is not available for this target.")
	else:
		controller.selected_world_action = action_id
	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()


static func refresh_world_action_panel(controller: Variant) -> void:
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var target_object: Dictionary = Dictionary(target_data.get("target_object", {}))
	var actions: Array = Array(target_data.get("actions", []))
	if target_object.is_empty():
		controller.selected_world_action = ""
		controller.world_action_panel_requested.emit({}, [], "")
		return
	if actions.is_empty() or not actions.has(controller.selected_world_action):
		controller.selected_world_action = ""
	controller.world_action_panel_requested.emit(target_object, actions, controller.selected_world_action)


static func cycle_selected_world_action(controller: Variant) -> void:
	var target_data: Dictionary = get_facing_world_action_target(controller)
	var actions: Array[String] = target_data.get("actions", [])
	if actions.is_empty():
		controller.selected_world_action = ""
		var view_model: Dictionary = Dictionary(target_data.get("action_view_model", {}))
		var unavailable_label: String = str(view_model.get("primary_action_label", ""))
		controller.hint_requested.emit(unavailable_label if not unavailable_label.is_empty() and unavailable_label != "Action" else "No available action for this object.")
		refresh_world_action_panel(controller)
		controller.status_changed.emit()
		return
	if controller.selected_world_action.is_empty() or not actions.has(controller.selected_world_action):
		controller.selected_world_action = actions[0]
	else:
		var selected_action_index: int = actions.find(controller.selected_world_action)
		controller.selected_world_action = actions[(selected_action_index + 1) % actions.size()]
	controller.emit_facing_world_object_hint()
	refresh_world_action_panel(controller)
	controller.status_changed.emit()


static func clear_selected_world_action_if_invalid(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> void:
	if target_object.is_empty():
		controller.selected_world_action = ""
		return
	var view_model: Dictionary = build_runtime_action_view_model(controller, target_object, target_position)
	var actions: Array = Array(view_model.get("available_action_ids", []))
	if actions.is_empty() or not actions.has(controller.selected_world_action):
		controller.selected_world_action = ""


static func get_world_object_action_for_context(controller: Variant, world_object: Dictionary, target_position: Vector2i) -> String:
	var view_model: Dictionary = build_runtime_action_view_model(controller, world_object, target_position)
	var actions: Array = Array(view_model.get("available_action_ids", []))
	if not controller.selected_world_action.is_empty() and actions.has(controller.selected_world_action):
		if not _is_connector_workflow_action(controller.selected_world_action) or bool(controller.allow_connector_workflow_action_once):
			return controller.selected_world_action
	for action_variant in actions:
		var action_id: String = str(action_variant)
		if not _is_connector_workflow_action(action_id):
			return action_id
	return ""


static func _is_connector_workflow_action(action_id: String) -> bool:
	return action_id in ["connect", "scan", "hack", "download", "activate_platform", "open_door", "close_door", "unlock_door", "apply_digital_key", "input_password"] or action_id.begins_with("access_code_")


static func handle_runtime_action_interact(controller: Variant, target_position: Vector2i, _target_tile: int) -> bool:
	if controller.mission_manager == null:
		return false
	var active_manipulator: Variant = controller.get_best_manipulator_for_interaction(target_position)
	var pickup_execution: Dictionary = BipobItemPickupExecutionServiceRef.try_pickup_adjacent_or_current_item(controller, target_position, active_manipulator)
	if bool(pickup_execution.get("handled", false)):
		_apply_pickup_execution(controller, pickup_execution, target_position)
		return true

	var world_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(target_position))
	if world_object.is_empty():
		return false
	_execute_world_object_action(controller, world_object, target_position, active_manipulator)
	return true


static func _apply_pickup_execution(controller: Variant, pickup_execution: Dictionary, target_position: Vector2i) -> void:
	controller.hint_requested.emit(str(pickup_execution.get("message", "Pickup failed.")))
	if bool(pickup_execution.get("clear_selected_action", false)):
		clear_selected_world_action_if_invalid(controller, {}, Vector2i(pickup_execution.get("item_cell", target_position)))
	if bool(pickup_execution.get("refresh_threats", false)):
		controller.update_threat_detection_preview()
	if bool(pickup_execution.get("emit_facing_hint", false)):
		controller.emit_facing_world_object_hint()
	if bool(pickup_execution.get("refresh_action_panel", false)):
		refresh_world_action_panel(controller)
	if bool(pickup_execution.get("emit_status", true)):
		controller.status_changed.emit()


static func _execute_world_object_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, _active_manipulator: Variant) -> void:
	var target_platform: Dictionary = Dictionary(controller.mission_manager.get_platform_for_cell(target_position))
	if str(world_object.get("object_group", "")) == "platform":
		target_platform = world_object
	var actor: Dictionary = build_runtime_action_actor(controller, world_object, target_position)
	actor["platform_switch_access"] = controller.mission_manager.can_bipob_access_platform_switch(target_platform, controller.grid_position, controller.get_direction_id(controller.direction))
	var action_id: String = get_world_object_action_for_context(controller, world_object, target_position)
	controller.allow_connector_workflow_action_once = false
	var module: Dictionary = Dictionary(controller.get_world_action_module(action_id, world_object))
	if str(world_object.get("object_group", "")) == "terminal" and (action_id == "hack" or action_id == "activate_platform") and not controller._is_terminal_powered_for_interaction(world_object):
		controller.hint_requested.emit("Terminal is unpowered.")
		controller.status_changed.emit()
		return
	if str(world_object.get("object_group", "")) == "platform":
		if str(world_object.get("state", "active")) in ["unpowered", "disabled"] or not bool(world_object.get("is_powered", true)):
			controller.hint_requested.emit("Platform is unpowered.")
			controller.status_changed.emit()
			return
	if action_id in ["plug_in", "connect_wire_end", "connect_wire_1", "connect_wire_2"] and not controller._has_manipulator_cable_end():
		controller.hint_requested.emit("Cable reel wire end not found.")
		controller.status_changed.emit()
		return
	if action_id == "unlock" and WorldObjectCatalogRef.normalize_access_type(world_object.get("access_type", world_object.get("lock_type", ""))) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD and not controller.can_use_physical_hand():
		controller.hint_requested.emit("Free manipulator required.")
		controller.status_changed.emit()
		return
	if action_id.is_empty():
		_emit_no_action_available(controller, world_object, target_position)
		return
	if controller.mission_manager.has_method("build_device_interaction_preflight"):
		var preflight_variant: Variant = controller.mission_manager.call("build_device_interaction_preflight", world_object, target_position, action_id, actor)
		if typeof(preflight_variant) == TYPE_DICTIONARY:
			var preflight: Dictionary = preflight_variant
			if not bool(preflight.get("preflight_ok", false)):
				controller.hint_requested.emit(str(preflight.get("message", "Action unavailable.")))
				controller.status_changed.emit()
				return
	if str(world_object.get("object_group", "")) == "terminal" and action_id in ["open_door", "close_door", "unlock_door"]:
		_apply_terminal_control_execution(controller, world_object, target_position, action_id)
		return
	if action_id in ["push", "pull"] and WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object):
		_apply_heavy_claw_execution(controller, world_object, target_position, actor, module, action_id)
		return
	_apply_world_execution(controller, world_object, target_position, actor, module, action_id)


static func _emit_no_action_available(controller: Variant, world_object: Dictionary, target_position: Vector2i) -> void:
	var unavailable_view_model: Dictionary = build_runtime_action_view_model(controller, world_object, target_position)
	var unavailable_label: String = str(unavailable_view_model.get("primary_action_label", ""))
	if WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object) and not controller.has_heavy_claw_capability():
		controller.hint_requested.emit("Heavy Claw required.")
	elif not unavailable_label.is_empty() and unavailable_label != "Action":
		controller.hint_requested.emit(unavailable_label)
	else:
		controller.hint_requested.emit("No available action for this object.")
	controller.status_changed.emit()


static func _apply_terminal_control_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> void:
	var terminal_execution: Dictionary = BipobTerminalControlExecutionServiceRef.execute_terminal_control_action(controller, world_object, target_position, action_id)
	controller.hint_requested.emit(str(terminal_execution.get("message", "Door control unavailable.")))
	if bool(terminal_execution.get("refresh_action_panel", true)):
		refresh_world_action_panel(controller)
	if bool(terminal_execution.get("emit_status", true)):
		controller.status_changed.emit()


static func _apply_heavy_claw_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> void:
	var claw_action_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(actor, module, world_object, action_id)), world_object, action_id)
	if not bool(claw_action_result.get("success", false)):
		controller.hint_requested.emit(str(claw_action_result.get("message", "Action failed.")))
		controller.status_changed.emit()
		return
	if not controller.can_spend_action(1, 1):
		controller.hint_requested.emit("Not enough action/energy.")
		controller.status_changed.emit()
		return
	var claw_execution: Dictionary = BipobHeavyClawExecutionServiceRef.execute_heavy_claw_action(controller, world_object, target_position, action_id)
	controller.hint_requested.emit(str(claw_execution.get("message", "Cannot move object there.")))
	_apply_action_execution_refresh(controller, claw_execution)


static func _apply_world_execution(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> void:
	var world_execution: Dictionary = BipobWorldObjectExecutionServiceRef.execute_world_object_action(controller, world_object, target_position, actor, module, action_id)
	if bool(world_execution.get("clear_selected_action", false)):
		clear_selected_world_action_if_invalid(controller, Dictionary(world_execution.get("world_object", world_object)), target_position)
	BipobWorldObjectExecutionServiceRef.finalize_world_object_action(controller, world_execution)
	controller.hint_requested.emit(str(world_execution.get("message", "Action failed.")))
	_apply_action_execution_refresh(controller, world_execution)


static func _apply_action_execution_refresh(controller: Variant, execution: Dictionary) -> void:
	if bool(execution.get("refresh_overlay", false)):
		controller.refresh_world_object_overlay()
	if bool(execution.get("refresh_threats", false)):
		controller.update_threat_detection_preview()
	if bool(execution.get("emit_facing_hint", false)):
		controller.emit_facing_world_object_hint()
	if bool(execution.get("refresh_action_panel", false)):
		refresh_world_action_panel(controller)
	if bool(execution.get("emit_status", true)):
		controller.status_changed.emit()
