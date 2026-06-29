extends RefCounted
class_name ActionResultAggregator

const ActionResultContractRef = preload("res://scripts/game/actions/action_result_contract.gd")

const OUTCOME_PRIORITY: Dictionary = {
	ActionResultContractRef.RESULT_FAILED: 50,
	ActionResultContractRef.RESULT_BLOCKED: 40,
	ActionResultContractRef.RESULT_CANCELLED: 30,
	ActionResultContractRef.RESULT_SUCCESS: 20,
	ActionResultContractRef.RESULT_NO_CHANGE: 10
}

var _processed_action_ids: Dictionary = {}

func aggregate(command: Dictionary, step_results: Array[Dictionary]) -> Dictionary:
	var action_id: String = str(command.get("action_id", command.get("correlation_id", ""))).strip_edges()
	if action_id.is_empty():
		return _failure("action_aggregation.action_id_missing", action_id)
	if _processed_action_ids.has(action_id):
		return {
			"ok":true,
			"success":true,
			"code":"action_aggregation.duplicate_ignored",
			"reason_code":"action_aggregation.duplicate_ignored",
			"action_id":action_id,
			"duplicate":true,
			"published":false,
			"action_result":{},
			"notification_event":{}
		}
	var canonical_steps: Array[Dictionary] = []
	var mismatch_ids: Array[String] = []
	for step in step_results:
		var canonical: Dictionary = ActionResultContractRef.canonicalize(step, command)
		var step_action_id: String = str(canonical.get("action_id", ""))
		if step_action_id != action_id:
			mismatch_ids.append(step_action_id)
			continue
		canonical_steps.append(canonical)
	if not mismatch_ids.is_empty():
		return _failure("action_aggregation.correlation_mismatch", action_id, {"mismatch_action_ids":mismatch_ids})
	var final_result: Dictionary = _select_final_result(command, canonical_steps)
	var event: Dictionary = ActionResultContractRef.notification_event(final_result, bool(command.get("player_action", true)))
	_processed_action_ids[action_id] = true
	return {
		"ok":true,
		"success":true,
		"code":"action_aggregation.ready",
		"reason_code":"action_aggregation.ready",
		"action_id":action_id,
		"duplicate":false,
		"published":false,
		"step_results":canonical_steps.duplicate(true),
		"action_result":final_result,
		"notification_event":event
	}

func publish_once(notification_layer: Object, ui_owner: Object, aggregation: Dictionary, duration: float = 2.8) -> Dictionary:
	if bool(aggregation.get("duplicate", false)):
		return {"ok":true, "success":true, "code":"notification.duplicate_ignored", "reason_code":"notification.duplicate_ignored", "published":false}
	var event: Dictionary = Dictionary(aggregation.get("notification_event", {})).duplicate(true)
	if event.is_empty():
		return {"ok":false, "success":false, "code":"notification.event_missing", "reason_code":"notification.event_missing", "published":false}
	if notification_layer == null or not is_instance_valid(notification_layer) or not notification_layer.has_method("publish_event"):
		return {"ok":false, "success":false, "code":"notification.publisher_missing", "reason_code":"notification.publisher_missing", "published":false}
	var publish_result: Dictionary = Dictionary(notification_layer.call("publish_event", ui_owner, event, duration))
	aggregation["published"] = bool(publish_result.get("published", false))
	return publish_result

func has_processed(action_id: String) -> bool:
	return _processed_action_ids.has(action_id.strip_edges())

func clear_processed() -> void:
	_processed_action_ids.clear()

func _select_final_result(command: Dictionary, steps: Array[Dictionary]) -> Dictionary:
	if steps.is_empty():
		return ActionResultContractRef.make(
			str(command.get("action_id", "")),
			"action.no_change",
			ActionResultContractRef.RESULT_NO_CHANGE,
			str(command.get("actor_id", "")),
			str(command.get("target_id", "")),
			str(command.get("action_type", "")),
			"action.no_change",
			"Nothing changed.",
			{}
		)
	var selected: Dictionary = steps[0]
	var selected_priority: int = int(OUTCOME_PRIORITY.get(str(selected.get("result", "")), 0))
	for index in range(1, steps.size()):
		var candidate: Dictionary = steps[index]
		var candidate_priority: int = int(OUTCOME_PRIORITY.get(str(candidate.get("result", "")), 0))
		if candidate_priority > selected_priority:
			selected = candidate
			selected_priority = candidate_priority
	var details: Dictionary = Dictionary(selected.get("details", {})).duplicate(true)
	details["step_count"] = steps.size()
	details["step_codes"] = _step_codes(steps)
	var result: Dictionary = selected.duplicate(true)
	result["details"] = details
	return ActionResultContractRef.canonicalize(result, command)

func _step_codes(steps: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for step in steps:
		result.append(str(step.get("code", "")))
	return result

func _failure(code: String, action_id: String, details: Dictionary = {}) -> Dictionary:
	return {"ok":false, "success":false, "code":code, "reason_code":code, "action_id":action_id, "duplicate":false, "published":false, "details":details.duplicate(true), "action_result":{}, "notification_event":{}}
