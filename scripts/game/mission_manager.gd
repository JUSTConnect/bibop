extends Node

const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystem = preload("res://scripts/world/scan_system.gd")
const InteractionSystem = preload("res://scripts/world/interaction_system.gd")
const PowerSystem = preload("res://scripts/world/power_system.gd")

var mission_world_objects: Array[Dictionary] = []
var world_objects_by_cell: Dictionary = {}
var cell_items: Dictionary = {}
var debug_world_logs := false
var enable_debug_seed := false

func _ready() -> void:
	if enable_debug_seed:
		_seed_debug_world_objects()

func setup_world_objects_for_mission(mission_id: String) -> void:
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()

	var objects: Array[Dictionary] = WorldObjectCatalog.create_test_set()
	var placements := {
		"door_a1": Vector2i(2, 1),
		"door_e1": Vector2i(6, 2),
		"terminal_t1": Vector2i(5, 2),
		"wall_b1": Vector2i(2, 2),
		"wall_d1": Vector2i(3, 2),
		"power_src_1": Vector2i(1, 5),
		"cable_a": Vector2i(2, 5),
		"breaker_1": Vector2i(3, 5),
		"fuse_box_1": Vector2i(4, 5),
		"fuse_box_empty_1": Vector2i(5, 5),
		"crate_n_1": Vector2i(4, 3),
		"crate_h_1": Vector2i(4, 4),
		"barrel_1": Vector2i(1, 4),
		"debris_1": Vector2i(6, 5)
	}
	for object_data in objects:
		var object_id := String(object_data.get("id", ""))
		if object_id == "wall_b1":
			object_data["hidden_content"] = ["power_cable"]
		if object_id == "wall_d1":
			object_data["hidden_content"] = ["secret_passage"]
		if _should_assign_main_power_network(object_data):
			object_data["power_network_id"] = "power_net_A"
		elif object_id == "fuse_box_empty_1":
			object_data["power_network_id"] = "power_net_broken_test"
		else:
			object_data.erase("power_network_id")
		if placements.has(object_id):
			set_world_object_at_cell(placements[object_id], object_data)
		elif object_data.get("object_group", "") == "item":
			add_item_at_cell(Vector2i(1, 3), object_data)

	if mission_id == "mission_1":
		PowerSystem.recalculate_network(mission_world_objects, "power_net_A")

func _should_assign_main_power_network(object_data: Dictionary) -> bool:
	var object_type := String(object_data.get("object_type", ""))
	var object_group := String(object_data.get("object_group", ""))
	if object_type in [
		"power_source_class_1",
		"power_cable",
		"circuit_breaker",
		"fuse_box_installed",
		"door_terminal",
		"energy_door",
		"energy_wall",
		"light"
	]:
		return true
	if object_group in ["terminal", "power"]:
		return object_type != "fuse_box_empty"
	return false

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

func get_world_object_at_cell(cell: Vector2i) -> Dictionary:
	return world_objects_by_cell.get(cell, {})

func set_world_object_at_cell(cell: Vector2i, object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	object_data["position"] = cell
	world_objects_by_cell[cell] = object_data
	if not mission_world_objects.has(object_data):
		mission_world_objects.append(object_data)

func remove_world_object_at_cell(cell: Vector2i) -> void:
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		mission_world_objects.erase(object_data)
	world_objects_by_cell.erase(cell)

func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]:
	return cell_items.get(cell, [])

func add_item_at_cell(cell: Vector2i, item_data: Dictionary) -> void:
	item_data["position"] = cell
	var items: Array[Dictionary] = cell_items.get(cell, [])
	items.append(item_data)
	cell_items[cell] = items
	if not mission_world_objects.has(item_data):
		mission_world_objects.append(item_data)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var items: Array[Dictionary] = cell_items.get(cell, [])
	if items.is_empty():
		return {}
	var item: Dictionary = items.pop_front()
	cell_items[cell] = items
	mission_world_objects.erase(item)
	return item

func get_hidden_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return []
	var hidden: Array[Dictionary] = []
	for hidden_id in object_data.get("hidden_content", []):
		hidden.append({"id": hidden_id, "display_name": String(hidden_id).capitalize()})
	return hidden
