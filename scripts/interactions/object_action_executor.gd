extends RefCounted

const InteractionSystemRef = preload("res://scripts/systems/object_interaction_system.gd")
const DoorRulesRef = preload("res://scripts/systems/door_interaction_rules.gd")
const ActionProviderRef = preload("res://scripts/interactions/object_action_provider.gd")

static func execute(action_id: String, data: Dictionary, objects: Array[Dictionary]) -> Dictionary:
	var availability: Dictionary = _find_action(action_id, data)
	if availability.is_empty():
		return {"ok": false, "message": "Unknown action: %s" % action_id, "patches": []}
	if not bool(availability.get("enabled", false)):
		return {
			"ok": false,
			"message": str(availability.get("disabled_reason", "Action is unavailable.")),
			"patches": [],
		}
	match action_id:
		"turn_on":
			return _state_patch(data, {"state": "on", "power_state": "powered"}, "Power source on.")
		"turn_off":
			return _state_patch(data, {"state": "off", "power_state": "unpowered"}, "Power source off.")
		"open", "close":
			return DoorRulesRef.use_door(data, false)
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

static func _find_action(action_id: String, data: Dictionary) -> Dictionary:
	for action: Dictionary in ActionProviderRef.get_actions(data):
		if str(action.get("id", "")) == action_id:
			return action
	return {}

static func _state_patch(data: Dictionary, patch: Dictionary, message: String) -> Dictionary:
	return {
		"ok": true,
		"message": message,
		"patches": [{"instance_id": str(data.get("id", "")), "patch": patch}],
	}
