extends RefCounted
class_name MapConstructorReadinessService

const IssueContractRef = preload("res://scripts/game/map_constructor_issue_contract.gd")

static func build(issues: Array, options: Dictionary = {}) -> Dictionary:
	var canonical_issues: Array[Dictionary] = IssueContractRef.canonicalize_all(issues)
	var expected_invalid: Array[Dictionary] = []
	var blockers: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	for issue in canonical_issues:
		if bool(issue.get("expected_invalid", false)):
			expected_invalid.append(issue)
		if bool(issue.get("blocks_promotion", false)):
			blockers.append(issue)
		if str(issue.get("severity", "")) == IssueContractRef.SEVERITY_WARNING:
			warnings.append(issue)

	var serialization_ok: bool = bool(options.get("serialization_ok", true))
	var write_ok: bool = bool(options.get("write_ok", true))
	var loadable: bool = bool(options.get("loadable", true))
	var definition_errors: Array[Dictionary] = IssueContractRef.canonicalize_all(Array(options.get("definition_issues", [])))
	for issue in definition_errors:
		if not bool(issue.get("blocks_promotion", false)):
			issue["blocks_promotion"] = true
		blockers.append(issue)
	blockers = IssueContractRef.canonicalize_all(blockers)

	var draft_save_allowed: bool = serialization_ok and write_ok
	var task_test_allowed: bool = loadable
	var promotion_allowed: bool = blockers.is_empty()
	var status: String = "ready"
	if not promotion_allowed:
		status = "blocked"
	elif not warnings.is_empty():
		status = "warning"

	var result: Dictionary = {
		"draft_save_allowed":draft_save_allowed,
		"task_test_allowed":task_test_allowed,
		"promotion_allowed":promotion_allowed,
		"blocking_issues":blockers,
		"warnings":warnings,
		"expected_invalid_issues":expected_invalid,
		"issues":canonical_issues,
		"serialization_ok":serialization_ok,
		"write_ok":write_ok,
		"loadable":loadable,
		"status":status,
		"summary":_summary(draft_save_allowed, task_test_allowed, promotion_allowed, blockers.size(), warnings.size(), expected_invalid.size()),
		"blocking_count":blockers.size(),
		"warning_count":warnings.size(),
		"expected_invalid_count":expected_invalid.size(),
		"info_count":_count_severity(canonical_issues, IssueContractRef.SEVERITY_INFO),
		"checks":_compatibility_checks(canonical_issues),
		"warning_issues":warnings,
		"recommended_actions":[],
		"ok":true,
		"success":true,
		"playable":promotion_allowed
	}
	if not draft_save_allowed:
		result["save_reason_code"] = "map_constructor.serialization_failed" if not serialization_ok else "map_constructor.write_failed"
	if not task_test_allowed:
		result["task_test_reason_code"] = "map_constructor.map_not_loadable"
	if not promotion_allowed:
		result["promotion_reason_code"] = "map_constructor.promotion_blocked"
	return result

static func for_draft_save(issues: Array, options: Dictionary = {}) -> Dictionary:
	return build(issues, options)

static func for_task_test(issues: Array, options: Dictionary = {}) -> Dictionary:
	return build(issues, options)

static func for_promotion(issues: Array, options: Dictionary = {}) -> Dictionary:
	return build(issues, options)

static func _count_severity(issues: Array[Dictionary], severity: String) -> int:
	var count: int = 0
	for issue in issues:
		if str(issue.get("severity", "")) == severity:
			count += 1
	return count

static func _compatibility_checks(issues: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for issue in issues:
		var status: String = "info"
		if bool(issue.get("expected_invalid", false)):
			status = "expected_invalid"
		elif bool(issue.get("blocks_promotion", false)):
			status = "fail"
		elif str(issue.get("severity", "")) == IssueContractRef.SEVERITY_WARNING:
			status = "warning"
		result.append({
			"id":str(issue.get("code", "")),
			"label":str(issue.get("issue_type", "validation")).replace("_", " ").capitalize(),
			"status":status,
			"message":str(issue.get("fallback", "")),
			"count":1,
			"entity_id":str(issue.get("entity_id", "")),
			"issue_id":str(issue.get("code", ""))
		})
	return result

static func _summary(save_allowed: bool, task_allowed: bool, promotion_allowed: bool, blocker_count: int, warning_count: int, expected_count: int) -> String:
	return "Draft Save=%s | TASK TEST=%s | Promotion=%s | blockers=%d warnings=%d expected-invalid=%d" % [
		"allowed" if save_allowed else "blocked",
		"allowed" if task_allowed else "blocked",
		"allowed" if promotion_allowed else "blocked",
		blocker_count,
		warning_count,
		expected_count
	]
