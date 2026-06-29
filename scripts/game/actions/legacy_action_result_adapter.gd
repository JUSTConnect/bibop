extends RefCounted
class_name LegacyActionResultAdapter

const ActionResultContractRef = preload("res://scripts/game/actions/action_result_contract.gd")

const KIND_SYSTEM := "system"
const KIND_SYSTEM_NEGATIVE := "system_negative"
const KIND_POSITIVE := "positive"
const KIND_NEGATIVE := "negative"

var _sequence: int = 0

func adapt_message(message: String, kind: String = "", context: Dictionary = {}) -> Dictionary:
	_sequence += 1
	var fallback: String = message.strip_edges()
	var resolved_kind: String = normalize_kind(kind)
	if resolved_kind.is_empty():
		resolved_kind = classify_message(fallback)
	var result: String = result_for_kind(resolved_kind)
	var action_id: String = str(context.get("action_id", "")).strip_edges()
	if action_id.is_empty():
		action_id = "legacy_%d_%d" % [Time.get_ticks_usec(), _sequence]
	var action_type: String = str(context.get("action_type", "legacy.notification")).strip_edges().to_lower()
	var code: String = str(context.get("code", "legacy.%s" % result)).strip_edges().to_lower()
	var action_result: Dictionary = ActionResultContractRef.make(
		action_id,
		code,
		result,
		str(context.get("actor_id", "")),
		str(context.get("target_id", "")),
		action_type,
		str(context.get("message_key", "")),
		fallback,
		{"legacy_adapter":true, "legacy_kind":resolved_kind}
	)
	return ActionResultContractRef.notification_event(action_result, bool(context.get("player_action", true)))

static func classify_message(message: String) -> String:
	var lower_message: String = message.strip_edges().to_lower()
	if lower_message.is_empty():
		return KIND_SYSTEM
	if _contains_any(lower_message, ["overheat", "thermal critical", "critical", "broken", "damaged", "failed", "mission failed", "disabled", "shutdown", "destroyed"]):
		return KIND_NEGATIVE
	if _contains_any(lower_message, ["blocked", "locked", "missing", "unavailable", "invalid", "insufficient", "no ", "cannot", "can't", "warning", "low battery"]):
		return KIND_SYSTEM_NEGATIVE
	if _contains_any(lower_message, ["charged", "completed", "success", "scan", "scanned", "hack", "hacked", "activated", "enabled", "opened", "closed", "connected", "collected", "stored", "picked up"]):
		return KIND_POSITIVE
	return KIND_SYSTEM

static func runtime_role(message: String) -> String:
	var kind: String = classify_message(message)
	if kind == KIND_POSITIVE:
		return "ok"
	if kind in [KIND_NEGATIVE, KIND_SYSTEM_NEGATIVE]:
		return "danger"
	return "info"

static func result_for_kind(kind: String) -> String:
	match normalize_kind(kind):
		KIND_POSITIVE:
			return ActionResultContractRef.RESULT_SUCCESS
		KIND_SYSTEM_NEGATIVE:
			return ActionResultContractRef.RESULT_BLOCKED
		KIND_NEGATIVE:
			return ActionResultContractRef.RESULT_FAILED
	return ActionResultContractRef.RESULT_NO_CHANGE

static func normalize_kind(kind: String) -> String:
	var clean_kind: String = kind.strip_edges().to_lower()
	if clean_kind in [KIND_SYSTEM, KIND_SYSTEM_NEGATIVE, KIND_POSITIVE, KIND_NEGATIVE]:
		return clean_kind
	if clean_kind in ["info", "blue", "system_positive"]:
		return KIND_SYSTEM
	if clean_kind in ["warning", "orange"]:
		return KIND_SYSTEM_NEGATIVE
	if clean_kind in ["ok", "success", "green"]:
		return KIND_POSITIVE
	if clean_kind in ["danger", "error", "red"]:
		return KIND_NEGATIVE
	return ""

static func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false
