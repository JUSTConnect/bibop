extends RefCounted

# Target class: ControlSystem
# Runtime owner for internal/external control.

var repository: RefCounted = null

func get_control_state(object_id: String) -> Dictionary:
	return {"object_id": object_id, "control_state": "none"}

func get_control_targets(_controller_id: String) -> Array[Dictionary]:
	return []

func set_control_terminal(object_id: String, terminal_id: String) -> Dictionary:
	return {"ok": true, "message": "Control terminal linked.", "changed_ids": [object_id, terminal_id]}
