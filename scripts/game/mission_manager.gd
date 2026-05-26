extends Node

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystemRef = preload("res://scripts/world/scan_system.gd")
const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const PowerSystemRef = preload("res://scripts/world/power_system.gd")

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
var grid_manager: Node = null
var platform_last_tick_action_index: int = -1
var runtime_inventory_state := {
	"pocket_items": [],
	"manipulator_hold": "",
	"digital_buffer": [],
	"box_storage": [],
	"item_amounts": {},
	"consumed_item_ids": [],
	"world_item_runtime": {}
}
var _map_constructor_runtime_object_seq: int = 1
const MAP_CONSTRUCTOR_SOLID_PREFABS: Array[String] = [
	"outer_wall","brick_wall","concrete_wall","steel_wall","grate_wall",
	"mechanical_door","digital_door","powered_gate"
]

# region Typed world-object access wrappers
func _wo_id(object_data: Dictionary) -> String:
	return String(object_data.get("id", ""))

func _wo_group(object_data: Dictionary) -> String:
	return String(object_data.get("object_group", ""))

func _wo_type(object_data: Dictionary) -> String:
	return String(object_data.get("object_type", ""))

func _wo_pos(object_data: Dictionary, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	return Vector2i(object_data.get("position", fallback))
# endregion

# region Lifecycle / setup
func _ready() -> void:
	if enable_debug_seed:
		_seed_debug_world_objects()

func setup_world_objects_for_mission(mission_id: String) -> void:
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	if mission_id == "mission_10":
		_setup_task_test_mission_world()
		return
	if mission_id != "mission_1":
		return
	var objects: Array[Dictionary] = WorldObjectCatalogRef.create_test_set()
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
	objects.append(WorldObjectCatalogRef.create_world_object("turret", "turret_1"))
	for object_data in objects:
		var object_id := _wo_id(object_data)
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
		elif _wo_group(object_data) == "item":
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
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
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
# endregion

func _setup_task_test_mission_world() -> void:
	var validation_data := build_task_test_mission_world_objects_for_validation()
	var objects: Array[Dictionary] = validation_data.get("objects", [])
	var items_by_cell: Dictionary = validation_data.get("items_by_cell", {})
	for obj in objects:
		set_world_object_at_cell(Vector2i(obj.get("position", Vector2i.ZERO)), obj)
	for cell_variant in items_by_cell.keys():
		var cell := Vector2i(cell_variant)
		for item in Array(items_by_cell.get(cell_variant, [])):
			add_item_at_cell(cell, Dictionary(item).duplicate(true))
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power")
	refresh_world_cooling_received()

func build_task_test_mission_world_objects_for_validation() -> Dictionary:
	var warnings: Array[String] = []
	var objects: Array[Dictionary] = []
	var specs: Array[Dictionary] = [
		{"type":"power_source_class_1","id":"task_test_source_class_1","pos":Vector2i(1, 1),"extra":{"power_network_id":"task_test_power","connected_device_ids":["task_test_energy_door"]}},
		{"type":"power_source_class_2","id":"task_test_source_class_2","pos":Vector2i(1, 3),"extra":{"power_network_id":"task_test_power","connected_device_ids":["task_test_terminal_main","task_test_platform_terminal"],"current_heat":4,"working_heat":3,"overheat_threshold":3}},
		{"type":"power_source_class_3","id":"task_test_overheated_source","pos":Vector2i(1, 5),"extra":{"power_network_id":"task_test_power","state":"overheated","current_heat":5,"working_heat":3,"overheat_threshold":3}},
		{"type":"circuit_breaker","id":"task_test_breaker","pos":Vector2i(2, 1),"extra":{"power_network_id":"task_test_power"}},
		{"type":"circuit_switch","id":"task_test_switch","pos":Vector2i(3, 1),"extra":{"power_network_id":"task_test_power"}},
		{"type":"fuse_box_empty","id":"task_test_fuse_box_empty","pos":Vector2i(4, 1),"extra":{"power_network_id":"task_test_power"}},
		{"type":"light","id":"task_test_light","pos":Vector2i(5, 1),"extra":{"power_network_id":"task_test_power"}},
		{"type":"energy_door","id":"task_test_energy_door","pos":Vector2i(6, 1),"extra":{"power_network_id":"task_test_power","lock_type":"digital_key","is_locked":true}},
		{"type":"power_socket","id":"task_test_power_socket_a","pos":Vector2i(2, 3),"extra":{"power_network_id":"task_test_power"}},
		{"type":"power_socket","id":"task_test_power_socket_b","pos":Vector2i(3, 3),"extra":{"power_network_id":"task_test_power"}},
		{"type":"power_cable","id":"task_test_cut_cable","pos":Vector2i(4, 3),"extra":{"state":"cut","damaged":true}},
		{"type":"power_cable","id":"task_test_hidden_cable","pos":Vector2i(5, 3),"extra":{"hidden":true,"hidden_cable":true,"visible_with_xray":true}},
		{"type":"power_socket","id":"task_test_hidden_socket","pos":Vector2i(6, 3),"extra":{"hidden":true,"visible_with_xray":true}},
		{"type":"external_radiator","id":"task_test_radiator","pos":Vector2i(2, 5)},
		{"type":"external_air_cooler","id":"task_test_air_cooler","pos":Vector2i(3, 5),"extra":{"facing_dir":"right"}},
		{"type":"metal_cooling_block","id":"task_test_cooling_block","pos":Vector2i(4, 5)},
		{"type":"door_terminal","id":"task_test_terminal_main","pos":Vector2i(5, 5),"extra":{"required_connector_level":1,"required_processor_level":1,"target_door_id":"task_test_door_terminal_locked","state":"active","is_powered":true}},
		{"type":"door_terminal","id":"task_test_terminal_unpowered","pos":Vector2i(6, 5),"extra":{"state":"unpowered","is_powered":false}},
		{"type":"door_terminal","id":"task_test_terminal_damaged","pos":Vector2i(1, 6),"extra":{"state":"damaged","damaged":true}},
		{"type":"reinforced_steel_door","id":"task_test_door_terminal_locked","pos":Vector2i(4, 4),"extra":{"is_locked":true,"lock_type":"terminal_lock"}},
		{"type":"steel_door","id":"task_test_door_mechanical","pos":Vector2i(5, 4),"extra":{"is_locked":true,"lock_type":"mechanical_key"}},
		{"type":"energy_door","id":"task_test_door_digital","pos":Vector2i(6, 4),"extra":{"is_locked":true,"lock_type":"digital_key","power_network_id":"task_test_power"}},
		{"type":"titanium_door","id":"task_test_door_password","pos":Vector2i(2, 6),"extra":{"is_locked":true,"lock_type":"password"}},
		{"type":"lifting_platform","id":"task_test_platform_lift","pos":Vector2i(3, 4),"extra":{"platform_id":"task_test_platform_lift","is_powered":false}},
		{"type":"rotating_platform","id":"task_test_platform_rotate","pos":Vector2i(3, 6),"extra":{"platform_id":"task_test_platform_rotate"}},
		{"type":"lifting_platform","id":"task_test_platform_switch","pos":Vector2i(4, 6),"extra":{"platform_id":"task_test_platform_switch","control_type":"switch"}},
		{"type":"rotating_platform","id":"task_test_platform_terminal","pos":Vector2i(5, 6),"extra":{"platform_id":"task_test_platform_terminal","linked_terminal_id":"task_test_terminal_main","requires_terminal_enabled":true}},
		{"type":"power_cable","id":"task_test_xray_route_marker","pos":Vector2i(5, 2),"extra":{"hidden":true,"visible_with_xray":true}},
		{"type":"energy_door","id":"task_test_extraction_door","pos":Vector2i(6, 6),"extra":{"state":"open","is_locked":false,"mission_exit":true,"extraction":true}},
		{"type":"grid_door","id":"task_test_blocked_cable_target","pos":Vector2i(1, 2),"extra":{"state":"jammed","damaged":true}},
		{"type":"outer_wall","id":"task_test_outer_wall_visual","pos":Vector2i(0, 1)},
		{"type":"brick_wall","id":"task_test_brick_wall_visual","pos":Vector2i(2, 2)},
		{"type":"concrete_wall","id":"task_test_concrete_wall_visual","pos":Vector2i(3, 2)},
		{"type":"steel_wall","id":"task_test_steel_wall_visual","pos":Vector2i(4, 2)},
		{"type":"grate_wall","id":"task_test_grate_wall_visual","pos":Vector2i(1, 4)}
	]
	for spec in specs:
		var obj := WorldObjectCatalogRef.create_world_object(String(spec.get("type", "")), String(spec.get("id", "")))
		if obj.is_empty():
			warnings.append("catalog_create_failed_%s" % String(spec.get("id", "")))
			continue
		obj["position"] = Vector2i(spec.get("pos", Vector2i.ZERO))
		var extra: Dictionary = spec.get("extra", {})
		for key in extra.keys():
			obj[String(key)] = extra[key]
		objects.append(obj)
	var items_by_cell: Dictionary = {}
	var fuse := WorldObjectCatalogRef.create_world_object("fuse", "task_test_item_fuse")
	if fuse.is_empty():
		warnings.append("catalog_create_failed_task_test_item_fuse")
	else:
		items_by_cell[Vector2i(1, 1)] = [fuse]
	var repair := WorldObjectCatalogRef.create_world_object("repair_kit", "task_test_item_repair_kit")
	if repair.is_empty():
		warnings.append("catalog_create_failed_task_test_item_repair_kit")
	else:
		items_by_cell[Vector2i(1, 3)] = [repair]
	var cable_reel := WorldObjectCatalogRef.create_world_object("power_cable_reel", "task_test_cable_reel")
	if cable_reel.is_empty():
		warnings.append("catalog_create_failed_task_test_cable_reel")
	else:
		items_by_cell[Vector2i(2, 3)] = [cable_reel]
	var mech_key := WorldObjectCatalogRef.create_world_object("mechanical_keycard", "task_test_item_mechanical_keycard")
	if mech_key.is_empty():
		warnings.append("catalog_create_failed_task_test_item_mechanical_keycard")
	else:
		items_by_cell[Vector2i(2, 4)] = [mech_key]
	var opened_key := WorldObjectCatalogRef.create_world_object("digital_key", "task_test_item_digital_key_opened")
	if opened_key.is_empty():
		warnings.append("catalog_create_failed_task_test_item_digital_key_opened")
	else:
		opened_key["digital_state"] = "opened"
	var enc_key := WorldObjectCatalogRef.create_world_object("digital_key", "task_test_item_digital_key_encrypted")
	if enc_key.is_empty():
		warnings.append("catalog_create_failed_task_test_item_digital_key_encrypted")
	else:
		enc_key["digital_state"] = "encrypted"
	var dmg_key := WorldObjectCatalogRef.create_world_object("digital_key", "task_test_item_digital_key_damaged")
	if dmg_key.is_empty():
		warnings.append("catalog_create_failed_task_test_item_digital_key_damaged")
	else:
		dmg_key["digital_state"] = "damaged"
	items_by_cell[Vector2i(2, 5)] = [opened_key, enc_key, dmg_key].filter(func(it: Dictionary) -> bool: return not it.is_empty())
	var access_code := WorldObjectCatalogRef.create_world_object("access_code", "task_test_item_access_code")
	if access_code.is_empty():
		warnings.append("catalog_create_failed_task_test_item_access_code")
	else:
		items_by_cell[Vector2i(3, 5)] = [access_code]
	return {"objects": objects, "items_by_cell": items_by_cell, "warnings": warnings}

func set_grid_manager_ref(value: Node) -> void:
	grid_manager = value

# region Scenario validation
func validate_world_object_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var ids := {}
	var occupied_cells := {}
	var turret_1: Dictionary = {}
	for object_data in mission_world_objects:
		var object_id := _wo_id(object_data)
		if not object_id.is_empty():
			ids[object_id] = true
		if object_id == "turret_1":
			turret_1 = object_data
	for object_data in mission_world_objects:
		var object_id := _wo_id(object_data)
		var pos := _wo_pos(object_data)
		if _wo_group(object_data) != "item":
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
		var turret_cell := _wo_pos(turret_1)
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
# endregion

func _should_assign_main_power_network(object_data: Dictionary) -> bool:
	var object_type := _wo_type(object_data)
	var object_group := _wo_group(object_data)
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
	mission_world_objects = WorldObjectCatalogRef.create_test_set()
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
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
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
	var object_data := WorldObjectCatalogRef.create_world_object(object_type, object_id)
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
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
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
		var scan_text := ScanSystemRef.get_scan_display_text(object_data, "visor")
		print("[WorldObject] %s (%s) state=%s" % [object_data.get("display_name", "Unknown"), object_data.get("object_type", ""), object_data.get("state", "")])
		print("[Scan] %s" % scan_text)

func debug_try_action(target_id: String, action_type: String, module_id: String = "") -> Dictionary:
	var target := _find_object(target_id)
	if target.is_empty():
		return {"success": false, "message": "Target not found.", "effects": []}
	var actor := {
		"processor_level": 1,
		"connector_level": 1,
		"manipulator_level": 1,
		"wired_connector_level": 1,
		"optical_connector_level": 1,
		"wireless_connector_level": 1,
		"high_bandwidth_connector_level": 1,
		"firewall_module_v1": false,
		"manipulator_occupied": false,
		"pocket_full": false,
		"power_class": "scout",
		"magnetic_path_blocked": false,
		"target_is_grate": false
	}
	var module := {"id": module_id}
	var result := InteractionSystemRef.apply_action(actor, module, target, action_type)
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


func get_runtime_cell_state(cell: Vector2i) -> Dictionary:
	var state: Dictionary = {
		"cell": cell,
		"in_bounds": false,
		"tile_type": -1,
		"tile_name": "",
		"static_walkable": false,
		"has_object": false,
		"object_id": "",
		"object_type": "",
		"object_group": "",
		"display_name": "",
		"state": "",
		"is_open": false,
		"is_locked": false,
		"is_powered": false,
		"blocks_movement": false,
		"requires_key": false,
		"required_key_id": "",
		"lock_type": "",
		"power_network_id": "",
		"control_source_id": "",
		"is_passable": false,
		"block_reason": "out_of_bounds",
		"visual_profile": ""
	}
	if grid_manager == null or not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		return state

	state["in_bounds"] = true
	state["block_reason"] = ""
	if grid_manager.has_method("get_tile"):
		var tile_type: int = int(grid_manager.call("get_tile", cell))
		state["tile_type"] = tile_type
		if grid_manager.has_method("get_tile_name"):
			state["tile_name"] = String(grid_manager.call("get_tile_name", tile_type))
	if grid_manager.has_method("is_walkable"):
		state["static_walkable"] = bool(grid_manager.call("is_walkable", cell))

	var object_data: Dictionary = get_world_object_at_cell(cell)
	if not object_data.is_empty():
		state["has_object"] = true
		state["object_id"] = String(object_data.get("id", ""))
		state["object_type"] = String(object_data.get("object_type", ""))
		state["object_group"] = String(object_data.get("object_group", ""))
		state["display_name"] = String(object_data.get("display_name", ""))
		state["state"] = String(object_data.get("state", "")).to_lower()
		state["is_open"] = bool(object_data.get("is_open", false))
		state["is_locked"] = bool(object_data.get("is_locked", false)) or bool(object_data.get("locked", false))
		state["is_powered"] = bool(object_data.get("is_powered", false))
		state["blocks_movement"] = bool(object_data.get("blocks_movement", false))
		state["requires_key"] = bool(object_data.get("requires_key", false))
		state["required_key_id"] = String(object_data.get("required_key_id", ""))
		state["lock_type"] = String(object_data.get("lock_type", ""))
		state["power_network_id"] = String(object_data.get("power_network_id", ""))
		state["control_source_id"] = String(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", ""))))
		state["visual_profile"] = String(object_data.get("visual_profile", ""))

	var tile_type_value: int = int(state.get("tile_type", -1))
	var tile_is_wall: bool = tile_type_value == GridManager.TILE_WALL
	var tile_is_door: bool = tile_type_value == GridManager.TILE_DOOR or tile_type_value == GridManager.TILE_DIGITAL_DOOR or tile_type_value == GridManager.TILE_POWERED_GATE
	var object_state: String = String(state.get("state", ""))
	var is_open_state: bool = object_state == "open" or object_state == "opened"
	var canonical_open: bool = bool(state.get("is_open", false)) or is_open_state
	if tile_is_wall:
		state["is_passable"] = false
		state["block_reason"] = "wall"
		return state
	if tile_is_door:
		if canonical_open:
			state["is_passable"] = true
			state["block_reason"] = ""
			return state
		state["is_passable"] = false
		if object_state == "locked" or bool(state.get("is_locked", false)):
			state["block_reason"] = "door_locked"
		elif object_state == "unpowered":
			state["block_reason"] = "door_unpowered"
		elif object_state == "damaged" or object_state == "broken" or object_state == "destroyed":
			state["block_reason"] = "door_damaged"
		else:
			state["block_reason"] = "door_closed"
		return state
	if bool(state.get("has_object", false)) and bool(state.get("blocks_movement", false)):
		state["is_passable"] = false
		state["block_reason"] = "blocked_by_object"
		return state
	state["is_passable"] = bool(state.get("static_walkable", false))
	if not bool(state.get("is_passable", false)):
		state["block_reason"] = "tile_blocked"
	return state

func is_runtime_cell_passable(cell: Vector2i) -> bool:
	var state: Dictionary = get_runtime_cell_state(cell)
	return bool(state.get("is_passable", false))

func get_runtime_cell_block_reason(cell: Vector2i) -> String:
	var state: Dictionary = get_runtime_cell_state(cell)
	return String(state.get("block_reason", ""))

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
	var result: Array[Dictionary] = []
	var raw_items: Array = Array(cell_items.get(cell, []))
	for item_variant in raw_items:
		if item_variant is Dictionary:
			result.append(Dictionary(item_variant))
	return result

func add_item_at_cell(cell: Vector2i, item_data: Dictionary) -> void:
	item_data["position"] = cell
	var items: Array[Dictionary] = get_items_at_cell(cell)
	items.append(item_data)
	cell_items[cell] = items
	if not mission_world_objects.has(item_data):
		mission_world_objects.append(item_data)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var items: Array[Dictionary] = get_items_at_cell(cell)
	if items.is_empty():
		return {}
	var item: Dictionary = items.pop_front()
	cell_items[cell] = items
	mission_world_objects.erase(item)
	return item

func get_map_constructor_prefab_catalog() -> Array[Dictionary]:
	return [
		{"category":"Floors","id":"floor"},{"category":"Floors","id":"stepped_floor"},
		{"category":"Walls","id":"outer_wall"},{"category":"Walls","id":"brick_wall"},{"category":"Walls","id":"concrete_wall"},{"category":"Walls","id":"steel_wall"},{"category":"Walls","id":"grate_wall"},
		{"category":"Doors","id":"mechanical_door"},{"category":"Doors","id":"digital_door"},{"category":"Doors","id":"powered_gate"},
		{"category":"Terminals","id":"information_terminal"},{"category":"Terminals","id":"control_terminal"},
		{"category":"Power","id":"power_source_class_1"},{"category":"Power","id":"power_socket"},{"category":"Power","id":"power_cable"},{"category":"Power","id":"circuit_switch"},{"category":"Power","id":"fuse_box"},
		{"category":"Items","id":"mechanical_key"},{"category":"Items","id":"digital_key"},{"category":"Items","id":"access_code"}
	]

func can_place_map_constructor_prefab(prefab_id: String, cell: Vector2i) -> Dictionary:
	var result := {"ok": false, "message": "Cannot place prefab.", "object_id": "", "warnings": []}
	if grid_manager == null or not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		result["message"] = "Out of bounds."
		return result
	if active_bipob_ref != null and Vector2i(active_bipob_ref.get("grid_position", Vector2i(-1, -1))) == cell:
		result["message"] = "Cannot place under Bipob."
		return result
	var existing: Dictionary = get_world_object_at_cell(cell)
	if MAP_CONSTRUCTOR_SOLID_PREFABS.has(prefab_id) and not existing.is_empty():
		var existing_type: String = String(existing.get("object_type", ""))
		if MAP_CONSTRUCTOR_SOLID_PREFABS.has(existing_type):
			result["message"] = "Cell already has solid object."
			return result
	result["ok"] = true
	result["message"] = "Placement possible."
	return result

func place_map_constructor_prefab(prefab_id: String, cell: Vector2i) -> Dictionary:
	var check := can_place_map_constructor_prefab(prefab_id, cell)
	if not bool(check.get("ok", false)):
		return check
	var result := {"ok": true, "message": "Placed %s." % prefab_id, "object_id": "", "warnings": []}
	if prefab_id == "floor":
		grid_manager.call("set_tile", cell, GridManager.TILE_FLOOR)
		return result
	if prefab_id == "stepped_floor":
		grid_manager.call("set_tile", cell, GridManager.TILE_STEPPED_FLOOR)
		return result
	if prefab_id.ends_with("_wall") or prefab_id == "outer_wall":
		grid_manager.call("set_tile", cell, GridManager.TILE_WALL)
	elif prefab_id == "mechanical_door":
		grid_manager.call("set_tile", cell, GridManager.TILE_DOOR)
	elif prefab_id == "digital_door":
		grid_manager.call("set_tile", cell, GridManager.TILE_DIGITAL_DOOR)
	elif prefab_id == "powered_gate":
		grid_manager.call("set_tile", cell, GridManager.TILE_POWERED_GATE)
	var object_id: String = "mapedit_%s_%d" % [prefab_id, _map_constructor_runtime_object_seq]
	_map_constructor_runtime_object_seq += 1
	var object_data: Dictionary = {"id": object_id, "object_type": prefab_id, "position": cell, "display_name": prefab_id.capitalize(), "state": "active"}
	set_world_object_at_cell(cell, object_data)
	result["object_id"] = object_id
	return result

func remove_map_constructor_object_at_cell(cell: Vector2i) -> Dictionary:
	var result := {"ok": false, "message": "Nothing to remove.", "object_id": "", "warnings": []}
	var existing: Dictionary = get_world_object_at_cell(cell)
	if existing.is_empty():
		return result
	result["ok"] = true
	result["object_id"] = String(existing.get("id", ""))
	result["message"] = "Removed object."
	remove_world_object_at_cell(cell)
	return result

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
	var from_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	result["from"] = from_cell
	if not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data):
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
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	result["success"] = true
	result["message"] = "Moved %s." % String(object_data.get("display_name", "Object"))
	return result

func refresh_world_cooling_received() -> void:
	for object_data in mission_world_objects:
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var target_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var cooling_received := WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		object_data["cooling_received"] = cooling_received
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)

func preview_cooling_application(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var report := {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": []}
	for object_data in mission_world_objects:
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		var object_id := String(object_data.get("id", ""))
		var previous_cooling := maxi(0, int(object_data.get("cooling_received", 0)))
		var previous_heat := maxi(0, int(object_data.get("current_heat", 0)))
		var previous_state := String(object_data.get("state", ""))
		var target_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var next_cooling := WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		var projected_heat := maxi(0, int(object_data.get("working_heat", previous_heat)) + int(object_data.get("heat_from_connections", 0)) - next_cooling)
		var threshold := maxi(0, int(object_data.get("overheat_threshold", 0)))
		var next_state := previous_state
		if threshold > 0 and projected_heat >= threshold:
			next_state = "overheated"
		elif previous_state == "overheated":
			next_state = String(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active")))
		var reason := "stable"
		if next_cooling > 0:
			reason = "cooled"
		report["targets"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
		if previous_cooling != next_cooling or previous_heat != projected_heat or previous_state != next_state:
			report["changes"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
	for object_data in mission_world_objects:
		if String(object_data.get("object_group", "")) != "cooling":
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		report["cooling_sources"].append({"object_id": String(object_data.get("id", "")), "cooling_output": maxi(0, int(object_data.get("cooling_output", 0))), "cooling_device_type": String(object_data.get("cooling_device_type", "")), "facing_dir": String(object_data.get("facing_dir", "")), "state": String(object_data.get("state", ""))})
	return report

func apply_cooling_application(filter: String = "") -> Dictionary:
	var preview := preview_cooling_application(filter)
	for target_variant in preview.get("targets", []):
		if typeof(target_variant) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = target_variant
		var object_id := String(target.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			continue
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		object_data["cooling_received"] = maxi(0, int(target.get("cooling_received", 0)))
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
	return preview

func update_cooling_for_network_or_area(filter: String = "") -> Dictionary:
	return apply_cooling_application(filter)

func get_cooling_debug_report_text(filter: String = "") -> String:
	var preview := preview_cooling_application(filter)
	var lines: Array[String] = []
	lines.append("Cooling sources:")
	for source_variant in preview.get("cooling_sources", []):
		var source: Dictionary = source_variant
		lines.append("- %s type=%s output=%d facing=%s state=%s" % [String(source.get("object_id", "")), String(source.get("cooling_device_type", "")), int(source.get("cooling_output", 0)), String(source.get("facing_dir", "-")), String(source.get("state", ""))])
	lines.append("Cooling targets:")
	for target_variant in preview.get("targets", []):
		var target: Dictionary = target_variant
		lines.append("- %s heat %d->%d cooling=%d state %s->%s reason=%s" % [String(target.get("object_id", "")), int(target.get("previous_heat", 0)), int(target.get("new_heat", 0)), int(target.get("cooling_received", 0)), String(target.get("previous_state", "")), String(target.get("new_state", "")), String(target.get("reason", ""))])
	lines.append("Preview changes:")
	lines.append("- %d" % Array(preview.get("changes", [])).size())
	lines.append("Warnings:")
	for warning in preview.get("warnings", []):
		lines.append("- %s" % String(warning))
	return "\n".join(lines)

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

func can_threat_detect_bipop(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> bool:
	return bool(get_threat_detection_result(threat, bipob_cell, grid_manager_ref).get("detected", false))

func get_threat_detection_result(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> Dictionary:
	var result := {"detected":false, "threat_id":String(threat.get("id", "")), "threat_name":String(threat.get("display_name", "Threat")), "detection_mode":"", "distance":999, "message":"Threat cannot detect Bipop."}
	if threat.is_empty() or not is_threat_active(threat):
		result["message"] = "Threat inactive."
		return result
	var threat_position := Vector2i(threat.get("position", Vector2i(-1, -1)))
	var distance: int = abs(threat_position.x - bipob_cell.x) + abs(threat_position.y - bipob_cell.y)
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
		if _can_detect_by_mode(mode, threat_position, bipob_cell, grid_manager_ref):
			result["detected"] = true
			result["detection_mode"] = mode
			result["message"] = "%s detected Bipop by %s." % [result["threat_name"], mode]
			return result
	result["message"] = "%s has no clear detection path." % result["threat_name"]
	return result

func _can_detect_by_mode(mode: String, from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node) -> bool:
	if grid_manager_ref == null:
		return false
	return _has_cardinal_clear_path(from_cell, to_cell, grid_manager_ref, mode, mode != "vision")

func _has_cardinal_clear_path(from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node, scan_type: String, allow_wall_pass: bool) -> bool:
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
		if not grid_manager_ref.is_in_bounds(current):
			return false
		var tile := int(grid_manager_ref.get_tile(current))
		if tile == grid_manager_ref.TILE_WALL:
			return false
		var blocker := get_world_object_at_cell(current)
		if blocker.is_empty():
			current += step
			continue
		if bool(blocker.get("blocks_vision", false)):
			if not allow_wall_pass:
				return false
			if not ScanSystemRef.can_scan_through_wall(blocker, scan_type):
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

func _get_power_event_filter_for_object(object_data: Dictionary) -> String:
	var network_id := _get_power_network_id(object_data)
	if not network_id.is_empty():
		return network_id
	var object_id := String(object_data.get("id", "")).strip_edges()
	if not object_id.is_empty():
		return object_id
	return ""

func _is_power_source_object(object_data: Dictionary) -> bool:
	var object_type := String(object_data.get("object_type", "")).strip_edges().to_lower()
	var power_role := String(object_data.get("power_role", "")).strip_edges().to_lower()
	return object_type == "power_source" or power_role == "source" or object_type in ["power_source_class_1", "power_source_class_2", "power_source_class_3"]

func _collect_power_network_objects() -> Dictionary:
	var power_objects: Array[Dictionary] = []
	var networks := {}
	var sources_by_id := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		power_objects.append(object_data)
		var network_id := _get_power_network_id(object_data)
		if not networks.has(network_id):
			networks[network_id] = []
		networks[network_id].append(object_data)
		if _is_power_source_object(object_data):
			var source_id := String(object_data.get("id", "")).strip_edges()
			if not source_id.is_empty():
				sources_by_id[source_id] = object_data
	return {"objects": power_objects, "networks": networks, "sources_by_id": sources_by_id}

func _is_power_source_available(source: Dictionary) -> bool:
	if not _is_power_source_object(source):
		return false
	var state := String(source.get("state", "")).strip_edges().to_lower()
	var is_powered := bool(source.get("is_powered", false))
	var damaged_or_broken := bool(source.get("damaged", false)) or bool(source.get("broken", false))
	if state in ["overheated", "damaged", "broken", "destroyed"]:
		return false
	if damaged_or_broken:
		return false
	if is_powered:
		return true
	return state in ["active", "switch_on", "connected"]

func _normalize_power_gate_text(raw_value: Variant) -> String:
	return String(raw_value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

func _normalize_power_consumer_text(raw_value: Variant) -> String:
	return _normalize_power_gate_text(raw_value)

func _is_terminal_object(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	if object_group == "terminal":
		return true
	return object_type in ["terminal", "door_terminal", "information_terminal", "info_terminal", "cooling_terminal", "platform_terminal", "elevator_terminal", "turret_terminal", "security_terminal"]

func _is_terminal_powered_for_interaction(object_data: Dictionary) -> bool:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	if bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		return false
	if state in ["damaged", "broken", "destroyed", "overheated", "unpowered"]:
		return false
	if object_data.has("is_powered"):
		return bool(object_data.get("is_powered", true))
	return true

func _is_power_reactive_door_object(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	var material := _normalize_power_consumer_text(object_data.get("material", ""))
	if object_type in ["energy_door", "grid_door", "power_door", "electromagnetic_door"]:
		return true
	if object_group == "door" and (material in ["electromagnetic", "energy", "grid"] or object_type.find("electromagnetic") != -1 or object_type.find("energy") != -1 or object_type.find("grid") != -1):
		return true
	return false

func _is_platform_power_consumer(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	return object_group == "platform" or object_type in ["platform", "lifting_platform", "rotating_platform"]

func update_terminal_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	var previous_state := String(object_data.get("state", ""))
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_terminal"}
	if not _is_terminal_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "overheated"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "terminal_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "damaged", "broken", "destroyed", "overheated"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "terminal_unpowered"
		return report
	if state == "unpowered":
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "damaged", "broken", "destroyed", "overheated"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "terminal_power_restored"
		return report
	report["reason"] = "terminal_already_powered"
	return report

func update_power_door_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := String(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_power_reactive_door"}
	if not _is_power_reactive_door_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "sealed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "door_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "door_unpowered"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			restore_state = "closed"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "door_power_restored"
		return report
	report["reason"] = "door_already_powered"
	return report

func update_platform_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := String(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": String(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_platform_consumer"}
	if not _is_platform_power_consumer(object_data):
		return report
	if state in ["damaged", "broken", "destroyed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		report["reason"] = "platform_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "platform_unpowered"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "platform_power_restored"
		return report
	report["reason"] = "platform_already_powered"
	return report

func _get_power_gate_state(object_data: Dictionary) -> Dictionary:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if state in ["cut", "damaged", "broken"] or damaged_or_broken:
		if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "fuse_box", "power_cable", "cable", "cable_reel"]:
			return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state if not state.is_empty() else "damaged"}
	var closed_states := {}
	var open_states := {}
	var is_gate := false
	if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker"]:
		is_gate = true
		closed_states = {"switch_on": true, "on": true, "active": true, "closed": true}
		open_states = {"switch_off": true, "off": true, "inactive": true, "open": true}
	elif object_type == "fuse_box":
		is_gate = true
		closed_states = {"installed": true, "fuse_installed": true, "active": true}
		open_states = {"empty": true, "missing_fuse": true, "open": true}
	elif object_type in ["power_cable", "cable", "cable_reel"]:
		is_gate = true
		closed_states = {"connected": true, "installed": true, "active": true}
		open_states = {"disconnected": true, "cut": true, "damaged": true, "broken": true}
	if not is_gate:
		return {"is_gate": false, "gate_type": "", "is_closed": true, "reason": "not_gate"}
	if open_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state}
	if closed_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": state}
	return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": "default_closed"}

func _is_power_gate_closed(object_data: Dictionary) -> bool:
	var gate_state := _get_power_gate_state(object_data)
	return bool(gate_state.get("is_closed", true))

func _resolve_power_graph_filter_to_network_id(filter: String) -> String:
	var filter_text := filter.strip_edges()
	if filter_text.is_empty():
		return ""
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	if networks.has(filter_text):
		return filter_text
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		var network_objects: Array = networks.get(network_id, [])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if String(object_data.get("id", "")).strip_edges() == filter_text:
				return network_id
	return filter_text

func _is_power_load_gate_object(object_data: Dictionary) -> bool:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	return object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "fuse_box", "power_cable", "cable", "cable_reel"]

func _is_power_load_consumer_object(object_data: Dictionary) -> bool:
	if _is_power_source_object(object_data):
		return false
	if _is_power_load_gate_object(object_data):
		return false
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if damaged_or_broken or state in ["damaged", "broken", "destroyed"]:
		return false
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var object_group := _normalize_power_gate_text(object_data.get("object_group", ""))
	if bool(object_data.get("consumes_power", false)):
		return true
	if object_group == "terminal" or object_type in ["terminal", "door_terminal", "information_terminal"]:
		return true
	if object_type in ["energy_door", "energy_wall", "electromagnetic_door", "electromagnetic_wall", "grid_door", "grid_wall"]:
		return true
	if object_type in ["platform", "lifting_platform", "rotating_platform", "lift"]:
		return true
	if object_type in ["light", "camera", "alarm", "turret"]:
		return true
	if object_type.find("cooling") != -1:
		return true
	return false

func _get_power_source_capacity_for_load(source: Dictionary) -> int:
	if source.has("source_capacity"):
		return maxi(1, int(source.get("source_capacity", 1)))
	if source.has("allowed_socket_connections"):
		return maxi(1, int(source.get("allowed_socket_connections", 1)))
	if source.has("allowed_connections"):
		return maxi(1, int(source.get("allowed_connections", 1)))
	if source.has("source_class"):
		var source_class := int(source.get("source_class", 1))
		return maxi(1, mini(3, source_class))
	var object_type := String(source.get("object_type", "")).strip_edges().to_lower()
	if object_type == "power_source_class_1":
		return 1
	if object_type == "power_source_class_2":
		return 2
	if object_type == "power_source_class_3":
		return 3
	if object_type.find("class_2") != -1:
		return 2
	if object_type.find("class_3") != -1:
		return 3
	return 1

func preview_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			var overheat_threshold := int(source.get("overheat_threshold", 0))
			var current_heat := int(source.get("current_heat", 0))
			var source_overloaded := consumer_count > source_capacity
			var heat_from_connections := maxi(0, consumer_count - source_capacity)
			var projected_heat := maxi(0, current_heat - int(source.get("cooling_received", 0))) + int(source.get("working_heat", 0)) + heat_from_connections
			var projected_state := String(source.get("state", "")).strip_edges().to_lower()
			if overheat_threshold > 0 and projected_heat >= overheat_threshold:
				projected_state = "overheated"
			source_reports.append({
				"object_id": String(source.get("id", "")),
				"network_id": network_id,
				"source_load": consumer_count,
				"source_capacity": source_capacity,
				"source_overloaded": source_overloaded,
				"current_heat": projected_heat,
				"overheat_threshold": overheat_threshold,
				"state": projected_state
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func update_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			source["source_load"] = consumer_count
			source["source_capacity"] = source_capacity
			source["source_overloaded"] = consumer_count > source_capacity
			source["heat_from_connections"] = maxi(0, consumer_count - source_capacity)
			WorldObjectCatalogRef.update_world_object_heat_state(source)
			source_reports.append({
				"object_id": String(source.get("id", "")),
				"network_id": network_id,
				"source_load": int(source.get("source_load", 0)),
				"source_capacity": int(source.get("source_capacity", source_capacity)),
				"source_overloaded": bool(source.get("source_overloaded", false)),
				"current_heat": int(source.get("current_heat", 0)),
				"overheat_threshold": int(source.get("overheat_threshold", 0)),
				"state": String(source.get("state", ""))
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func preview_power_graph_state_application(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var filter_text := filter.strip_edges()
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter_text)
	var source_load_report := preview_power_source_load_heat_for_network(filter_text)
	var warnings: Array[String] = []
	var changes: Array[Dictionary] = []
	var blocked_entries: Array[Dictionary] = []
	var sources: Array[Dictionary] = []
	var nodes: Array[String] = []
	var reachable: Array[String] = []
	var result: Dictionary = {
		"filter": filter_text,
		"resolved_filter": resolved_filter,
		"sources": sources,
		"nodes": nodes,
		"reachable_object_ids": reachable,
		"blocked": blocked_entries,
		"changes": changes,
		"warnings": warnings,
		"source_load_report": source_load_report
	}
	warnings.append("Power graph MVP uses network-level gate blocking; adjacency traversal not available yet.")
	for network_id_variant in networks.keys():
		var network_id := String(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var has_available_source := false
		var network_open_gate := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			if not object_id.is_empty():
				nodes.append(object_id)
			if _is_power_source_object(object_data) and _is_power_source_available(object_data):
				has_available_source = true
				sources.append({"object_id": object_id, "network_id": network_id})
			var gate_state := _get_power_gate_state(object_data)
			if bool(gate_state.get("is_gate", false)) and not bool(gate_state.get("is_closed", true)):
				network_open_gate = true
				blocked_entries.append({
					"object_id": object_id,
					"network_id": network_id,
					"gate_type": String(gate_state.get("gate_type", "")),
					"reason": String(gate_state.get("reason", "blocked_by_gate"))
				})
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			var object_id := String(object_data.get("id", "")).strip_edges()
			var current_is_powered := bool(object_data.get("is_powered", false))
			var state := _normalize_power_gate_text(object_data.get("state", ""))
			var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var preview_is_powered := current_is_powered
			var reason := "no_powered_source"
			if state == "cut":
				preview_is_powered = false
				reason = "cut"
			elif state == "broken" or damaged_or_broken:
				preview_is_powered = false
				reason = "broken" if state == "broken" else "damaged"
			elif state == "damaged":
				preview_is_powered = false
				reason = "damaged"
			elif not has_available_source:
				preview_is_powered = false
				reason = "no_powered_source"
			elif network_open_gate:
				preview_is_powered = false
				reason = "blocked_by_gate"
			else:
				preview_is_powered = true
				reason = "graph_powered_source_reachable"
			if preview_is_powered:
				reachable.append(object_id)
			if preview_is_powered == current_is_powered:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	return result

func get_power_graph_preview_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphPreview: filter=%s sources=%d reachable=%d blocked=%d changes=%d warnings=%d" % [
		String(preview.get("filter", "")),
		(preview.get("sources", []) as Array).size(),
		(preview.get("reachable_object_ids", []) as Array).size(),
		(preview.get("blocked", []) as Array).size(),
		(preview.get("changes", []) as Array).size(),
		(preview.get("warnings", []) as Array).size()
	])
	for source_variant in preview.get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		lines.append("SOURCE: object=%s network=%s" % [String(source.get("object_id", "")), String(source.get("network_id", ""))])
	for blocked_variant in preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		lines.append("BLOCKED: object=%s network=%s gate=%s reason=%s" % [String(blocked.get("object_id", "")), String(blocked.get("network_id", "")), String(blocked.get("gate_type", "")), String(blocked.get("reason", ""))])
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [String(change.get("object_id", "")), String(change.get("network_id", "")), str(bool(change.get("current_is_powered", false))).to_lower(), str(bool(change.get("preview_is_powered", false))).to_lower(), String(change.get("reason", ""))])
	for warning_variant in preview.get("warnings", []):
		lines.append("WARNING: %s" % String(warning_variant))
	return "\n".join(lines)

func apply_power_graph_state_from_preview(filter: String = "") -> Dictionary:
	var source_load_report := update_power_source_load_heat_for_network(filter)
	var preview := preview_power_graph_state_application(filter)
	var applied_changes: Array[Dictionary] = []
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := String(change.get("object_id", "")).strip_edges()
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty() or _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var next_is_powered := bool(change.get("preview_is_powered", false))
		var state := _normalize_power_gate_text(object_data.get("state", ""))
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if next_is_powered and (state in ["damaged", "broken", "cut"] or damaged_or_broken):
			next_is_powered = false
		if previous_is_powered == next_is_powered:
			continue
		object_data["is_powered"] = next_is_powered
		if next_is_powered:
			object_data.erase("power_unavailable_reason")
		else:
			object_data["power_unavailable_reason"] = String(change.get("reason", ""))
		var applied_change := {"object_id": object_id, "network_id": String(change.get("network_id", "")), "previous_is_powered": previous_is_powered, "new_is_powered": next_is_powered, "reason": String(change.get("reason", ""))}
		var consumer_state_report := {}
		if _is_terminal_object(object_data):
			consumer_state_report = update_terminal_power_state_from_is_powered(object_data)
		elif _is_power_reactive_door_object(object_data):
			consumer_state_report = update_power_door_state_from_is_powered(object_data)
		elif _is_platform_power_consumer(object_data):
			consumer_state_report = update_platform_power_state_from_is_powered(object_data)
		if not consumer_state_report.is_empty():
			applied_change["consumer_state_report"] = consumer_state_report
		applied_changes.append(applied_change)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": preview.get("warnings", []), "source_load_report": source_load_report}

func execute_power_graph_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_graph_state_from_preview(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphApply: filter=%s applied=%d warnings=%d" % [filter, int(report.get("applied", 0)), (report.get("warnings", []) as Array).size()])
	for change_variant in report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var line := "APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [String(change.get("object_id", "")), String(change.get("network_id", "")), str(bool(change.get("previous_is_powered", false))).to_lower(), str(bool(change.get("new_is_powered", false))).to_lower(), String(change.get("reason", ""))]
		var consumer_state_report_variant: Variant = change.get("consumer_state_report", {})
		if consumer_state_report_variant is Dictionary:
			var consumer_state_report: Dictionary = consumer_state_report_variant
			if bool(consumer_state_report.get("changed", false)):
				line += " state %s -> %s" % [String(consumer_state_report.get("previous_state", "")), String(consumer_state_report.get("new_state", ""))]
		lines.append(line)
	for warning_variant in report.get("warnings", []):
		lines.append("WARNING: %s" % String(warning_variant))
	return "\n".join(lines)

func preview_power_network_state_application(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = collected.get("objects", [])
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	var filter_text := filter.strip_edges().to_lower()
	var all_network_ids: Array[String] = []
	for network_id_variant in networks.keys():
		all_network_ids.append(String(network_id_variant))
	all_network_ids.sort()
	for network_id in all_network_ids:
		var network_objects: Array = networks.get(network_id, [])
		var network_has_available_source := false
		var has_powered_consumer := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source_candidate: Dictionary = object_variant
			if not _is_power_source_object(source_candidate):
				continue
			if _is_power_source_available(source_candidate):
				network_has_available_source = true
			else:
				var source_state := String(source_candidate.get("state", "")).strip_edges().to_lower()
				var source_damaged := bool(source_candidate.get("damaged", false)) or bool(source_candidate.get("broken", false))
				if source_state in ["overheated", "damaged"] or source_damaged:
					var source_id := String(source_candidate.get("id", "")).strip_edges()
					warnings.append("Source %s in network %s is unavailable: overheated/damaged." % [source_id, network_id if not network_id.is_empty() else "-"])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			if bool(object_data.get("is_powered", false)):
				has_powered_consumer = true
				break
		if has_powered_consumer and not network_has_available_source:
			warnings.append("Network %s has powered consumers but no available source." % (network_id if not network_id.is_empty() else "-"))
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := String(object_data.get("id", "")).strip_edges()
			var object_state := String(object_data.get("state", "")).strip_edges().to_lower()
			var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var current_is_powered := bool(object_data.get("is_powered", false))
			var preview_is_powered := current_is_powered
			var reason := "source"
			if _is_power_source_object(object_data):
				preview_is_powered = current_is_powered
				reason = "source"
			elif object_state == "damaged" or object_damaged:
				preview_is_powered = false
				reason = "damaged"
			elif object_state == "overheated":
				preview_is_powered = false
				reason = "overheated"
			else:
				preview_is_powered = network_has_available_source
				reason = "powered_source_available" if network_has_available_source else "no_powered_source"
			var connected_source_id := String(object_data.get("connected_power_source_id", "")).strip_edges()
			if not connected_source_id.is_empty() and not sources_by_id.has(connected_source_id):
				warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, connected_source_id])
			if network_id.is_empty():
				warnings.append("Power object %s has no network id." % object_id)
			if preview_is_powered == current_is_powered:
				continue
			var change_line := "object=%s network=%s reason=%s" % [object_id, network_id, reason]
			if not filter_text.is_empty() and change_line.to_lower().find(filter_text) == -1:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	var filtered_warnings: Array[String] = []
	for warning in warnings:
		if filter_text.is_empty() or warning.to_lower().find(filter_text) != -1:
			filtered_warnings.append(warning)
	return {"networks": networks.size(), "objects": power_objects.size(), "changes": changes, "warnings": filtered_warnings}

func get_power_network_state_preview_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkStatePreview: networks=%d objects=%d changes=%d warnings=%d" % [
		int(preview.get("networks", 0)),
		int(preview.get("objects", 0)),
		changes.size(),
		warnings.size()
	])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("CHANGE: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func apply_power_network_state_from_preview(filter: String = "") -> Dictionary:
	var preview := preview_power_network_state_application(filter)
	var preview_changes: Array = preview.get("changes", [])
	var applied_changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := String(change.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			warnings.append("Power apply skipped missing object %s." % object_id)
			continue
		if not _is_power_network_object(object_data):
			warnings.append("Power apply skipped non-power object %s." % object_id)
			continue
		if _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var preview_is_powered := bool(change.get("preview_is_powered", false))
		var object_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		var blocked_from_power_up := object_state in ["damaged", "overheated"] or object_damaged
		var new_is_powered := preview_is_powered
		if blocked_from_power_up and preview_is_powered:
			new_is_powered = false
		if previous_is_powered == new_is_powered:
			continue
		object_data["is_powered"] = new_is_powered
		applied_changes.append({
			"object_id": object_id,
			"network_id": String(change.get("network_id", "")),
			"previous_is_powered": previous_is_powered,
			"new_is_powered": new_is_powered,
			"reason": String(change.get("reason", ""))
		})
	for preview_warning in preview.get("warnings", []):
		var warning_text := String(preview_warning).strip_edges()
		if warning_text.is_empty():
			continue
		warnings.append(warning_text)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": warnings}



func _apply_graph_power_after_world_object_power_change(object_data: Dictionary, reason: String) -> Dictionary:
	var filter := _get_power_event_filter_for_object(object_data)
	return apply_power_network_after_explicit_power_event(reason, filter)

func preview_cable_path(cable_reel_id: String, target_id: String) -> Dictionary:
	var reel := get_world_object_by_id(cable_reel_id.strip_edges())
	var target := get_world_object_by_id(target_id.strip_edges())
	if reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	var reel_cell := WorldObjectCatalogRef.to_world_cell(reel.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var target_cell := WorldObjectCatalogRef.to_world_cell(target.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var path_cells: Array = []
	var x_step := signi(target_cell.x - reel_cell.x)
	var y_step := signi(target_cell.y - reel_cell.y)
	var current := reel_cell
	while current.x != target_cell.x:
		current = Vector2i(current.x + x_step, current.y)
		path_cells.append(current)
	while current.y != target_cell.y:
		current = Vector2i(current.x, current.y + y_step)
		path_cells.append(current)
	return validate_cable_path(reel, target, path_cells)

func validate_cable_path(cable_reel: Dictionary, target: Dictionary, path_cells: Array = []) -> Dictionary:
	if cable_reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	if bool(cable_reel.get("cut", false)):
		return {"valid": false, "reason": "cable_cut", "length": 0, "max_length": 0, "path_cells": path_cells}
	if bool(cable_reel.get("damaged", false)):
		return {"valid": false, "reason": "cable_damaged", "length": 0, "max_length": 0, "path_cells": path_cells}
	if not bool(target.get("can_connect_cable", false)) and String(target.get("object_type", "")) != "power_source":
		return {"valid": false, "reason": "no_socket", "length": 0, "max_length": 0, "path_cells": path_cells}
	var max_length := maxi(1, int(cable_reel.get("max_cable_length", 5)))
	var length := path_cells.size()
	if length > max_length:
		return {"valid": false, "reason": "too_far", "length": length, "max_length": max_length, "path_cells": path_cells}
	for path_cell_variant in path_cells:
		if typeof(path_cell_variant) != TYPE_VECTOR2I:
			continue
		var path_cell: Vector2i = path_cell_variant
		var blocker := get_world_object_at_cell(path_cell)
		if blocker.is_empty():
			continue
		if bool(blocker.get("blocks_movement", false)) or String(blocker.get("state", "")) == "closed":
			return {"valid": false, "reason": "path_blocked", "length": length, "max_length": max_length, "path_cells": path_cells}
	return {"valid": true, "reason": "ok", "length": length, "max_length": max_length, "path_cells": path_cells}

func can_connect_cable_reel_to_target(cable_reel: Dictionary, target: Dictionary) -> Dictionary:
	var path_report := preview_cable_path(String(cable_reel.get("id", "")), String(target.get("id", "")))
	if not bool(path_report.get("valid", false)):
		return path_report
	return {"valid": true, "reason": "ok", "length": int(path_report.get("length", 0)), "max_length": int(path_report.get("max_length", 0)), "path_cells": path_report.get("path_cells", [])}

func connect_cable_reel_to_target(cable_reel_id: String, target_id: String) -> Dictionary:
	var cable_reel := get_world_object_by_id(cable_reel_id.strip_edges())
	var target := get_world_object_by_id(target_id.strip_edges())
	if cable_reel.is_empty() or target.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	var can_connect := can_connect_cable_reel_to_target(cable_reel, target)
	if not bool(can_connect.get("valid", false)):
		return {"success": false, "reason": String(can_connect.get("reason", "target_not_connectable")), "path": can_connect}
	cable_reel["connected"] = true
	cable_reel["disconnected"] = false
	cable_reel["cut"] = false
	cable_reel["state"] = "connected"
	cable_reel["cable_endpoint_a_id"] = String(cable_reel.get("id", ""))
	cable_reel["cable_endpoint_b_id"] = String(target.get("id", ""))
	cable_reel["cable_path_cells"] = can_connect.get("path_cells", [])
	cable_reel["cable_length"] = int(can_connect.get("length", 0))
	cable_reel["cable_max_length"] = int(can_connect.get("max_length", 0))
	var report := _apply_graph_power_after_world_object_power_change(cable_reel, "cable_connected")
	return {"success": true, "reason": "ok", "apply": report, "path": can_connect}

func disconnect_cable_from_target(cable_id_or_reel_id: String, target_id: String = "") -> Dictionary:
	var cable := get_world_object_by_id(cable_id_or_reel_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if not target_id.strip_edges().is_empty() and String(cable.get("cable_endpoint_b_id", "")) != target_id.strip_edges():
		return {"success": false, "reason": "target_not_connectable"}
	cable["connected"] = false
	cable["disconnected"] = true
	cable["state"] = "disconnected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_disconnected")
	return {"success": true, "reason": "ok", "apply": report}

func cut_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	cable["state"] = "cut"
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_cut")
	return {"success": true, "reason": "cable_cut", "apply": report}

func repair_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if not bool(cable.get("cut", false)) and not bool(cable.get("damaged", false)):
		return {"success": false, "reason": "ok"}
	cable["cut"] = false
	cable["damaged"] = false
	cable["connected"] = false
	cable["disconnected"] = true
	cable["state"] = "repaired"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_repaired")
	return {"success": true, "reason": "cable_repaired", "apply": report}

func reconnect_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if bool(cable.get("cut", false)) or bool(cable.get("damaged", false)):
		return {"success": false, "reason": "cable_damaged"}
	cable["connected"] = true
	cable["disconnected"] = false
	cable["state"] = "connected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_reconnected")
	return {"success": true, "reason": "cable_reconnected", "apply": report}

func update_power_source_overheat_recovery_for_network(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var recovered: Array[Dictionary] = []
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if not _is_power_source_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var prev_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var prev_is_powered := bool(object_data.get("is_powered", false))
		var prev_overheated_state_before := String(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active"))).strip_edges().to_lower()
		var prev_damaged_flag := bool(object_data.get("damaged", false))
		var prev_broken_flag := bool(object_data.get("broken", false))
		var prev_destroyed_flag := bool(object_data.get("destroyed", false))
		var prev_current_heat := int(object_data.get("current_heat", 0))
		var prev_threshold := int(object_data.get("overheat_threshold", 0))
		var has_prev_damage_flags := prev_damaged_flag or prev_broken_flag or prev_destroyed_flag
		var prev_state_is_damage := prev_state in ["damaged", "broken", "destroyed"]
		var prev_overheated_state_is_damage := prev_overheated_state_before in ["damaged", "broken", "destroyed"]
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
		var next_state := String(object_data.get("state", "")).strip_edges().to_lower()
		var threshold := int(object_data.get("overheat_threshold", 0))
		var heat := int(object_data.get("current_heat", 0))
		if prev_state != "overheated":
			continue
		if has_prev_damage_flags or prev_state_is_damage or prev_overheated_state_is_damage or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)) or next_state in ["damaged", "broken", "destroyed"]:
			if prev_overheated_state_is_damage:
				object_data["state"] = prev_overheated_state_before
			elif prev_state_is_damage:
				object_data["state"] = prev_state
			elif has_prev_damage_flags and next_state == "active":
				object_data["state"] = "unpowered"
			object_data["is_powered"] = false
			object_data["power_unavailable_reason"] = "source_damage_state"
			warnings.append("Source %s remains unavailable due to source_damage_state." % String(object_data.get("id", "")))
			continue
		if threshold > 0 and heat >= threshold:
			continue
		var restore_state := prev_overheated_state_before
		if restore_state in ["", "unpowered", "overheated", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		object_data["power_unavailable_reason"] = ""
		recovered.append({
			"object_id": String(object_data.get("id", "")),
			"network_id": network_id,
			"previous_state": prev_state,
			"new_state": restore_state,
			"current_heat": heat,
			"overheat_threshold": threshold,
			"previous_is_powered": prev_is_powered,
			"previous_overheated_state_before": prev_overheated_state_before,
			"previous_damage_flags": {"damaged": prev_damaged_flag, "broken": prev_broken_flag, "destroyed": prev_destroyed_flag},
			"previous_current_heat": prev_current_heat,
			"previous_overheat_threshold": prev_threshold
		})
	return {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "recovered": recovered, "warnings": warnings}

func execute_power_source_recovery_apply(filter: String = "") -> Dictionary:
	var recovery := update_power_source_overheat_recovery_for_network(filter)
	var apply := apply_power_network_after_explicit_power_event("source_cooling_recovered", String(recovery.get("resolved_filter", filter)))
	return {"recovery": recovery, "apply": apply}

func apply_power_network_after_explicit_power_event(reason: String = "", filter: String = "") -> Dictionary:
	var report := apply_power_graph_state_from_preview(filter)
	return {
		"event_reason": reason,
		"applied": int(report.get("applied", 0)),
		"changes": report.get("changes", []),
		"warnings": report.get("warnings", [])
	}

func execute_power_event_apply_and_get_report_text(reason: String = "", filter: String = "") -> String:
	var report := apply_power_network_after_explicit_power_event(reason, filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApply: reason=%s applied=%d warnings=%d" % [reason, int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func get_power_event_apply_preview_text(reason: String = "", filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApplyPreview: reason=%s changes=%d warnings=%d" % [reason, changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func execute_power_network_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_network_state_from_preview(filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApply: applied=%d warnings=%d" % [int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

func execute_power_network_apply_debug_command(filter: String = "") -> String:
	return execute_power_network_apply_and_get_report_text(filter)

func get_power_network_apply_debug_preview_text(filter: String = "") -> String:
	return get_power_network_apply_preview_report_text(filter)

func get_power_network_apply_preview_report_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApplyPreview: changes=%d warnings=%d" % [changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			String(change.get("object_id", "")),
			String(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			String(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % String(warning))
	return "\n".join(lines)

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

func _build_power_network_debug_object(object_id: String, object_type: String, network_id: String, overrides: Dictionary = {}) -> Dictionary:
	var object_data := {
		"id": object_id,
		"object_group": "power",
		"object_type": object_type,
		"power_network_id": network_id,
		"state": "active",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 0,
		"connected": false
	}
	for key in overrides.keys():
		object_data[key] = overrides[key]
	return object_data

func validate_power_network_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = collected.get("objects", [])
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var source_ids := {}
	for source_id in sources_by_id.keys():
		source_ids[String(source_id)] = true
	var network_has_powered_source := {}
	for object_data in power_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		var network_id := _get_power_network_id(object_data)
		if network_id.is_empty():
			warnings.append("Power object %s has no network id." % object_id)
		if _is_power_source_object(object_data):
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

func validate_power_network_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var temp_objects: Array[Dictionary] = []
	var temp_ids := {}
	var base_size := mission_world_objects.size()
	var unchanged_snapshot: Array = []
	for object_data in mission_world_objects:
		unchanged_snapshot.append(object_data)
	temp_objects.append(_build_power_network_debug_object("power_debug_source_no_threshold", "power_source", "power_debug_no_threshold", {
		"is_powered": true,
		"current_heat": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheated", "power_source", "power_debug_overheated", {
		"state": "overheated",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 3
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_before_source", "power_cable", "power_debug_order", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_order"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_order", "power_source", "power_debug_order", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_missing_source", "power_cable", "power_debug_missing_source", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_missing"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_limit", "power_source", "power_debug_limit", {
		"allowed_connections": 1,
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_a", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_b", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_generic_connected", "power_source", "power_debug_generic_connected", {
		"allowed_connections": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_generic_connected", "power_cable", "power_debug_generic_connected", {
		"state": "connected",
		"connected": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_negative_heat", "power_cable", "power_debug_negative_heat", {
		"current_heat": -1
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source", "power_source", "power_debug_preview_active", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable", "power_cable", "power_debug_preview_active", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_overheated", "power_source", "power_debug_preview_overheated", {
		"state": "overheated",
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable_overheated", "power_cable", "power_debug_preview_overheated", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_damaged_consumer", "power_source", "power_debug_preview_damaged_consumer", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": false,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged_powered", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_source", "power_source", "power_debug_apply_case_a", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_consumer", "power_cable", "power_debug_apply_case_a", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_source", "power_source", "power_debug_apply_case_b", {
		"is_powered": true,
		"state": "overheated"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_consumer", "power_cable", "power_debug_apply_case_b", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_source", "power_source", "power_debug_apply_case_c", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_consumer", "power_cable", "power_debug_apply_case_c", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_on", "power_source", "power_debug_apply_case_d", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_off", "power_source", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_consumer", "power_cable", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_source", "power_source", "power_debug_event_apply", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_consumer", "power_cable", "power_debug_event_apply", {
		"is_powered": false
	}))
	var debug_switch_object := _build_power_network_debug_object("power_debug_switch_toggle_object", "circuit_switch", "power_debug_switch_toggle", {
		"state": "switch_off",
		"is_powered": false
	})
	temp_objects.append(debug_switch_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_source", "power_source", "power_debug_switch_toggle", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_consumer", "power_cable", "power_debug_switch_toggle", {
		"is_powered": false
	}))
	var debug_fuse_object := _build_power_network_debug_object("power_debug_fuse_box", "fuse_box", "power_debug_fuse_event", {
		"state": "empty",
		"is_powered": false
	})
	temp_objects.append(debug_fuse_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_source", "power_source", "power_debug_fuse_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_consumer", "power_cable", "power_debug_fuse_event", {
		"is_powered": false
	}))
	var debug_cable_object := _build_power_network_debug_object("power_debug_cable_object", "power_cable", "power_debug_cable_event", {
		"state": "disconnected",
		"is_powered": false
	})
	temp_objects.append(debug_cable_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_source", "power_source", "power_debug_cable_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_consumer", "power_socket", "power_debug_cable_event", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_source", "power_source", "power_debug_graph_closed_gate", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_switch", "circuit_switch", "power_debug_graph_closed_gate", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_consumer", "power_socket", "power_debug_graph_closed_gate", {"is_powered": false}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_source", "power_source", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_gate", "circuit_switch", "power_debug_graph_open_switch", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_consumer", "power_socket", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_source", "power_source", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_gate", "fuse_box", "power_debug_graph_empty_fuse", {"state": "empty"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_consumer", "power_socket", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_source", "power_source", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_gate", "power_cable", "power_debug_graph_cut_cable", {"state": "cut"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_consumer", "power_socket", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_source", "power_source", "power_debug_graph_no_source", {"is_powered": false, "state": "off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_consumer", "power_socket", "power_debug_graph_no_source", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer_source", "power_source", "power_debug_graph_damaged_consumer", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer", "power_socket", "power_debug_graph_damaged_consumer", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_source", "power_source", "power_debug_terminal_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_switch", "circuit_switch", "power_debug_terminal_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_terminal", "information_terminal", "power_debug_terminal_powered", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_source", "power_source", "power_debug_terminal_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_switch", "circuit_switch", "power_debug_terminal_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_terminal", "information_terminal", "power_debug_terminal_blocked", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_source", "power_source", "power_debug_terminal_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_terminal", "information_terminal", "power_debug_terminal_damaged", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_source", "power_source", "power_debug_energy_door_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_switch", "circuit_switch", "power_debug_energy_door_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_door", "energy_door", "power_debug_energy_door_blocked", {"is_powered": true, "state": "closed"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_source", "power_source", "power_debug_energy_door_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_switch", "circuit_switch", "power_debug_energy_door_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_door", "energy_door", "power_debug_energy_door_powered", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_source", "power_source", "power_debug_platform_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_switch", "circuit_switch", "power_debug_platform_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_platform", "lifting_platform", "power_debug_platform_blocked", {"is_powered": true, "state": "active", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_source", "power_source", "power_debug_platform_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_switch", "circuit_switch", "power_debug_platform_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_platform", "lifting_platform", "power_debug_platform_powered", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_source", "power_source", "power_debug_platform_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_switch", "circuit_switch", "power_debug_platform_damaged", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_platform", "lifting_platform", "power_debug_platform_damaged", {"is_powered": true, "state": "damaged", "height_level": 2, "damaged": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok", "power_source_class_2", "power_debug_source_load_ok", {"is_powered": true, "state": "active", "source_capacity": 2, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_terminal", "information_terminal", "power_debug_source_load_ok", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_door", "energy_door", "power_debug_source_load_ok", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_source", "power_source_class_2", "power_debug_source_fallback_class2", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_a", "information_terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_b", "information_terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_source", "power_source_class_3", "power_debug_source_fallback_class3", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_a", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_b", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_c", "information_terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_source", "power_source_class_1", "power_debug_source_overloaded", {"is_powered": true, "state": "active", "source_capacity": 1, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_terminal", "information_terminal", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_platform", "lifting_platform", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_source", "power_source_class_1", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active", "source_capacity": 1, "current_heat": 0, "overheat_threshold": 2, "working_heat": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_terminal", "information_terminal", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_platform", "lifting_platform", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		var object_id := String(object_data.get("id", "")).strip_edges()
		if not object_id.is_empty():
			temp_ids[object_id] = true
	var validation := validate_power_network_runtime_state()
	var runtime_warnings: Array = validation.get("warnings", [])
	var runtime_errors: Array = validation.get("errors", [])
	var summary_text := get_power_network_debug_summary_text()
	if summary_text.find("network=power_debug_no_threshold") == -1:
		warnings.append("Expected debug network summary for power_debug_no_threshold.")
	if summary_text.find("network=power_debug_no_threshold") != -1 and summary_text.find("network=power_debug_no_threshold |") != -1:
		var no_threshold_summary := get_power_network_debug_summary_text("network=power_debug_no_threshold")
		if no_threshold_summary.find("overheated_sources=1") != -1:
			warnings.append("No-threshold source regression: power_debug_no_threshold incorrectly counted overheated source.")
	var no_threshold_warning := "Power source power_debug_source_no_threshold current_heat >= overheat_threshold but state is not overheated."
	if runtime_warnings.has(no_threshold_warning):
		warnings.append("No-threshold source regression: unexpected overheat threshold warning for power_debug_source_no_threshold.")
	var overheated_summary := get_power_network_debug_summary_text("network=power_debug_overheated")
	if overheated_summary.find("overheated_sources=1") == -1:
		warnings.append("Expected overheated source count for power_debug_overheated.")
	var order_missing_source_warning := "Power object power_debug_cable_before_source connected_power_source_id points to missing source power_debug_source_order."
	if runtime_warnings.has(order_missing_source_warning):
		warnings.append("Connected object before source produced false missing-source warning.")
	var true_missing_source_warning := "Power object power_debug_cable_missing_source connected_power_source_id points to missing source power_debug_source_missing."
	if not runtime_warnings.has(true_missing_source_warning):
		warnings.append("Missing-source warning not reported for power_debug_cable_missing_source.")
	var source_limit_warning := "Power source power_debug_source_limit connections (2) exceed allowed_connections (1)."
	if not runtime_warnings.has(source_limit_warning):
		warnings.append("Expected allowed_connections warning for power_debug_source_limit.")
	var generic_limit_warning := "Power source power_debug_source_generic_connected connections (1) exceed allowed_connections (0)."
	if runtime_warnings.has(generic_limit_warning):
		warnings.append("Generic connected object without connected_power_source_id incorrectly counted toward source limit.")
	var negative_heat_error := "Power object power_debug_negative_heat has negative current_heat (-1)."
	if not runtime_errors.has(negative_heat_error):
		warnings.append("Expected negative current_heat error for power_debug_negative_heat.")
	var preview_result := preview_power_network_state_application()
	var preview_changes: Array = preview_result.get("changes", [])
	var saw_power_up_change := false
	var saw_overheated_power_up_change := false
	var saw_damaged_consumer_change := false
	var saw_damaged_powered_change := false
	var damaged_powered_reason_ok := false
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var changed_id := String(change.get("object_id", ""))
		var preview_powered := bool(change.get("preview_is_powered", false))
		if changed_id == "power_debug_preview_cable" and preview_powered:
			saw_power_up_change = true
		if changed_id == "power_debug_preview_cable_overheated" and preview_powered:
			saw_overheated_power_up_change = true
		if changed_id == "power_debug_preview_consumer_damaged":
			saw_damaged_consumer_change = true
		if changed_id == "power_debug_preview_consumer_damaged_powered":
			saw_damaged_powered_change = true
			if not preview_powered and String(change.get("reason", "")) == "damaged":
				damaged_powered_reason_ok = true
	if not saw_power_up_change:
		warnings.append("Preview regression: powered source did not predict power-up for connected consumer.")
	if saw_overheated_power_up_change:
		warnings.append("Preview regression: overheated source incorrectly predicted consumer power-up.")
	if saw_damaged_consumer_change:
		warnings.append("Preview regression: damaged consumer should remain unpowered with no change entry.")
	if not saw_damaged_powered_change:
		warnings.append("Preview regression: powered damaged consumer did not emit power-down change.")
	elif not damaged_powered_reason_ok:
		warnings.append("Preview regression: powered damaged consumer change missing reason=damaged.")
	var preview_cable_object := get_world_object_by_id("power_debug_preview_cable")
	var preview_cable_before := bool(preview_cable_object.get("is_powered", false))
	preview_power_network_state_application()
	var preview_cable_after := bool(preview_cable_object.get("is_powered", false))
	if preview_cable_before != preview_cable_after:
		warnings.append("Preview mutated temporary object state for power_debug_preview_cable.")
	var apply_case_a_consumer := get_world_object_by_id("power_debug_apply_case_a_consumer")
	var apply_case_a_before_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	var apply_preview_report_text := get_power_network_apply_debug_preview_text("power_debug_apply_case_a")
	if apply_preview_report_text.find("WOULD_APPLY") == -1:
		warnings.append("Apply preview report regression: missing WOULD_APPLY entry for case A.")
	if apply_preview_report_text.find("APPLIED") != -1:
		warnings.append("Apply preview report regression: preview text must not include APPLIED entries.")
	var apply_case_a_after_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	if apply_case_a_before_preview_report != apply_case_a_after_preview_report:
		warnings.append("Apply preview report regression: report mutated apply_case_a_consumer before apply.")
	var apply_execute_report_text := execute_power_network_apply_debug_command("power_debug_apply_case_a")
	if apply_execute_report_text.find("PowerNetworkApply") == -1:
		warnings.append("Apply debug execute regression: missing PowerNetworkApply header for case A.")
	if apply_execute_report_text.find("APPLIED") == -1:
		warnings.append("Apply debug execute regression: missing APPLIED entry for case A.")
	if not bool(apply_case_a_consumer.get("is_powered", false)):
		warnings.append("Apply regression A: powered source did not power unpowered consumer.")
	if apply_execute_report_text.find("object=power_debug_apply_case_a_consumer") == -1:
		warnings.append("Apply debug execute regression: report missing applied consumer power-up.")
	var apply_case_b_consumer := get_world_object_by_id("power_debug_apply_case_b_consumer")
	var apply_case_b_before := bool(apply_case_b_consumer.get("is_powered", false))
	var apply_result_b := apply_power_network_state_from_preview("power_debug_apply_case_b")
	var apply_case_b_after := bool(apply_case_b_consumer.get("is_powered", false))
	if apply_case_b_before != apply_case_b_after or apply_case_b_after:
		warnings.append("Apply regression B: consumer power changed with overheated source.")
	for change_variant in apply_result_b.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_apply_case_b_consumer" and bool(change.get("new_is_powered", false)):
			warnings.append("Apply regression B: report included invalid consumer power-up.")
			break
	var apply_case_c_consumer := get_world_object_by_id("power_debug_apply_case_c_consumer")
	var apply_result_c := apply_power_network_state_from_preview("power_debug_apply_case_c")
	if bool(apply_case_c_consumer.get("is_powered", false)):
		warnings.append("Apply regression C: damaged consumer remained powered.")
	var apply_case_c_reason_ok := false
	for change_variant in apply_result_c.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) != "power_debug_apply_case_c_consumer":
			continue
		if not bool(change.get("new_is_powered", false)) and String(change.get("reason", "")) == "damaged":
			apply_case_c_reason_ok = true
			break
	if not apply_case_c_reason_ok:
		warnings.append("Apply regression C: damaged consumer power-down missing reason=damaged.")
	var apply_case_d_source_on := get_world_object_by_id("power_debug_apply_case_d_source_on")
	var apply_case_d_source_off := get_world_object_by_id("power_debug_apply_case_d_source_off")
	var source_on_before := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_before := bool(apply_case_d_source_off.get("is_powered", false))
	apply_power_network_state_from_preview("power_debug_apply_case_d")
	var source_on_after := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_after := bool(apply_case_d_source_off.get("is_powered", false))
	if source_on_before != source_on_after or source_off_before != source_off_after:
		warnings.append("Apply regression D: source object is_powered mutated by apply.")
	var event_apply_consumer := get_world_object_by_id("power_debug_event_apply_consumer")
	var event_preview_before := bool(event_apply_consumer.get("is_powered", false))
	var event_preview_text := get_power_event_apply_preview_text("debug_event", "power_debug_event_apply")
	if event_preview_text.find("PowerEventApplyPreview") == -1:
		warnings.append("Event apply preview regression: missing PowerEventApplyPreview header.")
	if event_preview_text.find("WOULD_APPLY") == -1:
		warnings.append("Event apply preview regression: missing WOULD_APPLY entry.")
	if event_preview_text.find("APPLIED") != -1:
		warnings.append("Event apply preview regression: preview text must not include APPLIED entries.")
	var event_preview_after := bool(event_apply_consumer.get("is_powered", false))
	if event_preview_before != event_preview_after:
		warnings.append("Event apply preview regression: preview mutated consumer state.")
	var event_execute_text := execute_power_event_apply_and_get_report_text("debug_event", "power_debug_event_apply")
	if event_execute_text.find("PowerEventApply") == -1:
		warnings.append("Event apply execute regression: missing PowerEventApply header.")
	if event_execute_text.find("reason=debug_event") == -1:
		warnings.append("Event apply execute regression: missing reason=debug_event in header.")
	if event_execute_text.find("APPLIED") == -1:
		warnings.append("Event apply execute regression: missing APPLIED entry.")
	if not bool(event_apply_consumer.get("is_powered", false)):
		warnings.append("Event apply execute regression: consumer did not become powered.")
	var event_dict_report := apply_power_network_after_explicit_power_event("debug_event_dict", "power_debug_event_apply")
	if int(event_dict_report.get("applied", -1)) != 0:
		warnings.append("Event apply dictionary regression: expected applied=0 after execute.")
	if String(event_dict_report.get("event_reason", "")) != "debug_event_dict":
		warnings.append("Event apply dictionary regression: event_reason mismatch.")
	var switch_toggle_consumer := get_world_object_by_id("power_debug_switch_toggle_consumer")
	var switch_toggle_before := bool(switch_toggle_consumer.get("is_powered", false))
	debug_switch_object["state"] = "switch_on"
	var switch_filter := _get_power_event_filter_for_object(debug_switch_object)
	if switch_filter != "power_debug_switch_toggle":
		warnings.append("Power event filter helper regression: expected power_debug_switch_toggle for switch object.")
	var switch_toggle_report := apply_power_network_after_explicit_power_event("switch_toggled", switch_filter)
	if String(switch_toggle_report.get("event_reason", "")) != "switch_toggled":
		warnings.append("Switch toggle event apply regression: event_reason mismatch.")
	if not bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer did not become powered.")
	if switch_toggle_before == bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer power state did not change.")
	var fuse_consumer := get_world_object_by_id("power_debug_fuse_consumer")
	var fuse_filter := _get_power_event_filter_for_object(debug_fuse_object)
	if fuse_filter != "power_debug_fuse_event":
		warnings.append("Power event filter helper regression: expected power_debug_fuse_event for fuse object.")
	debug_fuse_object["state"] = "installed"
	var fuse_insert_report := apply_power_network_after_explicit_power_event("fuse_inserted", fuse_filter)
	if String(fuse_insert_report.get("event_reason", "")) != "fuse_inserted":
		warnings.append("Fuse insert event apply regression: event_reason mismatch.")
	if not bool(fuse_consumer.get("is_powered", false)):
		warnings.append("Fuse insert event apply regression: consumer did not become powered.")
	fuse_consumer["is_powered"] = true
	debug_fuse_object["state"] = "empty"
	var fuse_remove_report := apply_power_network_after_explicit_power_event("fuse_removed", fuse_filter)
	if String(fuse_remove_report.get("event_reason", "")) != "fuse_removed":
		warnings.append("Fuse remove event apply regression: event_reason mismatch.")
	var debug_cable_consumer := get_world_object_by_id("power_debug_cable_consumer")
	debug_cable_object["state"] = "connected"
	debug_cable_object["connected"] = true
	var cable_filter := _get_power_event_filter_for_object(debug_cable_object)
	if cable_filter != "power_debug_cable_event":
		warnings.append("Power event filter helper regression: expected power_debug_cable_event for cable object.")
	var cable_connect_report := apply_power_network_after_explicit_power_event("cable_connected", cable_filter)
	if String(cable_connect_report.get("event_reason", "")) != "cable_connected":
		warnings.append("Cable connect event apply regression: event_reason mismatch.")
	if not bool(debug_cable_consumer.get("is_powered", false)):
		warnings.append("Cable connect event apply regression: consumer did not become powered.")
	debug_cable_consumer["is_powered"] = true
	debug_cable_object["state"] = "disconnected"
	debug_cable_object["connected"] = false
	var cable_disconnect_report := apply_power_network_after_explicit_power_event("cable_disconnected", cable_filter)
	if String(cable_disconnect_report.get("event_reason", "")) != "cable_disconnected":
		warnings.append("Cable disconnect event apply regression: event_reason mismatch.")
	var graph_closed_source := get_world_object_by_id("power_debug_graph_closed_gate_source")
	var graph_closed_gate := get_world_object_by_id("power_debug_graph_closed_gate_switch")
	var graph_closed_consumer := get_world_object_by_id("power_debug_graph_closed_gate_consumer")
	var graph_closed_source_before_preview := bool(graph_closed_source.get("is_powered", false))
	var graph_closed_gate_state_before_preview := String(graph_closed_gate.get("state", ""))
	var graph_closed_gate_power_before_preview := bool(graph_closed_gate.get("is_powered", false))
	var graph_closed_consumer_before_preview := bool(graph_closed_consumer.get("is_powered", false))
	var graph_closed_preview := preview_power_graph_state_application("power_debug_graph_closed_gate")
	var graph_closed_preview_changes: Array = graph_closed_preview.get("changes", [])
	var graph_closed_preview_reason_ok := false
	for change_variant in graph_closed_preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_closed_gate_consumer" and String(change.get("reason", "")) == "graph_powered_source_reachable":
			graph_closed_preview_reason_ok = true
			break
	if not graph_closed_preview_reason_ok:
		warnings.append("Graph closed gate scenario regression: expected reason=graph_powered_source_reachable.")
	if graph_closed_source_before_preview != bool(graph_closed_source.get("is_powered", false)) or graph_closed_consumer_before_preview != bool(graph_closed_consumer.get("is_powered", false)) or graph_closed_gate_state_before_preview != String(graph_closed_gate.get("state", "")) or graph_closed_gate_power_before_preview != bool(graph_closed_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated closed-gate objects.")
	var graph_closed_apply := apply_power_graph_state_from_preview("power_debug_graph_closed_gate")
	if int(graph_closed_apply.get("applied", 0)) <= 0:
		warnings.append("Graph closed gate scenario regression: expected apply changes.")
	if not bool(graph_closed_consumer.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: consumer did not become powered.")
	if not bool(graph_closed_source.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: source mutated from powered state.")
	for change_variant in graph_closed_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_closed_gate_source":
			warnings.append("Graph apply regression: source object appeared in applied changes.")
			break
	var graph_open_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_open_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_open_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_open_source_before_preview := bool(graph_open_source.get("is_powered", false))
	var graph_open_gate_state_before_preview := String(graph_open_gate.get("state", ""))
	var graph_open_gate_power_before_preview := bool(graph_open_gate.get("is_powered", false))
	var graph_open_consumer_before_preview := bool(graph_open_consumer.get("is_powered", false))
	var graph_open_preview := preview_power_graph_state_application("power_debug_graph_open_switch")
	if String(get_power_graph_preview_text("power_debug_graph_open_switch")).find("blocked=1") == -1:
		warnings.append("Graph open switch scenario regression: blocked gate not reported.")
	if str(graph_open_preview).find("blocked_by_gate") == -1:
		warnings.append("Graph open switch scenario regression: reason blocked_by_gate missing.")
	if graph_open_source_before_preview != bool(graph_open_source.get("is_powered", false)) or graph_open_consumer_before_preview != bool(graph_open_consumer.get("is_powered", false)) or graph_open_gate_state_before_preview != String(graph_open_gate.get("state", "")) or graph_open_gate_power_before_preview != bool(graph_open_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated open-gate objects.")
	var graph_open_blocked_ok := false
	for blocked_variant in graph_open_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_open_switch_gate":
			graph_open_blocked_ok = true
			break
	if not graph_open_blocked_ok:
		warnings.append("Graph open switch scenario regression: blocked entry missing switch gate.")
	var graph_open_apply := apply_power_graph_state_from_preview("power_debug_graph_open_switch")
	if bool(graph_open_consumer.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: consumer should be unpowered.")
	if not bool(graph_open_source.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: source mutated from powered state.")
	var graph_open_reason_ok := false
	for change_variant in graph_open_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_open_switch_consumer":
			if String(change.get("reason", "")) == "blocked_by_gate":
				graph_open_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_open_switch_source":
			warnings.append("Graph apply regression: source object appeared in open-switch changes.")
	if not graph_open_reason_ok:
		warnings.append("Graph open switch scenario regression: missing reason=blocked_by_gate.")
	var graph_empty_fuse_source := get_world_object_by_id("power_debug_graph_empty_fuse_source")
	var graph_empty_fuse_consumer := get_world_object_by_id("power_debug_graph_empty_fuse_consumer")
	var graph_empty_fuse_preview := preview_power_graph_state_application("power_debug_graph_empty_fuse")
	var graph_empty_fuse_blocked_ok := false
	for blocked_variant in graph_empty_fuse_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_empty_fuse_gate":
			graph_empty_fuse_blocked_ok = true
			break
	if not graph_empty_fuse_blocked_ok:
		warnings.append("Graph empty fuse scenario regression: blocked entry missing fuse gate.")
	var graph_empty_fuse_apply := apply_power_graph_state_from_preview("power_debug_graph_empty_fuse")
	if bool(graph_empty_fuse_consumer.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: consumer should be unpowered.")
	if not bool(graph_empty_fuse_source.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: source mutated from powered state.")
	var graph_empty_fuse_reason_ok := false
	for change_variant in graph_empty_fuse_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_empty_fuse_consumer" and String(change.get("reason", "")) == "blocked_by_gate":
			graph_empty_fuse_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_empty_fuse_source":
			warnings.append("Graph apply regression: source object appeared in empty-fuse changes.")
	if not graph_empty_fuse_reason_ok:
		warnings.append("Graph empty fuse scenario regression: missing reason=blocked_by_gate.")
	var graph_cut_cable_source := get_world_object_by_id("power_debug_graph_cut_cable_source")
	var graph_cut_cable_consumer := get_world_object_by_id("power_debug_graph_cut_cable_consumer")
	var graph_cut_cable_preview := preview_power_graph_state_application("power_debug_graph_cut_cable")
	var graph_cut_cable_blocked_ok := false
	for blocked_variant in graph_cut_cable_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if String(blocked.get("object_id", "")) == "power_debug_graph_cut_cable_gate":
			graph_cut_cable_blocked_ok = true
			break
	if not graph_cut_cable_blocked_ok:
		warnings.append("Graph cut cable scenario regression: blocked entry missing cable gate.")
	var graph_cut_cable_apply := apply_power_graph_state_from_preview("power_debug_graph_cut_cable")
	if bool(graph_cut_cable_consumer.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: consumer should be unpowered.")
	if not bool(graph_cut_cable_source.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: source mutated from powered state.")
	var graph_cut_cable_reason_ok := false
	for change_variant in graph_cut_cable_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_cut_cable_consumer":
			var change_reason := String(change.get("reason", ""))
			if change_reason == "blocked_by_gate" or change_reason == "cut":
				graph_cut_cable_reason_ok = true
		elif String(change.get("object_id", "")) == "power_debug_graph_cut_cable_source":
			warnings.append("Graph apply regression: source object appeared in cut-cable changes.")
	if not graph_cut_cable_reason_ok:
		warnings.append("Graph cut cable scenario regression: missing reason=blocked_by_gate/cut.")
	var graph_no_source_consumer := get_world_object_by_id("power_debug_graph_no_source_consumer")
	var graph_no_source_apply := apply_power_graph_state_from_preview("power_debug_graph_no_source")
	if bool(graph_no_source_consumer.get("is_powered", false)):
		warnings.append("Graph no source scenario regression: consumer should be unpowered.")
	var graph_no_source_reason_ok := false
	for change_variant in graph_no_source_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_no_source_consumer" and String(change.get("reason", "")) == "no_powered_source":
			graph_no_source_reason_ok = true
			break
	if not graph_no_source_reason_ok:
		warnings.append("Graph no source scenario regression: missing reason=no_powered_source.")
	var graph_damaged_consumer := get_world_object_by_id("power_debug_graph_damaged_consumer")
	var graph_damaged_preview := preview_power_graph_state_application("power_debug_graph_damaged_consumer")
	var graph_damaged_apply := apply_power_graph_state_from_preview("power_debug_graph_damaged_consumer")
	if bool(graph_damaged_consumer.get("is_powered", false)):
		warnings.append("Graph damaged consumer scenario regression: damaged consumer became powered.")
	for change_variant in graph_damaged_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_damaged_consumer_source":
			warnings.append("Graph apply regression: source object appeared in damaged-consumer changes.")
	for change_variant in graph_damaged_preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_graph_damaged_consumer" and String(change.get("reason", "")) != "damaged":
			warnings.append("Graph damaged consumer scenario regression: expected reason=damaged for preview change.")
	var terminal_powered := get_world_object_by_id("power_debug_terminal_powered_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_powered")
	if not bool(terminal_powered.get("is_powered", false)) or String(terminal_powered.get("state", "")) != "active":
		warnings.append("Terminal powered restore regression: terminal did not restore active powered state.")
	var terminal_blocked := get_world_object_by_id("power_debug_terminal_blocked_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_blocked")
	if bool(terminal_blocked.get("is_powered", true)) or String(terminal_blocked.get("state", "")) != "unpowered":
		warnings.append("Terminal blocked regression: terminal should become unpowered.")
	var terminal_damaged := get_world_object_by_id("power_debug_terminal_damaged_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_damaged")
	if String(terminal_damaged.get("state", "")) != "damaged" or _is_terminal_powered_for_interaction(terminal_damaged):
		warnings.append("Terminal damaged regression: damaged terminal must remain non-interactable.")
	var terminal_legacy := {"object_type": "terminal", "state": "active"}
	if not _is_terminal_powered_for_interaction(terminal_legacy):
		warnings.append("Terminal legacy default regression: missing is_powered must remain interactable.")
	var terminal_explicit_unpowered := {"object_type": "terminal", "state": "active", "is_powered": false}
	if _is_terminal_powered_for_interaction(terminal_explicit_unpowered):
		warnings.append("Terminal explicit unpowered regression: is_powered=false must block interaction.")
	var energy_door_blocked := get_world_object_by_id("power_debug_energy_door_blocked_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_blocked")
	if bool(energy_door_blocked.get("is_powered", true)) or not String(energy_door_blocked.get("state", "")) in ["unpowered", "disabled"]:
		warnings.append("Energy door blocked regression: powered barrier did not disable when unpowered.")
	var energy_door_powered := get_world_object_by_id("power_debug_energy_door_powered_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_powered")
	if not bool(energy_door_powered.get("is_powered", false)) or not String(energy_door_powered.get("state", "")) in ["closed", "active", "powered"]:
		warnings.append("Energy door powered regression: barrier did not restore.")
	var platform_blocked := get_world_object_by_id("power_debug_platform_blocked_platform")
	var platform_blocked_height_before := int(platform_blocked.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_blocked")
	if bool(platform_blocked.get("is_powered", true)) or not String(platform_blocked.get("state", "")) in ["unpowered", "disabled"] or int(platform_blocked.get("height_level", 0)) != platform_blocked_height_before:
		warnings.append("Platform blocked regression: platform power-off should disable without movement.")
	var platform_powered := get_world_object_by_id("power_debug_platform_powered_platform")
	var platform_powered_height_before := int(platform_powered.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_powered")
	if not bool(platform_powered.get("is_powered", false)) or not String(platform_powered.get("state", "")) in ["active", "idle"] or int(platform_powered.get("height_level", 0)) != platform_powered_height_before:
		warnings.append("Platform powered regression: platform should restore and not move.")
	var platform_damaged := get_world_object_by_id("power_debug_platform_damaged_platform")
	var platform_damaged_state_before := String(platform_damaged.get("state", ""))
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if String(platform_damaged.get("state", "")) != platform_damaged_state_before or String(platform_damaged.get("state", "")) == "unpowered" or String(platform_damaged.get("state", "")) == "active":
		warnings.append("Platform damaged regression: damaged platform state must be preserved when unpowered.")
	var platform_damaged_switch := get_world_object_by_id("power_debug_platform_damaged_switch")
	platform_damaged_switch["state"] = "switch_on"
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if String(platform_damaged.get("state", "")) != platform_damaged_state_before:
		warnings.append("Platform damaged restore regression: power restore must not heal damaged platform.")
	var graph_filter_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_filter_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_filter_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_filter_source_before_preview := bool(graph_filter_source.get("is_powered", false))
	var graph_filter_gate_state_before_preview := String(graph_filter_gate.get("state", ""))
	var graph_filter_gate_power_before_preview := bool(graph_filter_gate.get("is_powered", false))
	var graph_filter_consumer_before_preview := bool(graph_filter_consumer.get("is_powered", false))
	var graph_filter_object_preview := preview_power_graph_state_application("power_debug_graph_open_switch_gate")
	if int((graph_filter_object_preview.get("sources", []) as Array).size()) != 1:
		warnings.append("Graph filter fallback regression: object-id filter did not resolve to network.")
	if graph_filter_source_before_preview != bool(graph_filter_source.get("is_powered", false)) or graph_filter_consumer_before_preview != bool(graph_filter_consumer.get("is_powered", false)) or graph_filter_gate_state_before_preview != String(graph_filter_gate.get("state", "")) or graph_filter_gate_power_before_preview != bool(graph_filter_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: object-id filter preview mutated open-switch objects.")
	var load_ok_source := get_world_object_by_id("power_debug_source_load_ok")
	var _load_ok_preview := preview_power_graph_state_application("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: preview mutated source load fields.")
	var load_ok_apply := apply_power_graph_state_from_preview("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != 2 or int(load_ok_source.get("source_capacity", -1)) != 2 or bool(load_ok_source.get("source_overloaded", true)):
		warnings.append("Source load scenario A regression: expected load=2 capacity=2 overloaded=false.")
	if String(load_ok_source.get("state", "")).to_lower() == "overheated":
		warnings.append("Source load scenario A regression: source should not overheat.")
	if int(load_ok_apply.get("applied", 0)) < 2:
		warnings.append("Source load scenario A regression: expected consumers to be powered.")
	var fallback_class2_source := get_world_object_by_id("power_debug_source_fallback_class2_source")
	var fallback_class2_preview := preview_power_graph_state_application("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class2 preview regression: preview mutated source capacity fields.")
	var fallback_class2_preview_sources: Array = fallback_class2_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class2_preview_capacity_ok := false
	for source_variant in fallback_class2_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if String(source_entry.get("object_id", "")) == "power_debug_source_fallback_class2_source" and int(source_entry.get("source_capacity", -1)) == 2:
			fallback_class2_preview_capacity_ok = true
			break
	if not fallback_class2_preview_capacity_ok:
		warnings.append("Source fallback class2 preview regression: expected source_capacity=2 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != 2:
		warnings.append("Source fallback class2 apply regression: expected source_capacity=2.")
	var fallback_class3_source := get_world_object_by_id("power_debug_source_fallback_class3_source")
	var fallback_class3_preview := preview_power_graph_state_application("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class3 preview regression: preview mutated source capacity fields.")
	var fallback_class3_preview_sources: Array = fallback_class3_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class3_preview_capacity_ok := false
	for source_variant in fallback_class3_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if String(source_entry.get("object_id", "")) == "power_debug_source_fallback_class3_source" and int(source_entry.get("source_capacity", -1)) == 3:
			fallback_class3_preview_capacity_ok = true
			break
	if not fallback_class3_preview_capacity_ok:
		warnings.append("Source fallback class3 preview regression: expected source_capacity=3 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != 3:
		warnings.append("Source fallback class3 apply regression: expected source_capacity=3.")
	var overloaded_source := get_world_object_by_id("power_debug_source_overloaded_source")
	apply_power_graph_state_from_preview("power_debug_source_overloaded")
	if int(overloaded_source.get("source_load", 0)) <= int(overloaded_source.get("source_capacity", 0)) or not bool(overloaded_source.get("source_overloaded", false)) or int(overloaded_source.get("heat_from_connections", 0)) <= 0:
		warnings.append("Source load scenario B regression: expected overloaded source with heat_from_connections.")
	var overheat_source := get_world_object_by_id("power_debug_source_overheat_shutdown_source")
	var overheat_terminal := get_world_object_by_id("power_debug_source_overheat_shutdown_terminal")
	var overheat_platform := get_world_object_by_id("power_debug_source_overheat_shutdown_platform")
	var overheat_preview_before := preview_power_graph_state_application("power_debug_source_overheat_shutdown")
	if str(overheat_preview_before).find("source_load_report") == -1 and int((overheat_preview_before.get("source_load_report", {}).get("updated", 0))) <= 0:
		warnings.append("Source load preview regression: missing source_load_report in graph preview.")
	if int(overheat_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: source overheat preview mutated source fields.")
	var overheat_apply := apply_power_graph_state_from_preview("power_debug_source_overheat_shutdown")
	if String(overheat_source.get("state", "")).to_lower() != "overheated":
		warnings.append("Source load scenario C regression: source did not overheat.")
	if bool(overheat_terminal.get("is_powered", true)) or bool(overheat_platform.get("is_powered", true)):
		warnings.append("Source load scenario C regression: dependent consumers should be unpowered.")
	for change_variant in overheat_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if String(change.get("object_id", "")) == "power_debug_source_overheat_shutdown_source":
			warnings.append("Source load scenario C regression: source appeared in applied changes.")
			break
	var allowed_fuse_remove_fields := {
		"is_powered": true,
		"current_heat": true,
		"working_heat": true,
		"cooling_received": true,
		"heat_from_connections": true,
		"state": true
	}
	for change_variant in fuse_remove_report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		for key_variant in change.keys():
			var key := String(key_variant)
			if not allowed_fuse_remove_fields.has(key):
				warnings.append("Fuse remove event apply regression: unexpected change field %s." % key)
				break
	var index := mission_world_objects.size() - 1
	while index >= 0:
		var object_data: Dictionary = mission_world_objects[index]
		var object_id := String(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			mission_world_objects.remove_at(index)
		index -= 1
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			warnings.append("Temporary debug power object remained after cleanup: %s." % object_id)
	if mission_world_objects.size() != base_size:
		warnings.append("Mission world object count changed after debug scenario cleanup (expected %d, got %d)." % [base_size, mission_world_objects.size()])
	if mission_world_objects.size() == unchanged_snapshot.size():
		for i in range(mission_world_objects.size()):
			if mission_world_objects[i] != unchanged_snapshot[i]:
				warnings.append("Mission world object at index %d changed during debug scenario." % i)
				break
	return warnings

func get_power_network_debug_validation_text() -> String:
	var warnings := validate_power_network_debug_scenario()
	var lines: Array[String] = []
	lines.append("PowerNetworkDebugScenario: warnings=%d" % warnings.size())
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)



func get_power_network_full_debug_report_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerNetworkFullDebug: filter=%s resolved_filter=%s" % [filter.strip_edges(), String(preview.get("resolved_filter", ""))])
	lines.append("Sources:")
	for source_variant in preview.get("source_load_report", {}).get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		var obj := get_world_object_by_id(String(source.get("object_id", "")))
		lines.append("- %s state=%s available=%s load=%d/%d heat=%d/%d overloaded=%s" % [String(source.get("object_id", "")), String(source.get("state", obj.get("state", ""))), str(_is_power_source_available(obj)).to_lower(), int(source.get("source_load", 0)), int(source.get("source_capacity", 0)), int(source.get("current_heat", 0)), int(source.get("overheat_threshold", 0)), str(bool(source.get("source_overloaded", false))).to_lower()])
	lines.append("Gates:")
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		var gate := _get_power_gate_state(object_data)
		if not bool(gate.get("is_gate", false)):
			continue
		lines.append("- %s type=%s state=%s closed=%s reason=%s" % [String(object_data.get("id", "")), String(gate.get("gate_type", "")), String(object_data.get("state", "")), str(bool(gate.get("is_closed", true))).to_lower(), String(gate.get("reason", ""))])
	lines.append("Consumers:")
	for object_data in mission_world_objects:
		if _is_power_source_object(object_data) or not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		lines.append("- %s type=%s powered=%s state=%s reason=%s" % [String(object_data.get("id", "")), String(object_data.get("object_type", "")), str(bool(object_data.get("is_powered", false))).to_lower(), String(object_data.get("state", "")), String(object_data.get("power_unavailable_reason", ""))])
	lines.append("Blocked:")
	for b in preview.get("blocked", []):
		lines.append("- %s" % str(b))
	lines.append("Preview changes:")
	for c in preview.get("changes", []):
		lines.append("- %s" % str(c))
	lines.append("Source load preview:")
	lines.append(str(preview.get("source_load_report", {})))
	lines.append("Warnings:")
	for w in preview.get("warnings", []):
		lines.append("- %s" % String(w))
	return "\n".join(lines)

func validate_full_power_system_runtime() -> Array[String]:
	var warnings := validate_power_network_debug_scenario()
	var runtime_validation := validate_power_network_runtime_state()
	for warning in runtime_validation.get("warnings", []):
		warnings.append("runtime: %s" % String(warning))
	for err in runtime_validation.get("errors", []):
		warnings.append("runtime_error: %s" % String(err))
	var temp_objects: Array[Dictionary] = []
	var cleanup_ids: Array[String] = []
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_source", "power_source_class_1", "power_debug_source_recovery", {"state": "overheated", "is_powered": false, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "heat_from_connections": 2, "cooling_received": 5, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_terminal", "information_terminal", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_door", "energy_door", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_platform", "lifting_platform", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_source", "power_source_class_1", "power_debug_source_recovery_damaged", {"state": "overheated", "is_powered": false, "overheated_state_before": "damaged", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_terminal", "information_terminal", "power_debug_source_recovery_damaged", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_source", "power_source_class_1", "power_debug_source_recovery_broken", {"state": "overheated", "is_powered": false, "broken": true, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_terminal", "information_terminal", "power_debug_source_recovery_broken", {"is_powered": false, "state": "unpowered"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		cleanup_ids.append(String(object_data.get("id", "")))
	var recovery_a := execute_power_source_recovery_apply("power_debug_source_recovery")
	var source_a := get_world_object_by_id("power_debug_source_recovery_source")
	if String(source_a.get("state", "")).to_lower() != "active":
		warnings.append("power_debug_source_recovery: expected source state active after valid cooling recovery.")
	if not _is_power_source_available(source_a):
		warnings.append("power_debug_source_recovery: expected source available after valid cooling recovery.")
	var recovery_a_changes: Array = recovery_a.get("apply", {}).get("changes", [])
	for change_variant in recovery_a_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(change_variant).get("object_id", "")) == "power_debug_source_recovery_source":
			warnings.append("power_debug_source_recovery: source should not be included in consumer apply changes.")
			break
	for object_id in ["power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var consumer := get_world_object_by_id(object_id)
		if not bool(consumer.get("is_powered", false)):
			warnings.append("power_debug_source_recovery: expected %s to become powered after valid recovery." % object_id)
	var recovery_b := execute_power_source_recovery_apply("power_debug_source_recovery_damaged")
	var source_b := get_world_object_by_id("power_debug_source_recovery_damaged_source")
	if String(source_b.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_damaged: source unexpectedly recovered to active from damaged pre-overheat state.")
	if _is_power_source_available(source_b):
		warnings.append("power_debug_source_recovery_damaged: expected source to remain unavailable.")
	if String(source_b.get("power_unavailable_reason", "")) != "source_damage_state":
		warnings.append("power_debug_source_recovery_damaged: expected power_unavailable_reason=source_damage_state.")
	if bool(get_world_object_by_id("power_debug_source_recovery_damaged_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_damaged: consumer should remain unpowered.")
	if Array(recovery_b.get("recovery", {}).get("warnings", [])).is_empty():
		warnings.append("power_debug_source_recovery_damaged: expected recovery warning for blocked damaged restore.")
	var _recovery_c := execute_power_source_recovery_apply("power_debug_source_recovery_broken")
	var source_c := get_world_object_by_id("power_debug_source_recovery_broken_source")
	if String(source_c.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_broken: source unexpectedly recovered while broken=true.")
	if bool(get_world_object_by_id("power_debug_source_recovery_broken_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_broken: consumer should remain unpowered.")
	var report_snapshot := {}
	for object_id in ["power_debug_source_recovery_source", "power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var obj := get_world_object_by_id(object_id)
		report_snapshot[object_id] = {"state": String(obj.get("state", "")), "is_powered": bool(obj.get("is_powered", false)), "power_unavailable_reason": String(obj.get("power_unavailable_reason", "")), "connected": bool(obj.get("connected", false))}
	get_power_network_full_debug_report_text("power_debug_source_recovery")
	for object_id in report_snapshot.keys():
		var obj := get_world_object_by_id(String(object_id))
		var snap: Dictionary = report_snapshot[object_id]
		if String(obj.get("state", "")) != String(snap.get("state", "")) or bool(obj.get("is_powered", false)) != bool(snap.get("is_powered", false)) or String(obj.get("power_unavailable_reason", "")) != String(snap.get("power_unavailable_reason", "")) or bool(obj.get("connected", false)) != bool(snap.get("connected", false)):
			warnings.append("power_debug_source_recovery: full debug report mutated runtime state for %s." % String(object_id))
	var runtime_object := _build_power_network_debug_object("power_debug_runtime_save_fields", "information_terminal", "power_debug_runtime_save")
	runtime_object["state"] = "unpowered"
	runtime_object["is_powered"] = false
	runtime_object["current_heat"] = 3
	runtime_object["working_heat"] = 2
	runtime_object["cooling_received"] = 1
	runtime_object["heat_from_connections"] = 4
	runtime_object["overheat_threshold"] = 5
	runtime_object["source_load"] = 1
	runtime_object["source_capacity"] = 2
	runtime_object["source_overloaded"] = false
	runtime_object["power_unavailable_reason"] = "network_blocked"
	runtime_object["connected"] = true
	runtime_object["disconnected"] = false
	runtime_object["cut"] = false
	runtime_object["damaged"] = true
	runtime_object["broken"] = false
	runtime_object["destroyed"] = false
	runtime_object["state_before_unpowered"] = "active"
	runtime_object["powered_state_before_unpowered"] = "active"
	mission_world_objects.append(runtime_object)
	cleanup_ids.append("power_debug_runtime_save_fields")
	var runtime_snapshot := get_world_object_runtime_state()
	var saved_entry: Dictionary = runtime_snapshot.get("power_debug_runtime_save_fields", {})
	for field_name in ["state", "is_powered", "current_heat", "working_heat", "cooling_received", "heat_from_connections", "overheat_threshold", "source_load", "source_capacity", "source_overloaded", "power_unavailable_reason", "connected", "disconnected", "cut", "damaged", "broken", "destroyed", "state_before_unpowered", "powered_state_before_unpowered"]:
		if not saved_entry.has(field_name):
			warnings.append("power_debug_runtime_save_fields: runtime snapshot missing field %s." % field_name)
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := String(mission_world_objects[i].get("id", "")).strip_edges()
		if cleanup_ids.has(object_id):
			mission_world_objects.remove_at(i)
	for warning in validate_cooling_runtime():
		warnings.append(String(warning))
	for warning in validate_cooling_and_cable_runtime():
		warnings.append(String(warning))
	if has_method("validate_platform_scan_visibility_runtime"):
		for warning in validate_platform_scan_visibility_runtime():
			warnings.append(String(warning))
	return warnings

func validate_cooling_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var preview := preview_cooling_application("")
	if typeof(preview.get("targets", [])) != TYPE_ARRAY:
		warnings.append("Cooling preview regression: targets missing.")
	var apply_snapshot := preview_cooling_application("")
	if str(preview) != str(apply_snapshot):
		warnings.append("Cooling preview regression: read-only preview produced unstable results.")
	return warnings

func validate_cooling_and_cable_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var snapshot := get_world_object_runtime_state()
	var source := {"id":"temp_cooling_source", "object_group":"power", "object_type":"power_source", "position":Vector2i(130, 100), "is_powered":true, "state":"active"}
	var radiator := {"id":"temp_cooling_radiator", "object_group":"cooling", "object_type":"cooling_radiator", "position":Vector2i(131, 100), "cooling_device_type":"radiator", "cooling_output":2, "state":"active", "is_powered":true}
	var cable := {"id":"temp_validation_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(132, 100), "connected":true, "disconnected":false, "cut":false, "state":"active"}
	for obj in [source, radiator, cable]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
	var cool_preview_before := str(get_world_object_runtime_state())
	preview_cooling_application("")
	if str(get_world_object_runtime_state()) != cool_preview_before:
		warnings.append("cooling_preview_mutated_state")
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	if bool(cable.get("connected", true)):
		warnings.append("cut_cable_should_disconnect")
	var repair_item := {"id":"temp_repair_kit_cable", "object_group":"item", "object_type":"item", "position":Vector2i(133, 100), "item_type":"repair_kit"}
	mission_world_objects.append(repair_item)
	world_objects_by_cell[Vector2i(133, 100)] = repair_item
	cable["damaged"] = true
	use_inventory_item_on_world_object("temp_repair_kit_cable", "temp_validation_cable")
	if not bool(cable.get("disconnected", false)):
		warnings.append("cable_repair_should_not_reconnect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := String(mission_world_objects[i].get("id", ""))
		if oid.begins_with("temp_"):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(snapshot)
	for object_id_variant in snapshot.keys():
		var object_id := String(object_id_variant)
		var entry: Dictionary = snapshot.get(object_id_variant, {})
		if entry.has("cable_path_cells") and not entry.has("cable_length"):
			warnings.append("Runtime cable serialization regression: cable_length missing for %s." % object_id)
	return warnings

func get_cooling_and_cable_validation_text() -> String:
	var warnings := validate_cooling_and_cable_runtime()
	if warnings.is_empty():
		return "CoolingCableValidation: ok"
	return "CoolingCableValidation:\n- " + "\n- ".join(warnings)

func get_full_power_system_validation_text() -> String:
	var warnings := validate_full_power_system_runtime()
	var lines: Array[String] = ["FullPowerValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)


func _has_xray_capability() -> Dictionary:
	if active_bipob_ref != null and active_bipob_ref.has_method("has_module_id") and bool(active_bipob_ref.call("has_module_id", "xray_v1")):
		return {"ok": true, "reason": "ok"}
	return {"ok": false, "reason": "xray_capability_unavailable", "debug_reason": "debug_xray_allowed"}

func is_world_object_visible_to_player(object_data: Dictionary, scan_mode: String = "basic") -> bool:
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var cell_visible := true
	if grid_manager != null and grid_manager.has_method("is_cell_visible"):
		cell_visible = bool(grid_manager.call("is_cell_visible", cell))
	var hidden := bool(object_data.get("hidden", false))
	if scan_mode == "xray":
		return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false)) or bool(object_data.get("revealed_by_scan", false)) or bool(object_data.get("visible_with_xray", false))
	if hidden:
		return cell_visible and (bool(object_data.get("discovered", false)) or bool(object_data.get("revealed", false)) or bool(object_data.get("revealed_by_scan", false)))
	return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false))

func get_visible_world_objects_for_scan(scan_mode: String = "basic") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if is_world_object_visible_to_player(object_data, scan_mode): out.append(object_data)
	return out

func get_xray_visible_objects(filter: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if not bool(object_data.get("hidden", false)): continue
		if not bool(object_data.get("visible_with_xray", false)) and not bool(object_data.get("hidden_cable", false)): continue
		if not filter.strip_edges().is_empty() and String(object_data.get("power_network_id", "")) != filter.strip_edges(): continue
		out.append(object_data)
	return out

func reveal_xray_objects(filter: String = "") -> Dictionary:
	var cap := _has_xray_capability()
	var targets := get_xray_visible_objects(filter)
	for target in targets:
		target["revealed"] = true
		target["discovered"] = true
		target["revealed_by_scan"] = true
	return {"success": true, "reason": String(cap.get("reason", "ok")), "debug_reason": String(cap.get("debug_reason", "")), "revealed": targets.size()}

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
	info["position"] = _debug_cell_to_array(WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
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
			if tile_array.size() <= 16:
				return tile_array.duplicate(true)
			return str(tile_array)
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
		var tile_info: Variant = _get_debug_tile_info(cell)
		if tile_info != null:
			info["tile"] = tile_info
			if typeof(tile_info) == TYPE_DICTIONARY:
				var tile_data: Dictionary = Dictionary(tile_info)
				if String(tile_data.get("type", "")) == "wall":
					info["is_wall"] = true
			elif typeof(tile_info) == TYPE_INT:
				var wall_tile_id: Variant = _get_wall_tile_id()
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
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
	var movable_text := str(WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data))
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
		"working_heat",
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
		"platform_remote_control",
		"state_before_unpowered",
		"powered_state_before_unpowered",
		"source_load",
		"source_capacity",
		"source_overloaded",
		"overheat_threshold",
		"power_unavailable_reason",
		"connected",
		"disconnected",
		"cut",
		"cable_endpoint_a_id",
		"cable_endpoint_b_id",
		"cable_path_cells",
		"cable_length",
		"cable_max_length",
		"cooling_source_ids",
		"cooling_reason",
		"damaged",
		"broken",
		"destroyed",
		"revealed",
		"discovered",
		"revealed_by_scan",
		"visible_with_xray",
		"hidden_cable",
		"requires_xray",
		"platform_rotation",
		"local_switch_enabled",
		"terminal_control_enabled"
	]
	for object_data in mission_world_objects:
		var object_id := String(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var serialized := {}
		if object_data.has("object_type"):
			serialized["object_type"] = String(object_data.get("object_type", ""))
		if object_data.has("position"):
			var world_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			serialized["position"] = [world_cell.x, world_cell.y]
		for field_name in runtime_fields:
			if object_data.has(field_name):
				serialized[field_name] = object_data[field_name]
		if not serialized.is_empty():
			runtime_state[object_id] = serialized
	return runtime_state

func get_inventory_state() -> Dictionary:
	return runtime_inventory_state.duplicate(true)

func get_actor_capability_levels() -> Dictionary:
	var defaults := {
		"manipulator_level": 0,
		"connector_level": 0,
		"processor_level": 0,
		"connector_types": [],
		"power_class": "none",
		"modules": [],
		"tools": [],
		"port_state": {}
	}
	if active_bipob_ref == null:
		return defaults
	defaults["manipulator_level"] = int(active_bipob_ref.call("get_installed_manipulator_arm_level")) if active_bipob_ref.has_method("get_installed_manipulator_arm_level") else 0
	defaults["power_class"] = String(active_bipob_ref.call("get_bipob_power_class")) if active_bipob_ref.has_method("get_bipob_power_class") else "none"
	var port_state: Dictionary = active_bipob_ref.call("preview_module_port_activity") if active_bipob_ref.has_method("preview_module_port_activity") else {}
	defaults["port_state"] = port_state
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var installed_modules: Array = Array(active_bipob_ref.installed_modules) if _active_bipob_has_property("installed_modules") else []
	var modules: Array[String] = []
	var tools: Array[String] = []
	var tool_seen := {}
	var connector_types: Array[String] = []
	var connector_kind_seen := {}
	var connector_level := 0
	var processor_level := 0
	var level_regex := RegEx.new()
	level_regex.compile("_v(\\d+)$")
	for module_id_variant in modules_state.keys():
		var module_id := String(module_id_variant)
		var module_state: Dictionary = Dictionary(modules_state.get(module_id_variant, {}))
		if not bool(module_state.get("active", false)):
			continue
		modules.append(module_id)
		if module_id.contains("_connector_v"):
			var found := level_regex.search(module_id)
			if found != null:
				connector_level = maxi(connector_level, int(found.get_string(1)))
			var connector_type := ""
			if module_id.begins_with("external_interface_connector_"):
				connector_type = "physical"
			elif module_id.begins_with("optical_connector_"):
				connector_type = "optical"
			elif module_id.begins_with("wireless_connector_"):
				connector_type = "wireless"
			elif module_id.begins_with("high_bandwidth_connector_"):
				connector_type = "high_bandwidth"
			if not connector_type.is_empty() and not connector_kind_seen.has(connector_type):
				connector_kind_seen[connector_type] = true
				connector_types.append(connector_type)
		elif module_id.begins_with("processor_"):
			var pfound := level_regex.search(module_id)
			if pfound != null:
				processor_level = maxi(processor_level, int(pfound.get_string(1)))
	for module_variant in installed_modules:
		if module_variant == null:
			continue
		var module_id := String(module_variant.id).strip_edges()
		if module_id.is_empty():
			continue
		if String(module_variant.category) != "Tools":
			continue
		var module_state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		if not bool(module_state.get("active", false)):
			continue
		var tool_action := String(module_variant.tool_action).strip_edges()
		var tool_id := tool_action if not tool_action.is_empty() else module_id
		if tool_seen.has(tool_id):
			continue
		tool_seen[tool_id] = true
		tools.append(tool_id)
	defaults["modules"] = modules
	defaults["tools"] = tools
	defaults["connector_types"] = connector_types
	defaults["connector_level"] = connector_level
	defaults["processor_level"] = processor_level
	return defaults

func check_world_object_requirements(object_id: String, action: String = "") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	var capabilities := get_actor_capability_levels()
	var requirements: Dictionary = {}
	var reasons: Array[String] = []
	if object_data.is_empty():
		return {"allowed": false, "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": ["object_missing"]}
	for key in ["required_manipulator_level", "required_connector_level", "required_processor_level", "required_bipob_power_class", "fits_targets", "required_tool", "required_item_id", "lock_type", "terminal_class", "door_class", "item_form", "storage_type"]:
		if object_data.has(key):
			requirements[key] = object_data[key]
	if int(requirements.get("required_manipulator_level", 0)) > int(capabilities.get("manipulator_level", 0)): reasons.append("manipulator_level_too_low")
	if int(requirements.get("required_connector_level", 0)) > int(capabilities.get("connector_level", 0)): reasons.append("connector_level_too_low")
	if int(requirements.get("required_processor_level", 0)) > int(capabilities.get("processor_level", 0)): reasons.append("processor_level_too_low")
	var required_power_class := String(requirements.get("required_bipob_power_class", "")).strip_edges()
	if not required_power_class.is_empty() and required_power_class != String(capabilities.get("power_class", "none")):
		reasons.append("power_class_too_low")
	if not String(requirements.get("required_tool", "")).strip_edges().is_empty() and not Array(capabilities.get("tools", [])).has(String(requirements.get("required_tool", ""))):
		reasons.append("required_tool_missing")
	if not String(requirements.get("required_item_id", "")).strip_edges().is_empty():
		var inv := get_inventory_state()
		var all_items: Array = Array(inv.get("pocket_items", [])) + [String(inv.get("manipulator_hold", ""))] + Array(inv.get("digital_buffer", []))
		if not all_items.has(String(requirements.get("required_item_id", ""))):
			reasons.append("required_item_missing")
	if reasons.is_empty():
		reasons.append("ok")
	return {"allowed": reasons.size() == 1 and reasons[0] == "ok", "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": reasons}

func can_pickup_world_item(item_id: String) -> Dictionary:
	var item := get_world_object_by_id(item_id)
	if item.is_empty():
		return {"success": false, "reasons": ["item_missing"], "item_id": item_id}
	if not bool(item.get("can_pickup", true)):
		return {"success": false, "reasons": ["item_does_not_fit"], "item_id": item_id}
	return {"success": true, "reasons": ["ok"], "item_id": item_id}

func pickup_world_item(item_id: String) -> Dictionary:
	var gate := can_pickup_world_item(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var item := get_world_object_by_id(item_id)
	var storage_type := String(item.get("storage_type", "pocket"))
	if String(item.get("item_form", "physical")) == "digital":
		return place_item_in_digital_buffer(item_id)
	if storage_type == "manipulator_hold":
		return hold_item_in_manipulator(item_id)
	var pocket: Array = runtime_inventory_state.get("pocket_items", [])
	pocket.append(item_id)
	runtime_inventory_state["pocket_items"] = pocket
	runtime_inventory_state["world_item_runtime"][item_id] = {"picked_up": true, "in_inventory": true, "carried_by": "bipob"}
	return {"success": true, "reasons": ["ok"], "item_id": item_id}

func can_drop_inventory_item(item_id: String) -> Dictionary:
	var inv := get_inventory_state()
	var has_item := Array(inv.get("pocket_items", [])).has(item_id) or String(inv.get("manipulator_hold", "")) == item_id
	return {"success": has_item, "item_id": item_id, "reasons": ["ok"] if has_item else ["item_missing"]}

func drop_inventory_item(item_id: String, target_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var gate := can_drop_inventory_item(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var pocket: Array = runtime_inventory_state.get("pocket_items", [])
	pocket.erase(item_id)
	runtime_inventory_state["pocket_items"] = pocket
	if String(runtime_inventory_state.get("manipulator_hold", "")) == item_id:
		runtime_inventory_state["manipulator_hold"] = ""
	runtime_inventory_state["world_item_runtime"][item_id] = {"picked_up": false, "in_inventory": false, "carried_by": "", "position": [target_cell.x, target_cell.y]}
	return {"success": true, "item_id": item_id, "target_cell": target_cell, "reasons": ["ok"]}

func can_hold_item_in_manipulator(item_id: String) -> Dictionary:
	if String(runtime_inventory_state.get("manipulator_hold", "")) != "":
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func hold_item_in_manipulator(item_id: String) -> Dictionary:
	var gate := can_hold_item_in_manipulator(item_id)
	if not bool(gate.get("success", false)):
		return gate
	runtime_inventory_state["manipulator_hold"] = item_id
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func can_place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var item := get_world_object_by_id(item_id)
	if item.is_empty():
		return {"success": false, "item_id": item_id, "reasons": ["item_missing"]}
	if not bool(item.get("can_place_in_digital_buffer", false)):
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var gate := can_place_item_in_digital_buffer(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var buffer: Array = runtime_inventory_state.get("digital_buffer", [])
	if not buffer.has(item_id):
		buffer.append(item_id)
	runtime_inventory_state["digital_buffer"] = buffer
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func _add_world_runtime_restore_warning(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	last_world_runtime_restore_warnings.append(message)

func _extract_saved_world_runtime_position(saved_data: Dictionary, object_id: String, fallback_position: Vector2i) -> Dictionary:
	if not saved_data.has("position"):
		return {"ok": true, "position": fallback_position}
	var position_variant: Variant = saved_data.get("position")
	var parsed_position := WorldObjectCatalogRef.to_world_cell(position_variant, Vector2i(-1, -1))
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
			var created := WorldObjectCatalogRef.create_world_object(object_type, object_id)
			if created.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: failed to create object_type %s." % [object_id, object_type])
				continue
			created["id"] = object_id
			candidate_object = created
		var old_position := WorldObjectCatalogRef.to_world_cell(candidate_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func get_world_runtime_persistence_debug_summary_text() -> String:
	var serialized := get_world_object_runtime_state()
	var moved_objects := 0
	var heat_enabled_objects := 0
	var powered_objects := 0
	var connection_state_objects := 0
	for object_data in mission_world_objects:
		var current_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if object_data.has("original_position"):
			var original_position := WorldObjectCatalogRef.to_world_cell(object_data.get("original_position", current_position), current_position)
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
			var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
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
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
		cells.append(WorldObjectCatalogRef.to_world_cell(c, Vector2i(-1, -1)))
	var occupants := {"world_objects": [], "items": [], "bipobs": []}
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == String(platform.get("id", "")):
			continue
		var pos := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
	var local_switch_cell := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
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


func get_platform_action_availability(platform_id: String, action: String = "") -> Dictionary:
	var normalized_action := action.strip_edges().to_lower()
	var result := {"available": false, "platform_id": platform_id, "action": normalized_action, "reasons": [], "state": "", "is_powered": false, "control_type": "", "power_type": ""}
	var valid_actions := ["", "activate", "raise", "lower", "toggle", "rotate_clockwise", "rotate_counterclockwise"]
	if not valid_actions.has(normalized_action):
		result["reasons"] = ["invalid_action"]
		return result
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		result["reasons"] = ["platform_missing"]
		return result
	if String(platform.get("object_group", "")) != "platform":
		result["reasons"] = ["not_platform"]
		return result
	result["state"] = String(platform.get("state", ""))
	result["is_powered"] = bool(platform.get("is_powered", false))
	result["control_type"] = String(platform.get("control_type", "internal"))
	result["power_type"] = String(platform.get("power_type", "external"))
	var reasons: Array[String] = []
	if bool(platform.get("damaged", false)) or String(platform.get("state", "")) == "damaged": reasons.append("platform_damaged")
	if bool(platform.get("broken", false)) or String(platform.get("state", "")) == "broken": reasons.append("platform_broken")
	if bool(platform.get("destroyed", false)) or String(platform.get("state", "")) == "destroyed": reasons.append("platform_destroyed")
	if not bool(platform.get("is_powered", true)) or String(platform.get("state", "")) in ["unpowered", "disabled"] or String(platform.get("power_type", "external")) == "external" and not bool(platform.get("is_powered", false)):
		reasons.append("platform_unpowered")
	if not bool(platform.get("local_switch_enabled", true)): reasons.append("local_switch_disabled")
	if not bool(platform.get("terminal_control_enabled", true)): reasons.append("terminal_control_disabled")
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(String(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or not bool(terminal.get("platform_control_enabled", true)) or String(terminal.get("state", "")) in ["unpowered", "disabled", "damaged"]:
			reasons.append("linked_terminal_unavailable")
	if reasons.is_empty(): reasons.append("ok")
	result["reasons"] = reasons
	result["available"] = reasons.size() == 1 and reasons[0] == "ok"
	return result

func get_lifting_platform_carry_targets(platform_id: String) -> Array[Dictionary]:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty() or String(platform.get("platform_type", "")) != "lifting":
		return []
	var targets: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if String(object_data.get("id", "")) == String(platform.get("id", "")):
			continue
		if String(object_data.get("object_group", "")) in ["wall", "door", "terminal"] and not bool(object_data.get("rotate_with_platform", false)):
			continue
		if bool(object_data.get("destroyed", false)):
			continue
		var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var on_platform := false
		for platform_cell_variant in Array(platform.get("platform_cells", [])):
			if WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1)) == object_cell:
				on_platform = true
				break
		if on_platform or String(object_data.get("carried_by_platform_id", "")) == platform_id:
			targets.append(object_data)
	return targets

func apply_lifting_platform_height_change(platform_id: String, delta: int, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var current := int(platform.get("height_level", 0))
	var min_h := int(platform.get("min_height_level", 0))
	var max_h := int(platform.get("max_height_level", 1))
	var target := clampi(current + delta, min_h, max_h)
	if target == current:
		return {"success": false, "reason": "already_at_max_height" if delta > 0 else "already_at_min_height", "height_level": current}
	platform["height_level"] = target
	for obj in get_lifting_platform_carry_targets(platform_id):
		obj["platform_height_level"] = target
		obj["height_level"] = target
		obj["carried_by_platform_id"] = platform_id
	if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and _is_active_bipob_on_platform(platform):
		active_bipob_ref.call("set_platform_height_level", target, platform_id)
	return {"success": true, "reason": "ok", "height_level": target, "controller_id": controller_id}

func apply_rotating_platform_rotation(platform_id: String, clockwise: bool = true, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var occupants := get_platform_occupants(platform_id)
	platform["rotation_direction"] = "clockwise" if clockwise else "counterclockwise"
	if platform.has("facing_dir"):
		platform["facing_dir"] = _rotate_facing(String(platform.get("facing_dir", "up")), clockwise)
	for obj in Array(occupants.get("world_objects", [])):
		if String(obj.get("object_type", "")) in ["external_air_cooler", "external_air_duct"] or bool(obj.get("rotate_with_platform", false)):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(String(obj.get("facing_dir", "up")), clockwise)
	var filter := String(platform.get("power_network_id", ""))
	apply_cooling_application(filter)
	execute_power_source_recovery_apply(filter)
	return {"success": true, "reason": "ok", "rotation_direction": platform["rotation_direction"], "controller_id": controller_id}

func execute_platform_action(platform_id: String, action: String = "", controller_id: String = "") -> Dictionary:
	var availability := get_platform_action_availability(platform_id, action)
	if not bool(availability.get("available", false)):
		return {"success": false, "platform_id": platform_id, "action": action, "reason": String((availability.get("reasons", ["blocked"]) as Array)[0]), "availability": availability}
	var normalized := action.strip_edges().to_lower()
	if normalized in ["", "activate", "toggle"]:
		var r := activate_platform_by_id(platform_id, controller_id)
		r["reason"] = "ok" if bool(r.get("success", false)) else "invalid_action"
		return r
	if normalized == "raise": return apply_lifting_platform_height_change(platform_id, 1, controller_id)
	if normalized == "lower": return apply_lifting_platform_height_change(platform_id, -1, controller_id)
	if normalized == "rotate_clockwise": return apply_rotating_platform_rotation(platform_id, true, controller_id)
	if normalized == "rotate_counterclockwise": return apply_rotating_platform_rotation(platform_id, false, controller_id)
	return {"success": false, "platform_id": platform_id, "action": action, "reason": "invalid_action"}

func _is_active_bipob_on_platform(platform: Dictionary) -> bool:
	if active_bipob_ref == null:
		return false
	if not active_bipob_ref.has_method("get_grid_position"):
		return false
	var actor_cell: Variant = active_bipob_ref.call("get_grid_position")
	if typeof(actor_cell) != TYPE_VECTOR2I:
		return false
	for platform_cell_variant in Array(platform.get("platform_cells", [])):
		var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
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
				var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
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
			var world_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
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
			var local_switch := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
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
			var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			var object_platform := get_platform_for_cell(object_cell)
			if not object_platform.is_empty() and String(object_platform.get("platform_type", "")) == "lifting":
				var expected_platform_id := String(object_platform.get("platform_id", "")).strip_edges()
				warnings.append("Object %s stands on lifting platform %s but carried_by_platform_id is missing." % [object_id, expected_platform_id])
			continue
		if not platform_ids.has(carried_platform_id):
			warnings.append("Object %s references missing carried_by_platform_id %s." % [object_id, carried_platform_id])
			continue
		var object_cell_with_carried := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
			var platform_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
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
			var object_cell := WorldObjectCatalogRef.to_world_cell(world_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
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
		var world_cell := WorldObjectCatalogRef.to_world_cell(cell, Vector2i(-1, -1))
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
		var world_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
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
		var switch_cell := WorldObjectCatalogRef.to_world_cell(lifting_platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
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
	var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
	if platform_cell == Vector2i(-1, -1):
		warnings.append("Lifting platform first platform cell is invalid.")
		return warnings
	var floor_cell := _find_debug_floor_cell_near_platform(platform_cells, platform_cell)
	if floor_cell == Vector2i(-1, -1):
		warnings.append("No normal floor cell found near lifting platform for height gating validation.")
		return warnings
	var same_height_platform_cell := platform_cell
	if platform_cells.size() > 1:
		same_height_platform_cell = WorldObjectCatalogRef.to_world_cell(platform_cells[1], platform_cell)
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

func get_terminal_hack_requirements(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var required_connector_level := int(terminal.get("required_connector_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var required_processor_level := int(terminal.get("required_processor_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var capabilities := get_actor_capability_levels()
	var available_connector_level := int(capabilities.get("connector_level", 0))
	var available_processor_level := int(capabilities.get("processor_level", 0))
	var reasons: Array[String] = []
	if terminal.is_empty():
		reasons.append("terminal_missing")
	else:
		if not _is_terminal_powered_for_interaction(terminal):
			reasons.append("terminal_unpowered")
		if bool(terminal.get("damaged", false)) or String(terminal.get("state", "")).to_lower() == "damaged":
			reasons.append("terminal_damaged")
	if available_connector_level < required_connector_level:
		reasons.append("connector_level_too_low")
	if available_processor_level < required_processor_level:
		reasons.append("processor_level_too_low")
	var heat_preview := {"would_overheat": false, "current_heat": 0, "hack_heat": 0, "overheat_threshold": 0, "projected_heat": 0}
	if not terminal.is_empty():
		var current_heat := int(terminal.get("current_heat", terminal.get("working_heat", 0)))
		var hack_heat := int(terminal.get("hack_heat", 0))
		var threshold := int(terminal.get("overheat_threshold", 99999))
		var projected := current_heat + hack_heat
		heat_preview = {"would_overheat": projected > threshold, "current_heat": current_heat, "hack_heat": hack_heat, "overheat_threshold": threshold, "projected_heat": projected}
	if bool(heat_preview.get("would_overheat", false)):
		reasons.append("hack_would_overheat")
	if reasons.is_empty():
		reasons.append("ok")
	return {"can_hack": reasons.size() == 1 and reasons[0] == "ok", "terminal_id": terminal_id, "required_connector_level": required_connector_level, "required_processor_level": required_processor_level, "available_connector_level": available_connector_level, "available_processor_level": available_processor_level, "reasons": reasons, "heat_preview": heat_preview}

func get_terminal_action_availability(terminal_id: String, action: String = "") -> Dictionary:
	var report := {"available": false, "terminal_id": terminal_id, "action": action, "reasons": [], "requirements": {}, "state": "", "is_powered": true}
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty():
		report["reasons"] = ["terminal_missing"]
		return report
	if not _is_terminal_object(terminal):
		report["reasons"] = ["not_terminal"]
		return report
	var state := String(terminal.get("state", "active")).strip_edges().to_lower()
	report["state"] = state
	var powered := bool(terminal.get("is_powered", true)) if terminal.has("is_powered") else true
	report["is_powered"] = powered
	var reasons: Array[String] = []
	if bool(terminal.get("damaged", false)) or state == "damaged": reasons.append("terminal_damaged")
	if bool(terminal.get("broken", false)) or state == "broken": reasons.append("terminal_broken")
	if bool(terminal.get("destroyed", false)) or state == "destroyed": reasons.append("terminal_destroyed")
	if state == "overheated": reasons.append("terminal_overheated")
	if state in ["unpowered", "disabled"] or (terminal.has("is_powered") and not powered): reasons.append("terminal_unpowered")
	var req := get_terminal_hack_requirements(terminal_id) if action == "hack" else {}
	report["requirements"] = req
	if action == "hack":
		if req.get("reasons", []).has("connector_level_too_low"): reasons.append("connector_level_too_low")
		if req.get("reasons", []).has("processor_level_too_low"): reasons.append("processor_level_too_low")
	if reasons.is_empty():
		report["available"] = true
		report["reasons"] = ["ok"]
	else:
		report["reasons"] = reasons
	return report

func attempt_terminal_hack(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var before := String(terminal.get("state", "")) if not terminal.is_empty() else ""
	var req := get_terminal_hack_requirements(terminal_id)
	if not bool(req.get("can_hack", false)):
		return {"success": false, "terminal_id": terminal_id, "reasons": req.get("reasons", []), "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	if String(terminal.get("state", "")) == "hacked":
		return {"success": false, "terminal_id": terminal_id, "reasons": ["already_hacked"], "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	terminal["state"] = "hacked"
	terminal["hacked"] = true
	terminal["hack_attempts"] = int(terminal.get("hack_attempts", 0)) + 1
	return {"success": true, "terminal_id": terminal_id, "reasons": ["ok"], "state_before": before, "state_after": "hacked", "heat_report": req.get("heat_preview", {})}


func get_terminal_control_targets(terminal_id: String) -> Array[Dictionary]:
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty(): return []
	var out: Array[Dictionary] = []
	for key in ["target_door_id","target_platform_id","target_object_id","linked_object_id"]:
		var tid := String(terminal.get(key, "")).strip_edges()
		if tid != "": out.append({"target_id":tid, "source":key})
	for tidv in Array(terminal.get("controlled_object_ids", [])):
		var tid := String(tidv).strip_edges()
		if tid != "": out.append({"target_id":tid, "source":"controlled_object_ids"})
	return out

func execute_terminal_control_action(terminal_id: String, target_id: String = "", action: String = "") -> Dictionary:
	var avail := get_terminal_action_availability(terminal_id, action)
	if not bool(avail.get("available", false)): return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":avail.get("reasons", [])}
	var targets := get_terminal_control_targets(terminal_id)
	var allowed := target_id.strip_edges().is_empty()
	for t in targets:
		if String(t.get("target_id", "")) == target_id: allowed = true
	if not allowed: return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":["target_invalid"]}
	var target := get_world_object_by_id(target_id) if target_id != "" else {}
	if action == "open_door" and not target.is_empty(): target["state"] = "open"; target["is_open"] = true; target["is_locked"] = false; target["locked"] = false; target["blocks_movement"] = false
	elif action == "close_door" and not target.is_empty(): target["state"] = "closed"; target["is_open"] = false; target["blocks_movement"] = true
	elif action == "unlock_door" and not target.is_empty(): target["is_locked"] = false; target["locked"] = false
	elif action == "lock_door" and not target.is_empty(): target["is_locked"] = true; target["locked"] = true
	elif action in ["activate_platform","toggle_platform","rotate_platform"] and not target.is_empty():
		activate_platform_by_id(String(target.get("platform_id", target_id)), "terminal")
	elif action == "enable_cooling":
		apply_cooling_application()
	elif action == "reset_source_overheat":
		execute_power_source_recovery_apply()
	return {"success":true, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":["ok"]}

func get_door_access_state(door_id: String) -> Dictionary:
	var door := get_world_object_by_id(door_id)
	if door.is_empty(): return {"door_id":door_id, "can_open":false, "can_unlock":false, "is_locked":true, "is_open":false, "is_powered":false, "reasons":["door_missing"], "lock_type":"", "door_class":0}
	var lock_type := String(door.get("lock_type", "none"))
	var is_locked := bool(door.get("is_locked", door.get("locked", lock_type != "none")))
	var is_open := String(door.get("state", "closed")) == "open"
	var powered := bool(door.get("is_powered", true))
	var reasons: Array[String] = []
	if String(door.get("state", "")).to_lower() == "destroyed": reasons.append("door_destroyed")
	elif is_locked: reasons.append("locked")
	else: reasons.append("ok")
	return {"door_id":door_id, "can_open":reasons.has("ok"), "can_unlock":is_locked, "is_locked":is_locked, "is_open":is_open, "is_powered":powered, "reasons":reasons, "lock_type":lock_type, "door_class":int(door.get("door_class", 1))}

func can_use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var door := get_world_object_by_id(door_id)
	var item := get_world_object_by_id(item_id)
	if item.is_empty(): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["item_missing"]}
	if door.is_empty(): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["door_missing"]}
	var lock_type := String(door.get("lock_type", "none"))
	var digital_state := String(item.get("digital_state", ""))
	if item_id.find("damaged") != -1 or digital_state == "damaged": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["digital_key_damaged"]}
	if item_id.find("encrypted") != -1 or digital_state == "encrypted": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["digital_key_encrypted"]}
	if lock_type == "mechanical_key" and String(item.get("key_kind", "")) != "mechanical": return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["wrong_key_type"]}
	return {"success":true, "item_id":item_id, "door_id":door_id, "reasons":["ok"]}

func use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var gate := can_use_access_item_on_door(item_id, door_id)
	var door := get_world_object_by_id(door_id)
	var before := String(door.get("state", "")) if not door.is_empty() else ""
	if not bool(gate.get("success", false)): return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":gate.get("reasons", []), "door_state_before":before, "door_state_after":before, "consumed":false}
	door["state"] = "open"; door["is_open"] = true; door["is_locked"] = false; door["locked"] = false; door["blocks_movement"] = false
	return {"success":true, "item_id":item_id, "door_id":door_id, "reasons":["ok"], "door_state_before":before, "door_state_after":"open", "consumed":false}

func use_inventory_item_on_world_object(item_id: String, target_id: String, action: String = "") -> Dictionary:
	var out := {"success": false, "item_id": item_id, "target_id": target_id, "action": action, "reasons": [], "consumed": false, "target_state_before": "", "target_state_after": "", "side_effects": {}}
	var item := get_world_object_by_id(item_id)
	var target := get_world_object_by_id(target_id)
	if item.is_empty():
		out["reasons"] = ["item_missing"]
		return out
	if target.is_empty():
		out["reasons"] = ["target_missing"]
		return out
	var item_type := String(item.get("item_type", item.get("object_type", item_id)))
	var before := String(target.get("state", ""))
	out["target_state_before"] = before
	if item_type == "fuse" and String(target.get("object_type", "")) in ["fuse_box_empty", "fuse_box_installed"]:
		if String(target.get("state", "")) == "installed":
			out["reasons"] = ["fuse_already_installed"]
			return out
		target["state"] = "installed"
		out["side_effects"] = apply_power_network_after_explicit_power_event("fuse_inserted", String(target.get("power_network_id", "")))
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "repair_kit":
		if bool(target.get("destroyed", false)) or String(target.get("state", "")) == "destroyed":
			out["reasons"] = ["target_destroyed"]
			return out
		if not (bool(target.get("damaged", false)) or bool(target.get("broken", false)) or String(target.get("state", "")) in ["damaged", "broken"]):
			out["reasons"] = ["already_repaired"]
			return out
		target["damaged"] = false
		target["broken"] = false
		if String(target.get("state", "")) in ["damaged", "broken"]:
			target["state"] = "active"
		if String(target.get("object_type", "")) == "power_cable":
			target["disconnected"] = true
			target["connected"] = false
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "power_cable_reel":
		var report := connect_cable_reel_to_target(item_id, target_id)
		out["success"] = bool(report.get("success", false))
		out["reasons"] = report.get("reasons", ["cable_connect_failed"])
		out["side_effects"] = report
	elif item_type in ["mechanical_keycard", "digital_key", "access_code"]:
		var access_report := use_access_item_on_door(item_id, target_id)
		out["success"] = bool(access_report.get("success", false))
		out["reasons"] = access_report.get("reasons", ["access_denied"])
		out["side_effects"] = access_report
	else:
		out["reasons"] = ["wrong_item_type"]
		return out
	out["target_state_after"] = String(target.get("state", before))
	return out

func get_door_debug_report_text(door_id: String = "") -> String:
	var ids: Array[String] = []
	if door_id.strip_edges() != "": ids.append(door_id)
	else:
		for obj in mission_world_objects:
			if String(obj.get("object_group", "")) == "door": ids.append(String(obj.get("id", "")))
	var lines: Array[String] = []
	for id in ids:
		var st := get_door_access_state(id)
		lines.append("%s | lock=%s | locked=%s | powered=%s | reasons=%s" % [id, String(st.get("lock_type", "")), str(bool(st.get("is_locked", false))), str(bool(st.get("is_powered", true))), ",".join(Array(st.get("reasons", [])))])
	return "\n".join(lines)

func validate_terminal_and_door_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var base_size := mission_world_objects.size()
	var world_snapshot := get_world_object_runtime_state()
	var temp_ids: Array[String] = []
	var terminal_id := "temp_validation_terminal"
	var linked_door_id := "temp_validation_door_linked"
	var unlinked_door_id := "temp_validation_door_unlinked"
	var mechanical_door_id := "temp_validation_door_mechanical"
	var digital_door_id := "temp_validation_door_digital"
	var terminal := {"id": terminal_id, "object_group": "terminal", "object_type": "terminal", "position": Vector2i(100, 100), "state": "active", "is_powered": true, "required_connector_level": 0, "required_processor_level": 0, "target_door_id": linked_door_id}
	var linked_door := {"id": linked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(101, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var unlinked_door := {"id": unlinked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(102, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var mechanical_door := {"id": mechanical_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(103, 100), "state": "closed", "is_locked": true, "lock_type": "mechanical_key", "is_powered": true}
	var digital_door := {"id": digital_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(104, 100), "state": "closed", "is_locked": true, "lock_type": "access_code", "is_powered": true}
	for obj in [terminal, linked_door, unlinked_door, mechanical_door, digital_door]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
		temp_ids.append(String(obj.get("id", "")))
	var av := get_terminal_action_availability(terminal_id, "hack")
	if not bool(av.get("available", false)): warnings.append("active_powered_terminal_unavailable")
	terminal["is_powered"] = false
	var unpowered := get_terminal_action_availability(terminal_id, "hack")
	if not Array(unpowered.get("reasons", [])).has("terminal_unpowered"): warnings.append("terminal_unpowered_reason_missing")
	terminal["is_powered"] = true
	terminal["damaged"] = true
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("terminal_damaged"): warnings.append("terminal_damaged_reason_missing")
	terminal["damaged"] = false
	terminal["required_connector_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("connector_level_too_low"): warnings.append("connector_level_gate_missing")
	terminal["required_connector_level"] = 0
	terminal["required_processor_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("processor_level_too_low"): warnings.append("processor_level_gate_missing")
	terminal["required_processor_level"] = 0
	var before_preview := str(get_world_object_runtime_state().get(terminal_id, {}))
	get_terminal_hack_requirements(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_preview: warnings.append("terminal_hack_preview_mutated_state")
	terminal["required_connector_level"] = 2
	var before_fail := str(get_world_object_runtime_state().get(terminal_id, {}))
	attempt_terminal_hack(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_fail: warnings.append("failed_hack_mutated_state")
	terminal["required_connector_level"] = 0
	terminal["state"] = "hacked"
	if not Array(attempt_terminal_hack(terminal_id).get("reasons", [])).has("already_hacked"): warnings.append("already_hacked_reason_missing")
	terminal["state"] = "active"
	if not bool(execute_terminal_control_action(terminal_id, linked_door_id, "unlock_door").get("success", false)): warnings.append("linked_door_control_failed")
	if bool(execute_terminal_control_action(terminal_id, unlinked_door_id, "unlock_door").get("success", false)): warnings.append("unlinked_door_control_should_fail")
	var mechanical_key := {"id":"temp_validation_mechanical_key", "object_group":"item", "object_type":"item", "position":Vector2i(105, 100), "key_kind":"mechanical", "item_type":"mechanical_keycard"}
	var wrong_key := {"id":"temp_validation_wrong_key", "object_group":"item", "object_type":"item", "position":Vector2i(106, 100), "item_type":"digital_key"}
	var damaged_key := {"id":"temp_validation_damaged_key", "object_group":"item", "object_type":"item", "position":Vector2i(107, 100), "item_type":"digital_key", "digital_state":"damaged"}
	var encrypted_key := {"id":"temp_validation_encrypted_key", "object_group":"item", "object_type":"item", "position":Vector2i(108, 100), "item_type":"digital_key", "digital_state":"encrypted"}
	var good_digital := {"id":"temp_validation_good_digital", "object_group":"item", "object_type":"item", "position":Vector2i(109, 100), "item_type":"access_code"}
	for key_obj in [mechanical_key, wrong_key, damaged_key, encrypted_key, good_digital]:
		mission_world_objects.append(key_obj); world_objects_by_cell[Vector2i(key_obj.get("position", Vector2i(-1, -1)))] = key_obj; temp_ids.append(String(key_obj.get("id", "")))
	if not bool(can_use_access_item_on_door(mechanical_key["id"], mechanical_door_id).get("success", false)): warnings.append("mechanical_key_gate_failed")
	var wrong_before := str(get_world_object_runtime_state().get(mechanical_door_id, {}))
	if bool(use_access_item_on_door(wrong_key["id"], mechanical_door_id).get("success", false)): warnings.append("wrong_key_should_fail")
	if str(get_world_object_runtime_state().get(mechanical_door_id, {})) != wrong_before: warnings.append("wrong_key_mutated_door")
	if not Array(use_access_item_on_door(damaged_key["id"], digital_door_id).get("reasons", [])).has("digital_key_damaged"): warnings.append("digital_key_damaged_missing")
	if not Array(use_access_item_on_door(encrypted_key["id"], digital_door_id).get("reasons", [])).has("digital_key_encrypted"): warnings.append("digital_key_encrypted_missing")
	if not bool(use_access_item_on_door(good_digital["id"], digital_door_id).get("success", false)): warnings.append("digital_access_open_failed")
	var door_debug_before := str(get_world_object_runtime_state())
	get_door_debug_report_text()
	if str(get_world_object_runtime_state()) != door_debug_before: warnings.append("door_debug_mutated_state")
	var runtime_snap := get_world_object_runtime_state()
	if not Dictionary(runtime_snap.get(terminal_id, {})).has("state"): warnings.append("runtime_snapshot_terminal_state_missing")
	if not Dictionary(runtime_snap.get(digital_door_id, {})).has("is_locked"): warnings.append("runtime_snapshot_door_lock_missing")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := String(mission_world_objects[i].get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	if mission_world_objects.size() != base_size:
		warnings.append("terminal_door_cleanup_world_size_changed")
	return warnings

func get_terminal_and_door_validation_text() -> String:
	var warnings := validate_terminal_and_door_runtime()
	return "TerminalDoorValidation: warnings=%d" % warnings.size()

func get_scan_result_for_object(object_id: String, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		return {"ok": false, "reason": "object_missing", "scan_mode": scan_mode}
	if not is_world_object_visible_to_player(object_data, scan_mode):
		return {"ok": false, "reason": "not_visible", "scan_mode": scan_mode}
	var result := {"ok": true, "scan_mode": scan_mode, "object_id": object_id, "object_type": String(object_data.get("object_type", "")), "state": String(object_data.get("state", ""))}
	if scan_mode in ["diagnostic", "power", "platform"]:
		result["power_reason"] = String(object_data.get("power_unavailable_reason", ""))
	if scan_mode in ["diagnostic", "cooling"]:
		result["cooling_received"] = int(object_data.get("cooling_received", 0))
		result["cooling_source_ids"] = object_data.get("cooling_source_ids", [])
	if scan_mode in ["diagnostic", "platform"] and String(object_data.get("object_group", "")) == "platform":
		result["platform"] = get_platform_action_availability(String(object_data.get("platform_id", "")), "activate")
	if scan_mode == "xray":
		result["xray_objects"] = get_xray_visible_objects(String(object_data.get("power_network_id", "")))
	return result

func get_scan_result_for_cell(cell: Vector2i, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return {"ok": true, "scan_mode": scan_mode, "cell": [cell.x, cell.y], "object": {}}
	return get_scan_result_for_object(String(object_data.get("id", "")), scan_mode)

func get_scan_text_for_object(object_id: String, scan_mode: String = "basic") -> String:
	return JSON.stringify(get_scan_result_for_object(object_id, scan_mode))

func validate_platform_scan_visibility_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var platform := get_platform_by_id("platform_lift_a")
	if not platform.is_empty():
		var av := get_platform_action_availability(String(platform.get("platform_id", "")), "activate")
		if not av.has("available"):
			warnings.append("platform availability helper missing fields")
	var snapshot_a := str(get_world_object_runtime_state())
	get_scan_result_for_cell(Vector2i.ZERO, "basic")
	var snapshot_b := str(get_world_object_runtime_state())
	if snapshot_a != snapshot_b:
		warnings.append("scan/report helpers are not read-only")
	var hidden_cable := {"id":"temp_hidden_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(140, 100), "hidden":true, "hidden_cable":true, "visible_with_xray":true}
	mission_world_objects.append(hidden_cable)
	world_objects_by_cell[Vector2i(140, 100)] = hidden_cable
	var basic_visible := is_world_object_visible_to_player(hidden_cable, "basic")
	var xray_result := get_scan_result_for_object("temp_hidden_cable", "xray")
	if basic_visible:
		warnings.append("basic_scan_should_hide_hidden_cable")
	if not bool(xray_result.get("ok", false)):
		warnings.append("xray_scan_should_report_hidden_cable")
	var reveal_before := str(get_world_object_runtime_state().get("temp_hidden_cable", {}))
	reveal_xray_objects("")
	var reveal_after: Dictionary = get_world_object_runtime_state().get("temp_hidden_cable", {})
	if not bool(reveal_after.get("revealed", false)) or not bool(reveal_after.get("discovered", false)):
		warnings.append("reveal_xray_objects_did_not_mark_revealed_discovered")
	if reveal_before == str(reveal_after):
		warnings.append("reveal_xray_objects_no_effect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		if String(mission_world_objects[i].get("id", "")) == "temp_hidden_cable":
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	return warnings

func get_platform_scan_visibility_validation_text() -> String:
	var warnings := validate_platform_scan_visibility_runtime()
	if warnings.is_empty():
		return "PlatformScanVisibilityValidation: ok"
	return "PlatformScanVisibilityValidation:\n- " + "\n- ".join(warnings)

func validate_inventory_tools_modules_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var inventory_snapshot := runtime_inventory_state.duplicate(true)
	var world_snapshot := get_world_object_runtime_state()
	var temp_ids: Array[String] = []
	var caps := get_actor_capability_levels()
	if not caps.has("manipulator_level") or not caps.has("connector_level") or not caps.has("processor_level"):
		warnings.append("capability_defaults_missing")
	var req_obj := {"id":"temp_req_obj", "object_group":"item", "object_type":"item", "position":Vector2i(120, 100), "required_manipulator_level":1, "required_connector_level":1, "required_processor_level":1}
	mission_world_objects.append(req_obj); world_objects_by_cell[Vector2i(120, 100)] = req_obj; temp_ids.append("temp_req_obj")
	var req := check_world_object_requirements("temp_req_obj", "use")
	for r in ["manipulator_level_too_low","connector_level_too_low","processor_level_too_low"]:
		if not Array(req.get("reasons", [])).has(r): warnings.append("requirements_missing_%s" % r)
	var physical_item := {"id":"temp_item_physical", "object_group":"item", "object_type":"item", "position":Vector2i(121, 100), "item_type":"fuse", "item_form":"physical", "can_pickup":true}
	var digital_item := {"id":"temp_item_digital", "object_group":"item", "object_type":"item", "position":Vector2i(122, 100), "item_form":"digital", "can_place_in_digital_buffer":true}
	var digital_blocked := {"id":"temp_item_digital_blocked", "object_group":"item", "object_type":"item", "position":Vector2i(123, 100), "item_form":"digital", "can_place_in_digital_buffer":false}
	for obj in [physical_item, digital_item, digital_blocked]:
		mission_world_objects.append(obj); world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj; temp_ids.append(String(obj.get("id", "")))
	if not bool(pickup_world_item("temp_item_physical").get("success", false)): warnings.append("physical_pickup_failed")
	if not bool(pickup_world_item("temp_item_digital").get("success", false)): warnings.append("digital_pickup_allowed_failed")
	if bool(pickup_world_item("temp_item_digital_blocked").get("success", false)): warnings.append("digital_pickup_block_missing")
	runtime_inventory_state["manipulator_hold"] = "occupied_slot"
	if bool(hold_item_in_manipulator("temp_item_physical").get("success", false)): warnings.append("manipulator_single_item_gate_missing")
	runtime_inventory_state["manipulator_hold"] = ""
	var inv_before_fail := str(get_inventory_state())
	drop_inventory_item("missing_item")
	if str(get_inventory_state()) != inv_before_fail: warnings.append("failed_inventory_action_mutated_state")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := String(mission_world_objects[i].get("id", ""))
		if temp_ids.has(oid):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	runtime_inventory_state = inventory_snapshot.duplicate(true)
	return warnings

func get_inventory_tools_modules_validation_text() -> String:
	var warnings := validate_inventory_tools_modules_runtime()
	return "InventoryToolsModulesValidation: ok" if warnings.is_empty() else "InventoryToolsModulesValidation:\n- " + "\n- ".join(warnings)

func validate_full_runtime_persistence() -> Array[String]:
	var warnings: Array[String] = []
	var snap := get_world_object_runtime_state()
	if snap.is_empty() and not mission_world_objects.is_empty():
		warnings.append("world_runtime_snapshot_empty")
	var inv := get_inventory_state()
	for field_name in ["pocket_items", "manipulator_hold", "digital_buffer", "item_amounts", "consumed_item_ids", "world_item_runtime"]:
		if not inv.has(field_name):
			warnings.append("inventory_field_missing_%s" % field_name)
	return warnings

func _get_mission10_layout_for_validation() -> Array:
	if grid_manager != null and grid_manager.has_method("get_mission10_layout"):
		return Array(grid_manager.call("get_mission10_layout"))
	var temporary_grid: GridManager = GridManager.new()
	var layout: Array = Array(temporary_grid.get_mission10_layout())
	temporary_grid.free()
	return layout

func validate_task_test_mission_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var built := build_task_test_mission_world_objects_for_validation()
	warnings.append_array(Array(built.get("warnings", [])))
	var task_objects: Array[Dictionary] = built.get("objects", [])
	var task_items_by_cell: Dictionary = built.get("items_by_cell", {})
	var task_ids := {}
	var occupied_cells := {}
	for obj in task_objects:
		var oid := String(obj.get("id", "")).strip_edges()
		if not oid.begins_with("task_test_"):
			continue
		if task_ids.has(oid):
			warnings.append("duplicate_task_test_id_%s" % oid)
		task_ids[oid] = true
		if String(obj.get("object_type", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_type_%s" % oid)
		if String(obj.get("object_group", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_group_%s" % oid)
		var cell := Vector2i(obj.get("position", Vector2i.ZERO))
		if not bool(obj.get("allow_cell_overlap", false)) and occupied_cells.has(cell):
			warnings.append("duplicate_task_test_cell_%s_between_%s_and_%s" % [str(cell), String(occupied_cells[cell]), oid])
		occupied_cells[cell] = oid
	for required_id in ["task_test_extraction_door","task_test_source_class_1","task_test_radiator","task_test_terminal_main","task_test_door_mechanical","task_test_platform_lift","task_test_hidden_cable","task_test_item_repair_kit","task_test_cable_reel"]:
		if not task_ids.has(required_id):
			var exists_item := false
			for cell in task_items_by_cell.keys():
				for item in Array(task_items_by_cell[cell]):
					if String(item.get("id", "")) == required_id:
						exists_item = true
						break
				if exists_item:
					break
			if not exists_item:
				warnings.append("missing_%s" % required_id)
	var extraction: Dictionary = {}
	for obj in task_objects:
		if String(obj.get("id", "")) == "task_test_extraction_door":
			extraction = obj
			break
	if extraction.is_empty() or not bool(extraction.get("mission_exit", false)):
		warnings.append("task_test_extraction_not_flagged")
	else:
		if not bool(extraction.get("extraction", false)):
			warnings.append("task_test_extraction_missing_extraction_flag")
		if String(extraction.get("state", "")) != "open":
			warnings.append("task_test_extraction_not_open")
		if bool(extraction.get("is_locked", false)):
			warnings.append("task_test_extraction_locked")
	var xray_exists := task_ids.has("task_test_xray_route_marker")
	if not xray_exists:
		warnings.append("task_test_xray_route_marker_missing")
	var exit_cell := Vector2i(6, 6)
	var extraction_cell := Vector2i(extraction.get("position", Vector2i(-999, -999)))
	if extraction_cell != exit_cell and extraction_cell.distance_to(exit_cell) > 1.0:
		warnings.append("task_test_extraction_not_on_or_adjacent_to_exit")
	var mission_layout: Array = _get_mission10_layout_for_validation()
	var exit_tiles := 0
	var layout_exit_cell := Vector2i(-999, -999)
	for y in range(mission_layout.size()):
		for x in range(Array(mission_layout[y]).size()):
			if int(Array(mission_layout[y])[x]) == GridManager.TILE_EXIT:
				exit_tiles += 1
				layout_exit_cell = Vector2i(x, y)
	if exit_tiles != 1:
		warnings.append("task_test_layout_exit_tile_count_%d" % exit_tiles)
	elif extraction_cell != layout_exit_cell and extraction_cell.distance_to(layout_exit_cell) > 1.0:
		warnings.append("task_test_extraction_cell_not_matching_layout_exit")
	return warnings

func get_task_test_system_coverage_report() -> Dictionary:
	var report: Dictionary = {
		"total_objects": 0,
		"counts_by_object_type": {},
		"counts_by_object_group": {},
		"door_cells": [],
		"powered_objects": [],
		"controlled_objects": [],
		"key_locked_doors": [],
		"cooling_objects": [],
		"hidden_xray_thermal_objects": []
	}
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		report["total_objects"] = int(report.get("total_objects", 0)) + 1
		var object_type: String = String(object_data.get("object_type", ""))
		var object_group: String = String(object_data.get("object_group", ""))
		var counts_type: Dictionary = report.get("counts_by_object_type", {})
		counts_type[object_type] = int(counts_type.get(object_type, 0)) + 1
		report["counts_by_object_type"] = counts_type
		var counts_group: Dictionary = report.get("counts_by_object_group", {})
		counts_group[object_group] = int(counts_group.get(object_group, 0)) + 1
		report["counts_by_object_group"] = counts_group
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		var runtime_state: Dictionary = get_runtime_cell_state(cell)
		var lock_type: String = String(object_data.get("lock_type", ""))
		var object_state: String = String(object_data.get("state", "")).to_lower()
		var is_door: bool = object_type.find("door") >= 0 or lock_type != ""
		if is_door:
			report["door_cells"].append({"cell": cell, "object_id": String(object_data.get("id", "")), "state": object_state, "is_passable": bool(runtime_state.get("is_passable", false)), "block_reason": String(runtime_state.get("block_reason", ""))})
		if bool(object_data.get("is_powered", false)) or object_data.has("power_network_id"):
			report["powered_objects"].append({"object_id": String(object_data.get("id", "")), "power_network_id": String(object_data.get("power_network_id", ""))})
		var control_source_id: String = String(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", ""))))
		if not control_source_id.is_empty() or bool(object_data.get("requires_external_control", false)):
			report["controlled_objects"].append({"object_id": String(object_data.get("id", "")), "control_source_id": control_source_id, "linked_terminal_id": String(object_data.get("linked_terminal_id", ""))})
		if bool(object_data.get("requires_key", false)) or lock_type == "mechanical_key" or lock_type == "digital_key":
			report["key_locked_doors"].append({"object_id": String(object_data.get("id", "")), "required_key_id": String(object_data.get("required_key_id", "")), "lock_type": lock_type})
		if object_group == "cooling":
			report["cooling_objects"].append({"object_id": String(object_data.get("id", "")), "object_type": object_type})
		if bool(object_data.get("hidden", false)) or bool(object_data.get("visible_with_xray", false)) or bool(object_data.get("visible_with_thermal", false)):
			report["hidden_xray_thermal_objects"].append({"object_id": String(object_data.get("id", "")), "hidden": bool(object_data.get("hidden", false)), "xray": bool(object_data.get("visible_with_xray", false)), "thermal": bool(object_data.get("visible_with_thermal", false))})
	return report

func get_task_test_system_coverage_report_text() -> String:
	var report: Dictionary = get_task_test_system_coverage_report()
	var lines: Array[String] = []
	lines.append("TaskTestSystemCoverage: total_objects=%d" % int(report.get("total_objects", 0)))
	lines.append("By type: %s" % JSON.stringify(report.get("counts_by_object_type", {})))
	lines.append("By group: %s" % JSON.stringify(report.get("counts_by_object_group", {})))
	lines.append("Door cells: %s" % JSON.stringify(report.get("door_cells", [])))
	lines.append("Powered objects: %s" % JSON.stringify(report.get("powered_objects", [])))
	lines.append("Controlled objects: %s" % JSON.stringify(report.get("controlled_objects", [])))
	lines.append("Key locked doors: %s" % JSON.stringify(report.get("key_locked_doors", [])))
	lines.append("Cooling objects: %s" % JSON.stringify(report.get("cooling_objects", [])))
	lines.append("Hidden/Xray/Thermal objects: %s" % JSON.stringify(report.get("hidden_xray_thermal_objects", [])))
	return "\n".join(lines)

func validate_task_test_runtime_cell_states() -> Array[String]:
	var warnings: Array[String] = []
	var task_item_ids: Array[String] = []
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			task_item_ids.append(String(Dictionary(item_variant).get("id", "")))
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var object_id: String = String(object_data.get("id", ""))
		var object_type: String = String(object_data.get("object_type", "")).to_lower()
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		var runtime_state: Dictionary = get_runtime_cell_state(cell)
		if not bool(runtime_state.get("has_object", false)):
			warnings.append("object_exists_but_runtime_has_no_object_%s" % object_id)
		var state_name: String = String(object_data.get("state", "")).to_lower()
		var canonical_open: bool = state_name == "open" or state_name == "opened" or bool(object_data.get("is_open", false))
		var is_door: bool = object_type.find("door") >= 0 or String(object_data.get("lock_type", "")) != ""
		if is_door and canonical_open and not bool(runtime_state.get("is_passable", false)):
			warnings.append("door_open_not_passable_%s" % object_id)
		if is_door and (state_name == "closed" or state_name == "locked" or bool(object_data.get("is_locked", false))) and bool(runtime_state.get("is_passable", false)):
			warnings.append("door_closed_or_locked_but_passable_%s" % object_id)
		if bool(object_data.get("requires_external_power", false)) and String(object_data.get("power_network_id", "")).is_empty():
			warnings.append("external_power_missing_network_%s" % object_id)
		if bool(object_data.get("requires_external_control", false)):
			var ctrl: String = String(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", ""))))
			if ctrl.is_empty():
				warnings.append("external_control_missing_reference_%s" % object_id)
		if (bool(object_data.get("requires_key", false)) or String(object_data.get("lock_type", "")) == "mechanical_key" or String(object_data.get("lock_type", "")) == "digital_key") and String(object_data.get("required_key_id", "")).is_empty():
			warnings.append("key_locked_door_missing_required_key_%s" % object_id)
		var required_key_id: String = String(object_data.get("required_key_id", ""))
		if not required_key_id.is_empty() and not task_item_ids.has(required_key_id):
			warnings.append("required_key_not_in_task_items_%s_%s" % [object_id, required_key_id])
		if bool(object_data.get("blocks_movement", false)) and bool(runtime_state.get("is_passable", false)) and not (is_door and canonical_open):
			warnings.append("blocking_object_marked_passable_%s" % object_id)
	return warnings

func get_task_test_mission_validation_text() -> String:
	var warnings := validate_task_test_mission_runtime()
	return "TaskTestValidation: ok" if warnings.is_empty() else "TaskTestValidation:\n- " + "\n- ".join(warnings)




func _build_task_test_module_port_specs() -> Array[Dictionary]:
	# TASK TEST module-port scenario data shared across validation checks.
	return [
		{"id":"task_test_internal_interface_v1","module_id":"internal_interface_v1"},
		{"id":"task_test_external_interface_v1","module_id":"external_interface_v1"},
		{"id":"task_test_power_block_v1","module_id":"power_block_v1"},
		{"id":"task_test_processor_v1","module_id":"processor_v1"},
		{"id":"task_test_processor_v2","module_id":"processor_v2"},
		{"id":"task_test_wired_connector_v1","module_id":"wired_connector_v1"},
		{"id":"task_test_optical_connector_v1","module_id":"optical_connector_v1"},
		{"id":"task_test_extra_external_tool","module_id":"repair_v1"},
		{"id":"task_test_battery_v1","module_id":"battery_v1"},
		{"id":"task_test_cooler_v1","module_id":"cooler_v1"},
		{"id":"task_test_radiator_v1","module_id":"radiator_v1"}
	]

func _simulate_task_test_port_state(specs: Array[Dictionary], active_module_ids: Array[String], internal_ports_total: int, external_ports_total: int, power_ports_total: int) -> Dictionary:
	# Static fallback simulation kept for compatibility/safety when runtime mutation is unavailable.
	var modules: Dictionary = {}
	var sorted_specs := specs.duplicate()
	sorted_specs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(active_bipob_ref.call("_get_module_port_priority", String(a.get("module_id", ""))))
		var pb := int(active_bipob_ref.call("_get_module_port_priority", String(b.get("module_id", ""))))
		if pa == pb:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return pa < pb
	)
	var internal_remaining := maxi(0, internal_ports_total)
	var external_remaining := maxi(0, external_ports_total)
	var power_remaining := maxi(0, power_ports_total)
	for spec in sorted_specs:
		var tid := String(spec.get("id", ""))
		var module_id := String(spec.get("module_id", ""))
		if not active_module_ids.has(tid):
			modules[tid] = {"id":tid,"active":false,"inactive_reason":"module_not_installed","port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
			continue
		var needs_internal := bool(active_bipob_ref.call("_module_requires_internal_interface_port", module_id))
		var needs_external := bool(active_bipob_ref.call("_module_requires_external_interface_port", module_id))
		var needs_power := bool(active_bipob_ref.call("_module_requires_power_block_port", module_id))
		var active := true
		var reason := "ok"
		if needs_internal and internal_remaining <= 0:
			active = false
			reason = "internal_interface_port_missing"
		elif needs_external and external_remaining <= 0:
			active = false
			reason = "external_interface_port_missing"
		elif needs_power and power_remaining <= 0:
			active = false
			reason = "power_block_port_missing"
		if active:
			if needs_internal:
				internal_remaining -= 1
			if needs_external:
				external_remaining -= 1
			if needs_power:
				power_remaining -= 1
		modules[tid] = {"id":tid,"active":active,"inactive_reason":reason,"port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
	return {"modules":modules, "internal_remaining":internal_remaining, "external_remaining":external_remaining, "power_remaining":power_remaining}

func _active_bipob_has_property(property_name: String) -> bool:
	if active_bipob_ref == null:
		return false
	for property_info in Array(active_bipob_ref.get_property_list()):
		if String(Dictionary(property_info).get("name", "")) == property_name:
			return true
	return false

func _snapshot_installed_modules_for_validation() -> Dictionary:
	if not _active_bipob_has_property("installed_modules"):
		return {"ok": false, "reason": "installed_modules_unavailable"}
	return {"ok": true, "installed_modules": Array(active_bipob_ref.installed_modules).duplicate()}

func _restore_installed_modules_from_snapshot(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("ok", false)) or not _active_bipob_has_property("installed_modules"):
		return false
	active_bipob_ref.installed_modules = Array(snapshot.get("installed_modules", [])).duplicate()
	return true

func _is_internal_runtime_module_id(module_id: String) -> bool:
	for prefix in ["internal_interface_","external_interface_","power_block_","processor_","memory_","gpu_","hard_drive_","charger_","battery_","cooler_","radiator_","water_tube_","air_duct_"]:
		if module_id.begins_with(prefix):
			return true
	return false

func _build_runtime_modules_by_id(module_ids: Array[String]) -> Array:
	var modules: Array = []
	for module_id in module_ids:
		var module = null
		if _is_internal_runtime_module_id(module_id):
			module = active_bipob_ref.call("create_internal_module", module_id, module_id, Vector3i.ONE)
		else:
			module = active_bipob_ref.call("create_external_module_by_id", module_id)
		if module == null:
			return []
		modules.append(module)
	return modules

func _preview_module_port_activity_for_module_ids(module_ids: Array[String]) -> Dictionary:
	var snapshot := _snapshot_installed_modules_for_validation()
	if not bool(snapshot.get("ok", false)):
		return {"ok": false, "reason": String(snapshot.get("reason", "snapshot_failed"))}
	var runtime_modules := _build_runtime_modules_by_id(module_ids)
	if runtime_modules.is_empty() and not module_ids.is_empty():
		_restore_installed_modules_from_snapshot(snapshot)
		return {"ok": false, "reason": "create_test_modules_failed"}
	active_bipob_ref.installed_modules = runtime_modules
	var state: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	var restored := _restore_installed_modules_from_snapshot(snapshot)
	if not restored:
		return {"ok": false, "reason": "restore_failed", "state": state}
	return {"ok": true, "state": state}

func validate_module_port_network_runtime() -> Array[String]:
	var warnings: Array[String] = []
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return ["active_bipob_missing"]
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			warnings.append("module_ports_helper_missing_%s" % helper_name)
	if warnings.any(func(warning: String) -> bool: return warning.begins_with("module_ports_helper_missing_")):
		return warnings

	var baseline: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	for key in ["modules", "internal_interface", "external_interface", "power_block"]:
		if not baseline.has(key):
			warnings.append("module_ports_missing_%s" % key)
	if not active_bipob_ref.has_method("get_module_port_debug_report"):
		warnings.append("module_ports_debug_report_missing")
	if not active_bipob_ref.has_method("get_module_port_debug_report_text"):
		warnings.append("module_ports_debug_report_text_missing")
	if warnings.has("module_ports_debug_report_missing") or warnings.has("module_ports_debug_report_text_missing"):
		return warnings
	var debug_report_a: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	var debug_report_b: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	for report_key in ["internal_ports_total", "internal_ports_used", "internal_ports_remaining", "external_ports_total", "external_ports_used", "external_ports_remaining", "power_ports_total", "power_ports_used", "power_ports_remaining", "active_modules", "inactive_modules", "modules"]:
		if not debug_report_a.has(report_key):
			warnings.append("module_ports_debug_report_missing_%s" % report_key)
	var debug_text: String = String(active_bipob_ref.call("get_module_port_debug_report_text"))
	if debug_text.strip_edges().is_empty():
		warnings.append("module_ports_debug_report_text_empty")
	if str(debug_report_a) != str(debug_report_b):
		warnings.append("module_ports_debug_report_not_read_only")
	var internal_ports_total: int = int(debug_report_a.get("internal_ports_total", 0))
	var internal_ports_used: int = int(debug_report_a.get("internal_ports_used", 0))
	var internal_ports_remaining: int = int(debug_report_a.get("internal_ports_remaining", 0))
	if internal_ports_remaining != maxi(0, internal_ports_total - internal_ports_used):
		warnings.append("module_ports_debug_report_internal_accounting_mismatch")
	var external_ports_total: int = int(debug_report_a.get("external_ports_total", 0))
	var external_ports_used: int = int(debug_report_a.get("external_ports_used", 0))
	var external_ports_remaining: int = int(debug_report_a.get("external_ports_remaining", 0))
	if external_ports_remaining != maxi(0, external_ports_total - external_ports_used):
		warnings.append("module_ports_debug_report_external_accounting_mismatch")
	var power_ports_total: int = int(debug_report_a.get("power_ports_total", 0))
	var power_ports_used: int = int(debug_report_a.get("power_ports_used", 0))
	var power_ports_remaining: int = int(debug_report_a.get("power_ports_remaining", 0))
	if power_ports_remaining != maxi(0, power_ports_total - power_ports_used):
		warnings.append("module_ports_debug_report_power_accounting_mismatch")
	var external_interface_link_ports_reserved: int = int(debug_report_a.get("external_interface_link_ports_reserved", 0))
	if external_interface_link_ports_reserved > 0 and external_ports_used < external_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_external_reserved_accounting_mismatch")
	var internal_interface_link_ports_reserved: int = int(debug_report_a.get("internal_interface_link_ports_reserved", 0))
	if internal_interface_link_ports_reserved > 0 and internal_ports_used < internal_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_internal_reserved_accounting_mismatch")

	var _known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"id":"processor_active","modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1","active":true,"reason":"ok"},
		{"id":"memory_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1","active":true,"reason":"ok"},
		{"id":"gpu_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1","active":true,"reason":"ok"},
		{"id":"hard_drive_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1","active":true,"reason":"ok"},
		{"id":"charger_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1","active":true,"reason":"ok"},
		{"id":"cooler_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1","active":true,"reason":"ok"},
		{"id":"connector_active","modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":true,"reason":"ok"},
		{"id":"external_interface_missing","modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":false,"reason":"external_interface_missing"},
		{"id":"external_interface_port_missing","modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1","active":false,"reason":"external_interface_port_missing"},
		{"id":"internal_interface_missing","modules":["power_block_v1","processor_v1"],"module":"processor_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"internal_interface_port_missing","modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1","active":false,"reason":"internal_interface_port_missing"},
		{"id":"power_block_missing","modules":["internal_interface_v1","battery_v1"],"module":"battery_v1","active":false,"reason":"power_block_missing"},
		{"id":"power_block_port_missing","modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1","active":false,"reason":"power_block_port_missing"},
		{"id":"radiator_no_internal_or_power","modules":["radiator_v1"],"module":"radiator_v1","active":true,"reason":"ok"},
		{"id":"battery_no_internal_required","modules":["power_block_v1","battery_v1"],"module":"battery_v1","active":true,"reason":"ok"},
		{"id":"power_block_requires_internal_interface","modules":["power_block_v1"],"module":"power_block_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"power_block_active_with_internal_interface","modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1","active":true,"reason":"ok"},
		{"id":"internal_interface_v1_capacity","modules":["internal_interface_v1"],"internal_ports_total":6},
		{"id":"priority_tie","modules":["internal_interface_v1","power_block_v1","processor_v1","memory_v1","gpu_v1","hard_drive_v1","charger_v1","cooler_v1","processor_v2"],"priority":true}
	]

	for scenario in scenarios:
		var runtime := _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			warnings.append("module_ports_runtime_preview_unavailable_%s" % String(runtime.get("reason", "unknown")))
			break
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var modules: Dictionary = Dictionary(state.get("modules", {}))
		if scenario.has("internal_ports_total"):
			var internal_interface_state := Dictionary(state.get("internal_interface", {}))
			if int(internal_interface_state.get("ports_total", -1)) != int(scenario.get("internal_ports_total", -1)):
				warnings.append("module_ports_internal_interface_capacity_mismatch_%s" % String(scenario.get("id", "")))
			continue
		if bool(scenario.get("priority", false)):
			var p1 := Dictionary(modules.get("processor_v1", {}))
			var p2 := Dictionary(modules.get("processor_v2", {}))
			var p1_active := bool(p1.get("active", false))
			var p2_active := bool(p2.get("active", false))
			if p1_active and p2_active:
				continue
			if p1_active == p2_active:
				warnings.append("task_test_processor_priority_tie_break_not_deterministic")
				continue
			if not p1_active and p2_active:
				warnings.append("task_test_processor_priority_tie_break_unstable_order")
			continue
		var module_id := String(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(modules.get(module_id, {}))
		if module_state.is_empty():
			warnings.append("module_not_installed")
			continue
		var expected_active := bool(scenario.get("active", false))
		var expected_reason := String(scenario.get("reason", "ok"))
		if bool(module_state.get("active", false)) != expected_active:
			warnings.append("module_ports_runtime_active_mismatch_%s" % String(scenario.get("id", "")))
		var actual_reason := String(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true
		if actual_reason != expected_reason:
			warnings.append("module_ports_runtime_reason_mismatch_%s_%s" % [String(scenario.get("id", "")), actual_reason])
	return warnings

func _get_module_port_reason_coverage_gaps() -> Array[String]:
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return []
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			return []

	var known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1"},
		{"modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1"},
		{"modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1"},
		{"modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1"},
		{"modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1"},
		{"modules":["power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1"},
		{"modules":["radiator_v1"],"module":"radiator_v1"},
		{"modules":["power_block_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["power_block_v1"],"module":"power_block_v1"},
		{"modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1"},
	]
	for scenario in scenarios:
		var runtime := _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			return []
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var module_id := String(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(Dictionary(state.get("modules", {})).get(module_id, {}))
		if module_state.is_empty():
			continue
		var actual_reason := String(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true

	var gaps: Array[String] = []
	for reason_key in known_reason_keys:
		if not observed_runtime_reason_keys.has(reason_key):
			gaps.append("module_port_reason_key_coverage_gap_%s" % reason_key)
	return gaps

func get_module_port_reason_coverage_gap_text() -> String:
	var gaps := _get_module_port_reason_coverage_gaps()
	return "ModulePortReasonCoverage: complete" if gaps.is_empty() else "ModulePortReasonCoverage:\n- " + "\n- ".join(gaps)

func get_module_port_network_validation_text() -> String:
	var warnings := validate_module_port_network_runtime()
	var coverage_gaps := _get_module_port_reason_coverage_gaps()
	var lines: Array[String] = ["ModulePortNetworkValidation: ok" if warnings.is_empty() else "ModulePortNetworkValidation:"]
	if not warnings.is_empty():
		lines.append("- " + "\n- ".join(warnings))
	if not coverage_gaps.is_empty():
		lines.append("Coverage gaps (informational):")
		lines.append("- " + "\n- ".join(coverage_gaps))
	if active_bipob_ref != null and active_bipob_ref.has_method("get_module_port_debug_report_text"):
		lines.append("")
		lines.append(String(active_bipob_ref.call("get_module_port_debug_report_text")))
	return "\n".join(lines)

func validate_connector_processor_migration() -> Array[String]:
	var warnings: Array[String] = []
	var caps := get_actor_capability_levels()
	for key in ["processor_level", "connector_level", "connector_types", "modules", "tools", "port_state"]:
		if not caps.has(key):
			warnings.append("capability_report_missing_%s" % key)
	if caps.has("processor_level") and not (caps["processor_level"] is int):
		warnings.append("capability_report_invalid_processor_level_type")
	if caps.has("connector_level") and not (caps["connector_level"] is int):
		warnings.append("capability_report_invalid_connector_level_type")
	if caps.has("connector_types"):
		if not (caps["connector_types"] is Array):
			warnings.append("capability_report_invalid_connector_types_type")
		else:
			for entry in Array(caps["connector_types"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_connector_types_entry")
					break
	if caps.has("modules"):
		if not (caps["modules"] is Array):
			warnings.append("capability_report_invalid_modules_type")
		else:
			for entry in Array(caps["modules"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_modules_entry")
					break
	if caps.has("tools"):
		if not (caps["tools"] is Array):
			warnings.append("capability_report_invalid_tools_type")
		else:
			for entry in Array(caps["tools"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_tools_entry")
					break
			var tools_array: Array = Array(caps["tools"])
			var non_tool_module_ids := {
				"internal_interface_v1": true,
				"power_block_v1": true,
				"processor_v1": true,
				"memory_v1": true,
				"external_interface_v1": true,
				"external_interface_connector_v1": true
			}
			for entry in tools_array:
				var tool_entry: String = String(entry)
				if non_tool_module_ids.has(tool_entry):
					warnings.append("capability_report_tools_contains_non_tool_module_id_%s" % tool_entry)
					break
	if caps.has("port_state") and not (caps["port_state"] is Dictionary):
		warnings.append("capability_report_invalid_port_state_type")

	var cap_port_state: Dictionary = Dictionary(caps.get("port_state", {}))
	var cap_modules_state: Dictionary = Dictionary(cap_port_state.get("modules", {}))
	var external_connector_active := false
	if cap_modules_state.has("external_interface_connector_v1"):
		external_connector_active = bool(Dictionary(cap_modules_state.get("external_interface_connector_v1", {})).get("active", false))
	if external_connector_active and not Array(caps.get("connector_types", [])).has("physical"):
		warnings.append("capability_report_missing_physical_connector_type_for_external_interface")
	for legacy_key in ["cpu_level", "required_cpu_level", "interface_level", "required_interface_level"]:
		if caps.has(legacy_key):
			warnings.append("capability_report_uses_legacy_%s" % legacy_key)

	var task := build_task_test_mission_world_objects_for_validation()
	for obj in Array(task.get("objects", [])):
		var obj_dict: Dictionary = Dictionary(obj)
		var obj_id: String = String(obj_dict.get("id", ""))
		if not obj_id.begins_with("task_test_terminal"):
			continue
		if obj_dict.has("required_interface_level"):
			warnings.append("task_test_uses_required_interface_level")
		if obj_dict.has("required_cpu_level"):
			warnings.append("task_test_uses_required_cpu_level")
		if not obj_dict.has("required_connector_level"):
			warnings.append("task_test_terminal_missing_required_connector_level")
		if not obj_dict.has("required_processor_level") and String(obj_dict.get("state", "")).to_lower() not in ["damaged", "unpowered"]:
			warnings.append("task_test_terminal_missing_required_processor_level")

	if active_bipob_ref != null and active_bipob_ref.has_method("get_world_action_module"):
		var module: Dictionary = Dictionary(active_bipob_ref.call("get_world_action_module", "connect", {"connection_type":"wired"}))
		if not String(Dictionary(module).get("id", "")).contains("_connector_v"):
			warnings.append("connect_action_not_connector_id")

	var req: Dictionary = get_terminal_hack_requirements("task_test_terminal_main")
	for key in ["required_connector_level", "required_processor_level", "available_connector_level", "available_processor_level"]:
		if not req.has(key):
			warnings.append("terminal_requirements_missing_%s" % key)
	for legacy_key in ["required_cpu_level", "required_interface_level", "cpu_level", "interface_level"]:
		if req.has(legacy_key):
			warnings.append("terminal_requirements_uses_legacy_%s" % legacy_key)
	if req.is_empty():
		warnings.append("terminal_requirements_empty")
	elif active_bipob_ref != null and (int(caps.get("connector_level", 0)) > 0 or int(caps.get("processor_level", 0)) > 0):
		if int(req.get("available_connector_level", 0)) <= 0 and int(caps.get("connector_level", 0)) > 0:
			warnings.append("terminal_available_connector_level_zero_with_modules")
		if int(req.get("available_processor_level", 0)) <= 0 and int(caps.get("processor_level", 0)) > 0:
			warnings.append("terminal_available_processor_level_zero_with_modules")
	return warnings

func get_connector_processor_migration_validation_text() -> String:
	var warnings := validate_connector_processor_migration()
	return "ConnectorProcessorMigrationValidation: ok" if warnings.is_empty() else "ConnectorProcessorMigrationValidation:
- " + "
- ".join(warnings)

func _to_stable_validation_summary(value: Variant) -> String:
	if value == null:
		return "null"
	if value is Dictionary:
		var dict_value: Dictionary = Dictionary(value)
		var keys: Array[String] = []
		for key_variant in dict_value.keys():
			keys.append(String(key_variant))
		keys.sort()
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s:%s" % [key, _to_stable_validation_summary(dict_value.get(key, null))])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var arr_value: Array = Array(value)
		var items: Array[String] = []
		for item in arr_value:
			items.append(_to_stable_validation_summary(item))
		return "[%s]" % ",".join(items)
	return str(value)

func _build_developer_validation_runtime_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	snapshot["mission_id"] = "unavailable"
	snapshot["mission_state"] = "unavailable"
	snapshot["world_objects"] = _to_stable_validation_summary(mission_world_objects)
	snapshot["inventory"] = _to_stable_validation_summary(runtime_inventory_state)
	snapshot["cell_items"] = _to_stable_validation_summary(cell_items)
	if active_bipob_ref != null and _active_bipob_has_property("installed_modules"):
		snapshot["installed_modules"] = _to_stable_validation_summary(active_bipob_ref.installed_modules)
	else:
		snapshot["installed_modules"] = "unavailable"
	if active_bipob_ref != null and active_bipob_ref.has_method("preview_module_port_activity"):
		snapshot["port_state"] = _to_stable_validation_summary(active_bipob_ref.call("preview_module_port_activity"))
	else:
		snapshot["port_state"] = "unavailable"
	snapshot["capability_report"] = _to_stable_validation_summary(get_actor_capability_levels())
	var task_state: Dictionary = {}
	var property_names: Dictionary = {}
	for property_data in get_property_list():
		var property_dict: Dictionary = Dictionary(property_data)
		var property_name: String = String(property_dict.get("name", ""))
		if property_name.is_empty():
			continue
		property_names[property_name] = true
	for task_field in ["task_test_started", "task_test_completed", "task_test_failed", "task_test_turns_left", "task_test_auto_seeded", "task_test_progress", "task_test_state"]:
		if property_names.has(task_field):
			task_state[task_field] = get(task_field)
	snapshot["task_state"] = _to_stable_validation_summary(task_state)
	return snapshot


func get_developer_systems_logic_audit() -> Dictionary:
	var systems: Array[Dictionary] = [
		{
			"id":"power",
			"display_name":"Power",
			"status":"implemented",
			"has_runtime_logic":true,
			"has_validation":true,
			"has_task_test_coverage":true,
			"related_validation_suite":"power",
			"notes":["Power graph, sources, consumers, and propagation are validated in developer suites."],
			"gaps":[]
		},
		{"id":"cooling","display_name":"Cooling","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cooling runtime behavior is covered together with cable flow checks."],"gaps":[]},
		{"id":"cable_socket_reel","display_name":"Cable / Socket / Cable Reel","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cable connectivity, socket linking, and reel interactions are checked by runtime validation."],"gaps":[]},
		{"id":"terminal_hacking","display_name":"Terminal / Hacking","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Terminal operations and access interactions are included in terminal/door checks."],"gaps":[]},
		{"id":"doors_access","display_name":"Doors / Access","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Door lock/access behavior is covered by runtime door validation."],"gaps":[]},
		{"id":"inventory_items","display_name":"Inventory / Items","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Inventory and item interactions are checked in inventory/tools/modules suite."],"gaps":[]},
		{"id":"tools_modules","display_name":"Tools / Modules","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Tool usage and module workflows have runtime validation coverage."],"gaps":[]},
		{"id":"module_ports","display_name":"Module Ports","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"module_ports","notes":["Module port activation and network mapping are validated."],"gaps":[]},
		{"id":"connector_processor_requirements","display_name":"Connector / Processor Requirements","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"connector_processor_migration","notes":["Connector/processor migration and requirements are validated."],"gaps":[]},
		{"id":"platforms","display_name":"Platforms","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Platform activation, timing, and gating are covered in runtime validation."],"gaps":[]},
		{"id":"scan_visibility_xray","display_name":"Scan / Visibility / X-Ray","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Scanning and visibility logic are covered alongside platform validation."],"gaps":[]},
		{"id":"persistence","display_name":"Persistence","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":false,"related_validation_suite":"persistence","notes":["Runtime persistence consistency is validated."],"gaps":["persistence_task_test_coverage_missing"]},
		{"id":"task_test","display_name":"TASK TEST","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"task_test","notes":["TASK TEST scenario and mission checks are part of developer validation."],"gaps":[]},
		{"id":"extraction","display_name":"Extraction","status":"partial","has_runtime_logic":true,"has_validation":false,"has_task_test_coverage":true,"related_validation_suite":"","notes":["Extraction flow exists but is not represented as a dedicated validation suite yet."],"gaps":["extraction_validation_missing"]},
		{"id":"visual_isometric_floor_walls_objects","display_name":"Visual Isometric Floor / Walls / Objects","status":"visual_only","has_runtime_logic":false,"has_validation":false,"has_task_test_coverage":false,"related_validation_suite":"","notes":["Rendering layer is visual-first and intentionally decoupled from gameplay mutation logic."],"gaps":["visual_isometric_objects_validation_missing"]}
	]
	return {"systems": systems}

func validate_developer_systems_logic_audit() -> Array[String]:
	var warnings: Array[String] = []
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	if systems.is_empty():
		warnings.append("audit_report_empty")
		return warnings
	var required_fields: Array[String] = ["id", "display_name", "status", "has_runtime_logic", "has_validation", "has_task_test_coverage", "related_validation_suite", "notes", "gaps"]
	var allowed_status: Dictionary = {"implemented":true, "partial":true, "data_only":true, "visual_only":true, "missing":true}
	var ids: Dictionary = {}
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			warnings.append("audit_system_missing_required_field_unknown_id")
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var system_id: String = String(entry.get("id", ""))
		if not system_id.is_empty():
			ids[system_id] = true
		for field_name in required_fields:
			if not entry.has(field_name):
				warnings.append("audit_system_missing_required_field_%s_%s" % [system_id, field_name])
		var status: String = String(entry.get("status", ""))
		if not allowed_status.has(status):
			warnings.append("audit_system_invalid_status_%s" % system_id)
	if not ids.has("power"):
		warnings.append("audit_system_missing_power")
	if not ids.has("terminal_hacking"):
		warnings.append("audit_system_missing_terminal")
	if not ids.has("module_ports"):
		warnings.append("audit_system_missing_module_ports")
	if not ids.has("task_test"):
		warnings.append("audit_system_missing_task_test")
	return warnings

func get_developer_systems_logic_audit_text() -> String:
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	var lines: Array[String] = ["DeveloperSystemsLogicAudit:"]
	var gaps: Array[String] = []
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var status: String = String(entry.get("status", "missing"))
		var logic_flag: String = "yes" if bool(entry.get("has_runtime_logic", false)) else "no"
		var validation_flag: String = "yes" if bool(entry.get("has_validation", false)) else "no"
		var task_test_flag: String = "yes" if bool(entry.get("has_task_test_coverage", false)) else "no"
		lines.append("- %s: %s logic=%s validation=%s task_test=%s" % [String(entry.get("id", "unknown")), status, logic_flag, validation_flag, task_test_flag])
		for gap_variant in Array(entry.get("gaps", [])):
			var gap_id: String = String(gap_variant)
			if gap_id.is_empty():
				continue
			if gaps.has(gap_id):
				continue
			gaps.append(gap_id)
	if not gaps.is_empty():
		lines.append("")
		lines.append("Gaps:")
		for gap in gaps:
			lines.append("- %s" % gap)
	return "\n".join(lines)

func validate_developer_validation_no_mutation() -> Array[String]:
	var warnings: Array[String] = []
	var baseline: Dictionary = _build_developer_validation_runtime_snapshot()
	get_developer_validation_suite_text("module_ports")
	get_developer_validation_suite_text("connector_processor_migration")
	_get_developer_validation_suite_text_internal("all", false)
	run_developer_validation_suite("module_ports")
	run_developer_validation_suite("connector_processor_migration")
	_run_developer_validation_suite_internal("all", false)
	var after: Dictionary = _build_developer_validation_runtime_snapshot()
	if String(after.get("mission_id", "")) != String(baseline.get("mission_id", "")):
		warnings.append("developer_validation_mutated_mission_id")
	if String(after.get("mission_state", "")) != String(baseline.get("mission_state", "")):
		warnings.append("developer_validation_mutated_mission_state")
	if String(after.get("world_objects", "")) != String(baseline.get("world_objects", "")):
		warnings.append("developer_validation_mutated_world_objects")
	if String(after.get("inventory", "")) != String(baseline.get("inventory", "")):
		warnings.append("developer_validation_mutated_inventory")
	if String(after.get("installed_modules", "")) != String(baseline.get("installed_modules", "")):
		warnings.append("developer_validation_mutated_installed_modules")
	if String(after.get("port_state", "")) != String(baseline.get("port_state", "")):
		warnings.append("developer_validation_mutated_port_state")
	if String(after.get("capability_report", "")) != String(baseline.get("capability_report", "")):
		warnings.append("developer_validation_mutated_capability_report")
	if String(after.get("task_state", "")) != String(baseline.get("task_state", "")):
		warnings.append("developer_validation_mutated_task_state")
	return warnings

func get_developer_validation_no_mutation_text() -> String:
	var warnings: Array[String] = validate_developer_validation_no_mutation()
	if warnings.is_empty():
		return "DeveloperValidationNoMutation: ok"
	return "DeveloperValidationNoMutation:\n- " + "\n- ".join(warnings)

func run_developer_validation_suite(suite: String = "all") -> Dictionary:
	return _run_developer_validation_suite_internal(suite, true)

func _run_developer_validation_suite_internal(suite: String = "all", include_no_mutation: bool = true) -> Dictionary:
	var suites: Array[String] = ["power", "cooling_cable", "terminal_door", "platform_scan_visibility", "inventory_tools_modules", "persistence", "task_test", "module_ports", "connector_processor_migration", "systems_audit"]
	if include_no_mutation:
		suites.append("no_mutation")
	var selected: Array = suites if suite == "all" else [suite]
	var warnings_by_suite: Dictionary = {}
	var suites_run := 0
	for suite_id in selected:
		var warnings: Array[String] = []
		match suite_id:
			"power": warnings = validate_full_power_system_runtime()
			"cooling_cable": warnings = validate_cooling_and_cable_runtime()
			"terminal_door": warnings = validate_terminal_and_door_runtime()
			"platform_scan_visibility": warnings = validate_platform_scan_visibility_runtime()
			"inventory_tools_modules": warnings = validate_inventory_tools_modules_runtime()
			"persistence": warnings = validate_full_runtime_persistence()
			"task_test": warnings = validate_task_test_mission_runtime()
			"module_ports": warnings = validate_module_port_network_runtime()
			"connector_processor_migration": warnings = validate_connector_processor_migration()
			"systems_audit": warnings = validate_developer_systems_logic_audit()
			"no_mutation": warnings = validate_developer_validation_no_mutation()
			_: warnings = ["suite_missing"]
		warnings_by_suite[suite_id] = warnings
		suites_run += 1
	var warnings_count: int = 0
	for k in warnings_by_suite.keys():
		warnings_count += Array(warnings_by_suite[k]).size()
	return {"suite": suite, "suites_run": suites_run, "warnings_count": warnings_count, "warnings_by_suite": warnings_by_suite}

func get_developer_validation_menu_text() -> String:
	return "Validation suites: all, power, cooling_cable, terminal_door, platform_scan_visibility, inventory_tools_modules, persistence, task_test, module_ports, connector_processor_migration, systems_audit, no_mutation"

func get_developer_validation_suite_text(suite: String = "all") -> String:
	return _get_developer_validation_suite_text_internal(suite, true)

func _get_developer_validation_suite_text_internal(suite: String = "all", include_no_mutation: bool = true) -> String:
	if suite == "no_mutation":
		return get_developer_validation_no_mutation_text()
	if suite == "systems_audit":
		return get_developer_systems_logic_audit_text()
	var report: Dictionary = _run_developer_validation_suite_internal(suite, include_no_mutation)
	var lines: Array[String] = ["DeveloperValidation suite=%s suites_run=%d warnings=%d" % [suite, int(report.get("suites_run", 0)), int(report.get("warnings_count", 0))]]
	var by_suite: Dictionary = Dictionary(report.get("warnings_by_suite", {}))
	for suite_id_variant in by_suite.keys():
		var suite_id: String = String(suite_id_variant)
		var suite_warnings: Array = Array(by_suite.get(suite_id_variant, []))
		lines.append("- %s: %d warning(s)" % [suite_id, suite_warnings.size()])
		for warning in suite_warnings:
			lines.append("  • %s" % String(warning))
	return "\n".join(lines)
