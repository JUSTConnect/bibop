extends RefCounted

# Target class: StatusSystem
# Runtime owner for recalculated read-only status.

const ObjectStatusModelRef = preload("res://scripts/domain/object_status_model.gd")

var repository: RefCounted = null

func get_object_status(object_id: String) -> Dictionary:
	var data: Dictionary = repository.get_object_by_id(object_id) if repository != null and repository.has_method("get_object_by_id") else {}
	return ObjectStatusModelRef.build_status(data)

func get_item_status(item_id: String) -> Dictionary:
	var data: Dictionary = repository.get_item_by_id(item_id) if repository != null and repository.has_method("get_item_by_id") else {}
	return {"item_type": str(data.get("item_type", "unknown")), "total_state": "ready"}

func recalculate_all() -> void:
	pass
