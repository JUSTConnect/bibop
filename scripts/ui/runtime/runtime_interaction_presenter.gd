extends RefCounted
class_name RuntimeInteractionPresenter

const RuntimeInteractionPanelRef = preload("res://scripts/ui/runtime/runtime_interaction_panel.gd")
const RuntimeHeavyClawPresenterRef = preload("res://scripts/ui/runtime/runtime_heavy_claw_presenter.gd")
const BipobActionControllerRef = preload("res://scripts/bipob/bipob_action_controller.gd")
const ActionIconAtlasServiceRef = preload("res://scripts/ui/action_icon_atlas_service.gd")

const DEBUG_BREACHABLE_WALL_RUNTIME_TRACE := false


static func refresh(ui) -> void:
	if ui.runtime_action_button == null or ui.runtime_end_turn_button == null:
		return

	var target_data: Dictionary = RuntimeInteractionPanelRef.get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var action_view_model: Dictionary = ui._safe_ui_dictionary(target_data.get("action_view_model", {}))
	var actions: Array = ui._safe_ui_array(target_data.get("actions", []))
	var physical_actions: Array[String] = RuntimeInteractionPanelRef.get_physical_actions(actions, target_object)
	var connect_descriptor: Dictionary = RuntimeInteractionPanelRef.get_connect_descriptor(target_data)
	var heavy_claw_descriptor: Dictionary = RuntimeInteractionPanelRef.get_heavy_claw_descriptor(target_data)

	var is_heavy_claw_movable_target: bool = RuntimeInteractionPanelRef.is_heavy_claw_movable_target(target_object)
	var has_interactable: bool = not target_object.is_empty() and bool(action_view_model.get("has_interaction_target", false))
	var has_physical_interactable: bool = has_interactable and not is_heavy_claw_movable_target and not physical_actions.is_empty()
	_refresh_available_action_target_overlay(ui, target_data, target_object, physical_actions, connect_descriptor, heavy_claw_descriptor)

	if is_heavy_claw_movable_target:
		ui.runtime_interaction_mode_active = false
		if ui.runtime_world_actions_panel != null and is_instance_valid(ui.runtime_world_actions_panel):
			ui.runtime_world_actions_panel.visible = false

	var has_actions_left: bool = ui.bipob != null and int(ui.bipob.actions_left) > 0
	var active_channel: String = str(ui.runtime_interaction_active_channel).strip_edges().to_lower()
	
	if ui.runtime_action_button != null:
		var action_channel_active: bool = ui.runtime_interaction_mode_active and active_channel == "action"
		var action_button_label: String = "Cancel" if action_channel_active else "Act"
		ui.runtime_action_button.text = action_button_label
		ui.runtime_action_button.disabled = not (has_physical_interactable or action_channel_active)
		ui.runtime_action_button.tooltip_text = "" if has_physical_interactable or action_channel_active else ""
		ui._apply_action_button_style(
			ui.runtime_action_button,
			"danger" if action_channel_active else ("primary" if has_physical_interactable else "disabled"),
			has_physical_interactable or action_channel_active
		)
		ActionIconAtlasServiceRef.apply_icon_to_button(ui.runtime_action_button, "cancel" if action_channel_active else "manipulator_action", action_button_label, ActionIconAtlasServiceRef.CONTROL_ICON_SIZE, ActionIconAtlasServiceRef.CONTROL_BUTTON_MIN_SIZE, true, true)

		if has_physical_interactable and not ui.runtime_interaction_mode_active:
			ui._apply_selected_pulse(ui.runtime_action_button)
		else:
			ui._clear_selected_pulse(ui.runtime_action_button)
	if ui.runtime_connect_button != null:
		var terminal_connected: bool = ui.bipob != null and ui.bipob.has_method("is_connected_to_terminal") and bool(ui.bipob.call("is_connected_to_terminal"))
		var terminal_reopen_enabled: bool = not target_object.is_empty() and str(target_object.get("object_group", "")) == "terminal" and bool(target_object.get("connected", false))
		var connect_channel_active: bool = ui.runtime_interaction_mode_active and active_channel == "connect"
		var connect_enabled: bool = false

		if not is_heavy_claw_movable_target:
			connect_enabled = terminal_connected or terminal_reopen_enabled or connect_channel_active or (not connect_descriptor.is_empty() and bool(connect_descriptor.get("enabled", false)) and has_actions_left)

		var connect_button_label: String = "Cancel" if terminal_connected or connect_channel_active else "Connect"
		ui.runtime_connect_button.text = connect_button_label
		ui.runtime_connect_button.disabled = not connect_enabled
		ui.runtime_connect_button.tooltip_text = "" if connect_enabled else str(connect_descriptor.get("label", "Connector jack unavailable."))
		ui._apply_action_button_style(
			ui.runtime_connect_button,
			"danger" if terminal_connected or connect_channel_active else ("primary" if connect_enabled else "disabled"),
			connect_enabled
		)
		ActionIconAtlasServiceRef.apply_icon_to_button(ui.runtime_connect_button, "cancel" if terminal_connected or connect_channel_active else "wired_connector", connect_button_label, ActionIconAtlasServiceRef.CONTROL_ICON_SIZE, ActionIconAtlasServiceRef.CONTROL_BUTTON_MIN_SIZE, true, true)
	if ui.runtime_heavy_claw_button != null:
		var heavy_claw_drag_active: bool = ui.bipob != null and ui.bipob.has_method("is_heavy_claw_drag_active") and bool(ui.bipob.call("is_heavy_claw_drag_active"))
		var heavy_claw_channel_active: bool = ui.runtime_interaction_mode_active and active_channel == "heavy_claw"
		var heavy_claw_enabled: bool = heavy_claw_drag_active or heavy_claw_channel_active or (not heavy_claw_descriptor.is_empty() and bool(heavy_claw_descriptor.get("enabled", false)) and has_actions_left)

		var heavy_claw_button_label: String = "Cancel" if heavy_claw_drag_active or heavy_claw_channel_active else "Claw"
		ui.runtime_heavy_claw_button.text = heavy_claw_button_label
		ui.runtime_heavy_claw_button.disabled = not heavy_claw_enabled
		ui.runtime_heavy_claw_button.tooltip_text = "" if heavy_claw_enabled else str(heavy_claw_descriptor.get("label", ""))
		ui._apply_action_button_style(
			ui.runtime_heavy_claw_button,
			"danger" if heavy_claw_drag_active or heavy_claw_channel_active else ("primary" if heavy_claw_enabled else "disabled"),
			heavy_claw_enabled
		)
		ActionIconAtlasServiceRef.apply_icon_to_button(ui.runtime_heavy_claw_button, "cancel" if heavy_claw_drag_active or heavy_claw_channel_active else "heavy_claw_action", heavy_claw_button_label, ActionIconAtlasServiceRef.CONTROL_ICON_SIZE, ActionIconAtlasServiceRef.CONTROL_BUTTON_MIN_SIZE, true, true)
	if ui.runtime_cut_button != null:
		var cutter_installed: bool = ui.bipob != null and ui.bipob.has_method("has_module_id") and bool(ui.bipob.call("has_module_id", "plasma_cutter_v1"))
		var cut_context: Dictionary = BipobActionControllerRef.get_direct_cut_target_context(ui.bipob) if ui.bipob != null else {}
		var cut_target_available: bool = bool(cut_context.get("available", false))
		var cut_enabled: bool = cutter_installed and has_actions_left and cut_target_available
		ui.runtime_cut_button.visible = cutter_installed
		ui.runtime_cut_button.text = "Cut"
		ui.runtime_cut_button.disabled = not cut_enabled
		if not cutter_installed:
			ui.runtime_cut_button.tooltip_text = "Plasma Cutter required."
		elif not has_actions_left:
			ui.runtime_cut_button.tooltip_text = "Not enough action/energy."
		elif not cut_target_available:
			ui.runtime_cut_button.tooltip_text = str(cut_context.get("reason", "No cut target."))
		else:
			ui.runtime_cut_button.tooltip_text = "Cut facing cable."
		ui._apply_action_button_style(ui.runtime_cut_button, "primary" if cut_enabled else "disabled", cut_enabled)
		ActionIconAtlasServiceRef.apply_icon_to_button(ui.runtime_cut_button, "plasma_cutter", "Cut", ActionIconAtlasServiceRef.CONTROL_ICON_SIZE, ActionIconAtlasServiceRef.CONTROL_BUTTON_MIN_SIZE, true, true)
	if ui.runtime_end_turn_button != null:
		ui._apply_action_button_style(ui.runtime_end_turn_button, "reference", true)
		ActionIconAtlasServiceRef.apply_icon_to_button(ui.runtime_end_turn_button, "end_turn", "End Turn", ActionIconAtlasServiceRef.CONTROL_ICON_SIZE, ActionIconAtlasServiceRef.CONTROL_BUTTON_MIN_SIZE, true, true)

	if RuntimeHeavyClawPresenterRef.is_drag_active(ui):
		RuntimeHeavyClawPresenterRef.refresh(ui)
		return

	RuntimeHeavyClawPresenterRef.refresh(ui)

	if is_heavy_claw_movable_target:
		if ui.runtime_interaction_actions_row != null:
			ui.runtime_interaction_actions_row.visible = false
		return

	_refresh_action_row(ui, target_object, physical_actions)


static func _refresh_available_action_target_overlay(ui, target_data: Dictionary, target_object: Dictionary, physical_actions: Array[String], connect_descriptor: Dictionary, heavy_claw_descriptor: Dictionary) -> void:
	if ui == null or ui.runtime_interaction_mode_active:
		return
	if not ui.has_method("_make_runtime_selected_interaction_target") or not ui.has_method("set_runtime_selected_interaction_target") or not ui.has_method("clear_runtime_selected_interaction_target"):
		return
	if ui.bipob == null:
		ui.call("clear_runtime_selected_interaction_target")
		return
	var has_actions_left: bool = int(ui.bipob.actions_left) > 0
	if not has_actions_left:
		ui.call("clear_runtime_selected_interaction_target")
		return

	var overlay_object: Dictionary = target_object.duplicate(true)
	var action_id: String = _get_default_available_overlay_action_id(ui, target_data, physical_actions, connect_descriptor, heavy_claw_descriptor)
	if action_id.is_empty():
		var cut_context: Dictionary = BipobActionControllerRef.get_direct_cut_target_context(ui.bipob)
		if bool(cut_context.get("available", false)):
			action_id = "cut"
			overlay_object = Dictionary(cut_context.get("target_object", {})).duplicate(true)
			target_data["target_position"] = cut_context.get("target_position", target_data.get("target_position", Vector2i(-1, -1)))
	if action_id.is_empty() or overlay_object.is_empty():
		ui.call("clear_runtime_selected_interaction_target")
		return

	overlay_object["action_id"] = action_id
	var target_cell: Vector2i = ui._safe_ui_vector2i(target_data.get("target_position", overlay_object.get("position", overlay_object.get("cell", Vector2i(-1, -1)))))
	var overlay_target: Dictionary = ui.call("_make_runtime_selected_interaction_target", overlay_object, "available_action", target_cell)
	if overlay_target.is_empty():
		ui.call("clear_runtime_selected_interaction_target")
		return
	ui.call("set_runtime_selected_interaction_target", overlay_target)


static func _get_default_available_overlay_action_id(ui, target_data: Dictionary, physical_actions: Array[String], connect_descriptor: Dictionary, heavy_claw_descriptor: Dictionary) -> String:
	var available_action_ids: Array[String] = []
	for action_variant in Array(target_data.get("available_action_ids", [])):
		var action_id: String = str(action_variant).strip_edges().to_lower()
		if not action_id.is_empty() and not available_action_ids.has(action_id):
			available_action_ids.append(action_id)
	var selected_action: String = ""
	if ui.bipob != null:
		selected_action = str(ui.bipob.get("selected_world_action")).strip_edges().to_lower()
	if not selected_action.is_empty() and available_action_ids.has(selected_action):
		return selected_action
	for action_id in physical_actions:
		if available_action_ids.is_empty() or available_action_ids.has(action_id):
			return action_id
	if not connect_descriptor.is_empty() and bool(connect_descriptor.get("enabled", false)):
		return str(connect_descriptor.get("id", "connect")).strip_edges().to_lower()
	if not heavy_claw_descriptor.is_empty() and bool(heavy_claw_descriptor.get("enabled", false)):
		return str(heavy_claw_descriptor.get("id", "push")).strip_edges().to_lower()
	return ""
	
static func refresh_world_actions_panel(ui, payload: Dictionary = {}) -> void:
	var rebuild_world_actions_panel: bool = false
	if ui.runtime_world_actions_panel != null and not is_instance_valid(ui.runtime_world_actions_panel):
		ui.runtime_world_actions_panel = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_target_label != null and not is_instance_valid(ui.runtime_world_actions_target_label):
		ui.runtime_world_actions_target_label = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_state_label != null and not is_instance_valid(ui.runtime_world_actions_state_label):
		ui.runtime_world_actions_state_label = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_behavior_label != null and not is_instance_valid(ui.runtime_world_actions_behavior_label):
		ui.runtime_world_actions_behavior_label = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_list != null and not is_instance_valid(ui.runtime_world_actions_list):
		ui.runtime_world_actions_list = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_no_actions_label != null and not is_instance_valid(ui.runtime_world_actions_no_actions_label):
		ui.runtime_world_actions_no_actions_label = null
		rebuild_world_actions_panel = true
	if ui.runtime_world_actions_selected_button != null and not is_instance_valid(ui.runtime_world_actions_selected_button):
		ui.runtime_world_actions_selected_button = null
	if rebuild_world_actions_panel:
		ui.runtime_world_actions_panel = null
	if ui.runtime_world_actions_panel == null:
		if ui.has_method("_ensure_runtime_world_actions_panel"):
			ui.call("_ensure_runtime_world_actions_panel")
		elif ui.has_method("_build_runtime_world_actions_panel"):
			ui.call("_build_runtime_world_actions_panel")
	if ui.runtime_world_actions_panel == null or not is_instance_valid(ui.runtime_world_actions_panel) or ui.runtime_world_actions_target_label == null or not is_instance_valid(ui.runtime_world_actions_target_label) or ui.runtime_world_actions_state_label == null or not is_instance_valid(ui.runtime_world_actions_state_label) or ui.runtime_world_actions_behavior_label == null or not is_instance_valid(ui.runtime_world_actions_behavior_label) or ui.runtime_world_actions_list == null or not is_instance_valid(ui.runtime_world_actions_list) or ui.runtime_world_actions_no_actions_label == null or not is_instance_valid(ui.runtime_world_actions_no_actions_label):
		return
	var target_data: Dictionary = RuntimeInteractionPanelRef.get_target_data(ui)
	var target_object: Dictionary = ui._safe_ui_dictionary(target_data.get("target_object", {}))
	var action_view_model: Dictionary = ui._safe_ui_dictionary(target_data.get("action_view_model", {}))
	var action_ids: Array[String] = RuntimeInteractionPanelRef.get_physical_actions(ui._safe_ui_array(target_data.get("actions", [])), target_object)
	
	if action_ids.is_empty():
		ui.runtime_interaction_mode_active = false
		ui.runtime_interaction_active_channel = ""
		ui.runtime_world_actions_panel.visible = false
		if ui.has_method("clear_runtime_selected_interaction_target"):
			ui.call("clear_runtime_selected_interaction_target")
		_clear_runtime_world_actions_list(ui)
		return
		
	var selected_action: String = str(payload.get("selected_action", ui.last_world_action_selected if not ui.last_world_action_selected.is_empty() else ""))
	var fallback_name: String = str(target_object.get("display_name", target_object.get("name", target_object.get("label", ""))))
	var target_id: String = ui._get_runtime_world_action_target_id(target_object, fallback_name)
	var action_descriptors: Array[Dictionary] = []
	for action_id in action_ids:
		var descriptor: Dictionary = RuntimeInteractionPanelRef.get_action_descriptor(target_data, action_id)
		if descriptor.is_empty():
			descriptor = {"id": action_id, "label": action_id.capitalize(), "enabled": true, "reason": ""}
		action_descriptors.append(descriptor)
	var actions_key: String = "|".join(action_ids)
	var state_key: String = "%s|%s|%s|%s" % [str(target_object.get("state", "")), str(target_object.get("power_state", "")), str(target_object.get("connected", "")), str(target_object.get("access_code_entry", ""))]
	_trace_breachable_wall_game_ui_payload(target_object, action_ids, selected_action)
	clear_selected_action_if_stale(ui, target_id, actions_key, state_key)
	if selected_action.is_empty() or not action_ids.has(selected_action):
		selected_action = str(ui.last_world_action_selected)
	if selected_action.is_empty() or not action_ids.has(selected_action):
		selected_action = action_ids[0]
	ui.last_world_action_target_id = target_id
	ui.last_world_action_actions_key = actions_key
	ui.last_world_action_selected = selected_action
	ui.last_world_action_state_key = state_key
	_clear_runtime_world_actions_list(ui)
	var is_open: bool = ui.runtime_interaction_mode_active
	ui.runtime_world_actions_panel.visible = is_open
	if not is_open:
		if ui.has_method("clear_runtime_selected_interaction_target"):
			ui.call("clear_runtime_selected_interaction_target")
		return
	var title_text: String = fallback_name if not fallback_name.is_empty() else "Interactable"
	if not target_id.is_empty() and target_id != title_text:
		title_text = "%s (%s)" % [title_text, target_id]
	ui.runtime_world_actions_target_label.text = "Target: %s" % title_text
	var cell_text: String = "Cell: -"
	var target_cell_source: Variant = target_data.get("target_position", target_object.get("position", Vector2i(-1, -1)))
	var target_cell: Vector2i = ui._safe_ui_vector2i(target_cell_source)
	if ui.has_method("_make_runtime_selected_interaction_target") and ui.has_method("set_runtime_selected_interaction_target"):
		var selected_overlay_object: Dictionary = target_object.duplicate(true)
		selected_overlay_object["action_id"] = selected_action
		var overlay_target: Dictionary = ui.call("_make_runtime_selected_interaction_target", selected_overlay_object, "world_action_hud", target_cell)
		if not overlay_target.is_empty():
			ui.call("set_runtime_selected_interaction_target", overlay_target)
	cell_text = "Cell: (%d, %d)" % [target_cell.x, target_cell.y]
	var state_text: String = "State: %s" % str(target_object.get("state", "unknown"))
	if str(target_object.get("power_state", "")).strip_edges() != "":
		state_text += " | Power: %s" % str(target_object.get("power_state", ""))
	if str(target_object.get("connected", "")).strip_edges() != "":
		state_text += " | Connected: %s" % str(target_object.get("connected", false))
	ui.runtime_world_actions_state_label.text = "%s | %s" % [cell_text, state_text]
	var summary_bits: Array[String] = []
	if bool(action_view_model.get("has_available_action", false)):
		summary_bits.append("Available actions: %d" % int(action_view_model.get("available_action_ids", []).size()))
	else:
		summary_bits.append(str(action_view_model.get("disabled_reason", "No actions available.")))
	ui.runtime_world_actions_behavior_label.text = " | ".join(summary_bits)
	var no_actions_visible: bool = action_descriptors.is_empty()
	if no_actions_visible:
		ui.runtime_world_actions_no_actions_label.visible = true
		ui.runtime_world_actions_no_actions_label.text = str(action_view_model.get("disabled_reason", "No available actions"))
	else:
		ui.runtime_world_actions_no_actions_label.visible = false
	for descriptor in action_descriptors:
		var action_id: String = str(descriptor.get("id", ""))
		if action_id.is_empty():
			continue
		var button_label: String = action_id.capitalize()
		if ui.bipob != null and ui.bipob.has_method("get_world_action_display_label"):
			button_label = str(ui.bipob.call("get_world_action_display_label", action_id, target_object))
		if button_label.is_empty():
			button_label = action_id.capitalize()
		var action_enabled: bool = bool(descriptor.get("enabled", false))
		var action_reason: String = str(descriptor.get("reason", ""))
		var button: Button = ui._create_runtime_control_button(button_label, Callable(ui, "_on_world_action_button_pressed").bind(action_id), "primary" if action_enabled else "disabled")
		button.disabled = not action_enabled
		button.tooltip_text = button_label if action_enabled or action_reason.is_empty() else "%s — %s" % [button_label, action_reason]
		ActionIconAtlasServiceRef.apply_icon_to_button(button, action_id, button_label, ActionIconAtlasServiceRef.SUBMENU_ICON_SIZE, ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE, true, true)
		button.custom_minimum_size = Vector2(ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE) if button.get_node_or_null(ActionIconAtlasServiceRef.ICON_TEXTURE_RECT_NAME) != null else Vector2(0, 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if action_id == selected_action:
			ui.runtime_world_actions_selected_button = button
			ui._apply_selected_pulse(button)
		elif action_enabled:
			ui._clear_selected_pulse(button)
		ui.runtime_world_actions_list.add_child(button)
	var cancel_button: Button = ui._create_runtime_control_button("Cancel", Callable(ui, "_on_world_action_panel_cancel_pressed"), "danger")
	ActionIconAtlasServiceRef.apply_icon_to_button(cancel_button, "cancel", "Cancel", ActionIconAtlasServiceRef.SUBMENU_ICON_SIZE, ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE, true, true)
	cancel_button.tooltip_text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE) if cancel_button.get_node_or_null(ActionIconAtlasServiceRef.ICON_TEXTURE_RECT_NAME) != null else Vector2(0, 28)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.runtime_world_actions_list.add_child(cancel_button)


static func _trace_breachable_wall_game_ui_payload(target_object: Dictionary, actions: Array, selected_action: String) -> void:
	if not DEBUG_BREACHABLE_WALL_RUNTIME_TRACE:
		return
	var wall_archetype: String = str(target_object.get("wall_archetype", "")).strip_edges().to_lower()
	var is_breachable: bool = bool(target_object.get("is_breachable_wall", false)) or wall_archetype == "breachable"
	if not is_breachable:
		return
	var trace: Dictionary = {
		"target_position": target_object.get("position", Vector2i(-1, -1)),
		"object_group": str(target_object.get("object_group", "")),
		"object_type": str(target_object.get("object_type", "")),
		"wall_archetype": wall_archetype,
		"breach_side": str(target_object.get("breach_side", "")),
		"state": str(target_object.get("state", "")),
		"breach_state": str(target_object.get("breach_state", "")),
		"actions_received": actions,
		"selected_action": selected_action
	}
	print("[breachable_wall_game_ui] %s" % var_to_str(trace))


static func _clear_runtime_world_actions_list(ui) -> void:
	if ui.runtime_world_actions_list != null and not is_instance_valid(ui.runtime_world_actions_list):
		ui.runtime_world_actions_list = null
		ui.runtime_world_actions_selected_button = null
	if ui.runtime_world_actions_list == null:
		return
	for child in ui.runtime_world_actions_list.get_children():
		child.queue_free()
	ui.runtime_world_actions_selected_button = null


static func clear_selected_action_if_stale(ui, target_id: String, actions_key: String, state_key: String) -> void:
	var target_changed: bool = not ui.last_world_action_target_id.is_empty() and ui.last_world_action_target_id != target_id
	var actions_changed: bool = not ui.last_world_action_actions_key.is_empty() and ui.last_world_action_actions_key != actions_key
	var state_changed: bool = not ui.last_world_action_state_key.is_empty() and ui.last_world_action_state_key != state_key
	if not target_changed and not actions_changed and not state_changed:
		return
	ui.last_world_action_selected = ""
	if ui.runtime_world_actions_selected_button != null and is_instance_valid(ui.runtime_world_actions_selected_button):
		ui._clear_selected_pulse(ui.runtime_world_actions_selected_button)
	ui.runtime_world_actions_selected_button = null


static func on_action_pressed(ui) -> void:
	RuntimeInteractionPanelRef.press_interact(ui)


static func on_connect_pressed(ui) -> void:
	RuntimeInteractionPanelRef.press_connect(ui)


static func on_heavy_claw_pressed(ui) -> void:
	RuntimeInteractionPanelRef.press_heavy_claw(ui)


static func on_runtime_action_pressed(ui, action_id: String) -> void:
	RuntimeInteractionPanelRef.press_action(ui, action_id)


static func on_use_selected_world_action_pressed(ui) -> void:
	RuntimeInteractionPanelRef.use_selected_world_action(ui)


static func on_world_action_cancel_pressed(ui) -> void:
	RuntimeInteractionPanelRef.exit_mode(ui)
	ui.update_status()


static func on_world_action_button_pressed(ui, action_id: String) -> void:
	RuntimeInteractionPanelRef.press_action(ui, action_id)


static func _refresh_action_row(ui, target_object: Dictionary, physical_actions: Array[String]) -> void:
	if ui.runtime_interaction_actions_row == null:
		return
	var terminal_connected: bool = ui.bipob != null and ui.bipob.has_method("is_connected_to_terminal") and bool(ui.bipob.call("is_connected_to_terminal"))
	if terminal_connected:
		_refresh_terminal_action_row(ui)
		return
	var action_id_texts: Array[String] = []
	for signature_action_variant in physical_actions:
		action_id_texts.append(str(signature_action_variant))
	var access_code_entry: String = str(target_object.get("access_code_entry", ""))
	var next_signature: String = "%s|%s|%s" % [str(ui.runtime_interaction_mode_active), "|".join(action_id_texts), access_code_entry]
	if next_signature == ui.runtime_interaction_actions_signature:
		ui.runtime_interaction_actions_row.visible = ui.runtime_interaction_mode_active
		return
	ui.runtime_interaction_actions_signature = next_signature
	for child in ui.runtime_interaction_actions_row.get_children():
		child.queue_free()
	ui.runtime_interaction_actions_row.visible = ui.runtime_interaction_mode_active
	if not ui.runtime_interaction_mode_active:
		return
	if str(target_object.get("access_type", "")) == "access_code" and bool(target_object.get("connected", false)):
		var keypad_display := Label.new()
		keypad_display.name = "RuntimeAccessCodeDisplay"
		keypad_display.text = "Code: %s" % (access_code_entry + "_".repeat(maxi(0, 4 - access_code_entry.length())))
		keypad_display.tooltip_text = "Enter four digits, then press Input."
		ui.runtime_interaction_actions_row.add_child(keypad_display)
	for leading_column_index in range(2):
		var leading_spacer := Control.new()
		leading_spacer.name = "RuntimeInteractionActionSpacer%d" % (leading_column_index + 1)
		leading_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		leading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.runtime_interaction_actions_row.add_child(leading_spacer)
	for action_variant in physical_actions:
		var action_id: String = str(action_variant)
		if action_id.is_empty():
			continue
		var action_label: String = action_id.capitalize()
		if ui.bipob != null and ui.bipob.has_method("get_world_action_display_label"):
			action_label = str(ui.bipob.call("get_world_action_display_label", action_id, target_object))
		var button: Button = ui._create_runtime_control_button(action_label, Callable(ui, "_on_runtime_interaction_action_pressed").bind(action_id), "primary")
		ActionIconAtlasServiceRef.apply_icon_to_button(button, action_id, action_label, ActionIconAtlasServiceRef.SUBMENU_ICON_SIZE, ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE, true, true)
		button.custom_minimum_size = Vector2(ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE)
		ui._apply_selected_pulse(button)
		ui.runtime_interaction_actions_row.add_child(button)
	for trailing_column_index in range(max(0, 2 - physical_actions.size())):
		var trailing_spacer := Control.new()
		trailing_spacer.name = "RuntimeInteractionActionTrailingSpacer%d" % (trailing_column_index + 1)
		trailing_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		trailing_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.runtime_interaction_actions_row.add_child(trailing_spacer)


static func _refresh_terminal_action_row(ui) -> void:
	var has_actions_left: bool = ui.bipob != null and int(ui.bipob.actions_left) > 0
	var next_signature: String = "terminal|%s" % str(has_actions_left)
	if next_signature == ui.runtime_interaction_actions_signature:
		ui.runtime_interaction_actions_row.visible = true
		return
	ui.runtime_interaction_actions_signature = next_signature
	for child in ui.runtime_interaction_actions_row.get_children():
		child.queue_free()
	ui.runtime_interaction_actions_row.visible = true
	for leading_column_index in range(3):
		var leading_spacer := Control.new()
		leading_spacer.name = "RuntimeTerminalActionSpacer%d" % (leading_column_index + 1)
		leading_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
		leading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.runtime_interaction_actions_row.add_child(leading_spacer)
	var scan_button: Button = ui._create_runtime_control_button("Scan", Callable(ui, "_on_scan_device_button_pressed"), "primary" if has_actions_left else "disabled")
	scan_button.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
	scan_button.disabled = not has_actions_left
	scan_button.tooltip_text = "Scan" if has_actions_left else "Scan — No actions left. End turn."
	ActionIconAtlasServiceRef.apply_icon_to_button(scan_button, "device_scanner", "Scan", ActionIconAtlasServiceRef.SUBMENU_ICON_SIZE, ActionIconAtlasServiceRef.SUBMENU_BUTTON_MIN_SIZE, true, true)
	if has_actions_left:
		ui._apply_selected_pulse(scan_button)
	ui.runtime_interaction_actions_row.add_child(scan_button)
	var trailing_spacer := Control.new()
	trailing_spacer.name = "RuntimeTerminalActionTrailingSpacer"
	trailing_spacer.custom_minimum_size = ui.runtime_action_button.custom_minimum_size
	trailing_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.runtime_interaction_actions_row.add_child(trailing_spacer)
