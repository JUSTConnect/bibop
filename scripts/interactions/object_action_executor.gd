extends RefCounted

const InteractionSystemRef = preload("res://scripts/systems/object_interaction_system.gd")
const DoorRulesRef = preload("res://scripts/systems/door_interaction_rules.gd")

static func execute(action_id: String, data: Dictionary, objects: Array[Dictionary]) -> Dictionary:
	match action_id:
		"turn_on":
			return _state_patch(data, {"state": "on", "power_state": "powered"}, "Power source on.")
		"turn_off":
			return _state_patch(data, {"state": "off", "power_state": "unpowered"}, "Power source off.")
		"open":
			if str(data.get("state", "closed")) == "open":
				return {"ok": false, "message": "Door is already open.", "patches": []}
			return DoorRulesRef.use_door(data, false)
		"close":
			if str(data.get("state", "closed")) != "open":
				return {"ok": false, "message": "Door is already closed.", "patches": []}
			return DoorRulesRef.use_door(data, false)
		"unlock":
			return _state_patch(data, {"locked": false}, "Door unlocked.")
		"lock":
			if str(data.get("state", "closed")) == "open":
				return {"ok": false, "message": "Close door before locking.", "patches": []}
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
