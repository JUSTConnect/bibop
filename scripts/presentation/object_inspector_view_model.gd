extends RefCounted

# ObjectInspectorViewModel
# Единая модель инспектора для object/item/floor/wall.
# Собирает sections, но не создаёт UI.

const ObjectIdentityViewModelRef = preload("res://scripts/presentation/object_identity_view_model.gd")
const ObjectStatusViewModelRef = preload("res://scripts/presentation/object_status_view_model.gd")
const ObjectConfigViewModelRef = preload("res://scripts/presentation/object_config_view_model.gd")
const ObjectLinksViewModelRef = preload("res://scripts/presentation/object_links_view_model.gd")

static func create(entity_kind: String, entity_id: String, definition: Dictionary, data: Dictionary, status: Dictionary = {}, link_targets: Array = []) -> Dictionary:
	var sections: Array[Dictionary] = [
		ObjectIdentityViewModelRef.create(entity_kind, entity_id, data),
		ObjectStatusViewModelRef.create(status),
		ObjectConfigViewModelRef.create(Array(definition.get("config_schema", [])), data, entity_kind, entity_id, definition),
		ObjectLinksViewModelRef.create(Array(definition.get("links_schema", [])), data, entity_kind, entity_id, link_targets),
	]
	return {
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"title": str(data.get("display_name", entity_id)),
		"sections": sections,
		"data": data,
		"status": status,
	}
