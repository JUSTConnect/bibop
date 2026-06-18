extends RefCounted

# ObjectConfigViewModel
# Builds configurable parameter rows from schema.
# UI получает готовые rows и не читает config_schema напрямую.

const ObjectConfigSchemaRef = preload("res://scripts/domain/object_config_schema.gd")

static func create(schema_rows: Array, data: Dictionary, entity_kind: String = "world_object", entity_id: String = "", definition: Dictionary = {}) -> Dictionary:
	var rows: Array[Dictionary] = []
	var base_config: Dictionary = _get_base_config(definition, data)
	var overrides: Dictionary = Dictionary(data.get("config_overrides", {}))
	for row_variant in schema_rows:
		var row: Dictionary = Dictionary(row_variant)
		var field_id: String = str(row.get("id", row.get("field", "")))
		if field_id.is_empty():
			continue
		var control_type: String = _normalize_control_type(str(row.get("type", "string")))
		var base_value: Variant = base_config.get(field_id, ObjectConfigSchemaRef.get_schema_default(row))
		var has_override: bool = ObjectConfigSchemaRef.has_override(data, field_id, base_value)
		var value: Variant = overrides.get(field_id, data.get(field_id, base_value))
		var source_label := "override" if has_override else "base"
		rows.append({
			"id": field_id,
			"label": str(row.get("label", field_id.replace("_", " ").capitalize())),
			"control_type": control_type,
			"value": value,
			"base_value": base_value,
			"value_source": source_label,
			"can_reset": entity_kind == "placed_object" and has_override,
			"readonly": bool(row.get("readonly", false)),
			"options": Array(row.get("options", row.get("values", []))),
			"min": row.get("min", 0),
			"max": row.get("max", 999),
			"apply_mode": "auto" if control_type == "enum" else "inline",
			"row_kind": "config_field",
			"entity_kind": entity_kind,
			"entity_id": entity_id,
		})
	return {"section_id": "config", "title": "3. Configurable Parameters", "rows": rows}


static func _get_base_config(definition: Dictionary, data: Dictionary) -> Dictionary:
	var base_from_data: Dictionary = Dictionary(data.get("base_config", {}))
	if not base_from_data.is_empty():
		return base_from_data
	return ObjectConfigSchemaRef.make_base_config(definition)


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
