extends RefCounted
class_name MapConstructorValidationView

const MapConstructorValidationAdapterRef = preload("res://scripts/ui/map_constructor/map_constructor_validation_adapter.gd")


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
		var entry: Dictionary = MapConstructorValidationAdapterRef.normalize_warning_row(ui, entry_variant)
		if bool(entry.get("display_is_dictionary", false)):
			var target_id: String = ui._safe_ui_string(entry.get("display_target_id", ""))
			var button: Button = Button.new()
			button.text = ui._safe_ui_string(entry.get("display_label_text", ""))
			var entry_location: String = ui._safe_ui_string(entry.get("display_location", "map"), "map")
			button.disabled = entry_location != "map" and ui._safe_ui_vector2i(entry.get("display_cell", Vector2i(-1, -1))).x < 0
			button.pressed.connect(func() -> void:
				var target_kind: String = ui._safe_ui_string(entry.get("display_target_kind", "world_object"), "world_object")
				var target_cell: Vector2i = ui._safe_ui_vector2i(entry.get("display_cell", Vector2i(-1, -1)))
				if target_cell.x >= 0 and target_cell.y >= 0:
					ui._focus_map_constructor_cell(target_cell)
				ui._show_map_constructor_inspector(target_cell, target_kind, target_id)
			)
			section.add_child(button)
		else:
			var label: Label = Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text = ui._safe_ui_string(entry.get("display_text", ""))
			section.add_child(label)


static func add_linked_targets(ui: Variant, section: VBoxContainer, validation_result: Dictionary) -> void:
	var display_rows: Dictionary = MapConstructorValidationAdapterRef.build_display_rows(ui, validation_result)
	add_validation_entries(ui, section, "Linked", ui._safe_ui_array(display_rows.get("linked_rows", [])))


static func add_warning_entries(ui: Variant, section: VBoxContainer, validation_result: Dictionary) -> void:
	var display_rows: Dictionary = MapConstructorValidationAdapterRef.build_display_rows(ui, validation_result)
	add_validation_entries(ui, section, "Missing", ui._safe_ui_array(display_rows.get("missing_rows", [])))
	add_validation_entries(ui, section, "Warnings", ui._safe_ui_array(display_rows.get("warning_rows", [])))
