extends RefCounted
class_name MapConstructorIssueContract

const SEVERITY_INFO := "info"
const SEVERITY_WARNING := "warning"
const SEVERITY_ERROR := "error"
const SEVERITIES: Array[String] = [SEVERITY_INFO, SEVERITY_WARNING, SEVERITY_ERROR]

const REQUIRED_FIELDS: Array[String] = [
	"code", "severity", "blocks_promotion", "entity_id", "field_id", "profile_id",
	"binding_id", "source_id", "target_id", "message_key", "fallback", "fix_hint", "details"
]

static func canonicalize(value: Dictionary, defaults: Dictionary = {}) -> Dictionary:
	var code: String = str(value.get("code", value.get("reason_code", defaults.get("code", "map_constructor.issue_unknown")))).strip_edges().to_lower()
	if code.is_empty():
		code = "map_constructor.issue_unknown"
	var severity: String = str(value.get("severity", defaults.get("severity", SEVERITY_INFO))).strip_edges().to_lower()
	if severity not in SEVERITIES:
		severity = SEVERITY_INFO
	var details: Dictionary = {}
	var raw_details: Variant = value.get("details", defaults.get("details", {}))
	if raw_details is Dictionary:
		details = Dictionary(raw_details).duplicate(true)
	var fallback: String = str(value.get("fallback", value.get("message", defaults.get("fallback", "")))).strip_edges()
	var result: Dictionary = {
		"code":code,
		"severity":severity,
		"blocks_promotion":bool(value.get("blocks_promotion", defaults.get("blocks_promotion", severity == SEVERITY_ERROR))),
		"entity_id":str(value.get("entity_id", value.get("object_id", defaults.get("entity_id", "")))).strip_edges(),
		"field_id":str(value.get("field_id", value.get("field", defaults.get("field_id", "")))).strip_edges(),
		"profile_id":str(value.get("profile_id", defaults.get("profile_id", ""))).strip_edges(),
		"binding_id":str(value.get("binding_id", defaults.get("binding_id", ""))).strip_edges(),
		"source_id":str(value.get("source_id", defaults.get("source_id", ""))).strip_edges(),
		"target_id":str(value.get("target_id", defaults.get("target_id", ""))).strip_edges(),
		"message_key":str(value.get("message_key", defaults.get("message_key", code))).strip_edges(),
		"fallback":fallback,
		"fix_hint":str(value.get("fix_hint", defaults.get("fix_hint", ""))).strip_edges(),
		"details":details,
		"expected_invalid":bool(value.get("expected_invalid", defaults.get("expected_invalid", false))),
		"issue_type":str(value.get("issue_type", defaults.get("issue_type", "validation"))).strip_edges().to_lower()
	}
	if result["message_key"].is_empty():
		result["message_key"] = code
	return result

static func validate(value: Dictionary) -> Dictionary:
	var issue: Dictionary = canonicalize(value)
	var missing: Array[String] = []
	for field_name in REQUIRED_FIELDS:
		if not issue.has(field_name):
			missing.append(field_name)
	if str(issue.get("code", "")).is_empty():
		missing.append("code")
	var success: bool = missing.is_empty() and str(issue.get("severity", "")) in SEVERITIES
	return {
		"success":success,
		"ok":success,
		"code":"map_constructor.issue_valid" if success else "map_constructor.issue_invalid",
		"reason_code":"map_constructor.issue_valid" if success else "map_constructor.issue_invalid",
		"missing_fields":missing,
		"issue":issue
	}

static func canonicalize_all(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if value is Dictionary:
			result.append(canonicalize(Dictionary(value)))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return sort_key(a) < sort_key(b)
	)
	return result

static func sort_key(issue: Dictionary) -> String:
	var severity_rank: int = 0
	match str(issue.get("severity", SEVERITY_INFO)):
		SEVERITY_ERROR:
			severity_rank = 0
		SEVERITY_WARNING:
			severity_rank = 1
		_:
			severity_rank = 2
	return "%d|%d|%s|%s|%s|%s|%s|%s" % [
		severity_rank,
		0 if bool(issue.get("blocks_promotion", false)) else 1,
		str(issue.get("code", "")),
		str(issue.get("entity_id", "")),
		str(issue.get("field_id", "")),
		str(issue.get("binding_id", "")),
		str(issue.get("source_id", "")),
		str(issue.get("target_id", ""))
	]

static func promotion_blockers(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for issue in canonicalize_all(values):
		if bool(issue.get("blocks_promotion", false)):
			result.append(issue)
	return result

static func warnings(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for issue in canonicalize_all(values):
		if str(issue.get("severity", "")) == SEVERITY_WARNING:
			result.append(issue)
	return result
