extends RefCounted
class_name MapConstructorReadinessValidationService

const CanonicalReadinessRef = preload("res://scripts/game/map_constructor_readiness_service.gd")
const IssueContractRef = preload("res://scripts/game/map_constructor_issue_contract.gd")

static func build_save_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager, "draft_save")

static func build_load_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager, "task_test")

static func build_promotion_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager, "promotion")

static func normalize_readiness_report(report: Variant) -> Dictionary:
	var normalized: Dictionary = {
		"ok":false,
		"success":false,
		"playable":false,
		"status":"unknown",
		"decision_status":"unknown",
		"draft_save_allowed":false,
		"task_test_allowed":false,
		"promotion_allowed":false,
		"summary":"Mission readiness unavailable.",
		"blocking_count":0,
		"warning_count":0,
		"info_count":0,
		"expected_invalid_count":0,
		"checks":[],
		"issues":[],
		"blocking_issues":[],
		"warning_issues":[],
		"warnings":[],
		"expected_invalid_issues":[],
		"recommended_actions":[]
	}
	if report is Dictionary:
		for key in Dictionary(report).keys():
			normalized[key] = Dictionary(report)[key]
	return normalized

static func issue_is_expected_invalid(mission_manager: Variant, issue: Dictionary) -> bool:
	if bool(issue.get("expected_invalid", false)):
		return true
	var entity_id: String = str(issue.get("entity_id", "")).strip_edges()
	if entity_id.is_empty() or mission_manager == null:
		return false
	return mission_manager.has_method("is_task_test_expected_invalid_object_id") and bool(mission_manager.call("is_task_test_expected_invalid_object_id", entity_id))

static func build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	var canonical: Dictionary = IssueContractRef.canonicalize(issue)
	return {
		"id":str(canonical.get("code", "")),
		"label":str(canonical.get("issue_type", "validation")).replace("_", " ").capitalize(),
		"status":status,
		"message":str(canonical.get("fallback", "")),
		"count":1,
		"entity_kind":str(Dictionary(canonical.get("details", {})).get("entity_kind", "")),
		"entity_id":str(canonical.get("entity_id", "")),
		"cell":Dictionary(canonical.get("details", {})).get("cell", Vector2i(-1, -1)),
		"issue_id":str(canonical.get("code", ""))
	}

static func _build_readiness_report(mission_manager: Variant, decision: String) -> Dictionary:
	var unavailable: Dictionary = normalize_readiness_report({})
	if mission_manager == null:
		unavailable["summary"] = "Mission manager is unavailable."
		return unavailable
	if mission_manager.has_method("_is_task_test_constructor_context") and not bool(mission_manager.call("_is_task_test_constructor_context")):
		unavailable["summary"] = "Readiness works only in TASK TEST constructor mode."
		return unavailable

	var raw_issues: Array = []
	if mission_manager.has_method("get_map_constructor_validation_issues"):
		var issue_values: Variant = mission_manager.call("get_map_constructor_validation_issues")
		if issue_values is Array:
			raw_issues = Array(issue_values).duplicate(true)
	var canonical_issues: Array[Dictionary] = []
	var recommended: Array[Dictionary] = []
	for value in raw_issues:
		if not value is Dictionary:
			continue
		var raw: Dictionary = Dictionary(value).duplicate(true)
		var expected: bool = issue_is_expected_invalid(mission_manager, raw)
		var severity: String = str(raw.get("severity", "info")).strip_edges().to_lower()
		var code: String = str(raw.get("code", raw.get("reason_code", raw.get("id", "map_constructor.issue_unknown")))).strip_edges().to_lower()
		var issue: Dictionary = IssueContractRef.canonicalize({
			"code":code,
			"severity":severity,
			"blocks_promotion":bool(raw.get("blocks_promotion", severity == IssueContractRef.SEVERITY_ERROR and not expected)),
			"entity_id":str(raw.get("entity_id", "")),
			"field_id":str(raw.get("field_id", raw.get("field", ""))),
			"profile_id":str(raw.get("profile_id", "")),
			"binding_id":str(raw.get("binding_id", "")),
			"source_id":str(raw.get("source_id", "")),
			"target_id":str(raw.get("target_id", "")),
			"message_key":str(raw.get("message_key", code)),
			"fallback":str(raw.get("fallback", raw.get("message", ""))),
			"fix_hint":str(raw.get("fix_hint", "")),
			"expected_invalid":expected,
			"issue_type":str(raw.get("issue_type", "validation")),
			"details":{
				"entity_kind":str(raw.get("entity_kind", "")),
				"cell":raw.get("cell", Vector2i(-1, -1)),
				"legacy_issue":raw
			}
		})
		canonical_issues.append(issue)
		if bool(issue.get("blocks_promotion", false)):
			recommended.append_array(_recommended_actions(mission_manager, raw, issue))

	_append_runtime_warning_issues(mission_manager, canonical_issues)
	var options: Dictionary = {
		"serialization_ok":_optional_bool(mission_manager, "is_map_constructor_serialization_ready", true),
		"write_ok":_optional_bool(mission_manager, "is_map_constructor_write_ready", true),
		"loadable":_optional_bool(mission_manager, "is_map_constructor_task_test_loadable", true)
	}
	var report: Dictionary
	match decision:
		"draft_save":
			report = CanonicalReadinessRef.for_draft_save(canonical_issues, options)
		"task_test":
			report = CanonicalReadinessRef.for_task_test(canonical_issues, options)
		_:
			report = CanonicalReadinessRef.for_promotion(canonical_issues, options)
	report["recommended_actions"] = recommended
	report["checks"] = _checks_for_report(report)
	return normalize_readiness_report(report)

static func _append_runtime_warning_issues(mission_manager: Variant, issues: Array[Dictionary]) -> void:
	if not mission_manager.has_method("get_task_test_system_audit_report"):
		return
	var audit_value: Variant = mission_manager.call("get_task_test_system_audit_report")
	if not audit_value is Dictionary:
		return
	var runtime_values: Variant = Dictionary(audit_value).get("runtime_cell_warnings", [])
	if not runtime_values is Array:
		return
	var index: int = 0
	for warning in Array(runtime_values):
		issues.append(IssueContractRef.canonicalize({
			"code":"map_constructor.runtime_warning.%d" % index,
			"severity":IssueContractRef.SEVERITY_WARNING,
			"blocks_promotion":false,
			"fallback":str(warning),
			"issue_type":"runtime_warning"
		}))
		index += 1

static func _recommended_actions(mission_manager: Variant, raw_issue: Dictionary, canonical_issue: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if mission_manager.has_method("get_map_constructor_issue_autofix_options"):
		var options_value: Variant = mission_manager.call("get_map_constructor_issue_autofix_options", raw_issue)
		if options_value is Array:
			for value in Array(options_value):
				if not value is Dictionary:
					continue
				var option: Dictionary = Dictionary(value)
				result.append({
					"label":str(option.get("label", "Fix issue")),
					"action_type":"autofix",
					"fix_type":str(option.get("fix_type", "")),
					"cleanup_type":"",
					"options":Dictionary(option.get("options", {})).duplicate(true),
					"target_issue_id":str(canonical_issue.get("code", ""))
				})
	result.append({
		"label":"Jump to issue",
		"action_type":"jump",
		"fix_type":"",
		"cleanup_type":"",
		"options":{},
		"target_issue_id":str(canonical_issue.get("code", ""))
	})
	return result

static func _checks_for_report(report: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for issue in Array(report.get("issues", [])):
		if not issue is Dictionary:
			continue
		var canonical: Dictionary = Dictionary(issue)
		var status: String = "info"
		if bool(canonical.get("expected_invalid", false)):
			status = "expected_invalid"
		elif bool(canonical.get("blocks_promotion", false)):
			status = "fail"
		elif str(canonical.get("severity", "")) == IssueContractRef.SEVERITY_WARNING:
			status = "warning"
		result.append(build_readiness_check(canonical, status))
	return result

static func _optional_bool(target: Variant, method_name: String, fallback: bool) -> bool:
	if target != null and target.has_method(method_name):
		return bool(target.call(method_name))
	return fallback
