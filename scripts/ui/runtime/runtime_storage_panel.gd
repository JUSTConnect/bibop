extends RefCounted
class_name RuntimeStoragePanel

const PANEL_SIZE: Vector2 = Vector2(380, 190)
const FLYOUT_SIZE: Vector2 = Vector2(240, 118)
const MIN_VISIBLE_POCKET_SLOTS: int = 2


static func build(ui, hud_root: Control, margin: float) -> PanelContainer:
	_reset_ui_refs(ui)
	var panel: PanelContainer = PanelContainer.new()
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

	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 8)
	panel_margin.add_theme_constant_override("margin_top", 6)
	panel_margin.add_theme_constant_override("margin_right", 8)
	panel_margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(panel_margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel_margin.add_child(root)
	var title: Label = Label.new()
	title.text = "Things | Storage"
	root.add_child(title)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	columns.add_child(_build_manipulator_area(ui))
	columns.add_child(_build_buffer_area(ui))

	ui.runtime_pocket_flyout = _build_flyout(ui, hud_root, margin, "RuntimePocketFlyout", "Pocket", true)
	ui.runtime_storage_flyout = _build_flyout(ui, hud_root, margin, "RuntimeStorageFlyout", "Storage", false)
	refresh(ui)
	return panel


static func refresh(ui) -> void:
	var bipob = ui.bipob
	if bipob == null:
		return
	var manipulator_items: Array = bipob.get_manipulator_items()
	if ui.runtime_manipulator_content_label != null and is_instance_valid(ui.runtime_manipulator_content_label):
		ui.runtime_manipulator_content_label.text = _get_module_name(bipob, manipulator_items[0]) if not manipulator_items.is_empty() and manipulator_items[0] != null else "Empty"
	if ui.runtime_key_summary_label != null and is_instance_valid(ui.runtime_key_summary_label):
		var key_count: int = bipob.get_key_count() if bipob.has_method("get_key_count") else 0
		ui.runtime_key_summary_label.text = "Keys: empty" if key_count <= 0 else "Keys: %d" % key_count

	var pocket_items: Array = bipob.get_pocket_items()
	var available_pocket_slots: int = bipob.get_available_pocket_slots()
	for index in range(ui.runtime_pocket_slots.size()):
		var pocket_item: Variant = pocket_items[index] if index < available_pocket_slots and index < pocket_items.size() else null
		ui.runtime_pocket_slots[index].text = _get_module_name(bipob, pocket_item) if pocket_item != null else "Empty"

	var buffer_item: Variant = bipob.get_buffer_item()
	if ui.runtime_buffer_content_label != null and is_instance_valid(ui.runtime_buffer_content_label):
		ui.runtime_buffer_content_label.text = _get_record_name(buffer_item, "Buffer empty")
	var digital_items: Array = bipob.get_digital_storage_items()
	for index in range(ui.runtime_digital_slots.size()):
		var digital_item: Variant = digital_items[index] if index < digital_items.size() else null
		ui.runtime_digital_slots[index].text = _get_record_name(digital_item, "Empty")


static func _build_manipulator_area(ui) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(228, 132)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))
	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var title: Label = Label.new()
	title.text = "Things / Manipulator"
	root.add_child(title)
	var preview_row: HBoxContainer = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 4)
	root.add_child(preview_row)
	var preview: Button = Button.new()
	preview.text = "Empty"
	preview.focus_mode = Control.FOCUS_NONE
	preview.custom_minimum_size = Vector2(0, 54)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.pressed.connect(func() -> void: _on_manipulator_preview_pressed(ui))
	preview_row.add_child(preview)
	ui.runtime_manipulator_content_label = preview
	var drop_button: Button = Button.new()
	drop_button.text = "Drop"
	drop_button.tooltip_text = "Drop held manipulator item"
	drop_button.focus_mode = Control.FOCUS_NONE
	drop_button.pressed.connect(func() -> void: _on_drop_pressed(ui))
	preview_row.add_child(drop_button)
	var keys: Label = Label.new()
	keys.text = "Keys: empty"
	keys.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	root.add_child(keys)
	ui.runtime_key_summary_label = keys
	return panel


static func _build_buffer_area(ui) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(116, 132)
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))
	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var title: Label = Label.new()
	title.text = "Storage / Buffer"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title)
	var preview: Button = Button.new()
	preview.text = "Buffer empty"
	preview.focus_mode = Control.FOCUS_NONE
	preview.custom_minimum_size = Vector2(0, 54)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.pressed.connect(func() -> void: _on_buffer_preview_pressed(ui))
	root.add_child(preview)
	ui.runtime_buffer_content_label = preview
	return panel


static func _build_flyout(ui, hud_root: Control, margin: float, node_name: String, title_text: String, is_pocket: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
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
	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 6)
	panel_margin.add_theme_constant_override("margin_top", 4)
	panel_margin.add_theme_constant_override("margin_right", 6)
	panel_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(panel_margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel_margin.add_child(root)
	var header: HBoxContainer = HBoxContainer.new()
	root.add_child(header)
	var title: Label = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse: Button = Button.new()
	collapse.text = "▼"
	collapse.tooltip_text = "Collapse"
	collapse.focus_mode = Control.FOCUS_NONE
	collapse.pressed.connect(func() -> void: close_flyouts(ui))
	header.add_child(collapse)
	var cells: HBoxContainer = HBoxContainer.new()
	cells.add_theme_constant_override("separation", 4)
	root.add_child(cells)
	var slot_count: int = max(MIN_VISIBLE_POCKET_SLOTS, ui.bipob.get_available_pocket_slots()) if is_pocket else max(1, ui.bipob.get_available_digital_storage_slots())
	for index in range(slot_count):
		var cell: Button = Button.new()
		cell.text = "Empty"
		cell.focus_mode = Control.FOCUS_NONE
		cell.custom_minimum_size = Vector2(104, 52)
		if is_pocket:
			cell.pressed.connect(_on_pocket_slot_pressed.bind(ui, index))
			ui.runtime_pocket_slots.append(cell)
		else:
			cell.pressed.connect(_on_storage_slot_pressed.bind(ui, index))
			ui.runtime_digital_slots.append(cell)
		cells.add_child(cell)
	return panel


static func _on_manipulator_preview_pressed(ui) -> void:
	var manipulator_items: Array = ui.bipob.get_manipulator_items()
	if not manipulator_items.is_empty() and manipulator_items[0] != null:
		ui._on_storage_store_pressed()
	_open_flyout(ui, "pocket")


static func _on_buffer_preview_pressed(ui) -> void:
	if ui.bipob.get_buffer_item() != null:
		ui._on_storage_data_store_pressed()
	_open_flyout(ui, "storage")


static func _on_pocket_slot_pressed(ui, slot_index: int) -> void:
	var pocket_items: Array = ui.bipob.get_pocket_items()
	if slot_index < 0 or slot_index >= ui.bipob.get_available_pocket_slots() or slot_index >= pocket_items.size() or pocket_items[slot_index] == null:
		_show_hint(ui, "Pocket is empty.")
		return
	ui._on_storage_take_slot_pressed(slot_index)
	refresh(ui)


static func _on_storage_slot_pressed(ui, slot_index: int) -> void:
	ui._on_storage_load_slot_pressed(slot_index)
	refresh(ui)


static func _on_drop_pressed(ui) -> void:
	ui._on_drop_item_button_pressed()
	refresh(ui)


static func _open_flyout(ui, flyout_id: String) -> void:
	close_flyouts(ui)
	refresh(ui)
	if flyout_id == "pocket":
		if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
			ui.runtime_pocket_flyout.visible = true
		return
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = true


static func close_flyouts(ui) -> void:
	if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
		ui.runtime_pocket_flyout.visible = false
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = false


static func _show_hint(ui, message: String) -> void:
	if ui != null and ui.has_method("show_hint"):
		ui.call("show_hint", message)


static func _get_module_name(bipob, item: Variant) -> String:
	if item == null:
		return "Empty"
	return bipob.get_module_display_name(item)


static func _get_record_name(item: Variant, empty_text: String) -> String:
	if typeof(item) != TYPE_DICTIONARY:
		return empty_text
	var record: Dictionary = item
	var display_name: String = String(record.get("display_name", record.get("id", ""))).strip_edges()
	return empty_text if display_name.is_empty() else display_name


static func _reset_ui_refs(ui) -> void:
	ui.runtime_storage_panel_body = null
	ui.runtime_storage_collapse_button = null
	ui.runtime_pocket_slots.clear()
	ui.runtime_digital_slots.clear()
	ui.runtime_pocket_take_buttons.clear()
	ui.runtime_digital_load_buttons.clear()
	ui.runtime_key_slots.clear()
	ui.runtime_key_summary_label = null
