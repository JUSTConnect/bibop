extends SceneTree

const MarkerModel = preload("res://scripts/game/map_constructor_marker_model.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _find(rows: Array[Dictionary], entity_id: String, role: String) -> Dictionary:
	for row in rows:
		if str(row.get("entity_id", "")) == entity_id and str(row.get("role", "")) == role:
			return row
	return {}

func _run() -> void:
	await process_frame
	var issues: Array = [
		{"code":"z.warning", "severity":"warning", "entity_id":"warning_a"},
		{"code":"a.warning", "severity":"warning", "entity_id":"warning_a"},
		{"code":"binding.missing", "severity":"error", "blocks_promotion":true, "entity_id":"blocked_a"}
	]
	var hidden: Array[Dictionary] = MarkerModel.build(["ready_a", "warning_a", "blocked_a"], issues, false)
	_check(_find(hidden, "ready_a", MarkerModel.ROLE_READY).is_empty(), "healthy marker visible while diagnostics are off")
	var warning: Dictionary = _find(hidden, "warning_a", MarkerModel.ROLE_WARNING)
	_check(str(warning.get("code", "")) == "a.warning", "warning selection is not deterministic")
	_check(not _find(hidden, "blocked_a", MarkerModel.ROLE_PROMOTION_BLOCKER).is_empty(), "promotion blocker marker missing")
	var visible: Array[Dictionary] = MarkerModel.build(["ready_a"], [], true, ["ready_a", "ready_a"])
	_check(not _find(visible, "ready_a", MarkerModel.ROLE_READY).is_empty(), "ready marker missing")
	_check(not _find(visible, "ready_a", MarkerModel.ROLE_TEST_OVERRIDE).is_empty(), "test override marker missing")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_DIAGNOSTIC_POLICY_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_DIAGNOSTIC_POLICY_GATE: FAIL: %s" % failure)
	quit(1)
