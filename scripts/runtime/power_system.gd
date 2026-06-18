extends RefCounted

# Target class: PowerSystem
# Runtime owner for power sources, circuits, load and powered/unpowered state.

var repository: RefCounted = null

func get_power_state(object_id: String) -> Dictionary:
	var data: Dictionary = repository.get_object_by_id(object_id) if repository != null and repository.has_method("get_object_by_id") else {}
	return {"object_id": object_id, "power_state": "powered" if bool(data.get("is_powered", false)) else "unpowered"}

func get_available_power_sources(_object_id: String) -> Array[Dictionary]:
	return []

func set_power_source(object_id: String, source_id: String) -> Dictionary:
	return {"ok": true, "message": "Power source linked.", "changed_ids": [object_id, source_id]}

func recalculate_all() -> Dictionary:
	return {"ok": true, "message": "Power recalculated."}
