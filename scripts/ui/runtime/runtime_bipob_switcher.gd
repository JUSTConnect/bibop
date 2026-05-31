extends RefCounted
class_name RuntimeBipobSwitcher

const PANEL_SIZE: Vector2 = Vector2(240, 78)
const MAX_VISIBLE_BIPOBS: int = 4


static func build(ui, hud_root: Control, margin: float, top_offset: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RuntimeBipobSwitcher"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -PANEL_SIZE.x - margin
	panel.offset_right = -margin
	panel.offset_top = top_offset
	panel.offset_bottom = top_offset + PANEL_SIZE.y
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_BORDER, 1, 8))
	hud_root.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 8)
	panel_margin.add_theme_constant_override("margin_top", 6)
	panel_margin.add_theme_constant_override("margin_right", 8)
	panel_margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(panel_margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var title := Label.new()
	title.text = "BIPOB"
	root.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	root.add_child(row)

	ui.runtime_mission_bipob_cards.clear()
	var mission_bipobs: Array[Dictionary] = ui._get_mission_bipobs()
	var visible_count: int = mini(mission_bipobs.size(), MAX_VISIBLE_BIPOBS)
	if visible_count <= 0:
		visible_count = 1
	for index in range(visible_count):
		var text: String = "Bipob 1"
		if index < mission_bipobs.size():
			text = ui._get_mission_bipob_display_name(mission_bipobs[index], index)
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(52, 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = text
		button.tooltip_text = "Active Bipob" if index == ui.runtime_selected_mission_bipob_index else "Bipob preview"
		button.pressed.connect(func() -> void: _on_card_pressed(ui, index))
		ui.runtime_mission_bipob_cards.append(button)
		row.add_child(button)
	refresh(ui)
	return panel


static func refresh(ui) -> void:
	for index in range(ui.runtime_mission_bipob_cards.size()):
		var card: Button = ui.runtime_mission_bipob_cards[index]
		if card == null or not is_instance_valid(card):
			continue
		var is_active: bool = index == ui.runtime_selected_mission_bipob_index
		card.button_pressed = is_active
		card.modulate = Color(1, 1, 1, 1) if is_active else Color(0.78, 0.82, 0.88, 1.0)


static func _on_card_pressed(ui, _index: int) -> void:
	refresh(ui)
	if ui != null and ui.has_method("show_hint"):
		ui.call("show_hint", "Bipob switching will be implemented later.")
