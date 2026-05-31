extends RefCounted
class_name MapConstructorValidationView


static func add_validation_entries(ui: Variant, section: VBoxContainer, title: String, entries: Array) -> void:
	var title_label: Label = Label.new()
	title_label.text = title
	section.add_child(title_label)
	if entries.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "(none)"
		section.add_child(none_label)
		return
	for entry_variant in entries:
		if entry_variant is Dictionary:
			var entry: Dictionary = ui._safe_ui_dictionary(entry_variant)
			var target_id: String = ui._safe_ui_string(entry.get("target_id", entry.get("id", "")))
			var label_text: String = "%s: %s" % [ui._safe_ui_string(entry.get("label", entry.get("field_name", "link"))), target_id]
			var button: Button = Button.new()
			button.text = label_text
			var entry_location: String = ui._safe_ui_string(entry.get("location", "map"), "map")
			button.disabled = entry_location != "map" and ui._safe_ui_vector2i(entry.get("cell", Vector2i(-1, -1))).x < 0
			button.pressed.connect(func() -> void:
				var target_kind: String = ui._safe_ui_string(entry.get("target_kind", "world_object"), "world_object")
				var target_cell: Vector2i = ui._safe_ui_vector2i(entry.get("cell", Vector2i(-1, -1)))
				if target_cell.x >= 0 and target_cell.y >= 0:
					ui._focus_map_constructor_cell(target_cell)
				ui._show_map_constructor_inspector(target_cell, target_kind, target_id)
			)
			section.add_child(button)
		else:
			var label: Label = Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text = ui._safe_ui_string(entry_variant)
			section.add_child(label)


static func add_linked_targets(ui: Variant, section: VBoxContainer, validation_result: Dictionary) -> void:
	add_validation_entries(ui, section, "Linked", ui._safe_ui_array(validation_result.get("linked_targets", [])))


static func add_warning_entries(ui: Variant, section: VBoxContainer, validation_result: Dictionary) -> void:
	var seen_entries: Dictionary = {}
	var missing_entries: Array = _deduplicate_entries(ui, ui._safe_ui_array(validation_result.get("missing_links", [])), seen_entries)
	add_validation_entries(ui, section, "Missing", missing_entries)
	var warning_entries: Array = []
	for warning_key in ["warnings", "broken_links", "capacity_issues", "validation_warnings", "physical_path_warnings"]:
		var unique_entries: Array = _deduplicate_entries(ui, ui._safe_ui_array(validation_result.get(warning_key, [])), seen_entries)
		warning_entries.append_array(unique_entries)
	add_validation_entries(ui, section, "Warnings", warning_entries)


static func _deduplicate_entries(ui: Variant, entries: Array, seen_entries: Dictionary) -> Array:
	var unique_entries: Array = []
	for entry_variant in entries:
		var entry_key: String = _warning_entry_key(ui, entry_variant)
		if seen_entries.has(entry_key):
			continue
		seen_entries[entry_key] = true
		unique_entries.append(entry_variant)
	return unique_entries


static func _warning_entry_key(ui: Variant, entry_variant: Variant) -> String:
	if not entry_variant is Dictionary:
		return "value|%s|%s" % [type_string(typeof(entry_variant)), ui._safe_ui_string(entry_variant)]
	var entry: Dictionary = ui._safe_ui_dictionary(entry_variant)
	var parts: Array[String] = []
	for field_name in ["label", "target_id", "id", "target_kind", "field_name", "message", "text", "cell", "location"]:
		parts.append("%s=%s" % [field_name, ui._safe_ui_string(entry.get(field_name, ""))])
	return "dictionary|%s" % "|".join(parts)
