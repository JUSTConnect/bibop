extends RefCounted
class_name MapConstructorValidationAdapter


static func build_display_rows(ui: Variant, validation_result: Dictionary) -> Dictionary:
	var seen_entries: Dictionary = {}
	var missing_rows: Array = dedupe_rows(ui, ui._safe_ui_array(validation_result.get("missing_links", [])), seen_entries)
	var warning_rows: Array = []
	for warning_key in ["warnings", "broken_links", "capacity_issues", "validation_warnings", "physical_path_warnings"]:
		warning_rows.append_array(dedupe_rows(ui, ui._safe_ui_array(validation_result.get(warning_key, [])), seen_entries))
	return {
		"linked_rows": normalize_rows(ui, ui._safe_ui_array(validation_result.get("linked_targets", []))),
		"missing_rows": missing_rows,
		"warning_rows": warning_rows,
	}


static func normalize_rows(ui: Variant, rows: Array) -> Array:
	var display_rows: Array = []
	for row_variant in rows:
		display_rows.append(normalize_warning_row(ui, row_variant))
	return display_rows


static func normalize_warning_row(ui: Variant, row_variant: Variant) -> Dictionary:
	if not row_variant is Dictionary:
		return {
			"display_is_dictionary": false,
			"display_text": ui._safe_ui_string(row_variant),
		}
	var row: Dictionary = ui._safe_ui_dictionary(row_variant)
	if row.has("display_is_dictionary"):
		return row
	var target_id: String = ui._safe_ui_string(row.get("target_id", row.get("id", "")))
	return {
		"display_is_dictionary": true,
		"display_label_text": "%s: %s" % [ui._safe_ui_string(row.get("label", row.get("field_name", "link"))), target_id],
		"display_target_id": target_id,
		"display_location": ui._safe_ui_string(row.get("location", "map"), "map"),
		"display_cell": ui._safe_ui_vector2i(row.get("cell", Vector2i(-1, -1))),
		"display_target_kind": ui._safe_ui_string(row.get("target_kind", "world_object"), "world_object"),
	}


static func dedupe_rows(ui: Variant, rows: Array, seen_entries: Dictionary = {}) -> Array:
	var unique_rows: Array = []
	for row_variant in rows:
		var entry_key: String = _warning_entry_key(ui, row_variant)
		if seen_entries.has(entry_key):
			continue
		seen_entries[entry_key] = true
		unique_rows.append(normalize_warning_row(ui, row_variant))
	return unique_rows


static func _warning_entry_key(ui: Variant, row_variant: Variant) -> String:
	if not row_variant is Dictionary:
		return "value|%s|%s" % [type_string(typeof(row_variant)), ui._safe_ui_string(row_variant)]
	var row: Dictionary = ui._safe_ui_dictionary(row_variant)
	var parts: Array[String] = []
	for field_name in ["label", "target_id", "id", "target_kind", "field_name", "message", "text", "cell", "location"]:
		parts.append("%s=%s" % [field_name, ui._safe_ui_string(row.get(field_name, ""))])
	return "dictionary|%s" % "|".join(parts)
