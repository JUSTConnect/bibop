extends RefCounted
class_name ActionResultContract

const RESULT_SUCCESS := "success"
const RESULT_BLOCKED := "blocked"
const RESULT_FAILED := "failed"
const RESULT_NO_CHANGE := "no_change"
const RESULT_CANCELLED := "cancelled"
const RESULTS: Array[String] = [RESULT_SUCCESS, RESULT_BLOCKED, RESULT_FAILED, RESULT_NO_CHANGE, RESULT_CANCELLED]

const REQUIRED_FIELDS: Array[String] = ["action_id", "code", "result", "actor_id", "target_id", "action_type", "message_key", "fallback", "details"]

static func canonicalize(value: Dictionary, defaults: Dictionary = {}) -> Dictionary:
	var details: Dictionary = {}
	var raw_details: Variant = value.get("details", defaults.get("details", {}))
	if raw_details is Dictionary:
		details = Dictionary(raw_details).duplicate(true)
	var result_value: String = str(value.get("result", defaults.get("result", RESULT_FAILED))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if result_value not in RESULTS:
		result_value = RESULT_FAILED
	return {
		"action_id":str(value.get("action_id", defaults.get("action_id", ""))).strip_edges(),
		"code":str(value.get("code", defaults.get("code", "action.unknown"))).strip_edges().to_lower(),
		"result":result_value,
		"actor_id":str(value.get("actor_id", defaults.get("actor_id", ""))).strip_edges(),
		"target_id":str(value.get("target_id", defaults.get("target_id", ""))).strip_edges(),
		"action_type":str(value.get("action_type", defaults.get("action_type", ""))).strip_edges().to_lower(),
		"message_key":str(value.get("message_key", defaults.get("message_key", ""))).strip_edges(),
		"fallback":str(value.get("fallback", defaults.get("fallback", ""))).strip_edges(),
		"details":details
	}

static func validate(value: Dictionary) -> Dictionary:
	var canonical: Dictionary = canonicalize(value)
	var missing: Array[String] = []
	for field_name in REQUIRED_FIELDS:
		if not canonical.has(field_name):
			missing.append(field_name)
	if str(canonical.get("action_id", "")).is_empty():
		missing.append("action_id")
	if str(canonical.get("code", "")).is_empty():
		missing.append("code")
	if str(canonical.get("action_type", "")).is_empty():
		missing.append("action_type")
	var valid: bool = missing.is_empty() and str(canonical.get("result", "")) in RESULTS
	return {
		"ok":valid,
		"success":valid,
		"code":"action_result.valid" if valid else "action_result.invalid",
		"reason_code":"action_result.valid" if valid else "action_result.invalid",
		"missing_fields":missing,
		"action_result":canonical
	}

static func make(action_id: String, code: String, result: String, actor_id: String, target_id: String, action_type: String, message_key: String = "", fallback: String = "", details: Dictionary = {}) -> Dictionary:
	return canonicalize({
		"action_id":action_id,
		"code":code,
		"result":result,
		"actor_id":actor_id,
		"target_id":target_id,
		"action_type":action_type,
		"message_key":message_key,
		"fallback":fallback,
		"details":details
	})

static func notification_event(action_result: Dictionary, player_action: bool = true) -> Dictionary:
	var canonical: Dictionary = canonicalize(action_result)
	return {
		"event_id":str(canonical.get("action_id", "")),
		"action_id":str(canonical.get("action_id", "")),
		"code":str(canonical.get("code", "")),
		"result":str(canonical.get("result", RESULT_FAILED)),
		"actor_id":str(canonical.get("actor_id", "")),
		"target_id":str(canonical.get("target_id", "")),
		"action_type":str(canonical.get("action_type", "")),
		"message_key":str(canonical.get("message_key", "")),
		"fallback":str(canonical.get("fallback", "")),
		"details":Dictionary(canonical.get("details", {})).duplicate(true),
		"player_action":player_action
	}
