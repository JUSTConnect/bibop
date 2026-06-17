extends SceneTree

const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")
const VisualAssetRenderContractServiceRef = preload("res://scripts/visual/visual_asset_render_contract_service.gd")

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


	_check_render_contract("air cooling base SW is floor authored", "res://assets/visual/isometric/objects/cooling/air_cooling_base_floor_SW.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("air cooling base NE is floor authored", "res://assets/visual/isometric/objects/cooling/air_cooling_base_floor_NE.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("air cooling off SW is floor authored", "res://assets/visual/isometric/objects/cooling/air_cooling_off_floor_SW.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("air cooling on NE is floor authored", "res://assets/visual/isometric/objects/cooling/air_cooling_on_floor_NE.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("air cooling pulsar overlay SW is floor authored", "res://assets/visual/isometric/objects/cooling/pulsar_overlay_air_cooling_on_floor_SW.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("case locked is floor authored", "res://assets/visual/isometric/objects/case/case_locked_floor.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("normal crate is floor authored", "res://assets/visual/isometric/moovable/normal_crate_floor.png", VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS)
	_check_render_contract("power socket on wall is wall authored", "res://assets/visual/isometric/objects/power_socket/power_socket_on_wall.png", VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS)

	_check_air_cooling_descriptor("air cooling SW uses SW source without mirror", "SW", "air_cooling_base_floor_sw_01", false)
	_check_air_cooling_descriptor("air cooling SE uses SW source with mirror", "SE", "air_cooling_base_floor_sw_01", true)
	_check_air_cooling_descriptor("air cooling NE uses NE source without mirror", "NE", "air_cooling_base_floor_ne_01", false)
	_check_air_cooling_descriptor("air cooling NW uses NE source with mirror", "NW", "air_cooling_base_floor_ne_01", true)

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

func _check_render_contract(label: String, texture_path: String, expected_contract: String) -> void:
	var actual_contract: String = VisualAssetRenderContractServiceRef.get_render_contract(texture_path)
	if actual_contract != expected_contract:
		_failures.append("%s: expected %s, got %s" % [label, expected_contract, actual_contract])

func _check_air_cooling_descriptor(label: String, airflow_direction: String, expected_asset_id: String, expected_mirror_x: bool) -> void:
	var object_data: Dictionary = {
		"visual_family": "air_cooling",
		"visual_surface": "floor",
		"visual_state_policy": "powered_three_state",
		"variant_policy": "airflow_direction",
		"power_visual_state_enabled": true,
		"state": "base",
		"airflow_direction": airflow_direction
	}
	var descriptor: Dictionary = VisualStateAssetServiceRef.resolve_visual_asset_descriptor(object_data)
	var actual_asset_id: String = str(descriptor.get("asset_id", ""))
	var actual_mirror_x: bool = bool(descriptor.get("mirror_x", false))
	if actual_asset_id != expected_asset_id or actual_mirror_x != expected_mirror_x:
		_failures.append("%s: expected %s mirror_x=%s, got %s mirror_x=%s" % [label, expected_asset_id, expected_mirror_x, actual_asset_id, actual_mirror_x])
