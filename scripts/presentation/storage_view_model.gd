extends RefCounted

# Target class: StorageViewModel
# View data for storage panel.

static func create(storage_state: Dictionary) -> Dictionary:
	return {
		"title": storage_state.get("display_name", "Storage"),
		"items": Array(storage_state.get("items", [])),
		"capacity": int(storage_state.get("capacity", 0)),
		"actions": Array(storage_state.get("actions", [])),
	}
