extends RefCounted
class_name RuntimeMissionMenu

const MENU_BUTTON_SIZE: Vector2 = Vector2(112, 28)
const MENU_OVERLAY_SIZE: Vector2 = Vector2(224, 292)


static func build(ui, hud_root: Control, margin: float) -> float:
	var menu_button := Button.new()
	menu_button.name = "RuntimeMenuButton"
	menu_button.text = "Menu"
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.custom_minimum_size = MENU_BUTTON_SIZE
	menu_button.anchor_left = 1.0
	menu_button.anchor_right = 1.0
	menu_button.offset_left = -MENU_BUTTON_SIZE.x - margin
	menu_button.offset_right = -margin
	menu_button.offset_top = margin
	menu_button.offset_bottom = margin + MENU_BUTTON_SIZE.y
	menu_button.pressed.connect(func() -> void: open_overlay(ui))
	hud_root.add_child(menu_button)
	ui.runtime_menu_button = menu_button

	var overlay_root := Control.new()
	overlay_root.name = "RuntimeMissionMenuOverlay"
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_root.z_index = ui.Z_RUNTIME_MODAL
	overlay_root.z_as_relative = false
	overlay_root.visible = false
	hud_root.add_child(overlay_root)
	ui.runtime_menu_overlay = overlay_root

	var outside_button := Button.new()
	outside_button.name = "RuntimeMissionMenuOutsideClick"
	outside_button.flat = true
	outside_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outside_button.focus_mode = Control.FOCUS_NONE
	outside_button.pressed.connect(func() -> void: close_overlay(ui))
	overlay_root.add_child(outside_button)

	var panel := PanelContainer.new()
	panel.name = "RuntimeMissionMenuPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -MENU_OVERLAY_SIZE.x - margin
	panel.offset_right = -margin
	panel.offset_top = margin + MENU_BUTTON_SIZE.y + 6.0
	panel.offset_bottom = panel.offset_top + MENU_OVERLAY_SIZE.y
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_BORDER, 1, 8))
	overlay_root.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 8)
	panel_margin.add_theme_constant_override("margin_top", 8)
	panel_margin.add_theme_constant_override("margin_right", 8)
	panel_margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(panel_margin)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	panel_margin.add_child(actions)

	_add_action_button(actions, "Continue", func() -> void: close_overlay(ui))
	_add_action_button(actions, "Restart mission", func() -> void: _call_game_ui_action(ui, "_on_restart_mission_button_pressed", "Restart mission is unavailable."))
	_add_action_button(actions, "Back to Center", func() -> void: _call_game_ui_action(ui, "_on_return_to_box_button_pressed", "Back to Center is unavailable."))
	_add_action_button(actions, "Save", func() -> void: _show_hint(ui, "Save is not implemented yet."))
	_add_action_button(actions, "Load", func() -> void: _show_hint(ui, "Load is not implemented yet."))
	_add_action_button(actions, "Settings", func() -> void: _show_hint(ui, "Settings are not implemented yet."))
	_add_action_button(actions, "Main menu", func() -> void: _call_game_ui_action(ui, "_on_runtime_exit_to_main_menu_pressed", "Main menu is unavailable."))
	return MENU_BUTTON_SIZE.y


static func open_overlay(ui) -> void:
	if ui.runtime_menu_overlay != null and is_instance_valid(ui.runtime_menu_overlay):
		ui.runtime_menu_overlay.visible = true


static func close_overlay(ui) -> void:
	if ui.runtime_menu_overlay != null and is_instance_valid(ui.runtime_menu_overlay):
		ui.runtime_menu_overlay.visible = false


static func _add_action_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callback.is_valid():
		button.pressed.connect(callback)
	else:
		button.disabled = true
	parent.add_child(button)


static func _call_game_ui_action(ui, method_name: String, unavailable_hint: String) -> void:
	close_overlay(ui)
	if ui != null and ui.has_method(method_name):
		ui.call(method_name)
		return
	_show_hint(ui, unavailable_hint)


static func _show_hint(ui, message: String) -> void:
	close_overlay(ui)
	if ui != null and ui.has_method("show_hint"):
		ui.call("show_hint", message)
