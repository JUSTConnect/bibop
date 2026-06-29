extends RefCounted
class_name PlayerActionCommandService

const ActionResultContractRef = preload("res://scripts/game/actions/action_result_contract.gd")

var _sequence: int = 0
var _prefix: String = "action"

func _init(prefix: String = "action") -> void:
	_prefix = prefix.strip_edges().to_lower()
	if _prefix.is_empty():
		_prefix = "action"

func begin_command(actor_id: String, target_id: String, action_type: String, details: Dictionary = {}) -> Dictionary:
	_sequence += 1
	var normalized_action_type: String = action_type.strip_edges().to_lower()
	var action_id: String = "%s_%d_%d" % [_prefix, Time.get_ticks_usec(), _sequence]
	return {
		"action_id":action_id,
		"correlation_id":action_id,
		"actor_id":actor_id.strip_edges(),
		"target_id":target_id.strip_edges(),
		"action_type":normalized_action_type,
		"player_action":true,
		"details":details.duplicate(true)
	}

func make_step(command: Dictionary, code: String, result: String, message_key: String = "", fallback: String = "", details: Dictionary = {}) -> Dictionary:
	return ActionResultContractRef.make(
		str(command.get("action_id", "")),
		code,
		result,
		str(command.get("actor_id", "")),
		str(command.get("target_id", "")),
		str(command.get("action_type", "")),
		message_key,
		fallback,
		details
	)

static func propagate(command: Dictionary, details_patch: Dictionary = {}) -> Dictionary:
	var result: Dictionary = command.duplicate(true)
	var details: Dictionary = Dictionary(result.get("details", {})).duplicate(true)
	for key in details_patch.keys():
		details[key] = details_patch[key]
	result["details"] = details
	result["correlation_id"] = str(result.get("action_id", result.get("correlation_id", "")))
	return result
