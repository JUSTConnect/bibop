extends RefCounted
class_name MapConstructorTerminalStoredDataControls

const TerminalVisibilityServiceRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector_visibility_service.gd")
const InformationTerminalServiceRef = preload("res://scripts/game/map_constructor_information_terminal_service.gd")

static func add_stored_data_section(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if not TerminalVisibilityServiceRef.should_show_terminal_stored_data(data):
		return
	var section: VBoxContainer = ui._create_inspector_section("Stored Data")
	var sanitized: Dictionary = InformationTerminalServiceRef.sanitize_information_terminal_data(data)
	var stored_data_type: String = InformationTerminalServiceRef.get_stored_data_type(sanitized)
	var options: Array[Dictionary] = [
		{"label":"None", "value":"none", "updates":{"stored_data_type":"none", "digital_payload_type":"none", "stored_access_code":"", "access_code_value":"", "access_code":"", "stored_digital_key_id":"", "stored_key_id":"", "stored_item_id":"", "stored_data_file_id":"", "payload_id":"", "encrypted":false, "damaged":false}},
		{"label":"Access Code", "value":"access_code", "updates":{"stored_data_type":"access_code", "digital_payload_type":"access_code", "stored_digital_key_id":"", "stored_key_id":"", "stored_item_id":"", "stored_data_file_id":"", "payload_id":"", "encrypted":false, "damaged":false}},
		{"label":"Digital Key", "value":"digital_key", "updates":{"stored_data_type":"digital_key", "digital_payload_type":"digital_key", "stored_access_code":"", "access_code_value":"", "access_code":"", "stored_data_file_id":"", "payload_id":"", "encrypted":false, "damaged":false}},
		{"label":"Data File", "value":"data_file", "updates":{"stored_data_type":"data_file", "digital_payload_type":"data_file", "stored_access_code":"", "access_code_value":"", "access_code":"", "stored_digital_key_id":"", "stored_key_id":"", "stored_item_id":""}}
	]
	MapConstructorPropertyControls.add_enum_updates_property(ui, section, "Stored data type", entity_kind, entity_id, stored_data_type, options)
	if stored_data_type == "access_code":
		_add_access_code_controls(ui, section, entity_kind, entity_id, sanitized)
	elif stored_data_type == "digital_key":
		_add_digital_key_controls(ui, section, entity_kind, entity_id, sanitized)
	elif stored_data_type == "data_file":
		_add_data_file_controls(ui, section, entity_kind, entity_id, sanitized)
	else:
		_add_note(ui, section, "No data payload is stored in this information terminal.", false)
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
		if not InformationTerminalServiceRef.is_four_digit_code(next_code):
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
	var current_key_id: String = str(data.get("stored_digital_key_id", data.get("stored_key_id", data.get("stored_item_id", "")))).strip_edges()
	var option: OptionButton = OptionButton.new()
	option.add_item("(no digital key)")
	option.set_item_metadata(0, "")
	if current_key_id.is_empty():
		option.select(0)
	var selected_index: int = 0
	for candidate in _get_digital_key_candidates(ui):
		var candidate_data: Dictionary = MapConstructorUiSafe.safe_dictionary(candidate)
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
		var updates: Dictionary = {"stored_digital_key_id":key_id, "stored_key_id":key_id, "stored_item_id":key_id, "encrypted":false, "damaged":false}
		ui._apply_map_constructor_property_updates(entity_kind, entity_id, updates)
		_sync_digital_key_terminal_storage(ui, key_id, entity_id)
	)
	section.add_child(ui._create_property_row("Digital key", option))
	_add_note(ui, section, "Digital key storage points to one placed digital key item and marks that key as stored in this information terminal.", false)

static func _add_data_file_controls(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	ui._add_text_property(section, "Data file id", entity_kind, entity_id, "stored_data_file_id", data.get("stored_data_file_id", data.get("payload_id", "")))
	ui._add_text_property(section, "Payload id", entity_kind, entity_id, "payload_id", data.get("payload_id", data.get("stored_data_file_id", "")))
	ui._add_bool_property(section, "Encrypted", entity_kind, entity_id, "encrypted", data.get("encrypted", false))
	ui._add_bool_property(section, "Damaged", entity_kind, entity_id, "damaged", data.get("damaged", false))
	_add_note(ui, section, "Data files may be encrypted or damaged.", false)

static func _get_digital_key_candidates(ui: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if ui.mission_manager_runtime == null:
		return rows
	if ui.mission_manager_runtime.has_method("get_map_constructor_link_targets_for_field"):
		var targets: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("get_map_constructor_link_targets_for_field", "item", "", "required_key_id"))
		for target_variant in MapConstructorUiSafe.safe_array(targets.get("targets", [])):
			var target: Dictionary = MapConstructorUiSafe.safe_dictionary(target_variant)
			var key_id: String = str(target.get("id", "")).strip_edges()
			if key_id.is_empty() or key_id == "__none__":
				continue
			if _is_digital_key_id(ui, key_id):
				rows.append({"id":key_id, "label":str(target.get("label", key_id))})
		return rows
	if not ui.mission_manager_runtime.has_method("get_map_constructor_placed_object_rows"):
		return rows
	for row_variant in Array(ui.mission_manager_runtime.call("get_map_constructor_placed_object_rows")):
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = MapConstructorUiSafe.safe_dictionary(row_variant)
		var row_id: String = str(row.get("id", "")).strip_edges()
		if row_id.is_empty():
			continue
		if _is_digital_key_id(ui, row_id):
			rows.append({"id":row_id, "label":"%s at %s" % [row_id, str(row.get("cell", Vector2i(-1, -1)))]})
	return rows

static func _is_digital_key_id(ui: Variant, key_id: String) -> bool:
	var normalized_key_id: String = key_id.strip_edges()
	if normalized_key_id.is_empty():
		return false
	var joined: String = normalized_key_id.to_lower()
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("find_map_constructor_key_item_by_id"):
		var key_entity: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("find_map_constructor_key_item_by_id", normalized_key_id))
		var key_data: Dictionary = MapConstructorUiSafe.safe_dictionary(key_entity.get("data", key_entity.get("item_data", {})))
		joined = "%s %s %s %s %s" % [joined, str(key_data.get("item_type", "")).to_lower(), str(key_data.get("key_type", "")).to_lower(), str(key_data.get("key_kind", "")).to_lower(), str(key_data.get("digital_payload_type", "")).to_lower()]
	return joined.contains("digital_key") or joined.contains("digital key") or joined.contains("digital")

static func _sync_digital_key_terminal_storage(ui: Variant, key_id: String, terminal_id: String) -> void:
	var normalized_key_id: String = key_id.strip_edges()
	if normalized_key_id.is_empty() or ui.mission_manager_runtime == null:
		return
	if not ui.mission_manager_runtime.has_method("find_map_constructor_key_item_by_id"):
		return
	var key_entity: Dictionary = MapConstructorUiSafe.safe_dictionary(ui.mission_manager_runtime.call("find_map_constructor_key_item_by_id", normalized_key_id))
	if not bool(key_entity.get("ok", false)):
		return
	var key_kind: String = str(key_entity.get("entity_kind", "item")).strip_edges()
	if key_kind.is_empty():
		key_kind = "item"
	var key_updates: Dictionary = {"storage_location":"terminal", "stored_in_terminal_id":terminal_id, "storage_terminal_id":terminal_id, "access_terminal_id":terminal_id}
	ui._apply_map_constructor_property_updates(key_kind, normalized_key_id, key_updates)

static func _add_note(ui: Variant, section: VBoxContainer, text: String, is_warning: bool) -> void:
	var note: Label = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = text
	note.add_theme_color_override("font_color", ui.UI_COLOR_WARNING if is_warning else ui.UI_COLOR_ACCENT)
	section.add_child(note)
