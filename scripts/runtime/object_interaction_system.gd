extends RefCounted

# Target class: ObjectInteractionSystem
# Единый источник available actions для объектов.

var repository: RefCounted = null

func get_available_actions(_actor_id: String, _object_id: String) -> Array[Dictionary]:
	return []

func can_apply_action(_actor_id: String, _object_id: String, _action_id: String) -> Dictionary:
	return {"ok": true, "message": "Action available."}

func apply_action(actor_id: String, object_id: String, action_id: String, payload: Dictionary = {}) -> Dictionary:
	return {"ok": true, "message": "Action applied.", "actor_id": actor_id, "object_id": object_id, "action_id": action_id, "payload": payload}
