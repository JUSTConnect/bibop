extends SceneTree

const MarkerModel = preload("res://scripts/game/map_constructor_marker_model.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _has_role(rows: Array[Dictionary], entity_id: String, role: String) -> bool:
	for row in rows:
		if str(row.get("entity_id", "")) == entity_id and str(row.get("role", "")) == role:
			return true
	return false

func _run() -> void:
	await process_frame
	var issues: Array = [
		{"code":"route.warning", "severity":"warning", "blocks_promotion":false, "entity_id":"warning_a"},
		{"code":"binding.missing", "severity":"error", "blocks_promotion":true, "entity_id":"blocked_a"}
	]
	var off_rows: Array[Dictionary] = MarkerModel.build(["ready_a", "warning_a", "blocked_a"], issues, false)
	_check(not _has_role(off_rows, "ready_a", "ready"), "diagnostics OFF showed healthy marker")
	_check(_has_role(off_rows, "warning_a", "warning"), "warning marker missing")
	_check(_has_role(off_rows, "blocked_a", "blocked"), "promotion blocker marker missing")
	var on_rows: Array[Dictionary] = MarkerModel.build(["ready_a", "warning_a", "blocked_a"], issues, true, ["ready_a"])
	_check(_has_role(on_rows, "ready_a", "ready"), "diagnostics ON ready marker missing")
	_check(_has_role(on_rows, "ready_a", "override"), "test override marker missing")
	if failures.is_empty():
		print("MAP_CONSTRUCTOR_DIAGNOSTIC_POLICY_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MAP_CONSTRUCTOR_DIAGNOSTIC_POLICY_GATE: FAIL: %s" % failure)
	quit(1)
