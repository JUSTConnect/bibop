extends SceneTree

const IssueContract = preload("res://scripts/game/map_constructor_issue_contract.gd")
const Readiness = preload("res://scripts/game/map_constructor_readiness_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _run() -> void:
	await process_frame
	var issues: Array = [
		{"code":"route.warning", "severity":"warning", "entity_id":"duct_a", "fallback":"Route warning"},
		{"code":"binding.missing", "severity":"error", "blocks_promotion":true, "entity_id":"door_a", "fallback":"Binding missing"}
	]
	var canonical: Array[Dictionary] = IssueContract.canonicalize_all(issues)
	_check(canonical.size() == 2, "canonical issue count changed")
	_check(str(canonical[0].get("code", "")) == "binding.missing", "blocker order changed")
	for field_name in IssueContract.REQUIRED_FIELDS:
		_check(canonical[0].has(field_name), "missing issue field %s" % field_name)
	var report: Dictionary = Readiness.build(issues, {"serialization_ok":true, "write_ok":true, "loadable":true})
	_check(bool(report.get("draft_save_allowed", false)), "instance issue blocked Draft Save")
	_check(bool(report.get("task_test_allowed", false)), "loadable map blocked TASK TEST")
	_check(not bool(report.get("promotion_allowed", true)), "promotion blocker ignored")
	var failed_save: Dictionary = Readiness.build([], {"serialization_ok":false, "loadable":true})
	_check(not bool(failed_save.get("draft_save_allowed", true)), "serialization failure allowed Draft Save")
	_check(bool(failed_save.get("task_test_allowed", false)), "serialization failure blocked TASK TEST")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_READINESS_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_READINESS_GATE: FAIL: %s" % failure)
	quit(1)
