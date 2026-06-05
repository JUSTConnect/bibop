extends RefCounted
class_name RuntimeHeavyClawPresenter


static func is_drag_active(ui) -> bool:
	return ui.bipob != null and ui.bipob.has_method("is_heavy_claw_drag_active") and bool(ui.bipob.call("is_heavy_claw_drag_active"))


static func refresh(ui) -> void:
	var dragging: bool = is_drag_active(ui)
	_refresh_base_buttons(ui, dragging)
	_refresh_drag_action_row(ui, dragging)


static func on_forward_pressed(ui) -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	ui.bipob.move_forward()
	ui.update_status()


static func on_back_pressed(ui) -> void:
	if ui.map_constructor_state.map_constructor_mode_active or ui.bipob == null:
		return
	ui.bipob.move_backward()
	ui.update_status()


static func on_cancel_pressed(ui) -> void:
	if ui.bipob == null or not ui.bipob.has_method("cancel_heavy_claw_drag"):
		return
	var cancel_result: Dictionary = Dictionary(ui.bipob.call("cancel_heavy_claw_drag"))
	if ui.has_method("show_hint"):
		ui.show_hint(str(cancel_result.get("message", "Heavy Claw detached.")))
	ui.update_status()


static func _refresh_base_buttons(ui, dragging: bool) -> void:
	if ui.runtime_turn_left_button != null:
		ui.runtime_turn_left_button.disabled = dragging
		ui.runtime_turn_left_button.tooltip_text = "Cancel Heavy Claw before turning." if dragging else ""
		ui._apply_action_button_style(ui.runtime_turn_left_button, "disabled" if dragging else "reference", not dragging)
	if ui.runtime_turn_right_button != null:
		ui.runtime_turn_right_button.disabled = dragging
		ui.runtime_turn_right_button.tooltip_text = "Cancel Heavy Claw before turning." if dragging else ""
		ui._apply_action_button_style(ui.runtime_turn_right_button, "disabled" if dragging else "reference", not dragging)
	if ui.runtime_action_button != null:
		ui.runtime_action_button.disabled = dragging or ui.runtime_action_button.disabled
	if ui.runtime_connect_button != null:
		ui.runtime_connect_button.disabled = dragging or ui.runtime_connect_button.disabled
	if ui.runtime_heavy_claw_button != null and dragging:
		ui.runtime_heavy_claw_button.text = "Cancel"
		ui.runtime_heavy_claw_button.disabled = false
		ui.runtime_heavy_claw_button.tooltip_text = "Release grabbed object. Cost: 0 actions."
		ui._apply_action_button_style(ui.runtime_heavy_claw_button, "danger", true)


static func _refresh_drag_action_row(ui, dragging: bool) -> void:
	if ui.runtime_interaction_actions_row == null:
		return
	if not dragging:
		return
	var has_actions_left: bool = ui.bipob != null and int(ui.bipob.actions_left) > 0
	var context: Dictionary = {}
	if ui.bipob.has_method("get_heavy_claw_drag_context"):
		context = Dictionary(ui.bipob.call("get_heavy_claw_drag_context"))
	var object_name: String = str(context.get("object_name", "Object"))
	var next_signature: String = "heavy_claw_drag|%s|%s" % [str(has_actions_left), object_name]
	if next_signature == ui.runtime_interaction_actions_signature:
		ui.runtime_interaction_actions_row.visible = true
		return
	ui.runtime_interaction_actions_signature = next_signature
	for child in ui.runtime_interaction_actions_row.get_children():
		child.queue_free()
	ui.runtime_interaction_actions_row.visible = true
	var title: Label = Label.new()
	title.name = "RuntimeHeavyClawDragLabel"
	title.text = "Dragging: %s" % object_name
	title.tooltip_text = "Forward/Back move Bipob and the grabbed object. Cancel releases for 0 actions."
	ui.runtime_interaction_actions_row.add_child(title)
	var forward_button: Button = ui._create_runtime_control_button("Forward", Callable(ui, "_on_runtime_heavy_claw_forward_pressed"), "primary" if has_actions_left else "disabled")
	forward_button.disabled = not has_actions_left
	forward_button.tooltip_text = "Move forward with grabbed object." if has_actions_left else "No actions left. End turn."
	ui.runtime_interaction_actions_row.add_child(forward_button)
	var back_button: Button = ui._create_runtime_control_button("Back", Callable(ui, "_on_runtime_heavy_claw_back_pressed"), "primary" if has_actions_left else "disabled")
	back_button.disabled = not has_actions_left
	back_button.tooltip_text = "Move backward with grabbed object." if has_actions_left else "No actions left. End turn."
	ui.runtime_interaction_actions_row.add_child(back_button)
