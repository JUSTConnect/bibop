extends RefCounted

const InteractionSystemRef = preload("res://scripts/systems/object_interaction_system.gd")

static func execute(action_id: String, data: Dictionary, objects: Array[Dictionary]) -> Dictionary:
	match action_id:
		"turn_on":
			return _state_patch(data, {"state": "on", "power_state": "powered"}, "Power source on.")
		"turn_off":
			return _state_patch(data, {"state": "off", "power_state": "unpowered"}, "Power source off.")
		"open":
			return _state_patch(data, {"state": "open"}, "Door opened.")
		"close":
			return _state_patch(data, {"state": "closed"}, "Door closed.")
		"unlock":
			return _state_patch(data, {"locked": false}, "Door unlocked.")
		"lock":
			return _state_patch(data, {"locked": true}, "Door locked.")
		"activate":
			return InteractionSystemRef.use_object(data, objects)
		"inspect", "inspect_links":
			return {"ok": true, "message": "Inspector updated.", "patches": []}
		_:
			return {"ok": false, "message": "Unknown action: %s" % action_id, "patches": []}

static func _state_patch(data: Dictionary, patch: Dictionary, message: String) -> Dictionary:
	return {
		"ok": true,
		"message": message,
		"patches": [{"instance_id": str(data.get("id", "")), "patch": patch}],
	}
