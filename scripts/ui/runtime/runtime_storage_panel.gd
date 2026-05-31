extends RefCounted
class_name RuntimeStoragePanel

const PANEL_SIZE: Vector2 = Vector2(380, 190)
const FLYOUT_SIZE: Vector2 = Vector2(240, 118)


static func build(ui, hud_root: Control, margin: float) -> PanelContainer:
	_reset_ui_refs(ui)
	var panel := PanelContainer.new()
	panel.name = "RuntimeThingsStoragePanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -PANEL_SIZE.x - margin
	panel.offset_right = -margin
	panel.offset_top = -PANEL_SIZE.y - margin
	panel.offset_bottom = -margin
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_BORDER, 1, 8))
	hud_root.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 8)
	panel_margin.add_theme_constant_override("margin_top", 6)
	panel_margin.add_theme_constant_override("margin_right", 8)
	panel_margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(panel_margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel_margin.add_child(root)
	var title := Label.new()
	title.text = "Things | Storage"
	root.add_child(title)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	columns.add_child(_build_manipulator_area(ui))
	columns.add_child(_build_buffer_area(ui))

	ui.runtime_pocket_flyout = _build_flyout(ui, hud_root, margin, "RuntimePocketFlyout", "Pocket", "Pocket transfer will be implemented later.")
	ui.runtime_storage_flyout = _build_flyout(ui, hud_root, margin, "RuntimeStorageFlyout", "Storage", "Storage transfer will be implemented later.")
	refresh(ui)
	return panel


static func refresh(ui) -> void:
	if ui.runtime_manipulator_content_label != null and is_instance_valid(ui.runtime_manipulator_content_label):
		ui.runtime_manipulator_content_label.text = "Empty"
	if ui.runtime_buffer_content_label != null and is_instance_valid(ui.runtime_buffer_content_label):
		ui.runtime_buffer_content_label.text = "Buffer empty"


static func _build_manipulator_area(ui) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(228, 132)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var title := Label.new()
	title.text = "Things / Manipulator"
	root.add_child(title)
	var preview := Button.new()
	preview.text = "Empty"
	preview.focus_mode = Control.FOCUS_NONE
	preview.custom_minimum_size = Vector2(0, 54)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.pressed.connect(func() -> void: _open_flyout(ui, "pocket"))
	root.add_child(preview)
	ui.runtime_manipulator_content_label = preview
	var keys := Label.new()
	keys.text = "Keys: empty"
	keys.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	root.add_child(keys)
	return panel


static func _build_buffer_area(ui) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(116, 132)
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var title := Label.new()
	title.text = "Storage / Buffer"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title)
	var preview := Button.new()
	preview.text = "Buffer empty"
	preview.focus_mode = Control.FOCUS_NONE
	preview.custom_minimum_size = Vector2(0, 54)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.pressed.connect(func() -> void: _open_flyout(ui, "storage"))
	root.add_child(preview)
	ui.runtime_buffer_content_label = preview
	return panel


static func _build_flyout(ui, hud_root: Control, margin: float, node_name: String, title_text: String, hint_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -FLYOUT_SIZE.x - margin
	panel.offset_right = -margin
	panel.offset_top = -PANEL_SIZE.y - FLYOUT_SIZE.y - margin - 6.0
	panel.offset_bottom = -PANEL_SIZE.y - margin - 6.0
	panel.visible = false
	panel.z_index = ui.Z_RUNTIME_MODAL
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_ACCENT, 1, 8))
	hud_root.add_child(panel)
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse := Button.new()
	collapse.text = "▼"
	collapse.tooltip_text = "Collapse"
	collapse.focus_mode = Control.FOCUS_NONE
	collapse.pressed.connect(func() -> void: close_flyouts(ui))
	header.add_child(collapse)
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 4)
	root.add_child(cells)
	for _index in range(2):
		var cell := Button.new()
		cell.text = "Empty"
		cell.focus_mode = Control.FOCUS_NONE
		cell.custom_minimum_size = Vector2(104, 52)
		cell.pressed.connect(func() -> void: _show_hint(ui, hint_text))
		cells.add_child(cell)
	return panel


static func _open_flyout(ui, flyout_id: String) -> void:
	close_flyouts(ui)
	if flyout_id == "pocket":
		if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
			ui.runtime_pocket_flyout.visible = true
		_show_hint(ui, "Pocket transfer will be implemented later.")
		return
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = true
	_show_hint(ui, "Storage transfer will be implemented later.")


static func close_flyouts(ui) -> void:
	if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
		ui.runtime_pocket_flyout.visible = false
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = false


static func _show_hint(ui, message: String) -> void:
	if ui != null and ui.has_method("show_hint"):
		ui.call("show_hint", message)


static func _reset_ui_refs(ui) -> void:
	ui.runtime_storage_panel_body = null
	ui.runtime_storage_collapse_button = null
	ui.runtime_pocket_slots.clear()
	ui.runtime_digital_slots.clear()
	ui.runtime_pocket_take_buttons.clear()
	ui.runtime_digital_load_buttons.clear()
	ui.runtime_key_slots.clear()
