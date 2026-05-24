extends RefCounted
class_name WorldObjectCatalog

const WorldObjectDataRef = preload("res://scripts/world/world_object_data.gd")

const OBJECT_LIBRARY := {
	"steel_door": {"group":"door","name":"Steel Door","material":"steel","durability":30,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":1,"lock_type":"mechanical_key","required_manipulator_level":1,"required_interface_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"reinforced_steel_door": {"group":"door","name":"Reinforced Steel Door","material":"reinforced_steel","durability":40,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":2,"lock_type":"terminal_lock","required_manipulator_level":2,"required_interface_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"titanium_door": {"group":"door","name":"Titanium Door","material":"titanium","durability":100,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":3,"lock_type":"password","required_manipulator_level":3,"required_interface_level":0},
	"energy_door": {"group":"door","name":"Energy Door","material":"electromagnetic","durability":1,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"digital_key","required_manipulator_level":1,"required_interface_level":1,"invulnerable_while_powered":true,"power_mode":"external_power","control_mode":"external_control"},
	"grid_door": {"group":"door","name":"Grid Door","material":"steel","durability":15,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"none","required_manipulator_level":1,"required_interface_level":0},
	"door_terminal": {"group":"terminal","name":"Door Terminal","connection_type":"wired","terminal_class":1,"required_interface_level":1,"required_cpu_level":1,"encrypts_data":false,"drain_pool":10,"durability":10,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"elevator_terminal": {"group":"terminal","name":"Elevator Terminal","connection_type":"high_bandwidth","terminal_class":2,"required_interface_level":2,"required_cpu_level":2,"encrypts_data":true,"drain_pool":20,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"information_terminal": {"group":"terminal","name":"Information Terminal","connection_type":"optical","terminal_class":2,"required_interface_level":2,"required_cpu_level":2,"encrypts_data":true,"drain_pool":20,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"turret_terminal": {"group":"terminal","name":"Turret Terminal","connection_type":"wireless","terminal_class":3,"required_interface_level":3,"required_cpu_level":3,"can_attack":true,"encrypts_data":true,"drain_pool":30,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":2,"overheated_state_before":""},
	"cooling_terminal": {"group":"terminal","name":"Cooling Terminal","connection_type":"wired","terminal_class":1,"required_interface_level":1,"required_cpu_level":1,"encrypts_data":false,"drain_pool":10,"durability":10,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"outer_wall": {"group":"wall","name":"Outer Wall","material":"steel","durability":9999,"indestructible":true,"blocks_movement":true,"blocks_vision":true},
	"grate_wall": {"group":"wall","name":"Grate Wall","material":"steel","durability":15,"blocks_movement":true,"blocks_vision":false},
	"damaged_wall": {"group":"wall","name":"Damaged Wall","material":"concrete","durability":3,"blocks_movement":true,"blocks_vision":false,"hidden_content":["secret_passage"]},
	"brick_wall": {"group":"wall","name":"Brick Wall","material":"brick","durability":10,"blocks_movement":true,"blocks_vision":true},
	"concrete_wall": {"group":"wall","name":"Concrete Wall","material":"concrete","durability":20,"blocks_movement":true,"blocks_vision":true},
	"steel_wall": {"group":"wall","name":"Steel Wall","material":"steel","durability":30,"blocks_movement":true,"blocks_vision":true},
	"reinforced_steel_wall": {"group":"wall","name":"Reinforced Steel Wall","material":"reinforced_steel","durability":40,"blocks_movement":true,"blocks_vision":true},
	"titanium_wall": {"group":"wall","name":"Titanium Wall","material":"titanium","durability":100,"blocks_movement":true,"blocks_vision":true},
	"energy_wall": {"group":"wall","name":"Energy Wall","material":"energy_flow","durability":1,"blocks_movement":true,"blocks_vision":false,"invulnerable_while_powered":true,"power_mode":"external_power"},
	"power_cable": {"group":"power","name":"Power Cable","state":"active","durability":5,"power_mode":"external_power"},
	"circuit_breaker": {"group":"power","name":"Circuit Breaker","state":"switch_on","durability":8},
	"circuit_switch": {"group":"power","name":"Circuit Switch","state":"switch_off","durability":8},
	"fuse_box": {"group":"power","name":"Fuse Box","state":"installed","durability":8,"requires_fuse":true},
	"fuse_box_installed": {"group":"power","name":"Fuse Box Installed","state":"installed","durability":8,"requires_fuse":true},
	"fuse_box_empty": {"group":"power","name":"Fuse Box Empty","state":"empty","durability":8,"requires_fuse":true},
	"light": {"group":"power","name":"Light","state":"active","durability":6},
	"light_switch": {"group":"power","name":"Light Switch","state":"switch_off","durability":6,"can_be_switched":true},
	"power_socket": {"group":"power","name":"Power Socket","state":"disconnected","durability":8,"can_connect_cable":true},
	"power_cable_reel": {"group":"item","name":"Power Cable Reel","state":"disconnected","item_form":"physical","storage_type":"pocket","can_connect_socket":true,"max_cable_length":5},
	"power_source_class_1": {"group":"power","name":"Power Source C1","state":"active","durability":30,"power_source_class":1,"drain_pool":60,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":1,"connected_device_ids":[]},
	"power_source_class_2": {"group":"power","name":"Power Source C2","state":"active","durability":30,"power_source_class":2,"drain_pool":120,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":2,"connected_device_ids":[]},
	"power_source_class_3": {"group":"power","name":"Power Source C3","state":"active","durability":30,"power_source_class":3,"drain_pool":240,"working_heat":3,"current_heat":3,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":3,"connected_device_ids":[]},
	"external_radiator": {"group":"cooling","name":"External Radiator","state":"active","cooling_device_type":"radiator","cooling_output":1,"movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20},
	"external_air_cooler": {"group":"cooling","name":"External Air Cooler","state":"active","cooling_device_type":"air_cooler","cooling_output":2,"directed_airflow":true,"facing_dir":"right","movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20},
	"metal_cooling_block": {"group":"physical","name":"Metal Cooling Block","state":"active","material":"metal","cooling_amplifier":true,"movable":true,"heavy_claw_movable":true,"blocks_movement":true,"blocks_vision":false,"durability":30},
	"module_external": {"group":"item","name":"Module External","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"module_internal": {"group":"item","name":"Module Internal","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mechanical_keycard": {"group":"item","name":"Mechanical KeyCard","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":["door"],"key_kind":"mechanical"},
	"fuse": {"group":"item","name":"Fuse","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["fuse_box","fuse_box_empty"]},
	"repair_kit": {"group":"item","name":"Repair Kit","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door","terminal","power"]},
	"reinforcement": {"group":"item","name":"Reinforcement","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door"],"damage":2},
	"parts": {"group":"item","name":"Parts","item_form":"physical","storage_type":"pocket","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_small": {"group":"item","name":"Parts (Small)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":5,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_medium": {"group":"item","name":"Parts (Medium)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":10,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_large": {"group":"item","name":"Parts (Large)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":20,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"sample": {"group":"item","name":"Sample","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mission_item": {"group":"item","name":"Mission Item","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"digital_key_opened": {"group":"item","name":"Digital Key Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"opened","consumable":false,"fits_targets":["door"]},
	"digital_key_encrypted": {"group":"item","name":"Digital Key Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"encrypted","consumable":false,"fits_targets":["door"]},
	"digital_key_damaged": {"group":"item","name":"Digital Key Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"damaged","consumable":false,"fits_targets":["door"]},
	"access_code": {"group":"item","name":"Access Code","item_form":"digital","storage_type":"digital_storage","can_place_in_digital_buffer":false,"digital_state":"opened","consumable":false,"fits_targets":["door","terminal"]},
	"data_file_opened": {"group":"item","name":"Data File Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"opened","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_encrypted": {"group":"item","name":"Data File Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"encrypted","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_damaged": {"group":"item","name":"Data File Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"damaged","consumable":false,"fits_targets":["terminal","firewall"]},
	"normal_crate": {"group":"physical_object","name":"Normal Crate","weight_class":"normal","required_bipob_power_class":"scout","durability":8,"blocks_movement":true},"heavy_crate": {"group":"physical_object","name":"Heavy Crate","weight_class":"heavy","required_bipob_power_class":"engineer","durability":14,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"movable_platform_block": {"group":"physical_object","name":"Movable Platform Block","weight_class":"block","required_bipob_power_class":"juggernaut","durability":20,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"disabled_bipop_scout": {"group":"physical_object","name":"Disabled Bipop Scout","weight_class":"normal","required_bipob_power_class":"scout","durability":10},"disabled_bipop_engineer": {"group":"physical_object","name":"Disabled Bipop Engineer","weight_class":"heavy","required_bipob_power_class":"engineer","durability":15},"disabled_bipop_juggernaut": {"group":"physical_object","name":"Disabled Bipop Juggernaut","weight_class":"block","required_bipob_power_class":"juggernaut","durability":25},"barrel": {"group":"physical_object","name":"Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":8},"explosive_barrel": {"group":"physical_object","name":"Explosive Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":6,"on_destroy":"explode"},"debris": {"group":"physical_object","name":"Debris","weight_class":"normal","required_bipob_power_class":"scout","durability":1,"blocks_movement":false,"terrain_tag":"debris","movement_debuff":-1},
	"enemy_robot": {"group":"threat","name":"Enemy Robot","state":"active","behavior_state":"patrolling","durability":20,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":20,"drained_this_turn":false,"detection_range":3,"vision_range":3,"radar_range":3,"thermal_range":0,"detection_modes":["vision","radar"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":5,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"turret": {"group":"threat","name":"Turret","state":"active","behavior_state":"idle","durability":15,"blocks_movement":true,"blocks_vision":false,"power_mode":"external_power","power_network_id":"power_net_A","is_powered":true,"control_mode":"external_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":15,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":0,"thermal_range":4,"detection_modes":["vision","thermal"],"detection_shape":"cardinal","detection_cone_enabled":false,"detection_direction":"forward","attack_range":4,"attack_damage":4,"can_be_controlled_by_terminal":true,"required_cpu_level":1,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"bug": {"group":"threat","name":"Bug","state":"active","behavior_state":"patrolling","durability":8,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["organic"],"heat_signature":true,"magnetic":false,"drain_energy_pool":5,"drained_this_turn":false,"detection_range":2,"vision_range":2,"radar_range":0,"thermal_range":0,"detection_modes":["vision"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":2,"drops":["sample","parts_small"],"on_destroy":["drop_items"]},
	"vagus": {"group":"threat","name":"Vagus","state":"active","behavior_state":"idle","durability":30,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_heavy"],"heat_signature":true,"magnetic":true,"drain_energy_pool":30,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":4,"thermal_range":4,"detection_modes":["vision","radar","thermal"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":2,"attack_damage":7,"drops":["mission_item","parts_large"],"on_destroy":["drop_items","debris"]}
}

static func create_world_object(object_type: String, id_override: String = "") -> Dictionary:
	if not OBJECT_LIBRARY.has(object_type):
		return {}
	var def: Dictionary = OBJECT_LIBRARY[object_type]
	var object_id := id_override if id_override != "" else "%s_%s" % [object_type, str(Time.get_unix_time_from_system())]
	var data := WorldObjectDataRef.create_base(object_id, def.get("name", object_type), def.get("group", "physical_object"), object_type)
	for key in def.keys():
		if key == "name" or key == "group":
			continue
		data[key] = def[key]
	if data.has("durability"):
		data["durability_max"] = data["durability"]
		data["durability_current"] = data["durability"]
		data.erase("durability")
	if data.get("indestructible", false):
		data["invulnerable"] = true
	if data.get("invulnerable_while_powered", false) and data.get("is_powered", true):
		data["invulnerable"] = true
	data = update_world_object_heat_state(data)
	return data

static func get_world_object_working_heat(object_data: Dictionary) -> int:
	return maxi(0, int(object_data.get("working_heat", 0)))

# Persistent world heat uses only working + connection heat minus cooling.
# Temporary action heat (for example terminal hack heat) is never stored in object data.
static func get_world_object_current_heat(object_data: Dictionary) -> int:
	var working_heat := get_world_object_working_heat(object_data)
	var connection_heat := maxi(0, int(object_data.get("heat_from_connections", 0)))
	var cooling := maxi(0, int(object_data.get("cooling_received", 0)))
	return maxi(0, working_heat + connection_heat - cooling)

static func get_world_object_current_heat_with_temporary_heat(object_data: Dictionary, temporary_heat: int = 0) -> int:
	var working_heat := get_world_object_working_heat(object_data)
	var connection_heat := maxi(0, int(object_data.get("heat_from_connections", 0)))
	var cooling := maxi(0, int(object_data.get("cooling_received", 0)))
	var extra_heat := maxi(0, temporary_heat)
	return maxi(0, working_heat + connection_heat + extra_heat - cooling)

static func would_world_object_overheat_with_temporary_heat(object_data: Dictionary, temporary_heat: int = 0) -> bool:
	var threshold := int(object_data.get("overheat_threshold", 0))
	if threshold <= 0:
		return false
	return get_world_object_current_heat_with_temporary_heat(object_data, temporary_heat) >= threshold

static func get_world_object_heat_breakdown(object_data: Dictionary, temporary_heat: int = 0) -> Dictionary:
	var threshold := int(object_data.get("overheat_threshold", 0))
	var current_heat := get_world_object_current_heat_with_temporary_heat(object_data, temporary_heat)
	var would_overheat := false
	if threshold > 0:
		would_overheat = current_heat >= threshold
	return {
		"working_heat": get_world_object_working_heat(object_data),
		"heat_from_connections": maxi(0, int(object_data.get("heat_from_connections", 0))),
		"temporary_heat": maxi(0, temporary_heat),
		"cooling_received": maxi(0, int(object_data.get("cooling_received", 0))),
		"current_heat": current_heat,
		"threshold": threshold,
		"would_overheat": would_overheat,
		"state": String(object_data.get("state", "active"))
	}

static func is_world_object_overheated(object_data: Dictionary) -> bool:
	var threshold := int(object_data.get("overheat_threshold", 0))
	if threshold <= 0:
		return false
	return get_world_object_current_heat(object_data) >= threshold

static func update_world_object_heat_state(object_data: Dictionary) -> Dictionary:
	if object_data.is_empty():
		return object_data
	if not object_data.has("working_heat") and not object_data.has("overheat_threshold") and not object_data.has("cooling_received"):
		return object_data
	var state := String(object_data.get("state", "active"))
	object_data["working_heat"] = get_world_object_working_heat(object_data)
	object_data["heat_from_connections"] = maxi(0, int(object_data.get("heat_from_connections", 0)))
	object_data["cooling_received"] = maxi(0, int(object_data.get("cooling_received", 0)))
	object_data["current_heat"] = get_world_object_current_heat(object_data)
	if is_world_object_overheated(object_data):
		if state != "overheated":
			if not ["destroyed", "damaged"].has(state):
				object_data["overheated_state_before"] = state if not state.is_empty() else "active"
				object_data["overheated_powered_before"] = bool(object_data.get("is_powered", true))
			object_data["state"] = "overheated"
		object_data["is_powered"] = false
	elif state == "overheated":
		var restore_state := String(object_data.get("overheated_state_before", "active"))
		if restore_state.is_empty():
			restore_state = "active"
		if not ["destroyed", "damaged"].has(restore_state):
			object_data["state"] = restore_state
		object_data.erase("overheated_state_before")
		if object_data.has("overheated_powered_before"):
			object_data["is_powered"] = bool(object_data.get("overheated_powered_before", true))
			object_data.erase("overheated_powered_before")
	return object_data

static func set_world_object_cooling_received(object_data: Dictionary, cooling_value: int) -> Dictionary:
	object_data["cooling_received"] = maxi(0, cooling_value)
	return update_world_object_heat_state(object_data)

static func can_world_object_receive_cooling(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var has_heat_metadata := object_data.has("overheat_threshold") or object_data.has("working_heat")
	if not has_heat_metadata:
		return false
	var object_group := String(object_data.get("object_group", ""))
	if object_group == "terminal":
		return true
	var object_type := String(object_data.get("object_type", ""))
	return object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]

static func _to_vector2i(value: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", fallback.x)), int(value.get("y", fallback.y)))
	return fallback

static func to_world_cell(value: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	return _to_vector2i(value, fallback)

static func _is_world_object_inactive_for_cooling(object_data: Dictionary) -> bool:
	var state := String(object_data.get("state", "active"))
	return state in ["damaged", "destroyed", "overheated", "disabled", "inactive", "unpowered"]

static func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1

static func _facing_dir_to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	var dir_text := String(value).to_lower()
	match dir_text:
		"up":
			return Vector2i.UP
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.RIGHT

static func get_radiator_world_cooling_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if String(object_data.get("cooling_device_type", "")) != "radiator":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var radiator_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		if not _is_adjacent(radiator_position, target_position):
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 1)))
		for neighbor in all_objects:
			if neighbor == target_object:
				continue
			if _is_world_object_inactive_for_cooling(neighbor):
				continue
			var neighbor_position := _to_vector2i(neighbor.get("position", Vector2i(-999, -999)))
			if not _is_adjacent(radiator_position, neighbor_position):
				continue
			var is_metal := String(neighbor.get("material", "")) == "metal"
			var is_amplifier := bool(neighbor.get("cooling_amplifier", false))
			if is_metal or is_amplifier:
				output = maxi(output, 2)
				break
		strongest = maxi(strongest, output)
	return strongest

static func get_air_cooler_world_cooling_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if String(object_data.get("cooling_device_type", "")) != "air_cooler":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var cooler_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		var facing_dir := _facing_dir_to_vector2i(object_data.get("facing_dir", "right"))
		var affected_cell := cooler_position + facing_dir
		if affected_cell != target_position:
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 2)))
		strongest = maxi(strongest, output)
	return strongest

static func calculate_world_cooling_received_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	if not can_world_object_receive_cooling(target_object):
		return 0
	var radiator_cooling := get_radiator_world_cooling_for_target(target_object, target_position, all_objects)
	var air_cooling := get_air_cooler_world_cooling_for_target(target_object, target_position, all_objects)
	if radiator_cooling > 0 and air_cooling > 0:
		return 3
	return maxi(radiator_cooling, air_cooling)

static func get_power_source_active_socket_connection_count(source_data: Dictionary) -> int:
	return Array(source_data.get("connected_device_ids", [])).size()

static func can_power_source_accept_connection(source_data: Dictionary) -> bool:
	var allowed := maxi(0, int(source_data.get("allowed_socket_connections", 0)))
	if allowed <= 0:
		return true
	return get_power_source_active_socket_connection_count(source_data) < allowed

static func add_power_source_socket_connection(source_data: Dictionary, device_id: String) -> Dictionary:
	var ids: Array = Array(source_data.get("connected_device_ids", []))
	if not ids.has(device_id):
		if can_power_source_accept_connection(source_data):
			ids.append(device_id)
	source_data["connected_device_ids"] = ids
	source_data["heat_from_connections"] = ids.size()
	return update_world_object_heat_state(source_data)

static func remove_power_source_socket_connection(source_data: Dictionary, device_id: String) -> Dictionary:
	var ids: Array = Array(source_data.get("connected_device_ids", []))
	if ids.has(device_id):
		ids.erase(device_id)
	source_data["connected_device_ids"] = ids
	source_data["heat_from_connections"] = ids.size()
	return update_world_object_heat_state(source_data)

static func create_test_set() -> Array[Dictionary]:
	return [
		create_world_object("steel_door", "door_a1"),
		create_world_object("energy_door", "door_e1"),
		create_world_object("door_terminal", "terminal_t1"),
		create_world_object("brick_wall", "wall_b1"),
		create_world_object("damaged_wall", "wall_d1"),
		create_world_object("power_source_class_1", "power_src_1"),
		create_world_object("power_cable", "cable_a"),
		create_world_object("circuit_breaker", "breaker_1"),
		create_world_object("fuse_box_installed", "fuse_box_1"),
		create_world_object("fuse_box_empty", "fuse_box_empty_1"),
		create_world_object("fuse", "fuse_item_1"),
		create_world_object("mechanical_keycard", "keycard_a1"),
		create_world_object("digital_key_opened", "digikey_a1"),
		create_world_object("data_file_encrypted", "datafile_enc_1"),
		create_world_object("normal_crate", "crate_n_1"),
		create_world_object("heavy_crate", "crate_h_1"),
		create_world_object("barrel", "barrel_1"),
		create_world_object("debris", "debris_1")
	]
