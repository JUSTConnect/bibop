extends RefCounted

# Target class: ObjectInspectorViewModel
# Единая модель инспектора для object/item/floor/wall.

static func create(entity_kind: String, entity_id: String, data: Dictionary, status: Dictionary = {}) -> Dictionary:
	return {
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"title": str(data.get("display_name", entity_id)),
		"sections": [
			{"id": "identity", "title": "1. Identity", "rows": []},
			{"id": "status", "title": "2. Status", "rows": []},
			{"id": "config", "title": "3. Configurable Parameters", "rows": []},
			{"id": "links", "title": "4. Links", "rows": []},
			{"id": "validation", "title": "5. Validation", "rows": []},
			{"id": "debug", "title": "6. Debug", "rows": []},
		],
		"data": data,
		"status": status,
	}
