extends RefCounted
class_name MapConstructorInspector

static func build(ui: Variant, entity_kind: String, entity_id: String, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var inspector_rect: Rect2 = ui._get_map_constructor_bottom_inspector_rect()
	panel.position = inspector_rect.position
	panel.size = inspector_rect.size
	panel.custom_minimum_size = inspector_rect.size
	panel.z_index = ui.Z_MAP_CONSTRUCTOR_UI
	panel.z_as_relative = false
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var inspector_stack := VBoxContainer.new()
	inspector_stack.add_theme_constant_override("separation", 6)
	inspector_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(inspector_stack)
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_label := Label.new()
	header_label.text = "Selected %s: %s" % [entity_kind, ui._safe_ui_string(data.get("display_name", entity_id), entity_id)]
	header_label.clip_text = true
	header_label.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var expand_button := Button.new()
	expand_button.text = "▲" if ui.map_constructor_inspector_expanded else "▼"
	expand_button.tooltip_text = "Collapse inspector" if ui.map_constructor_inspector_expanded else "Expand inspector"
	expand_button.pressed.connect(ui._toggle_map_constructor_inspector_expanded)
	header_row.add_child(expand_button)
	inspector_stack.add_child(header_row)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.runtime_map_constructor_inspector_scroll = scroll
	inspector_stack.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.custom_minimum_size = Vector2(maxf(inspector_rect.size.x - 36.0, 1.0), 0.0)
	scroll.add_child(content)
	ui.runtime_map_constructor_inspector_panel = panel
	return panel


static func clear(ui: Variant) -> void:
	if ui.runtime_map_constructor_inspector_panel != null and is_instance_valid(ui.runtime_map_constructor_inspector_panel):
		ui.runtime_map_constructor_inspector_panel.queue_free()
	ui.runtime_map_constructor_inspector_panel = null
	ui.runtime_map_constructor_inspector_scroll = null


static func _get_normalized_object_type(ui: Variant, data: Dictionary) -> String:
	var object_type: String = ui._safe_ui_string(data.get("object_type", data.get("item_type", "item")), "item").strip_edges().to_lower()
	if object_type.begins_with("power_source"):
		return "power_source"
	return object_type


static func _get_normalized_object_class(ui: Variant, data: Dictionary, type_group: String) -> String:
	var object_type: String = _get_normalized_object_type(ui, data)
	if object_type == "power_source":
		var source_class: String = ui._safe_ui_string(data.get("power_source_class", data.get("source_class", ""))).strip_edges()
		if source_class.is_empty():
			var raw_type: String = ui._safe_ui_string(data.get("object_type", "")).strip_edges().to_lower()
			if raw_type.ends_with("_1"):
				source_class = "1"
			elif raw_type.ends_with("_2"):
				source_class = "2"
			elif raw_type.ends_with("_3"):
				source_class = "3"
		return "C%s" % source_class if not source_class.is_empty() else ""
	for class_field in ["object_class", "door_class", "terminal_class", "item_class"]:
		if data.has(class_field):
			var class_value: String = ui._safe_ui_string(data.get(class_field, "")).strip_edges()
			if not class_value.is_empty() and class_value.to_lower() != object_type:
				return class_value
	return "" if type_group == object_type or type_group == "generic" else type_group


static func _get_power_health_state(data: Dictionary) -> String:
	var state: String = MapConstructorUiSafe.safe_string(data.get("cable_health_state", data.get("health_state", data.get("state", "")))).strip_edges().to_lower()
	if bool(data.get("cut", false)) or state == "cut":
		return "cut"
	if bool(data.get("broken", false)) or state == "broken":
		return "broken"
	if bool(data.get("damaged", false)) or state == "damaged":
		return "damaged"
	return "normal"


static func _get_cable_install_type(data: Dictionary) -> String:
	if bool(data.get("hidden_installation", data.get("is_hidden", false))):
		return "hidden"
	var raw_install_mode: Variant = data.get("mount", data.get("cable_install_mode", data.get("install_mode", data.get("placement_mode", data.get("route_surface", "floor")))))
	var install_mode: String = MapConstructorUiSafe.safe_string(raw_install_mode, "floor").strip_edges().to_lower()
	if install_mode in ["wall", "hidden"]:
		return install_mode
	return "floor"


static func _cell_has_wall(ui: Variant, cell: Vector2i) -> bool:
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("_is_map_constructor_wall_cell"):
		return bool(ui.mission_manager_runtime.call("_is_map_constructor_wall_cell", cell))
	return false


static func _add_cable_note(ui: Variant, section: VBoxContainer, text: String, is_warning: bool = false) -> void:
	var note: Label = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = text
	note.add_theme_color_override("font_color", ui.UI_COLOR_WARNING if is_warning else ui.UI_COLOR_ACCENT)
	section.add_child(note)



static func _build_cell_panel(ui: Variant, cell: Vector2i) -> PanelContainer:
	var panel := PanelContainer.new()
	var inspector_rect: Rect2 = ui._get_map_constructor_bottom_inspector_rect()
	panel.position = inspector_rect.position
	panel.size = inspector_rect.size
	panel.custom_minimum_size = inspector_rect.size
	panel.z_index = ui.Z_MAP_CONSTRUCTOR_UI
	panel.z_as_relative = false
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var inspector_stack := VBoxContainer.new()
	inspector_stack.add_theme_constant_override("separation", 6)
	inspector_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(inspector_stack)
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_label := Label.new()
	header_label.text = "Cell (%d, %d)" % [cell.x, cell.y]
	header_label.clip_text = true
	header_label.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var expand_button := Button.new()
	expand_button.text = "▲" if ui.map_constructor_inspector_expanded else "▼"
	expand_button.tooltip_text = "Collapse inspector" if ui.map_constructor_inspector_expanded else "Expand inspector"
	expand_button.pressed.connect(ui._toggle_map_constructor_inspector_expanded)
	header_row.add_child(expand_button)
	inspector_stack.add_child(header_row)
	ui.runtime_map_constructor_inspector_panel = panel
	return panel


static func _make_tab_content(ui: Variant, inspector_rect: Rect2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.custom_minimum_size = Vector2(maxf(inspector_rect.size.x - 46.0, 420.0), 0.0)
	scroll.add_child(content)
	return content


static func _get_tab_id_for_entity(ui: Variant, entity_kind: String, data: Dictionary) -> String:
	if entity_kind == "item":
		return "items"
	var object_type: String = ui._safe_ui_string(data.get("object_type", data.get("item_type", ""))).to_lower()
	var object_group: String = ui._safe_ui_string(data.get("object_group", data.get("group", ""))).to_lower()
	var joined: String = "%s %s %s" % [object_type, object_group, ui._safe_ui_string(data.get("map_constructor_prefab_id", "")).to_lower()]
	if object_group == "threat" or joined.contains("enemy") or joined.contains("bipob") or joined.contains("bipop"):
		return "enemies"
	if object_type in ["power_cable", "power_cable_reel"] or object_group == "cable" or joined.contains("power_cable"):
		return "cables"
	if object_type == "light" or object_group == "lighting":
		return "lighting"
	if object_group == "wall" or object_type == "wall":
		return "walls"
	return "objects"


static func _find_entity_in_tabs(tabs: Array, entity_kind: String, entity_id: String) -> Dictionary:
	for tab_variant in tabs:
		var tab: Dictionary = Dictionary(tab_variant)
		for entity_variant in Array(tab.get("entities", [])):
			var entity: Dictionary = Dictionary(entity_variant)
			if str(entity.get("entity_kind", "")) == entity_kind and str(entity.get("id", "")) == entity_id:
				return entity
	return {}


static func _find_tab_index_by_id(tabs: Array, tab_id: String) -> int:
	for index in range(tabs.size()):
		var tab: Dictionary = Dictionary(tabs[index])
		if str(tab.get("id", "")) == tab_id:
			return index
	return -1


static func _choose_preferred_tab_id(ui: Variant, tabs: Array, model_preferred_tab: String, preferred_entity_kind: String, preferred_entity_id: String) -> String:
	if not preferred_entity_id.is_empty():
		return model_preferred_tab
	var remembered_tab: String = ui._safe_ui_string(ui.map_constructor_active_inspector_tab_id, "")
	if not remembered_tab.is_empty() and _find_tab_index_by_id(tabs, remembered_tab) >= 0:
		return remembered_tab
	return model_preferred_tab


static func _choose_tab_entity(ui: Variant, tab: Dictionary, preferred_entity_kind: String, preferred_entity_id: String) -> Dictionary:
	var entities: Array = Array(tab.get("entities", []))
	if entities.is_empty():
		return {}
	for entity_variant in entities:
		var entity: Dictionary = Dictionary(entity_variant)
		if str(entity.get("entity_kind", "")) == preferred_entity_kind and str(entity.get("id", "")) == preferred_entity_id:
			return entity
	var remembered_kind: String = ui.selected_map_constructor_entity_kind
	var remembered_id: String = ui.selected_map_constructor_entity_id
	for entity_variant in entities:
		var entity: Dictionary = Dictionary(entity_variant)
		if str(entity.get("entity_kind", "")) == remembered_kind and str(entity.get("id", "")) == remembered_id:
			return entity
	return Dictionary(entities[0])


static func _add_entity_selector(ui: Variant, parent: VBoxContainer, tab: Dictionary, selected_entity: Dictionary, selected_cell: Vector2i) -> void:
	var entities: Array = Array(tab.get("entities", []))
	if entities.size() <= 1:
		return
	var option := OptionButton.new()
	for entity_variant in entities:
		var entity: Dictionary = Dictionary(entity_variant)
		var data: Dictionary = ui._safe_ui_dictionary(entity.get("data", {}))
		var entity_id: String = str(entity.get("id", ""))
		var label: String = ui._safe_ui_string(data.get("display_name", data.get("object_type", data.get("item_type", entity_id))), entity_id)
		option.add_item("%s — %s" % [label, entity_id])
		var index: int = option.item_count - 1
		option.set_item_metadata(index, {"entity_kind":str(entity.get("entity_kind", "")), "id":entity_id})
		if entity_id == str(selected_entity.get("id", "")) and str(entity.get("entity_kind", "")) == str(selected_entity.get("entity_kind", "")):
			option.select(index)
	option.item_selected.connect(func(_idx: int) -> void:
		var metadata: Dictionary = ui._safe_ui_dictionary(option.get_selected_metadata())
		refresh(ui, selected_cell, str(metadata.get("entity_kind", "")), str(metadata.get("id", "")))
	)
	parent.add_child(ui._create_property_row("Select", option))


static func _render_read_only_entity(ui: Variant, parent: VBoxContainer, entity: Dictionary, title: String) -> void:
	var data: Dictionary = ui._safe_ui_dictionary(entity.get("data", {}))
	var section: VBoxContainer = ui._create_inspector_section(title)
	for key in ["id", "display_name", "object_type", "object_group", "state", "position", "tile_type", "tile_name"]:
		if data.has(key):
			var label := Label.new()
			label.text = ui._safe_ui_string(data.get(key, ""))
			section.add_child(ui._create_property_row(key, label))
	parent.add_child(section)

static func _add_floor_wall_coverage_sections(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, cell: Vector2i, data: Dictionary, entity_kind: String, entity_id: String, type_group: String, include_floor_coverage: bool = true, include_wall_coverage: bool = true) -> void:
	MapConstructorFloorWallControls.add_coverage_sections(ui, parent, entity_info, cell, data, entity_kind, entity_id, type_group, include_floor_coverage, include_wall_coverage)

static func _render_floor_tab(ui: Variant, parent: VBoxContainer, cell: Vector2i) -> void:
	var previous_pending: Vector2i = ui.pending_map_constructor_cell
	var previous_selected_cell: Vector2i = ui.selected_map_constructor_entity_cell
	ui.pending_map_constructor_cell = cell
	ui.selected_map_constructor_entity_cell = cell
	var floor_entity_info: Dictionary = {"ok": false, "cell": cell, "data": {}}
	_add_floor_wall_coverage_sections(ui, parent, floor_entity_info, cell, {}, "", "", "floor", true, false)
	ui.pending_map_constructor_cell = previous_pending
	ui.selected_map_constructor_entity_cell = previous_selected_cell


static func _render_wall_tab(ui: Variant, parent: VBoxContainer, entity: Dictionary, cell: Vector2i) -> void:
	var data: Dictionary = ui._safe_ui_dictionary(entity.get("data", {}))
	var entity_kind: String = str(entity.get("entity_kind", "wall"))
	var entity_id: String = str(entity.get("id", "wall_%d_%d" % [cell.x, cell.y]))
	var identity: VBoxContainer = ui._create_inspector_section("1. Identity")
	var id_label: Label = Label.new(); id_label.text = entity_id; identity.add_child(ui._create_property_row("ID", id_label))
	var type_label: Label = Label.new(); type_label.text = "wall"; identity.add_child(ui._create_property_row("Type", type_label))
	parent.add_child(identity)
	var placement: VBoxContainer = ui._create_inspector_section("2. Placement")
	var cell_label: Label = Label.new(); cell_label.text = str(cell); placement.add_child(ui._create_property_row("Cell", cell_label))
	var tile_label: Label = Label.new(); tile_label.text = ui._safe_ui_string(data.get("tile_name", data.get("tile_type", "wall")), "wall"); placement.add_child(ui._create_property_row("Tile", tile_label))
	var move_row: HBoxContainer = HBoxContainer.new()
	move_row.add_theme_constant_override("separation", 6)
	var move_x_label: Label = Label.new(); move_x_label.text = "X"
	var move_x: SpinBox = SpinBox.new(); move_x.step = 1; move_x.min_value = -999; move_x.max_value = 999; move_x.value = float(cell.x); move_x.custom_minimum_size = Vector2(72, 0)
	var move_y_label: Label = Label.new(); move_y_label.text = "Y"
	var move_y: SpinBox = SpinBox.new(); move_y.step = 1; move_y.min_value = -999; move_y.max_value = 999; move_y.value = float(cell.y); move_y.custom_minimum_size = Vector2(72, 0)
	var move_button: Button = Button.new(); move_button.text = "Move"
	move_button.pressed.connect(func() -> void:
		MapConstructorActions.move_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(move_x.value), int(move_y.value)))
	)
	move_row.add_child(move_x_label); move_row.add_child(move_x); move_row.add_child(move_y_label); move_row.add_child(move_y); move_row.add_child(move_button)
	placement.add_child(ui._create_property_row("Position", move_row))
	var duplicate_button: Button = Button.new(); duplicate_button.text = "Duplicate to X/Y"
	duplicate_button.pressed.connect(func() -> void:
		MapConstructorActions.duplicate_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(move_x.value), int(move_y.value)))
	)
	placement.add_child(duplicate_button)
	var delete_button: Button = Button.new(); delete_button.text = "Delete"
	delete_button.pressed.connect(func() -> void:
		MapConstructorActions.delete_entity_by_id(ui, entity_kind, entity_id, cell)
	)
	placement.add_child(delete_button)
	parent.add_child(placement)
	var status: VBoxContainer = ui._create_inspector_section("3. Wall Layer")
	var layer_label: Label = Label.new(); layer_label.text = "actual wall layer"; status.add_child(ui._create_property_row("Layer", layer_label))
	parent.add_child(status)
	var wall_entity_info: Dictionary = {"ok": true, "entity_kind": entity_kind, "id": entity_id, "cell": cell, "data": data}
	_add_floor_wall_coverage_sections(ui, parent, wall_entity_info, cell, data, entity_kind, entity_id, "wall", false, true)


static func _render_entity_tab(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, fallback_cell: Vector2i, include_wall_coverage: bool = false) -> void:
	var entity_kind: String = ui._safe_ui_string(entity_info.get("entity_kind", "world_object"), "world_object")
	var entity_id: String = ui._safe_ui_string(entity_info.get("id", ""))
	var data: Dictionary = ui._safe_ui_dictionary(entity_info.get("data", {})).duplicate(true)
	var cell: Vector2i = ui._safe_ui_vector2i(entity_info.get("cell", fallback_cell))
	ui.selected_map_constructor_entity_kind = entity_kind
	ui.selected_map_constructor_entity_id = entity_id
	ui.selected_map_constructor_entity_cell = cell
	if not (entity_kind in ["world_object", "item"]):
		_render_read_only_entity(ui, parent, entity_info, "Details")
		return
	var type_group: String = ui._safe_ui_string(ui.mission_manager_runtime.call("get_map_constructor_entity_type_group", entity_kind, entity_id), "generic") if ui.mission_manager_runtime.has_method("get_map_constructor_entity_type_group") else "generic"
	var identity: VBoxContainer = ui._create_inspector_section("1. Identity")
	var id_label: Label = Label.new(); id_label.text = entity_id; identity.add_child(ui._create_property_row("ID", id_label))
	ui._add_text_property(identity, "Name", entity_kind, entity_id, "display_name", data.get("display_name", ""))
	ui._add_map_constructor_description_editor(identity, data, entity_kind, entity_id)
	var normalized_object_type: String = _get_normalized_object_type(ui, data)
	var type_label: Label = Label.new(); type_label.text = normalized_object_type; identity.add_child(ui._create_property_row("Object type", type_label))
	var class_text: String = _get_normalized_object_class(ui, data, type_group)
	if not class_text.is_empty():
		var class_label: Label = Label.new(); class_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; class_label.text = class_text
		identity.add_child(ui._create_property_row("Object class", class_label))
	parent.add_child(identity)
	var current_status: VBoxContainer = ui._create_inspector_section("2. Current Status")
	if type_group == "power":
		if normalized_object_type == "power_cable":
			var install_label: Label = Label.new(); install_label.text = _get_cable_install_type(data); current_status.add_child(ui._create_property_row("Cable install type", install_label))
		var power_state_label: Label = Label.new(); power_state_label.text = "powered" if bool(data.get("is_powered", false)) else "unpowered"; current_status.add_child(ui._create_property_row("Power state", power_state_label))
		if data.has("is_on") or normalized_object_type == "power_source":
			var active_label: Label = Label.new(); active_label.text = "off" if ui._safe_ui_string(data.get("state", "on")).strip_edges().to_lower() == "off" or not bool(data.get("is_on", true)) else "on"; current_status.add_child(ui._create_property_row("Active state", active_label))
		var health_label: Label = Label.new(); health_label.text = _get_power_health_state(data); current_status.add_child(ui._create_property_row("Health state", health_label))
	else:
		var state_label: Label = Label.new(); state_label.text = ui._safe_ui_string(data.get("state", "(none)"), "(none)"); current_status.add_child(ui._create_property_row("state", state_label))
		for status_field in ["is_open", "is_closed", "is_locked", "is_powered", "damaged", "broken", "blocks_movement"]:
			if data.has(status_field):
				var status_value_label: Label = Label.new()
				status_value_label.text = ui._safe_ui_string(data.get(status_field, ""))
				current_status.add_child(ui._create_property_row(status_field, status_value_label))
	if entity_kind == "world_object" and type_group == "door" and ui.mission_manager_runtime.has_method("get_map_constructor_door_visual_state"):
		var door_visual: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_door_visual_state", entity_id))
		var door_visual_label: Label = Label.new(); door_visual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		door_visual_label.text = "visual=%s, badges=%s, note=%s" % [ui._safe_ui_string(door_visual.get("state", "unknown"), "unknown"), ui._safe_ui_string(door_visual.get("badges", [])), ui._safe_ui_string(door_visual.get("message", ""))]
		current_status.add_child(ui._create_property_row("Door visual", door_visual_label))
	if entity_kind == "world_object" and type_group == "terminal" and ui.mission_manager_runtime.has_method("get_map_constructor_terminal_visual_state"):
		var terminal_visual: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_terminal_visual_state", entity_id))
		var terminal_visual_label: Label = Label.new(); terminal_visual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		terminal_visual_label.text = "type=%s, state=%s, badges=%s" % [ui._safe_ui_string(terminal_visual.get("terminal_type", "unknown"), "unknown"), ui._safe_ui_string(terminal_visual.get("state", "unknown"), "unknown"), ui._safe_ui_string(terminal_visual.get("badges", []))]
		current_status.add_child(ui._create_property_row("Terminal visual", terminal_visual_label))
	parent.add_child(current_status)
	MapConstructorPropertyControls.add_circuit_block(ui, parent, entity_kind, entity_id, data)
	var placement: VBoxContainer = ui._create_inspector_section("4. Placement")
	var cell_l:=Label.new(); cell_l.text = ui._safe_ui_string(entity_info.get("cell", fallback_cell), str(fallback_cell)); placement.add_child(ui._create_property_row("Cell", cell_l))
	var pm_l:=Label.new(); pm_l.text = ui._safe_ui_string(data.get("placement_mode", "floor"), "floor"); placement.add_child(ui._create_property_row("Mode", pm_l))
	var move_row: HBoxContainer = HBoxContainer.new()
	var move_x: SpinBox = SpinBox.new(); move_x.step = 1; move_x.min_value = -999; move_x.max_value = 999; move_x.value = float(cell.x)
	var move_y: SpinBox = SpinBox.new(); move_y.step = 1; move_y.min_value = -999; move_y.max_value = 999; move_y.value = float(cell.y)
	var move_button: Button = Button.new(); move_button.text = "Move"
	move_button.pressed.connect(func() -> void:
		MapConstructorActions.move_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(move_x.value), int(move_y.value)))
	)
	move_row.add_child(move_x); move_row.add_child(move_y); move_row.add_child(move_button)
	placement.add_child(move_row)
	var dup_button: Button = Button.new(); dup_button.text = "Duplicate to X/Y"
	dup_button.pressed.connect(func() -> void:
		MapConstructorActions.duplicate_entity_to_cell(ui, entity_kind, entity_id, Vector2i(int(move_x.value), int(move_y.value)))
	)
	placement.add_child(dup_button)
	var del: Button = Button.new(); del.text = "Delete"
	del.pressed.connect(func() -> void:
		MapConstructorActions.delete_entity_by_id(ui, entity_kind, entity_id, cell)
	)
	placement.add_child(del)
	parent.add_child(placement)
	var configurable: VBoxContainer = ui._create_inspector_section("5. Configurable Parameters")
	var object_is_configurable: bool = bool(data.get("configurable", true))
	var object_archetype_id: String = ui._safe_ui_string(data.get("archetype_id", "")).strip_edges()
	if object_is_configurable and object_archetype_id.is_empty():
		if not (type_group == "power" and normalized_object_type in ["power_source", "power_cable"]):
			ui._add_preset_buttons(configurable, entity_kind, entity_id)
	var rendered_archetype_schema: bool = ui._add_archetype_schema_properties(configurable, entity_kind, entity_id, data) if object_is_configurable else false
	if object_is_configurable and not rendered_archetype_schema:
		ui._add_map_constructor_active_settings(configurable, entity_kind, entity_id, data, type_group)
	if (type_group == "control" or data.has("requires_external_control")) and normalized_object_type != "power_source":
		ui._add_bool_property(configurable, "requires_external_control", entity_kind, entity_id, "requires_external_control", data.get("requires_external_control", false))
	var inspector_object_type: String = ui._safe_ui_string(data.get("object_type", "")).to_lower()
	var uses_dedicated_power_state_selector: bool = type_group == "power" and (inspector_object_type.begins_with("power_source") or inspector_object_type in ["power_cable", "power_cable_reel"])
	if object_is_configurable and data.has("state") and normalized_object_type not in ["power_switcher", "fuse_box"] and not (type_group == "door" or uses_dedicated_power_state_selector):
		ui._add_text_property(configurable, "Editable state override", entity_kind, entity_id, "state", data.get("state", ""))
	if type_group == "terminal":
		ui._add_bool_property(configurable, "damaged", entity_kind, entity_id, "damaged", data.get("damaged", false))
		ui._add_bool_property(configurable, "encrypted", entity_kind, entity_id, "encrypted", data.get("encrypted", false))
	if type_group == "power":
		var power_object_type: String = normalized_object_type
		if power_object_type == "power_source":
			var source_active_state: String = "off" if ui._safe_ui_string(data.get("state", "on")).strip_edges().to_lower() == "off" else "on"
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Active state", entity_kind, entity_id, source_active_state, [{"label":"On", "value":"on", "updates":{"state":"on"}}, {"label":"Off", "value":"off", "updates":{"state":"off"}}])
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Health state", entity_kind, entity_id, _get_power_health_state(data), [{"label":"Normal", "value":"normal", "updates":{"state":"on", "damaged":false}}, {"label":"Damaged", "value":"damaged", "updates":{"state":"damaged", "damaged":true}}, {"label":"Broken", "value":"broken", "updates":{"state":"broken", "damaged":true}}])
			var source_class_options: Array[Dictionary] = [{"label":"C1 (4 outlets)", "value":"1"}, {"label":"C2 (5 outlets)", "value":"2"}, {"label":"C3 (6 outlets)", "value":"3"}]
			ui._add_enum_property(configurable, "Source class", entity_kind, entity_id, "power_source_class", data.get("power_source_class", 1), source_class_options)
		elif power_object_type == "power_cable" or power_object_type == "power_cable_reel":
			var cable_has_wall: bool = _cell_has_wall(ui, cell)
			if power_object_type == "power_cable_reel":
				MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Mount", entity_kind, entity_id, _get_cable_install_type(data), [{"label":"Floor", "value":"floor", "updates":{"mount":"floor", "cable_install_mode":"floor", "install_mode":"floor", "route_surface":"floor"}}, {"label":"Wall", "value":"wall", "updates":{"mount":"wall", "cable_install_mode":"wall", "install_mode":"wall", "route_surface":"wall"}, "disabled": not cable_has_wall, "disabled_reason":"Wall cable reel requires a wall in this cell."}])
				if not cable_has_wall:
					_add_cable_note(ui, configurable, "Wall cable reel requires a wall in this cell.", true)
			else:
				MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Install mode", entity_kind, entity_id, _get_cable_install_type(data), [{"label":"Floor", "value":"floor", "updates":{"cable_install_mode":"floor", "install_mode":"floor", "route_surface":"floor"}}, {"label":"Wall", "value":"wall", "updates":{"cable_install_mode":"wall", "install_mode":"wall", "route_surface":"wall"}, "disabled": not cable_has_wall, "disabled_reason":"Wall cable requires a wall in this cell."}, {"label":"Hidden", "value":"hidden", "updates":{"cable_install_mode":"hidden", "install_mode":"hidden", "route_surface":"floor"}}])
				if not cable_has_wall:
					_add_cable_note(ui, configurable, "Wall cable requires a wall in this cell.", true)
			if _get_cable_install_type(data) == "hidden":
				_add_cable_note(ui, configurable, "Hidden cables are visible only in the editor.")
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Health state", entity_kind, entity_id, _get_power_health_state(data), [{"label":"Normal", "value":"normal", "updates":{"cable_health_state":"normal"}}, {"label":"Damaged", "value":"damaged", "updates":{"cable_health_state":"damaged"}}, {"label":"Broken", "value":"broken", "updates":{"cable_health_state":"broken"}}, {"label":"Cut", "value":"cut", "updates":{"cable_health_state":"cut"}}])
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Power state", entity_kind, entity_id, "powered" if bool(data.get("is_powered", false)) else "unpowered", [{"label":"Powered", "value":"powered", "updates":{"is_powered":true}}, {"label":"Unpowered", "value":"unpowered", "updates":{"is_powered":false}}])
		elif power_object_type == "light":
			ui._add_text_property(configurable, "Brightness", entity_kind, entity_id, "brightness", data.get("brightness", "1.0"))
			ui._add_text_property(configurable, "Color", entity_kind, entity_id, "color", data.get("color", "#ffffff"))
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Power state", entity_kind, entity_id, "powered" if bool(data.get("is_powered", false)) else "unpowered", [{"label":"Powered", "value":"powered", "updates":{"is_powered":true}}, {"label":"Unpowered", "value":"unpowered", "updates":{"is_powered":false}}])
			MapConstructorPropertyControls.add_enum_updates_property(ui, configurable, "Health state", entity_kind, entity_id, _get_power_health_state(data), [{"label":"Normal", "value":"normal", "updates":{"damaged":false}}, {"label":"Damaged", "value":"damaged", "updates":{"damaged":true}}, {"label":"Broken", "value":"broken", "updates":{"state":"broken", "damaged":true}}])
	if type_group == "item":
		var item_type_label: Label = Label.new()
		item_type_label.text = ui._safe_ui_string(data.get("item_type", data.get("object_type", "item")), "item")
		configurable.add_child(ui._create_property_row("Item type", item_type_label))
		if data.has("digital_payload_type") or ui._safe_ui_string(data.get("item_type", "")).findn("digital") >= 0 or ui._safe_ui_string(data.get("item_type", "")).findn("access_code") >= 0:
			ui._add_text_property(configurable, "digital_payload_type", entity_kind, entity_id, "digital_payload_type", data.get("digital_payload_type", ""))
	if configurable.get_child_count() <= 1:
		var no_config_label: Label = Label.new()
		no_config_label.text = "No configurable object-specific parameters."
		configurable.add_child(no_config_label)
	parent.add_child(configurable)
	var link_section: VBoxContainer = ui._create_inspector_section("6. Links")
	ui._add_map_constructor_object_link_sections(link_section, entity_kind, entity_id, data, type_group)
	var validation_result: Dictionary = {}
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("validate_map_constructor_entity_links"):
		validation_result = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("validate_map_constructor_entity_links", entity_kind, entity_id))
		MapConstructorValidationView.add_linked_targets(ui, link_section, validation_result)
	parent.add_child(link_section)
	var warning_section: VBoxContainer = ui._create_inspector_section("7. Warnings")
	MapConstructorValidationView.add_warning_entries(ui, warning_section, validation_result)
	parent.add_child(warning_section)
	if include_wall_coverage:
		_add_floor_wall_coverage_sections(ui, parent, entity_info, cell, data, entity_kind, entity_id, type_group, false, true)


static func refresh(ui: Variant, cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> void:
	var previous_entity_kind: String = ui.selected_map_constructor_entity_kind
	var previous_entity_id: String = ui.selected_map_constructor_entity_id
	var previous_cell: Vector2i = ui.selected_map_constructor_entity_cell
	if preferred_entity_id.is_empty() and previous_cell != cell:
		ui.map_constructor_active_inspector_tab_id = ""
		ui.map_constructor_active_inspector_entity_id = ""
		ui.map_constructor_active_inspector_entity_kind = ""
	var preserve_scroll_value: int = 0
	if ui.runtime_map_constructor_inspector_scroll != null and is_instance_valid(ui.runtime_map_constructor_inspector_scroll):
		preserve_scroll_value = ui.runtime_map_constructor_inspector_scroll.scroll_vertical
	clear(ui)
	if not ui.map_constructor_mode_active:
		ui._set_runtime_bottom_hud_visible(true)
		return
	ui._set_runtime_bottom_hud_visible(false)
	ui._ensure_runtime_hud_root()
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_cell_inspection_model"):
		return
	var model: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_cell_inspection_model", cell, preferred_entity_kind, preferred_entity_id))
	if not bool(model.get("ok", false)):
		return
	var selected_cell: Vector2i = ui._safe_ui_vector2i(model.get("cell", cell))
	ui.pending_map_constructor_cell = selected_cell
	var tabs: Array = ui._safe_ui_array(model.get("tabs", []))
	var preferred_tab_id: String = _choose_preferred_tab_id(ui, tabs, ui._safe_ui_string(model.get("preferred_tab", "floor"), "floor"), preferred_entity_kind, preferred_entity_id)
	if preferred_tab_id.is_empty() and not preferred_entity_id.is_empty():
		var preferred_entity: Dictionary = _find_entity_in_tabs(tabs, preferred_entity_kind, preferred_entity_id)
		preferred_tab_id = _get_tab_id_for_entity(ui, preferred_entity_kind, ui._safe_ui_dictionary(preferred_entity.get("data", {}))) if not preferred_entity.is_empty() else "floor"
	var panel: PanelContainer = _build_cell_panel(ui, selected_cell)
	var inspector_rect: Rect2 = ui._get_map_constructor_bottom_inspector_rect()
	var stack: VBoxContainer = panel.get_child(0).get_child(0) as VBoxContainer
	var tab_container := TabContainer.new()
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(tab_container)
	var selected_tab_index: int = 0
	var selected_tab_entity: Dictionary = {}
	tab_container.tab_changed.connect(func(tab_index: int) -> void:
		if tab_index < 0 or tab_index >= tabs.size():
			return
		var changed_tab: Dictionary = Dictionary(tabs[tab_index])
		ui.map_constructor_active_inspector_tab_id = ui._safe_ui_string(changed_tab.get("id", ""))
		var changed_entity: Dictionary = _choose_tab_entity(ui, changed_tab, preferred_entity_kind, preferred_entity_id)
		ui.map_constructor_active_inspector_entity_kind = ui._safe_ui_string(changed_entity.get("entity_kind", ""))
		ui.map_constructor_active_inspector_entity_id = ui._safe_ui_string(changed_entity.get("id", ""))
	)
	for tab_variant in tabs:
		var tab: Dictionary = Dictionary(tab_variant)
		var tab_id: String = ui._safe_ui_string(tab.get("id", ""))
		var content: VBoxContainer = _make_tab_content(ui, inspector_rect)
		var scroll: ScrollContainer = content.get_parent() as ScrollContainer
		scroll.name = ui._safe_ui_string(tab.get("title", tab_id), tab_id)
		tab_container.add_child(scroll)
		var tab_index: int = tab_container.get_tab_count() - 1
		tab_container.set_tab_title(tab_index, ui._safe_ui_string(tab.get("title", tab_id), tab_id))
		var entity: Dictionary = _choose_tab_entity(ui, tab, preferred_entity_kind, preferred_entity_id)
		_add_entity_selector(ui, content, tab, entity, selected_cell)
		match tab_id:
			"floor":
				_render_floor_tab(ui, content, selected_cell)
			"walls":
				_render_wall_tab(ui, content, entity, selected_cell)
			_:
				_render_entity_tab(ui, content, entity, selected_cell, false)
		if tab_id == preferred_tab_id:
			selected_tab_index = tab_index
			selected_tab_entity = entity
	if tab_container.get_tab_count() > 0:
		tab_container.current_tab = selected_tab_index
		ui.map_constructor_active_inspector_tab_id = ui._safe_ui_string(Dictionary(tabs[selected_tab_index]).get("id", ""))
		var selected_scroll: ScrollContainer = tab_container.get_child(selected_tab_index) as ScrollContainer
		ui.runtime_map_constructor_inspector_scroll = selected_scroll
		if selected_tab_entity.is_empty():
			selected_tab_entity = _choose_tab_entity(ui, Dictionary(tabs[selected_tab_index]), preferred_entity_kind, preferred_entity_id)
		if not selected_tab_entity.is_empty() and str(selected_tab_entity.get("entity_kind", "")) in ["world_object", "item"]:
			ui.selected_map_constructor_entity_kind = str(selected_tab_entity.get("entity_kind", ""))
			ui.selected_map_constructor_entity_id = str(selected_tab_entity.get("id", ""))
			ui.selected_map_constructor_entity_cell = ui._safe_ui_vector2i(selected_tab_entity.get("cell", selected_cell))
		else:
			ui.selected_map_constructor_entity_kind = ""
			ui.selected_map_constructor_entity_id = ""
			ui.selected_map_constructor_entity_cell = selected_cell
		ui.map_constructor_active_inspector_entity_kind = ui.selected_map_constructor_entity_kind
		ui.map_constructor_active_inspector_entity_id = ui.selected_map_constructor_entity_id
		if previous_entity_kind == ui.selected_map_constructor_entity_kind and previous_entity_id == ui.selected_map_constructor_entity_id:
			ui._restore_map_constructor_inspector_scroll_deferred(selected_scroll, preserve_scroll_value)
	ui.runtime_hud_root.add_child(panel)
	ui.runtime_hud_root.move_child(panel, ui.runtime_hud_root.get_child_count() - 1)
	ui._sync_map_constructor_overlay_visuals()
	if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
		ui.field_runtime.call("request_visual_refresh")
