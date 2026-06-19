extends RefCounted

const ObjectDefinitionCatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")

var definitions: Array[Dictionary] = []
var definitions_by_id: Dictionary = {}
var preview_data_by_id: Dictionary = {}
var selected_index: int = 0

func load_paths(paths: Array[String]) -> Array[String]:
	var catalog: RefCounted = ObjectDefinitionCatalogRef.new()
	definitions = catalog.call("load_paths", paths)
	definitions_by_id.clear()
	preview_data_by_id.clear()
	for definition: Dictionary in definitions:
		var definition_id: String = str(definition.get("id", ""))
		definitions_by_id[definition_id] = definition
		preview_data_by_id[definition_id] = ObjectDataFactoryRef.make_initial_object_data(definition)
	selected_index = clampi(selected_index, 0, max(0, definitions.size() - 1))
	return Array(catalog.call("get_validation_errors"), TYPE_STRING, "", null)

func select_index(index: int) -> Dictionary:
	if definitions.is_empty():
		return {}
	selected_index = clampi(index, 0, definitions.size() - 1)
	return get_selected_definition()

func select_definition_id(definition_id: String) -> Dictionary:
	for index in range(definitions.size()):
		if str(definitions[index].get("id", "")) == definition_id:
			return select_index(index)
	return get_selected_definition()

func get_selected_definition() -> Dictionary:
	if definitions.is_empty():
		return {}
	return Dictionary(definitions[selected_index]).duplicate(true)

func get_definition(definition_id: String) -> Dictionary:
	return Dictionary(definitions_by_id.get(definition_id, {})).duplicate(true)

func get_preview_data(definition_id: String) -> Dictionary:
	return Dictionary(preview_data_by_id.get(definition_id, {})).duplicate(true)

func patch_preview(definition_id: String, patch: Dictionary) -> Dictionary:
	var data: Dictionary = get_preview_data(definition_id)
	for key: Variant in patch.keys():
		data[key] = patch[key]
	data["power_state"] = ObjectDataFactoryRef.infer_power_state(data)
	preview_data_by_id[definition_id] = data
	return data.duplicate(true)
