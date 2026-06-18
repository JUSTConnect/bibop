extends RefCounted

# Target class: ObjectConfigViewModel
# Builds configurable parameter rows from schema.

static func create(schema_rows: Array, data: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for row_variant in schema_rows:
		var row := Dictionary(row_variant)
		var field_id := str(row.get("id", row.get("field", "")))
		if field_id.is_empty():
			continue
		rows.append({
			"id": field_id,
			"label": str(row.get("label", field_id.replace("_", " ").capitalize())),
			"control_type": str(row.get("type", "string")),
			"value": data.get(field_id, row.get("default_value", row.get("default", null))),
			"readonly": bool(row.get("readonly", false)),
			"options": Array(row.get("options", row.get("values", []))),
		})
	return {"section_id": "config", "title": "3. Configurable Parameters", "rows": rows}
