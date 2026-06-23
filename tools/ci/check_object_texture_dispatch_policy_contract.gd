extends SceneTree

const PolicyRef = preload("res://scripts/visual/renderer/object_texture_dispatch_policy.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_attempt_plans()
	_check_accent_policy()
	_check_descriptor_routes()
	_check_execution_simulation()
	if failures.is_empty():
		print("ObjectTextureDispatchPolicy contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_attempt_plans() -> void:
	_expect_plan("loot case", {"is_case_visual": true, "case_asset_id": "case_open"}, [_a(0, "png", "case_open", "case")])
	_expect_plan("png primary", {"profile_key": "crate", "primary_asset_id": "crate_01", "primary_is_png": true}, [_a(0, "png", "crate_01", "primary")])
	_expect_plan("non png", {"profile_key": "crate", "primary_asset_id": "object_generic", "primary_is_png": false}, [_a(0, "optional", "object_generic", "primary"), _a(1, "legacy", "object_generic", "primary")])
	_expect_plan("cable", {"profile_key": "cable", "primary_asset_id": "object_cable", "primary_is_png": false}, [])
	_expect_plan("door fallback only", {"profile_key": "cable", "has_door_visual": true, "door_texture_asset_id": "door_locked"}, [_a(0, "optional", "door_locked", "door_state")])
	_expect_plan("terminal fallback only", {"profile_key": "cable", "has_terminal_visual": true, "terminal_texture_asset_id": "terminal_on"}, [_a(0, "optional", "terminal_on", "terminal_state")])
	_expect_plan("both fallbacks", {"profile_key": "crate", "primary_asset_id": "crate_01", "primary_is_png": true, "has_door_visual": true, "door_texture_asset_id": "door_locked", "has_terminal_visual": true, "terminal_texture_asset_id": "terminal_on"}, [_a(0, "png", "crate_01", "primary"), _a(1, "optional", "door_locked", "door_state"), _a(2, "optional", "terminal_on", "terminal_state")])
	_expect_plan("empty asset ids", {"profile_key": "crate", "primary_asset_id": "", "primary_is_png": false, "has_door_visual": true, "door_texture_asset_id": "", "has_terminal_visual": true, "terminal_texture_asset_id": ""}, [_a(0, "optional", "", "primary"), _a(1, "legacy", "", "primary"), _a(2, "optional", "", "door_state"), _a(3, "optional", "", "terminal_state")])
	_expect_plan("malformed", {}, [_a(0, "optional", "", "primary"), _a(1, "legacy", "", "primary")])
	var context := {"profile_key": "crate", "primary_asset_id": "crate_01", "primary_is_png": true}
	_expect(PolicyRef.build_attempt_plan(context) == PolicyRef.build_attempt_plan(context), "repeated identical input must be stable")

func _check_accent_policy() -> void:
	_expect(PolicyRef.should_draw_success_accent({"texture_succeeded": true, "is_case_visual": false}), "non-case success must draw accent")
	_expect(not PolicyRef.should_draw_success_accent({"texture_succeeded": true, "is_case_visual": true}), "case success must suppress accent")
	_expect(not PolicyRef.should_draw_success_accent({"texture_succeeded": false, "is_case_visual": false}), "failed texture must not draw accent")

func _check_descriptor_routes() -> void:
	_expect(PolicyRef.get_descriptor_route("object_sprite", "wall_authored_canvas", "floor_authored_canvas") == "object", "object route changed")
	_expect(PolicyRef.get_descriptor_route("wall_authored_canvas", "wall_authored_canvas", "floor_authored_canvas") == "wall_authored", "wall route changed")
	_expect(PolicyRef.get_descriptor_route("floor_authored_canvas", "wall_authored_canvas", "floor_authored_canvas") == "floor_authored", "floor route changed")
	_expect(PolicyRef.get_descriptor_route("unknown", "wall_authored_canvas", "floor_authored_canvas") == "object", "unknown route changed")

func _check_execution_simulation() -> void:
	var attempts := [_a(0, "optional", "miss", "primary"), _a(1, "legacy", "hit", "primary"), _a(2, "optional", "unused", "terminal_state")]
	var consumed: Array[String] = []
	var success := false
	for attempt in attempts:
		consumed.append(str(attempt.get("asset_id", "")))
		if str(attempt.get("asset_id", "")) == "hit":
			success = true
			if bool(attempt.get("stop_on_success", true)):
				break
	_expect(success, "simulation must report success")
	_expect(consumed == ["miss", "hit"], "simulation must stop at first success")

func _expect_plan(label: String, context: Dictionary, expected: Array) -> void:
	var actual := PolicyRef.build_attempt_plan(context)
	_expect(actual.size() == expected.size(), "%s size changed: %s" % [label, str(actual)])
	var count = mini(actual.size(), expected.size())
	for index in range(count):
		_expect(Dictionary(actual[index]) == Dictionary(expected[index]), "%s attempt %d changed: %s" % [label, index, str(actual[index])])

func _a(order: int, kind: String, asset_id: String, source: String) -> Dictionary:
	return {"order": order, "kind": kind, "asset_id": asset_id, "source": source, "stop_on_success": true}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
