extends RefCounted

const ObjectDefinitionValidatorRef = preload("res://scripts/domain/object_definition_validator.gd")

var definitions_by_id: Dictionary = {}
var definition_order: Array[String] = []
var validation_errors: Array[String] = []

func clear() -> void:
	definitions_by_id.clear()
	definition_order.clear()
	validation_errors.clear()

func load_paths(paths: Array[String]) -> Array[Dictionary]:
	clear()
	for path: String in paths:
		_load_and_register(path)
	return get_all_definitions()

func load_all(base_path: String = "res://data/objects") -> Array[Dictionary]:
	clear()
	var dir: DirAccess = DirAccess.open(base_path)
	if dir == null:
		push_warning("Cannot open object definitions directory: %s" % base_path)
		return []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_and_register(base_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	return get_all_definitions()

func _load_and_register(path: String) -> void:
	var definition: Dictionary = _load_json_dictionary(path)
	if definition.is_empty():
		return
	var errors: Array[String] = ObjectDefinitionValidatorRef.validate(definition, path)
	if not errors.is_empty():
		validation_errors.append_array(errors)
		for error: String in errors:
			push_warning(error)
		return
	register_definition(str(definition.get("id", "")), definition)

func register_definition(definition_id: String, definition: Dictionary) -> void:
	if not definitions_by_id.has(definition_id):
		definition_order.append(definition_id)
	definitions_by_id[definition_id] = definition.duplicate(true)

func get_definition(definition_id: String) -> Dictionary:
	return Dictionary(definitions_by_id.get(definition_id, {})).duplicate(true)

func get_all_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition_id: String in definition_order:
		result.append(get_definition(definition_id))
	return result

func get_validation_errors() -> Array[String]:
	return validation_errors.duplicate()

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing object definition: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Cannot open object definition: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return Dictionary(parsed)
	push_warning("Invalid object definition JSON: %s" % path)
	return {}
