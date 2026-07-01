extends SceneTree

const MigrationService = preload("res://scripts/world/versioned_snapshot_migration_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _issue_by_code(result: Dictionary, code: String) -> Dictionary:
	for value in Array(result.get("issues", [])):
		if value is Dictionary and str(Dictionary(value).get("code", "")) == code:
			return Dictionary(value)
	return {}

func _run() -> void:
	await process_frame
	var older: Dictionary = {"format_version": MigrationService.MIN_SUPPORTED_FORMAT_VERSION - 1, "entities": [], "bindings": []}
	var older_before: String = var_to_str(older)
	var older_result: Dictionary = MigrationService.migrate_document(older)
	_assert(not bool(older_result.get("success", true)), "older unsupported version was accepted")
	_assert(str(older_result.get("code", "")) == MigrationService.CODE_UNSUPPORTED_OLDER_VERSION, "older version reason code mismatch")
	_assert(var_to_str(older) == older_before, "older unsupported snapshot was mutated")
	var older_issue: Dictionary = _issue_by_code(older_result, MigrationService.CODE_UNSUPPORTED_OLDER_VERSION)
	_assert(not older_issue.is_empty(), "older version issue missing")
	var details: Dictionary = Dictionary(older_issue.get("details", {}))
	_assert(int(details.get("supported_min", -999)) == MigrationService.MIN_SUPPORTED_FORMAT_VERSION, "supported_min metadata mismatch")

	var current: Dictionary = {"format_version": MigrationService.CURRENT_FORMAT_VERSION, "entities": [], "bindings": []}
	var current_result: Dictionary = MigrationService.migrate_document(current)
	_assert(bool(current_result.get("success", false)), "empty current snapshot rejected")
	_assert(str(current_result.get("code", "")) == MigrationService.CODE_ALREADY_CURRENT, "current snapshot should not migrate")
	_assert(Array(current_result.get("applied_steps", [])).is_empty(), "current snapshot applied migration steps")

	await process_frame
	if failures.is_empty():
		print("VERSION_BOUNDS_MIGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("VERSION_BOUNDS_MIGRATION_GATE: FAIL: %s" % failure)
	quit(1)
