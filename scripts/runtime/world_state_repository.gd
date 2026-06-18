extends RefCounted

# Target class: WorldStateRepository
# Единый владелец runtime world data.

var world_objects: Dictionary = {}
var items: Dictionary = {}
var actors: Dictionary = {}
var links: Array[Dictionary] = []

func get_object_by_id(object_id: String) -> Dictionary:
	return Dictionary(world_objects.get(object_id, {}))

func get_item_by_id(item_id: String) -> Dictionary:
	return Dictionary(items.get(item_id, {}))

func apply_object_patch(object_id: String, patch: Dictionary) -> Dictionary:
	var data := get_object_by_id(object_id)
	for key in patch.keys():
		data[key] = patch[key]
	world_objects[object_id] = data
	return {"ok": true, "message": "Object updated.", "changed_ids": [object_id]}

func apply_item_patch(item_id: String, patch: Dictionary) -> Dictionary:
	var data := get_item_by_id(item_id)
	for key in patch.keys():
		data[key] = patch[key]
	items[item_id] = data
	return {"ok": true, "message": "Item updated.", "changed_ids": [item_id]}
