extends RefCounted
class_name WorldObjectCatalog

const WorldObjectDataRef = preload("res://scripts/world/world_object_data.gd")

const OBJECT_LIBRARY := {
	"steel_door": {"group":"door","name":"Steel Door","material":"steel","durability":30,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":1,"lock_type":"mechanical_key","required_manipulator_level":1,"required_interface_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"reinforced_steel_door": {"group":"door","name":"Reinforced Steel Door","material":"reinforced_steel","durability":40,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":2,"lock_type":"terminal_lock","required_manipulator_level":2,"required_interface_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"titanium_door": {"group":"door","name":"Titanium Door","material":"titanium","durability":100,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":3,"lock_type":"password","required_manipulator_level":3,"required_interface_level":0},
	"energy_door": {"group":"door","name":"Energy Door","material":"electromagnetic","durability":1,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"digital_key","required_manipulator_level":1,"required_interface_level":1,"invulnerable_while_powered":true,"power_mode":"external_power","control_mode":"external_control"},
	"grid_door": {"group":"door","name":"Grid Door","material":"steel","durability":15,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"none","required_manipulator_level":1,"required_interface_level":0},
	"door_terminal": {"group":"terminal","name":"Door Terminal","connection_type":"wired","terminal_class":1,"required_interface_level":1,"required_cpu_level":1,"encrypts_data":false,"drain_pool":10,"durability":10},
	"elevator_terminal": {"group":"terminal","name":"Elevator Terminal","connection_type":"high_bandwidth","terminal_class":2,"required_interface_level":2,"required_cpu_level":2,"encrypts_data":true,"drain_pool":20,"durability":10},
	"information_terminal": {"group":"terminal","name":"Information Terminal","connection_type":"optical","terminal_class":2,"required_interface_level":2,"required_cpu_level":2,"encrypts_data":true,"drain_pool":20,"durability":10},
	"turret_terminal": {"group":"terminal","name":"Turret Terminal","connection_type":"wireless","terminal_class":3,"required_interface_level":3,"required_cpu_level":3,"can_attack":true,"encrypts_data":true,"drain_pool":30,"durability":10},
	"cooling_terminal": {"group":"terminal","name":"Cooling Terminal","connection_type":"wired","terminal_class":1,"required_interface_level":1,"required_cpu_level":1,"encrypts_data":false,"drain_pool":10,"durability":10},
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
	"power_source_class_1": {"group":"power","name":"Power Source C1","state":"active","durability":30,"power_source_class":1,"drain_pool":60},
	"power_source_class_2": {"group":"power","name":"Power Source C2","state":"active","durability":30,"power_source_class":2,"drain_pool":120},
	"power_source_class_3": {"group":"power","name":"Power Source C3","state":"active","durability":30,"power_source_class":3,"drain_pool":240},
	"module_external": {"group":"item","name":"Module External","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"module_internal": {"group":"item","name":"Module Internal","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mechanical_keycard": {"group":"item","name":"Mechanical KeyCard","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":["door"],"key_kind":"mechanical"},
	"fuse": {"group":"item","name":"Fuse","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["fuse_box","fuse_box_empty"]},
	"repair_kit": {"group":"item","name":"Repair Kit","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door","terminal","power"]},
	"reinforcement": {"group":"item","name":"Reinforcement","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door"],"damage":2},
	"parts": {"group":"item","name":"Parts","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"sample": {"group":"item","name":"Sample","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mission_item": {"group":"item","name":"Mission Item","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"digital_key_opened": {"group":"item","name":"Digital Key Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"opened","consumable":false,"fits_targets":["door"]},
	"digital_key_encrypted": {"group":"item","name":"Digital Key Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"encrypted","consumable":false,"fits_targets":["door"]},
	"digital_key_damaged": {"group":"item","name":"Digital Key Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"damaged","consumable":false,"fits_targets":["door"]},
	"access_code": {"group":"item","name":"Access Code","item_form":"digital","storage_type":"digital_storage","can_place_in_digital_buffer":false,"digital_state":"opened","consumable":false,"fits_targets":["door","terminal"]},
	"data_file_opened": {"group":"item","name":"Data File Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"opened","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_encrypted": {"group":"item","name":"Data File Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"encrypted","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_damaged": {"group":"item","name":"Data File Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"damaged","consumable":false,"fits_targets":["terminal","firewall"]},
	"normal_crate": {"group":"physical_object","name":"Normal Crate","weight_class":"normal","required_bipob_power_class":"scout","durability":8,"blocks_movement":true},"heavy_crate": {"group":"physical_object","name":"Heavy Crate","weight_class":"heavy","required_bipob_power_class":"engineer","durability":14,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"movable_platform_block": {"group":"physical_object","name":"Movable Platform Block","weight_class":"block","required_bipob_power_class":"juggernaut","durability":20,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"disabled_bipop_scout": {"group":"physical_object","name":"Disabled Bipop Scout","weight_class":"normal","required_bipob_power_class":"scout","durability":10},"disabled_bipop_engineer": {"group":"physical_object","name":"Disabled Bipop Engineer","weight_class":"heavy","required_bipob_power_class":"engineer","durability":15},"disabled_bipop_juggernaut": {"group":"physical_object","name":"Disabled Bipop Juggernaut","weight_class":"block","required_bipob_power_class":"juggernaut","durability":25},"barrel": {"group":"physical_object","name":"Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":8},"explosive_barrel": {"group":"physical_object","name":"Explosive Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":6,"on_destroy":"explode"},"debris": {"group":"physical_object","name":"Debris","weight_class":"normal","required_bipob_power_class":"scout","durability":1,"blocks_movement":false,"terrain_tag":"debris","movement_debuff":-1},
	"enemy_robot": {"group":"threat","name":"Enemy Robot","state":"active","behavior_state":"patrolling","durability":20,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":20,"drained_this_turn":false,"detection_modes":["vision","radar"],"attack_range":1,"attack_damage":5,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"turret": {"group":"threat","name":"Turret","state":"active","behavior_state":"idle","durability":15,"blocks_movement":true,"blocks_vision":false,"power_mode":"external_power","power_network_id":"power_net_A","is_powered":true,"control_mode":"external_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":15,"drained_this_turn":false,"detection_modes":["vision","thermal"],"attack_range":4,"attack_damage":4,"can_be_controlled_by_terminal":true,"required_cpu_level":1,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"bug": {"group":"threat","name":"Bug","state":"active","behavior_state":"patrolling","durability":8,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["organic"],"heat_signature":true,"magnetic":false,"drain_energy_pool":5,"drained_this_turn":false,"detection_modes":["vision"],"attack_range":1,"attack_damage":2,"drops":["sample","parts_small"],"on_destroy":["drop_items"]},
	"vagus": {"group":"threat","name":"Vagus","state":"active","behavior_state":"idle","durability":30,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_heavy"],"heat_signature":true,"magnetic":true,"drain_energy_pool":30,"drained_this_turn":false,"detection_modes":["vision","radar","thermal"],"attack_range":2,"attack_damage":7,"drops":["mission_item","parts_large"],"on_destroy":["drop_items","debris"]}
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
	return data

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
