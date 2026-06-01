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
		if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("update_map_constructor_entity_properties"):
			return
		var result: Dictionary = ui.mission_manager_runtime.call("update_map_constructor_entity_properties", entity_kind, entity_id, {"description": desc_edit.text})
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Description updated."), "Description updated."))
		ui._refresh_map_constructor_panels()
		if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
			ui.field_runtime.call("request_visual_refresh")
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
	section.add_child(create_property_row("Description", desc_edit))
	var apply_button: Button = Button.new()
	apply_button.text = "Apply Description"
	apply_button.pressed.connect(func() -> void:
		apply_description.call()
	)
	section.add_child(apply_button)

static func create_map_constructor_description_block(ui: Variant, data: Dictionary, entity_kind: String, entity_id: String) -> Control:
	var section: VBoxContainer = create_inspector_section("Description")
	add_map_constructor_description_editor(ui, section, data, entity_kind, entity_id)
	return section

static func create_inspector_section(title: String) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	var header: Label = Label.new()
	header.text = title
	section.add_child(header)
	return section

static func create_property_row(label_text: String, control: Control) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 0)
	row.add_child(label)
	row.add_child(control)
	return row

static func add_text_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = MapConstructorUiSafe.safe_string(current_value)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_text_update := func() -> void:
		if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("update_map_constructor_entity_properties"):
			return
		var result: Dictionary = ui.mission_manager_runtime.call("update_map_constructor_entity_properties", entity_kind, entity_id, {field_name: line_edit.text})
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Updated."), "Updated."))
		ui._refresh_map_constructor_panels()
		if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
			ui.field_runtime.call("request_visual_refresh")
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
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
	section.add_child(create_property_row(label, row_controls))

static func add_bool_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var check: CheckBox = CheckBox.new()
	check.button_pressed = bool(current_value)
	check.toggled.connect(func(pressed: bool) -> void:
		if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("update_map_constructor_entity_properties"):
			return
		var result: Dictionary = ui.mission_manager_runtime.call("update_map_constructor_entity_properties", entity_kind, entity_id, {field_name: pressed})
		ui.show_hint(MapConstructorUiSafe.safe_string(result.get("message", "Updated."), "Updated."))
		ui._refresh_map_constructor_panels()
		if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
			ui.field_runtime.call("request_visual_refresh")
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
	)
	section.add_child(create_property_row(label, check))

static func add_preset_buttons(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String) -> void:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_property_presets"):
		return
	var row: HFlowContainer = HFlowContainer.new()
	for preset in MapConstructorUiSafe.safe_array(ui.mission_manager_runtime.call("get_map_constructor_property_presets", entity_kind, entity_id)):
		var preset_data: Dictionary = MapConstructorUiSafe.safe_dictionary(preset)
		var preset_id: String = String(preset_data.get("id", ""))
		if preset_id.is_empty():
			continue
		var button: Button = Button.new()
		button.text = String(preset_data.get("label", "Preset"))
		button.pressed.connect(func() -> void:
			if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("apply_map_constructor_property_preset"):
				return
			var result: Dictionary = ui.mission_manager_runtime.call("apply_map_constructor_property_preset", entity_kind, entity_id, preset_id)
			ui.show_hint(String(result.get("message", "Preset applied.")))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
				ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
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
	section.add_child(create_property_row(label, option))


static func add_int_property(ui: Variant, section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	var spin: SpinBox = SpinBox.new()
	spin.step = 1
	spin.min_value = 0
	spin.max_value = 999999
	spin.value = float(current_value)
	spin.value_changed.connect(func(value: float) -> void:
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {field_name:int(value)})
	)
	section.add_child(create_property_row(label, spin))

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
	section.add_child(create_property_row(label, menu))

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
			add_enum_property(ui, section, field_name.replace("_", " ").capitalize(), entity_kind, entity_id, field_name, current_value, options)
		elif field_type == "enum_array":
			add_enum_array_property(ui, section, field_name.replace("_", " ").capitalize(), entity_kind, entity_id, field_name, current_value, MapConstructorUiSafe.safe_array(row.get("values", [])))
		elif field_type == "bool":
			add_bool_property(ui, section, field_name.replace("_", " ").capitalize(), entity_kind, entity_id, field_name, current_value)
		elif field_type == "int":
			add_int_property(ui, section, field_name.replace("_", " ").capitalize(), entity_kind, entity_id, field_name, current_value)
		else:
			add_text_property(ui, section, field_name.replace("_", " ").capitalize(), entity_kind, entity_id, field_name, current_value)
	return not schema_rows.is_empty()
