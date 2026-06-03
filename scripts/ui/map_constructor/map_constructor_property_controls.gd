extends RefCounted
class_name MapConstructorPropertyControls

static func add_map_constructor_description_editor(ui: Variant, section: VBoxContainer, data: Dictionary, entity_kind: String, entity_id: String) -> void:
	var description_text: String = MapConstructorUiSafe.safe_string(data.get("description", data.get("custom_description", ""))).strip_edges()
	var desc_edit: TextEdit = TextEdit.new()
	desc_edit.text = description_text
	desc_edit.placeholder_text = "No description."
	desc_edit.custom_minimum_size = Vector2(0.0, 72.0)
	desc_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_description := func() -> void:
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {"description": desc_edit.text}, "Description updated.")
	section.add_child(create_property_row(ui, "Description", desc_edit))
	var apply_button: Button = Button.new()
	apply_button.text = "Apply Description"
	apply_button.pressed.connect(func() -> void:
		apply_description.call()
	)
	section.add_child(apply_button)

static func create_map_constructor_description_block(ui: Variant, data: Dictionary, entity_kind: String, entity_id: String) -> Control:
	var section: VBoxContainer = create_inspector_section(ui, "Description")
	add_map_constructor_description_editor(ui, section, data, entity_kind, entity_id)
	return section

static func create_inspector_section(_ui: Variant, title: String) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	var header: Label = Label.new()
	header.text = title
	section.add_child(header)
	return section

static func create_property_row(_ui: Variant, label_text: String, control: Control, expand_layout: bool = false) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(420, 0)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var control_minimum_size: Vector2 = control.custom_minimum_size
	control_minimum_size.x = maxf(control_minimum_size.x, 220.0)
	control.custom_minimum_size = control_minimum_size
	if control is Label:
		var value_label: Label = control
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		value_label.clip_text = true
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	elif control is LineEdit:
		var value_edit: LineEdit = control
		value_edit.expand_to_text_length = false
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(label)
	row.add_child(control)
	return row

static func add_text_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = MapConstructorUiSafe.safe_string(current_value)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_text_update := func() -> void:
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name: line_edit.text})
	line_edit.text_submitted.connect(func(_text: String) -> void:
		apply_text_update.call()
	)
	var apply_button: Button = Button.new()
	apply_button.text = "Apply"
	apply_button.pressed.connect(func() -> void:
		apply_text_update.call()
	)
	var row_controls: HBoxContainer = HBoxContainer.new()
	row_controls.add_theme_constant_override("separation", 6)
	row_controls.add_child(line_edit)
	row_controls.add_child(apply_button)
	section.add_child(create_property_row(ui, label, row_controls))

static func add_bool_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var check: CheckBox = CheckBox.new()
	check.button_pressed = bool(current_value)
	check.text = "☑ Enabled" if check.button_pressed else "☐ Disabled"
	check.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
	check.add_theme_color_override("font_pressed_color", ui.UI_COLOR_OK)
	check.toggled.connect(func(pressed: bool) -> void:
		check.text = "☑ Enabled" if pressed else "☐ Disabled"
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name: pressed})
	)
	section.add_child(create_property_row(ui, label, check))

static func add_preset_buttons(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String) -> void:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_property_presets"):
		return
	var row: HFlowContainer = HFlowContainer.new()
	for preset in MapConstructorUiSafe.safe_array(ui.mission_manager_runtime.call("get_map_constructor_property_presets", entity_kind, entity_id)):
		var preset_data: Dictionary = MapConstructorUiSafe.safe_dictionary(preset)
		var preset_id: String = str(preset_data.get("id", ""))
		if preset_id.is_empty():
			continue
		var button: Button = Button.new()
		button.text = str(preset_data.get("label", "Preset"))
		button.pressed.connect(func() -> void:
			ui._apply_map_constructor_property_preset(entity_kind, entity_id, preset_id)
		)
		row.add_child(button)
	if row.get_child_count() > 0:
		section.add_child(row)

static func add_enum_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant, options: Array[Dictionary]) -> void:
	var option: OptionButton = OptionButton.new()
	var current_text: String = MapConstructorUiSafe.safe_string(current_value).strip_edges().to_lower()
	var selected_index: int = -1
	for option_variant in options:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(option_variant)
		var value: String = MapConstructorUiSafe.safe_string(row.get("value", "")).strip_edges()
		option.add_item(MapConstructorUiSafe.safe_string(row.get("label", value), value))
		var index: int = option.item_count - 1
		option.set_item_metadata(index, value)
		if value == current_text:
			selected_index = index
	if selected_index >= 0:
		option.select(selected_index)
	option.item_selected.connect(func(index: int) -> void:
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name: MapConstructorUiSafe.safe_string(option.get_item_metadata(index))})
	)
	section.add_child(create_property_row(ui, label, option))



static func add_enum_updates_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, current_value: Variant, options: Array[Dictionary]) -> void:
	var option: OptionButton = OptionButton.new()
	var current_text: String = MapConstructorUiSafe.safe_string(current_value).strip_edges().to_lower()
	var selected_index: int = -1
	for option_variant in options:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(option_variant)
		var value: String = MapConstructorUiSafe.safe_string(row.get("value", "")).strip_edges()
		option.add_item(MapConstructorUiSafe.safe_string(row.get("label", value), value))
		var index: int = option.item_count - 1
		option.set_item_metadata(index, row)
		if bool(row.get("disabled", false)):
			option.set_item_disabled(index, true)
			option.set_item_tooltip(index, MapConstructorUiSafe.safe_string(row.get("disabled_reason", "Unavailable."), "Unavailable."))
		if value == current_text:
			selected_index = index
	if selected_index >= 0:
		option.select(selected_index)
	option.item_selected.connect(func(index: int) -> void:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(option.get_item_metadata(index))
		var updates: Dictionary = MapConstructorUiSafe.safe_dictionary(row.get("updates", {}))
		if updates.is_empty() and row.has("field"):
			updates[MapConstructorUiSafe.safe_string(row.get("field", ""))] = row.get("value", "")
		if not updates.is_empty():
			ui._apply_map_constructor_property_updates(entity_kind, entity_id, updates)
	)
	section.add_child(create_property_row(ui, label, option))

static func add_int_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var spin: SpinBox = SpinBox.new()
	spin.step = 1
	spin.min_value = 0
	spin.max_value = 999999
	spin.value = float(current_value)
	spin.value_changed.connect(func(value: float) -> void:
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:int(value)})
	)
	section.add_child(create_property_row(ui, label, spin))

static func add_enum_array_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant, values: Array) -> void:
	var menu: MenuButton = MenuButton.new()
	var selected_values: Array = MapConstructorUiSafe.safe_array(current_value).duplicate()
	menu.text = ", ".join(selected_values)
	var popup: PopupMenu = menu.get_popup()
	for value_variant in values:
		var value: String = MapConstructorUiSafe.safe_string(value_variant)
		popup.add_check_item(value.replace("_", " ").capitalize())
		var index: int = popup.item_count - 1
		popup.set_item_metadata(index, value)
		popup.set_item_checked(index, selected_values.has(value))
	popup.id_pressed.connect(func(index: int) -> void:
		var value: String = MapConstructorUiSafe.safe_string(popup.get_item_metadata(index))
		if selected_values.has(value):
			selected_values.erase(value)
		else:
			selected_values.append(value)
		popup.set_item_checked(index, selected_values.has(value))
		menu.text = ", ".join(selected_values)
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:selected_values.duplicate()})
	)
	section.add_child(create_property_row(ui, label, menu))

static func add_circuit_block(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var object_type: String = MapConstructorUiSafe.safe_string(data.get("object_type", data.get("item_type", ""))).strip_edges().to_lower()
	if not object_type.begins_with("power_source"):
		return
	var section: VBoxContainer = create_inspector_section(ui, "3. Circuit")
	var summary: Dictionary = {}
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_circuit_summary"):
		summary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("get_map_constructor_circuit_summary", entity_kind, entity_id))
	var circuit_id: String = MapConstructorUiSafe.safe_string(summary.get("circuit_id", "")).strip_edges()
	if circuit_id.is_empty() and ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_normalized_map_constructor_circuit_id"):
		circuit_id = MapConstructorUiSafe.safe_string(ui.mission_manager_runtime.call("get_normalized_map_constructor_circuit_id", data)).strip_edges()
	var id_label: Label = Label.new()
	id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	id_label.text = circuit_id if not circuit_id.is_empty() else "No circuit assigned"
	section.add_child(create_property_row(ui, "Circuit id", id_label))
	var list_box: VBoxContainer = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 4)
	var has_main: bool = false
	for option_variant_list in MapConstructorUiSafe.safe_array(summary.get("options", [])):
		var option_data_list: Dictionary = MapConstructorUiSafe.safe_dictionary(option_variant_list)
		var option_id_list: String = MapConstructorUiSafe.safe_string(option_data_list.get("id", "")).strip_edges()
		if option_id_list.is_empty():
			continue
		if option_id_list == "main":
			has_main = true
		var circuit_row: HBoxContainer = HBoxContainer.new()
		circuit_row.add_theme_constant_override("separation", 6)
		var circuit_label: Label = Label.new()
		circuit_label.text = MapConstructorUiSafe.safe_string(option_data_list.get("label", option_id_list), option_id_list)
		circuit_label.clip_text = true
		circuit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		circuit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		circuit_row.add_child(circuit_label)
		var delete_button: Button = Button.new()
		delete_button.text = "Delete"
		delete_button.disabled = option_id_list == "main" or ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("delete_map_constructor_circuit")
		delete_button.pressed.connect(func() -> void:
			if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("delete_map_constructor_circuit"):
				return
			var result: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("delete_map_constructor_circuit", option_id_list))
			ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Circuit deleted."), "Circuit deleted."))
			ui._refresh_map_constructor_panels()
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, entity_kind, entity_id)
		)
		circuit_row.add_child(delete_button)
		list_box.add_child(circuit_row)
	if not has_main:
		var main_label: Label = Label.new()
		main_label.text = "main"
		list_box.add_child(main_label)
	section.add_child(create_property_row(ui, "Circuits", list_box))
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = MapConstructorUiSafe.safe_string(summary.get("circuit_name", data.get("circuit_name", ""))).strip_edges()
	name_edit.placeholder_text = "Circuit display name"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rename_button: Button = Button.new()
	rename_button.text = "Rename circuit"
	rename_button.disabled = circuit_id.is_empty()
	rename_button.pressed.connect(func() -> void:
		if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("rename_map_constructor_circuit"):
			return
		var result: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("rename_map_constructor_circuit", entity_kind, entity_id, name_edit.text))
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Circuit renamed."), "Circuit renamed."))
		ui._refresh_map_constructor_panels()
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, entity_kind, entity_id)
	)
	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	name_row.add_child(name_edit)
	name_row.add_child(rename_button)
	section.add_child(create_property_row(ui, "Name", name_row))
	var create_id_edit: LineEdit = LineEdit.new()
	create_id_edit.placeholder_text = "New circuit id (blank = auto)"
	create_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var create_name_edit: LineEdit = LineEdit.new()
	create_name_edit.placeholder_text = "New circuit name"
	create_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var create_button: Button = Button.new()
	create_button.text = "Create new circuit"
	create_button.pressed.connect(func() -> void:
		if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("create_map_constructor_circuit"):
			return
		var result: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("create_map_constructor_circuit", entity_kind, entity_id, create_id_edit.text, create_name_edit.text))
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Circuit created."), "Circuit created."))
		ui._refresh_map_constructor_panels()
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, entity_kind, entity_id)
	)
	var create_row: VBoxContainer = VBoxContainer.new()
	create_row.add_theme_constant_override("separation", 4)
	create_row.add_child(create_id_edit)
	create_row.add_child(create_name_edit)
	create_row.add_child(create_button)
	section.add_child(create_property_row(ui, "Create", create_row))
	var assign_option: OptionButton = OptionButton.new()
	assign_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected_index: int = -1
	for option_variant in MapConstructorUiSafe.safe_array(summary.get("options", [])):
		var option_data: Dictionary = MapConstructorUiSafe.safe_dictionary(option_variant)
		var option_id: String = MapConstructorUiSafe.safe_string(option_data.get("id", "")).strip_edges()
		if option_id.is_empty():
			continue
		assign_option.add_item(MapConstructorUiSafe.safe_string(option_data.get("label", option_id), option_id))
		var index: int = assign_option.item_count - 1
		assign_option.set_item_metadata(index, option_id)
		if option_id == circuit_id:
			selected_index = index
	if selected_index >= 0:
		assign_option.select(selected_index)
	var assign_button: Button = Button.new()
	assign_button.text = "Set source circuit"
	assign_button.disabled = assign_option.item_count <= 0
	assign_button.pressed.connect(func() -> void:
		if assign_option.get_selected() < 0 or ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("assign_map_constructor_entity_to_circuit"):
			return
		var target_circuit_id: String = MapConstructorUiSafe.safe_string(assign_option.get_item_metadata(assign_option.get_selected())).strip_edges()
		var result: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("assign_map_constructor_entity_to_circuit", entity_kind, entity_id, target_circuit_id, ""))
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Circuit assigned."), "Circuit assigned."))
		ui._refresh_map_constructor_panels()
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, entity_kind, entity_id)
	)
	var assign_row: HBoxContainer = HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 6)
	assign_row.add_child(assign_option)
	assign_row.add_child(assign_button)
	section.add_child(create_property_row(ui, "Assign", assign_row))
	var copy_button: Button = Button.new()
	copy_button.text = "Copy circuit from selected object / current cell"
	copy_button.disabled = circuit_id.is_empty()
	copy_button.pressed.connect(func() -> void:
		if circuit_id.is_empty():
			ui.show_hint("No circuit assigned")
			return
		DisplayServer.clipboard_set(circuit_id)
		ui.show_hint("Copied circuit %s." % circuit_id)
	)
	section.add_child(copy_button)
	parent.add_child(section)

static func get_display_label(field_name: String) -> String:
	var label: String = field_name.replace("_", " ").capitalize()
	if field_name in ["required_manipulator_level", "required_connector_level", "required_processor_level"]:
		label = label.replace(" Level", " Version")
	return label

static func add_archetype_schema_properties(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> bool:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_archetype_property_schema"):
		return false
	var schema_rows: Array = MapConstructorUiSafe.safe_array(ui.mission_manager_runtime.call("get_map_constructor_archetype_property_schema", entity_kind, entity_id))
	for row_variant in schema_rows:
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(row_variant)
		var field_name: String = MapConstructorUiSafe.safe_string(row.get("field", ""))
		var field_type: String = MapConstructorUiSafe.safe_string(row.get("type", "string"))
		var current_value: Variant = data.get(field_name, row.get("default"))
		if field_type == "enum":
			var options: Array[Dictionary] = []
			var labels: Dictionary = MapConstructorUiSafe.safe_dictionary(row.get("labels", {}))
			for value_variant in MapConstructorUiSafe.safe_array(row.get("values", [])):
				var value: String = MapConstructorUiSafe.safe_string(value_variant)
				options.append({"label":MapConstructorUiSafe.safe_string(labels.get(value, value.replace("_", " ").capitalize())), "value":value})
			add_enum_property(ui, section, get_display_label(field_name), entity_kind, entity_id, field_name, current_value, options)
		elif field_type == "enum_array":
			add_enum_array_property(ui, section, get_display_label(field_name), entity_kind, entity_id, field_name, current_value, MapConstructorUiSafe.safe_array(row.get("values", [])))
		elif field_type == "bool":
			add_bool_property(ui, section, get_display_label(field_name), entity_kind, entity_id, field_name, current_value)
		elif field_type == "int":
			add_int_property(ui, section, get_display_label(field_name), entity_kind, entity_id, field_name, current_value)
		else:
			add_text_property(ui, section, get_display_label(field_name), entity_kind, entity_id, field_name, current_value)
	return not schema_rows.is_empty()
