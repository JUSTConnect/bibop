extends SceneTree

const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")

var _failures: Array[String] = []

func _init() -> void:
	_check_door_asset("closed no_power status uses base", {"status": "no_power"}, "door_close_base_floor_01")
	_check_door_asset("closed unpowered status uses base", {"status": "unpowered"}, "door_close_base_floor_01")
	_check_door_asset("closed false has_power uses base", {"has_power": false}, "door_close_base_floor_01")
	_check_door_asset("closed powered off status uses off", {"status": "off", "has_power": true}, "door_close_off_floor_01")
	_check_door_asset("open no_power status uses base", {"is_open": true, "status": "no_power"}, "door_open_base_floor_01")

	_check_case_asset("case locked uses authored locked floor", {"object_type":"case", "locked":true}, "case_locked_floor_01")
	_check_case_asset("loot_case locked uses authored locked floor", {"object_type":"loot_case", "locked":true}, "case_locked_floor_01")
	_check_case_asset("class1 unsearched uses authored class1 floor", {"object_type":"case", "locked":false, "loot_class":"class1", "case_loot_state":"unsearched"}, "case_class1_floor_01")
	_check_case_asset("class2 unsearched uses authored class2 floor", {"object_type":"loot_case", "locked":false, "loot_class":"class2", "case_loot_state":"unsearched"}, "case_class2_floor_01")
	_check_case_asset("class3 unsearched uses authored class3 floor", {"object_type":"loot_crate", "locked":false, "loot_class":"class3", "case_loot_state":"unsearched"}, "case_class3_floor_01")
	_check_case_asset("searched with remaining loot uses authored not empty floor", {"object_type":"case_01", "locked":false, "searched":true, "remaining_loot_count":1}, "case_not_empty_floor_01")
	_check_case_asset("empty uses authored empty floor", {"map_constructor_prefab_id":"case_empty", "locked":false, "empty":true}, "case_empty_floor_01")
	_check_case_asset("visual_asset_id case_01 enters case visual state", {"visual_asset_id":"case_01", "locked":false, "loot_class":"class2", "case_loot_state":"unsearched"}, "case_class2_floor_01")

	if _failures.is_empty():
		print("Visual state asset service regression checks passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _check_door_asset(label: String, overrides: Dictionary, expected_asset_id: String) -> void:
	var object_data: Dictionary = {
		"visual_family": "door",
		"visual_surface": "floor",
		"visual_state_policy": "powered_three_state",
		"power_visual_state_enabled": true
	}
	object_data.merge(overrides, true)
	var actual_asset_id: String = VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if actual_asset_id != expected_asset_id:
		_failures.append("%s: expected %s, got %s" % [label, expected_asset_id, actual_asset_id])

func _check_case_asset(label: String, overrides: Dictionary, expected_asset_id: String) -> void:
	var object_data: Dictionary = overrides.duplicate(true)
	var actual_asset_id: String = VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if actual_asset_id != expected_asset_id:
		_failures.append("%s: expected %s, got %s" % [label, expected_asset_id, actual_asset_id])
