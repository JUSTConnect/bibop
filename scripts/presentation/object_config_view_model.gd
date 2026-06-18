extends RefCounted

# ObjectConfigViewModel
# Builds configurable parameter rows from schema.
# UI получает готовые rows и не читает config_schema напрямую.

static func create(schema_rows: Array, data: Dictionary, entity_kind: String = "world_object", entity_id: String = "") -> Dictionary:
	var rows: Array[Dictionary] = []
	for row_variant in schema_rows:
		var row: Dictionary = Dictionary(row_variant)
		var field_id: String = str(row.get("id", row.get("field", "")))
		if field_id.is_empty():
			continue
		var control_type: String = _normalize_control_type(str(row.get("type", "string")))
		rows.append({
			"id": field_id,
			"label": str(row.get("label", field_id.replace("_", " ").capitalize())),
			"control_type": control_type,
			"value": data.get(field_id, row.get("default_value", row.get("default", ""))),
			"readonly": bool(row.get("readonly", false)),
			"options": Array(row.get("options", row.get("values", []))),
			"min": row.get("min", 0),
			"max": row.get("max", 999),
			"apply_mode": "auto" if control_type == "enum" else "inline",
			"entity_kind": entity_kind,
			"entity_id": entity_id,
		})
	return {"section_id": "config", "title": "3. Configurable Parameters", "rows": rows}


static func _normalize_control_type(raw_type: String) -> String:
	match raw_type:
		"enum", "dropdown":
			return "enum"
		"int", "number_spin", "integer":
			return "int"
		"bool", "checkbox":
			return "checkbox"
		"text", "text_edit":
			return "text_edit"
		_:
			return "line_edit"
