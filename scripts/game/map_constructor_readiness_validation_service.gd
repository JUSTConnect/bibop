extends RefCounted
class_name MapConstructorReadinessValidationService

static func build_save_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager)

static func build_load_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager)

static func build_promotion_readiness_report(mission_manager: Variant) -> Dictionary:
	return _build_readiness_report(mission_manager)

static func normalize_readiness_report(report: Variant) -> Dictionary:
	var normalized: Dictionary = {
		"ok": false,
		"playable": false,
		"status": "unknown",
		"summary": "Mission readiness unavailable.",
		"blocking_count": 0,
		"warning_count": 0,
		"info_count": 0,
		"expected_invalid_count": 0,
		"checks": [],
		"blocking_issues": [],
		"warning_issues": [],
		"expected_invalid_issues": [],
		"recommended_actions": []
	}
	if report is Dictionary:
		for key in report:
			normalized[key] = report[key]
	return normalized

static func issue_is_expected_invalid(mission_manager: Variant, issue: Dictionary) -> bool:
	var entity_id: String = str(issue.get("entity_id", "")).strip_edges()
	if entity_id.is_empty():
		return false
	return mission_manager.is_task_test_expected_invalid_object_id(entity_id)

static func build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	var issue_id: String = _safe_string(issue.get("id", ""))
	var label: String = "Validation check"
	if issue_id.find("wm_") == 0:
		label = "Wall-mounted attachment"
	elif issue_id.find("link_") == 0:
		label = "Entity links"
	elif issue_id.find("duplicate_") == 0:
		label = "Duplicate occupancy"
	elif issue_id.find("generic_cable_") == 0:
		label = "Generic cable/power readiness"
	elif issue_id.find("generic_airflow_") == 0:
		label = "Generic airflow/cooling readiness"
	elif issue_id.find("missing_marker_") == 0:
		label = "Mission markers"
	return {
		"id": issue_id,
		"label": label,
		"status": status,
		"message": str(issue.get("message", "")),
		"count": 1,
		"entity_kind": str(issue.get("entity_kind", "")),
		"entity_id": str(issue.get("entity_id", "")),
		"cell": Vector2i(issue.get("cell", Vector2i(-1, -1))),
		"issue_id": issue_id
	}

static func _build_readiness_report(mission_manager: Variant) -> Dictionary:
	var report: Dictionary = normalize_readiness_report({})
	if not mission_manager._is_task_test_constructor_context():
		report["summary"] = "Readiness works only in TASK TEST constructor mode."
		return report
	var checks: Array[Dictionary] = []
	var blocking: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	var expected_invalid: Array[Dictionary] = []
	var recommended: Array[Dictionary] = []
	var constructor_issues: Array[Dictionary] = mission_manager._safe_dictionary_array(mission_manager.get_map_constructor_validation_issues())
	for issue in constructor_issues:
		var issue_row: Dictionary = mission_manager._safe_dictionary(issue)
		var severity: String = _safe_string(issue_row.get("severity", "info")).to_lower()
		var expected: bool = issue_is_expected_invalid(mission_manager, issue_row)
		if expected:
			expected_invalid.append(issue_row)
			checks.append(build_readiness_check(issue_row, "expected_invalid"))
			continue
		if severity == "error":
			blocking.append(issue_row)
			checks.append(build_readiness_check(issue_row, "fail"))
			var issue_fix_options: Array[Dictionary] = []
			issue_fix_options.append_array(mission_manager.get_map_constructor_issue_autofix_options(issue_row))
			for fix_opt in issue_fix_options:
				var option: Dictionary = mission_manager._safe_dictionary(fix_opt)
				recommended.append({"label": _safe_string(option.get("label", "Fix issue")), "action_type": "autofix", "fix_type": _safe_string(option.get("fix_type", "")), "cleanup_type": "", "options": mission_manager._safe_dictionary(option.get("options", {})), "target_issue_id": _safe_string(issue_row.get("id", ""))})
			var message_text: String = _safe_string(issue_row.get("message", "")).to_lower()
			if message_text.find("missing") >= 0:
				recommended.append({"label":"Clean invalid references", "action_type":"cleanup", "fix_type":"", "cleanup_type":"invalid_references", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			if message_text.find("broken") >= 0 or message_text.find("missing") >= 0:
				recommended.append({"label":"Fix broken references", "action_type":"autofix", "fix_type":"clear_all_broken_references", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			if _safe_string(issue_row.get("id", "")).begins_with("wm_"):
				recommended.append({"label":"Repair wall-mounted attachments", "action_type":"autofix", "fix_type":"repair_all_wall_mounted_attachments", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			recommended.append({"label":"Jump to issue", "action_type":"jump", "fix_type":"", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
		elif severity == "warning":
			warnings.append(issue_row)
			checks.append(build_readiness_check(issue_row, "warning"))
		else:
			checks.append(build_readiness_check(issue_row, "info"))
	var audit_summary: Dictionary = mission_manager.get_map_constructor_audit_summary()
	checks.append({"id":"audit_summary","label":"Audit coverage","status":"info","message":"missing=%d invalid=%d runtime_warn=%d duplicates=%d" % [int(audit_summary.get("missing_coverage_count",0)), int(audit_summary.get("invalid_links_count",0)), int(audit_summary.get("runtime_warnings_count",0)), int(audit_summary.get("duplicate_cell_warnings_count",0))],"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var task_audit: Dictionary = mission_manager.get_task_test_system_audit_report()
	var runtime_warnings: Array = mission_manager._safe_array(task_audit.get("runtime_cell_warnings", []))
	for runtime_warning in runtime_warnings:
		warnings.append({"id":"runtime_warning_%d" % warnings.size(), "severity":"warning", "message":_safe_string(runtime_warning)})
		checks.append({"id":"runtime_warning_%d" % warnings.size(),"label":"Runtime warning","status":"warning","message":_safe_string(runtime_warning),"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var blocking_count: int = blocking.size()
	var warning_count: int = warnings.size()
	var expected_count: int = expected_invalid.size()
	var info_count: int = maxi(0, checks.size() - blocking_count - warning_count - expected_count)
	var status: String = "playable"
	if blocking_count > 0:
		status = "blocked"
	elif warning_count > 0:
		status = "warning"
	report["ok"] = true
	report["playable"] = blocking_count == 0
	report["status"] = status
	report["summary"] = "Readiness %s | blocking=%d warnings=%d expected-invalid=%d info=%d" % [status.to_upper(), blocking_count, warning_count, expected_count, info_count]
	report["blocking_count"] = blocking_count
	report["warning_count"] = warning_count
	report["info_count"] = info_count
	report["expected_invalid_count"] = expected_count
	report["checks"] = checks
	report["blocking_issues"] = blocking
	report["warning_issues"] = warnings
	report["expected_invalid_issues"] = expected_invalid
	report["recommended_actions"] = recommended
	return report

static func _safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value).strip_edges()
