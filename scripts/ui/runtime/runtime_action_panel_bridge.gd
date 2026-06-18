extends RefCounted
class_name RuntimeActionPanelBridge

const RuntimeControlPanelRef = preload("res://scripts/ui/runtime/runtime_control_panel.gd")
const RuntimeInteractionPanelRef = preload("res://scripts/ui/runtime/runtime_interaction_panel.gd")
const RuntimeInteractionPresenterRef = preload("res://scripts/ui/runtime/runtime_interaction_presenter.gd")
const RuntimeNotificationsRef = preload("res://scripts/ui/runtime/runtime_notifications.gd")
const RuntimeHeavyClawPresenterRef = preload("res://scripts/ui/runtime/runtime_heavy_claw_presenter.gd")

const RESOURCE_COLOR_HIGH: Color = Color(0.250, 0.850, 0.480, 1.0)
const RESOURCE_COLOR_MID: Color = Color(0.950, 0.720, 0.180, 1.0)
const RESOURCE_COLOR_LOW: Color = Color(0.950, 0.250, 0.250, 1.0)
const RESOURCE_OUTLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.72)

var ui = null


func _init(ui_owner) -> void:
	ui = ui_owner


func build_control_panel() -> Control:
	return RuntimeControlPanelRef.build(ui, self)


func get_target_data() -> Dictionary:
	return RuntimeInteractionPanelRef.get_target_data(ui)


func get_action_view_model() -> Dictionary:
	var target_data: Dictionary = get_target_data()
	return ui._safe_ui_dictionary(target_data.get("action_view_model", {}))


func action_requires_manipulator(action_id: String, target_object: Dictionary) -> bool:
	return RuntimeInteractionPanelRef.action_requires_manipulator(action_id, target_object)


func is_manipulator_blocked(target_object: Dictionary, actions: Array) -> bool:
	return RuntimeInteractionPanelRef.is_manipulator_blocked(ui, target_object, actions)


func _get_resource_ratio(current_value: int, max_value: int) -> float:
	if max_value <= 0:
		return 1.0
	return clampf(float(current_value) / float(max_value), 0.0, 1.0)


func _get_resource_gradient_color(current_value: int, max_value: int) -> Color:
	var ratio: float = _get_resource_ratio(current_value, max_value)
	if ratio >= 0.5:
		return RESOURCE_COLOR_MID.lerp(RESOURCE_COLOR_HIGH, (ratio - 0.5) * 2.0)
	return RESOURCE_COLOR_LOW.lerp(RESOURCE_COLOR_MID, ratio * 2.0)


func _apply_resource_label_style(label: Label, current_value: int, max_value: int) -> void:
	if label == null or not is_instance_valid(label):
		return
	var resource_color: Color = _get_resource_gradient_color(current_value, max_value)
	label.add_theme_color_override("font_color", resource_color)
	label.add_theme_color_override("font_outline_color", RESOURCE_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 1)


func _apply_runtime_resource_label_styles() -> void:
	if ui == null or ui.bipob == null:
		return
	_apply_resource_label_style(ui.runtime_energy_label, int(ui.bipob.energy), maxi(int(ui.bipob.max_energy), 1))
	_apply_resource_label_style(ui.runtime_actions_label, int(ui.bipob.actions_left), maxi(int(ui.bipob.actions_per_turn), 1))


func _ensure_runtime_control_menu_visible() -> void:
	if ui == null or ui.runtime_hud_root == null or not is_instance_valid(ui.runtime_hud_root):
		return
	var bottom_left: Control = ui.runtime_hud_root.get_node_or_null("RuntimeBottomLeft") as Control
	if bottom_left != null and is_instance_valid(bottom_left):
		bottom_left.visible = true
		bottom_left.z_index = ui.Z_RUNTIME_HUD + 8 if "Z_RUNTIME_HUD" in ui else 58
		bottom_left.z_as_relative = false
		bottom_left.mouse_filter = Control.MOUSE_FILTER_PASS
		ui.runtime_hud_root.move_child(bottom_left, ui.runtime_hud_root.get_child_count() - 1)
	var controls_panel: Control = null
	if bottom_left != null and is_instance_valid(bottom_left):
		controls_panel = bottom_left.get_node_or_null("RuntimeControlsPanel") as Control
	if controls_panel != null and is_instance_valid(controls_panel):
		controls_panel.visible = true
		controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var base_row: Control = null
	if ui.runtime_base_controls_grid != null and is_instance_valid(ui.runtime_base_controls_grid):
		base_row = ui.runtime_base_controls_grid
	elif controls_panel != null and is_instance_valid(controls_panel):
		base_row = controls_panel.find_child("RuntimeBaseControlRow", true, false) as Control
	if base_row != null and is_instance_valid(base_row):
		base_row.visible = true
		base_row.mouse_filter = Control.MOUSE_FILTER_PASS
	for button in [ui.runtime_turn_left_button, ui.runtime_turn_right_button, ui.runtime_action_button, ui.runtime_connect_button, ui.runtime_heavy_claw_button, ui.runtime_end_turn_button]:
		if button != null and is_instance_valid(button):
			button.visible = true
			button.mouse_filter = Control.MOUSE_FILTER_STOP


func refresh_controls() -> void:
	_ensure_runtime_control_menu_visible()
	_apply_runtime_resource_label_styles()
	RuntimeInteractionPresenterRef.refresh(ui)
	_ensure_runtime_control_menu_visible()
	if ui != null and ui.has_method("_update_runtime_bottom_left_layout"):
		ui.call("_update_runtime_bottom_left_layout")
		ui.call_deferred("_update_runtime_bottom_left_layout")


func enter_interaction_mode() -> void:
	RuntimeInteractionPanelRef.enter_mode(ui)


func exit_interaction_mode() -> void:
	RuntimeInteractionPanelRef.exit_mode(ui)


func process_feedback(delta: float) -> void:
	if ui.app_screen_mode != ui.AppScreenMode.GAMEPLAY:
		return

	RuntimeNotificationsRef.process_runtime_notification_timer(ui, delta)

	if ui.bipob == null:
		return

	refresh_controls()

	if RuntimeHeavyClawPresenterRef.is_drag_active(ui):
		return

	var target_data: Dictionary = get_target_data()
	var target_object: Dictionary = Dictionary(target_data.get("target_object", {}))
	var action_view_model: Dictionary = get_action_view_model()
	var actions: Array = Array(target_data.get("actions", []))
	var physical_actions: Array[String] = RuntimeInteractionPanelRef.get_physical_actions(actions, target_object)
	var heavy_claw_descriptor: Dictionary = RuntimeInteractionPanelRef.get_heavy_claw_descriptor(target_data)

	var is_heavy_claw_movable_target: bool = RuntimeInteractionPanelRef.is_heavy_claw_movable_target(target_object)
	var has_interactable: bool = not target_object.is_empty() and bool(action_view_model.get("has_interaction_target", false))
	var has_physical_interactable: bool = has_interactable and not is_heavy_claw_movable_target and not physical_actions.is_empty()

	var has_actions_left: bool = int(ui.bipob.actions_left) > 0
	var manipulator_blocked: bool = has_physical_interactable and is_manipulator_blocked(target_object, physical_actions)
	var heavy_claw_available: bool = not heavy_claw_descriptor.is_empty() and bool(heavy_claw_descriptor.get("enabled", false)) and has_actions_left
	var pulse_alpha: float = 0.72 + 0.28 * abs(sin(float(Time.get_ticks_msec()) / 170.0))

	if ui.runtime_action_button != null:
		if manipulator_blocked and has_actions_left:
			ui.runtime_action_button.modulate = Color(1.0, 0.38, 0.38, 1.0)
		elif has_physical_interactable and has_actions_left and not ui.runtime_interaction_mode_active:
			ui.runtime_action_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			ui._clear_selected_pulse(ui.runtime_action_button)

	if ui.runtime_heavy_claw_button != null:
		if is_heavy_claw_movable_target and heavy_claw_available:
			ui.runtime_heavy_claw_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			ui._clear_selected_pulse(ui.runtime_heavy_claw_button)

	if ui.runtime_end_turn_button != null:
		if ui.bipob != null and int(ui.bipob.actions_left) <= 0:
			ui.runtime_end_turn_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			ui.runtime_end_turn_button.modulate = Color.WHITE

func on_move_forward_pressed() -> void:
	RuntimeHeavyClawPresenterRef.on_forward_pressed(ui)


func on_move_backward_pressed() -> void:
	RuntimeHeavyClawPresenterRef.on_back_pressed(ui)


func on_heavy_claw_drag_cancel_pressed() -> void:
	RuntimeHeavyClawPresenterRef.on_cancel_pressed(ui)


func _close_interaction_before_direction_change() -> void:
	if ui.runtime_interaction_mode_active:
		RuntimeInteractionPanelRef.exit_mode(ui)


func on_turn_left_pressed() -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	_close_interaction_before_direction_change()
	ui.bipob.turn_left()
	ui.update_status()


func on_turn_right_pressed() -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	_close_interaction_before_direction_change()
	ui.bipob.turn_right()
	ui.update_status()


func on_runtime_action_pressed(action_id: String) -> void:
	RuntimeInteractionPresenterRef.on_runtime_action_pressed(ui, action_id)


func on_action_pressed() -> void:
	RuntimeInteractionPresenterRef.on_action_pressed(ui)


func on_connect_pressed() -> void:
	RuntimeInteractionPresenterRef.on_connect_pressed(ui)


func on_heavy_claw_pressed() -> void:
	RuntimeInteractionPresenterRef.on_heavy_claw_pressed(ui)


func on_cut_pressed() -> void:
	if ui == null or ui.bipob == null:
		return
	if ui.bipob.has_method("try_direct_cut_facing_object"):
		ui.bipob.call("try_direct_cut_facing_object")
	ui.update_status()


func on_use_selected_world_action_pressed() -> void:
	RuntimeInteractionPresenterRef.on_use_selected_world_action_pressed(ui)


func on_world_action_cancel_pressed() -> void:
	RuntimeInteractionPresenterRef.on_world_action_cancel_pressed(ui)


func on_world_action_button_pressed(action_id: String) -> void:
	RuntimeInteractionPresenterRef.on_world_action_button_pressed(ui, action_id)


func get_world_action_target_id(target_object: Dictionary, fallback_name: String) -> String:
	var raw_id: Variant = target_object.get("id", "")
	if not str(raw_id).is_empty():
		return str(raw_id)

	var raw_position: Variant = target_object.get("position", null)
	if raw_position is Vector2i:
		var cell: Vector2i = raw_position
		return "cell_%d_%d" % [cell.x, cell.y]
	if raw_position is Vector2:
		var vector_position: Vector2 = raw_position
		return "pos_%d_%d" % [int(vector_position.x), int(vector_position.y)]
	if raw_position != null:
		return str(raw_position)

	return fallback_name


func refresh_world_actions_panel(target_object: Dictionary, actions: Array, selected_action: String) -> void:
	refresh_controls()
	RuntimeInteractionPresenterRef.refresh_world_actions_panel(ui, {"target_object": target_object, "actions": actions, "selected_action": selected_action})


func on_end_turn_pressed() -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	ui.bipob.end_turn()
	ui.update_status()
