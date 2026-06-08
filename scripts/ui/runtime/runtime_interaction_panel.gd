extends RefCounted
class_name RuntimeInteractionPanel


static func get_target_data(ui) -> Dictionary:
	if ui.bipob == null or not ui.bipob.has_method("get_facing_world_action_target"):
		return {"target_object": {}, "actions": []}
	return ui._safe_ui_dictionary(ui.bipob.call("get_facing_world_action_target"))


static func is_connector_action(action_id: String) -> bool:
	return action_id in ["connect", "scan", "hack", "download", "activate_platform", "open_door", "close_door", "unlock_door", "apply_digital_key", "input_password"] or action_id.begins_with("access_code_")


static func is_heavy_claw_action(action_id: String) -> bool:
	return action_id in ["push", "break_breachable_wall"]


static func get_physical_actions(actions: Array) -> Array[String]:
	var physical_actions: Array[String] = []
	for action_variant in actions:
		var action_id: String = str(action_variant)
		if not action_id.is_empty() and not is_connector_action(action_id) and not is_heavy_claw_action(action_id):
			physical_actions.append(action_id)
	return physical_actions


static func get_action_descriptor(target_data: Dictionary, action_id: String) -> Dictionary:
	var view_model: Dictionary = Dictionary(target_data.get("action_view_model", {}))
	for descriptor_variant in Array(view_model.get("actions", [])):
		if descriptor_variant is Dictionary and str(Dictionary(descriptor_variant).get("id", "")) == action_id:
			return Dictionary(descriptor_variant)
	return {}


static func get_connect_descriptor(target_data: Dictionary) -> Dictionary:
	return get_action_descriptor(target_data, "connect")


static func get_heavy_claw_descriptor(target_data: Dictionary) -> Dictionary:
	var breach_descriptor: Dictionary = get_action_descriptor(target_data, "break_breachable_wall")
	if not breach_descriptor.is_empty():
		return breach_descriptor
	return get_action_descriptor(target_data, "push")


static func action_requires_manipulator(action_id: String, target_object: Dictionary) -> bool:
	if action_id == "pickup" and str(target_object.get("item_form", "physical")) == "digital":
		return false
	return action_id in ["pickup", "open", "close", "unlock", "switch", "force_open", "break_breachable_wall", "push", "pull", "repair", "cut", "impact", "take_end_1", "take_end_2", "plug_in", "plug_out", "connect_wire_end", "connect_wire_1", "connect_wire_2", "disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2"]


static func is_manipulator_blocked(ui, target_object: Dictionary, actions: Array) -> bool:
	if ui.bipob == null or not ui.bipob.has_method("can_use_physical_hand"):
		return false
	if bool(ui.bipob.call("can_use_physical_hand")):
		return false
	for action_variant in actions:
		if action_requires_manipulator(str(action_variant), target_object):
			return true
	return false


static func refresh_controls(ui) -> void:
	if ui != null and ui.has_method("_refresh_runtime_interaction_controls"):
		ui._refresh_runtime_interaction_controls()

static func enter_mode(ui) -> void:
	ui.runtime_interaction_mode_active = true
	refresh_controls(ui)


static func exit_mode(ui) -> void:
	ui.runtime_interaction_mode_active = false
	refresh_controls(ui)


static func _has_action_points(ui) -> bool:
	return ui.bipob != null and int(ui.bipob.actions_left) > 0


static func press_action(ui, action_id: String) -> void:
	if ui.bipob == null or action_id.is_empty() or not ui.bipob.has_method("set_selected_world_action") or not ui.bipob.has_method("interact"):
		print("[PRESS_ACTION_RETURN] missing bipob/method/action")
		return

	if not _has_action_points(ui):
		print("[PRESS_ACTION_RETURN] no action points")
		ui.show_hint("No actions left. End turn.")
		refresh_controls(ui)
		ui.update_status()
		return

	if not ui.runtime_interaction_mode_active:
		print("[PRESS_ACTION_ENTER_MODE]")
		enter_mode(ui)

	get_target_data(ui)

	ui.bipob.call("set_selected_world_action", action_id)

	ui.bipob.call("interact")


	refresh_controls(ui)
	ui.update_status()


static func press_interact(ui) -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	if ui.runtime_interaction_mode_active:
		exit_mode(ui)
		ui.update_status()
		return
	if not _has_action_points(ui):
		ui.show_hint("No actions left. End turn.")
		refresh_controls(ui)
		ui.update_status()
		return
	var target_data: Dictionary = get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var action_view_model: Dictionary = ui._safe_ui_dictionary(target_data.get("action_view_model", {}))
	if not target_object.is_empty() and bool(action_view_model.get("has_interaction_target", false)):
		enter_mode(ui)
		ui.show_hint("")
		ui.update_status()
		return
	if not target_object.is_empty():
		var unavailable_label: String = str(action_view_model.get("primary_action_label", ""))
		if unavailable_label.is_empty() or unavailable_label == "Action":
			unavailable_label = str(action_view_model.get("disabled_reason", ""))
		if unavailable_label.is_empty():
			unavailable_label = "No physical action available."
		ui.show_hint(unavailable_label)
		refresh_controls(ui)
		ui.update_status()
		return
	ui.show_hint("No physical action available. Face an interactable object first.")
	refresh_controls(ui)
	ui.update_status()


static func press_connect(ui) -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	if ui.bipob.has_method("is_connected_to_terminal") and bool(ui.bipob.call("is_connected_to_terminal")):
		if ui.bipob.has_method("cancel_terminal_connection"):
			var cancel_result: Dictionary = Dictionary(ui.bipob.call("cancel_terminal_connection"))
			ui.show_hint(str(cancel_result.get("message", "Terminal connection cancelled.")))
		refresh_controls(ui)
		ui.update_status()
		return
	if not _has_action_points(ui):
		ui.show_hint("No actions left. End turn.")
		refresh_controls(ui)
		ui.update_status()
		return
	var target_data: Dictionary = get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var target_position: Vector2i = Vector2i(target_data.get("target_position", Vector2i(-9999, -9999)))
	var is_terminal_target: bool = not target_object.is_empty() and str(target_object.get("object_group", "")) == "terminal"
	if is_terminal_target and bool(target_object.get("connected", false)) and ui.bipob.has_method("open_terminal_connection_mode"):
		var reopen_result: Dictionary = Dictionary(ui.bipob.call("open_terminal_connection_mode", target_position))
		ui.show_hint(str(reopen_result.get("message", "Terminal connected.")))
		refresh_controls(ui)
		ui.update_status()
		return
	var descriptor: Dictionary = get_connect_descriptor(target_data)
	if descriptor.is_empty() or not bool(descriptor.get("enabled", false)):
		ui.show_hint(str(descriptor.get("label", "Connector jack unavailable.")))
		refresh_controls(ui)
		return
	if is_terminal_target and ui.bipob.has_method("open_terminal_connection_mode"):
		var connect_result: Dictionary = Dictionary(ui.bipob.call("open_terminal_connection_mode", target_position))
		ui.show_hint(str(connect_result.get("message", "Terminal connection unavailable.")))
	else:
		ui.bipob.call("set_selected_world_action", "connect")
		ui.show_hint("Connection target selected.")
	refresh_controls(ui)
	ui.update_status()


static func press_heavy_claw(ui) -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	if ui.bipob.has_method("is_heavy_claw_drag_active") and bool(ui.bipob.call("is_heavy_claw_drag_active")):
		if ui.bipob.has_method("cancel_heavy_claw_drag"):
			var cancel_result: Dictionary = Dictionary(ui.bipob.call("cancel_heavy_claw_drag"))
			ui.show_hint(str(cancel_result.get("message", "Heavy Claw detached.")))
		refresh_controls(ui)
		ui.update_status()
		return
	if not _has_action_points(ui):
		ui.show_hint("No actions left. End turn.")
		return
	var descriptor: Dictionary = get_heavy_claw_descriptor(get_target_data(ui))
	if descriptor.is_empty() or not bool(descriptor.get("enabled", false)):
		ui.show_hint(str(descriptor.get("label", "No heavy object in front.")))
		refresh_controls(ui)
		return
	press_action(ui, str(descriptor.get("id", "push")))


static func use_selected_world_action(ui) -> void:
	if ui.bipob == null or not ui.bipob.has_method("interact"):
		return
	if not _has_action_points(ui):
		ui.show_hint("No actions left. End turn.")
		refresh_controls(ui)
		ui.update_status()
		return
	if not ui.runtime_interaction_mode_active:
		enter_mode(ui)
	ui.bipob.call("interact")
	refresh_controls(ui)
	ui.update_status()


static func select_world_action(ui, action_id: String) -> void:
	press_action(ui, action_id)
