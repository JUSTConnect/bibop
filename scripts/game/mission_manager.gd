extends Node

const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystem = preload("res://scripts/world/scan_system.gd")
const InteractionSystem = preload("res://scripts/world/interaction_system.gd")
const PowerSystem = preload("res://scripts/world/power_system.gd")

var mission_world_objects: Array[Dictionary] = []
var world_objects_by_cell: Dictionary = {}
var cell_items: Dictionary = {}
var last_threat_warning_ids: Dictionary = {}
var last_world_runtime_restore_warnings: Array[String] = []
var debug_world_logs := false
var enable_debug_seed := false
var debug_world_cooling_scenario_enabled: bool = false
var debug_platform_scenario_enabled: bool = false
var active_bipob_ref: Node = null
var platform_last_tick_action_index: int = -1

func _ready() -> void:
	if enable_debug_seed:
		_seed_debug_world_objects()

func setup_world_objects_for_mission(mission_id: String) -> void:
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	if mission_id != "mission_1":
		return
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
		"debris_1": Vector2i(6, 5),
		"turret_1": Vector2i(7, 1)
	}
	objects.append(WorldObjectCatalog.create_world_object("turret", "turret_1"))
	for object_data in objects:
		var object_id := String(object_data.get("id", ""))
		if object_id == "terminal_t1":
			object_data["id"] = "door_terminal_1"
			object_data["controls"] = ["steel_door_1"]
		if object_id == "wall_b1":
			object_data["hidden_content"] = ["power_cable"]
		if object_id == "wall_d1":
			object_data["hidden_content"] = ["secret_passage"]
		if object_id == "door_e1":
			object_data["id"] = "steel_door_1"
			object_data["state"] = "locked"
		if _should_assign_main_power_network(object_data):
			object_data["power_network_id"] = "power_net_A"
		elif object_id == "fuse_box_empty_1":
			object_data["power_network_id"] = "power_net_broken_test"
		else:
			object_data.erase("power_network_id")
		if placements.has(object_id):
			set_world_object_at_cell(placements[object_id], object_data)
		elif object_data.get("object_group", "") == "item":
			match object_id:
				"keycard_a1":
					add_item_at_cell(Vector2i(1, 3), object_data)
				"digikey_a1":
					add_item_at_cell(Vector2i(5, 1), object_data)
				"fuse_item_1":
					add_item_at_cell(Vector2i(4, 1), object_data)
				"datafile_enc_1":
					add_item_at_cell(Vector2i(3, 4), object_data)
				_:
					add_item_at_cell(Vector2i(1, 3), object_data)
	PowerSystem.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	last_threat_warning_ids.clear()
	if debug_world_logs:
		var scenario_warnings := validate_world_object_scenario()
		if not scenario_warnings.is_empty():
			for warning in scenario_warnings:
				push_warning("[WorldScenario] %s" % warning)

func validate_world_object_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var ids := {}
	var occupied_cells := {}
	var turret_1: Dictionary = {}
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		if not object_id.is_empty():
			ids[object_id] = true
		if object_id == "turret_1":
			turret_1 = object_data
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		var pos := Vector2i(object_data.get("position", Vector2i(-1, -1)))
		if object_data.get("object_group", "") != "item":
			if occupied_cells.has(pos):
				warnings.append("Two world objects occupy %s." % str(pos))
			occupied_cells[pos] = object_id
		var controls: Array = object_data.get("controls", [])
		if object_data.has("controls") and controls.is_empty():
			warnings.append("Object %s has empty controls list." % object_id)
		for controlled_id in controls:
			if not ids.has(String(controlled_id)):
				warnings.append("Object %s controls missing id %s." % [object_id, String(controlled_id)])
		if object_data.has("power_network_id"):
			var network_id := String(object_data.get("power_network_id", ""))
			if network_id.is_empty():
				warnings.append("Object %s has empty power network id." % object_id)
	for required_id in ["steel_door_1", "door_terminal_1", "turret_1"]:
		if not ids.has(required_id):
			warnings.append("Required scenario id missing: %s." % required_id)
	if not turret_1.is_empty():
		if String(turret_1.get("object_group", "")) != "threat":
			warnings.append("turret_1 must use object_group threat.")
		if int(turret_1.get("detection_range", 0)) <= 0:
			warnings.append("turret_1 must have detection_range > 0.")
		var extraction_cell := Vector2i(7, 7)
		var turret_cell := Vector2i(turret_1.get("position", Vector2i(-1, -1)))
		if turret_cell == extraction_cell:
			warnings.append("turret_1 cannot be placed on extraction cell %s." % str(extraction_cell))
		var main_route := [
			Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(7, 2),
			Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7)
		]
		if main_route.has(turret_cell):
			warnings.append("turret_1 overlaps basic mission route at %s." % str(turret_cell))
	for cell in cell_items.keys():
		var seen := {}
		for item in cell_items[cell]:
			var item_id := String(item.get("id", ""))
			if seen.has(item_id):
				warnings.append("Duplicate item id %s at cell %s." % [item_id, str(cell)])
			seen[item_id] = true
	return warnings

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
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	if debug_world_logs:
		_debug_world_summary()

func _place_debug_world_object(object_type: String, object_id: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	if object_type.is_empty() or object_id.is_empty():
		return {}
	var existing := get_world_object_by_id(object_id)
	if not existing.is_empty():
		var existing_cell := Vector2i(existing.get("position", cell))
		world_objects_by_cell.erase(existing_cell)
		mission_world_objects.erase(existing)
	var object_data := WorldObjectCatalog.create_world_object(object_type, object_id)
	if object_data.is_empty():
		return {}
	object_data["id"] = object_id
	object_data["position"] = cell
	for key in overrides.keys():
		object_data[key] = overrides[key]
	var replaced := get_world_object_at_cell(cell)
	if not replaced.is_empty() and String(replaced.get("id", "")) == object_id:
		mission_world_objects.erase(replaced)
	world_objects_by_cell[cell] = object_data
	if not mission_world_objects.has(object_data):
		mission_world_objects.append(object_data)
	return object_data

func seed_world_cooling_debug_scenario(origin: Vector2i = Vector2i(8, 8)) -> void:
	_place_debug_world_object("information_terminal", "terminal_c2_radiator", origin + Vector2i(0, 0), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_a", origin + Vector2i(1, 0))
	_place_debug_world_object("information_terminal", "terminal_c2_radiator_metal", origin + Vector2i(0, 2), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_b", origin + Vector2i(1, 2))
	_place_debug_world_object("metal_cooling_block", "cooling_metal_block_b", origin + Vector2i(2, 2))
	_place_debug_world_object("information_terminal", "terminal_c2_air", origin + Vector2i(0, 4), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_direct_c", origin + Vector2i(-1, 4), {"facing_dir": "right"})
	_place_debug_world_object("information_terminal", "terminal_c2_water", origin + Vector2i(0, 6), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_water_pipe", "cooling_water_d", origin + Vector2i(1, 6))
	_place_debug_world_object("information_terminal", "terminal_c2_duct", origin + Vector2i(3, 8), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_duct_e", origin + Vector2i(0, 8), {"facing_dir": "right"})
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e1", origin + Vector2i(1, 8))
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e2", origin + Vector2i(2, 8))
	_place_debug_world_object("information_terminal", "terminal_c2_air_water", origin + Vector2i(0, 10), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_combo_f", origin + Vector2i(-1, 10), {"facing_dir": "right"})
	_place_debug_world_object("external_water_pipe", "cooling_water_combo_f", origin + Vector2i(0, 11))
	_place_debug_world_object("power_source_class_3", "power_source_c3_cooled", origin + Vector2i(0, 12), {"working_heat": 3, "current_heat": 3, "overheat_threshold": 3, "state": "active"})
	_place_debug_world_object("external_water_pipe", "cooling_water_g", origin + Vector2i(1, 12))
	refresh_world_cooling_received()
	PowerSystem.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func validate_world_cooling_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	# Manual validation checklist:
	# 1) Class 2 terminal without cooling should fail hack due to temporary overheat.
	# 2) Class 2 terminal with cooling 1+ should be safe from terminal temporary overheat.
	# 3) CPU internal overheat is separate and may still fail hack first.
	var expected := {
		"terminal_c2_radiator": 1,
		"terminal_c2_radiator_metal": 2,
		"terminal_c2_air": 2,
		"terminal_c2_water": 2,
		"terminal_c2_duct": 2,
		"terminal_c2_air_water": 4
	}
	for object_id in expected.keys():
		var object_data := get_world_object_by_id(String(object_id))
		if object_data.is_empty():
			warnings.append("Missing debug object: %s." % String(object_id))
			continue
		var received := int(object_data.get("cooling_received", -1))
		var target := int(expected[object_id])
		if received != target:
			warnings.append("%s cooling_received expected %d, got %d." % [String(object_id), target, received])
	var power_source := get_world_object_by_id("power_source_c3_cooled")
	if power_source.is_empty():
		warnings.append("Missing debug object: power_source_c3_cooled.")
	else:
		if String(power_source.get("state", "")) != "active":
			warnings.append("power_source_c3_cooled state expected active, got %s." % String(power_source.get("state", "")))
		var current_heat := int(power_source.get("current_heat", 999))
		var threshold := int(power_source.get("overheat_threshold", 0))
		if current_heat >= threshold:
			warnings.append("power_source_c3_cooled current_heat must be below threshold (%d >= %d)." % [current_heat, threshold])
	return warnings

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
	refresh_world_cooling_received()

func remove_world_object_at_cell(cell: Vector2i) -> void:
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		mission_world_objects.erase(object_data)
	world_objects_by_cell.erase(cell)
	refresh_world_cooling_received()

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

func get_world_object_by_id(id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == id:
			return object_data
	return {}

func update_world_object_by_id(id: String, data: Dictionary) -> void:
	if id.is_empty() or data.is_empty():
		return
	for index in range(mission_world_objects.size()):
		var object_data: Dictionary = mission_world_objects[index]
		if String(object_data.get("id", "")) != id:
			continue
		var old_position := Vector2i(object_data.get("position", Vector2i(-1, -1)))
		for key in data.keys():
			object_data[key] = data[key]
		mission_world_objects[index] = object_data
		var new_position := Vector2i(object_data.get("position", old_position))
		if old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = object_data
		refresh_world_cooling_received()
		return


func move_world_object_by_heavy_claw(object_id: String, target_cell: Vector2i) -> Dictionary:
	var result := {"success": false, "message": "Cannot move object there.", "object_id": object_id, "from": Vector2i(-1, -1), "to": target_cell}
	if object_id.strip_edges().is_empty():
		result["message"] = "Object not found."
		return result
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		result["message"] = "Object not found."
		return result
	var from_cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	result["from"] = from_cell
	if not WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(object_data):
		result["message"] = "Object cannot be moved by Heavy Claw."
		return result
	if from_cell == target_cell:
		result["message"] = "Object already there."
		return result
	if target_cell.x < 0 or target_cell.y < 0:
		result["message"] = "Target cell is blocked."
		return result
	if grid_manager != null:
		if grid_manager.has_method("is_in_bounds") and not bool(grid_manager.is_in_bounds(target_cell)):
			result["message"] = "Target cell is blocked."
			return result
		if grid_manager.has_method("is_walkable") and not bool(grid_manager.is_walkable(target_cell)):
			result["message"] = "Target cell is blocked."
			return result
		if grid_manager.has_method("get_tile"):
			var tile := int(grid_manager.get_tile(target_cell))
			if tile == grid_manager.TILE_WALL:
				result["message"] = "Target cell is blocked."
				return result
	if from_cell.x < 0 or from_cell.y < 0:
		result["message"] = "Object not found."
		return result
	var target_object := get_world_object_at_cell(target_cell)
	if not target_object.is_empty():
		result["message"] = "Target cell is occupied."
		return result
	if cell_items.has(target_cell) and not Array(cell_items.get(target_cell, [])).is_empty():
		result["message"] = "Target cell contains items."
		return result
	world_objects_by_cell.erase(from_cell)
	object_data["position"] = target_cell
	world_objects_by_cell[target_cell] = object_data
	refresh_world_cooling_received()
	PowerSystem.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	result["success"] = true
	result["message"] = "Moved %s." % String(object_data.get("display_name", "Object"))
	return result

func refresh_world_cooling_received() -> void:
	for object_data in mission_world_objects:
		if not WorldObjectCatalog.can_world_object_receive_cooling(object_data):
			continue
		var target_position := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var cooling_received := WorldObjectCatalog.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		object_data["cooling_received"] = cooling_received
		WorldObjectCatalog.update_world_object_heat_state(object_data)

func get_hidden_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return []
	var hidden: Array[Dictionary] = []
	for hidden_id in object_data.get("hidden_content", []):
		hidden.append({"id": hidden_id, "display_name": String(hidden_id).capitalize()})
	return hidden

func get_threats() -> Array[Dictionary]:
	var threats: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "threat":
			threats.append(object_data)
	return threats

func is_threat_active(threat: Dictionary) -> bool:
	if threat.is_empty():
		return false
	if String(threat.get("object_group", "")) != "threat":
		return false
	var state := String(threat.get("state", "active"))
	if state in ["destroyed", "disabled", "hacked", "stunned", "unpowered"]:
		return false
	if String(threat.get("behavior_state", "")) == "disabled":
		return false
	if String(threat.get("power_mode", "")) == "external_power" and not bool(threat.get("is_powered", true)):
		return false
	return true

func can_threat_detect_bipop(threat: Dictionary, bipob_cell: Vector2i, grid_manager: Node) -> bool:
	return bool(get_threat_detection_result(threat, bipob_cell, grid_manager).get("detected", false))

func get_threat_detection_result(threat: Dictionary, bipob_cell: Vector2i, grid_manager: Node) -> Dictionary:
	var result := {"detected":false, "threat_id":String(threat.get("id", "")), "threat_name":String(threat.get("display_name", "Threat")), "detection_mode":"", "distance":999, "message":"Threat cannot detect Bipop."}
	if threat.is_empty() or not is_threat_active(threat):
		result["message"] = "Threat inactive."
		return result
	var threat_position := Vector2i(threat.get("position", Vector2i(-1, -1)))
	var distance := abs(threat_position.x - bipob_cell.x) + abs(threat_position.y - bipob_cell.y)
	result["distance"] = distance
	var max_range := int(threat.get("detection_range", 0))
	if distance > max_range:
		result["message"] = "%s is out of detection range." % result["threat_name"]
		return result
	for mode_variant in Array(threat.get("detection_modes", [])):
		var mode := String(mode_variant)
		var mode_range := int(threat.get("%s_range" % mode, max_range))
		if mode_range <= 0 or distance > mode_range:
			continue
		if _can_detect_by_mode(mode, threat_position, bipob_cell, grid_manager):
			result["detected"] = true
			result["detection_mode"] = mode
			result["message"] = "%s detected Bipop by %s." % [result["threat_name"], mode]
			return result
	result["message"] = "%s has no clear detection path." % result["threat_name"]
	return result

func _can_detect_by_mode(mode: String, from_cell: Vector2i, to_cell: Vector2i, grid_manager: Node) -> bool:
	if grid_manager == null:
		return false
	return _has_cardinal_clear_path(from_cell, to_cell, grid_manager, mode, mode != "vision")

func _has_cardinal_clear_path(from_cell: Vector2i, to_cell: Vector2i, grid_manager: Node, scan_type: String, allow_wall_pass: bool) -> bool:
	var threat := get_world_object_at_cell(from_cell)
	var detection_shape := String(threat.get("detection_shape", "cardinal"))
	if detection_shape == "cardinal" and from_cell.x != to_cell.x and from_cell.y != to_cell.y:
		return false
	if detection_shape == "radius":
		if from_cell.x != to_cell.x and from_cell.y != to_cell.y:
			return true
	var step := Vector2i(signi(to_cell.x - from_cell.x), signi(to_cell.y - from_cell.y))
	var current := from_cell + step
	while current != to_cell:
		if not grid_manager.is_in_bounds(current):
			return false
		var tile := int(grid_manager.get_tile(current))
		if tile == grid_manager.TILE_WALL:
			return false
		var blocker := get_world_object_at_cell(current)
		if blocker.is_empty():
			current += step
			continue
		if bool(blocker.get("blocks_vision", false)):
			if not allow_wall_pass:
				return false
			if not ScanSystem.can_scan_through_wall(blocker, scan_type):
				return false
		current += step
	return true


func reset_world_object_turn_flags() -> void:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "threat":
			continue
		object_data["drained_this_turn"] = false
		var stunned_turns := int(object_data.get("stunned_turns", 0))
		if stunned_turns > 0:
			stunned_turns -= 1
			object_data["stunned_turns"] = stunned_turns
			if stunned_turns <= 0 and String(object_data.get("state", "")) == "stunned":
				var previous_state := String(object_data.get("state_before_stun", ""))
				var previous_behavior := String(object_data.get("behavior_before_stun", ""))
				if previous_state.is_empty() or previous_state in ["destroyed", "hacked", "disabled", "unpowered", "stunned"]:
					object_data["state"] = "active"
				else:
					object_data["state"] = previous_state
				if previous_behavior.is_empty():
					object_data["behavior_state"] = "idle"
				else:
					object_data["behavior_state"] = previous_behavior
				object_data.erase("state_before_stun")
				object_data.erase("behavior_before_stun")

func get_world_object_debug_summary() -> String:
	var world_count := mission_world_objects.size()
	var items_count := 0
	var threats_count := 0
	var powered_count := 0
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "item":
			items_count += 1
		if String(object_data.get("object_group", "")) == "threat":
			threats_count += 1
		if bool(object_data.get("is_powered", false)):
			powered_count += 1
	var warning_count := last_threat_warning_ids.size()
	return "WorldObjects: %d | Items: %d | Threats: %d | Powered: %d | Warnings: %d" % [world_count, items_count, threats_count, powered_count, warning_count]

func _is_power_network_object(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var object_group := String(object_data.get("object_group", "")).strip_edges().to_lower()
	if object_group == "power":
		return true
	var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
	if object_type in [
		"power_source",
		"power_cable",
		"power_socket",
		"cable_reel",
		"circuit_breaker",
		"circuit_switch",
		"fuse_box",
		"light",
		"light_switch",
		"energy_door"
	]:
		return true
	return object_data.has("power_network_id") or object_data.has("network_id") or object_data.has("connected_power_source_id")

func _get_power_network_id(object_data: Dictionary) -> String:
	for key in ["power_network_id", "network_id", "connected_power_source_id"]:
		var value := String(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

func _is_power_source_object(object_data: Dictionary) -> bool:
	var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
	var power_role := String(object_data.get("power_role", "")).strip_edges().to_lower()
	return object_type == "power_source" or power_role == "source" or object_type in ["power_source_class_1", "power_source_class_2", "power_source_class_3"]

func _get_power_network_summary_lines(filter: String = "") -> Array[String]:
	var grouped := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not grouped.has(network_id):
			grouped[network_id] = []
		grouped[network_id].append(object_data)
	var ids: Array[String] = []
	for key in grouped.keys():
		ids.append(String(key))
	ids.sort()
	var filter_text := filter.strip_edges().to_lower()
	var lines: Array[String] = []
	for network_id in ids:
		var objects: Array = grouped.get(network_id, [])
		var object_count := 0
		var source_count := 0
		var cable_count := 0
		var socket_count := 0
		var network_powered := false
		var overheated_sources := 0
		var damaged_count := 0
		var connection_count := 0
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			object_count += 1
			var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var is_source := _is_power_source_object(object_data)
			if is_source:
				source_count += 1
			if object_type.find("cable") != -1 or object_type == "power_cable":
				cable_count += 1
			if object_type.find("socket") != -1 or object_type == "power_socket":
				socket_count += 1
			if bool(object_data.get("is_powered", false)) or state in ["active", "switch_on", "connected"]:
				network_powered = true
			var threshold := int(object_data.get("overheat_threshold", 0))
			var current_heat := int(object_data.get("current_heat", 0))
			if is_source and (state == "overheated" or (threshold > 0 and current_heat >= threshold)):
				overheated_sources += 1
			if state == "damaged" or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
				damaged_count += 1
			if state == "connected" or bool(object_data.get("connected", false)):
				connection_count += 1
		var network_text := network_id if not network_id.is_empty() else "-"
		var line := "network=%s | objects=%d | sources=%d | cables=%d | sockets=%d | powered=%s | overheated_sources=%d | damaged=%d | connections=%d" % [
			network_text, object_count, source_count, cable_count, socket_count, str(network_powered).to_lower(), overheated_sources, damaged_count, connection_count
		]
		if not filter_text.is_empty() and line.to_lower().find(filter_text) == -1:
			continue
		lines.append(line)
	return lines

func get_power_network_debug_summary_text(filter: String = "") -> String:
	var lines := _get_power_network_summary_lines(filter)
	if lines.is_empty():
		return "PowerNetworkSummary:\nnone" if filter.strip_edges().is_empty() else "PowerNetworkSummary:\nnone (filter=%s)" % filter.strip_edges().to_lower()
	return "PowerNetworkSummary:\n%s" % "\n".join(lines)

func validate_power_network_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var power_objects: Array[Dictionary] = []
	var networks := {}
	var source_ids := {}
	var network_has_powered_source := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		power_objects.append(object_data)
		var object_id := String(object_data.get("id", "")).strip_edges()
		var network_id := _get_power_network_id(object_data)
		if network_id.is_empty():
			warnings.append("Power object %s has no network id." % object_id)
		if not networks.has(network_id):
			networks[network_id] = []
		networks[network_id].append(object_data)
		if _is_power_source_object(object_data):
			if not object_id.is_empty():
				source_ids[object_id] = true
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var powered_source := bool(object_data.get("is_powered", false)) and state != "overheated"
			if powered_source:
				network_has_powered_source[network_id] = true
	for object_data in power_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		var current_heat := int(object_data.get("current_heat", 0))
		var threshold := int(object_data.get("overheat_threshold", 0))
		if current_heat < 0:
			errors.append("Power object %s has negative current_heat (%d)." % [object_id, current_heat])
		if threshold < 0:
			errors.append("Power object %s has negative overheat_threshold (%d)." % [object_id, threshold])
		var state_text := String(object_data.get("state", "")).strip_edges().to_lower()
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if _is_power_source_object(object_data):
			if threshold > 0 and current_heat >= threshold and state_text != "overheated":
				warnings.append("Power source %s current_heat >= overheat_threshold but state is not overheated." % object_id)
			if threshold > 0 and state_text == "overheated" and current_heat < threshold and not damaged_or_broken:
				warnings.append("Power source %s state is overheated but current_heat < overheat_threshold and object is not damaged/broken." % object_id)
		var linked_source_id := String(object_data.get("connected_power_source_id", "")).strip_edges()
		if not linked_source_id.is_empty() and not source_ids.has(linked_source_id):
			warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, linked_source_id])
	for network_id in networks.keys():
		var objects: Array = networks[network_id]
		var has_source := false
		var has_cable_or_socket := false
		var has_powered_source := bool(network_has_powered_source.get(network_id, false))
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := String(object_data.get("state", "")).strip_edges().to_lower()
			var connected := state == "connected" or bool(object_data.get("connected", false))
			var is_source := _is_power_source_object(object_data)
			if is_source:
				has_source = true
				if object_data.has("allowed_connections"):
					var allowed := int(object_data.get("allowed_connections", -1))
					if allowed >= 0:
						var source_connections := 0
						for object_variant_2 in objects:
							if typeof(object_variant_2) != TYPE_DICTIONARY:
								continue
							var connected_object: Dictionary = object_variant_2
							var connected_source_id := String(connected_object.get("connected_power_source_id", "")).strip_edges()
							if connected_source_id == object_id:
								source_connections += 1
						if source_connections > allowed:
							warnings.append("Power source %s connections (%d) exceed allowed_connections (%d)." % [object_id, source_connections, allowed])
			if object_type.find("cable") != -1 or object_type.find("socket") != -1:
				has_cable_or_socket = true
			if connected and not has_powered_source:
				warnings.append("Connected power object %s is in network %s but no source is powered." % [object_id, String(network_id if not String(network_id).is_empty() else "-")])
			if bool(object_data.get("is_powered", false)) and not has_powered_source:
				warnings.append("Power object %s is_powered=true but network %s has no powered source." % [object_id, String(network_id if not String(network_id).is_empty() else "-")])
		if has_cable_or_socket and not has_source:
			warnings.append("Network %s has cables/sockets but no source." % String(network_id if not String(network_id).is_empty() else "-"))
	return {"valid": errors.is_empty(), "networks": networks.size(), "objects": power_objects.size(), "warnings": warnings, "errors": errors}

func get_power_network_validation_text() -> String:
	var validation := validate_power_network_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkValidation: valid=%s networks=%d objects=%d warnings=%d errors=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("networks", 0)),
		int(validation.get("objects", 0)),
		warnings.size(),
		errors.size()
	])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	for err in errors:
		lines.append("ERROR: %s" % err)
	return "\n".join(lines)

func get_world_object_debug_info(object_id: String) -> Dictionary:
	var normalized_id := object_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	var object_data := get_world_object_by_id(normalized_id)
	if object_data.is_empty():
		return {}
	var info := {}
	for key in ["id", "object_type", "display_name", "object_group", "state"]:
		if object_data.has(key):
			info[key] = object_data[key]
	info["position"] = _debug_cell_to_array(WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
	for key in [
		"is_powered",
		"current_heat",
		"working_heat",
		"cooling_received",
		"heat_from_connections",
		"overheat_threshold",
		"connected_device_ids",
		"power_network_id",
		"facing_dir",
		"movable",
		"heavy_claw_movable",
		"cooling_device_type",
		"cooling_output",
		"cooling_amplifier",
		"material",
		"storage_type",
		"storage_capacity",
		"storage_locked",
		"lock_type",
		"lock_difficulty",
		"access_level",
		"required_access_level"
	]:
		if object_data.has(key):
			info[key] = object_data[key]
	for key in ["platform_height_level", "carried_by_platform_id"]:
		if object_data.has(key):
			info[key] = object_data[key]
	if _is_power_network_object(object_data):
		info["power_network_id"] = _get_power_network_id(object_data)
		info["current_heat"] = int(object_data.get("current_heat", 0))
		info["overheat_threshold"] = int(object_data.get("overheat_threshold", 0))
		info["is_powered"] = bool(object_data.get("is_powered", false))
		info["connected_power_source_id"] = String(object_data.get("connected_power_source_id", "")).strip_edges()
		var network_summary_lines := _get_power_network_summary_lines(_get_power_network_id(object_data))
		if not network_summary_lines.is_empty():
			info["power_network_summary_line"] = network_summary_lines[0]
	if String(object_data.get("object_group", "")) == "platform":
		info["platform_state_summary"] = get_platform_state_summary(object_data)
		info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	return info

func _get_debug_tile_info(cell: Vector2i) -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_tile"):
		return null
	var tile_variant: Variant = grid_manager.get_tile(cell)
	match typeof(tile_variant):
		TYPE_NIL:
			return null
		TYPE_INT:
			return int(tile_variant)
		TYPE_FLOAT:
			return float(tile_variant)
		TYPE_STRING:
			return String(tile_variant)
		TYPE_DICTIONARY:
			return Dictionary(tile_variant).duplicate(true)
		TYPE_ARRAY:
			var tile_array := Array(tile_variant)
			return tile_array.duplicate(true) if tile_array.size() <= 16 else str(tile_array)
		_:
			return str(tile_variant)

func _get_wall_tile_id() -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_property_list"):
		return null
	for property_data in grid_manager.get_property_list():
		if typeof(property_data) != TYPE_DICTIONARY:
			continue
		if String(property_data.get("name", "")) == "TILE_WALL":
			return grid_manager.get("TILE_WALL")
	return null

func get_world_cell_debug_info(cell: Vector2i) -> Dictionary:
	var info := {"cell": _debug_cell_to_array(cell)}
	info["height_level"] = get_cell_height_level(cell)
	if grid_manager != null:
		if grid_manager.has_method("is_in_bounds"):
			info["in_bounds"] = bool(grid_manager.is_in_bounds(cell))
		if grid_manager.has_method("is_walkable"):
			info["walkable"] = bool(grid_manager.is_walkable(cell))
		var tile_info := _get_debug_tile_info(cell)
		if tile_info != null:
			info["tile"] = tile_info
			if typeof(tile_info) == TYPE_DICTIONARY:
				var tile_data := Dictionary(tile_info)
				if String(tile_data.get("type", "")) == "wall":
					info["is_wall"] = true
			elif typeof(tile_info) == TYPE_INT:
				var wall_tile_id := _get_wall_tile_id()
				if wall_tile_id != null and typeof(wall_tile_id) == TYPE_INT:
					info["is_wall"] = int(tile_info) == int(wall_tile_id)
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		info["world_object_id"] = String(object_data.get("id", ""))
		info["world_object_type"] = String(object_data.get("object_type", ""))
		if _is_power_network_object(object_data):
			var power_network_id := _get_power_network_id(object_data)
			info["power_network_id"] = power_network_id
			var network_summary_lines := _get_power_network_summary_lines(power_network_id)
			if not network_summary_lines.is_empty():
				info["power_network_debug_summary_line"] = network_summary_lines[0]
		if String(object_data.get("object_group", "")) == "platform":
			info["platform_id"] = String(object_data.get("platform_id", ""))
			info["platform_state_summary"] = get_platform_state_summary(object_data)
			info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	var items: Array = cell_items.get(cell, [])
	info["item_count"] = items.size()
	if not items.is_empty():
		var item_ids: Array[String] = []
		var item_types: Array[String] = []
		for item_variant in items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data := Dictionary(item_variant)
			item_ids.append(String(item_data.get("id", "")))
			item_types.append(String(item_data.get("object_type", "")))
		info["item_ids"] = item_ids
		info["item_types"] = item_types
	return info

func get_world_objects_debug_table_text(filter: String = "") -> String:
	if mission_world_objects.is_empty():
		return "world_objects: none"
	var filter_text := filter.strip_edges().to_lower()
	var object_rows: Array[String] = []
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		var object_type := String(object_data.get("object_type", ""))
		var object_group := String(object_data.get("object_group", ""))
		var state := String(object_data.get("state", ""))
		if not filter_text.is_empty():
			var match_blob := ("%s|%s|%s|%s" % [object_id, object_type, object_group, state]).to_lower()
			if match_blob.find(filter_text) == -1:
				continue
		object_rows.append(_format_world_object_debug_row(object_data))
	if object_rows.is_empty():
		return "world_objects: none (filter=%s)" % filter_text
	object_rows.sort()
	var lines: Array[String] = []
	lines.append("id | type | pos | state | heat | cooling | powered | facing | movable")
	lines.append_array(object_rows)
	if has_method("get_world_runtime_restore_warnings"):
		var warnings: Array = get_world_runtime_restore_warnings()
		lines.append("restore_warnings=%d" % warnings.size())
	return "\n".join(lines)

func _format_world_object_debug_row(object_data: Dictionary) -> String:
	var object_id := String(object_data.get("id", ""))
	var object_type := String(object_data.get("object_type", ""))
	var state := String(object_data.get("state", ""))
	var cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var position_text := "[%d,%d]" % [cell.x, cell.y]
	var heat_text := "-"
	if object_data.has("current_heat") or object_data.has("overheat_threshold"):
		heat_text = "%d/%d" % [int(object_data.get("current_heat", 0)), int(object_data.get("overheat_threshold", 0))]
	var cooling_text := "-"
	if object_data.has("cooling_received"):
		cooling_text = str(int(object_data.get("cooling_received", 0)))
	var powered_text := "-"
	if object_data.has("is_powered"):
		powered_text = str(bool(object_data.get("is_powered", false)))
	var facing_text := "-"
	if object_data.has("facing_dir"):
		facing_text = String(object_data.get("facing_dir", "")).strip_edges()
		if facing_text.is_empty():
			facing_text = "-"
	var movable_text := str(WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(object_data))
	if object_data.has("heavy_claw_movable"):
		movable_text = str(bool(object_data.get("heavy_claw_movable", false)))
	elif object_data.has("movable"):
		movable_text = str(bool(object_data.get("movable", false)))
	return "%s | %s | %s | %s | heat=%s | cool=%s | powered=%s | facing=%s | movable=%s" % [
		object_id,
		object_type,
		position_text,
		state,
		heat_text,
		cooling_text,
		powered_text,
		facing_text,
		movable_text
	]

func _debug_cell_to_array(cell: Vector2i) -> Array[int]:
	return [cell.x, cell.y]

func get_world_heat_debug_summary_text() -> String:
	var terminals_count := 0
	var overheated_terminals := 0
	var power_sources_count := 0
	var overheated_power_sources := 0
	var invalid_heat_metadata := 0
	var missing_threshold := 0
	var cooling_devices_count := 0
	var cooled_heat_targets := 0
	var max_cooling_received := 0
	var invalid_cooling_metadata := 0
	var has_cooling_debug_scenario := not get_world_object_by_id("terminal_c2_radiator").is_empty()
	for object_data in mission_world_objects:
		var group := String(object_data.get("object_group", ""))
		var object_type := String(object_data.get("object_type", ""))
		var is_power_source := object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]
		if group == "cooling":
			cooling_devices_count += 1
		var heat_enabled := object_data.has("working_heat") or object_data.has("overheat_threshold")
		if group == "terminal":
			terminals_count += 1
			if String(object_data.get("state", "")) == "overheated":
				overheated_terminals += 1
		elif is_power_source:
			power_sources_count += 1
			if String(object_data.get("state", "")) == "overheated":
				overheated_power_sources += 1
		if heat_enabled:
			var cooling_value := maxi(0, int(object_data.get("cooling_received", 0)))
			if cooling_value > 0:
				cooled_heat_targets += 1
			max_cooling_received = maxi(max_cooling_received, cooling_value)
			if not object_data.has("overheat_threshold"):
				missing_threshold += 1
			var threshold := int(object_data.get("overheat_threshold", 0))
			if threshold < 0 or int(object_data.get("working_heat", 0)) < 0:
				invalid_heat_metadata += 1
		var object_cooling_type := String(object_data.get("cooling_device_type", ""))
		if group == "cooling":
			if object_cooling_type.is_empty():
				invalid_cooling_metadata += 1
			elif not object_cooling_type in ["radiator", "air_cooler", "water_pipe", "air_duct"]:
				invalid_cooling_metadata += 1
		if object_cooling_type == "air_cooler" and not object_data.has("facing_dir"):
			invalid_cooling_metadata += 1
	var summary := "WorldHeat: terminals=%d overheated=%d | power_sources=%d overheated=%d | invalid_heat=%d | missing_threshold=%d | cooling_devices=%d | cooled_targets=%d | max_cooling=%d | invalid_cooling=%d" % [
		terminals_count,
		overheated_terminals,
		power_sources_count,
		overheated_power_sources,
		invalid_heat_metadata,
		missing_threshold,
		cooling_devices_count,
		cooled_heat_targets,
		max_cooling_received,
		invalid_cooling_metadata
	]
	if has_cooling_debug_scenario:
		var validation_warnings := validate_world_cooling_debug_scenario()
		if debug_world_logs and not validation_warnings.is_empty():
			for warning in validation_warnings:
				push_warning("[WorldCoolingValidation] %s" % warning)
		summary += " | cooling_validation_issues=%d" % validation_warnings.size()
	return summary

func get_world_object_runtime_state() -> Dictionary:
	# Runtime-only snapshot helper for future save manager integration.
	var runtime_state := {}
	var runtime_fields := [
		"state",
		"is_powered",
		"current_heat",
		"cooling_received",
		"heat_from_connections",
		"connected_device_ids",
		"overheated_state_before",
		"overheated_powered_before",
		"facing_dir",
		"power_network_id",
		"drain_pool",
		"platform_id",
		"platform_type",
		"platform_cells",
		"local_switch_cell",
		"local_switch_facing_dir",
		"linked_terminal_id",
		"requires_terminal_enabled",
		"control_type",
		"power_type",
		"height_level",
		"min_height_level",
		"max_height_level",
		"activation_mode",
		"timer_turns",
		"timer_remaining_turns",
		"period_turns",
		"periodic_active",
		"permanent_state",
		"pending_activation",
		"rotation_direction",
		"platform_height_level",
		"carried_by_platform_id",
		"target_platform_id",
		"platform_control_enabled",
		"platform_remote_control"
	]
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var serialized := {}
		if object_data.has("object_type"):
			serialized["object_type"] = String(object_data.get("object_type", ""))
		if object_data.has("position"):
			var world_cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			serialized["position"] = [world_cell.x, world_cell.y]
		for field_name in runtime_fields:
			if object_data.has(field_name):
				serialized[field_name] = object_data[field_name]
		if not serialized.is_empty():
			runtime_state[object_id] = serialized
	return runtime_state

func _add_world_runtime_restore_warning(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	last_world_runtime_restore_warnings.append(message)

func _extract_saved_world_runtime_position(saved_data: Dictionary, object_id: String, fallback_position: Vector2i) -> Dictionary:
	if not saved_data.has("position"):
		return {"ok": true, "position": fallback_position}
	var position_variant: Variant = saved_data.get("position")
	var parsed_position := WorldObjectCatalog.to_world_cell(position_variant, Vector2i(-1, -1))
	if parsed_position.x < 0 and parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: invalid position data." % object_id)
		return {"ok": false}
	if parsed_position.x < 0 or parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: position has negative coordinate %s." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_in_bounds") and not bool(grid_manager.call("is_in_bounds", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is out of bounds." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_walkable") and not bool(grid_manager.call("is_walkable", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is not walkable." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("get_tile"):
		var tile_variant: Variant = grid_manager.call("get_tile", parsed_position)
		if typeof(tile_variant) == TYPE_DICTIONARY:
			var tile_data: Dictionary = tile_variant
			if String(tile_data.get("type", "")) == "wall":
				_add_world_runtime_restore_warning("Restore skipped for %s: position %s is a wall tile." % [object_id, str(parsed_position)])
				return {"ok": false}
	return {"ok": true, "position": parsed_position}

func apply_world_object_runtime_state(saved_state: Dictionary) -> void:
	last_world_runtime_restore_warnings.clear()
	if saved_state.is_empty():
		return
	for object_id_variant in saved_state.keys():
		var object_id := String(object_id_variant).strip_edges()
		if object_id.is_empty():
			continue
		var saved_data_variant: Variant = saved_state.get(object_id_variant, {})
		if typeof(saved_data_variant) != TYPE_DICTIONARY:
			_add_world_runtime_restore_warning("Restore skipped for %s: runtime entry is not a dictionary." % object_id)
			continue
		var saved_data: Dictionary = saved_data_variant
		var existing_object := get_world_object_by_id(object_id)
		var is_new_object := existing_object.is_empty()
		var candidate_object := existing_object
		if is_new_object:
			var object_type := String(saved_data.get("object_type", "")).strip_edges()
			if object_type.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: missing object_type for unknown object id." % object_id)
				continue
			var created := WorldObjectCatalog.create_world_object(object_type, object_id)
			if created.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: failed to create object_type %s." % [object_id, object_type])
				continue
			created["id"] = object_id
			candidate_object = created
		var old_position := WorldObjectCatalog.to_world_cell(candidate_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var parsed_position_info := _extract_saved_world_runtime_position(saved_data, object_id, old_position)
		if not bool(parsed_position_info.get("ok", false)):
			continue
		var new_position := Vector2i(parsed_position_info.get("position", old_position))
		var replaced := get_world_object_at_cell(new_position)
		if not replaced.is_empty() and String(replaced.get("id", "")) != object_id:
			_add_world_runtime_restore_warning("Restore skipped for %s: target cell occupied by %s." % [object_id, String(replaced.get("id", ""))])
			continue
		var runtime_updates: Dictionary = {}
		for key_variant in saved_data.keys():
			var key := String(key_variant)
			if String(key) == "position":
				continue
			runtime_updates[key] = saved_data[key_variant]
		for key in runtime_updates.keys():
			candidate_object[key] = runtime_updates[key]
		candidate_object["id"] = object_id
		candidate_object["position"] = new_position
		if not is_new_object and old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = candidate_object
		if is_new_object and not mission_world_objects.has(candidate_object):
			mission_world_objects.append(candidate_object)
	refresh_world_cooling_received()
	PowerSystem.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func get_world_runtime_persistence_debug_summary_text() -> String:
	var serialized := get_world_object_runtime_state()
	var moved_objects := 0
	var heat_enabled_objects := 0
	var powered_objects := 0
	var connection_state_objects := 0
	for object_data in mission_world_objects:
		var current_position := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if object_data.has("original_position"):
			var original_position := WorldObjectCatalog.to_world_cell(object_data.get("original_position", current_position), current_position)
			if original_position != current_position:
				moved_objects += 1
		if object_data.has("working_heat") or object_data.has("overheat_threshold") or object_data.has("current_heat"):
			heat_enabled_objects += 1
		if bool(object_data.get("is_powered", false)):
			powered_objects += 1
		if object_data.has("connected_device_ids") or object_data.has("heat_from_connections"):
			connection_state_objects += 1
	return "WorldRuntimePersistence: serialized=%d | moved=%d | heat_enabled=%d | powered=%d | connection_state=%d | restore_warnings=%d" % [
		serialized.size(),
		moved_objects,
		heat_enabled_objects,
		powered_objects,
		connection_state_objects,
		last_world_runtime_restore_warnings.size()
	]

func get_world_runtime_restore_warnings_text() -> String:
	if last_world_runtime_restore_warnings.is_empty():
		return "No world runtime restore warnings."
	return "\n".join(last_world_runtime_restore_warnings)

func get_world_runtime_restore_warnings() -> Array[String]:
	return last_world_runtime_restore_warnings.duplicate()


func set_active_bipob_ref(bipob: Node) -> void:
	active_bipob_ref = bipob

func get_platform_by_id(platform_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		if String(object_data.get("platform_id", "")) == platform_id:
			return object_data
	return {}

func get_platform_for_cell(cell: Vector2i) -> Dictionary:
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		for platform_cell_variant in Array(object_data.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalog.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
			if platform_cell == cell:
				return object_data
	return {}

func get_cell_height_level(cell: Vector2i) -> int:
	var platform := get_platform_for_cell(cell)
	if platform.is_empty() or String(platform.get("platform_type", "")) != "lifting":
		return 0
	return int(platform.get("height_level", 0))

func refresh_world_object_platform_height_state(object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	var object_cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if object_cell.x < 0 or object_cell.y < 0:
		return
	var platform := get_platform_for_cell(object_cell)
	if not platform.is_empty() and String(platform.get("platform_type", "")) == "lifting":
		object_data["platform_height_level"] = int(platform.get("height_level", 0))
		object_data["carried_by_platform_id"] = String(platform.get("platform_id", ""))
		return
	object_data["platform_height_level"] = get_cell_height_level(object_cell)
	object_data.erase("carried_by_platform_id")

func get_world_object_height_level(object_data: Dictionary) -> int:
	if object_data.is_empty():
		return 0
	if object_data.has("platform_height_level"):
		return int(object_data.get("platform_height_level", 0))
	var object_cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	return get_cell_height_level(object_cell)

func get_actor_height_level(actor_cell: Vector2i, actor: Node = null) -> int:
	var cell_height := get_cell_height_level(actor_cell)
	if actor == null:
		return cell_height
	if actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := String(actor.call("get_carried_by_platform_id")).strip_edges()
		if carried_platform_id.is_empty():
			return cell_height
		var current_platform := get_platform_for_cell(actor_cell)
		if current_platform.is_empty():
			return cell_height
		var current_platform_id := String(current_platform.get("platform_id", "")).strip_edges()
		if current_platform_id != carried_platform_id:
			return cell_height
		if actor.has_method("get_platform_height_level"):
			return int(actor.call("get_platform_height_level"))
		return cell_height
	if actor.has_method("get_platform_height_level"):
		return int(actor.call("get_platform_height_level"))
	return get_cell_height_level(actor_cell)

func can_move_between_height_levels(from_cell: Vector2i, to_cell: Vector2i, actor: Node = null) -> bool:
	var from_height := get_actor_height_level(from_cell, actor)
	var to_height := get_cell_height_level(to_cell)
	if from_height == to_height:
		return true
	if actor != null and actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := String(actor.call("get_carried_by_platform_id")).strip_edges()
		if not carried_platform_id.is_empty():
			var target_platform := get_platform_for_cell(to_cell)
			if not target_platform.is_empty() and String(target_platform.get("platform_id", "")).strip_edges() == carried_platform_id:
				return true
	return false

func get_platform_occupants(platform_id: String) -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"world_objects": [], "items": [], "bipobs": []}
	var cells: Array = []
	for c in Array(platform.get("platform_cells", [])):
		cells.append(WorldObjectCatalog.to_world_cell(c, Vector2i(-1, -1)))
	var occupants := {"world_objects": [], "items": [], "bipobs": []}
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == String(platform.get("id", "")):
			continue
		var pos := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if cells.has(pos):
			occupants["world_objects"].append(object_data)
	for cell in cells:
		for item in get_items_at_cell(cell):
			occupants["items"].append(item)
	if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
		var bipob_cell: Vector2i = active_bipob_ref.get_grid_position()
		if cells.has(bipob_cell):
			var bipob_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				bipob_direction = String(active_bipob_ref.get_direction())
			occupants["bipobs"].append({"id":"active_bipob","position":bipob_cell,"direction":bipob_direction})
	return occupants

func can_bipob_access_platform_switch(platform: Dictionary, actor_cell: Vector2i, facing_dir: String) -> bool:
	if platform.is_empty():
		return false
	if String(platform.get("object_group", "")) != "platform":
		return false
	if String(platform.get("control_type", "internal")) != "internal":
		return false
	if not platform.has("local_switch_cell"):
		return false
	var local_switch_cell := WorldObjectCatalog.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if local_switch_cell.x < 0 or local_switch_cell.y < 0:
		return false
	var facing_vector := _facing_to_vector(facing_dir)
	return actor_cell + facing_vector == local_switch_cell

func activate_platform_by_id(platform_id: String, source: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"success":false, "message":"Platform not found."}
	if String(platform.get("state", "active")) in ["unpowered", "disabled"] or not bool(platform.get("is_powered", true)):
		return {"success":false, "message":"Platform is unpowered."}
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(String(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or String(terminal.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(terminal.get("platform_control_enabled", true)) or not bool(terminal.get("is_powered", true)):
			return {"success":false, "message":"Platform terminal is unavailable."}
	var mode := String(platform.get("activation_mode", "instant"))
	if mode == "timer":
		platform["pending_activation"] = true
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("timer_turns", 1)))
		return {"success":true, "message":"Platform timer armed."}
	if mode == "periodic":
		platform["periodic_active"] = not bool(platform.get("periodic_active", false))
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("period_turns", 1)))
		return {"success":true, "message":"Platform periodic toggled."}
	if mode == "permanent":
		platform["permanent_state"] = not bool(platform.get("permanent_state", false))
	return _execute_platform_action(platform, source)

func _is_active_bipob_on_platform(platform: Dictionary) -> bool:
	if active_bipob_ref == null:
		return false
	if not active_bipob_ref.has_method("get_grid_position"):
		return false
	var actor_cell: Variant = active_bipob_ref.call("get_grid_position")
	if typeof(actor_cell) != TYPE_VECTOR2I:
		return false
	for platform_cell_variant in Array(platform.get("platform_cells", [])):
		var platform_cell := WorldObjectCatalog.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
		if platform_cell == actor_cell:
			return true
	return false

func _execute_platform_action(platform: Dictionary, source: String = "") -> Dictionary:
	var platform_id := String(platform.get("platform_id", platform.get("id", "")))
	var platform_type := String(platform.get("platform_type", ""))
	var activation_mode := String(platform.get("activation_mode", "instant"))
	var normalized_source := source
	var result := {
		"success": false,
		"message": "",
		"platform_id": platform_id,
		"platform_type": platform_type,
		"activation_mode": activation_mode,
		"source": normalized_source,
		"height_level": -1,
		"rotation_direction": ""
	}
	if platform_type == "rotating":
		var rotation_direction := String(platform.get("rotation_direction", "clockwise"))
		result["rotation_direction"] = rotation_direction
		var occupants := get_platform_occupants(String(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(String(obj.get("facing_dir", "up")), rotation_direction != "counterclockwise")
		if _is_active_bipob_on_platform(platform) and active_bipob_ref.has_method("set_direction"):
			var current_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				current_direction = String(active_bipob_ref.get_direction())
			active_bipob_ref.set_direction(_rotate_facing(current_direction, rotation_direction != "counterclockwise"))
		refresh_world_cooling_received()
		result["success"] = true
		var affected_count := Array(occupants.get("world_objects", [])).size() + Array(occupants.get("items", [])).size() + Array(occupants.get("bipobs", [])).size()
		if affected_count > 0:
			result["message"] = "Platform %s rotated %s; occupants affected: %d." % [platform_id, rotation_direction, affected_count]
		else:
			result["message"] = "Platform %s rotated %s." % [platform_id, rotation_direction]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = String(result.get("message", ""))
		return result
	if platform_type == "lifting":
		var min_h := int(platform.get("min_height_level", 0))
		var max_h := int(platform.get("max_height_level", 1))
		var previous_height := int(platform.get("height_level", min_h))
		platform["height_level"] = max_h if previous_height <= min_h else min_h
		var current_height := int(platform.get("height_level", min_h))
		result["height_level"] = current_height
		var occupants := get_platform_occupants(String(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			refresh_world_object_platform_height_state(obj)
		if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and active_bipob_ref.has_method("get_grid_position"):
			var actor_cell: Vector2i = active_bipob_ref.call("get_grid_position")
			for platform_cell_variant in Array(platform.get("platform_cells", [])):
				var platform_cell := WorldObjectCatalog.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
				if platform_cell == actor_cell:
					active_bipob_ref.call("set_platform_height_level", int(platform.get("height_level", 0)), String(platform.get("platform_id", "")))
					break
		result["success"] = true
		if current_height > previous_height:
			result["message"] = "Platform %s lifted to height %d." % [platform_id, current_height]
		elif current_height < previous_height:
			result["message"] = "Platform %s lowered to height %d." % [platform_id, current_height]
		else:
			result["message"] = "Platform %s stayed at height %d." % [platform_id, current_height]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = String(result.get("message", ""))
		return result
	result["message"] = "Unknown platform type."
	return result

func _rotate_facing(facing: String, clockwise: bool) -> String:
	var dirs := ["up", "right", "down", "left"]
	var idx := dirs.find(facing)
	if idx == -1:
		idx = 0
	idx = posmod(idx + (1 if clockwise else -1), 4)
	return dirs[idx]

func _facing_to_vector(facing_dir: String) -> Vector2i:
	match facing_dir:
		"up":
			return Vector2i(0, -1)
		"down":
			return Vector2i(0, 1)
		"left":
			return Vector2i(-1, 0)
		"right":
			return Vector2i(1, 0)
	return Vector2i.ZERO

func process_platform_turn_tick() -> Array[String]:
	var events: Array[String] = []
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	if platforms.is_empty():
		return events
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [String(a.get("platform_id", "")), String(a.get("id", ""))]
		var b_key := "%s|%s" % [String(b.get("platform_id", "")), String(b.get("id", ""))]
		return a_key < b_key
	)
	for platform in platforms:
		var mode := String(platform.get("activation_mode", "instant"))
		if mode == "timer":
			if not bool(platform.get("pending_activation", false)):
				continue
			var timer_turns := int(platform.get("timer_turns", 0))
			var timer_remaining := int(platform.get("timer_remaining_turns", 0))
			if timer_turns <= 0 and timer_remaining <= 0:
				platform["pending_activation"] = false
				continue
			var next_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_timer
			if next_timer == 0:
				platform["pending_activation"] = false
				var result := _execute_platform_action(platform, "timer")
				if bool(result.get("success", false)):
					var result_message := String(result.get("message", "")).strip_edges()
					if not result_message.is_empty():
						events.append(result_message)
					else:
						events.append("%s activated (timer)." % String(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
		elif mode == "periodic":
			if not bool(platform.get("periodic_active", false)):
				continue
			var period_turns := int(platform.get("period_turns", 0))
			if period_turns <= 0:
				continue
			var next_periodic_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_periodic_timer
			if next_periodic_timer == 0:
				var periodic_result := _execute_platform_action(platform, "periodic")
				platform["timer_remaining_turns"] = maxi(1, period_turns)
				if bool(periodic_result.get("success", false)):
					var periodic_message := String(periodic_result.get("message", "")).strip_edges()
					if not periodic_message.is_empty():
						events.append(periodic_message)
					else:
						events.append("%s activated (periodic)." % String(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
	return events

func process_platform_turn_tick_once(action_index: int) -> Array[String]:
	if action_index == platform_last_tick_action_index:
		return []
	platform_last_tick_action_index = action_index
	return process_platform_turn_tick()

func get_platform_last_tick_action_index() -> int:
	return platform_last_tick_action_index

func get_platform_timer_debug_summary_text() -> String:
	var lines: Array[String] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		lines.append("%s mode=%s pending=%s periodic=%s remaining=%d" % [String(object_data.get("platform_id", object_data.get("id", ""))), String(object_data.get("activation_mode", "instant")), str(bool(object_data.get("pending_activation", false))), str(bool(object_data.get("periodic_active", false))), int(object_data.get("timer_remaining_turns", 0))])
	return "\n".join(lines) if not lines.is_empty() else "No platforms."

func get_platform_state_summary(platform: Dictionary) -> String:
	var platform_id := String(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var platform_type := String(platform.get("platform_type", "")).strip_edges()
	if platform_type.is_empty():
		platform_type = "-"
	var activation_mode := String(platform.get("activation_mode", "instant")).strip_edges()
	if activation_mode.is_empty():
		activation_mode = "instant"
	var state := String(platform.get("state", "active")).strip_edges()
	if state.is_empty():
		state = "active"
	var powered_text := str(bool(platform.get("is_powered", true))).to_lower()
	var details: Array[String] = []
	if platform_type == "lifting":
		details.append("height=%d" % int(platform.get("height_level", 0)))
	elif platform_type == "rotating":
		var rotation_direction := String(platform.get("rotation_direction", "")).strip_edges()
		if rotation_direction.is_empty():
			rotation_direction = "-"
		details.append("rotation=%s" % rotation_direction)
	if activation_mode == "timer":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("timer_turns", 0))])
	elif activation_mode == "periodic":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("period_turns", 0))])
	details.append("pending=%s" % str(bool(platform.get("pending_activation", false))).to_lower())
	details.append("periodic=%s" % str(bool(platform.get("periodic_active", false))).to_lower())
	var control_type := String(platform.get("control_type", "internal")).strip_edges()
	if control_type.is_empty():
		control_type = "internal"
	details.append("control=%s" % control_type)
	var terminal_id := String(platform.get("linked_terminal_id", "")).strip_edges()
	if terminal_id.is_empty():
		terminal_id = "-"
	details.append("terminal=%s" % terminal_id)
	var last_source := String(platform.get("last_activation_source", "")).strip_edges()
	var last_message := String(platform.get("last_activation_message", "")).strip_edges()
	var last_text := "-"
	if not last_source.is_empty() and not last_message.is_empty():
		last_text = "%s:%s" % [last_source, last_message]
	elif not last_message.is_empty():
		last_text = last_message
	elif not last_source.is_empty():
		last_text = last_source
	details.append("last=%s" % last_text)
	return "Platform %s | %s | mode=%s | state=%s | powered=%s | %s" % [
		platform_id,
		platform_type,
		activation_mode,
		state,
		powered_text,
		" | ".join(details)
	]

func get_platform_state_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := String(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := String(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformStateSummary:"]
	for platform in platforms:
		var summary := get_platform_state_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		if filter_text.is_empty():
			lines.append("none")
		else:
			lines.append("none (filter=%s)" % filter_text)
	return "\n".join(lines)

func get_platform_occupant_summary(platform: Dictionary) -> String:
	var platform_id := String(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var cells_count := Array(platform.get("platform_cells", [])).size()
	var occupants := get_platform_occupants(platform_id) if platform_id != "-" else {"world_objects": [], "items": [], "bipobs": []}
	var world_objects: Array = Array(occupants.get("world_objects", []))
	var items_count := Array(occupants.get("items", [])).size()
	var bipobs_count := Array(occupants.get("bipobs", [])).size()
	var is_lifting_platform := String(platform.get("platform_type", "")) == "lifting"
	var carried_world_objects := 0
	var stale_world_objects := 0
	for object_data_variant in world_objects:
		if typeof(object_data_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = object_data_variant
		var carried_id := String(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_id == platform_id:
			carried_world_objects += 1
		elif is_lifting_platform:
			stale_world_objects += 1
	if not is_lifting_platform:
		stale_world_objects = 0
	var carry_required := str(is_lifting_platform).to_lower()
	var active_bipob_on_platform := str(_is_active_bipob_on_platform(platform)).to_lower()
	return "Occupants %s | cells=%d | world_objects=%d | items=%d | bipobs=%d | carry_required=%s | carried_world_objects=%d | stale_world_objects=%d | active_bipop_on_platform=%s" % [
		platform_id,
		cells_count,
		world_objects.size(),
		items_count,
		bipobs_count,
		carry_required,
		carried_world_objects,
		stale_world_objects,
		active_bipob_on_platform
	]

func get_platform_occupant_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := String(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := String(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformOccupantSummary:"]
	for platform in platforms:
		var summary := get_platform_occupant_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		lines.append("none" if filter_text.is_empty() else "none (filter=%s)" % filter_text)
	return "\n".join(lines)

func validate_platform_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	var platform_cell_owner := {}
	var platform_ids := {}
	var terminal_targets_count := {}
	for object_data in mission_world_objects:
		var group := String(object_data.get("object_group", ""))
		if group == "platform":
			platforms.append(object_data)
			continue
		if String(object_data.get("object_type", "")) == "platform_terminal":
			terminals.append(object_data)
	for platform in platforms:
		var object_id := String(platform.get("id", ""))
		var platform_id := String(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			errors.append("Platform %s has empty platform_id." % object_id)
		else:
			platform_ids[platform_id] = true
		var platform_type := String(platform.get("platform_type", ""))
		if not platform_type in ["rotating", "lifting"]:
			errors.append("Platform %s has invalid platform_type %s." % [platform_id if not platform_id.is_empty() else object_id, platform_type])
		var raw_cells: Array = platform.get("platform_cells", [])
		if raw_cells.is_empty():
			errors.append("Platform %s has empty platform_cells." % (platform_id if not platform_id.is_empty() else object_id))
		var local_cells := {}
		for cell_variant in raw_cells:
			var world_cell := WorldObjectCatalog.to_world_cell(cell_variant, Vector2i(-1, -1))
			if world_cell.x < 0 or world_cell.y < 0:
				errors.append("Platform %s has invalid cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			if local_cells.has(world_cell):
				errors.append("Platform %s has duplicate cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			local_cells[world_cell] = true
			if platform_cell_owner.has(world_cell):
				errors.append("Cell %s is claimed by multiple platforms (%s and %s)." % [str(world_cell), String(platform_cell_owner[world_cell]), platform_id])
			else:
				platform_cell_owner[world_cell] = platform_id
		var control_type := String(platform.get("control_type", ""))
		if not control_type in ["internal", "external"]:
			errors.append("Platform %s has invalid control_type %s." % [platform_id, control_type])
		var power_type := String(platform.get("power_type", ""))
		if not power_type in ["internal", "external"]:
			errors.append("Platform %s has invalid power_type %s." % [platform_id, power_type])
		if control_type == "internal":
			var local_switch := WorldObjectCatalog.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
			if local_switch.x < 0 or local_switch.y < 0:
				errors.append("Platform %s has invalid local_switch_cell %s." % [platform_id, str(local_switch)])
		if platform_type == "rotating":
			var rotation_direction := String(platform.get("rotation_direction", ""))
			if not rotation_direction in ["clockwise", "counterclockwise"]:
				errors.append("Platform %s has invalid rotation_direction %s." % [platform_id, rotation_direction])
			if not platform.has("rotation_direction"):
				warnings.append("Platform %s (rotating) is missing rotation_direction." % platform_id)
		if platform_type == "lifting":
			var min_h := int(platform.get("min_height_level", 0))
			var max_h := int(platform.get("max_height_level", 0))
			if typeof(platform.get("height_level", 0)) != TYPE_INT:
				errors.append("Platform %s has non-int height_level." % platform_id)
			var height := int(platform.get("height_level", 0))
			if min_h > height or height > max_h:
				errors.append("Platform %s has invalid height range min=%d height=%d max=%d." % [platform_id, min_h, height, max_h])
			if not platform.has("height_level"):
				warnings.append("Platform %s (lifting) is missing height_level." % platform_id)
		for timer_key in ["timer_turns", "timer_remaining_turns", "period_turns"]:
			if int(platform.get(timer_key, 0)) < 0:
				errors.append("Platform %s has negative %s." % [platform_id, timer_key])
		var activation_mode := String(platform.get("activation_mode", "instant"))
		if activation_mode == "timer":
			if int(platform.get("timer_turns", 0)) <= 0:
				warnings.append("Platform %s uses timer mode with timer_turns <= 0." % platform_id)
			if bool(platform.get("pending_activation", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0:
				warnings.append("Platform %s has pending timer activation with timer_remaining_turns <= 0." % platform_id)
		if activation_mode == "periodic":
			if int(platform.get("period_turns", 0)) <= 0:
				warnings.append("Platform %s uses periodic mode with period_turns <= 0." % platform_id)
			if bool(platform.get("periodic_active", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0 and int(platform.get("period_turns", 0)) > 0:
				warnings.append("Platform %s has periodic_active with timer_remaining_turns <= 0." % platform_id)
		var last_source := String(platform.get("last_activation_source", ""))
		if not last_source in ["", "timer", "periodic", "terminal", "local_switch", "debug", "direct"]:
			warnings.append("Platform %s has unexpected last_activation_source %s." % [platform_id, last_source])
		if platform.has("last_activation_message") and typeof(platform.get("last_activation_message", "")) != TYPE_STRING:
			warnings.append("Platform %s has non-string last_activation_message." % platform_id)
		var has_pending_activation := bool(platform.get("pending_activation", false))
		if has_pending_activation and not activation_mode in ["timer", "permanent"]:
			warnings.append("Platform %s has pending_activation outside timer/permanent mode." % platform_id)
		var has_periodic_active := bool(platform.get("periodic_active", false))
		if has_periodic_active and activation_mode != "periodic":
			warnings.append("Platform %s has periodic_active outside periodic mode." % platform_id)
		if bool(platform.get("requires_terminal_enabled", false)):
			var linked_terminal_id := String(platform.get("linked_terminal_id", "")).strip_edges()
			if linked_terminal_id.is_empty():
				errors.append("Platform %s requires terminal but linked_terminal_id is empty." % platform_id)
			else:
				var linked_terminal := get_world_object_by_id(linked_terminal_id)
				if linked_terminal.is_empty():
					errors.append("Platform %s linked terminal %s is missing." % [platform_id, linked_terminal_id])
				else:
					if String(linked_terminal.get("terminal_type", "")) != "platform":
						errors.append("Platform %s linked terminal %s has invalid terminal_type." % [platform_id, linked_terminal_id])
					if String(linked_terminal.get("target_platform_id", "")) != platform_id:
						errors.append("Platform %s linked terminal %s targets %s." % [platform_id, linked_terminal_id, String(linked_terminal.get("target_platform_id", ""))])
	for terminal in terminals:
		var terminal_id := String(terminal.get("id", ""))
		var target_platform_id := String(terminal.get("target_platform_id", "")).strip_edges()
		if target_platform_id.is_empty():
			errors.append("Platform terminal %s has empty target_platform_id." % terminal_id)
			continue
		terminal_targets_count[target_platform_id] = int(terminal_targets_count.get(target_platform_id, 0)) + 1
		if get_platform_by_id(target_platform_id).is_empty():
			errors.append("Platform terminal %s targets missing platform %s." % [terminal_id, target_platform_id])
	for target_id in terminal_targets_count.keys():
		var count := int(terminal_targets_count[target_id])
		if count > 1:
			warnings.append("Multiple terminals (%d) target platform %s." % [count, String(target_id)])
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", ""))
		var carried_platform_id := String(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_platform_id.is_empty():
			var object_cell := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			var object_platform := get_platform_for_cell(object_cell)
			if not object_platform.is_empty() and String(object_platform.get("platform_type", "")) == "lifting":
				var expected_platform_id := String(object_platform.get("platform_id", "")).strip_edges()
				warnings.append("Object %s stands on lifting platform %s but carried_by_platform_id is missing." % [object_id, expected_platform_id])
			continue
		if not platform_ids.has(carried_platform_id):
			warnings.append("Object %s references missing carried_by_platform_id %s." % [object_id, carried_platform_id])
			continue
		var object_cell_with_carried := WorldObjectCatalog.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var current_platform := get_platform_for_cell(object_cell_with_carried)
		if current_platform.is_empty():
			warnings.append("Object %s references carried_by_platform_id %s but is not on a platform cell." % [object_id, carried_platform_id])
			continue
		var current_platform_id := String(current_platform.get("platform_id", "")).strip_edges()
		var current_platform_type := String(current_platform.get("platform_type", ""))
		if current_platform_type != "lifting":
			warnings.append("Object %s references carried_by_platform_id %s but stands on non-lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
			continue
		if current_platform_id != carried_platform_id:
			warnings.append("Object %s references carried_by_platform_id %s but stands on lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
		if object_data.has("platform_height_level"):
			var carried_platform := get_platform_by_id(carried_platform_id)
			if not carried_platform.is_empty():
				var platform_height := int(carried_platform.get("height_level", 0))
				var object_height := int(object_data.get("platform_height_level", 0))
				if object_height != platform_height:
					warnings.append("Object %s platform_height_level %d differs from platform %s height %d." % [object_id, object_height, carried_platform_id, platform_height])
	for platform in platforms:
		var platform_id := String(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			continue
		var occupants := get_platform_occupants(platform_id)
		var platform_cells: Array = []
		for cell_variant in Array(platform.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalog.to_world_cell(cell_variant, Vector2i(-1, -1))
			if platform_cell.x >= 0 and platform_cell.y >= 0:
				platform_cells.append(platform_cell)
		var is_lifting_platform := String(platform.get("platform_type", "")) == "lifting"
		var platform_height := int(platform.get("height_level", 0))
		for world_object_variant in Array(occupants.get("world_objects", [])):
			if typeof(world_object_variant) != TYPE_DICTIONARY:
				continue
			var world_object: Dictionary = world_object_variant
			var world_object_id := String(world_object.get("id", ""))
			var world_object_carried_id := String(world_object.get("carried_by_platform_id", "")).strip_edges()
			if is_lifting_platform and world_object_carried_id != platform_id:
				warnings.append("World object %s is on lifting platform %s but carried_by_platform_id is stale." % [world_object_id, platform_id])
			if is_lifting_platform and int(world_object.get("platform_height_level", 0)) != platform_height:
				warnings.append("World object %s has platform_height_level mismatch on lifting platform %s." % [world_object_id, platform_id])
		for world_object in mission_world_objects:
			if String(world_object.get("carried_by_platform_id", "")).strip_edges() != platform_id:
				continue
			var object_cell := WorldObjectCatalog.to_world_cell(world_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			if not platform_cells.has(object_cell):
				warnings.append("World object %s is carried by platform %s but is not on its cells." % [String(world_object.get("id", "")), platform_id])
		if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
			var active_cell_variant: Variant = active_bipob_ref.call("get_grid_position")
			if typeof(active_cell_variant) == TYPE_VECTOR2I:
				var active_cell: Vector2i = active_cell_variant
				var active_on_platform := platform_cells.has(active_cell)
				var has_bipob_carried_getter := active_bipob_ref.has_method("get_carried_by_platform_id")
				var has_bipob_height_getter := active_bipob_ref.has_method("get_platform_height_level")
				var bipob_carried_id := ""
				if has_bipob_carried_getter:
					bipob_carried_id = String(active_bipob_ref.call("get_carried_by_platform_id")).strip_edges()
				if is_lifting_platform and active_on_platform and has_bipob_carried_getter and bipob_carried_id != platform_id:
					warnings.append("Active Bipop is on lifting platform %s but carried_by_platform_id is stale." % platform_id)
				if has_bipob_carried_getter and bipob_carried_id == platform_id and not active_on_platform:
					warnings.append("Active Bipop is carried by platform %s but is not on its cells." % platform_id)
				if is_lifting_platform and active_on_platform and has_bipob_height_getter:
					var bipob_height := int(active_bipob_ref.call("get_platform_height_level"))
					if bipob_height != platform_height:
						warnings.append("Active Bipop platform_height_level mismatch on lifting platform %s." % platform_id)
	return {
		"valid": errors.is_empty(),
		"platforms": platforms.size(),
		"terminals": terminals.size(),
		"warnings": warnings,
		"errors": errors
	}

func get_platform_runtime_validation_text() -> String:
	var validation := validate_platform_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PlatformRuntimeValidation: valid=%s | platforms=%d | terminals=%d | errors=%d | warnings=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("platforms", 0)),
		int(validation.get("terminals", 0)),
		errors.size(),
		warnings.size()
	])
	for error in errors:
		lines.append("ERROR: %s" % error)
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func get_platform_runtime_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
		elif String(object_data.get("object_type", "")) == "platform_terminal":
			terminals.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [String(a.get("platform_id", "")), String(a.get("id", ""))]
		var b_key := "%s|%s" % [String(b.get("platform_id", "")), String(b.get("id", ""))]
		return a_key < b_key
	)
	terminals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	var lines: Array[String] = []
	lines.append("Platforms:")
	for platform in platforms:
		var platform_id := String(platform.get("platform_id", platform.get("id", "")))
		var terminal_id := String(platform.get("linked_terminal_id", "none"))
		if terminal_id.strip_edges().is_empty():
			terminal_id = "none"
		var occupants := get_platform_occupants(platform_id)
		var occ_obj := Array(occupants.get("world_objects", [])).size()
		var occ_item := Array(occupants.get("items", [])).size()
		var occ_bipob := Array(occupants.get("bipobs", [])).size()
		var mode := String(platform.get("activation_mode", "instant"))
		var timer_remaining := int(platform.get("timer_remaining_turns", 0))
		var height := "-"
		if String(platform.get("platform_type", "")) == "lifting":
			height = str(int(platform.get("height_level", 0)))
		var last_source := String(platform.get("last_activation_source", "")).strip_edges()
		var last_message := String(platform.get("last_activation_message", "")).strip_edges()
		var last_fragment := "last=-"
		if not last_source.is_empty() or not last_message.is_empty():
			last_fragment = "last=%s:%s" % [last_source if not last_source.is_empty() else "-", last_message if not last_message.is_empty() else "-"]
		var line := "%s | %s | cells=%d | %s | powered=%s | %s/%s | terminal=%s | %s | pending=%s | periodic=%s | timer_turns=%d | period_turns=%d | timer=%d | height=%s | occupants obj=%d item=%d bipob=%d" % [
			platform_id,
			String(platform.get("platform_type", "")),
			Array(platform.get("platform_cells", [])).size(),
			String(platform.get("state", "active")),
			str(bool(platform.get("is_powered", true))).to_lower(),
			String(platform.get("power_type", "internal")),
			String(platform.get("control_type", "internal")),
			terminal_id,
			mode,
			str(bool(platform.get("pending_activation", false))).to_lower(),
			str(bool(platform.get("periodic_active", false))).to_lower(),
			int(platform.get("timer_turns", 0)),
			int(platform.get("period_turns", 0)),
			timer_remaining,
			height,
			occ_obj,
			occ_item,
			occ_bipob
		]
		line = "%s | %s" % [line, last_fragment]
		var haystack := "%s %s %s %s %s" % [platform_id, String(platform.get("id", "")), String(platform.get("platform_type", "")), String(platform.get("state", "")), terminal_id]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	lines.append("Terminals:")
	for terminal in terminals:
		var line := "%s | target=%s | %s | powered=%s | enabled=%s | remote=%s | interface=%s" % [
			String(terminal.get("id", "")),
			String(terminal.get("target_platform_id", "")),
			String(terminal.get("state", "active")),
			str(bool(terminal.get("is_powered", true))).to_lower(),
			str(bool(terminal.get("platform_control_enabled", true))).to_lower(),
			str(bool(terminal.get("platform_remote_control", true))).to_lower(),
			String(terminal.get("terminal_interface", "standard"))
		]
		var haystack := "%s %s %s" % [String(terminal.get("id", "")), String(terminal.get("target_platform_id", "")), String(terminal.get("state", ""))]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	return "\n".join(lines)

func seed_platform_debug_scenario(origin: Vector2i = Vector2i(10, 2)) -> void:
	_place_debug_world_object("rotating_platform", "rotating_platform_debug", origin, {"platform_id":"platform_rot_a","platform_cells":[[origin.x, origin.y],[origin.x+1, origin.y]],"control_type":"external","linked_terminal_id":"platform_terminal_debug","requires_terminal_enabled":true})
	_place_debug_world_object("lifting_platform", "lifting_platform_debug", origin + Vector2i(0, 3), {"platform_id":"platform_lift_a","platform_cells":[[origin.x, origin.y+3]],"control_type":"internal","local_switch_cell":[origin.x-1, origin.y+3],"height_level":0,"min_height_level":0,"max_height_level":1})
	_place_debug_world_object("platform_terminal", "platform_terminal_debug", origin + Vector2i(-2, 0), {"target_platform_id":"platform_rot_a","platform_control_enabled":true})
	_place_debug_world_object("external_air_cooler", "platform_air_cooler_debug", origin, {"facing_dir":"right"})

func _snapshot_platform_debug_fields(object_data: Dictionary, fields: Array[String]) -> Dictionary:
	var snapshot := {}
	for field in fields:
		var had_field := object_data.has(field)
		var value = null
		if had_field:
			value = object_data[field]
			if value is Dictionary or value is Array:
				value = value.duplicate(true)
		snapshot[field] = {"had_field": had_field, "value": value}
	return snapshot

func _restore_platform_debug_fields(object_data: Dictionary, snapshot: Dictionary) -> void:
	for field in snapshot.keys():
		var field_state: Dictionary = snapshot[field]
		if bool(field_state.get("had_field", false)):
			var restored_value = field_state.get("value")
			if restored_value is Dictionary or restored_value is Array:
				restored_value = restored_value.duplicate(true)
			object_data[field] = restored_value
		else:
			object_data.erase(field)

func _find_debug_floor_cell_near_platform(platform_cells: Array, origin_cell: Vector2i) -> Vector2i:
	var platform_world_cells: Array[Vector2i] = []
	for cell in platform_cells:
		var world_cell := WorldObjectCatalog.to_world_cell(cell, Vector2i(-1, -1))
		if world_cell != Vector2i(-1, -1):
			platform_world_cells.append(world_cell)
	var candidate_offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	for offset in candidate_offsets:
		var candidate := origin_cell + offset
		if platform_world_cells.has(candidate):
			continue
		if not get_platform_for_cell(candidate).is_empty():
			continue
		if grid_manager != null and grid_manager.has_method("is_in_bounds") and not grid_manager.is_in_bounds(candidate):
			continue
		if grid_manager != null and grid_manager.has_method("is_walkable") and not grid_manager.is_walkable(candidate):
			continue
		return candidate
	return Vector2i(-1, -1)


func _build_platform_timer_tick_debug_platform(platform_id: String, mode: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	var platform: Dictionary = {
		"id": "platform_timer_tick_debug_%s" % platform_id,
		"object_group": "platform",
		"object_type": "platform_debug_helper",
		"platform_id": platform_id,
		"platform_type": "rotating",
		"platform_cells": [[cell.x, cell.y]],
		"control_type": "internal",
		"power_type": "internal",
		"state": "active",
		"is_powered": true,
		"height_level": 0,
		"min_height_level": 0,
		"max_height_level": 1,
		"rotation_direction": "clockwise",
		"permanent_state": "active",
		"activation_mode": mode,
		"timer_turns": 0,
		"period_turns": 0,
		"timer_remaining_turns": 0,
		"pending_activation": false,
		"periodic_active": false
	}
	for key in overrides.keys():
		platform[key] = overrides[key]
	return platform

func _cleanup_platform_timer_tick_debug_state(temp_platforms: Array[Dictionary], original_platform_snapshots: Dictionary, original_last_tick_action_index: int) -> void:
	for temp_platform in temp_platforms:
		mission_world_objects.erase(temp_platform)
	for object_data in original_platform_snapshots.keys():
		_restore_platform_debug_fields(object_data, original_platform_snapshots[object_data])
	platform_last_tick_action_index = original_last_tick_action_index


func validate_platform_timer_tick_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var fields_to_snapshot: Array[String] = [
		"activation_mode",
		"pending_activation",
		"periodic_active",
		"timer_turns",
		"period_turns",
		"timer_remaining_turns",
		"height_level",
		"rotation_direction",
		"permanent_state",
		"platform_last_tick_action_index"
	]
	var original_last_tick_action_index := platform_last_tick_action_index
	var original_platform_snapshots := {}
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "platform":
			continue
		original_platform_snapshots[object_data] = _snapshot_platform_debug_fields(object_data, fields_to_snapshot)

	var temp_platforms: Array[Dictionary] = []
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer", "timer", Vector2i(80, 80), {"pending_activation": true, "timer_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic", "periodic", Vector2i(82, 80), {"periodic_active": true, "period_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic_invalid", "periodic", Vector2i(84, 80), {"periodic_active": true, "period_turns": 0, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer_invalid", "timer", Vector2i(86, 80), {"pending_activation": true, "timer_turns": 0, "timer_remaining_turns": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_instant", "instant", Vector2i(88, 80), {"height_level": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_permanent", "permanent", Vector2i(90, 80), {"pending_activation": true, "permanent_state": "active", "height_level": 0}))
	for temp_platform in temp_platforms:
		mission_world_objects.append(temp_platform)
	var temp_cells := {}
	var has_temp_overlap := false
	for temp_platform in temp_platforms:
		var platform_cells: Array = temp_platform.get("platform_cells", [])
		if platform_cells.is_empty():
			continue
		var world_cell := WorldObjectCatalog.to_world_cell(platform_cells[0], Vector2i(-1, -1))
		if world_cell == Vector2i(-1, -1):
			continue
		if temp_cells.has(world_cell):
			has_temp_overlap = true
			break
		temp_cells[world_cell] = true
	if has_temp_overlap:
		warnings.append("Timer tick debug platforms overlap cells.")

	var instant_platform := get_platform_by_id("debug_timer_tick_instant")
	var permanent_platform := get_platform_by_id("debug_timer_tick_permanent")
	var instant_height_before := int(instant_platform.get("height_level", 0)) if not instant_platform.is_empty() else 0
	var permanent_height_before := int(permanent_platform.get("height_level", 0)) if not permanent_platform.is_empty() else 0

	process_platform_turn_tick_once(100)
	process_platform_turn_tick_once(100)

	var timer_platform := get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Missing timer validation platform.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 1:
			warnings.append("Timer platform ticked more than once for the same action index.")
	process_platform_turn_tick_once(101)
	if timer_platform.is_empty():
		timer_platform = get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Timer platform missing after second tick.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform did not complete after two distinct action indices.")
		if bool(timer_platform.get("pending_activation", true)):
			warnings.append("Timer platform pending_activation did not clear after activation.")

	var periodic_platform := get_platform_by_id("debug_timer_tick_periodic")
	if periodic_platform.is_empty():
		warnings.append("Missing periodic validation platform.")
	else:
		if int(periodic_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform did not reactivate every two distinct action indices.")

	var periodic_invalid_platform := get_platform_by_id("debug_timer_tick_periodic_invalid")
	if periodic_invalid_platform.is_empty():
		warnings.append("Missing invalid periodic validation platform.")
	else:
		if int(periodic_invalid_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform with period_turns <= 0 ticked unexpectedly.")

	var timer_invalid_platform := get_platform_by_id("debug_timer_tick_timer_invalid")
	if timer_invalid_platform.is_empty():
		warnings.append("Missing invalid timer validation platform.")
	else:
		if bool(timer_invalid_platform.get("pending_activation", true)):
			warnings.append("Timer platform with invalid turns did not clear pending_activation.")
		if int(timer_invalid_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform with invalid turns changed timer_remaining_turns unexpectedly.")

	if not instant_platform.is_empty() and int(instant_platform.get("height_level", 0)) != instant_height_before:
		warnings.append("Instant platform tick changed height unexpectedly.")
	if not permanent_platform.is_empty() and int(permanent_platform.get("height_level", 0)) != permanent_height_before:
		warnings.append("Permanent platform tick changed height unexpectedly.")

	_cleanup_platform_timer_tick_debug_state(temp_platforms, original_platform_snapshots, original_last_tick_action_index)
	return warnings

func get_platform_timer_tick_validation_text() -> String:
	var warnings := validate_platform_timer_tick_debug_scenario()
	var lines: Array[String] = ["PlatformTimerTickValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)
func validate_platform_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var rotating_platform := get_platform_by_id("platform_rot_a")
	if rotating_platform.is_empty(): warnings.append("Missing rotating platform.")
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty(): warnings.append("Missing lifting platform.")
	var terminal := get_world_object_by_id("platform_terminal_debug")
	if terminal.is_empty() or String(terminal.get("target_platform_id", "")) != "platform_rot_a": warnings.append("Platform terminal link invalid.")
	var air_cooler := get_world_object_by_id("platform_air_cooler_debug")
	if air_cooler.is_empty():
		warnings.append("Missing air cooler on rotating platform.")
	var old_requires_terminal_enabled := bool(rotating_platform.get("requires_terminal_enabled", false))
	var air_cooler_snapshot := {}
	var lifting_platform_snapshot := {}
	var terminal_snapshot := {}
	var rotating_platform_snapshot := {}
	if not air_cooler.is_empty():
		air_cooler_snapshot = _snapshot_platform_debug_fields(air_cooler, ["facing_dir"])
	if not lifting_platform.is_empty():
		lifting_platform_snapshot = _snapshot_platform_debug_fields(lifting_platform, ["height_level", "carried_by_platform_id"])
	if not terminal.is_empty():
		terminal_snapshot = _snapshot_platform_debug_fields(terminal, ["state", "is_powered", "platform_control_enabled"])
	if not rotating_platform.is_empty():
		rotating_platform_snapshot = _snapshot_platform_debug_fields(rotating_platform, ["timer_remaining_turns", "pending_activation", "periodic_active", "requires_terminal_enabled", "permanent_state", "activation_mode", "timer_turns", "period_turns", "rotation_direction"])
	if not rotating_platform.is_empty() and not air_cooler.is_empty():
		var before_facing := String(air_cooler.get("facing_dir", ""))
		var rotate_result := activate_platform_by_id("platform_rot_a", "debug_validation")
		if not bool(rotate_result.get("success", false)):
			warnings.append("Rotating platform activation failed during validation.")
		var after_facing := String(air_cooler.get("facing_dir", ""))
		if before_facing == after_facing:
			warnings.append("Rotating platform action did not rotate air cooler.")
	if not lifting_platform.is_empty():
		var before_height := int(lifting_platform.get("height_level", 0))
		var lift_result := activate_platform_by_id("platform_lift_a", "debug_validation")
		if not bool(lift_result.get("success", false)):
			warnings.append("Lifting platform activation failed during validation.")
		var after_height := int(lifting_platform.get("height_level", before_height))
		if before_height == after_height:
			warnings.append("Lifting platform action did not toggle height_level.")
		var switch_cell := WorldObjectCatalog.to_world_cell(lifting_platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
		var wrong_access := can_bipob_access_platform_switch(lifting_platform, switch_cell + Vector2i(2, 0), "left")
		if wrong_access:
			warnings.append("Internal switch access returned true from wrong position.")
		var actor_cell := switch_cell - _facing_to_vector(String(lifting_platform.get("local_switch_facing_dir", "right")))
		var right_access := can_bipob_access_platform_switch(lifting_platform, actor_cell, String(lifting_platform.get("local_switch_facing_dir", "right")))
		if not right_access:
			warnings.append("Internal switch access returned false from valid position.")
	if not rotating_platform.is_empty() and not terminal.is_empty():
		rotating_platform["requires_terminal_enabled"] = true
		terminal["platform_control_enabled"] = false
		var blocked := activate_platform_by_id("platform_rot_a", "debug_validation_block")
		if bool(blocked.get("success", false)):
			warnings.append("Terminal unavailable did not block rotating platform activation.")
	if not air_cooler.is_empty():
		_restore_platform_debug_fields(air_cooler, air_cooler_snapshot)
	if not lifting_platform.is_empty():
		_restore_platform_debug_fields(lifting_platform, lifting_platform_snapshot)
	if not terminal.is_empty():
		_restore_platform_debug_fields(terminal, terminal_snapshot)
	if not rotating_platform.is_empty():
		rotating_platform["requires_terminal_enabled"] = old_requires_terminal_enabled
		_restore_platform_debug_fields(rotating_platform, rotating_platform_snapshot)
		if rotating_platform.get("requires_terminal_enabled", false) != old_requires_terminal_enabled:
			warnings.append("Validation restore mismatch: rotating platform terminal gate flag.")
	if debug_platform_scenario_enabled:
		warnings.append_array(validate_platform_height_gating_debug_scenario())
		warnings.append_array(validate_platform_timer_tick_debug_scenario())
	refresh_world_cooling_received()
	return warnings

func validate_platform_height_gating_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty():
		warnings.append("Missing lifting platform for height gating validation.")
		return warnings
	var platform_cells: Array = Array(lifting_platform.get("platform_cells", []))
	if platform_cells.is_empty():
		warnings.append("Lifting platform has no platform cells.")
		return warnings
	var platform_cell := WorldObjectCatalog.to_world_cell(platform_cells[0], Vector2i(-1, -1))
	if platform_cell == Vector2i(-1, -1):
		warnings.append("Lifting platform first platform cell is invalid.")
		return warnings
	var floor_cell := _find_debug_floor_cell_near_platform(platform_cells, platform_cell)
	if floor_cell == Vector2i(-1, -1):
		warnings.append("No normal floor cell found near lifting platform for height gating validation.")
		return warnings
	var same_height_platform_cell := platform_cell
	if platform_cells.size() > 1:
		same_height_platform_cell = WorldObjectCatalog.to_world_cell(platform_cells[1], platform_cell)
	var original_height := int(lifting_platform.get("height_level", 0))
	var platform_snapshot := _snapshot_platform_debug_fields(lifting_platform, ["height_level"])
	lifting_platform["height_level"] = original_height
	if get_cell_height_level(platform_cell) != original_height:
		warnings.append("Platform cell height does not match platform.height_level.")
	if get_cell_height_level(floor_cell) != 0:
		warnings.append("Normal floor cell did not resolve to height 0.")
	lifting_platform["height_level"] = 1
	if can_move_between_height_levels(platform_cell, floor_cell, null):
		warnings.append("Height gating failed: platform->floor movement allowed on mismatch (1->0).")
	if can_move_between_height_levels(floor_cell, platform_cell, null):
		warnings.append("Height gating failed: floor->platform movement allowed on mismatch (0->1).")
	if not can_move_between_height_levels(platform_cell, same_height_platform_cell, null):
		warnings.append("Height gating failed: movement between same-height platform cells blocked.")
	var candidate_object: Dictionary = {}
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) == "platform":
			continue
		if String(object_data.get("object_group", "")) == "item":
			continue
		candidate_object = object_data
		break
	if candidate_object.is_empty():
		warnings.append("No world object available for platform height validation.")
		_restore_platform_debug_fields(lifting_platform, platform_snapshot)
		return warnings
	var object_snapshot := _snapshot_platform_debug_fields(candidate_object, ["position", "platform_height_level", "carried_by_platform_id"])
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	var carried_platform_id := String(candidate_object.get("carried_by_platform_id", "")).strip_edges()
	if carried_platform_id != String(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object on lifting platform did not receive matching carried_by_platform_id.")
	if int(candidate_object.get("platform_height_level", -1)) != int(lifting_platform.get("height_level", -1)):
		warnings.append("Object platform height on lifting platform does not match platform height.")
	candidate_object["position"] = floor_cell
	refresh_world_object_platform_height_state(candidate_object)
	if String(candidate_object.get("carried_by_platform_id", "")).strip_edges() != "":
		warnings.append("Object moved off lifting platform kept carried_by_platform_id.")
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	if String(candidate_object.get("carried_by_platform_id", "")).strip_edges() != String(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object moved onto lifting platform did not get carried_by_platform_id.")
	_restore_platform_debug_fields(candidate_object, object_snapshot)
	_restore_platform_debug_fields(lifting_platform, platform_snapshot)
	return warnings

func get_platform_height_gating_validation_text() -> String:
	var warnings := validate_platform_height_gating_debug_scenario()
	var lines: Array[String] = ["PlatformHeightGatingValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)
