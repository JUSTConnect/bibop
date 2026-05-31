extends RefCounted
class_name RuntimeInteractionPanel


static func get_target_data(ui) -> Dictionary:
	if ui.bipob == null or not ui.bipob.has_method("get_facing_world_action_target"):
		return {"target_object": {}, "actions": []}
	return ui._safe_ui_dictionary(ui.bipob.call("get_facing_world_action_target"))


static func action_requires_manipulator(action_id: String, target_object: Dictionary) -> bool:
	if action_id == "pickup" and String(target_object.get("item_form", "physical")) == "digital":
		return false
	return action_id in ["pickup", "open", "close", "unlock", "switch", "force_open", "push", "pull", "insert_fuse", "repair", "cut", "impact", "take_end_1", "take_end_2", "plug_in", "plug_out", "connect_wire_end", "connect_wire_1", "connect_wire_2", "disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2"]


static func is_manipulator_blocked(ui, target_object: Dictionary, actions: Array) -> bool:
	if ui.bipob == null or not ui.bipob.has_method("can_use_physical_hand"):
		return false
	if bool(ui.bipob.call("can_use_physical_hand")):
		return false
	for action_variant in actions:
		if action_requires_manipulator(String(action_variant), target_object):
			return true
	return false


static func refresh_controls(ui) -> void:
	if ui.runtime_action_button == null or ui.runtime_end_turn_button == null:
		return
	var target_data: Dictionary = get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var actions: Array = ui._safe_ui_array(target_data.get("actions", []))
	var has_interactable: bool = not target_object.is_empty() and not actions.is_empty()
	if has_interactable and not ui.runtime_interaction_mode_active and ui.runtime_action_button != null:
		ui._apply_selected_pulse(ui.runtime_action_button)
	var has_actions_left: bool = ui.bipob != null and int(ui.bipob.actions_left) > 0
	if ui.runtime_interaction_mode_active and (not has_interactable or not has_actions_left):
		ui.runtime_interaction_mode_active = false
	if ui.runtime_action_button != null:
		ui.runtime_action_button.text = "Cancel" if ui.runtime_interaction_mode_active else "Action"
		ui._apply_action_button_style(ui.runtime_action_button, "danger" if ui.runtime_interaction_mode_active else "primary", true)
		if ui.runtime_interaction_mode_active:
			ui._apply_selected_pulse(ui.runtime_action_button)
	if ui.runtime_end_turn_button != null:
		ui._apply_action_button_style(ui.runtime_end_turn_button, "reference", true)
	if ui.runtime_interaction_actions_row == null:
		return
	var action_id_texts: Array[String] = []
	for signature_action_variant in actions:
		action_id_texts.append(String(signature_action_variant))
	var next_signature: String = "%s|%s" % [str(ui.runtime_interaction_mode_active), "|".join(action_id_texts)]
	if next_signature == ui.runtime_interaction_actions_signature:
		ui.runtime_interaction_actions_row.visible = ui.runtime_interaction_mode_active
		return
	ui.runtime_interaction_actions_signature = next_signature
	for child in ui.runtime_interaction_actions_row.get_children():
		child.queue_free()
	ui.runtime_interaction_actions_row.visible = ui.runtime_interaction_mode_active
	if not ui.runtime_interaction_mode_active:
		return
	for leading_column_index in range(2):
		var leading_spacer := Control.new()
		leading_spacer.name = "RuntimeInteractionActionSpacer%d" % (leading_column_index + 1)
		leading_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		leading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.runtime_interaction_actions_row.add_child(leading_spacer)
	for action_variant in actions:
		var action_id: String = String(action_variant)
		if action_id.is_empty():
			continue
		var action_label: String = action_id.capitalize()
		if ui.bipob != null and ui.bipob.has_method("get_world_action_display_label"):
			action_label = String(ui.bipob.call("get_world_action_display_label", action_id, target_object))
		var button :Button = ui._create_runtime_control_button(action_label, Callable(ui, "_on_runtime_interaction_action_pressed").bind(action_id), "primary")
		button.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		ui._apply_selected_pulse(button)
		ui.runtime_interaction_actions_row.add_child(button)
	for trailing_column_index in range(max(0, 2 - actions.size())):
		var trailing_spacer := Control.new()
		trailing_spacer.name = "RuntimeInteractionActionTrailingSpacer%d" % (trailing_column_index + 1)
		trailing_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		trailing_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.runtime_interaction_actions_row.add_child(trailing_spacer)


static func enter_mode(ui) -> void:
	ui.runtime_interaction_mode_active = true
	refresh_controls(ui)


static func exit_mode(ui) -> void:
	ui.runtime_interaction_mode_active = false
	refresh_controls(ui)


static func press_action(ui, action_id: String) -> void:
	if ui.bipob == null or action_id.is_empty() or not ui.bipob.has_method("set_selected_world_action") or not ui.bipob.has_method("interact"):
		return
	ui.bipob.call("set_selected_world_action", action_id)
	ui.bipob.call("interact")
	exit_mode(ui)
	ui.update_status()


static func press_interact(ui) -> void:
	if ui.map_constructor_mode_active or ui.bipob == null:
		return
	if ui.runtime_interaction_mode_active:
		exit_mode(ui)
		return
	var target_data: Dictionary = get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var actions: Array = ui._safe_ui_array(target_data.get("actions", []))
	if int(ui.bipob.actions_left) <= 0:
		ui.show_hint("No actions left. End turn.")
		return
	if not target_object.is_empty() and not actions.is_empty():
		if is_manipulator_blocked(ui, target_object, actions):
			ui.show_hint("Free manipulator required.")
			refresh_controls(ui)
			return
		enter_mode(ui)
		return
	if ui.bipob.has_method("interact"):
		ui.bipob.call("interact")
	ui.update_status()


static func use_selected_world_action(ui) -> void:
	if ui.bipob == null or not ui.bipob.has_method("interact"):
		return
	ui.bipob.call("interact")
	ui.update_status()


static func select_world_action(ui, action_id: String) -> void:
	if ui.bipob == null or action_id.is_empty() or not ui.bipob.has_method("set_selected_world_action"):
		return
	ui.bipob.call("set_selected_world_action", action_id)
