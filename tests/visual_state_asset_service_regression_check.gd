extends SceneTree

const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")

var _failures: Array[String] = []

func _init() -> void:
	_check_door_asset("closed no_power status uses base", {"status": "no_power"}, "door_close_base_floor_01")
	_check_door_asset("closed unpowered status uses base", {"status": "unpowered"}, "door_close_base_floor_01")
	_check_door_asset("closed false has_power uses base", {"has_power": false}, "door_close_base_floor_01")
	_check_door_asset("closed powered off status uses off", {"status": "off", "has_power": true}, "door_close_off_floor_01")
	_check_door_asset("open no_power status uses base", {"is_open": true, "status": "no_power"}, "door_open_base_floor_01")

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
