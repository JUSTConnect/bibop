extends RefCounted

# Target class: ItemDefinitionCatalog
# Единый catalog для items. Storage/inventory/palette читают отсюда.

var definitions_by_id: Dictionary = {}

func load_all(_base_path: String = "res://data/items") -> void:
	pass

func register_definition(definition_id: String, definition: Dictionary) -> void:
	definitions_by_id[definition_id] = definition

func get_definition(definition_id: String) -> Dictionary:
	return Dictionary(definitions_by_id.get(definition_id, {}))

func get_all_definitions() -> Array:
	return definitions_by_id.values()
