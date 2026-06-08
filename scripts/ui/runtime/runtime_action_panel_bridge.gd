extends RefCounted
class_name RuntimeActionPanelBridge

const RuntimeControlPanelRef = preload("res://scripts/ui/runtime/runtime_control_panel.gd")
const RuntimeInteractionPanelRef = preload("res://scripts/ui/runtime/runtime_interaction_panel.gd")
const RuntimeInteractionPresenterRef = preload("res://scripts/ui/runtime/runtime_interaction_presenter.gd")
const RuntimeNotificationsRef = preload("res://scripts/ui/runtime/runtime_notifications.gd")
const RuntimeHeavyClawPresenterRef = preload("res://scripts/ui/runtime/runtime_heavy_claw_presenter.gd")

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


func refresh_controls() -> void:
	RuntimeInteractionPresenterRef.refresh(ui)


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
	var physical_actions: Array[String] = RuntimeInteractionPanelRef.get_physical_actions(actions)
	var has_interactable: bool = not target_object.is_empty() and bool(action_view_model.get("has_interaction_target", false))
	if has_interactable and not ui.runtime_interaction_mode_active and ui.runtime_action_button != null:
		ui._apply_selected_pulse(ui.runtime_action_button)
	var has_actions_left: bool = int(ui.bipob.actions_left) > 0
	var manipulator_blocked: bool = has_interactable and is_manipulator_blocked(target_object, physical_actions)
	var pulse_alpha: float = 0.72 + 0.28 * abs(sin(float(Time.get_ticks_msec()) / 170.0))
	if ui.runtime_action_button != null:
		if manipulator_blocked and has_actions_left:
			ui.runtime_action_button.modulate = Color(1.0, 0.38, 0.38, 1.0)
		elif has_interactable and has_actions_left and not ui.runtime_interaction_mode_active:
			ui.runtime_action_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			ui._clear_selected_pulse(ui.runtime_action_button)
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
