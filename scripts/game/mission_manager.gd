extends Node

const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystem = preload("res://scripts/world/scan_system.gd")
const InteractionSystem = preload("res://scripts/world/interaction_system.gd")
const PowerSystem = preload("res://scripts/world/power_system.gd")

var mission_world_objects: Array[Dictionary] = []
var debug_world_logs := false

func _ready() -> void:
	_seed_debug_world_objects()

func _seed_debug_world_objects() -> void:
	mission_world_objects = WorldObjectCatalog.create_test_set()
	for object_data in mission_world_objects:
		if object_data.get("id", "") in ["wall_b1", "wall_d1"]:
			object_data["scan_level"] = 3
	if mission_world_objects.size() > 0:
		mission_world_objects[0]["power_network_id"] = "power_net_A"
	for object_data in mission_world_objects:
		if object_data.get("object_group", "") in ["door", "terminal", "power"]:
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("object_type", "") == "energy_wall":
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("id", "") == "fuse_box_empty_1":
			object_data["power_network_id"] = ""
	PowerSystem.recalculate_network(mission_world_objects, "power_net_A")
	if debug_world_logs:
		_debug_world_summary()

func _debug_world_summary() -> void:
	for object_data in mission_world_objects:
		var scan_text := ScanSystem.get_scan_display_text(object_data, "visor")
		print("[WorldObject] %s (%s) state=%s" % [object_data.get("display_name", "Unknown"), object_data.get("object_type", ""), object_data.get("state", "")])
		print("[Scan] %s" % scan_text)

func debug_try_action(target_id: String, action_type: String, module_id: String = "") -> Dictionary:
	var target := _find_object(target_id)
	if target.is_empty():
		return {"success": false, "message": "Target not found.", "effects": []}
	var actor := {
		"cpu_level": 1,
		"interface_level": 1,
		"manipulator_level": 1,
		"wired_interface_level": 1,
		"optical_interface_level": 1,
		"wireless_interface_level": 1,
		"high_bandwidth_interface_level": 1,
		"firewall_module_v1": false,
		"manipulator_occupied": false,
		"pocket_full": false,
		"power_class": "scout",
		"magnetic_path_blocked": false,
		"target_is_grate": false
	}
	var module := {"id": module_id}
	var result := InteractionSystem.apply_action(actor, module, target, action_type)
	if debug_world_logs:
		print("[Interact] %s -> %s: %s" % [target_id, action_type, result.get("message", "")])
	return result

func _find_object(target_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if object_data.get("id", "") == target_id:
			return object_data
	return {}
