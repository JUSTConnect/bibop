extends RefCounted

# Target class: AccessSystem
# Runtime owner for access_code, key_card, digital_key and terminal access checks.

var repository: RefCounted = null

func get_access_state(object_id: String) -> Dictionary:
	return {"object_id": object_id, "access_state": "none"}

func can_actor_access(_actor_id: String, _object_id: String) -> Dictionary:
	return {"ok": true, "message": "Access allowed."}

func set_access_mode(object_id: String, mode: String) -> Dictionary:
	return {"ok": true, "message": "Access mode updated.", "changed_ids": [object_id], "mode": mode}
