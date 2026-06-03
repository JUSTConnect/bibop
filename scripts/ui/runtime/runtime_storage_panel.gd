extends RefCounted
class_name RuntimeStoragePanel

const PANEL_SIZE: Vector2 = Vector2(380, 190)
const FLYOUT_SIZE: Vector2 = Vector2(66, 118)
const MANIPULATOR_CELL_SIZE: float = 54.0
const FLYOUT_CELL_SIZE: float = 54.0
const ACTIVE_FRAME_PADDING: float = 3.0
const MIN_VISIBLE_MANIPULATOR_SLOTS: int = 3
const MIN_VISIBLE_KEY_SLOTS: int = 6
const MIN_VISIBLE_POCKET_SLOTS: int = 2
const MANIPULATOR_VISIBLE_SLOTS: int = 3
const KEY_MINI_HUD_SLOTS: int = 6
const KEY_MINI_HUD_CELL_SIZE: Vector2 = Vector2(20, 16)
const BOTTOM_PANEL_GAP: float = 8.0
const STANDARD_ROW_HEIGHT: float = 28.0


static func get_panel_width(ui, margin: float) -> float:
	var viewport_width: float = _get_viewport_width(ui)
	return minf(PANEL_SIZE.x, maxf(viewport_width - margin * 2.0, 1.0))


static func get_reserved_bottom_width(ui, margin: float) -> float:
	return get_panel_width(ui, margin) + BOTTOM_PANEL_GAP


static func build(ui, hud_root: Control, margin: float) -> PanelContainer:
	_reset_ui_refs(ui)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "RuntimeThingsStoragePanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	var safe_panel_width: float = get_panel_width(ui, margin)
	panel.offset_left = -safe_panel_width - margin
	panel.offset_right = -margin
	panel.offset_top = -PANEL_SIZE.y - margin
	panel.offset_bottom = -margin
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
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
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	columns.add_child(_build_manipulator_area(ui))
	columns.add_child(_build_buffer_area(ui))

	ui.runtime_pocket_flyout = _build_flyout(ui, hud_root, margin, "RuntimePocketFlyout", true)
	ui.runtime_storage_flyout = _build_flyout(ui, hud_root, margin, "RuntimeStorageFlyout", false)
	refresh(ui)
	return panel


static func set_visible(ui, visible_state: bool) -> void:
	if ui == null:
		return
	if ui.runtime_storage_panel != null and is_instance_valid(ui.runtime_storage_panel):
		ui.runtime_storage_panel.visible = visible_state
	if not visible_state and ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = false


static func _get_inventory_item_id(value: Variant) -> String:
	if value is String or value is StringName:
		return str(value).strip_edges()
	if value is Dictionary:
		return str(Dictionary(value).get("id", Dictionary(value).get("item_id", ""))).strip_edges()
	return ""


static func refresh(ui) -> void:
	if ui == null:
		return
	var bipob = ui.bipob
	if bipob == null or not is_instance_valid(bipob):
		_refresh_empty_state(ui)
		return
	var inventory_state: Dictionary = bipob.get_inventory_state() if bipob.has_method("get_inventory_state") else {}
	var manipulator_items: Array = bipob.get_manipulator_items()
	var held_world_item_id: String = _get_inventory_item_id(inventory_state.get("manipulator_hold", ""))
	for index in range(ui.runtime_manipulator_slots.size()):
		var manipulator_item: Variant = manipulator_items[index] if index < manipulator_items.size() else null
		ui.runtime_manipulator_slots[index].text = _get_module_name(bipob, manipulator_item)
		if index == 0 and not held_world_item_id.is_empty():
			ui.runtime_manipulator_slots[index].text = _get_runtime_inventory_item_name(inventory_state, held_world_item_id)
	_refresh_key_mini_hud(ui, bipob)

	var pocket_items: Array = bipob.get_pocket_items()
	var runtime_pocket_items: Array = Array(inventory_state.get("pocket_items", []))
	var available_pocket_slots: int = bipob.get_available_pocket_slots()
	for index in range(ui.runtime_pocket_slots.size()):
		var pocket_item: Variant = pocket_items[index] if index < available_pocket_slots and index < pocket_items.size() else null
		ui.runtime_pocket_slots[index].text = _get_module_name(bipob, pocket_item)
		if index < runtime_pocket_items.size():
			var runtime_pocket_item_id: String = _get_inventory_item_id(runtime_pocket_items[index])
			if not runtime_pocket_item_id.is_empty():
				ui.runtime_pocket_slots[index].text = _get_runtime_inventory_item_name(inventory_state, runtime_pocket_item_id)

	var buffer_item: Variant = bipob.get_buffer_item()
	if ui.runtime_buffer_content_label != null and is_instance_valid(ui.runtime_buffer_content_label):
		ui.runtime_buffer_content_label.text = _get_record_name(buffer_item, "Empty")
		var delete_button: Variant = ui.runtime_buffer_content_label.get_meta("delete_button", null)
		if delete_button != null and is_instance_valid(delete_button):
			delete_button.disabled = buffer_item == null
	var digital_items: Array = bipob.get_digital_storage_items()
	for index in range(ui.runtime_digital_slots.size()):
		var digital_item: Variant = digital_items[index] if index < digital_items.size() else null
		ui.runtime_digital_slots[index].text = _get_record_name(digital_item, "Empty")


static func _refresh_key_mini_hud(ui, bipob) -> void:
	var inventory_state: Dictionary = {}
	if bipob.has_method("get_inventory_state"):
		var raw_inventory_state: Variant = bipob.call("get_inventory_state")
		if typeof(raw_inventory_state) == TYPE_DICTIONARY:
			inventory_state = raw_inventory_state
	var key_ids: Array = []
	if ui.has_method("_get_runtime_display_key_ids"):
		key_ids = ui._get_runtime_display_key_ids(inventory_state)
	elif bipob.has_method("get_key_count") and int(bipob.call("get_key_count")) > 0:
		key_ids.append("physical_key")
	for index in range(ui.runtime_key_slots.size()):
		var key_slot: Control = ui.runtime_key_slots[index]
		if key_slot == null or not is_instance_valid(key_slot):
			continue
		var key_text: String = "·"
		var tooltip_text: String = "Empty key slot"
		if index < key_ids.size():
			var key_id: String = str(key_ids[index]).strip_edges()
			tooltip_text = key_id
			if ui.has_method("_get_runtime_key_display_text"):
				tooltip_text = ui._get_runtime_key_display_text(key_id, inventory_state)
			# Keep the strip layout stable: every collected access card, including
			# compatibility ids for old mechanical keys, uses one compact glyph.
			key_text = "K"
		key_slot.set("text", key_text)
		key_slot.tooltip_text = tooltip_text


static func _get_viewport_width(ui) -> float:
	if ui != null and ui.has_method("_get_viewport_size"):
		var viewport_size: Variant = ui._get_viewport_size()
		if typeof(viewport_size) == TYPE_VECTOR2:
			return maxf(viewport_size.x, 1.0)
	return PANEL_SIZE.x + 24.0


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
	var manipulator_columns: HBoxContainer = HBoxContainer.new()
	manipulator_columns.add_theme_constant_override("separation", 14)
	root.add_child(manipulator_columns)
	for index in range(MANIPULATOR_VISIBLE_SLOTS):
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		column.custom_minimum_size = Vector2(MANIPULATOR_CELL_SIZE, 0)
		column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		manipulator_columns.add_child(column)
		var preview: Button = Button.new()
		preview.text = "Empty"
		preview.focus_mode = Control.FOCUS_NONE
		preview.clip_text = true
		preview.custom_minimum_size = Vector2(MANIPULATOR_CELL_SIZE, MANIPULATOR_CELL_SIZE)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		preview.pressed.connect(_on_manipulator_preview_pressed.bind(ui, index))
		column.add_child(preview)
		ui.runtime_manipulator_slots.append(preview)
		if index == 0:
			ui.runtime_manipulator_content_label = preview
		var drop_button: Button = Button.new()
		drop_button.text = "Drop"
		drop_button.tooltip_text = "Drop held manipulator item"
		drop_button.focus_mode = Control.FOCUS_NONE
		drop_button.custom_minimum_size = Vector2(MANIPULATOR_CELL_SIZE, STANDARD_ROW_HEIGHT)
		drop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drop_button.pressed.connect(_on_drop_pressed.bind(ui, index))
		column.add_child(drop_button)
		preview.set_meta("drop_button", drop_button)
	var keys_panel: PanelContainer = PanelContainer.new()
	keys_panel.name = "RuntimeKeysStripPanel"
	keys_panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL, ui.UI_COLOR_BORDER_DIM, 1, 4))
	root.add_child(keys_panel)
	var keys_margin: MarginContainer = MarginContainer.new()
	keys_margin.add_theme_constant_override("margin_left", 4)
	keys_margin.add_theme_constant_override("margin_top", 2)
	keys_margin.add_theme_constant_override("margin_right", 4)
	keys_margin.add_theme_constant_override("margin_bottom", 2)
	keys_panel.add_child(keys_margin)
	var keys_strip: HBoxContainer = HBoxContainer.new()
	keys_strip.add_theme_constant_override("separation", 3)
	keys_margin.add_child(keys_strip)
	for index in range(KEY_MINI_HUD_SLOTS):
		var key_slot: Label = Label.new()
		key_slot.text = "·"
		key_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_slot.clip_text = true
		key_slot.custom_minimum_size = KEY_MINI_HUD_CELL_SIZE
		key_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		key_slot.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
		keys_strip.add_child(key_slot)
		ui.runtime_key_slots.append(key_slot)
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
	var preview: Button = Button.new()
	preview.text = "Empty"
	preview.focus_mode = Control.FOCUS_NONE
	preview.clip_text = true
	preview.custom_minimum_size = Vector2(MANIPULATOR_CELL_SIZE, MANIPULATOR_CELL_SIZE)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.pressed.connect(func() -> void: _on_buffer_preview_pressed(ui))
	root.add_child(preview)
	var delete_button: Button = Button.new()
	delete_button.text = "Delete"
	delete_button.tooltip_text = "Delete buffered item"
	delete_button.focus_mode = Control.FOCUS_NONE
	delete_button.disabled = true
	delete_button.custom_minimum_size = Vector2(MANIPULATOR_CELL_SIZE, STANDARD_ROW_HEIGHT)
	delete_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# No confirmed backend delete path exists yet, so keep this action non-destructive.
	delete_button.pressed.connect(func() -> void: _show_hint(ui, "Delete is not implemented yet."))
	root.add_child(delete_button)
	preview.set_meta("delete_button", delete_button)
	ui.runtime_buffer_content_label = preview
	return panel


static func _build_flyout(ui, hud_root: Control, margin: float, node_name: String, is_pocket: bool) -> PanelContainer:
	var slot_count: int = 1
	if is_pocket:
		slot_count = MIN_VISIBLE_POCKET_SLOTS
	var bipob: Variant = null
	if ui != null:
		bipob = ui.bipob
	if bipob != null and is_instance_valid(bipob):
		if is_pocket:
			slot_count = max(MIN_VISIBLE_POCKET_SLOTS, bipob.get_available_pocket_slots())
		else:
			slot_count = max(1, bipob.get_available_digital_storage_slots())
	var flyout_width: float = _get_safe_width(hud_root, FLYOUT_SIZE.x, margin)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = node_name
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -flyout_width - margin
	panel.offset_right = -margin
	panel.offset_top = -PANEL_SIZE.y - FLYOUT_SIZE.y - 6.0
	panel.offset_bottom = -PANEL_SIZE.y - 6.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
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
	var collapse: Button = Button.new()
	collapse.text = "▼"
	collapse.tooltip_text = "Collapse"
	collapse.focus_mode = Control.FOCUS_NONE
	collapse.custom_minimum_size = Vector2(FLYOUT_CELL_SIZE, STANDARD_ROW_HEIGHT)
	collapse.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	collapse.pressed.connect(func() -> void: close_flyouts(ui))
	root.add_child(collapse)
	var cells: VBoxContainer = VBoxContainer.new()
	cells.add_theme_constant_override("separation", 4)
	root.add_child(cells)
	for index in range(slot_count):
		var cell: Button = Button.new()
		cell.text = "Empty"
		cell.focus_mode = Control.FOCUS_NONE
		cell.clip_text = true
		cell.custom_minimum_size = Vector2(FLYOUT_CELL_SIZE, FLYOUT_CELL_SIZE)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if is_pocket:
			cell.pressed.connect(_on_pocket_slot_pressed.bind(ui, index))
			ui.runtime_pocket_slots.append(cell)
		else:
			cell.pressed.connect(_on_storage_slot_pressed.bind(ui, index))
			ui.runtime_digital_slots.append(cell)
		cells.add_child(cell)
	var active_frame: PanelContainer = PanelContainer.new()
	active_frame.name = "RuntimePocketActiveColumnFrame" if is_pocket else "RuntimeStorageActiveColumnFrame"
	active_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_frame.visible = false
	active_frame.z_index = ui.Z_RUNTIME_MODAL + 1
	active_frame.add_theme_stylebox_override("panel", ui._make_panel_style(Color(0, 0, 0, 0), ui.UI_COLOR_ACCENT, 2, 8))
	hud_root.add_child(active_frame)
	panel.set_meta("active_frame", active_frame)
	panel.set_meta("hud_root", hud_root)
	return panel


static func _on_manipulator_preview_pressed(ui, manipulator_index: int) -> void:
	if ui == null or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	ui.selected_manipulator_slot = manipulator_index
	if not _is_pocket_flyout_open_for(ui, manipulator_index):
		_open_flyout(ui, "pocket", manipulator_index)
		return
	var result: Dictionary = ui._move_runtime_manipulator_to_first_free_pocket()
	if bool(result.get("ok", false)):
		refresh(ui)


static func _on_buffer_preview_pressed(ui) -> void:
	if ui == null or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	if not _is_storage_flyout_open(ui):
		_open_flyout(ui, "storage")
		return
	var result: Dictionary = ui._move_runtime_buffer_to_first_free_storage()
	if bool(result.get("ok", false)):
		refresh(ui)


static func _on_pocket_slot_pressed(ui, slot_index: int) -> void:
	if ui == null or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	var result: Dictionary = ui._move_or_swap_runtime_pocket_slot(slot_index)
	if bool(result.get("ok", false)):
		refresh(ui)


static func _on_storage_slot_pressed(ui, slot_index: int) -> void:
	if ui == null or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	var result: Dictionary = ui._move_or_swap_runtime_storage_slot(slot_index)
	if bool(result.get("ok", false)):
		refresh(ui)


static func _is_pocket_flyout_open_for(ui, manipulator_index: int) -> bool:
	if ui.runtime_pocket_flyout == null or not is_instance_valid(ui.runtime_pocket_flyout):
		return false
	return ui.runtime_pocket_flyout.visible and int(ui.runtime_pocket_flyout.get_meta("active_manipulator_index", -1)) == manipulator_index


static func _is_storage_flyout_open(ui) -> bool:
	return ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout) and ui.runtime_storage_flyout.visible


static func _on_drop_pressed(ui, manipulator_index: int) -> void:
	ui.selected_manipulator_slot = manipulator_index
	ui._on_drop_item_button_pressed()
	refresh(ui)


static func _open_flyout(ui, flyout_id: String, manipulator_index: int = -1) -> void:
	close_flyouts(ui)
	refresh(ui)
	if flyout_id == "pocket":
		if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
			ui.runtime_pocket_flyout.set_meta("active_manipulator_index", manipulator_index)
			ui.runtime_pocket_flyout.visible = true
			_align_pocket_flyout(ui, manipulator_index)
			_align_pocket_flyout.bind(ui, manipulator_index).call_deferred()
		return
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = true
		_align_storage_flyout(ui)
		_align_storage_flyout.bind(ui).call_deferred()


static func close_flyouts(ui) -> void:
	if ui.runtime_pocket_flyout != null and is_instance_valid(ui.runtime_pocket_flyout):
		ui.runtime_pocket_flyout.visible = false
		var active_frame: Variant = ui.runtime_pocket_flyout.get_meta("active_frame", null)
		if active_frame != null and is_instance_valid(active_frame):
			active_frame.visible = false
	if ui.runtime_storage_flyout != null and is_instance_valid(ui.runtime_storage_flyout):
		ui.runtime_storage_flyout.visible = false
		var active_frame: Variant = ui.runtime_storage_flyout.get_meta("active_frame", null)
		if active_frame != null and is_instance_valid(active_frame):
			active_frame.visible = false


static func _align_pocket_flyout(ui, manipulator_index: int) -> void:
	if ui == null or manipulator_index < 0 or manipulator_index >= ui.runtime_manipulator_slots.size():
		return
	var flyout: PanelContainer = ui.runtime_pocket_flyout
	if flyout == null or not is_instance_valid(flyout) or not flyout.visible:
		return
	var slot: Button = ui.runtime_manipulator_slots[manipulator_index]
	if slot == null or not is_instance_valid(slot):
		return
	var drop_button: Variant = slot.get_meta("drop_button", null)
	if drop_button == null or not is_instance_valid(drop_button):
		return
	var hud_root: Variant = flyout.get_meta("hud_root", null)
	var active_frame: Variant = flyout.get_meta("active_frame", null)
	if hud_root == null or not is_instance_valid(hud_root) or active_frame == null or not is_instance_valid(active_frame):
		return
	var hud_origin: Vector2 = hud_root.global_position
	var slot_rect: Rect2 = slot.get_global_rect()
	var drop_rect: Rect2 = drop_button.get_global_rect()
	var flyout_height: float = flyout.get_combined_minimum_size().y
	var flyout_width: float = maxf(slot_rect.size.x, flyout.get_combined_minimum_size().x)
	var flyout_left: float = slot_rect.get_center().x - hud_origin.x - flyout_width * 0.5
	var flyout_position: Vector2 = Vector2(flyout_left, slot_rect.position.y - hud_origin.y - flyout_height)
	flyout.set_anchors_preset(Control.PRESET_TOP_LEFT)
	flyout.position = flyout_position
	flyout.size = Vector2(flyout_width, flyout_height)
	var column_left: float = minf(flyout_position.x, drop_rect.position.x - hud_origin.x)
	var column_right: float = maxf(flyout_position.x + flyout_width, drop_rect.end.x - hud_origin.x)
	active_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	active_frame.position = Vector2(column_left - ACTIVE_FRAME_PADDING, flyout_position.y - ACTIVE_FRAME_PADDING)
	active_frame.size = Vector2(column_right - column_left + ACTIVE_FRAME_PADDING * 2.0, drop_rect.end.y - hud_origin.y - flyout_position.y + ACTIVE_FRAME_PADDING)
	active_frame.visible = true


static func _align_storage_flyout(ui) -> void:
	if ui == null:
		return
	var flyout: PanelContainer = ui.runtime_storage_flyout
	var slot: Button = ui.runtime_buffer_content_label
	if flyout == null or not is_instance_valid(flyout) or not flyout.visible or slot == null or not is_instance_valid(slot):
		return
	var delete_button: Variant = slot.get_meta("delete_button", null)
	var hud_root: Variant = flyout.get_meta("hud_root", null)
	var active_frame: Variant = flyout.get_meta("active_frame", null)
	if delete_button == null or not is_instance_valid(delete_button) or hud_root == null or not is_instance_valid(hud_root) or active_frame == null or not is_instance_valid(active_frame):
		return
	var hud_origin: Vector2 = hud_root.global_position
	var slot_rect: Rect2 = slot.get_global_rect()
	var delete_rect: Rect2 = delete_button.get_global_rect()
	var flyout_height: float = flyout.get_combined_minimum_size().y
	var flyout_width: float = maxf(slot_rect.size.x, flyout.get_combined_minimum_size().x)
	var flyout_left: float = slot_rect.get_center().x - hud_origin.x - flyout_width * 0.5
	var flyout_position: Vector2 = Vector2(flyout_left, slot_rect.position.y - hud_origin.y - flyout_height)
	flyout.set_anchors_preset(Control.PRESET_TOP_LEFT)
	flyout.position = flyout_position
	flyout.size = Vector2(flyout_width, flyout_height)
	var column_left: float = minf(flyout_position.x, delete_rect.position.x - hud_origin.x)
	var column_right: float = maxf(flyout_position.x + flyout_width, delete_rect.end.x - hud_origin.x)
	active_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	active_frame.position = Vector2(column_left - ACTIVE_FRAME_PADDING, flyout_position.y - ACTIVE_FRAME_PADDING)
	active_frame.size = Vector2(column_right - column_left + ACTIVE_FRAME_PADDING * 2.0, delete_rect.end.y - hud_origin.y - flyout_position.y + ACTIVE_FRAME_PADDING)
	active_frame.visible = true


static func _show_hint(ui, message: String) -> void:
	if ui != null and ui.has_method("show_hint"):
		ui.call("show_hint", message)


static func _get_safe_width(hud_root: Control, preferred_width: float, margin: float) -> float:
	var viewport_width: float = preferred_width + margin * 2.0
	if hud_root != null and is_instance_valid(hud_root):
		viewport_width = hud_root.get_viewport_rect().size.x
	return minf(preferred_width, maxf(viewport_width - margin * 2.0, 1.0))


static func _get_collected_key_ids(bipob) -> Array:
	if bipob.has_method("get_collected_runtime_key_ids"):
		var collected_value: Variant = bipob.call("get_collected_runtime_key_ids")
		if collected_value is Array:
			return collected_value
	var key_count: int = bipob.get_key_count() if bipob.has_method("get_key_count") else 0
	var fallback_ids: Array = []
	for _index in range(key_count):
		fallback_ids.append("physical_key")
	return fallback_ids


static func _get_key_slot_text(ui, key_value: Variant) -> String:
	var key_id: String = _get_inventory_item_id(key_value)
	if key_id.is_empty():
		return "—"
	if ui != null and ui.has_method("_get_runtime_key_display_text"):
		var display_text: String = str(ui.call("_get_runtime_key_display_text", key_id)).strip_edges()
		if not display_text.is_empty():
			return display_text.left(8)
	return key_id.left(8)


static func _refresh_empty_state(ui) -> void:
	for slot in ui.runtime_manipulator_slots:
		if slot != null and is_instance_valid(slot):
			slot.text = "Empty"
	for slot in ui.runtime_key_slots:
		if slot != null and is_instance_valid(slot):
			slot.text = "—"
	if ui.runtime_buffer_content_label != null and is_instance_valid(ui.runtime_buffer_content_label):
		ui.runtime_buffer_content_label.text = "Empty"
		var delete_button: Variant = ui.runtime_buffer_content_label.get_meta("delete_button", null)
		if delete_button != null and is_instance_valid(delete_button):
			delete_button.disabled = true



static func _get_runtime_inventory_item_name(inventory_state: Dictionary, item_id: String) -> String:
	var runtime_map: Dictionary = Dictionary(inventory_state.get("world_item_runtime", {}))
	var item_runtime: Dictionary = Dictionary(runtime_map.get(item_id, {}))
	var item_data: Dictionary = Dictionary(item_runtime.get("item_data", {}))
	var display_name: String = str(item_data.get("display_name", item_data.get("item_type", item_id))).strip_edges()
	return item_id if display_name.is_empty() else display_name.capitalize()

static func _get_module_name(bipob, item: Variant) -> String:
	if item == null:
		return "Empty"
	if typeof(item) == TYPE_DICTIONARY:
		return _get_record_name(item, "Item")
	return bipob.get_module_display_name(item)


static func _get_record_name(item: Variant, empty_text: String) -> String:
	if typeof(item) != TYPE_DICTIONARY:
		return empty_text
	var record: Dictionary = item
	var display_name: String = str(record.get("display_name", record.get("id", ""))).strip_edges()
	return empty_text if display_name.is_empty() else display_name


static func _reset_ui_refs(ui) -> void:
	ui.runtime_storage_panel_body = null
	ui.runtime_storage_collapse_button = null
	ui.runtime_manipulator_slots.clear()
	ui.runtime_pocket_slots.clear()
	ui.runtime_digital_slots.clear()
	ui.runtime_pocket_take_buttons.clear()
	ui.runtime_digital_load_buttons.clear()
	ui.runtime_key_slots.clear()
	ui.runtime_key_summary_label = null
