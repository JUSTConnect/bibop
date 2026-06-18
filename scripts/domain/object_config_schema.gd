extends RefCounted

# ObjectConfigSchema
# Единая логика для base config, default values и effective config.
# UI и runtime не должны заново угадывать default значения из config_schema.

static func normalize_field(row: Dictionary) -> Dictionary:
	return {
		"id": str(row.get("id", row.get("field", ""))),
		"label": str(row.get("label", "")),
		"type": str(row.get("type", "string")),
		"default_value": row.get("default_value", row.get("default", null)),
		"options": Array(row.get("options", row.get("values", []))),
		"visible_if": Dictionary(row.get("visible_if", {})),
		"readonly": bool(row.get("readonly", false)),
	}


static func make_base_config(definition: Dictionary) -> Dictionary:
	var base_config: Dictionary = Dictionary(definition.get("base_parameters", {})).duplicate(true)
	for row_variant in Array(definition.get("config_schema", [])):
		var row: Dictionary = Dictionary(row_variant)
		var field_id: String = str(row.get("id", row.get("field", "")))
		if field_id.is_empty() or base_config.has(field_id):
			continue
		base_config[field_id] = get_schema_default(row)
	return base_config


static func make_effective_config(definition: Dictionary, data: Dictionary) -> Dictionary:
	var effective: Dictionary = make_base_config(definition)
	var overrides: Dictionary = Dictionary(data.get("config_overrides", {}))
	for key in overrides.keys():
		effective[str(key)] = overrides[key]
	for row_variant in Array(definition.get("config_schema", [])):
		var row: Dictionary = Dictionary(row_variant)
		var field_id: String = str(row.get("id", row.get("field", "")))
		if field_id.is_empty() or overrides.has(field_id):
			continue
		if data.has(field_id):
			effective[field_id] = data[field_id]
	return effective


static func get_schema_default(row: Dictionary) -> Variant:
	if row.has("default_value"):
		return row.get("default_value")
	if row.has("default"):
		return row.get("default")
	var row_type: String = str(row.get("type", "string"))
	if row_type == "enum" or row_type == "dropdown":
		var values: Array = Array(row.get("values", row.get("options", [])))
		return values[0] if not values.is_empty() else ""
	if row_type == "int" or row_type == "integer" or row_type == "number_spin":
		return int(row.get("min", 0))
	if row_type == "bool" or row_type == "checkbox":
		return false
	return ""


static func has_override(data: Dictionary, field_id: String, base_value: Variant) -> bool:
	var overrides: Dictionary = Dictionary(data.get("config_overrides", {}))
	if overrides.has(field_id):
		return true
	if data.has(field_id):
		return not values_equal(data[field_id], base_value)
	return false


static func values_equal(left: Variant, right: Variant) -> bool:
	if typeof(left) == typeof(right):
		return left == right
	return str(left) == str(right)
