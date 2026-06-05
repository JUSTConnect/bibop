extends RefCounted
class_name MapConstructorTerminalStoredDataControls

const TerminalVisibilityServiceRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector_visibility_service.gd")

static func add_stored_data_section(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if not TerminalVisibilityServiceRef.should_show_terminal_stored_data(data):
		return
	var section: VBoxContainer = ui._create_inspector_section("Stored Data")
	var stored_data_type: String = TerminalVisibilityServiceRef.normalize_stored_data_type(data)
	var options: Array[Dictionary] = [
		{"label":"Access Code", "value":"access_code", "updates":{"stored_data_type":"access_code", "digital_payload_type":"access_code", "encrypted":false, "damaged":false}},
		{"label":"Digital Key", "value":"digital_key", "updates":{"stored_data_type":"digital_key", "digital_payload_type":"digital_key", "encrypted":false, "damaged":false}},
		{"label":"Data File", "value":"data_file", "updates":{"stored_data_type":"data_file", "digital_payload_type":"data_file"}}
	]
	MapConstructorPropertyControls.add_enum_updates_property(ui, section, "Stored data type", entity_kind, entity_id, stored_data_type, options)
	if stored_data_type == "access_code":
		_add_access_code_controls(ui, section, entity_kind, entity_id, data)
	elif stored_data_type == "digital_key":
		_add_digital_key_controls(ui, section, entity_kind, entity_id, data)
	else:
		_add_data_file_controls(ui, section, entity_kind, entity_id, data)
	parent.add_child(section)

static func _add_access_code_controls(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var code_value: String = str(data.get("stored_access_code", data.get("access_code_value", data.get("access_code", "")))).strip_edges()
	var code_edit: LineEdit = LineEdit.new()
	code_edit.text = code_value
	code_edit.placeholder_text = "4 digit code"
	code_edit.max_length = 4
	code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_button: Button = Button.new()
	apply_button.text = "Apply"
	apply_button.pressed.connect(func() -> void:
		var next_code: String = code_edit.text.strip_edges()
		if next_code.length() != 4 or not next_code.is_valid_int():
			ui.show_hint("Access code must be exactly 4 digits.")
			return
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {"stored_access_code":next_code, "access_code_value":next_code, "access_code":next_code, "encrypted":false, "damaged":false})
	)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(code_edit)
	row.add_child(apply_button)
	section.add_child(ui._create_property_row("Access code", row))
	_add_note(ui, section, "Access code is always 4 digits and cannot be encrypted or damaged.", false)

static func _add_digital_key_controls(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	var current_key_id: String = str(data.get("stored_digital_key_id", data.get("stored_key_id", ""))).strip_edges()
	var option: OptionButton = OptionButton.new()
	option.add_item("(no digital key)")
	option.set_item_metadata(0, "")
	if current_key_id.is_empty():
		option.select(0)
	var selected_index: int = 0
	for candidate in _get_digital_key_candidates(ui):
		var candidate_data: Dictionary = Dictionary(candidate)
		var candidate_id: String = str(candidate_data.get("id", "")).strip_edges()
		if candidate_id.is_empty():
			continue
		option.add_item(str(candidate_data.get("label", candidate_id)))
		var index: int = option.item_count - 1
		option.set_item_metadata(index, candidate_id)
		if candidate_id == current_key_id:
			selected_index = index
	option.select(selected_index)
	option.item_selected.connect(func(index: int) -> void:
		var key_id: String = str(option.get_item_metadata(index)).strip_edges()
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, {"stored_digital_key_id":key_id, "stored_key_id":key_id, "stored_item_id":key_id, "encrypted":false, "damaged":false})
	)
	section.add_child(ui._create_property_row("Digital key", option))
	_add_note(ui, section, "Digital key storage points to one placed digital key item.", false)

static func _add_data_file_controls(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	ui._add_text_property(section, "Data file id", entity_kind, entity_id, "stored_data_file_id", data.get("stored_data_file_id", data.get("payload_id", "")))
	ui._add_text_property(section, "Payload id", entity_kind, entity_id, "payload_id", data.get("payload_id", data.get("stored_data_file_id", "")))
	ui._add_bool_property(section, "Encrypted", entity_kind, entity_id, "encrypted", data.get("encrypted", false))
	ui._add_bool_property(section, "Damaged", entity_kind, entity_id, "damaged", data.get("damaged", false))
	_add_note(ui, section, "Data files may be encrypted or damaged.", false)

static func _get_digital_key_candidates(ui: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_placed_object_rows"):
		return rows
	for row_variant in Array(ui.mission_manager_runtime.call("get_map_constructor_placed_object_rows")):
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = Dictionary(row_variant)
		var row_id: String = str(row.get("id", "")).strip_edges()
		if row_id.is_empty():
			continue
		var joined: String = "%s %s %s" % [str(row.get("type_or_prefab", "")).to_lower(), str(row.get("display_name", "")).to_lower(), str(row.get("metadata_tags", "")).to_lower()]
		if not joined.contains("digital_key") and not joined.contains("digital key"):
			continue
		rows.append({"id":row_id, "label":"%s at %s" % [row_id, str(row.get("cell", Vector2i(-1, -1)))]})
	return rows

static func _add_note(ui: Variant, section: VBoxContainer, text: String, is_warning: bool) -> void:
	var note: Label = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = text
	note.add_theme_color_override("font_color", ui.UI_COLOR_WARNING if is_warning else ui.UI_COLOR_ACCENT)
	section.add_child(note)
