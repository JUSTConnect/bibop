extends RefCounted

# Target class: CoolingSystem
# Runtime owner for cooling boxes, ducts, pipes, contours and overheat reduction.

var repository: RefCounted = null

func get_cooling_state(object_id: String) -> Dictionary:
	return {"object_id": object_id, "cooling_state": "none"}

func get_available_cooling_links(_object_id: String) -> Array[Dictionary]:
	return []

func set_cooling_link(source_id: String, target_id: String) -> Dictionary:
	return {"ok": true, "message": "Cooling linked.", "changed_ids": [source_id, target_id]}

func recalculate_all() -> Dictionary:
	return {"ok": true, "message": "Cooling recalculated."}
