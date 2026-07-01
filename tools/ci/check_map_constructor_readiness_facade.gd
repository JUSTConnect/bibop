extends SceneTree

const Facade = preload("res://scripts/game/map_constructor_readiness_validation_service.gd")

class FakeManager:
	extends RefCounted
	var serialization_ready: bool = true
	var write_ready: bool = true
	var task_test_loadable: bool = true
	var issues: Array = []

	func _is_task_test_constructor_context() -> bool:
		return true

	func get_map_constructor_validation_issues() -> Array:
		return issues.duplicate(true)

	func is_task_test_expected_invalid_object_id(entity_id: String) -> bool:
		return entity_id == "expected_a"

	func get_map_constructor_issue_autofix_options(_issue: Dictionary) -> Array:
		return [{"label":"Repair relation", "fix_type":"repair_relation", "options":{}}]

	func get_task_test_system_audit_report() -> Dictionary:
		return {"runtime_cell_warnings":[]}

	func is_map_constructor_serialization_ready() -> bool:
		return serialization_ready

	func is_map_constructor_write_ready() -> bool:
		return write_ready

	func is_map_constructor_task_test_loadable() -> bool:
		return task_test_loadable

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _run() -> void:
	await process_frame
	var manager := FakeManager.new()
	manager.issues = [
		{"id":"arbitrary_relation_problem", "severity":"error", "entity_id":"door_a", "message":"Text may change", "issue_type":"binding"},
		{"id":"expected_problem", "severity":"error", "entity_id":"expected_a", "message":"Expected invalid", "issue_type":"authoring"}
	]
	var save_report: Dictionary = Facade.build_save_readiness_report(manager)
	var task_report: Dictionary = Facade.build_load_readiness_report(manager)
	var promotion_report: Dictionary = Facade.build_promotion_readiness_report(manager)
	_check(bool(save_report.get("draft_save_allowed", false)), "instance blocker incorrectly blocked Draft Save")
	_check(bool(task_report.get("task_test_allowed", false)), "loadable invalid map incorrectly blocked TASK TEST")
	_check(not bool(promotion_report.get("promotion_allowed", true)), "promotion blocker was ignored")
	_check(int(promotion_report.get("blocking_count", 0)) == 1, "expected-invalid issue counted as promotion blocker")
	_check(int(promotion_report.get("expected_invalid_count", 0)) == 1, "expected-invalid issue was not preserved")
	var checks: Array = Array(promotion_report.get("checks", []))
	var binding_label_found: bool = false
	for value in checks:
		if value is Dictionary and str(Dictionary(value).get("id", "")) == "arbitrary_relation_problem":
			binding_label_found = str(Dictionary(value).get("label", "")) == "Binding"
	_check(binding_label_found, "readiness label was not driven by structured issue_type")
	_check(not Array(promotion_report.get("recommended_actions", [])).is_empty(), "canonical blocker lost structured fix actions")

	manager.serialization_ready = false
	var failed_save: Dictionary = Facade.build_save_readiness_report(manager)
	_check(not bool(failed_save.get("draft_save_allowed", true)), "serialization failure did not block Draft Save")
	_check(bool(failed_save.get("task_test_allowed", false)), "serialization failure incorrectly changed independent TASK TEST decision")

	manager.serialization_ready = true
	manager.task_test_loadable = false
	var failed_load: Dictionary = Facade.build_load_readiness_report(manager)
	_check(not bool(failed_load.get("task_test_allowed", true)), "unloadable map did not block TASK TEST")
	_check(bool(failed_load.get("draft_save_allowed", false)), "unloadable map incorrectly blocked Draft Save")

	var source: String = FileAccess.get_file_as_string("res://scripts/game/map_constructor_readiness_validation_service.gd")
	_check(not source.contains("find(\"missing\")"), "readiness facade still classifies issue messages")
	_check(not source.contains("begins_with(\"wm_\")"), "readiness facade still classifies issue ID prefixes")
	_check(source.contains("CanonicalReadinessRef"), "readiness facade does not delegate to canonical service")

	if failures.is_empty():
		print("MAP_CONSTRUCTOR_READINESS_FACADE_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_READINESS_FACADE_GATE: FAIL: %s" % failure)
	quit(1)
