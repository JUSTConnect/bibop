extends RefCounted
class_name StationaryPowerActionService

const ActionResultRef = preload("res://scripts/game/actions/action_result_contract.gd")

static func apply_light_player_action(light: Dictionary, turn_on: bool, action_id: String, actor_id: String) -> Dictionary:
	var source: Dictionary = light.duplicate(true)
	var target_id: String = str(source.get("id", "")).strip_edges()
	var action_type: String = "light.turn_on" if turn_on else "light.turn_off"
	if target_id.is_empty() or action_id.strip_edges().is_empty():
		var invalid: Dictionary = ActionResultRef.make(action_id, "light.invalid", ActionResultRef.RESULT_FAILED, actor_id, target_id, action_type, "action.light.invalid", "Light action is invalid.")
		return _player_result(source, invalid)
	if str(source.get("health_state", "healthy")).strip_edges().to_lower() == "broken":
		var broken: Dictionary = ActionResultRef.make(action_id, "light.broken", ActionResultRef.RESULT_BLOCKED, actor_id, target_id, action_type, "action.light.broken", "The light is broken.")
		return _player_result(source, broken)
	var desired: String = "on" if turn_on else "off"
	if str(source.get("intent_state", "on")).strip_edges().to_lower() == desired:
		var unchanged: Dictionary = ActionResultRef.make(action_id, "light.no_change", ActionResultRef.RESULT_NO_CHANGE, actor_id, target_id, action_type, "action.light.no_change", "The light is already %s." % desired)
		return _player_result(source, unchanged)
	source["intent_state"] = desired
	var success: Dictionary = ActionResultRef.make(action_id, "light.intent_changed", ActionResultRef.RESULT_SUCCESS, actor_id, target_id, action_type, "action.light.intent_changed", "Light turned %s." % desired, {"intent_state":desired})
	return _player_result(source, success)

static func apply_autonomous_power_result(entity: Dictionary, power_result: Dictionary) -> Dictionary:
	var updated: Dictionary = entity.duplicate(true)
	for field_name in ["power_state", "is_powered", "resolved_source_id", "resolved_circuit_id", "physical_connection_source_id", "power_unavailable_reason"]:
		if power_result.has(field_name):
			updated[field_name] = power_result[field_name]
	return {
		"ok":true,
		"success":true,
		"code":"power.autonomous_applied",
		"reason_code":"power.autonomous_applied",
		"entity":updated,
		"action_result":{},
		"notification_event":{}
	}

static func _player_result(entity: Dictionary, action_result: Dictionary) -> Dictionary:
	return {
		"ok":str(action_result.get("result", "")) == ActionResultRef.RESULT_SUCCESS,
		"success":str(action_result.get("result", "")) == ActionResultRef.RESULT_SUCCESS,
		"code":str(action_result.get("code", "")),
		"reason_code":str(action_result.get("code", "")),
		"entity":entity,
		"action_result":action_result,
		"notification_event":ActionResultRef.notification_event(action_result, true)
	}
