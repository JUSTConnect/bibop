extends RefCounted
class_name MapConstructorMarkerModel

const IssueContractRef = preload("res://scripts/game/map_constructor_issue_contract.gd")

const ROLE_READY := "ready"
const ROLE_WARNING := "warning"
const ROLE_PROMOTION_BLOCKER := "promotion_blocker"
const ROLE_TEST_OVERRIDE := "test_override"

static func build(entity_ids: Array, issues: Array, diagnostics_enabled: bool, override_entity_ids: Array = []) -> Array[Dictionary]:
	var normalized_ids: Array[String] = _normalized_ids(entity_ids)
	var override_ids: Array[String] = _normalized_ids(override_entity_ids)
	var canonical_issues: Array[Dictionary] = IssueContractRef.canonicalize_all(issues)
	var result: Array[Dictionary] = []
	for entity_id in normalized_ids:
		var selected: Dictionary = _selected_issue(entity_id, canonical_issues)
		if not selected.is_empty():
			result.append(_issue_marker(entity_id, selected))
		elif diagnostics_enabled:
			result.append({
				"entity_id":entity_id,
				"role":ROLE_READY,
				"code":"map_constructor.ready",
				"severity":IssueContractRef.SEVERITY_INFO,
				"blocks_promotion":false
			})
		if diagnostics_enabled and override_ids.has(entity_id):
			result.append({
				"entity_id":entity_id,
				"role":ROLE_TEST_OVERRIDE,
				"code":"map_constructor.test_override_active",
				"severity":IssueContractRef.SEVERITY_INFO,
				"blocks_promotion":false
			})
	return result

static func _normalized_ids(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var entity_id: String = str(value).strip_edges()
		if not entity_id.is_empty() and not result.has(entity_id):
			result.append(entity_id)
	result.sort()
	return result

static func _selected_issue(entity_id: String, issues: Array[Dictionary]) -> Dictionary:
	var warning: Dictionary = {}
	for issue in issues:
		if str(issue.get("entity_id", "")) != entity_id:
			continue
		if bool(issue.get("blocks_promotion", false)):
			return issue.duplicate(true)
		if warning.is_empty() and str(issue.get("severity", "")) == IssueContractRef.SEVERITY_WARNING:
			warning = issue.duplicate(true)
	return warning

static func _issue_marker(entity_id: String, issue: Dictionary) -> Dictionary:
	var blocks_promotion: bool = bool(issue.get("blocks_promotion", false))
	return {
		"entity_id":entity_id,
		"role":ROLE_PROMOTION_BLOCKER if blocks_promotion else ROLE_WARNING,
		"code":str(issue.get("code", "")),
		"severity":str(issue.get("severity", IssueContractRef.SEVERITY_INFO)),
		"blocks_promotion":blocks_promotion,
		"message_key":str(issue.get("message_key", "")),
		"fallback":str(issue.get("fallback", ""))
	}
