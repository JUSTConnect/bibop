extends RefCounted

# ObjectDefinitionValidator
# Проверяет минимальный контракт ObjectDefinition перед попаданием в catalog.

const REQUIRED_STRING_FIELDS: Array[String] = ["id", "object_type", "object_group", "display_name", "visual_id"]
const REQUIRED_ARRAY_FIELDS: Array[String] = ["config_schema", "links_schema", "interactions"]

static func validate(definition: Dictionary, source_path: String = "") -> Array[String]:
	var errors: Array[String] = []
	for field in REQUIRED_STRING_FIELDS:
		if str(definition.get(field, "")).strip_edges().is_empty():
			errors.append("%s must be a non-empty string" % field)
	if not (definition.get("base_parameters", null) is Dictionary):
		errors.append("base_parameters must be a Dictionary")
	for field in REQUIRED_ARRAY_FIELDS:
		if not (definition.get(field, null) is Array):
			errors.append("%s must be an Array" % field)
	_validate_config_schema(Array(definition.get("config_schema", [])), errors)
	_validate_links_schema(Array(definition.get("links_schema", [])), errors)
	if not source_path.is_empty():
		for index in range(errors.size()):
			errors[index] = "%s: %s" % [source_path, errors[index]]
	return errors


static func is_valid(definition: Dictionary, source_path: String = "") -> bool:
	return validate(definition, source_path).is_empty()


static func _validate_config_schema(rows: Array, errors: Array[String]) -> void:
	var ids: Dictionary = {}
	for row_variant in rows:
		if not (row_variant is Dictionary):
			errors.append("config_schema row must be a Dictionary")
			continue
		var row: Dictionary = Dictionary(row_variant)
		var row_id: String = str(row.get("id", row.get("field", ""))).strip_edges()
		if row_id.is_empty():
			errors.append("config_schema row id is required")
			continue
		if ids.has(row_id):
			errors.append("duplicate config_schema id: %s" % row_id)
		ids[row_id] = true
		if str(row.get("type", "")).strip_edges().is_empty():
			errors.append("config_schema.%s type is required" % row_id)


static func _validate_links_schema(rows: Array, errors: Array[String]) -> void:
	var ids: Dictionary = {}
	for row_variant in rows:
		if not (row_variant is Dictionary):
			errors.append("links_schema row must be a Dictionary")
			continue
		var row: Dictionary = Dictionary(row_variant)
		var row_id: String = str(row.get("id", "")).strip_edges()
		if row_id.is_empty():
			errors.append("links_schema row id is required")
			continue
		if ids.has(row_id):
			errors.append("duplicate links_schema id: %s" % row_id)
		ids[row_id] = true
		if str(row.get("type", "")).strip_edges().is_empty():
			errors.append("links_schema.%s type is required" % row_id)
