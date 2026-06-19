extends SceneTree

const TESTS: Array = [
	preload("res://tests/smoke/test_definition_loading.gd"),
	preload("res://tests/smoke/test_test_room_loading.gd"),
	preload("res://tests/smoke/test_power_interaction.gd"),
	preload("res://tests/smoke/test_document_roundtrip.gd"),
	preload("res://tests/smoke/test_document_migration.gd"),
	preload("res://tests/smoke/test_visual_resolution.gd"),
	preload("res://tests/smoke/test_command_history.gd"),
	preload("res://tests/smoke/test_passability.gd"),
	preload("res://tests/smoke/test_agent_path.gd"),
	preload("res://tests/smoke/test_context_actions.gd"),
]

func _init() -> void:
	var errors: Array[String] = []
	for test_script: Variant in TESTS:
		var raw_errors: Variant = test_script.call("run")
		for error: Variant in Array(raw_errors):
			errors.append(str(error))
	if errors.is_empty():
		print("newbip smoke tests: PASS")
		quit(0)
		return
	for error: String in errors:
		push_error(error)
	print("newbip smoke tests: FAIL (%d)" % errors.size())
	quit(1)
