extends RefCounted

# Target class: StorageSystem
# Storage object logic. Storage UI читает view model, не меняет данные напрямую.

var repository: RefCounted = null

func get_storage_state(_object_id: String) -> Dictionary:
	return {"items": [], "capacity": 0}

func store_item(storage_id: String, item_id: String) -> Dictionary:
	return {"ok": true, "message": "Item stored.", "changed_ids": [storage_id, item_id]}

func take_item(storage_id: String, item_id: String) -> Dictionary:
	return {"ok": true, "message": "Item taken.", "changed_ids": [storage_id, item_id]}
