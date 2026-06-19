extends SceneTree

const TESTS: Array = [
	preload("res://tests/smoke/test_definition_loading.gd"),
	preload("res://tests/smoke/test_test_room_loading.gd"),
	preload("res://tests/smoke/test_power_interaction.gd"),
	preload("res://tests/smoke/test_document_roundtrip.gd"),
	preload("res://tests/smoke/test_visual_resolution.gd"),
]

func _init() -> void:
	var errors: Array[String] = []
	for test_script: Variant in TESTS:
		for error: Variant in Array(test_script.run()):
			errors.append(str(error))
	if errors.is_empty():
		print("newbip smoke tests: PASS")
		quit(0)
		return
	for error: String in errors:
		push_error(error)
	print("newbip smoke tests: FAIL (%d)" % errors.size())
	quit(1)
