extends SceneTree

const IssueContract = preload("res://scripts/game/map_constructor_issue_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _run() -> void:
	await process_frame
	var raw: Dictionary = {
		"reason_code":"binding.missing_endpoint",
		"severity":"error",
		"entity_id":"door_a",
		"source_id":"terminal_a",
		"message":"Missing endpoint"
	}
	var result: Dictionary = IssueContract.validate(raw)
	_check(bool(result.get("success", false)), "canonical issue validation failed")
	var issue: Dictionary = Dictionary(result.get("issue", {}))
	for field_name in IssueContract.REQUIRED_FIELDS:
		_check(issue.has(field_name), "missing canonical field %s" % field_name)
	_check(str(issue.get("code", "")) == "binding.missing_endpoint", "reason_code alias was not canonicalized")
	_check(bool(issue.get("blocks_promotion", false)), "error did not default to promotion blocker")
	_check(str(issue.get("fallback", "")) == "Missing endpoint", "message fallback was not preserved")
	var sorted: Array[Dictionary] = IssueContract.canonicalize_all([
		{"code":"z.warning", "severity":"warning", "entity_id":"z"},
		{"code":"a.blocker", "severity":"error", "blocks_promotion":true, "entity_id":"a"}
	])
	_check(sorted.size() == 2 and str(sorted[0].get("code", "")) == "a.blocker", "issue ordering is not deterministic blocker-first")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_ISSUE_CONTRACT_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_ISSUE_CONTRACT_GATE: FAIL: %s" % failure)
	quit(1)
