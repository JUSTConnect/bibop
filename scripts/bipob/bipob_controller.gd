extends Node2D
class_name BipobController

signal status_changed
signal hint_requested(message: String)
signal mission_completed
signal mission_failed
signal returned_to_box
signal world_action_panel_requested(target_object: Dictionary, actions: Array, selected_action: String)

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

const EXTERNAL_SIDE_TOP := "top"
const EXTERNAL_SIDE_BOTTOM := "bottom"
const EXTERNAL_SIDE_LEFT := "left"
const EXTERNAL_SIDE_RIGHT := "right"
const EXTERNAL_SIDE_FRONT := "front"
const EXTERNAL_SIDE_BACK := "back"

const EXTERNAL_SIDE_ORDER := [
	EXTERNAL_SIDE_TOP,
	EXTERNAL_SIDE_FRONT,
	EXTERNAL_SIDE_LEFT,
	EXTERNAL_SIDE_RIGHT,
	EXTERNAL_SIDE_BACK,
	EXTERNAL_SIDE_BOTTOM
]
const EXTERNAL_CATEGORY_MAP := {"movement":"Gear","sensor":"Sensors","manipulator":"Manipulator","connector":"Interface","tool":"Tools","repair":"Tools","weapon":"Weapons","armor":"Defense","other":"Other"}
const MissionManagerScript = preload("res://scripts/game/mission_manager.gd")
const ScanSystemRef = preload("res://scripts/world/scan_system.gd")
const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const PowerSystemRef = preload("res://scripts/world/power_system.gd")
const BipobModulePresenterRef = preload("res://scripts/bipob/bipob_module_presenter.gd")
const EXTERNAL_MODULE_CATALOG: Dictionary = {
"wheels_v1":{"name":"Wheels V1","cat":"Gear","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_BOTTOM],"desc":"Fast movement system for flat and stable surfaces. Ineffective on stairs, mud and debris.","energy":1,"terrain":"Flat surface","movement":"Drive","speed":3},
"legs_v1":{"name":"Legs V1","cat":"Gear","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_BOTTOM],"desc":"Universal movement system that provides stable traversal across uneven terrain, steps, obstacles, and mixed surfaces.","energy":1,"terrain":"Any surface","movement":"Walk","speed":2},
"tracks_v1":{"name":"Tracks V1","cat":"Gear","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_BOTTOM],"desc":"Heavy traction system for slow but reliable movement across mud, rubble, slopes, and stairs.","energy":2,"terrain":"Any surface","movement":"Drive","speed":1,"ignore_debuff":true,"special":"ignore debuff"},
"jumper_v1":{"name":"Jumper V1","cat":"Gear","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_BOTTOM],"desc":"A movement system based on jumping, allowing you to traverse gaps, obstacles, traps, and difficult terrain. Requires a Motor Controller.","energy":3,"terrain":"Any surface","movement":"Jump","speed":6,"ignore_debuff":true,"special":"ignore debuff"},
"hover_pad_v1":{"name":"Air Cushion V1","cat":"Gear","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_BOTTOM],"desc":"Hover movement system that provides high mobility over difficult surfaces, but requires increased energy consumption. Requires a Motor Controller.","energy":3,"terrain":"Any surface","movement":"Levitate","speed":5,"ignore_debuff":true,"special":"ignore debuff"},
"visor_v1":{"name":"Visor V1","cat":"Sensors","size":Vector2i(3,1),"sides":[EXTERNAL_SIDE_TOP],"desc":"Basic visual sensor module for standard object detection, navigation, and direct line-of-sight observation.","energy":0,"direction":"Front","scan":2,"visibility":15},
"visor_v2":{"name":"Visor V2","cat":"Sensors","size":Vector2i(3,1),"sides":[EXTERNAL_SIDE_TOP],"desc":"Improved visual sensor module with stronger object detection, navigation support, and direct line-of-sight observation.","energy":0,"direction":"Front","scan":3,"visibility":30},
"visor_v3":{"name":"Visor V3","cat":"Sensors","size":Vector2i(3,1),"sides":[EXTERNAL_SIDE_TOP],"desc":"Advanced visual sensor module with the strongest visor detection, long-range navigation support, and enhanced direct line-of-sight observation.","energy":1,"direction":"Front","scan":5,"visibility":60},
"thermal_visor_v1":{"name":"Thermal Visor V1","cat":"Sensors","size":Vector2i(3,1),"sides":[EXTERNAL_SIDE_TOP],"desc":"Heat-detection sensor that reveals active devices, hot zones, recently used systems, and heat-emitting targets.","energy":1,"direction":"Front","scan":5,"visibility":30,"special":"thermal objects"},
"radar_v1":{"name":"Radar V1","cat":"Sensors","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_TOP],"desc":"Detects movement and objects across the entire open area of the level, providing only approximate location data.","energy":2,"direction":"Front","scan":8,"visibility":90,"special":"approximate position"},
"xray_v1":{"name":"X-Ray V1","cat":"Sensors","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_TOP],"desc":"Deep scanning through walls and obstacles, revealing hidden objects, internal structures, cables, locks, containers, and concealed mechanisms.","energy":2,"direction":"Front","scan":5,"visibility":30,"special":"hidden/internal object"},
"manipulator_arm_v1":{"name":"Manipulator Arm V1","cat":"Manipulator","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Basic external arm for grabbing, pressing buttons, and interacting with devices directly in front.","energy":1,"reach":1,"direction":"front","carry":"normal"},"manipulator_heavy_claw_v1":{"name":"Manipulator Heavy Claw V1","cat":"Manipulator","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"Heavy-duty gripping module for moving heavy objects, holding doors, breaking weak obstacles, and performing force-based interactions.","energy":2,"reach":4,"direction":"front","carry":"Heavy"},"magnetic_manipulator_v1":{"name":"Magnetic Manipulator V1","cat":"Manipulator","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Magnetic gripping module that can attract and move metal objects from a distance without direct physical contact.","energy":2,"reach":4,"direction":"front","carry":"Heavy","special":"metal objects"},"tentacle_manipulator_v1":{"name":"Tentacle Manipulator V1","cat":"Manipulator","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Flexible manipulator that can interact with objects at an angle and reach targets that are not directly in area front.","energy":1,"reach":1,"direction":"side/front","carry":"normal"},"telescopic_arm_v1":{"name":"Telescopic Arm V1","cat":"Manipulator","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Extendable manipulator that allows the robot to interact with objects away.","energy":1,"reach":2,"direction":"front","carry":"normal"},
"high_bandwidth_connector_v1":{"name":"High-Bandwidth Connector","cat":"Interface","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"High-capacity external data channel for demanding modules such as radar, X-Ray systems, heavy sensors, turrets, and advanced tools.","energy":3,"connection":"high-bandwidth","connection_range":"contact","special":"heavy modules"},"external_interface_connector_v1":{"name":"External Interface Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Basic physical connector for linking external body modules to the robot’s internal control and power systems.","energy":1,"connection":"physical","connection_range":"contact"},"optical_connector_v1":{"name":"Optical Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Fast optical communication channel with reduced interference, designed for sensors, cameras, and precision data transfer.","energy":1,"connection":"optical","connection_range":"contact","special":"reduced interference"},"wireless_connector_v1":{"name":"Wireless Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Wireless connection module that allows nearby devices and external systems to exchange data without direct physical contact, but remains vulnerable to jamming.","energy":2,"connection":"wireless","connection_range":"3","special":"vulnerable to jamming"},
"welder_v1":{"name":"Welder V1","cat":"Tools","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"External welding tool for sealing doors, repairing metal surfaces, reinforcing damaged structures, and creating temporary welded connections.","energy":1,"range_value":1,"direction":"Front","tool_action":"weld"},
"repair_v1":{"name":"Repair V1","cat":"Tools","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Field repair module for restoring damaged robot modules, fixing mission equipment, and performing basic mechanical recovery tasks.","energy":1,"range_value":1,"direction":"Front","tool_action":"repair"},
"plasma_cutter_v1":{"name":"Plasma Cutter V1","cat":"Tools","size":Vector2i(3,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"High-energy cutting tool for opening metal doors, cutting grates, removing armor plates, and breaking through heavy obstacles.","energy":2,"range_value":1,"direction":"Front","tool_action":"cut","special":"opens blocked paths"},
"laser_v1":{"name":"Laser","cat":"Weapons","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"Long-range energy weapon that damages targets with a focused beam and increases heat on repeated hits.","energy":2,"damage":"1-3","range":"Ranged","range_value":5,"direction":"Front","span":"Ranged","special":"target overheat +1"},
"shocker_v1":{"name":"Shocker","cat":"Weapons","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Close-range electric weapon that stuns or disables targets for a short time.","energy":1,"damage":"1","range":"Melee","range_value":1,"direction":"Front","span":"Melee","special":"immobilize 1 turn"},
"sledgehammer_v1":{"name":"Sledgehammer","cat":"Weapons","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"Heavy melee impact weapon that strikes a small area in front of the robot with strong but inaccurate force.","energy":1,"damage":"3","range":"Melee","range_value":1,"direction":"Front","span":"Melee","special":"Splash area front 3 cells"},
"saw_v1":{"name":"Saw","cat":"Weapons","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"Close-range cutting weapon for damaging nearby targets and mechanical obstacles.","energy":1,"damage":"3","range":"Melee","range_value":1,"direction":"Front","span":"Melee","special":"Splash area side 3 cells"},
"gas_canister_v1":{"name":"Gas Canister","cat":"Weapons","size":Vector2i(2,4),"sides":[EXTERNAL_SIDE_BACK],"desc":"Fuel container for gas-based weapons. Stores limited fuel and can become dangerous if damaged.","energy":0,"fuel_capacity":6,"special":"explosive"},
"gas_burner_v1":{"name":"Gas Burner","cat":"Weapons","size":Vector2i(3,3),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT],"desc":"Gas-based flame weapon that projects fire across an area in front of the robot.","energy":0,"damage":"1-3","range":"Ranged","range_value":1,"direction":"Front","span":"Ranged","ammo_dependency_id":"gas_canister_v1","special":"Splash area square 3*4 cells"},
"shield_module_v1":{"name":"Shield Module V1","cat":"Defense","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Energy shield generator that absorbs incoming damage using battery charge. The shield weakens as available energy drops.","energy":1,"shield":20,"defense_type":"Absorption","special":"disables below 25% battery"},"emp_shield_v1":{"name":"EMP Shield V1","cat":"Defense","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Protective module that reduces the effect of EMP attacks, electric shock, forced shutdowns, and hostile module disruption.","energy":1,"shield":15,"defense_type":"EMP","special":"shock protection"},"heat_shield_v1":{"name":"Heat Shield V1","cat":"Defense","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Thermal protection plate that reduces damage and overheating from fire, lasers, gas burners, and other high-temperature sources.","energy":1,"defense_type":"Absorption","special":"fire and laser protection heat"},"reactive_bumper_v1":{"name":"Reactive Bumper V1","cat":"Defense","size":Vector2i(2,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Impact protection module that absorbs collision damage and allows safer ramming, pushing, and contact with heavy obstacles.","energy":0,"damage":"1","armor":10,"special":"ram attack"},"armor_plate_v1":{"name":"Armor Plate V1","cat":"Defense","size":Vector2i(2,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Passive armor plating that increases the robot body durability and protects mounted external modules from direct damage.","energy":0,"armor":20},
"antenna_v1":{"name":"Antenna","cat":"Other","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_TOP],"desc":"External communication module that maintains contact with the control center.","energy":0,"action":"Connection Center"},"intiradar_v1":{"name":"Anti-Radar Module","cat":"Other","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Counter-detection module that masks from enemy radar scans and reduces the chance of being detected by scanning systems.","energy":1,"action":"Radar masking"},"smoke_emitter_v1":{"name":"Smoke Emitter","cat":"Other","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Deploys a smoke screen to block vision, reduce enemy targeting, and cover movement through exposed areas.","energy":0,"action":"Blocks vision"},"beacon_module_v1":{"name":"Beacon Module","cat":"Other","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Emergency location marker that activates when it's disabled, allowing the control center to find and recover it.","energy":0,"action":"Back to Center"},"signal_jammer_v1":{"name":"Signal Jammer","cat":"Other","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"Electronic disruption module that interferes with enemy sensors, wireless links, and remote control systems.","energy":1,"action":"Disrupts sensors"},"ventilation_port_v1":{"name":"Ventilation Port","cat":"Other","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_TOP,EXTERNAL_SIDE_BOTTOM,EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT,EXTERNAL_SIDE_BACK],"desc":"External airflow port that connects the body to internal air-cooling systems and allows heat to be vented outside.","energy":0,"special":"Required for air cooling"}
}
const INTERNAL_SIZE_X := 3
const INTERNAL_SIZE_Y := 3
const INTERNAL_SIZE_Z := 4
const CONSTRUCTOR_PROFILE_SCOUT_SIZE := Vector3i(3, 3, 4)
const CONSTRUCTOR_PROFILE_ENGINEER_SIZE := Vector3i(5, 5, 6)
const CONSTRUCTOR_PROFILE_JUGGERNAUT_SIZE := Vector3i(7, 7, 9)
const THERMAL_CRITICAL_HEAT := 5
const MODULE_ICON_DIR: String = "res://assets/ui/module_icons/"

@export var start_grid_position := Vector2i(1, 1)
@export var use_isometric_visual_position: bool = false
@export var isometric_visual_y_offset: float = 0.0
@export var isometric_visual_rotation_offset_degrees: float = 90.0

@export var max_energy: int = 50
@export var vision_range: int = 3
@export var actions_per_turn: int = 5
@export var debug_install_wheels: bool = true
@export var debug_install_manipulator: bool = true
@export var debug_install_interface: bool = true
@export var debug_install_visor: bool = true

@export var debug_add_mission4_modules_to_box: bool = false
@export var debug_place_mission4_field_modules: bool = false
@export var debug_place_hidden_route_node: bool = false
@export var debug_hidden_route_node_position: Vector2i = Vector2i(3, 1)
@export var debug_show_hidden_route_node_logs: bool = false

# MVP module model: modules can grant small passive bonuses and command flags.
# No inventory/equipment UI yet; this only stores and applies data programmatically.
var base_max_energy: int = 0
var base_vision_range: int = 0
var base_actions_per_turn: int = 0

var grid_position := Vector2i.ZERO
var direction: Direction = Direction.NORTH

var energy: int = 0
var actions_left: int = 0
var mission_finished: bool = false
var sector_completed: bool = false
var current_mission_index: int = 1
var max_mission_index: int = 10
var turns_used: int = 0
var mission4_hidden_route_node_discovered: bool = false
var has_key: bool = false
var has_info_key: bool = false
var installed_modules: Array[BipobModule] = []
var box_storage: Array[BipobModule] = []
var external_modules_by_slot: Dictionary = {}
var placed_external_modules: Array[Dictionary] = []
var external_pockets_by_side: Dictionary = {}
var internal_modules_by_cell: Dictionary = {}
var placed_internal_modules: Array[Dictionary] = []
var internal_overlay_paths: Array[Dictionary] = []
var next_internal_overlay_path_id: int = 1
var constructor_body_size: Vector3i = CONSTRUCTOR_PROFILE_SCOUT_SIZE
var selected_internal_box_index: int = 0
var selected_internal_origin: Vector3i = Vector3i.ZERO
var selected_internal_rotation: int = 0
var selected_overlay_path_type: String = "liquid"
var selected_overlay_cells: Array[Vector3i] = []
var selected_overlay_path_index: int = 0
var selected_external_side: String = EXTERNAL_SIDE_TOP
var selected_external_origin: Vector2i = Vector2i.ZERO
var found_module: BipobModule = null
var held_module: BipobModule = null
var stored_physical_module: BipobModule = null
var manipulator_items: Array[BipobModule] = []
var pocket_items: Array[BipobModule] = []
var available_manipulator_slots: int = 1
var max_manipulator_slots: int = 3
var available_pocket_slots: int = 1
var max_pocket_slots: int = 4
var field_modules_by_position: Dictionary = {}
var physical_carry_capacity: int = 2
var digital_storage: Dictionary = {}
var digital_storage_capacity: int = 1
var max_digital_storage_slots: int = 4
var available_digital_storage_slots: int = 1
var buffer_item: Dictionary = {}
var digital_world_records: Dictionary = {}
var selected_world_action: String = ""
var selected_grid_cell: Vector2i = Vector2i(-1, -1)
var selected_route_target_cell: Vector2i = Vector2i(-1, -1)
var selected_route_cells: Array[Vector2i] = []
var mouse_route_execution_in_progress: bool = false
var pending_mouse_route_cells: Array[Vector2i] = []
const DIGITAL_RECORD_ROUTE_DATA := "route_data"
const DIGITAL_RECORD_INFO_KEY := "info_key"
var last_diagnostic_result: DiagnosticResult = null
var mission_start_energy: int = 0
var mission_start_actions_left: int = 0
var mission_start_has_key: bool = false
var mission_start_has_info_key: bool = false
var mission_start_held_module: BipobModule = null
var mission_start_stored_physical_module: BipobModule = null
var missing_visor_hint_shown: bool = false
var active_hidden_route_node_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_direction: Direction = Direction.EAST
var mission8_fan_speed: int = 0
var mission8_terminal_cooled: bool = false
var mission8_terminal_hacked: bool = false
var mission8_fan_platform_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_control_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_left_control_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_right_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_speed_up_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_speed_down_control_position: Vector2i = Vector2i(-1, -1)
var mission8_terminal_position: Vector2i = Vector2i(-1, -1)
var mission8_door_position: Vector2i = Vector2i(-1, -1)
var mission8_airflow_cells: Array[Vector2i] = []
var mission7_is_dragging_cable: bool = false
var mission7_cable_connected: bool = false
var mission7_cable_reel_position: Vector2i = Vector2i(-1, -1)
var mission7_socket_position: Vector2i = Vector2i(-1, -1)
var mission7_powered_gate_position: Vector2i = Vector2i(-1, -1)
var mission7_cable_path: Array[Vector2i] = []
var mission7_cable_max_length: int = 12
var movement_cells_since_energy_spend: int = 0
var platform_height_level: int = 0
var carried_by_platform_id: String = ""
var player_action_index: int = 0
var bipob_damage_state_by_profile: Dictionary = {"alpha": false, "beta": true, "juggernaut": false}
var bipob_armor_state_by_profile: Dictionary = {"alpha": {"current": 20, "max": 20}, "beta": {"current": 10, "max": 20}, "juggernaut": {"current": 20, "max": 20}}
var last_internal_overheat_messages: Array[String] = []
var map_constructor_input_blocked: bool = false

@onready var grid_manager: GridManager = get_node("../Field")
@onready var mission_label: Label = get_node("../UI/MissionLabel")
@onready var top_face: Polygon2D = get_node_or_null("TopFace")
@onready var left_face: Polygon2D = get_node_or_null("LeftFace")
@onready var right_face: Polygon2D = get_node_or_null("RightFace")
@onready var front_accent: Polygon2D = get_node_or_null("FrontAccent")
@onready var base_shadow: Polygon2D = get_node_or_null("BaseShadow")
@onready var mission_manager: Node = get_node_or_null("../MissionManager")

# BIP-604 integration hook:
# When a real save/load system serializes mission state, include
# save_data["world_object_runtime_state"] = get_world_object_runtime_state_for_save()
# and call apply_world_object_runtime_state_from_save(save_data) after
# start_mission()/setup_world_objects_for_mission() has finished.
func get_world_object_runtime_state_for_save() -> Dictionary:
	if mission_manager == null:
		return {}
	if not mission_manager.has_method("get_world_object_runtime_state"):
		return {}
	var runtime_state_variant: Variant = mission_manager.call("get_world_object_runtime_state")
	if typeof(runtime_state_variant) != TYPE_DICTIONARY:
		return {}
	return runtime_state_variant

func apply_world_object_runtime_state_from_save(save_data: Dictionary) -> void:
	if mission_manager == null:
		return
	if not mission_manager.has_method("apply_world_object_runtime_state"):
		return
	var world_runtime_state_variant: Variant = save_data.get("world_object_runtime_state", {})
	if typeof(world_runtime_state_variant) != TYPE_DICTIONARY:
		return
	mission_manager.call("apply_world_object_runtime_state", world_runtime_state_variant)

func get_world_runtime_restore_warnings() -> Array[String]:
	if mission_manager == null:
		return []
	if not mission_manager.has_method("get_world_runtime_restore_warnings"):
		return []
	var warnings_variant: Variant = mission_manager.call("get_world_runtime_restore_warnings")
	if typeof(warnings_variant) != TYPE_ARRAY:
		return []
	var warnings: Array[String] = []
	for warning_variant in warnings_variant:
		var warning := String(warning_variant).strip_edges()
		if warning.is_empty():
			continue
		warnings.append(warning)
	return warnings

func get_world_object_debug_info(object_id: String) -> Dictionary:
	if mission_manager == null:
		return {}
	if not mission_manager.has_method("get_world_object_debug_info"):
		return {}
	var info_variant: Variant = mission_manager.call("get_world_object_debug_info", object_id)
	if typeof(info_variant) != TYPE_DICTIONARY:
		return {}
	return info_variant

func get_world_cell_debug_info(cell: Vector2i) -> Dictionary:
	if mission_manager == null:
		return {}
	if not mission_manager.has_method("get_world_cell_debug_info"):
		return {}
	var info_variant: Variant = mission_manager.call("get_world_cell_debug_info", cell)
	if typeof(info_variant) != TYPE_DICTIONARY:
		return {}
	return info_variant

func get_world_objects_debug_table_text(filter: String = "") -> String:
	if mission_manager == null:
		return "World debug unavailable: mission manager is missing."
	if not mission_manager.has_method("get_world_objects_debug_table_text"):
		return "World debug unavailable: mission manager helper missing."
	var text_variant: Variant = mission_manager.call("get_world_objects_debug_table_text", filter)
	return String(text_variant)

func get_power_network_debug_summary_text(filter: String = "") -> String:
	if mission_manager == null:
		return "Power network summary unavailable: mission manager is missing."
	if not mission_manager.has_method("get_power_network_debug_summary_text"):
		return "Power network summary unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_debug_summary_text", filter))

func validate_power_network_runtime_state() -> Dictionary:
	if mission_manager == null:
		return {"valid": false, "networks": 0, "objects": 0, "warnings": ["Mission manager is missing."], "errors": ["Mission manager unavailable."]}
	if not mission_manager.has_method("validate_power_network_runtime_state"):
		return {"valid": false, "networks": 0, "objects": 0, "warnings": ["Power runtime helper missing."], "errors": ["validate_power_network_runtime_state helper missing."]}
	var report_variant: Variant = mission_manager.call("validate_power_network_runtime_state")
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {"valid": false, "networks": 0, "objects": 0, "warnings": ["Power runtime helper returned invalid data."], "errors": ["Power runtime report is not a dictionary."]}
	return report_variant

func validate_power_network_debug_scenario() -> Array[String]:
	if mission_manager == null:
		return ["Power network debug validation unavailable: mission manager/helper missing."]
	if not mission_manager.has_method("validate_power_network_debug_scenario"):
		return ["Power network debug validation unavailable: mission manager/helper missing."]
	var warnings_variant: Variant = mission_manager.call("validate_power_network_debug_scenario")
	if typeof(warnings_variant) != TYPE_ARRAY:
		return ["Power network debug validation unavailable: mission manager/helper missing."]
	var warnings: Array[String] = []
	for warning_variant in warnings_variant:
		var warning := String(warning_variant).strip_edges()
		if warning.is_empty():
			continue
		warnings.append(warning)
	return warnings

func get_power_network_debug_validation_text() -> String:
	if mission_manager == null:
		return "Power network debug validation unavailable: mission manager/helper missing."
	if not mission_manager.has_method("get_power_network_debug_validation_text"):
		return "Power network debug validation unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_debug_validation_text"))

func preview_power_network_state_application(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("preview_power_network_state_application"):
		return {
			"networks": 0,
			"objects": 0,
			"changes": [],
			"warnings": ["Power network state preview unavailable: mission manager/helper missing."]
		}
	var preview_variant: Variant = mission_manager.call("preview_power_network_state_application", filter)
	if typeof(preview_variant) != TYPE_DICTIONARY:
		return {
			"networks": 0,
			"objects": 0,
			"changes": [],
			"warnings": ["Power network state preview unavailable: mission manager/helper missing."]
		}
	return preview_variant

func get_power_network_state_preview_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_network_state_preview_text"):
		return "Power network state preview unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_state_preview_text", filter))

func apply_power_network_state_from_preview(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_power_network_state_from_preview"):
		return {
			"applied": 0,
			"changes": [],
			"warnings": ["Power network apply unavailable: mission manager/helper missing."]
		}
	var report_variant: Variant = mission_manager.call("apply_power_network_state_from_preview", filter)
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {
			"applied": 0,
			"changes": [],
			"warnings": ["Power network apply unavailable: mission manager/helper missing."]
		}
	return report_variant

func apply_power_network_after_explicit_power_event(reason: String = "", filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_power_network_after_explicit_power_event"):
		return {"event_reason": reason, "applied": 0, "changes": [], "warnings": ["Power event apply unavailable: mission manager/helper missing."]}
	var report_variant: Variant = mission_manager.call("apply_power_network_after_explicit_power_event", reason, filter)
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {"event_reason": reason, "applied": 0, "changes": [], "warnings": ["Power event apply unavailable: mission manager/helper missing."]}
	var report: Dictionary = report_variant
	if not report.has("event_reason"):
		report["event_reason"] = reason
	if not report.has("applied"):
		report["applied"] = 0
	if not report.has("changes"):
		report["changes"] = []
	if not report.has("warnings"):
		report["warnings"] = []
	return report

func execute_power_event_apply_and_get_report_text(reason: String = "", filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("execute_power_event_apply_and_get_report_text"):
		return "Power event apply unavailable: mission manager/helper missing."
	return String(mission_manager.call("execute_power_event_apply_and_get_report_text", reason, filter))

func get_power_event_apply_preview_text(reason: String = "", filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_event_apply_preview_text"):
		return "Power event apply preview unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_event_apply_preview_text", reason, filter))

func execute_power_network_apply_and_get_report_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("execute_power_network_apply_and_get_report_text"):
		return "Power network apply unavailable: mission manager/helper missing."
	return String(mission_manager.call("execute_power_network_apply_and_get_report_text", filter))

func preview_power_graph_state_application(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("preview_power_graph_state_application"):
		return {"filter": filter, "sources": [], "nodes": [], "reachable_object_ids": [], "blocked": [], "changes": [], "warnings": ["Power graph preview unavailable: mission manager/helper missing."]}
	var preview_variant: Variant = mission_manager.call("preview_power_graph_state_application", filter)
	if typeof(preview_variant) != TYPE_DICTIONARY:
		return {"filter": filter, "sources": [], "nodes": [], "reachable_object_ids": [], "blocked": [], "changes": [], "warnings": ["Power graph preview unavailable: mission manager/helper missing."]}
	return preview_variant

func get_power_graph_preview_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_graph_preview_text"):
		return "Power graph preview unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_graph_preview_text", filter))

func apply_power_graph_state_from_preview(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_power_graph_state_from_preview"):
		return {"applied": 0, "changes": [], "warnings": ["Power graph apply unavailable: mission manager/helper missing."]}
	var report_variant: Variant = mission_manager.call("apply_power_graph_state_from_preview", filter)
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {"applied": 0, "changes": [], "warnings": ["Power graph apply unavailable: mission manager/helper missing."]}
	return report_variant

func execute_power_graph_apply_and_get_report_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("execute_power_graph_apply_and_get_report_text"):
		return "Power graph apply unavailable: mission manager/helper missing."
	return String(mission_manager.call("execute_power_graph_apply_and_get_report_text", filter))

func _is_terminal_powered_for_interaction(world_object: Dictionary) -> bool:
	if mission_manager == null or not mission_manager.has_method("_is_terminal_powered_for_interaction"):
		var state := String(world_object.get("state", "")).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
		if bool(world_object.get("damaged", false)) or bool(world_object.get("broken", false)) or bool(world_object.get("destroyed", false)):
			return false
		if state in ["damaged", "broken", "destroyed", "overheated", "unpowered"]:
			return false
		if world_object.has("is_powered"):
			return bool(world_object.get("is_powered", true))
		return true
	return bool(mission_manager.call("_is_terminal_powered_for_interaction", world_object))

func get_power_network_apply_preview_report_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_network_apply_preview_report_text"):
		return "Power network apply preview unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_apply_preview_report_text", filter))

func execute_power_network_apply_debug_command(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("execute_power_network_apply_debug_command"):
		return "Power network apply debug command unavailable: mission manager/helper missing."
	return String(mission_manager.call("execute_power_network_apply_debug_command", filter))

func get_power_network_apply_debug_preview_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_network_apply_debug_preview_text"):
		return "Power network apply debug preview unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_apply_debug_preview_text", filter))

func get_power_network_apply_report_text(_filter: String = "") -> String:
	return "Power network apply report renamed: use execute_power_network_apply_and_get_report_text() to apply, or get_power_network_apply_preview_report_text() for read-only preview."



func execute_power_source_recovery_apply(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("execute_power_source_recovery_apply"):
		return {"recovery": {"filter": filter, "resolved_filter": filter, "recovered": [], "warnings": ["Power source recovery unavailable: mission manager/helper missing."]}, "apply": {"event_reason": "source_cooling_recovered", "applied": 0, "changes": [], "warnings": []}}
	var report_variant: Variant = mission_manager.call("execute_power_source_recovery_apply", filter)
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {"recovery": {"filter": filter, "resolved_filter": filter, "recovered": [], "warnings": ["Power source recovery unavailable: mission manager/helper missing."]}, "apply": {"event_reason": "source_cooling_recovered", "applied": 0, "changes": [], "warnings": []}}
	return report_variant

func get_power_network_full_debug_report_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_power_network_full_debug_report_text"):
		return "Power network full debug report unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_power_network_full_debug_report_text", filter))

func preview_cooling_application(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("preview_cooling_application"):
		return {"filter": filter, "resolved_filter": filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": ["Cooling preview unavailable: mission manager/helper missing."]}
	var report_variant: Variant = mission_manager.call("preview_cooling_application", filter)
	return report_variant if typeof(report_variant) == TYPE_DICTIONARY else {"filter": filter, "resolved_filter": filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": ["Cooling preview returned invalid data."]}

func apply_cooling_application(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_cooling_application"):
		return {"filter": filter, "resolved_filter": filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": ["Cooling apply unavailable: mission manager/helper missing."]}
	var report_variant: Variant = mission_manager.call("apply_cooling_application", filter)
	return report_variant if typeof(report_variant) == TYPE_DICTIONARY else {"filter": filter, "resolved_filter": filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": ["Cooling apply returned invalid data."]}

func get_cooling_debug_report_text(filter: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_cooling_debug_report_text"):
		return "Cooling debug report unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_cooling_debug_report_text", filter))

func validate_full_power_system_runtime() -> Array[String]:
	if mission_manager == null or not mission_manager.has_method("validate_full_power_system_runtime"):
		return ["Full power validation unavailable: mission manager/helper missing."]
	var warnings_variant: Variant = mission_manager.call("validate_full_power_system_runtime")
	if typeof(warnings_variant) != TYPE_ARRAY:
		return ["Full power validation unavailable: mission manager/helper missing."]
	var warnings: Array[String] = []
	for warning_variant in warnings_variant:
		warnings.append(String(warning_variant))
	return warnings

func get_full_power_system_validation_text() -> String:
	if mission_manager == null or not mission_manager.has_method("get_full_power_system_validation_text"):
		return "Full power validation text unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_full_power_system_validation_text"))

func validate_platform_runtime_state() -> Dictionary:
	if mission_manager == null:
		return {"valid": false, "platforms": 0, "terminals": 0, "warnings": ["Mission manager is missing."], "errors": ["Mission manager unavailable."]}
	if not mission_manager.has_method("validate_platform_runtime_state"):
		return {"valid": false, "platforms": 0, "terminals": 0, "warnings": ["Platform runtime helper missing."], "errors": ["validate_platform_runtime_state helper missing."]}
	var report_variant: Variant = mission_manager.call("validate_platform_runtime_state")
	if typeof(report_variant) != TYPE_DICTIONARY:
		return {"valid": false, "platforms": 0, "terminals": 0, "warnings": ["Platform runtime helper returned invalid data."], "errors": ["Platform runtime report is not a dictionary."]}
	return report_variant

func get_platform_runtime_validation_text() -> String:
	if mission_manager == null:
		return "Platform runtime validation unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_runtime_validation_text"):
		return "Platform runtime validation unavailable: helper missing."
	return String(mission_manager.call("get_platform_runtime_validation_text"))

func get_platform_runtime_table_text(filter: String = "") -> String:
	if mission_manager == null:
		return "Platform runtime table unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_runtime_table_text"):
		return "Platform runtime table unavailable: helper missing."
	return String(mission_manager.call("get_platform_runtime_table_text", filter))

func get_platform_state_summary_table_text(filter: String = "") -> String:
	if mission_manager == null:
		return "Platform state summary unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_state_summary_table_text"):
		return "Platform state summary unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_platform_state_summary_table_text", filter))

func get_platform_occupant_summary_table_text(filter: String = "") -> String:
	if mission_manager == null:
		return "Platform occupant summary unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_occupant_summary_table_text"):
		return "Platform occupant summary unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_platform_occupant_summary_table_text", filter))

func validate_platform_height_gating_debug_scenario() -> Array[String]:
	if mission_manager == null:
		return ["Platform height gating validation unavailable: mission manager is missing."]
	if not mission_manager.has_method("validate_platform_height_gating_debug_scenario"):
		return ["Platform height gating validation unavailable: helper missing."]
	var warnings_variant: Variant = mission_manager.call("validate_platform_height_gating_debug_scenario")
	if typeof(warnings_variant) != TYPE_ARRAY:
		return ["Platform height gating validation unavailable: helper returned invalid data."]
	var warnings: Array[String] = []
	for warning_variant in warnings_variant:
		var warning := String(warning_variant).strip_edges()
		if warning.is_empty():
			continue
		warnings.append(warning)
	return warnings

func get_platform_height_gating_validation_text() -> String:
	if mission_manager == null:
		return "Platform height gating validation unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_height_gating_validation_text"):
		return "Platform height gating validation unavailable: helper missing."
	return String(mission_manager.call("get_platform_height_gating_validation_text"))


func validate_platform_timer_tick_debug_scenario() -> Array[String]:
	if mission_manager == null:
		return ["Platform timer tick validation unavailable: mission manager is missing."]
	if not mission_manager.has_method("validate_platform_timer_tick_debug_scenario"):
		return ["Platform timer tick validation unavailable: helper missing."]
	var warnings_variant: Variant = mission_manager.call("validate_platform_timer_tick_debug_scenario")
	if typeof(warnings_variant) != TYPE_ARRAY:
		return ["Platform timer tick validation unavailable: helper returned invalid data."]
	var warnings: Array[String] = []
	for warning_variant in warnings_variant:
		var warning := String(warning_variant).strip_edges()
		if warning.is_empty():
			continue
		warnings.append(warning)
	return warnings

func get_platform_timer_tick_validation_text() -> String:
	if mission_manager == null:
		return "Platform timer tick validation unavailable: mission manager is missing."
	if not mission_manager.has_method("get_platform_timer_tick_validation_text"):
		return "Platform timer tick validation unavailable: helper missing."
	return String(mission_manager.call("get_platform_timer_tick_validation_text"))
func install_module(module: BipobModule) -> void:
	# MVP behavior: install immediately applies passive bonuses.
	if module == null:
		return
	if is_module_broken(module):
		hint_requested.emit("Broken module cannot be installed.")
		return

	# Keep module state consistent across storage and installed lists.
	var storage_index := box_storage.find(module)
	if storage_index != -1:
		box_storage.remove_at(storage_index)

	if installed_modules.has(module):
		return

	installed_modules.append(module)
	recalculate_module_stats()
	status_changed.emit()

func has_command(command_id: String) -> bool:
	for module in installed_modules:
		if module == null or not is_module_functional(module):
			continue
		if command_id in module.granted_commands:
			return true

	return false

func get_installed_module_by_id(module_id: String) -> BipobModule:
	for module in installed_modules:
		if module == null or not is_module_functional(module):
			continue
		if module.id == module_id:
			return module
	return null

func has_module_id(module_id: String) -> bool:
	return get_installed_module_by_id(module_id) != null

func has_module_id_in_box(module_id: String) -> bool:
	for module in box_storage:
		if module == null:
			continue
		if module.id == module_id:
			return true
	return false

func has_module_id_in_box_storage(module_id: String) -> bool:
	for module in box_storage:
		if module != null and module.id == module_id:
			return true
	return false

func has_module_id_in_physical_carry(module_id: String) -> bool:
	if held_module != null and held_module.id == module_id:
		return true
	if stored_physical_module != null and stored_physical_module.id == module_id:
		return true
	return false

func has_module_id_anywhere(module_id: String) -> bool:
	if has_module_id(module_id) or has_module_id_in_box(module_id) or has_module_id_in_physical_carry(module_id):
		return true

	for module_position in field_modules_by_position.keys():
		var field_module_variant: Variant = field_modules_by_position[module_position]
		if field_module_variant == null:
			continue
		var field_module: BipobModule = field_module_variant
		if field_module.id == module_id:
			return true

	return false


func get_module_visual_key(module: BipobModule) -> String:
	return BipobModulePresenterRef.get_module_visual_key(module)



func get_module_icon_path(module: BipobModule) -> String:
	var key: String = get_module_visual_key(module)
	return get_module_icon_path_by_key(key)

func get_module_icon_path_by_key(key: String) -> String:
	if key.is_empty():
		key = "unknown"
	return MODULE_ICON_DIR + key + ".png"

func get_module_visual_short_label(module: BipobModule) -> String:
	return BipobModulePresenterRef.get_module_visual_short_label(module)

func get_module_visual_color(module: BipobModule) -> Color:
	if module == null:
		return Color(0.25, 0.28, 0.30, 1.0)

	var key: String = get_module_visual_key(module)

	match key:
		"battery":
			return Color(0.25, 0.55, 0.95, 1.0)
		"processor":
			return Color(0.95, 0.45, 0.18, 1.0)
		"memory":
			return Color(0.55, 0.35, 0.95, 1.0)
		"storage":
			return Color(0.65, 0.70, 0.78, 1.0)
		"power":
			return Color(0.95, 0.78, 0.20, 1.0)
		"cooler":
			return Color(0.20, 0.75, 0.95, 1.0)
		"radiator":
			return Color(0.45, 0.85, 0.95, 1.0)
		"water_tube":
			return Color(0.05, 0.85, 0.95, 1.0)
		"air_duct":
			return Color(0.55, 0.65, 0.70, 1.0)
		"air_intake":
			return Color(0.35, 0.80, 0.85, 1.0)
		"air_duct_external":
			return Color(0.55, 0.65, 0.70, 1.0)
		"connector":
			return Color(0.20, 0.70, 0.95, 1.0)
		"manipulator_arm", "manipulator_tentacle", "manipulator_magnetic":
			return Color(0.90, 0.55, 0.25, 1.0)
		"radar", "thermal_visor", "xray", "motion_detector":
			return Color(0.25, 0.95, 0.65, 1.0)
		"pocket":
			return Color(0.65, 0.70, 0.78, 1.0)
		"torch", "gas_tank", "plasma_cutter", "saw", "sledgehammer", "welder":
			return Color(0.85, 0.58, 0.22, 1.0)
		"laser", "shock_device":
			return Color(0.95, 0.30, 0.30, 1.0)
		"repair_module":
			return Color(0.25, 0.80, 0.45, 1.0)
		"visor":
			return Color(0.25, 0.95, 0.65, 1.0)
		"wheels":
			return Color(0.55, 0.50, 0.42, 1.0)
		"legs":
			return Color(0.60, 0.55, 0.45, 1.0)
		"tracks":
			return Color(0.45, 0.42, 0.36, 1.0)
		"manipulator":
			return Color(0.90, 0.55, 0.25, 1.0)
		"interface":
			return Color(0.20, 0.70, 0.95, 1.0)
		"gpu":
			return Color(0.20, 0.95, 0.85, 1.0)
		_:
			return Color(0.45, 0.50, 0.55, 1.0)

func get_module_visual_border_color(module: BipobModule) -> Color:
	var base: Color = get_module_visual_color(module)
	return Color(
		clampf(base.r + 0.18, 0.0, 1.0),
		clampf(base.g + 0.18, 0.0, 1.0),
		clampf(base.b + 0.18, 0.0, 1.0),
		1.0
	)

func get_module_visual_card_line(module: BipobModule) -> String:
	if module == null:
		return "[?] Unknown"

	var label: String = get_module_visual_short_label(module)
	var module_name: String = get_module_display_name(module)
	var size_text: String = ""

	if is_internal_module(module):
		var size: Vector3i = get_internal_module_base_size(module)
		size_text = "%dx%dx%d" % [size.x, size.y, size.z]
	elif is_external_module(module):
		var footprint: Vector2i = get_external_module_footprint_size(module)
		size_text = "%dx%d" % [footprint.x, footprint.y]
	elif is_internal_overlay_module(module):
		size_text = "overlay"
	else:
		size_text = "module"

	return "[%s] %s — %s" % [
		label,
		module_name,
		size_text
	]
func get_external_module_footprint_size(module: BipobModule) -> Vector2i:
	if module == null:
		return Vector2i.ONE
	if module.external_width > 0 and module.external_height > 0:
		return Vector2i(module.external_width, module.external_height)
	if EXTERNAL_MODULE_CATALOG.has(module.id):
		return EXTERNAL_MODULE_CATALOG[module.id].get("size", Vector2i.ONE)
	return Vector2i(1, 1)
func get_module_category(module: BipobModule) -> String:
	if module == null:
		return "utility"

	if not module.category.is_empty():
		return module.category

	if module.placement_type == "internal" or module.placement_type == "internal_overlay":
		match String(module.internal_family).to_lower():
			"battery", "power":
				return "Power"
			"cpu":
				return "CPU"
			"gpu":
				return "GPU"
			"ram":
				return "RAM"
			"storage":
				return "Storage"
			"interface":
				return "Interface"
			"cooling":
				return "Cooling"
			_:
				return "Other"

	match module.id:
		"wheels_v1", "legs_v1", "tracks_v1":
			return "locomotion"
		"visor_v1", "visor_v2", "visor_v3":
			return "vision"
		"manipulator_v1":
			return "utility"
		"interface_v1":
			return "data"
		"air_intake_v1":
			return "cooling"
		_:
			if module.placement_type == "external":
				return "external"
			return "utility"

func get_effective_visor_level() -> int:
	if has_module_id("visor_v3"):
		return 3
	if has_module_id("visor_v2"):
		return 2
	if has_module_id("visor_v1"):
		return 1
	return 0

func get_effective_gpu_level() -> int:
	if has_module_id("gpu_v1"):
		return 1
	return 0

func get_effective_vision_range() -> int:
	var active_sensor := get_active_sensor_module()
	return get_effective_sensor_range(active_sensor)

func get_effective_vision_side_width() -> int:
	match get_effective_visor_level():
		3:
			return 2
		2:
			return 1
		1:
			return 0
		_:
			return 0

func can_detect_hidden_nodes() -> bool:
	return get_effective_visor_level() >= 2 and get_effective_gpu_level() >= 1

func is_sensor_module(module: BipobModule) -> bool:
	if module == null or module.placement_type != "external":
		return false
	return String(module.category) == "Sensors"

func get_active_sensor_module() -> BipobModule:
	var preferred_ids: Array[String] = ["visor_v3", "visor_v2", "visor_v1", "thermal_visor_v1", "radar_v1", "xray_v1"]
	for module_id in preferred_ids:
		var module := get_installed_module_by_id(module_id)
		if is_sensor_module(module):
			return module
	for module in installed_modules:
		if is_sensor_module(module):
			return module
	return null

func _extract_module_from_internal_record(record) -> BipobModule:
	if record == null:
		return null

	if record is BipobModule:
		return record

	if record is Dictionary:
		var module = record.get("module", null)
		if module is BipobModule:
			return module

		module = record.get("bipob_module", null)
		if module is BipobModule:
			return module

		module = record.get("data", null)
		if module is BipobModule:
			return module

	return null

func get_total_sensor_range_bonus() -> int:
	var total := 0
	for record in placed_internal_modules:
		var internal_module: BipobModule = _extract_module_from_internal_record(record)
		if not is_module_functional(internal_module):
			continue
		total += internal_module.sensor_range_bonus
	return total

func get_total_sensor_visibility_bonus() -> int:
	var total := 0
	for record in placed_internal_modules:
		var internal_module: BipobModule = _extract_module_from_internal_record(record)
		if not is_module_functional(internal_module):
			continue
		total += internal_module.sensor_visibility_bonus
	return total

func get_effective_sensor_range(sensor: BipobModule) -> int:
	if sensor == null:
		return 0
	return maxi(sensor.scan_range + get_total_sensor_range_bonus(), 0)

func get_effective_sensor_visibility(sensor: BipobModule) -> int:
	if sensor == null:
		return 0
	return maxi(sensor.visibility_value + get_total_sensor_visibility_bonus(), 0)

func get_missing_critical_modules() -> Array[String]:
	var critical_modules := [
		{"id": "wheels_v1", "display_name": "Wheels V1"},
		{"id": "manipulator_v1", "display_name": "Manipulator V1"},
		{"id": "interface_v1", "display_name": "External Interface Port V1"},
		{"id": "visor_v1", "display_name": "Visor V1"},
	]
	var missing_modules: Array[String] = []
	for critical_module in critical_modules:
		var required_module_id := String(critical_module.get("id", ""))
		if has_module_id(required_module_id):
			continue
		missing_modules.append(String(critical_module.get("display_name", required_module_id)))
	return missing_modules

func get_pre_mission_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var missing_modules := get_missing_critical_modules()
	if not missing_modules.is_empty():
		warnings.append("Missing critical modules: %s" % ", ".join(missing_modules))

	if energy <= 0:
		warnings.append("Battery depleted. Charge before starting mission.")
	else:
		if energy < 5:
			warnings.append("Battery critically low: %d / %d" % [energy, max_energy])
		if energy < max_energy:
			warnings.append("Battery is not fully charged: %d / %d" % [energy, max_energy])

	return warnings

func can_start_mission_from_box() -> bool:
	return energy > 0

func get_pre_mission_warning_text() -> String:
	var warnings := get_pre_mission_warnings()
	if warnings.is_empty():
		return ""

	return "Warnings before mission:\n- %s" % "\n- ".join(warnings)

func get_constructor_warning_lines() -> Array[String]:
	var warnings: Array[String] = []

	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		warnings.append("Air cooling requires Air Intake Node on external body.")

	if not is_virtual_power_available():
		warnings.append("Virtual power unavailable: Battery and Power Block required.")

	if not is_internal_data_network_available():
		warnings.append("Internal data network unavailable: Internal Interface required.")

	if not is_external_data_network_available():
		warnings.append("External data bridge unavailable: Internal Interface and External Interface required.")

	var critical_count: int = 0
	var warning_heat_count: int = 0
	for module in get_unique_internal_modules():
		var final_heat := int(get_internal_module_heat_breakdown(module).get("final_heat", 0))
		if final_heat >= 4:
			warning_heat_count += 1
		if final_heat >= THERMAL_CRITICAL_HEAT:
			critical_count += 1
	if warning_heat_count > 0:
		warnings.append("Thermal warning: %d module(s) at heat 4+." % warning_heat_count)
	if critical_count > 0:
		warnings.append("Thermal critical preview: %d module(s) at heat 5." % critical_count)

	return warnings

func get_constructor_warning_summary_text() -> String:
	var warnings: Array[String] = get_constructor_warning_lines()
	var lines: Array[String] = []
	lines.append("Constructor warnings:")

	if warnings.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for warning in warnings:
		lines.append("- " + warning)

	return "\n".join(lines)

func get_constructor_metadata_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor metadata:")

	var all_modules: Array[BipobModule] = []
	for module_variant in box_storage:
		var module: BipobModule = module_variant
		if module != null and not all_modules.has(module):
			all_modules.append(module)
	for module in get_unique_external_modules():
		if module != null and not all_modules.has(module):
			all_modules.append(module)
	for module in get_unique_internal_modules():
		if module != null and not all_modules.has(module):
			all_modules.append(module)

	if all_modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in all_modules:
		if module == null:
			continue

		lines.append("- %s | id=%s | placement=%s | category=%s | role=%s" % [
			get_module_display_name(module),
			module.id,
			module.placement_type,
			get_module_category(module),
			module.internal_role
		])

	return "\n".join(lines)

func get_constructor_warning_compact_text() -> String:
	var warnings: Array[String] = get_constructor_warning_lines()
	if warnings.is_empty():
		return "Warnings: none"
	return "Warnings: %d" % warnings.size()

func get_constructor_consistency_summary_text() -> String:
	var issues: Array[String] = get_constructor_consistency_issue_lines()
	var lines: Array[String] = []
	lines.append("Constructor consistency:")
	if issues.is_empty():
		lines.append("OK")
		return "\n".join(lines)
	lines.append("%d issue(s)" % issues.size())
	for issue in issues:
		lines.append("- " + issue)
	return "\n".join(lines)

func get_constructor_consistency_compact_text() -> String:
	var issue_count: int = get_constructor_consistency_issue_lines().size()
	if issue_count == 0:
		return "Consistency: OK"
	return "Consistency: %d issue(s)" % issue_count

func get_constructor_consistency_text() -> String:
	return get_constructor_consistency_summary_text()

func get_constructor_consistency_check_text() -> String:
	return get_constructor_consistency_text()

func get_constructor_consistency_issue_count() -> int:
	var count: int = 0
	var text: String = ""
	if has_method("get_constructor_consistency_text"):
		text = get_constructor_consistency_text()
	elif has_method("get_constructor_consistency_check_text"):
		text = get_constructor_consistency_check_text()
	for line in text.split("\n"):
		var lower_line: String = String(line).to_lower()
		if lower_line.contains("missing") or lower_line.contains("invalid") or lower_line.contains("error"):
			count += 1
	return count

func recalculate_module_stats() -> void:
	# MVP module model: aggregate passive stats from functional installed modules.
	var energy_bonus_total := 0
	var actions_bonus_total := 0
	var vision_bonus_total := 0

	for module in installed_modules:
		if module == null or not is_module_functional(module):
			continue
		energy_bonus_total += module.energy_bonus
		actions_bonus_total += module.actions_bonus
		vision_bonus_total += module.vision_bonus

	max_energy = base_max_energy + energy_bonus_total
	actions_per_turn = base_actions_per_turn + actions_bonus_total
	vision_range = base_vision_range + vision_bonus_total

	energy = clampi(energy, 0, max_energy)
	actions_left = clampi(actions_left, 0, actions_per_turn)

func _ready() -> void:
	base_max_energy = max_energy
	base_vision_range = vision_range
	base_actions_per_turn = actions_per_turn
	_ensure_external_pockets_shape()
	create_default_modules()
	if debug_add_mission4_modules_to_box:
		add_debug_mission4_modules_to_box()
	recalculate_module_stats()
	_initialize_runtime_storage_slots()

	energy = max_energy
	actions_left = actions_per_turn
	
	if mission_label != null:
		mission_label.text = ""
	
	setup_body()
	_setup_cycle_world_action_input()
	
	grid_position = start_grid_position
	update_visual_facing()
	if debug_place_hidden_route_node:
		place_debug_hidden_route_node()
	update_world_position()
	hint_requested.emit(get_current_mission_goal_hint())
	print_status()
	status_changed.emit()

func _setup_cycle_world_action_input() -> void:
	if InputMap.has_action("cycle_world_action"):
		return
	InputMap.add_action("cycle_world_action")
	var cycle_event := InputEventKey.new()
	cycle_event.keycode = KEY_TAB
	InputMap.action_add_event("cycle_world_action", cycle_event)
	# TODO: replace temporary debug action cycling key with final UI action panel.


func _try_get_catalog_mission_title(mission_index: int) -> String:
	if mission_manager == null or not mission_manager.has_method("get_mission_title"):
		return ""
	var mission_id: String = "mission_%d" % mission_index
	return String(mission_manager.call("get_mission_title", mission_id)).strip_edges()

func _try_get_catalog_mission_hint(mission_index: int) -> String:
	if mission_manager == null or not mission_manager.has_method("get_mission_objective_hint"):
		return ""
	var mission_id: String = "mission_%d" % mission_index
	return String(mission_manager.call("get_mission_objective_hint", mission_id)).strip_edges()

func get_mission_name(mission_index: int) -> String:
	match mission_index:
		1:
			return "Mission 1 — First Key"
		2:
			return "Mission 2 — Silent Terminal"
		3:
			return "Mission 3 — Info-Key"
		4:
			return "Mission 4 — Blind Sector"
		5:
			return "Mission 5 — Route Gate"
		6:
			return "Mission 6 — Hot Node"
		7:
			return "Mission 7 — Cable Route"
		8:
			return "Mission 8 — Airflow Terminal"
		9:
			return "Mission 9 — Terrain Passage"
		10:
			var catalog_title: String = _try_get_catalog_mission_title(mission_index)
			if not catalog_title.is_empty():
				return catalog_title
			return "TASK TEST"
		_:
			return "Unknown Mission"

func get_mission_goal_hint(mission_index: int) -> String:
	match mission_index:
		1:
			return "Mission 1: pick up the physical key with Interact, open the door, then reach the exit."
		2:
			return "Mission 2: face the terminal, use Scan Device, then use Hack Device."
		3:
			return "Mission 3: Scan and Hack the terminal to get the Info-Key, then Scan and Hack the digital door."
		4:
			return get_mission4_context_hint()
		5:
			return "Mission 5: use Route Data to unlock the Route Gate and reach the exit."
		6:
			return "Mission 6: scan the hot node, manage the risk, then hack it to open the path."
		7:
			return "Mission 7: take the cable end from the reel, drag it to the socket, then reach the exit."
		8:
			return "Mission 8: cool the terminal with directed airflow, then hack it and reach the exit."
		9:
			return get_mission9_context_hint()
		10:
			var catalog_hint: String = _try_get_catalog_mission_hint(mission_index)
			if not catalog_hint.is_empty():
				return catalog_hint
			return "TASK TEST: validate power, cooling, cables, terminals, doors, platforms, scan/X-Ray, inventory/tools, and extraction."
		_:
			return "No mission goal available."

func get_mission4_context_hint() -> String:
	var has_visor_anywhere := has_module_id_anywhere("visor_v2")
	var has_visor_installed := has_module_id("visor_v2")
	var has_gpu_anywhere := has_module_id_anywhere("gpu_v1")
	var has_gpu_installed := has_module_id("gpu_v1")

	if mission4_hidden_route_node_discovered:
		return "Hidden route-node found. Route Data stored. Reach the exit."
	if has_visor_installed and has_gpu_installed:
		return "Vision system ready. Find the hidden route-node."
	if has_visor_installed and not has_gpu_anywhere:
		return "Visor V2 widens vision, but hidden route data needs processing. Search for GPU V1."
	if has_visor_installed and has_gpu_anywhere and not has_gpu_installed:
		return "GPU V1 recovered. Return to the box and install it."
	if has_visor_anywhere and not has_visor_installed:
		return "Visor V2 recovered. Return to the box and install it."
	return "Mission 4: base vision is too narrow. Search the blind sector for a wider visor."


func get_mission9_context_hint() -> String:
	if has_module_id("legs_v1"):
		return "Legs V1 installed. Cross the stepped passage."
	if has_module_id_anywhere("legs_v1"):
		return "Legs V1 recovered. Return to the box and install it."
	return "Mission 9: wheels work on flat floor. Stepped terrain requires Legs V1."

func has_wheels() -> bool:
	return has_module_id("wheels_v1")

func has_legs() -> bool:
	return has_module_id("legs_v1")

func has_tracks() -> bool:
	return has_module_id("tracks_v1")

func can_cross_stepped_floor() -> bool:
	return has_legs() or has_tracks()
func get_current_mission_goal_hint() -> String:
	return get_mission_goal_hint(current_mission_index)

func start_mission(mission_index: int, save_snapshot: bool = true) -> void:
	# Box preparation flow: mission start resets turn actions, but does not spend resources.
	current_mission_index = clampi(mission_index, 1, max_mission_index)
	mission_finished = false
	turns_used = 0
	actions_left = actions_per_turn
	has_key = false
	has_info_key = false
	last_diagnostic_result = null
	mission4_hidden_route_node_discovered = false
	held_module = null
	stored_physical_module = null
	_initialize_runtime_storage_slots()
	recalculate_module_stats()
	energy = max_energy
	actions_left = actions_per_turn
	field_modules_by_position.clear()
	mission7_is_dragging_cable = false
	mission7_cable_connected = false
	mission7_cable_reel_position = Vector2i(-1, -1)
	mission7_socket_position = Vector2i(-1, -1)
	mission7_powered_gate_position = Vector2i(-1, -1)
	mission7_cable_path.clear()
	if grid_manager != null:
		var mission_id: String = "mission_%d" % current_mission_index
		var used_catalog_layout := false
		if current_mission_index == 10 and mission_manager != null and mission_manager.has_method("apply_catalog_mission_layout_to_grid"):
			used_catalog_layout = bool(mission_manager.call("apply_catalog_mission_layout_to_grid", mission_id))
		if not used_catalog_layout:
			grid_manager.reset_mission_layout(current_mission_index)
		if mission_manager != null:
			mission_manager.setup_world_objects_for_mission(mission_id)
			refresh_world_object_overlay()
		if current_mission_index == 4:
			setup_mission4_field_modules()
		elif debug_place_mission4_field_modules:
			place_debug_mission4_field_modules()
		if current_mission_index == 8:
			setup_mission8()
		elif current_mission_index == 7:
			setup_mission7()
		elif current_mission_index == 9:
			setup_mission9()
		elif grid_manager.has_method("clear_fan_platform_marker"):
			grid_manager.clear_fan_platform_marker()
		grid_manager.reset_fog_of_war()
		if current_mission_index != 4 and debug_place_hidden_route_node:
			place_debug_hidden_route_node()
	grid_position = start_grid_position
	direction = Direction.NORTH
	update_visual_facing()
	update_world_position()

	if save_snapshot:
		mission_start_energy = energy
		mission_start_actions_left = actions_left
		mission_start_has_key = has_key
		mission_start_has_info_key = has_info_key
		mission_start_held_module = held_module
		mission_start_stored_physical_module = stored_physical_module

	if mission_label != null:
		mission_label.text = ""

	status_changed.emit()
	hint_requested.emit(get_current_mission_goal_hint())

func find_valid_debug_hidden_route_node_position() -> Vector2i:
	var preferred_positions: Array[Vector2i] = [
		debug_hidden_route_node_position,
		Vector2i(3, 1),
		Vector2i(2, 1),
		Vector2i(3, 2),
		Vector2i(4, 1)
	]

	for cell_position in preferred_positions:
		if grid_manager == null:
			return Vector2i(-1, -1)
		if grid_manager.is_in_bounds(cell_position) and grid_manager.get_tile(cell_position) == GridManager.TILE_FLOOR:
			return cell_position

	return Vector2i(-1, -1)

func place_debug_hidden_route_node() -> void:
	if not debug_place_hidden_route_node:
		return
	if grid_manager == null:
		return

	var hidden_node_position := find_valid_debug_hidden_route_node_position()
	if hidden_node_position == Vector2i(-1, -1):
		hint_requested.emit("Debug hidden route-node was not placed: no valid floor tile.")
		return

	active_hidden_route_node_position = hidden_node_position
	grid_manager.set_tile(hidden_node_position, GridManager.TILE_HIDDEN_ROUTE_NODE)

	if grid_manager.has_method("reset_hidden_discoveries"):
		grid_manager.reset_hidden_discoveries()

	if debug_show_hidden_route_node_logs:
		print("Debug hidden route-node placed at: ", hidden_node_position)
		hint_requested.emit("Debug hidden route-node placed at: " + str(hidden_node_position))

func restart_current_mission() -> void:
	if sector_completed and current_mission_index == max_mission_index:
		sector_completed = false

	start_mission(current_mission_index, true)

func return_to_box() -> void:
	if mission_finished:
		returned_to_box.emit()
		return

	mission_finished = true
	last_diagnostic_result = null
	if current_mission_index == 7 and mission7_is_dragging_cable:
		release_mission7_cable_end()

	if held_module != null:
		add_module_to_box_storage(held_module)
		held_module = null

	if stored_physical_module != null:
		add_module_to_box_storage(stored_physical_module)
		stored_physical_module = null

	if current_mission_index == 4 and (has_module_id_anywhere("visor_v2") or has_module_id_anywhere("gpu_v1")):
		hint_requested.emit(get_mission4_context_hint())
	elif current_mission_index == 9 and has_module_id_anywhere("legs_v1"):
		hint_requested.emit(get_mission9_context_hint())
	else:
		hint_requested.emit("Returned to box. Mission attempt aborted.")
	status_changed.emit()
	returned_to_box.emit()

func store_digital_record(record_id: String, display_name: String, description: String = "") -> void:
	if record_id.is_empty():
		return

	if digital_storage_capacity <= 0:
		digital_storage.clear()
		status_changed.emit()
		return

	var record := {
		"id": record_id,
		"display_name": display_name,
		"description": description,
	}

	if digital_storage.has(record_id):
		digital_storage[record_id] = record
		hint_requested.emit("Digital record updated: " + get_digital_record_display_name(record_id))
		status_changed.emit()
		return

	if digital_storage.size() < digital_storage_capacity:
		digital_storage[record_id] = record
		hint_requested.emit("Digital record stored: " + display_name)
		status_changed.emit()
		return

	if digital_storage.size() >= digital_storage_capacity:
		var existing_record_id := String(digital_storage.keys()[0])
		var old_display_name := get_digital_record_display_name(existing_record_id)
		digital_storage.erase(existing_record_id)
		digital_storage[record_id] = record
		hint_requested.emit("Digital storage overwritten: " + old_display_name + " -> " + display_name)
		status_changed.emit()
		return

func get_first_digital_record_display_name() -> String:
	if digital_storage.is_empty():
		return "empty"

	var first_record_id := String(digital_storage.keys()[0])
	return get_digital_record_display_name(first_record_id)

func has_digital_record(record_id: String) -> bool:
	return digital_storage.has(record_id)

func use_digital_record(record_id: String) -> bool:
	return has_digital_record(record_id)

func get_digital_record_display_name(record_id: String) -> String:
	if not digital_storage.has(record_id):
		return record_id

	var record_data: Variant = digital_storage.get(record_id, {})
	if typeof(record_data) != TYPE_DICTIONARY:
		return record_id

	var record_dict: Dictionary = record_data
	if record_dict.has("display_name"):
		var resolved_display_name := String(record_dict.get("display_name", ""))
		if not resolved_display_name.is_empty():
			return resolved_display_name

	return record_id

func get_digital_storage_text() -> String:
	if digital_storage.is_empty():
		return "Digital storage: empty"

	var lines := ["Digital storage:"]
	for record_id in digital_storage.keys():
		lines.append("- " + get_digital_record_display_name(String(record_id)))
	return "\n".join(lines)

func debug_store_route_data() -> void:
	store_digital_record(
		DIGITAL_RECORD_ROUTE_DATA,
		"Route Data",
		"Temporary route record for future route mission."
	)

func start_next_mission() -> void:
	if sector_completed:
		hint_requested.emit("Sector-01 complete. All systems cleared.")
		status_changed.emit()
		return

	if current_mission_index < max_mission_index:
		start_mission(current_mission_index + 1)
		return

	sector_completed = true
	hint_requested.emit("Sector-01 complete. All systems cleared.")
	status_changed.emit()

func set_constructor_body_size(body_size: Vector3i) -> void:
	constructor_body_size = Vector3i(
		maxi(1, body_size.x),
		maxi(1, body_size.y),
		maxi(1, body_size.z)
	)
	_ensure_external_pockets_shape()


func get_constructor_body_size() -> Vector3i:
	return constructor_body_size


func get_external_side_size(side_id: String) -> Vector2i:
	var body_size: Vector3i = get_constructor_body_size()
	match side_id:
		EXTERNAL_SIDE_TOP:
			return Vector2i(body_size.x, body_size.y)
		EXTERNAL_SIDE_BOTTOM:
			return Vector2i(body_size.x, body_size.y)
		EXTERNAL_SIDE_LEFT:
			return Vector2i(body_size.y, body_size.z)
		EXTERNAL_SIDE_RIGHT:
			return Vector2i(body_size.y, body_size.z)
		EXTERNAL_SIDE_FRONT:
			return Vector2i(body_size.x, body_size.z)
		EXTERNAL_SIDE_BACK:
			return Vector2i(body_size.x, body_size.z)
		_:
			return Vector2i.ZERO

func get_bipop_body_armor_max(profile_id: String = "") -> int:
	var normalized: String = profile_id.strip_edges().to_lower()
	if normalized.is_empty():
		var size: Vector3i = get_constructor_body_size()
		if size == CONSTRUCTOR_PROFILE_JUGGERNAUT_SIZE:
			normalized = "juggernaut"
		elif size == CONSTRUCTOR_PROFILE_ENGINEER_SIZE:
			normalized = "engineer"
		else:
			normalized = "scout"

	match normalized:
		"juggernaut":
			return 40
		"engineer", "beta":
			return 20
		_:
			return 10


func get_internal_volume_size() -> Vector3i:
	return get_constructor_body_size()

func get_internal_slot_key(cell: Vector3i) -> String:
	return "%d:%d:%d" % [cell.x, cell.y, cell.z]

func is_internal_cell_in_bounds(cell: Vector3i) -> bool:
	var volume_size := get_internal_volume_size()
	return (
		cell.x >= 0 and cell.y >= 0 and cell.z >= 0
	and cell.x < volume_size.x and cell.y < volume_size.y and cell.z < volume_size.z
	)

func is_internal_cell_on_body_edge(cell: Vector3i) -> bool:
	if not is_internal_cell_in_bounds(cell):
		return false

	var volume_size: Vector3i = get_internal_volume_size()

	return (
		cell.x == 0
		or cell.y == 0
		or cell.z == 0
		or cell.x == volume_size.x - 1
		or cell.y == volume_size.y - 1
		or cell.z == volume_size.z - 1
	)

func clamp_selected_overlay_path_index() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	if selected_overlay_path_index < 0:
		selected_overlay_path_index = internal_overlay_paths.size() - 1
	elif selected_overlay_path_index >= internal_overlay_paths.size():
		selected_overlay_path_index = 0

func get_selected_overlay_path_record() -> Dictionary:
	clamp_selected_overlay_path_index()

	if internal_overlay_paths.is_empty():
		return {}

	return internal_overlay_paths[selected_overlay_path_index]

func get_selected_overlay_path_id() -> String:
	var record: Dictionary = get_selected_overlay_path_record()
	return String(record.get("id", ""))

func select_prev_overlay_path() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	selected_overlay_path_index -= 1
	clamp_selected_overlay_path_index()

func select_next_overlay_path() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	selected_overlay_path_index += 1
	clamp_selected_overlay_path_index()

func remove_selected_overlay_path() -> bool:
	var path_id: String = get_selected_overlay_path_id()
	if path_id.is_empty():
		return false

	var removed: bool = remove_internal_overlay_path(path_id)
	clamp_selected_overlay_path_index()
	return removed

func get_selected_overlay_module_id() -> String:
	if selected_overlay_path_type == "duct":
		return "air_duct_v1"
	return "water_tube_v1"

func is_internal_overlay_module(module: BipobModule) -> bool:
	return module != null and module.is_non_volume_cooling_path

func is_valid_internal_overlay_cell(cell: Vector3i) -> bool:
	return is_internal_cell_in_bounds(cell)

func has_selected_overlay_cell(cell: Vector3i) -> bool:
	for selected_cell in selected_overlay_cells:
		if selected_cell == cell:
			return true
	return false

func add_selected_overlay_cell(cell: Vector3i) -> bool:
	if not is_valid_internal_overlay_cell(cell):
		return false
	if has_selected_overlay_cell(cell):
		return false
	selected_overlay_cells.append(cell)
	return true

func remove_selected_overlay_cell(cell: Vector3i) -> bool:
	for i in range(selected_overlay_cells.size()):
		if selected_overlay_cells[i] == cell:
			selected_overlay_cells.remove_at(i)
			return true
	return false

func clear_selected_overlay_cells() -> void:
	selected_overlay_cells.clear()

func toggle_selected_overlay_cell(cell: Vector3i) -> bool:
	if has_selected_overlay_cell(cell):
		return remove_selected_overlay_cell(cell)
	return add_selected_overlay_cell(cell)

func get_last_selected_overlay_cell() -> Vector3i:
	if selected_overlay_cells.is_empty():
		return selected_internal_origin
	return selected_overlay_cells[selected_overlay_cells.size() - 1]

func get_overlay_direction_offset(direction_id: String) -> Vector3i:
	match direction_id:
		"+x":
			return Vector3i(1, 0, 0)
		"-x":
			return Vector3i(-1, 0, 0)
		"+y":
			return Vector3i(0, 1, 0)
		"-y":
			return Vector3i(0, -1, 0)
		"+z":
			return Vector3i(0, 0, 1)
		"-z":
			return Vector3i(0, 0, -1)
		_:
			return Vector3i.ZERO

func start_overlay_path_from_cursor_if_empty() -> void:
	if selected_overlay_cells.is_empty():
		add_selected_overlay_cell(selected_internal_origin)

func extend_selected_overlay_path(direction_id: String) -> bool:
	var offset: Vector3i = get_overlay_direction_offset(direction_id)
	if offset == Vector3i.ZERO:
		return false
	start_overlay_path_from_cursor_if_empty()
	var start_cell: Vector3i = get_last_selected_overlay_cell()
	var next_cell: Vector3i = start_cell + offset
	if not is_internal_cell_in_bounds(next_cell):
		return false
	return add_selected_overlay_cell(next_cell)

func undo_selected_overlay_cell() -> bool:
	if selected_overlay_cells.is_empty():
		return false
	selected_overlay_cells.remove_at(selected_overlay_cells.size() - 1)
	return true

func get_selected_overlay_plan_short_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Cells: %d" % selected_overlay_cells.size())
	if selected_overlay_cells.is_empty():
		lines.append("- Start: cursor %s" % format_internal_cell(selected_internal_origin))
	else:
		lines.append("- Start: %s" % format_internal_cell(selected_overlay_cells[0]))
		lines.append("- Last: %s" % format_internal_cell(get_last_selected_overlay_cell()))
	lines.append("- Connectivity: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	if has_method("get_overlay_path_endpoint_count"):
		lines.append("- Endpoints: %d" % get_overlay_path_endpoint_count({
			"id": "planning",
			"module_id": get_selected_overlay_module_id(),
			"path_type": selected_overlay_path_type,
			"cells": selected_overlay_cells
		}))
	return "\n".join(lines)

func commit_selected_overlay_path() -> bool:
	if selected_overlay_cells.is_empty():
		return false

	var module_id: String = get_selected_overlay_module_id()
	var required_module: BipobModule = null
	var raw_index: int = -1
	for i in range(box_storage.size()):
		var module: BipobModule = box_storage[i]
		if module != null and module.id == module_id:
			required_module = module
			raw_index = i
			break
	if required_module == null or raw_index < 0:
		return false

	var copied_cells: Array[Vector3i] = []
	for cell in selected_overlay_cells:
		if is_internal_cell_in_bounds(cell):
			copied_cells.append(cell)
	if copied_cells.is_empty():
		return false

	var path_record: Dictionary = {
		"id": "overlay_%d" % next_internal_overlay_path_id,
		"module_id": module_id,
		"path_type": selected_overlay_path_type,
		"cells": copied_cells
	}
	next_internal_overlay_path_id += 1
	internal_overlay_paths.append(path_record)
	selected_overlay_path_index = internal_overlay_paths.size() - 1
	box_storage.remove_at(raw_index)
	clear_selected_overlay_cells()
	return true

func create_overlay_module_by_id(module_id: String) -> BipobModule:
	match module_id:
		"water_tube_v1":
			return create_internal_module("water_tube_v1", "Water Tube V1", Vector3i(1, 1, 1))
		"air_duct_v1":
			return create_internal_module("air_duct_v1", "Air Duct V1", Vector3i(1, 1, 1))
		_:
			return null

func remove_internal_overlay_path(path_id: String) -> bool:
	for i in range(internal_overlay_paths.size()):
		var record: Dictionary = internal_overlay_paths[i]
		var record_id: String = String(record.get("id", ""))
		if record_id != path_id:
			continue
		var module_id: String = String(record.get("module_id", ""))
		var returned_module: BipobModule = create_overlay_module_by_id(module_id)
		if returned_module != null:
			box_storage.append(returned_module)
		internal_overlay_paths.remove_at(i)
		return true
	return false

func get_internal_overlay_paths_at_cell(cell: Vector3i) -> Array[Dictionary]:
	var paths: Array[Dictionary] = []
	for path_record in internal_overlay_paths:
		var cells: Array = path_record.get("cells", [])
		for item in cells:
			var path_cell: Vector3i = item
			if path_cell == cell:
				paths.append(path_record)
				break
	return paths

func get_overlay_path_cells(path_record: Dictionary) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var raw_cells: Array = path_record.get("cells", [])
	for item in raw_cells:
		var cell: Vector3i = item
		if is_internal_cell_in_bounds(cell):
			result.append(cell)
	return result

func is_overlay_path_connected(path_record: Dictionary) -> bool:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	if cells.size() <= 1:
		return true
	var cell_keys: Dictionary = {}
	for cell in cells:
		cell_keys[get_internal_slot_key(cell)] = true
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []
	queue.append(cells[0])
	visited[get_internal_slot_key(cells[0])] = true
	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		for offset in get_internal_neighbor_offsets():
			var neighbor: Vector3i = current + offset
			var neighbor_key: String = get_internal_slot_key(neighbor)
			if not cell_keys.has(neighbor_key):
				continue
			if visited.has(neighbor_key):
				continue
			visited[neighbor_key] = true
			queue.append(neighbor)
	return visited.size() == cell_keys.size()

func get_overlay_path_component_count(path_record: Dictionary) -> int:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	if cells.is_empty():
		return 0
	var remaining: Dictionary = {}
	for cell in cells:
		remaining[get_internal_slot_key(cell)] = cell
	var component_count: int = 0
	while not remaining.is_empty():
		var keys: Array = remaining.keys()
		var start_key: String = String(keys[0])
		var start_cell: Vector3i = remaining[start_key]
		component_count += 1
		var queue: Array[Vector3i] = []
		queue.append(start_cell)
		remaining.erase(start_key)
		while not queue.is_empty():
			var current: Vector3i = queue.pop_front()
			for offset in get_internal_neighbor_offsets():
				var neighbor: Vector3i = current + offset
				var neighbor_key: String = get_internal_slot_key(neighbor)
				if not remaining.has(neighbor_key):
					continue
				var next_cell: Vector3i = remaining[neighbor_key]
				remaining.erase(neighbor_key)
				queue.append(next_cell)
	return component_count

func get_overlay_path_neighbor_count(path_record: Dictionary, cell: Vector3i) -> int:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var cell_keys: Dictionary = {}

	for path_cell in cells:
		cell_keys[get_internal_slot_key(path_cell)] = true

	var count: int = 0
	for offset in get_internal_neighbor_offsets():
		var neighbor: Vector3i = cell + offset
		var neighbor_key: String = get_internal_slot_key(neighbor)
		if cell_keys.has(neighbor_key):
			count += 1

	return count

func get_overlay_path_endpoint_cells(path_record: Dictionary) -> Array[Vector3i]:
	var endpoints: Array[Vector3i] = []
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)

	if cells.is_empty():
		return endpoints

	if cells.size() == 1:
		endpoints.append(cells[0])
		return endpoints

	for cell in cells:
		var neighbor_count: int = get_overlay_path_neighbor_count(path_record, cell)
		if neighbor_count == 1:
			endpoints.append(cell)

	return endpoints

func get_overlay_path_endpoint_count(path_record: Dictionary) -> int:
	return get_overlay_path_endpoint_cells(path_record).size()

func format_internal_cell(cell: Vector3i) -> String:
	return "%d,%d,%d" % [cell.x, cell.y, cell.z]

func get_overlay_path_endpoints_text(path_record: Dictionary) -> String:
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	if endpoints.is_empty():
		return "none"

	var parts: Array[String] = []
	for cell in endpoints:
		parts.append(format_internal_cell(cell))

	return ", ".join(parts)

func is_selected_overlay_plan_connected() -> bool:
	if selected_overlay_cells.size() <= 1:
		return true
	var path_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}
	return is_overlay_path_connected(path_record)

func get_selected_overlay_plan_component_count() -> int:
	var path_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}
	return get_overlay_path_component_count(path_record)

func get_overlay_path_connectivity_text(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var connected: bool = is_overlay_path_connected(path_record)
	var components: int = get_overlay_path_component_count(path_record)
	var status: String = "connected" if connected else "disconnected"
	return "%s %s cells:%d %s components:%d" % [path_id, path_type, cells.size(), status, components]

func get_overlay_connectivity_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Check")
	lines.append("Planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Cells: %d" % selected_overlay_cells.size())
	lines.append("- Status: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	lines.append("")
	lines.append("Committed paths:")
	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_connectivity_text(path_record))
	lines.append("")
	lines.append("Rules:")
	lines.append("- Connectivity uses 6-direction orthogonal neighbors.")
	lines.append("- Overlay can pass over occupied modules.")
	lines.append("- Disconnected paths are informational only.")
	return "\n".join(lines)

func get_overlay_connectivity_compact_text() -> String:
	var disconnected_count: int = 0
	for path_record in internal_overlay_paths:
		if not is_overlay_path_connected(path_record):
			disconnected_count += 1
	var planning_status: String = "connected" if is_selected_overlay_plan_connected() else "disconnected"
	return "Overlay connectivity: planning %s / disconnected paths %d" % [planning_status, disconnected_count]

func has_internal_overlay_at_cell(cell: Vector3i, path_type: String = "") -> bool:
	var paths: Array[Dictionary] = get_internal_overlay_paths_at_cell(cell)
	if path_type.is_empty():
		return not paths.is_empty()
	for record in paths:
		if String(record.get("path_type", "")) == path_type:
			return true
	return false

func is_cell_in_selected_overlay_path(cell: Vector3i) -> bool:
	var record: Dictionary = get_selected_overlay_path_record()
	if record.is_empty():
		return false

	var cells: Array = record.get("cells", [])
	for item in cells:
		var path_cell: Vector3i = item
		if path_cell == cell:
			return true

	return false

func get_selected_overlay_path_marker_for_cell(cell: Vector3i) -> String:
	if not is_cell_in_selected_overlay_path(cell):
		return ""

	var record: Dictionary = get_selected_overlay_path_record()
	var path_type: String = String(record.get("path_type", ""))

	if path_type == "liquid":
		return "q"

	if path_type == "duct":
		return "d"

	return "?"

func get_internal_overlay_marker_for_cell(cell: Vector3i) -> String:
	if has_selected_overlay_cell(cell):
		if selected_overlay_path_type == "duct":
			return "A"
		return "L"

	var selected_marker: String = get_selected_overlay_path_marker_for_cell(cell)
	if not selected_marker.is_empty():
		return selected_marker
	if has_internal_overlay_at_cell(cell, "liquid"):
		return "l"
	if has_internal_overlay_at_cell(cell, "duct"):
		return "a"
	return ""

func get_modules_touched_by_overlay_path(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if not is_internal_cell_in_bounds(cell):
			continue

		var module: BipobModule = get_internal_module_at_cell(cell)
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_modules_adjacent_to_overlay_path(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if not is_internal_cell_in_bounds(cell):
			continue

		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue

			var module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if module != null and not modules.has(module):
				modules.append(module)

	return modules

func does_overlay_path_reach_body_edge(path_record: Dictionary) -> bool:
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if is_internal_cell_on_body_edge(cell):
			return true

	return false

func does_overlay_path_endpoint_touch_body_edge(path_record: Dictionary) -> bool:
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		if is_internal_cell_on_body_edge(cell):
			return true

	return false

func get_modules_touched_by_overlay_endpoints(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		var module: BipobModule = get_internal_module_at_cell(cell)
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_modules_adjacent_to_overlay_endpoints(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		for offset in get_internal_neighbor_offsets():
			var neighbor: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor):
				continue

			var module: BipobModule = get_internal_module_at_cell(neighbor)
			if module != null and not modules.has(module):
				modules.append(module)

	return modules

func does_overlay_path_touch_cooler(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_cooler_module(module):
			return true

	return false

func does_overlay_path_touch_radiator(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_radiator_module(module):
			return true

	return false

func does_overlay_path_touch_radiator_next_to_cooler(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_radiator_module(module) and is_radiator_next_to_cooler(module):
			return true

	return false

func is_hot_internal_module(module: BipobModule) -> bool:
	if module == null:
		return false

	return get_module_preview_heat(module, false) >= 3

func does_overlay_path_touch_hot_module(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_hot_internal_module(module):
			return true

	return false

func does_overlay_path_endpoint_touch_hot_module(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_endpoints(path_record)

	for module in modules:
		if is_hot_internal_module(module):
			return true

	return false

func get_overlay_path_endpoint_suitability_text(path_record: Dictionary) -> String:
	var path_type: String = String(path_record.get("path_type", ""))
	var connected: bool = is_overlay_path_connected(path_record)
	var reaches_edge_endpoint: bool = does_overlay_path_endpoint_touch_body_edge(path_record)
	var touches_cooler: bool = does_overlay_path_touch_cooler(path_record)
	var touches_radiator: bool = does_overlay_path_touch_radiator(path_record)
	var touches_hot: bool = does_overlay_path_touch_hot_module(path_record)

	if path_type == "liquid":
		var has_cooling_source: bool = touches_cooler or touches_radiator
		var has_target: bool = touches_hot

		if connected and has_cooling_source and has_target:
			return "good: liquid path touches cooling source and hot module"
		if not connected:
			return "notice: liquid path is disconnected"
		if not has_cooling_source:
			return "notice: liquid path does not touch cooler/radiator"
		if not has_target:
			return "notice: liquid path does not touch hot module"
		return "ok"

	if path_type == "duct":
		if connected and reaches_edge_endpoint:
			return "good: duct has endpoint at body edge"
		if not connected:
			return "notice: duct path is disconnected"
		if not reaches_edge_endpoint:
			return "notice: duct endpoint does not reach body edge"
		return "ok"

	return "unknown path type"

func get_overlay_path_endpoint_line(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var endpoint_count: int = get_overlay_path_endpoint_count(path_record)
	var endpoint_text: String = get_overlay_path_endpoints_text(path_record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(path_record)

	return "%s %s cells:%d endpoints:%d [%s] %s" % [
		path_id,
		path_type,
		cells.size(),
		endpoint_count,
		endpoint_text,
		suitability
	]

func get_overlay_endpoint_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Endpoint Preview")

	var planning_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}

	lines.append("Planning:")
	lines.append("- " + get_overlay_path_endpoint_line(planning_record))
	lines.append("")
	lines.append("Committed paths:")

	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_endpoint_line(path_record))

	lines.append("")
	lines.append("Rules:")
	lines.append("- Endpoint = path cell with exactly 1 path neighbor.")
	lines.append("- Single-cell path has one endpoint.")
	lines.append("- Loop path has zero endpoints.")
	lines.append("- Liquid preview prefers cooling source + hot module.")
	lines.append("- Duct preview prefers endpoint on body edge.")
	lines.append("- Endpoint preview is informational only.")
	return "\n".join(lines)

func get_overlay_endpoint_compact_text() -> String:
	var selected_record: Dictionary = get_selected_overlay_path_record()

	if selected_record.is_empty():
		var planning_record: Dictionary = {
			"id": "planning",
			"module_id": get_selected_overlay_module_id(),
			"path_type": selected_overlay_path_type,
			"cells": selected_overlay_cells
		}
		var planning_endpoints: int = get_overlay_path_endpoint_count(planning_record)
		return "Overlay endpoints: planning %d" % planning_endpoints

	var endpoint_count: int = get_overlay_path_endpoint_count(selected_record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(selected_record)
	return "Overlay endpoints: %d — %s" % [endpoint_count, suitability]

func get_overlay_path_potential_cooling_value(path_record: Dictionary) -> int:
	var path_type: String = String(path_record.get("path_type", ""))

	if path_type == "liquid":
		if does_overlay_path_touch_radiator_next_to_cooler(path_record):
			return 5
		if does_overlay_path_touch_cooler(path_record):
			return 4
		if does_overlay_path_touch_radiator(path_record):
			return 3
		return 2

	if path_type == "duct":
		if does_overlay_path_reach_body_edge(path_record):
			return 1
		return 0

	return 0

func get_liquid_overlay_paths_touching_module(module: BipobModule) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if module == null:
		return result

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "liquid":
			continue

		var touched_modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
		if touched_modules.has(module):
			result.append(path_record)

	return result

func get_edge_duct_overlay_paths() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "duct":
			continue

		if does_overlay_path_reach_body_edge(path_record):
			result.append(path_record)

	return result

func get_duct_overlay_paths_touching_or_adjacent_to_module(module: BipobModule) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if module == null:
		return result

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "duct":
			continue

		var touched_modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
		var adjacent_modules: Array[BipobModule] = get_modules_adjacent_to_overlay_path(path_record)

		if touched_modules.has(module) or adjacent_modules.has(module):
			result.append(path_record)

	return result

func get_liquid_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	var strongest_value: int = 0

	for path_record in get_liquid_overlay_paths_touching_module(module):
		var value: int = get_overlay_path_potential_cooling_value(path_record)
		strongest_value = maxi(strongest_value, value)

	return strongest_value

func get_air_duct_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var strongest_value: int = 0

	for path_record in get_duct_overlay_paths_touching_or_adjacent_to_module(module):
		if not does_overlay_path_reach_body_edge(path_record):
			continue

		strongest_value = maxi(strongest_value, 1)

	return strongest_value

func get_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	var liquid_value: int = get_liquid_overlay_potential_cooling_for_module(module)
	var duct_value: int = get_air_duct_overlay_potential_cooling_for_module(module)

	return maxi(liquid_value, duct_value)

func get_hypothetical_heat_after_overlay_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var current_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_cooling: int = get_overlay_potential_cooling_for_module(module)

	return clampi(current_preview_heat - overlay_cooling, 0, THERMAL_CRITICAL_HEAT)

func get_overlay_thermal_contribution_line(module: BipobModule) -> String:
	if module == null:
		return ""

	var base_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var liquid_value: int = get_liquid_overlay_potential_cooling_for_module(module)
	var duct_value: int = get_air_duct_overlay_potential_cooling_for_module(module)
	var overlay_value: int = get_overlay_potential_cooling_for_module(module)
	var hypothetical_heat: int = get_hypothetical_heat_after_overlay_for_module(module)

	return "%s: base preview %d, overlay liquid -%d, duct -%d, strongest -%d, hypothetical %d" % [
		get_module_display_name(module),
		base_preview_heat,
		liquid_value,
		duct_value,
		overlay_value,
		hypothetical_heat
	]

func get_overlay_thermal_contribution_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Thermal Preview")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	var any_contribution: bool = false

	for module in modules:
		if module == null:
			continue

		var contribution: int = get_overlay_potential_cooling_for_module(module)
		if contribution <= 0:
			continue

		any_contribution = true
		lines.append("- " + get_overlay_thermal_contribution_line(module))

	if not any_contribution:
		lines.append("none")

	lines.append("")
	lines.append("Rules:")
	lines.append("- Overlay contribution is hypothetical only.")
	lines.append("- Base thermal heat map is not changed.")
	lines.append("- Strongest overlay contribution is used, not stacking.")
	lines.append("- Liquid path must touch module.")
	lines.append("- Duct path must touch/neighbor module and reach body edge.")
	lines.append("- " + get_overlay_thermal_contribution_diff_summary_text())

	return "\n".join(lines)


func get_overlay_thermal_contribution_diff_summary_text() -> String:
	var improved_count: int = 0
	var best_delta: int = 0

	for module in get_unique_internal_modules():
		if module == null:
			continue

		var base_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var hypothetical_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
		var delta: int = base_preview_heat - hypothetical_heat
		if delta > 0:
			improved_count += 1
			best_delta = maxi(best_delta, delta)

	return "Overlay Diff: changed %d / best -%d" % [
		improved_count,
		best_delta
	]

func get_overlay_thermal_contribution_compact_text() -> String:
	var affected_count: int = 0
	var highest_contribution: int = 0

	for module in get_unique_internal_modules():
		var contribution: int = get_overlay_potential_cooling_for_module(module)
		if contribution > 0:
			affected_count += 1
			highest_contribution = maxi(highest_contribution, contribution)

	return "Overlay Thermal: affected %d / max potential -%d | %s" % [
		affected_count,
		highest_contribution,
		get_overlay_thermal_contribution_diff_summary_text()
	]

func get_thermal_rules_reference_text() -> String:
	var lines: Array[String] = []

	lines.append("Thermal Rules Reference")
	lines.append("")
	lines.append("Heat scale:")
	lines.append("- 1 = low heat")
	lines.append("- 2 = moderate heat")
	lines.append("- 3 = hot")
	lines.append("- 4 = very hot")
	lines.append("- 5 = critical preview")
	lines.append("")
	lines.append("Device heat:")
	lines.append("- Base heat is constant (idle = active for v1 preview)")
	lines.append("- Batteries: V1=1, V2=2, V3=3")
	lines.append("- Processor/GPU: V1=3, V2=4, V3=5")
	lines.append("- Memory: V1=1, V2=2, V3=3")
	lines.append("- Hard Drive: V1=2, V2=3, V3=4")
	lines.append("- Power Block: V1=1, V2=2, V3=3")
	lines.append("- Internal/External Interface: V1=1, V2=2, V3=3")
	lines.append("")
	lines.append("Neighbor doheat:")
	lines.append("- Calculated after cooling from cooled own heat")
	lines.append("- If source cooled heat - target cooled heat >= 2: target +1")
	lines.append("- Max +1, no stacking, no chain reaction")
	lines.append("- Target with any direct cooling does not receive doheat")
	lines.append("")
	lines.append("Direct cooling:")
	lines.append("- Cooler base output 2, requires Air Intake")
	lines.append("- Radiator base output 1; against body edge output 2")
	lines.append("- Radiator + working Cooler output 3 each")
	lines.append("- Cooler + edge Radiator output 5 each")
	lines.append("")
	lines.append("Overlay paths:")
	lines.append("- Water Tube does not consume internal volume")
	lines.append("- Water Tube base potential cooling: 2")
	lines.append("- Water Tube through Cooler: 4")
	lines.append("- Water Tube through Radiator: 3")
	lines.append("- Water Tube through Radiator near Cooler: 5")
	lines.append("- Air Duct does not consume internal volume")
	lines.append("- Air Duct requires Air Intake + working Cooler")
	lines.append("")
	lines.append("Air intake:")
	lines.append("- Air cooling requires Air Intake Node on external body")
	lines.append("- Liquid cooling does not require Air Intake Node")
	lines.append("")
	lines.append("Current implementation:")
	lines.append("- Broken modules provide no stats/heat/cooling")
	lines.append("- Base thermal preview is informational")
	lines.append("- Overlay contribution is hypothetical only")
	lines.append("- Thermal+Overlay view does not affect gameplay")
	lines.append("- No device damage or repair is implemented yet")
	lines.append("- No Test Build is implemented yet")

	return "\n".join(lines)

func get_thermal_rules_compact_text() -> String:
	return "Thermal Rules: heat 1-5, critical 5, overlay hypothetical"

func get_overlay_path_effect_line(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array = path_record.get("cells", [])

	var touched: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
	var adjacent: Array[BipobModule] = get_modules_adjacent_to_overlay_path(path_record)
	var reaches_edge: bool = does_overlay_path_reach_body_edge(path_record)
	var potential_value: int = get_overlay_path_potential_cooling_value(path_record)

	var touched_names: Array[String] = []
	for module in touched:
		touched_names.append(get_module_display_name(module))

	var adjacent_names: Array[String] = []
	for module in adjacent:
		if not touched.has(module):
			adjacent_names.append(get_module_display_name(module))

	var touched_text: String = "none" if touched_names.is_empty() else ", ".join(touched_names)
	var adjacent_text: String = "none" if adjacent_names.is_empty() else ", ".join(adjacent_names)
	var edge_text: String = "yes" if reaches_edge else "no"

	if path_type == "liquid":
		return "%s liquid cells:%d potential:%d touched:%s adjacent:%s" % [
			path_id,
			cells.size(),
			potential_value,
			touched_text,
			adjacent_text
		]

	if path_type == "duct":
		return "%s duct cells:%d edge:%s support:%d touched:%s adjacent:%s" % [
			path_id,
			cells.size(),
			edge_text,
			potential_value,
			touched_text,
			adjacent_text
		]

	return "%s %s cells:%d touched:%s adjacent:%s" % [
		path_id,
		path_type,
		cells.size(),
		touched_text,
		adjacent_text
	]

func get_overlay_effect_preview_text() -> String:
	var lines: Array[String] = []

	lines.append("Overlay effect preview:")

	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_effect_line(path_record))

	lines.append("")
	lines.append("Rules preview:")
	lines.append("- Water Tube base potential cooling: 2")
	lines.append("- Water Tube through Cooler: 4")
	lines.append("- Water Tube through Radiator: 3")
	lines.append("- Water Tube through Radiator near Cooler: 5")
	lines.append("- Air Duct reaching body edge can support air routing")
	lines.append("- Overlay effects are not applied to thermal calculation yet")

	return "\n".join(lines)

func get_overlay_effect_compact_text() -> String:
	var liquid_count: int = 0
	var duct_count: int = 0
	var edge_duct_count: int = 0

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type == "liquid":
			liquid_count += 1
		elif path_type == "duct":
			duct_count += 1
			if does_overlay_path_reach_body_edge(path_record):
				edge_duct_count += 1

	return "Overlay effects: liquid %d / duct %d / edge ducts %d" % [
		liquid_count,
		duct_count,
		edge_duct_count
	]

func get_internal_overlay_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay paths:")
	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for record in internal_overlay_paths:
			var path_id: String = String(record.get("id", ""))
			var module_id: String = String(record.get("module_id", ""))
			var path_type: String = String(record.get("path_type", ""))
			var cells: Array = record.get("cells", [])
			lines.append("- %s %s cells:%d module:%s" % [path_id, path_type, cells.size(), module_id])
	lines.append("")
	lines.append("Planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Selected cells: %d" % selected_overlay_cells.size())
	lines.append("- Uses module: %s" % get_selected_overlay_module_id())
	lines.append("- Connectivity: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	lines.append("- Overlay can pass over occupied modules.")
	lines.append("- Route cooling is not applied yet.")
	lines.append("- Disconnected paths are informational only.")
	return "\n".join(lines)

func get_selected_overlay_path_details_text() -> String:
	var record: Dictionary = get_selected_overlay_path_record()

	if record.is_empty():
		return "Selected overlay:\nnone"

	var path_id: String = String(record.get("id", ""))
	var module_id: String = String(record.get("module_id", ""))
	var path_type: String = String(record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(record)
	var connected: bool = is_overlay_path_connected(record)
	var components: int = get_overlay_path_component_count(record)
	var reaches_edge: bool = does_overlay_path_reach_body_edge(record)
	var potential_value: int = get_overlay_path_potential_cooling_value(record)
	var endpoint_count: int = get_overlay_path_endpoint_count(record)
	var endpoint_text: String = get_overlay_path_endpoints_text(record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(record)

	var edge_text: String = "yes" if reaches_edge else "no"
	var connected_text: String = "yes" if connected else "no"

	var lines: Array[String] = []
	lines.append("Selected overlay:")
	lines.append("- ID: %s" % path_id)
	lines.append("- Type: %s" % path_type)
	lines.append("- Module: %s" % module_id)
	lines.append("- Cells: %d" % cells.size())
	lines.append("- Connected: %s" % connected_text)
	lines.append("- Components: %d" % components)
	lines.append("- Reaches body edge: %s" % edge_text)
	lines.append("- Potential value: %d" % potential_value)
	lines.append("- Endpoints: %d" % endpoint_count)
	lines.append("- Endpoint cells: %s" % endpoint_text)
	lines.append("- Suitability: %s" % suitability)
	lines.append("- Preview only: yes")

	return "\n".join(lines)

func get_internal_module_at_cell(cell: Vector3i) -> BipobModule:
	var key := get_internal_slot_key(cell)
	if internal_modules_by_cell.has(key):
		return internal_modules_by_cell[key]
	return null

func get_internal_module_base_size(module: BipobModule) -> Vector3i:
	if module == null:
		return Vector3i.ONE
	return Vector3i(maxi(module.size_x, 1), maxi(module.size_y, 1), maxi(module.size_z, 1))

func get_rotated_internal_size(module: BipobModule, rotation_index: int) -> Vector3i:
	var base_size := get_internal_module_base_size(module)
	match posmod(rotation_index, 3):
		1:
			return Vector3i(base_size.z, base_size.y, base_size.x)
		2:
			return Vector3i(base_size.x, base_size.z, base_size.y)
		_:
			return base_size

func get_internal_module_covered_cells(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var module_size := get_rotated_internal_size(module, rotation_index)
	for z in range(module_size.z):
		for y in range(module_size.y):
			for x in range(module_size.x):
				cells.append(origin + Vector3i(x, y, z))
	return cells

func get_internal_module_placement_error(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> String:
	if module == null:
		return "No internal module selected."
	if module.placement_type != "internal":
		return "Module is not internal."
	for cell in get_internal_module_covered_cells(module, origin, rotation_index):
		if not is_internal_cell_in_bounds(cell):
			return "Internal module footprint is outside robot volume."
		if get_internal_module_at_cell(cell) != null:
			return "Internal cells are occupied."
	return ""

func can_place_internal_module(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> bool:
	return get_internal_module_placement_error(module, origin, rotation_index).is_empty()

func place_internal_module(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> bool:
	if not can_place_internal_module(module, origin, rotation_index):
		hint_requested.emit("Cannot place internal module here.")
		status_changed.emit()
		return false
	var rotated_size := get_rotated_internal_size(module, rotation_index)
	var record := {
		"module": module,
		"origin": origin,
		"size": rotated_size,
		"rotation": posmod(rotation_index, 3),
	}
	placed_internal_modules.append(record)
	for cell in get_internal_module_covered_cells(module, origin, rotation_index):
		internal_modules_by_cell[get_internal_slot_key(cell)] = module
	var storage_index := box_storage.find(module)
	if storage_index != -1:
		box_storage.remove_at(storage_index)
	hint_requested.emit("Internal module installed: %s" % get_module_display_name(module))
	status_changed.emit()
	return true

func find_internal_module_record_at_cell(cell: Vector3i) -> int:
	for index in range(placed_internal_modules.size()):
		var record: Dictionary = placed_internal_modules[index]
		var record_module: BipobModule = record.get("module", null)
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		if get_internal_module_covered_cells(record_module, origin, rotation_index).has(cell):
			return index
	return -1

func remove_internal_module(cell: Vector3i) -> bool:
	if not is_internal_cell_in_bounds(cell):
		hint_requested.emit("Internal cell is out of bounds.")
		status_changed.emit()
		return false
	var record: Dictionary = get_internal_module_record_at(cell)
	if record.is_empty():
		hint_requested.emit("No internal module at selected cell.")
		status_changed.emit()
		return false
	var module: BipobModule = record.get("module", null)
	if module != null and (bool(module.is_builtin) or not bool(module.is_removable)):
		hint_requested.emit("Built-in module cannot be removed.")
		status_changed.emit()
		return false
	remove_internal_module_record(record)
	if module != null and not box_storage.has(module):
		box_storage.append(module)
	hint_requested.emit("Internal module removed to Box: %s" % get_module_display_name(module))
	status_changed.emit()
	return true

func get_internal_module_record_at(cell: Vector3i) -> Dictionary:
	for record_variant in placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var module: BipobModule = record.get("module", null)
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		if get_internal_module_covered_cells(module, origin, rotation_index).has(cell):
			return record
	return {}

func remove_internal_module_record(record: Dictionary) -> bool:
	if record.is_empty():
		return false
	var module: BipobModule = record.get("module", null)
	var origin: Vector3i = record.get("origin", Vector3i.ZERO)
	var rotation_index: int = int(record.get("rotation", 0))
	for covered_cell in get_internal_module_covered_cells(module, origin, rotation_index):
		internal_modules_by_cell.erase(get_internal_slot_key(covered_cell))
	for index in range(placed_internal_modules.size() - 1, -1, -1):
		if placed_internal_modules[index] == record:
			placed_internal_modules.remove_at(index)
			return true
	for index in range(placed_internal_modules.size() - 1, -1, -1):
		var placed_record: Dictionary = placed_internal_modules[index]
		if placed_record.get("module", null) == module and placed_record.get("origin", Vector3i.ZERO) == origin and int(placed_record.get("rotation", 0)) == rotation_index:
			placed_internal_modules.remove_at(index)
			return true
	return true

func clear_internal_plan_to_storage() -> int:
	var returned_count: int = 0
	var modules_to_return: Array[BipobModule] = []

	for record_variant in placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var module: BipobModule = record.get("module", null)
		if module != null and not modules_to_return.has(module):
			modules_to_return.append(module)

	if modules_to_return.is_empty():
		for key in internal_modules_by_cell.keys():
			var module: BipobModule = internal_modules_by_cell.get(key, null)
			if module != null and not modules_to_return.has(module):
				modules_to_return.append(module)

	for module in modules_to_return:
		if module != null:
			box_storage.append(module)
			returned_count += 1

	internal_modules_by_cell.clear()
	placed_internal_modules.clear()
	clear_selected_overlay_cells()

	status_changed.emit()
	return returned_count


func get_cells_for_internal_module(module: BipobModule) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if module == null:
		return cells

	for record_variant in placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var record_module: BipobModule = record.get("module", null)
		if record_module != module:
			continue
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		for covered_cell in get_internal_module_covered_cells(module, origin, rotation_index):
			if not cells.has(covered_cell):
				cells.append(covered_cell)

	if not cells.is_empty():
		return cells

	for key_variant in internal_modules_by_cell.keys():
		var key := String(key_variant)
		var cell_module: BipobModule = internal_modules_by_cell.get(key, null)
		if cell_module != module:
			continue
		var parts := key.split(":")
		if parts.size() != 3:
			continue
		var cell := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		if not cells.has(cell):
			cells.append(cell)

	return cells

func get_internal_neighbor_offsets() -> Array[Vector3i]:
	return [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]

func get_module_preview_heat(module: BipobModule, active_mode: bool = false) -> int:
	if not is_module_functional(module):
		return 0
	var heat_value: int = module.heat_active if active_mode else module.heat_idle
	return clampi(heat_value, 0, THERMAL_CRITICAL_HEAT)

func get_preview_heat_for_internal_module(module: BipobModule) -> int:
	return get_module_preview_heat(module, false)

func is_internal_module_against_body(module: BipobModule) -> bool:
	if module == null:
		return false
	var volume_size: Vector3i = get_internal_volume_size()
	var cells: Array[Vector3i] = get_cells_for_internal_module(module)
	for cell in cells:
		if cell.x == 0 or cell.y == 0 or cell.z == 0:
			return true
		if cell.x == volume_size.x - 1 or cell.y == volume_size.y - 1 or cell.z == volume_size.z - 1:
			return true
	return false

func is_cooler_module(module: BipobModule) -> bool:
	return is_module_functional(module) and module.id == "cooler_v1"

func is_radiator_module(module: BipobModule) -> bool:
	return is_module_functional(module) and module.id == "radiator_v1"

func is_radiator_next_to_cooler(radiator_module: BipobModule) -> bool:
	if not is_radiator_module(radiator_module):
		return false
	var cells: Array[Vector3i] = get_cells_for_internal_module(radiator_module)
	for cell in cells:
		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue
			var neighbor_module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if is_cooler_module(neighbor_module):
				return true
	return false

func get_cooling_power_for_internal_module(cooling_module: BipobModule) -> int:
	if not is_module_functional(cooling_module):
		return 0
	var cooler_active: bool = has_external_air_intake()
	if is_cooler_module(cooling_module):
		if not cooler_active:
			return 0
		var cooler_boost := 2
		var cells := get_cells_for_internal_module(cooling_module)
		for cell in cells:
			for offset in get_internal_neighbor_offsets():
				var neighbor := get_internal_module_at_cell(cell + offset)
				if is_radiator_module(neighbor):
					cooler_boost = maxi(cooler_boost, 3)
					if is_internal_module_against_body(neighbor):
						cooler_boost = 5
		return cooler_boost
	if is_radiator_module(cooling_module):
		var output := 1
		if is_internal_module_against_body(cooling_module):
			output = 2
		if cooler_active and is_radiator_next_to_cooler(cooling_module):
			output = 3
			if is_internal_module_against_body(cooling_module):
				output = 5
		return output
	return max(0, cooling_module.cooling_power)

func get_internal_module_heat_breakdown(module: BipobModule, context: Dictionary = {}) -> Dictionary:
	var base_heat := get_module_preview_heat(module, false)
	var direct_cooling := get_cooling_received_by_internal_module(module)
	var cooled_heat := maxi(base_heat - direct_cooling, 0)
	var neighbor_doheat := 0
	if module != null and direct_cooling == 0:
		for cell in get_cells_for_internal_module(module):
			for offset in get_internal_neighbor_offsets():
				var neighbor: BipobModule = get_internal_module_at_cell(cell + offset)
				if neighbor == null or neighbor == module or not is_module_functional(neighbor):
					continue
				var neighbor_cooled := maxi(get_module_preview_heat(neighbor, false) - get_cooling_received_by_internal_module(neighbor), 0)
				if neighbor_cooled - cooled_heat >= 2:
					neighbor_doheat = 1
					break
			if neighbor_doheat > 0:
				break
	var temporary_heat := int(context.get("global_temporary_heat", 0))
	if module != null:
		var by_id: Dictionary = context.get("temporary_heat_by_module_id", {})
		temporary_heat += int(by_id.get(module.id, 0))
		var by_role: Dictionary = context.get("temporary_heat_by_role", {})
		temporary_heat += int(by_role.get(module.internal_role, 0))
	var final_heat := cooled_heat + neighbor_doheat + temporary_heat
	return {
		"module_id": "" if module == null else module.id,
		"display_name": get_module_display_name(module),
		"base_heat": base_heat,
		"direct_cooling": direct_cooling,
		"cooled_heat": cooled_heat,
		"neighbor_doheat": neighbor_doheat,
		"temporary_heat": temporary_heat,
		"final_heat": final_heat,
		"threshold": THERMAL_CRITICAL_HEAT,
		"receives_cooling": direct_cooling > 0,
		"would_overheat": final_heat >= THERMAL_CRITICAL_HEAT,
		"is_broken": is_module_broken(module),
	}

func get_cooling_received_by_internal_module(module: BipobModule) -> int:
	if module == null:
		return 0
	var strongest_cooling: int = 0
	var own_cells: Array[Vector3i] = get_cells_for_internal_module(module)
	for cell in own_cells:
		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue
			var neighbor_module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if neighbor_module == null or neighbor_module == module:
				continue
			if is_cooling_module(neighbor_module):
				strongest_cooling = maxi(strongest_cooling, get_cooling_power_for_internal_module(neighbor_module))
	return strongest_cooling

func get_preview_heat_after_cooling_for_internal_module(module: BipobModule) -> int:
	return int(get_internal_module_heat_breakdown(module).get("final_heat", 0))

func get_internal_module_thermal_line(module: BipobModule) -> String:
	if module == null:
		return ""
	var breakdown := get_internal_module_heat_breakdown(module)
	return "%s: base %d, cooling -%d, cooled %d, neighbor +%d, final %d / %d" % [breakdown.display_name, breakdown.base_heat, breakdown.direct_cooling, breakdown.cooled_heat, breakdown.neighbor_doheat, breakdown.final_heat, breakdown.threshold]

func get_internal_thermal_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Thermal preview:")
	lines.append("Critical heat: %d" % THERMAL_CRITICAL_HEAT)
	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)
	for module in modules:
		if module == null:
			continue
		lines.append("- " + get_internal_module_thermal_line(module))
	lines.append("")
	lines.append("Rules:")
	lines.append("- base heat is constant and does not accumulate")
	lines.append("- cooling applies before temporary heat")
	lines.append("- neighbor doheat is max +1 and has no chain")
	lines.append("- modules receiving cooling do not receive neighbor doheat")
	lines.append("- broken modules provide no stats/heat/cooling")
	lines.append("- critical heat 5 is informational for now")
	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		lines.append("")
		lines.append("Warning: Air cooling requires Air Intake Node on external body.")
	return "\n".join(lines)

func get_internal_action_temporary_heat_context(action_id: String) -> Dictionary:
	match action_id:
		"hack":
			return {"temporary_heat_by_role": {"processor": 2}, "temporary_heat_by_module_id": {}, "global_temporary_heat": 0, "source": action_id, "overheat_scope": "affected"}
		"xray", "thermal_scan":
			return {"temporary_heat_by_role": {"gpu": 2}, "temporary_heat_by_module_id": {}, "global_temporary_heat": 0, "source": action_id, "overheat_scope": "affected"}
		_:
			return {"temporary_heat_by_role": {}, "temporary_heat_by_module_id": {}, "global_temporary_heat": 0, "source": action_id, "overheat_scope": "affected"}

func get_internal_action_overheat_warnings(action_id: String) -> Array[String]:
	var context := get_internal_action_temporary_heat_context(action_id)
	var warnings: Array[String] = []
	var action_name := "action"
	if action_id == "hack":
		action_name = "hack"
	elif action_id == "xray":
		action_name = "X-Ray"
	elif action_id == "thermal_scan":
		action_name = "Thermal Scan"
	for module in get_unique_internal_modules():
		var breakdown := get_internal_module_heat_breakdown(module, context)
		if bool(breakdown.get("would_overheat", false)):
			warnings.append("%s may overheat during %s." % [String(breakdown.get("display_name", "Module")), action_name])
	return warnings

func break_internal_module(module: BipobModule, reason: String = "") -> bool:
	if module == null or is_module_broken(module):
		return false
	set_module_broken(module, true)
	recalculate_module_stats()
	if not reason.is_empty():
		print("Internal module broken | ", get_module_display_name(module), " | reason: ", reason)
	status_changed.emit()
	return true

func get_internal_modules_affected_by_heat_context(context: Dictionary) -> Array[BipobModule]:
	var affected_modules: Array[BipobModule] = []
	var overheat_scope := String(context.get("overheat_scope", ""))
	var global_temporary_heat := int(context.get("global_temporary_heat", 0))
	var temporary_heat_by_module_id: Dictionary = context.get("temporary_heat_by_module_id", {})
	var temporary_heat_by_role: Dictionary = context.get("temporary_heat_by_role", {})
	var include_all := overheat_scope == "all_critical" or global_temporary_heat > 0
	for module in get_unique_internal_modules():
		if module == null or not is_module_functional(module):
			continue
		if include_all:
			affected_modules.append(module)
			continue
		if temporary_heat_by_module_id.has(module.id):
			affected_modules.append(module)
			continue
		if temporary_heat_by_role.has(module.internal_role):
			affected_modules.append(module)
	return affected_modules

func apply_internal_overheat_if_needed(action_id: String, context: Dictionary = {}) -> Dictionary:
	var result := {
		"overheated": false,
		"failed": false,
		"broken_modules": [],
		"messages": [],
		"action_id": action_id
	}
	# Action temporary heat exists only for this attempted action.
	# Default scope is "affected": only modules that receive temporary heat can break.
	# "all_critical" is explicit for global/weapon heat style processing.
	var working_context: Dictionary = context if not context.is_empty() else get_internal_action_temporary_heat_context(action_id)
	var overheat_scope := String(working_context.get("overheat_scope", ""))
	if overheat_scope.is_empty():
		overheat_scope = "affected"
		working_context["overheat_scope"] = overheat_scope
	var action_name := "action"
	match action_id:
		"hack":
			action_name = "hack"
		"xray":
			action_name = "X-Ray"
		"thermal_scan":
			action_name = "Thermal Scan"
	for module in get_internal_modules_affected_by_heat_context(working_context):
		var breakdown := get_internal_module_heat_breakdown(module, working_context)
		var final_heat := int(breakdown.get("final_heat", 0))
		if final_heat < THERMAL_CRITICAL_HEAT:
			continue
		if break_internal_module(module, "overheat during %s" % action_id):
			result["overheated"] = true
			result["failed"] = true
			result["broken_modules"].append(module)
			var module_name := String(breakdown.get("display_name", get_module_display_name(module)))
			var message := "%s overheated and broke during %s." % [module_name, action_name]
			if action_id.is_empty():
				message = "Internal module overheated: %s." % module_name
			result["messages"].append(message)
	if result["messages"].is_empty() and bool(result["overheated"]):
		for broken_module in result["broken_modules"]:
			result["messages"].append("Internal module overheated: %s." % get_module_display_name(broken_module))
	last_internal_overheat_messages = result["messages"].duplicate()
	return result

func get_internal_overheat_debug_summary_text() -> String:
	var lines: Array[String] = []
	var broken_count := 0
	var highest_final_heat := 0
	for module in get_unique_internal_modules():
		if is_module_broken(module):
			broken_count += 1
		highest_final_heat = maxi(highest_final_heat, int(get_internal_module_heat_breakdown(module).get("final_heat", 0)))
	lines.append("Internal overheat debug:")
	lines.append("Broken modules: %d" % broken_count)
	lines.append("Highest current final heat: %d" % highest_final_heat)
	lines.append("Action overheat scope default: affected")
	lines.append("Action overheat scope override: all_critical")
	lines.append("Warn(hack): %d" % get_internal_action_overheat_warnings("hack").size())
	lines.append("Warn(X-Ray): %d" % get_internal_action_overheat_warnings("xray").size())
	lines.append("Warn(Thermal): %d" % get_internal_action_overheat_warnings("thermal_scan").size())
	if last_internal_overheat_messages.is_empty():
		lines.append("Last overheat: none")
	else:
		for msg in last_internal_overheat_messages:
			lines.append("- %s" % String(msg))
	return "\n".join(lines)

func get_internal_heat_debug_summary_text() -> String:
	var lines: Array[String] = []
	var highest := 0
	var warning_count := 0
	var critical_count := 0
	lines.append("Internal heat debug:")
	lines.append("Air Intake: %s" % get_air_intake_readiness_word())
	for module in get_unique_internal_modules():
		var breakdown := get_internal_module_heat_breakdown(module)
		var final_heat := int(breakdown.get("final_heat", 0))
		highest = maxi(highest, final_heat)
		if final_heat >= 4:
			warning_count += 1
		if final_heat >= THERMAL_CRITICAL_HEAT:
			critical_count += 1
		lines.append("- " + get_internal_module_thermal_line(module))
	lines.append("Highest final heat: %d" % highest)
	lines.append("Heat >= 4: %d" % warning_count)
	lines.append("Heat >= 5: %d" % critical_count)
	return "\n".join(lines)

func get_highest_internal_preview_heat() -> int:
	var highest_heat: int = 0
	for module in get_unique_internal_modules():
		highest_heat = maxi(highest_heat, get_preview_heat_after_cooling_for_internal_module(module))
	return highest_heat

func get_critical_internal_preview_count() -> int:
	var count: int = 0
	for module in get_unique_internal_modules():
		if get_preview_heat_after_cooling_for_internal_module(module) >= THERMAL_CRITICAL_HEAT:
			count += 1
	return count

func get_unique_internal_modules() -> Array[BipobModule]:
	var unique_modules: Array[BipobModule] = []
	for record in placed_internal_modules:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var module: BipobModule = record.get("module", null)
		if module == null:
			continue
		if unique_modules.has(module):
			continue
		unique_modules.append(module)
	return unique_modules

func get_unique_external_modules() -> Array[BipobModule]:
	var unique_modules: Array[BipobModule] = []
	for module_variant in external_modules_by_slot.values():
		if module_variant == null:
			continue
		var module: BipobModule = module_variant
		if unique_modules.has(module):
			continue
		unique_modules.append(module)
	return unique_modules

func get_all_constructor_modules() -> Array[BipobModule]:
	var modules: Array[BipobModule] = []

	for module in box_storage:
		if module != null and not modules.has(module):
			modules.append(module)

	for module in get_unique_external_modules():
		if module != null and not modules.has(module):
			modules.append(module)

	for module in get_unique_internal_modules():
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_allowed_constructor_placement_types() -> Array[String]:
	return ["internal", "external", "none"]

func get_allowed_constructor_categories() -> Array[String]:
	return [
		"external",
		"internal",
		"power",
		"cooling",
		"data",
		"locomotion",
		"vision",
		"storage",
		"utility"
	]

func get_allowed_cooling_types() -> Array[String]:
	return ["none", "air", "passive", "liquid", "duct"]

func get_allowed_repair_categories() -> Array[String]:
	return ["standard", "electronics", "power", "cooling", "mechanical", "interface"]

func get_repair_category_display_name(category_id: String) -> String:
	match category_id:
		"standard":
			return "Standard"
		"electronics":
			return "Electronics"
		"power":
			return "Power"
		"cooling":
			return "Cooling"
		"mechanical":
			return "Mechanical"
		"interface":
			return "Interface"
		_:
			return category_id

func get_module_damage_threshold(module: BipobModule) -> int:
	if module == null:
		return 5
	return clampi(module.damage_threshold_heat, 1, 5)

func get_module_repair_metadata_text(module: BipobModule) -> String:
	if module == null:
		return "Repair: none"
	if not module.can_be_damaged:
		return "Repair: not damageable"
	return "Repair: threshold heat %d / complexity %d / category %s" % [
		get_module_damage_threshold(module),
		module.repair_complexity,
		get_repair_category_display_name(module.repair_category)
	]

func get_module_damage_risk_preview_text(module: BipobModule) -> String:
	if module == null:
		return "Damage risk: none"
	if not module.can_be_damaged:
		return "Damage risk: not damageable"
	var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var threshold: int = get_module_damage_threshold(module)
	if preview_heat >= threshold:
		return "Damage risk: critical preview"
	if preview_heat == threshold - 1:
		return "Damage risk: warning preview"
	return "Damage risk: low preview"

func get_module_overlay_damage_risk_preview_text(module: BipobModule) -> String:
	if module == null:
		return "Overlay damage risk: none"
	if not module.can_be_damaged:
		return "Overlay damage risk: not damageable"
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
	var threshold: int = get_module_damage_threshold(module)
	if overlay_heat >= threshold:
		return "Overlay damage risk: critical preview"
	if overlay_heat == threshold - 1:
		return "Overlay damage risk: warning preview"
	return "Overlay damage risk: low preview"

func get_constructor_consistency_issue_lines() -> Array[String]:
	var issues: Array[String] = []
	var modules: Array[BipobModule] = get_all_constructor_modules()

	for module in modules:
		if module == null:
			continue

		var module_label: String = get_module_display_name(module)
		if module_label.is_empty():
			module_label = "<unnamed>"

		var module_id: String = module.id
		if module_id.is_empty():
			issues.append("%s has missing id." % module_label)

		if module.display_name.is_empty():
			issues.append("%s has missing display_name." % module_id)

		if module.placement_type.is_empty():
			issues.append("%s has missing placement_type." % module_label)
		elif not get_allowed_constructor_placement_types().has(module.placement_type):
			issues.append("%s has unknown placement_type: %s." % [module_label, module.placement_type])

		var category: String = get_module_category(module)
		if category.is_empty():
			issues.append("%s has missing category." % module_label)
		elif not get_allowed_constructor_categories().has(category):
			issues.append("%s has unknown category: %s." % [module_label, category])

		if module.placement_type == "internal":
			if module.internal_role.is_empty():
				issues.append("%s is internal but has no internal_role." % module_label)
			elif module.internal_role == "none" and not is_internal_overlay_module(module):
				issues.append("%s is internal but has no internal_role." % module_label)

			var internal_size: Vector3i = get_internal_module_base_size(module)
			if internal_size.x <= 0 or internal_size.y <= 0 or internal_size.z <= 0:
				issues.append("%s has invalid internal size: %s." % [module_label, str(internal_size)])

		if module.placement_type == "external":
			var footprint_size: Vector2i = get_external_module_size(module)
			if footprint_size.x <= 0 or footprint_size.y <= 0:
				issues.append("%s has invalid external footprint: %s." % [module_label, str(footprint_size)])

		if not get_allowed_cooling_types().has(module.cooling_type):
			issues.append("%s has unknown cooling_type: %s." % [module_label, module.cooling_type])

		if module.heat_idle < 0 or module.heat_idle > 5:
			issues.append("%s has heat_idle outside 0..5: %d." % [module_label, module.heat_idle])

		if module.heat_active < 0 or module.heat_active > 5:
			issues.append("%s has heat_active outside 0..5: %d." % [module_label, module.heat_active])

		if module.heat_active < module.heat_idle:
			issues.append("%s has heat_active lower than heat_idle." % module_label)

		if module.internal_role == "cooling":
			if module.id != "air_duct_v1" and module.id != "air_intake_v1":
				if module.cooling_power <= 0:
					issues.append("%s is cooling module but has cooling_power <= 0." % module_label)

		if module.requires_air_intake:
			if module.cooling_type != "air" and module.cooling_type != "duct":
				issues.append("%s requires air intake but cooling_type is %s." % [module_label, module.cooling_type])

		if module.damage_threshold_heat < 1 or module.damage_threshold_heat > 5:
			issues.append("%s has damage_threshold_heat outside 1..5: %d." % [module_label, module.damage_threshold_heat])

		if module.repair_complexity < 0:
			issues.append("%s has repair_complexity < 0: %d." % [module_label, module.repair_complexity])

		if not get_allowed_repair_categories().has(module.repair_category):
			issues.append("%s has unknown repair_category: %s." % [module_label, module.repair_category])

		if module.can_be_damaged and module.damage_threshold_heat <= 0:
			issues.append("%s can be damaged but damage_threshold_heat <= 0." % module_label)

		if module.can_be_damaged and module.repair_complexity <= 0:
			issues.append("%s can be damaged but repair_complexity <= 0." % module_label)

	_append_duplicate_constructor_metadata_issues(issues, modules)
	return issues

func _append_duplicate_constructor_metadata_issues(issues: Array[String], modules: Array[BipobModule]) -> void:
	var first_by_id: Dictionary = {}
	for module in modules:
		if module == null:
			continue
		var module_id: String = module.id
		if module_id.is_empty():
			continue
		if not first_by_id.has(module_id):
			first_by_id[module_id] = module
			continue
		var first_module: BipobModule = first_by_id[module_id]
		_compare_constructor_metadata_field(issues, module_id, "display_name", first_module.display_name, module.display_name)
		_compare_constructor_metadata_field(issues, module_id, "placement_type", first_module.placement_type, module.placement_type)
		_compare_constructor_metadata_field(issues, module_id, "category", get_module_category(first_module), get_module_category(module))
		_compare_constructor_metadata_field(issues, module_id, "internal_role", first_module.internal_role, module.internal_role)
		_compare_constructor_metadata_field(issues, module_id, "heat_idle", str(first_module.heat_idle), str(module.heat_idle))
		_compare_constructor_metadata_field(issues, module_id, "heat_active", str(first_module.heat_active), str(module.heat_active))
		_compare_constructor_metadata_field(issues, module_id, "cooling_type", first_module.cooling_type, module.cooling_type)
		_compare_constructor_metadata_field(issues, module_id, "cooling_power", str(first_module.cooling_power), str(module.cooling_power))
		_compare_constructor_metadata_field(issues, module_id, "requires_air_intake", str(first_module.requires_air_intake), str(module.requires_air_intake))
		_compare_constructor_metadata_field(issues, module_id, "can_be_damaged", str(first_module.can_be_damaged), str(module.can_be_damaged))
		_compare_constructor_metadata_field(issues, module_id, "damage_threshold_heat", str(first_module.damage_threshold_heat), str(module.damage_threshold_heat))
		_compare_constructor_metadata_field(issues, module_id, "repair_complexity", str(first_module.repair_complexity), str(module.repair_complexity))
		_compare_constructor_metadata_field(issues, module_id, "repair_category", first_module.repair_category, module.repair_category)

func _compare_constructor_metadata_field(
	issues: Array[String],
	module_id: String,
	field_name: String,
	first_value: String,
	next_value: String
) -> void:
	if first_value != next_value:
		issues.append("Duplicate metadata mismatch for %s: %s differs (%s vs %s)." % [module_id, field_name, first_value, next_value])

func get_box_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in box_storage:
		if module != null and module.id == module_id:
			count += 1
	return count

func get_external_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in get_unique_external_modules():
		if module != null and module.id == module_id:
			count += 1
	return count

func get_internal_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in get_unique_internal_modules():
		if module != null and module.id == module_id:
			count += 1
	return count

func get_overlay_path_count_by_module_id(module_id: String) -> int:
	var count: int = 0
	for record in internal_overlay_paths:
		var record_module_id: String = String(record.get("module_id", ""))
		if record_module_id == module_id:
			count += 1
	return count

func get_liquid_overlay_path_count() -> int:
	return get_overlay_path_count_by_module_id("water_tube_v1")

func get_duct_overlay_path_count() -> int:
	return get_overlay_path_count_by_module_id("air_duct_v1")

func get_total_module_count_by_id(module_id: String) -> int:
	return get_box_module_count_by_id(module_id) + get_external_module_count_by_id(module_id) + get_internal_module_count_by_id(module_id)

func has_internal_role(role_id: String) -> bool:
	return count_internal_role(role_id) > 0

func count_internal_role(role_id: String) -> int:
	if role_id.is_empty():
		return 0
	var count: int = 0
	for module in get_unique_internal_modules():
		if is_module_functional(module) and module.internal_role == role_id:
			count += 1
	return count

func get_internal_modules_by_role(role_id: String) -> Array[BipobModule]:
	var modules_by_role: Array[BipobModule] = []
	if role_id.is_empty():
		return modules_by_role
	for module in get_unique_internal_modules():
		if not is_module_functional(module):
			continue
		if module.internal_role == role_id:
			modules_by_role.append(module)
	return modules_by_role

func has_power_source() -> bool:
	return has_internal_role("battery")

func has_power_block() -> bool:
	return has_internal_role("power_block")

func has_internal_interface() -> bool:
	return has_internal_role("internal_interface")

func has_external_interface_bridge() -> bool:
	return has_internal_role("external_interface")

func is_virtual_power_available() -> bool:
	return has_power_source() and has_power_block()

func is_internal_data_network_available() -> bool:
	return has_internal_interface()

func is_external_data_network_available() -> bool:
	return has_internal_interface() and has_external_interface_bridge()

func get_status_word(value: bool) -> String:
	return "available" if value else "unavailable"

func get_thermal_status_word() -> String:
	var critical_count: int = get_critical_internal_preview_count()
	if critical_count > 0:
		return "critical preview"
	if get_highest_internal_preview_heat() >= 4:
		return "warning"
	return "ok"

func get_air_intake_readiness_word() -> String:
	if not has_air_cooling_requiring_intake():
		return "not required"
	if has_external_air_intake():
		return "installed"
	return "missing"

func get_warning_count() -> int:
	return get_constructor_warning_lines().size()


func get_installed_external_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Installed external:")

	var modules: Array[BipobModule] = get_unique_external_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in modules:
		if module == null:
			continue
		lines.append("- %s" % get_module_display_name(module))

	return "\n".join(lines)

func get_installed_internal_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Installed internal:")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in modules:
		if module == null:
			continue

		var role_text: String = ""
		if not module.internal_role.is_empty():
			role_text = " (%s)" % module.internal_role

		lines.append("- %s%s" % [
			get_module_display_name(module),
			role_text
		])

	return "\n".join(lines)

func get_storage_overview_text() -> String:
	var lines: Array[String] = []
	lines.append("Storage overview:")
	lines.append("- Box Storage: %d" % box_storage.size())
	lines.append("- External installed: %d" % get_unique_external_modules().size())
	lines.append("- Internal installed: %d" % get_unique_internal_modules().size())
	lines.append("- Overlay paths: %d" % internal_overlay_paths.size())
	lines.append("- Liquid paths: %d" % get_liquid_overlay_path_count())
	lines.append("- Duct paths: %d" % get_duct_overlay_path_count())

	var warnings_count: int = 0
	if has_method("get_warning_count"):
		warnings_count = get_warning_count()
	else:
		warnings_count = get_constructor_warning_lines().size()

	lines.append("- Warnings: %d" % warnings_count)
	return "\n".join(lines)

func get_constructor_dashboard_text() -> String:
	var lines: Array[String] = []

	lines.append("Constructor Dashboard")
	lines.append("")

	lines.append(get_constructor_readiness_summary_text())
	lines.append("")

	lines.append(get_constructor_warning_summary_text())
	lines.append("")

	lines.append(get_storage_overview_text())
	lines.append(get_constructor_planning_checkpoint_compact_text())
	lines.append("")

	var thermal_critical_heat: int = THERMAL_CRITICAL_HEAT
	lines.append("Thermal:")
	lines.append("- Highest heat: %d / %d" % [
		get_highest_internal_preview_heat(),
		thermal_critical_heat
	])
	lines.append("- Critical preview: %d" % get_critical_internal_preview_count())
	lines.append("- Air intake: %s" % get_air_intake_readiness_word())
	lines.append("")

	lines.append(get_installed_external_summary_text())
	lines.append("")

	lines.append(get_installed_internal_summary_text())

	return "\n".join(lines)

func get_constructor_planning_checkpoint_text() -> String:
	var lines: Array[String] = []

	lines.append("Constructor Planning Checkpoint")
	lines.append("")
	lines.append("Systems:")

	var internal_count: int = get_unique_internal_modules().size()
	var external_count: int = get_unique_external_modules().size()
	var overlay_count: int = internal_overlay_paths.size()
	var liquid_count: int = get_liquid_overlay_path_count() if has_method("get_liquid_overlay_path_count") else 0
	var duct_count: int = get_duct_overlay_path_count() if has_method("get_duct_overlay_path_count") else 0

	lines.append("- Box Storage: %d module(s)" % box_storage.size())
	lines.append("- Internal Volume: %d installed module(s)" % internal_count)
	lines.append("- External Slots: %d installed module(s)" % external_count)
	lines.append("- Overlay Paths: %d total / %d liquid / %d duct" % [
		overlay_count,
		liquid_count,
		duct_count
	])

	lines.append("")
	lines.append("Thermal:")
	lines.append("- Highest Thermal Preview: %d / %d" % [
		get_highest_internal_preview_heat(),
		THERMAL_CRITICAL_HEAT
	])
	lines.append("- Critical Thermal Preview: %d" % get_critical_internal_preview_count())

	if has_method("get_overlay_thermal_contribution_compact_text"):
		lines.append("- " + get_overlay_thermal_contribution_compact_text())

	if has_method("get_overlay_heat_diff_compact_text"):
		lines.append("- " + get_overlay_heat_diff_compact_text())

	lines.append("")
	lines.append("Damage / Repair:")
	if has_method("get_damage_planning_compact_text"):
		lines.append("- " + get_damage_planning_compact_text())
	if has_method("get_repair_planning_compact_reference_text"):
		lines.append("- " + get_repair_planning_compact_reference_text())

	lines.append("")
	lines.append("Readiness:")
	if has_method("get_constructor_readiness_summary_text"):
		lines.append(get_constructor_readiness_summary_text())
	else:
		lines.append("- Readiness summary unavailable")

	lines.append("")
	lines.append("Warnings:")
	if has_method("get_warning_count"):
		lines.append("- Warning count: %d" % get_warning_count())
	elif has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = get_constructor_warning_lines()
		lines.append("- Warning count: %d" % warning_lines.size())
	else:
		lines.append("- Warning count unavailable")

	lines.append("")
	lines.append("Consistency:")
	if has_method("get_constructor_consistency_issue_lines"):
		var issue_lines: Array[String] = get_constructor_consistency_issue_lines()
		lines.append("- Consistency issues: %d" % issue_lines.size())
	else:
		lines.append("- Consistency check unavailable")

	lines.append("")
	lines.append("Implementation status:")
	lines.append("- Constructor planning is UI/data preview only.")
	lines.append("- Overlay Thermal is hypothetical only.")
	lines.append("- Damage/Repair is metadata only.")
	lines.append("- No Test Build is implemented.")
	lines.append("- No runtime module damage is implemented.")
	lines.append("- Missions are not blocked by constructor planning.")

	return "\n".join(lines)

func get_constructor_planning_checkpoint_compact_text() -> String:
	var internal_count: int = get_unique_internal_modules().size()
	var external_count: int = get_unique_external_modules().size()
	var overlay_count: int = internal_overlay_paths.size()
	var warning_count: int = 0
	var consistency_count: int = 0

	if has_method("get_warning_count"):
		warning_count = get_warning_count()
	elif has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = get_constructor_warning_lines()
		warning_count = warning_lines.size()

	if has_method("get_constructor_consistency_issue_lines"):
		var issue_lines: Array[String] = get_constructor_consistency_issue_lines()
		consistency_count = issue_lines.size()

	return "Checkpoint: internal %d / external %d / overlay %d / warnings %d / consistency %d" % [
		internal_count,
		external_count,
		overlay_count,
		warning_count,
		consistency_count
	]
func get_constructor_readiness_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor readiness:")
	lines.append("- Power: %s" % get_status_word(is_virtual_power_available()))
	lines.append("- Internal data: %s" % get_status_word(is_internal_data_network_available()))
	lines.append("- External data: %s" % get_status_word(is_external_data_network_available()))
	lines.append("- Thermal: %s" % get_thermal_status_word())
	lines.append("- Air intake: %s" % get_air_intake_readiness_word())
	lines.append("- Warnings: %d" % get_warning_count())
	return "\n".join(lines)

func get_constructor_readiness_compact_text() -> String:
	return "Readiness: Power %s | Data %s/%s | Thermal %s | Air %s | Warnings %d" % [
		get_status_word(is_virtual_power_available()),
		get_status_word(is_internal_data_network_available()),
		get_status_word(is_external_data_network_available()),
		get_thermal_status_word(),
		get_air_intake_readiness_word(),
		get_warning_count()
	]

func get_virtual_connection_summary_text() -> String:
	var power_available := is_virtual_power_available()
	var internal_network_available := is_internal_data_network_available()
	var external_network_available := is_external_data_network_available()
	var lines: Array[String] = []
	lines.append("Virtual wiring:")
	lines.append("Power:")
	lines.append("- Battery source: %s" % get_yes_no(has_power_source()))
	lines.append("- Power Block: %s" % get_yes_no(has_power_block()))
	lines.append("- Power distribution: %s" % ("available" if power_available else "unavailable"))
	lines.append("")
	lines.append("Data:")
	lines.append("- Internal Interface: %s" % get_yes_no(has_internal_interface()))
	lines.append("- External Interface bridge: %s" % get_yes_no(has_external_interface_bridge()))
	lines.append("- Internal data network: %s" % ("available" if internal_network_available else "unavailable"))
	lines.append("- External data network: %s" % ("available" if external_network_available else "unavailable"))
	lines.append("")
	lines.append("Rules:")
	lines.append("Battery -> Power Block -> devices")
	lines.append("Internal devices -> Internal Interface")
	lines.append("External devices -> External Interface")
	lines.append("Internal Interface <-> External Interface")
	return "\n".join(lines)

func get_internal_connection_scheme_summary_text() -> String:
	return get_virtual_connection_summary_text()

func get_internal_role_summary_text() -> String:
	var role_order: Array[String] = [
		"battery",
		"power_block",
		"internal_interface",
		"external_interface",
		"processor",
		"memory",
		"storage",
		"cooling",
		"wire",
	]
	var lines: Array[String] = ["Internal roles:"]
	for role_id in role_order:
		var role_count := count_internal_role(role_id)
		if role_count > 0:
			lines.append("- %s: %d" % [role_id, role_count])
	if lines.size() == 1:
		lines.append("none")
	return "\n".join(lines)

func get_yes_no(value: bool) -> String:
	return "yes" if value else "no"

func get_module_idle_heat(module: BipobModule) -> int:
	if module == null:
		return 0
	return clampi(module.heat_idle, 0, 5)

func get_module_active_heat(module: BipobModule) -> int:
	if module == null:
		return 0
	return clampi(module.heat_active, 0, 5)

func get_module_cooling_power(module: BipobModule) -> int:
	if module == null:
		return 0
	return max(0, module.cooling_power)

func is_cooling_module(module: BipobModule) -> bool:
	return module != null and module.internal_role == "cooling"

func is_air_cooling_module(module: BipobModule) -> bool:
	return is_cooling_module(module) and module.cooling_type == "air"

func has_external_air_intake() -> bool:
	for module in get_unique_external_modules():
		if module != null and module.id == "air_intake_v1":
			return true
	return false

func has_air_cooling_requiring_intake() -> bool:
	for module in get_unique_internal_modules():
		if module != null and module.requires_air_intake:
			return true
	return false

func get_air_intake_status_text() -> String:
	if not has_air_cooling_requiring_intake():
		return "not required"
	if has_external_air_intake():
		return "installed"
	return "missing"

func get_air_intake_warning_text() -> String:
	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		return "Warning: Air cooling requires Air Intake Node on external body."
	return ""

func get_air_intake_summary_text() -> String:
	var status: String = get_air_intake_status_text()
	var warning: String = get_air_intake_warning_text()
	if warning.is_empty():
		return "Air intake: " + status
	return "Air intake: " + status + "\n" + warning

func get_thermal_metadata_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Thermal model:")
	lines.append("Critical heat: 5")
	lines.append("")
	lines.append("Heat sources:")
	for module in get_unique_internal_modules():
		if module == null:
			continue
		var idle_heat := get_module_idle_heat(module)
		var active_heat := get_module_active_heat(module)
		if idle_heat <= 0 and active_heat <= 0:
			continue
		lines.append("- %s: %d / %d" % [get_module_display_name(module), idle_heat, active_heat])
	if lines[lines.size() - 1] == "Heat sources:":
		lines.append("none")
	lines.append("")
	lines.append("Cooling:")
	for module in get_unique_internal_modules():
		if module == null or not is_cooling_module(module):
			continue
		lines.append("- %s: %s cooling %d" % [get_module_display_name(module), module.cooling_type, get_module_cooling_power(module)])
	if lines[lines.size() - 1] == "Cooling:":
		lines.append("none")
	lines.append("")
	var requires_intake := has_air_cooling_requiring_intake()
	var intake_installed := has_external_air_intake()
	lines.append("Air:")
	lines.append("- Air cooling requires intake: %s" % get_yes_no(requires_intake))
	lines.append("- Air Intake Node installed: %s" % get_yes_no(intake_installed))
	if requires_intake and not intake_installed:
		lines.append("- Warning: Air cooling requires Air Intake Node on external body.")
	lines.append("")
	lines.append("Rules:")
	lines.append("- Neighbor heat = source heat - 1")
	lines.append("- Cooler cools adjacent modules by 2")
	lines.append("- Radiator cools adjacent modules by 2")
	lines.append("- Radiator near cooler cools by 4")
	lines.append("- Radiator against body cools by 3")
	lines.append("- Water tube base cooling is 2")
	lines.append("- Water tube through cooler = 4")
	lines.append("- Water tube through radiator = 3")
	lines.append("- Water tube through radiator near cooler = 5")
	return "\n".join(lines)

func get_external_device_summary_text() -> String:
	if external_modules_by_slot.is_empty():
		return "External devices: none"
	var lines: Array[String] = ["External devices:"]
	for side_id in EXTERNAL_SIDE_ORDER:
		var side_size := get_external_side_size(side_id)
		var side_module_names: Array[String] = []
		var side_modules_seen: Array[BipobModule] = []
		for y in range(side_size.y):
			for x in range(side_size.x):
				var module := get_external_module_at(side_id, Vector2i(x, y))
				if module == null or side_modules_seen.has(module):
					continue
				side_modules_seen.append(module)
				side_module_names.append(get_module_display_name(module))
		if not side_module_names.is_empty():
			lines.append("- %s: %s" % [side_id, ", ".join(side_module_names)])
	if lines.size() == 1:
		return "External devices: none"
	return "\n".join(lines)
func get_overlay_heat_delta_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var base_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)

	return overlay_heat - base_heat


func does_overlay_improve_module_heat(module: BipobModule) -> bool:
	return get_overlay_heat_delta_for_module(module) < 0


func get_overlay_heat_diff_line(module: BipobModule) -> String:
	if module == null:
		return ""

	var base_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
	var delta: int = overlay_heat - base_heat

	var delta_text: String = "0"
	if delta < 0:
		delta_text = "%d" % delta
	elif delta > 0:
		delta_text = "+%d" % delta

	return "%s: base %d -> overlay %d (%s)" % [
		get_module_display_name(module),
		base_heat,
		overlay_heat,
		delta_text
	]


func get_overlay_heat_diff_summary_text(show_unchanged: bool = false) -> String:
	var lines: Array[String] = []
	lines.append("Overlay Diff")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		lines.append("")
		lines.append("Note: Overlay Diff is hypothetical only.")
		lines.append("Base Thermal Preview is unchanged.")
		return "\n".join(lines)

	var changed_count: int = 0

	for module in modules:
		if module == null:
			continue

		var delta: int = get_overlay_heat_delta_for_module(module)

		if delta == 0 and not show_unchanged:
			continue

		if delta != 0:
			changed_count += 1

		lines.append("- " + get_overlay_heat_diff_line(module))

	if lines.size() == 1:
		lines.append("none")

	lines.append("")
	lines.append("Changed modules: %d" % changed_count)
	lines.append("Note: Overlay Diff is hypothetical only.")
	lines.append("Base Thermal Preview is unchanged.")

	return "\n".join(lines)


func get_overlay_heat_diff_compact_text() -> String:
	var changed_count: int = 0
	var best_delta: int = 0

	for module in get_unique_internal_modules():
		if module == null:
			continue

		var delta: int = get_overlay_heat_delta_for_module(module)

		if delta < 0:
			changed_count += 1
			best_delta = mini(best_delta, delta)

	return "Overlay Diff: changed %d / best %d" % [
		changed_count,
		best_delta
	]
func get_external_slot_key(side_id: String, slot_position: Vector2i) -> String:
	return "%s:%d,%d" % [side_id, slot_position.x, slot_position.y]

func is_external_side_valid(side_id: String) -> bool:
	return side_id in EXTERNAL_SIDE_ORDER

func is_external_slot_in_bounds(side_id: String, slot_position: Vector2i) -> bool:
	if not is_external_side_valid(side_id):
		return false
	var side_size := get_external_side_size(side_id)
	return (
		slot_position.x >= 0
		and slot_position.y >= 0
		and slot_position.x < side_size.x
		and slot_position.y < side_size.y
	)

func set_selected_external_slot(side_id: String, origin: Vector2i) -> void:
	if not is_external_side_valid(side_id):
		return

	if not is_external_slot_in_bounds(side_id, origin):
		return

	selected_external_side = side_id
	selected_external_origin = origin

func get_selected_external_side() -> String:
	return selected_external_side

func get_selected_external_origin() -> Vector2i:
	return selected_external_origin

func get_external_module_at(side_id: String, slot_position: Vector2i) -> BipobModule:
	var key := get_external_slot_key(side_id, slot_position)
	if external_modules_by_slot.has(key):
		return external_modules_by_slot[key]
	return null

func is_external_slot_empty(side_id: String, slot_position: Vector2i) -> bool:
	return get_external_module_at(side_id, slot_position) == null

func get_max_pockets_per_side(profile_id: String = "") -> int:
	var normalized: String = profile_id.strip_edges().to_lower()
	if normalized.is_empty():
		var size: Vector3i = get_constructor_body_size()
		if size == CONSTRUCTOR_PROFILE_JUGGERNAUT_SIZE:
			normalized = "juggernaut"
		elif size == CONSTRUCTOR_PROFILE_ENGINEER_SIZE:
			normalized = "engineer"
		else:
			normalized = "scout"
	match normalized:
		"engineer", "beta":
			return 2
		"juggernaut":
			return 3
		_:
			return 1

func _ensure_external_pockets_shape() -> void:
	var max_count: int = get_max_pockets_per_side()
	for side_id in [EXTERNAL_SIDE_FRONT, EXTERNAL_SIDE_BACK, EXTERNAL_SIDE_LEFT, EXTERNAL_SIDE_RIGHT]:
		var row: Array = []
		if external_pockets_by_side.has(side_id):
			row = Array(external_pockets_by_side[side_id])
		while row.size() < max_count:
			row.append(false)
		if row.size() > max_count:
			row.resize(max_count)
		external_pockets_by_side[side_id] = row

func is_external_pocket_enabled(side_id: String, pocket_index: int) -> bool:
	_ensure_external_pockets_shape()
	if not external_pockets_by_side.has(side_id):
		return false
	var row: Array = external_pockets_by_side[side_id]
	return pocket_index >= 0 and pocket_index < row.size() and bool(row[pocket_index])

func get_external_pocket_reserved_cells(side_id: String, pocket_index: int) -> Array[Vector2i]:
	var reserved: Array[Vector2i] = []
	var side_size: Vector2i = get_external_side_size(side_id)
	if side_size.x <= 0 or side_size.y <= 0:
		return reserved
	var col_a: int = pocket_index * 2
	var col_b: int = col_a + 1
	var row_a: int = side_size.y - 2
	var row_b: int = side_size.y - 1
	for y in [row_a, row_b]:
		if y < 0 or y >= side_size.y:
			continue
		if col_a >= 0 and col_a < side_size.x:
			reserved.append(Vector2i(col_a, y))
		if col_b >= 0 and col_b < side_size.x:
			reserved.append(Vector2i(col_b, y))
	return reserved

func is_external_pocket_index_valid_for_side(side_id: String, pocket_index: int) -> bool:
	var side_size: Vector2i = get_external_side_size(side_id)
	if side_size.x <= 0 or side_size.y <= 0:
		return false
	var col_b: int = pocket_index * 2 + 1
	var top_reserved_row: int = side_size.y - 2
	return (
		pocket_index >= 0
		and col_b >= 0
		and col_b < side_size.x
		and top_reserved_row >= 0
	)

func is_external_cell_reserved_for_pocket(side_id: String, cell: Vector2i) -> bool:
	_ensure_external_pockets_shape()
	if not external_pockets_by_side.has(side_id):
		return false
	var row: Array = external_pockets_by_side[side_id]
	for pocket_index in range(row.size()):
		if not bool(row[pocket_index]):
			continue
		if get_external_pocket_reserved_cells(side_id, pocket_index).has(cell):
			return true
	return false

func toggle_external_pocket(side_id: String, pocket_index: int) -> void:
	_ensure_external_pockets_shape()
	if not external_pockets_by_side.has(side_id):
		return
	var row: Array = external_pockets_by_side[side_id]
	if pocket_index < 0 or pocket_index >= row.size():
		return
	if not is_external_pocket_index_valid_for_side(side_id, pocket_index):
		return
	var is_enabled: bool = bool(row[pocket_index])
	if not is_enabled:
		for cell in get_external_pocket_reserved_cells(side_id, pocket_index):
			if is_external_cell_occupied(side_id, cell):
				hint_requested.emit("Cannot reserve pocket: cells are occupied.")
				status_changed.emit()
				return
	row[pocket_index] = not is_enabled
	external_pockets_by_side[side_id] = row
	status_changed.emit()


func can_place_external_module(module: BipobModule, side_id: String, origin: Vector2i) -> bool:
	return can_place_external_module_at(module, side_id, origin)


func get_external_module_covered_cells(_side_id: String, origin: Vector2i, module: BipobModule) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if module == null:
		return cells

	var footprint_size: Vector2i = get_external_module_footprint_size(module)

	for y in range(footprint_size.y):
		for x in range(footprint_size.x):
			var cell: Vector2i = Vector2i(origin.x + x, origin.y + y)
			cells.append(cell)

	return cells


func get_external_module_size(module: BipobModule) -> Vector2i:
	return get_external_module_footprint_size(module)

func get_external_module_footprint_cells(module: BipobModule, origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var module_size: Vector2i = get_external_module_size(module)
	for y in range(module_size.y):
		for x in range(module_size.x):
			cells.append(origin + Vector2i(x, y))
	return cells

func get_external_module_safe_area_cells(module: BipobModule, origin: Vector2i) -> Array[Vector2i]:
	var safe_cells: Array[Vector2i] = []
	var module_size: Vector2i = get_external_module_size(module)
	var footprint_map: Dictionary = {}
	for footprint_cell in get_external_module_footprint_cells(module, origin):
		footprint_map[footprint_cell] = true

	for y in range(origin.y - 1, origin.y + module_size.y + 1):
		for x in range(origin.x - 1, origin.x + module_size.x + 1):
			var cell := Vector2i(x, y)
			if footprint_map.has(cell):
				continue
			if safe_cells.has(cell):
				continue
			safe_cells.append(cell)
	return safe_cells

func is_external_cell_occupied(side_id: String, cell_position: Vector2i) -> bool:
	return get_external_module_at(side_id, cell_position) != null

func can_place_external_module_at(module: BipobModule, side_id: String, origin: Vector2i) -> bool:
	return get_external_module_placement_error(module, side_id, origin).is_empty()

func get_external_module_placement_error(module: BipobModule, side_id: String, origin: Vector2i) -> String:
	if module == null:
		return "No module selected."
	if not is_external_module(module):
		return "Module cannot be installed outside: %s" % get_module_display_name(module)
	if not is_external_side_valid(side_id):
		return "Invalid external side: %s." % side_id
	if not can_place_external_module_on_side(module, side_id):
		return "Cannot install %s on %s. Allowed side: %s." % [
			get_module_display_name(module),
			get_external_side_display_name(side_id),
			get_allowed_external_sides_text(module)
		]

	for cell in get_external_module_covered_cells(side_id, origin, module):
		if not is_external_slot_in_bounds(side_id, cell):
			return "Module footprint is outside the %s side." % get_external_side_display_name(side_id)
		if is_external_cell_occupied(side_id, cell):
			return "External slot is occupied."
		if is_external_cell_reserved_for_pocket(side_id, cell):
			return "External pocket cell is reserved."

	return ""

func _remove_external_module_instance_cells(side_id: String, module: BipobModule) -> void:
	if module == null:
		return
	var keys_to_remove: Array[String] = []
	for slot_key_variant in external_modules_by_slot.keys():
		var slot_key := String(slot_key_variant)
		if not slot_key.begins_with(side_id + ":"):
			continue
		var stored_module: BipobModule = external_modules_by_slot[slot_key]
		if stored_module == module:
			keys_to_remove.append(slot_key)
	for slot_key in keys_to_remove:
		external_modules_by_slot.erase(slot_key)

func is_external_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if module.placement_type == "external" or module.placement_type == "any":
		return true
	return EXTERNAL_MODULE_CATALOG.has(module.id)

func is_internal_module(module: BipobModule) -> bool:
	return module != null and (module.placement_type == "internal" or module.placement_type == "internal_overlay")

func get_internal_modules_in_box_storage() -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	for module in box_storage:
		if is_internal_module(module):
			modules.append(module)
	return modules

func get_box_storage_index_for_internal_selection(internal_index: int) -> int:
	var current_internal_index := 0
	for i in range(box_storage.size()):
		var module: BipobModule = box_storage[i]
		if not is_internal_module(module):
			continue

		if current_internal_index == internal_index:
			return i

		current_internal_index += 1

	return -1

func get_allowed_external_sides_for_module(module: BipobModule) -> Array:
	if module == null:
		return []

	if not module.allowed_external_sides.is_empty():
		return module.allowed_external_sides.duplicate()

	if EXTERNAL_MODULE_CATALOG.has(module.id):
		var catalog_sides: Array = EXTERNAL_MODULE_CATALOG[module.id].get("sides", [])
		return catalog_sides.duplicate()

	return EXTERNAL_SIDE_ORDER.duplicate()

func can_place_external_module_on_side(module: BipobModule, side_id: String) -> bool:
	if module == null:
		return false
	var allowed_sides := get_allowed_external_sides_for_module(module)
	return side_id in allowed_sides

func get_external_side_display_name(side_id: String) -> String:
	return side_id.capitalize()

func get_allowed_external_sides_text(module: BipobModule) -> String:
	var allowed := get_allowed_external_sides_for_module(module)
	if allowed.is_empty():
		return "none"
	var names: Array[String] = []
	for side_id in allowed:
		names.append(get_external_side_display_name(side_id))
	return ", ".join(names)

func place_external_module(module: BipobModule, side_id: String, slot_position: Vector2i) -> bool:
	var placement_error := get_external_module_placement_error(module, side_id, slot_position)
	if not placement_error.is_empty():
		hint_requested.emit(placement_error)
		status_changed.emit()
		return false

	for cell in get_external_module_footprint_cells(module, slot_position):
		external_modules_by_slot[get_external_slot_key(side_id, cell)] = module
	placed_external_modules.append({
		"module": module,
		"side": side_id,
		"origin": slot_position
	})
	hint_requested.emit("External module placed: %s (%dx%d)" % [
		get_module_display_name(module),
		get_external_module_size(module).x,
		get_external_module_size(module).y
	])
	status_changed.emit()
	return true

func place_external_module_from_box_storage(storage_index: int, side_id: String, slot_position: Vector2i) -> bool:
	if storage_index < 0 or storage_index >= box_storage.size():
		hint_requested.emit("No module in that Box slot.")
		status_changed.emit()
		return false

	var module: BipobModule = box_storage[storage_index]
	if module == null:
		box_storage.remove_at(storage_index)
		hint_requested.emit("Removed empty module from Box Storage.")
		status_changed.emit()
		return false
	if is_module_broken(module):
		hint_requested.emit("Broken module cannot be installed.")
		status_changed.emit()
		return false
	if is_module_unknown(module):
		hint_requested.emit("Unknown module must be identified first.")
		status_changed.emit()
		return false

	var placement_error := get_external_module_placement_error(module, side_id, slot_position)
	if not placement_error.is_empty():
		hint_requested.emit(placement_error)
		status_changed.emit()
		return false

	box_storage.remove_at(storage_index)
	for cell in get_external_module_footprint_cells(module, slot_position):
		external_modules_by_slot[get_external_slot_key(side_id, cell)] = module
	placed_external_modules.append({
		"module": module,
		"side": side_id,
		"origin": slot_position
	})

	hint_requested.emit("External module installed: %s (%dx%d)" % [
		get_module_display_name(module),
		get_external_module_size(module).x,
		get_external_module_size(module).y
	])
	status_changed.emit()
	return true

func remove_external_module(side_id: String, slot_position: Vector2i) -> BipobModule:
	if not is_external_slot_in_bounds(side_id, slot_position):
		hint_requested.emit("External slot is out of bounds.")
		status_changed.emit()
		return null

	var record: Dictionary = get_external_module_record_at(side_id, slot_position)
	if record.is_empty():
		hint_requested.emit("External slot is empty.")
		status_changed.emit()
		return null
	var module: BipobModule = record.get("module", null)
	remove_external_module_record(record, false)
	hint_requested.emit("External module removed: " + get_module_display_name(module))
	status_changed.emit()
	return module

func remove_external_module_to_box_storage(side_id: String, slot_position: Vector2i) -> bool:
	if not is_external_slot_in_bounds(side_id, slot_position):
		hint_requested.emit("External slot is out of bounds.")
		status_changed.emit()
		return false

	var record: Dictionary = get_external_module_record_at(side_id, slot_position)
	if record.is_empty():
		hint_requested.emit("External slot is empty.")
		status_changed.emit()
		return false
	var module: BipobModule = record.get("module", null)
	if module != null and (bool(module.is_builtin) or not bool(module.is_removable)):
		hint_requested.emit("Built-in module cannot be removed.")
		status_changed.emit()
		return false
	remove_external_module_record(record, true)

	hint_requested.emit("External module removed to Box: " + get_module_display_name(module))
	status_changed.emit()
	return true

func get_external_module_record_at(side_id: String, cell: Vector2i) -> Dictionary:
	var module: BipobModule = get_external_module_at(side_id, cell)
	if module == null:
		return {}
	for record_variant in placed_external_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		if String(record.get("side", "")) != side_id:
			continue
		if record.get("module", null) != module:
			continue
		var origin: Vector2i = record.get("origin", Vector2i.ZERO)
		if get_external_module_footprint_cells(module, origin).has(cell):
			return record
	var module_size: Vector2i = get_external_module_size(module)
	for y in range(cell.y - module_size.y + 1, cell.y + 1):
		for x in range(cell.x - module_size.x + 1, cell.x + 1):
			var origin := Vector2i(x, y)
			var covered_cells: Array[Vector2i] = get_external_module_footprint_cells(module, origin)
			if not covered_cells.has(cell):
				continue
			var valid := true
			for covered_cell in covered_cells:
				if get_external_module_at(side_id, covered_cell) != module:
					valid = false
					break
			if valid:
				return {"module": module, "side": side_id, "origin": origin}
	return {}

func remove_external_module_record(record: Dictionary, should_return_to_box: bool = true) -> bool:
	if record.is_empty():
		return false
	var module: BipobModule = record.get("module", null)
	var side_id: String = String(record.get("side", ""))
	var origin: Vector2i = record.get("origin", Vector2i.ZERO)
	if module == null or side_id.is_empty():
		return false
	for cell in get_external_module_footprint_cells(module, origin):
		var key: String = get_external_slot_key(side_id, cell)
		if external_modules_by_slot.get(key, null) == module:
			external_modules_by_slot.erase(key)
	for index in range(placed_external_modules.size() - 1, -1, -1):
		var placed_record: Dictionary = placed_external_modules[index]
		if String(placed_record.get("side", "")) == side_id and placed_record.get("origin", Vector2i.ZERO) == origin and placed_record.get("module", null) == module:
			placed_external_modules.remove_at(index)
			break
	if should_return_to_box and module != null and not box_storage.has(module):
		box_storage.append(module)
	return true


func clear_external_modules_for_profile(_profile_id: String) -> void:
	for index in range(placed_external_modules.size() - 1, -1, -1):
		var record: Dictionary = placed_external_modules[index]
		var module: BipobModule = record.get("module", null)
		if module != null and (bool(module.is_builtin) or not bool(module.is_removable)):
			continue
		remove_external_module_record(record, true)
	status_changed.emit()

func clear_internal_modules_for_profile(_profile_id: String) -> void:
	for index in range(placed_internal_modules.size() - 1, -1, -1):
		var record: Dictionary = placed_internal_modules[index]
		var module: BipobModule = record.get("module", null)
		if module != null and (bool(module.is_builtin) or not bool(module.is_removable)):
			continue
		remove_internal_module_record(record)
		if module != null and not box_storage.has(module):
			box_storage.append(module)
	clear_selected_overlay_cells()
	status_changed.emit()

func get_external_build_summary_text() -> String:
	if external_modules_by_slot.is_empty():
		return "External build: empty"

	var lines: Array[String] = ["External build:"]
	for side_id in EXTERNAL_SIDE_ORDER:
		var side_size := get_external_side_size(side_id)
		var seen_modules: Array[BipobModule] = []
		for y in range(side_size.y):
			for x in range(side_size.x):
				var module: BipobModule = get_external_module_at(side_id, Vector2i(x, y))
				if module == null or seen_modules.has(module):
					continue
				seen_modules.append(module)
		if not seen_modules.is_empty():
			lines.append("- %s: %d module(s)" % [side_id, seen_modules.size()])

	return "\n".join(lines)

func debug_place_first_installed_external_module() -> void:
	if installed_modules.is_empty():
		hint_requested.emit("No installed modules to place externally.")
		status_changed.emit()
		return

	for module in installed_modules:
		if is_external_module(module):
			place_external_module(module, EXTERNAL_SIDE_FRONT, Vector2i(1, 1))
			return

	hint_requested.emit("No external installed module found.")
	status_changed.emit()


func create_external_module_by_id(module_id: String) -> BipobModule:
	var module := BipobModule.new()
	module.id = module_id
	module.module_id = module_id
	module.placement_type = "external"
	module.version = "V1"
	module.module_version = 1
	module.internal_role = "none"
	var normalized_id: String = module_id
	match module_id:
		"manipulator_v1", "manipulator_tentacle_v1": normalized_id = "manipulator_arm_v1"
		"manipulator_magnetic_v1": normalized_id = "magnetic_manipulator_v1"
		"interface_v1", "connector_v1": normalized_id = "external_interface_connector_v1"
		"shock_device_v1": normalized_id = "shocker_v1"
		"hammer_v1": normalized_id = "sledgehammer_v1"
		"repair_module_v1": normalized_id = "repair_v1"
		"energy_shield_v1": normalized_id = "shield_module_v1"
		_: pass
	module.id = normalized_id
	module.module_id = normalized_id
	var metadata: Dictionary = EXTERNAL_MODULE_CATALOG.get(normalized_id, {})
	if metadata.is_empty():
		return null
	module.module_version = get_module_version_for_module_id(normalized_id)
	module.version = "V%d" % module.module_version
	module.display_name = String(metadata.get("name", module_id))
	module.category = String(metadata.get("cat", "Other"))
	module.description = String(metadata.get("desc", ""))
	module.external_width = int(metadata.get("size", Vector2i.ONE).x)
	module.external_height = int(metadata.get("size", Vector2i.ONE).y)
	module.allowed_external_sides.clear()
	var raw_sides: Array = metadata.get("sides", [])
	for side in raw_sides:
		module.allowed_external_sides.append(String(side))
	module.energy_cost = int(metadata.get("energy", 0))
	module.heat_value = int(metadata.get("heat", 0))
	module.scan_range = int(metadata.get("scan", 0))
	module.visibility_value = int(metadata.get("visibility", 0))
	module.scan_accuracy = int(metadata.get("accuracy", 0))
	module.sensor_direction = String(metadata.get("direction", ""))
	module.armor_bonus = int(metadata.get("armor", 0))
	module.shield_value = int(metadata.get("shield", 0))
	module.defense_type = String(metadata.get("defense_type", ""))
	module.damage_value = String(metadata.get("damage", ""))
	module.weapon_range_type = String(metadata.get("range", ""))
	module.special_effect_text = String(metadata.get("special", ""))
	module.action_modifier = int(metadata.get("actions", 0))
	module.movement_type = String(metadata.get("movement", ""))
	module.terrain_type = String(metadata.get("terrain", ""))
	module.gear_speed = int(metadata.get("speed", 0))
	module.ignore_terrain_debuff = bool(metadata.get("ignore_debuff", false))
	module.reach_value = int(metadata.get("reach", 0))
	module.range_value = int(metadata.get("range_value", module.reach_value))
	module.direction_text = String(metadata.get("direction", ""))
	module.span_text = String(metadata.get("span", module.weapon_range_type))
	module.fuel_capacity = int(metadata.get("fuel_capacity", 0))
	module.ammo_dependency_id = String(metadata.get("ammo_dependency_id", ""))
	module.tool_action = String(metadata.get("tool_action", ""))
	module.carry_text = String(metadata.get("carry", ""))
	module.connection_type = String(metadata.get("connection", ""))
	module.connection_range_text = String(metadata.get("connection_range", ""))
	module.action_text = String(metadata.get("action", ""))
	if module.id in ["manipulator_arm_v1", "manipulator_heavy_claw_v1", "magnetic_manipulator_v1", "tentacle_manipulator_v1", "telescopic_arm_v1"]:
		module.granted_commands = ["interact_key", "open_physical_door"]
	if module.id in ["external_interface_connector_v1", "high_bandwidth_connector_v1", "optical_connector_v1", "wireless_connector_v1"]:
		module.granted_commands = ["read_terminal", "open_digital_door"]
	if module.id == "wheels_v1":
		module.granted_commands = ["move_forward", "move_backward", "turn_left", "turn_right"]
	if module.id in ["visor_v1", "visor_v2", "visor_v3"]:
		module.granted_commands = ["vision"]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module



func is_defense_module_active(module: BipobModule) -> bool:
	if module == null:
		return false
	if String(module.category) != "Defense":
		return false
	if module.id == "shield_module_v1" and max_energy > 0:
		var shield_disable_threshold: float = float(max_energy) * 0.25
		if float(energy) < shield_disable_threshold:
			return false
	return true


func try_apply_defense_energy_cost(module: BipobModule) -> bool:
	if module == null:
		return false
	if not is_defense_module_active(module):
		return false
	var energy_cost: int = maxi(0, module.energy_cost)
	if energy_cost <= 0:
		return true
	if energy < energy_cost:
		return false
	energy -= energy_cost
	status_changed.emit()
	return true


# TODO(BIB-530): Wire this helper into combat/status effect systems when damage hooks are available.
func consume_defense_energy_for_effect(effect_type: String) -> bool:
	var normalized_effect: String = effect_type.strip_edges().to_lower()
	for module in installed_modules:
		if module == null or module.placement_type != "external":
			continue
		if String(module.category) != "Defense":
			continue
		match normalized_effect:
			"emp", "shock":
				if module.id == "emp_shield_v1":
					return try_apply_defense_energy_cost(module)
			"heat", "fire", "laser":
				if module.id == "heat_shield_v1":
					return try_apply_defense_energy_cost(module)
			"damage", "absorption", "shield":
				if module.id == "shield_module_v1":
					return try_apply_defense_energy_cost(module)
	return false
func ensure_external_constructor_modules_in_box_storage() -> void:
	var required_ids: Array = EXTERNAL_MODULE_CATALOG.keys()

	for module_id_variant in required_ids:
		var module_id: String = String(module_id_variant)

		if has_module_id_in_box_storage(module_id):
			continue

		var module: BipobModule = create_external_module_by_id(module_id)
		if module != null:
			box_storage.append(module)

func create_default_modules() -> void:
	installed_modules.clear()

	if debug_install_wheels:
		var wheels_module: BipobModule = create_external_module_by_id("wheels_v1")
		if wheels_module != null:
			install_module(wheels_module)

	if debug_install_manipulator:
		var manipulator_module: BipobModule = create_external_module_by_id("manipulator_v1")
		if manipulator_module != null:
			install_module(manipulator_module)

	if debug_install_interface:
		var interface_module: BipobModule = create_external_module_by_id("interface_v1")
		if interface_module != null:
			install_module(interface_module)

	if debug_install_visor:
		var visor_module: BipobModule = create_external_module_by_id("visor_v1")
		if visor_module != null:
			install_module(visor_module)

	add_internal_mvp_modules_to_box()
	ensure_external_constructor_modules_in_box_storage()
	_add_broken_test_visor_v2_to_box_storage()
	_add_unknown_test_visor_v3_to_box_storage()

func _add_broken_test_visor_v2_to_box_storage() -> void:
	for module in box_storage:
		if module == null:
			continue
		if module.module_id == "test_broken_visor_v2":
			return
	var broken_visor: BipobModule = create_external_module_by_id("visor_v2")
	if broken_visor == null:
		return
	broken_visor.module_id = "test_broken_visor_v2"
	set_module_broken(broken_visor, true)
	box_storage.append(broken_visor)

func _add_unknown_test_visor_v3_to_box_storage() -> void:
	for module in box_storage:
		if module == null:
			continue
		if module.module_id == "visor_v3_unknown_test":
			return
		if module.id == "visor_v3" and is_module_unknown(module):
			return
	var unknown_visor: BipobModule = create_external_module_by_id("visor_v3")
	if unknown_visor == null:
		return
	unknown_visor.module_id = "visor_v3_unknown_test"
	unknown_visor.status = "unknown"
	unknown_visor.is_broken = false
	box_storage.append(unknown_visor)

func create_internal_module(module_id: String, module_name: String, module_size: Vector3i) -> BipobModule:
	var module := BipobModule.new()
	module.id = module_id
	module.module_id = module_id
	module.display_name = module_name
	module.placement_type = "internal_overlay" if module_size == Vector3i.ZERO else "internal"
	module.size_x = module_size.x
	module.size_y = module_size.y
	module.size_z = module_size.z
	module.internal_size = module_size
	module.internal_rotatable = true
	module.internal_role = get_internal_role_for_module_id(module_id)
	module.internal_family = get_internal_family_for_module_id(module_id)
	module.module_version = get_module_version_for_module_id(module_id)
	module.version = "V%d" % module.module_version
	module.battery_capacity = get_internal_battery_capacity(module_id)
	module.storage_capacity = get_internal_storage_capacity(module_id)
	module.actions_capacity = get_internal_actions_capacity(module_id)
	module.hack_level = get_internal_hack_level(module_id)
	module.energy_capacity = module.battery_capacity
	module.action_capacity = module.actions_capacity
	module.digital_storage_slots = module.storage_capacity
	module.hack_value = module.hack_level
	module.gpu_value = get_internal_gpu_value(module_id)
	module.sensor_range_bonus = get_internal_sensor_range_bonus(module_id)
	module.sensor_visibility_bonus = get_internal_sensor_visibility_bonus(module_id)
	module.cooling_value = get_internal_cooling_value(module_id)
	module.power_distribution = get_internal_power_distribution(module_id)
	module.interface_role = get_internal_interface_role(module_id)
	module.ports = get_internal_interface_ports(module_id)
	module.power_ports = get_internal_power_ports(module_id)
	module.category = get_internal_category_for_module_id(module_id)
	module.description = get_internal_description_for_module_id(module_id)
	module.heat_value = get_internal_overheat_for_module_id(module_id)
	module.energy_effect_text = get_internal_energy_effect_text(module_id)
	module.special_effect_text = get_internal_special_effect_text(module_id)
	module.characteristics_text = get_internal_characteristics_text(module)
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

func get_internal_category_for_module_id(module_id: String) -> String:
	var family := get_internal_family_for_module_id(module_id)

	match family:
		"battery", "power":
			return "Power"
		"cpu":
			return "CPU"
		"gpu":
			return "GPU"
		"ram":
			return "RAM"
		"storage":
			return "Storage"
		"interface":
			return "Interface"
		"cooling":
			return "Cooling"
		"other":
			return "Other"
		_:
			return "Other"

func get_internal_family_for_module_id(module_id: String) -> String:
	if module_id.begins_with("processor_"):
		return "cpu"
	if module_id.begins_with("memory_"):
		return "ram"
	if module_id.begins_with("hard_drive_"):
		return "storage"
	if module_id.begins_with("battery_"):
		return "battery"
	if module_id.begins_with("power_block_") or module_id.begins_with("capacitor_bank_") or module_id.begins_with("charger_"):
		return "power"
	if module_id.begins_with("charging_via_external_heat_") or module_id.begins_with("charging_via_internal_heat_") or module_id.begins_with("energy_drain_"):
		return "power"
	if module_id.begins_with("cooler_") or module_id.begins_with("radiator_") or module_id.begins_with("water_tube_") or module_id.begins_with("air_duct_"):
		return "cooling"
	if module_id.begins_with("gpu_"):
		return "gpu"
	if module_id.begins_with("internal_interface_") or module_id.begins_with("external_interface_"):
		return "interface"
	if module_id.begins_with("targeting_computer_") or module_id.begins_with("encryption_module_") or module_id.begins_with("motor_controller_") or module_id.begins_with("weapon_controller_") or module_id.begins_with("firewall_module_") or module_id.begins_with("auto_repair_unit_") or module_id.begins_with("sample_analyzer_"):
		return "other"
	return "none"

func get_module_version_for_module_id(module_id: String) -> int:
	if module_id.contains("_v3"):
		return 3
	if module_id.contains("_v2"):
		return 2
	return 1

func get_internal_battery_capacity(module_id: String) -> int:
	if not module_id.begins_with("battery_"):
		return 0
	match get_module_version_for_module_id(module_id):
		1: return 30
		2: return 40
		3: return 50
		_: return 0

func get_internal_storage_capacity(module_id: String) -> int:
	if not module_id.begins_with("hard_drive_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3)

func get_internal_actions_capacity(module_id: String) -> int:
	if not module_id.begins_with("memory_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3) * 5

func get_internal_hack_level(module_id: String) -> int:
	if not module_id.begins_with("processor_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3)

func get_internal_gpu_value(module_id: String) -> int:
	if not module_id.begins_with("gpu_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3) + 2

func get_internal_sensor_range_bonus(module_id: String) -> int:
	match module_id:
		"gpu_v1":
			return 3
		"gpu_v2":
			return 5
		"gpu_v3":
			return 7
		_:
			return 0

func get_internal_sensor_visibility_bonus(module_id: String) -> int:
	match module_id:
		"gpu_v1":
			return 15
		"gpu_v2":
			return 30
		"gpu_v3":
			return 45
		_:
			return 0

func get_internal_cooling_value(module_id: String) -> int:
	match module_id:
		"cooler_v1":
			return -2
		"radiator_v1":
			return -1
		"water_tube_v1":
			return -2
		"air_duct_v1":
			return -1
		_:
			return 0

func get_internal_power_distribution(module_id: String) -> int:
	return 1 if module_id.begins_with("power_block_") else 0

func get_internal_power_ports(module_id: String) -> int:
	match module_id:
		"power_block_v1":
			return 15
		"power_block_v2":
			return 17
		"power_block_v3":
			return 20
		_:
			return 0

func get_internal_interface_role(module_id: String) -> String:
	if module_id.begins_with("internal_interface_"):
		return "internal"
	if module_id.begins_with("external_interface_"):
		return "external"
	return ""

func get_internal_interface_ports(module_id: String) -> int:
	match module_id:
		"internal_interface_v1", "external_interface_v1":
			return 6
		"internal_interface_v2", "external_interface_v2":
			return 7
		"internal_interface_v3", "external_interface_v3":
			return 8
		_:
			return 0

func get_internal_interface_port_capacity() -> int:
	var total := 0
	for record in placed_internal_modules:
		var module: BipobModule = record.get("module", null)
		if is_module_functional(module) and module.interface_role == "internal":
			total += module.ports
	return total

func get_external_interface_port_capacity() -> int:
	var total := 0
	for record in placed_internal_modules:
		var module: BipobModule = record.get("module", null)
		if is_module_functional(module) and module.interface_role == "external":
			total += module.ports
	return total

func get_internal_connected_module_count() -> int:
	var count := 0
	for record in placed_internal_modules:
		var module: BipobModule = record.get("module", null)
		if not is_module_functional(module):
			continue
		if module.interface_role == "internal" or module.interface_role == "external":
			continue
		if module.placement_type == "internal_overlay":
			continue
		if module.is_non_volume_cooling_path:
			continue
		count += 1
	return count

# TODO external interface routing:
# - High-Bandwidth Connector should be required by heavy sensors and advanced tools.
# - Wireless Connector should allow short-range remote connection.
# - Optical Connector should reduce interference effects.
# - External Interface Connector is the base physical connection.
func get_external_connected_module_count() -> int:
	var unique_modules: Dictionary = {}
	for key in external_modules_by_slot.keys():
		var entry: Variant = external_modules_by_slot[key]
		var module: BipobModule = null
		if entry is BipobModule:
			module = entry
		elif entry is Dictionary:
			module = entry.get("module", null)
		if module == null:
			continue
		unique_modules[module.get_instance_id()] = true
	return unique_modules.size()

func is_power_block_module(module: BipobModule) -> bool:
	if module == null:
		return false
	return module.id.begins_with("power_block_")

func get_power_port_capacity() -> int:
	var total := 0
	for record in placed_internal_modules:
		var module: BipobModule = _extract_module_from_internal_record(record)
		if is_module_functional(module) and is_power_block_module(module):
			total += module.power_ports
	return total

func get_internal_powered_device_count() -> int:
	var unique_modules: Dictionary = {}
	for record in placed_internal_modules:
		var module: BipobModule = _extract_module_from_internal_record(record)
		if not is_module_functional(module):
			continue
		if is_power_block_module(module):
			continue
		if module.placement_type == "internal_overlay":
			continue
		unique_modules[module.get_instance_id()] = true
	return unique_modules.size()

func get_external_powered_device_count() -> int:
	var unique_modules: Dictionary = {}
	for key in external_modules_by_slot.keys():
		var entry: Variant = external_modules_by_slot[key]
		var module: BipobModule = null
		if entry is BipobModule:
			module = entry
		elif entry is Dictionary:
			module = entry.get("module", null)
		if module == null:
			continue
		if is_power_block_module(module):
			continue
		unique_modules[module.get_instance_id()] = true
	return unique_modules.size()

func get_used_power_port_count() -> int:
	return get_internal_powered_device_count() + get_external_powered_device_count()

func is_power_port_overloaded() -> bool:
	return get_used_power_port_count() > get_power_port_capacity()

func get_internal_description_for_module_id(module_id: String) -> String:
	match module_id:
		"battery_v1":
			return "Stores a basic amount of energy for movement, tools and other actions."
		"battery_v2":
			return "Accumulates an increased volume of energy, enabling the execution of longer missions and the use of enhanced modules."
		"battery_v3":
			return "A high-capacity energy storage unit for demanding builds equipped with heavy sensors, shields, weaponry, or advanced equipment."
		"power_block_v1":
			return "Distributes battery power between internal systems and connected external modules."
		"power_block_v2":
			return "It improves the distribution of power from the battery between internal systems and connected external modules."
		"power_block_v3":
			return "The ultimate power distributor for routing power from the battery to internal and external modules."
		"capacitor_bank_v1":
			return "Accumulates a short-duration impulse charge to execute powerful actions. An essential component for many advanced modules."
		"charger_v1":
			return "Allows batteries to be charged without removing them."
		"charging_via_external_heat_v1":
			return "Converts heat from the external environment into battery charge. Useful in hot zones, near fire, or around overheated machinery."
		"charging_via_internal_heat_v1":
			return "Recovers part of the robot’s internal waste heat and converts it into battery charge. Works best in builds with many overheating modules."
		"energy_drain_v1":
			return "Extracts energy from nearby powered objects, damaged machines, or exposed energy systems and redirects it into the robot’s batteries."
		"processor_v1":
			return "Performs basic logical operations, hacking routines, and system calculations."
		"processor_v2":
			return "Provides improved computing power for more complex hacking tasks."
		"processor_v3":
			return "High-performance computation core designed for complex security systems and advanced automation."
		"gpu_v1":
			return "Processes basic visual and sensor data. Required for stable operation of standard scanners and visual recognition systems."
		"gpu_v2":
			return "Improves sensor data processing, allowing better analysis of hidden objects, movement and heat signatures."
		"gpu_v3":
			return "Advanced sensor-processing unit for heavy scanners, X-Ray systems and radar interpretation."
		"internal_interface_v1", "internal_interface_v2", "internal_interface_v3":
			return "Creates the internal data bus that connects core modules into one stable robot network."
		"external_interface_v1", "external_interface_v2", "external_interface_v3":
			return "Bridges internal systems with external body modules, allowing modules to receive data and control signals."
		"targeting_computer_v1":
			return "Calculates firing angles, movement prediction, and weapon correction to improve accuracy with ranged and precision weapons."
		"encryption_module_v1":
			return "Protects internal data channels from hacking, interception, and unauthorized access."
		"motor_controller_v1":
			return "Ensures the coordination of movement commands between core systems and installed equipment modules. Essential for the stable control of jumper and air-cushion-based movement."
		"weapon_controller_v1":
			return "Manages weapon activation, targeting signals, safety locks, and firing commands for complex weapon systems."
		"firewall_module_v1":
			return "Blocks hostile hacking attempts and protects the internal network from remote intrusion."
		"auto_repair_unit_v1":
			return "Performs slow automatic repairs on damaged internal modules using available repair resources."
		"sample_analyzer_v1":
			return "Analyzes collected samples, materials, biological traces, and objects directly inside."
		_:
			return get_module_description_for_id(module_id)

func get_internal_overheat_for_module_id(module_id: String) -> int:
	match module_id:
		"battery_v1", "battery_v2", "battery_v3":
			return 1
		"power_block_v1", "power_block_v2", "power_block_v3", "capacitor_bank_v1":
			return 3
		"charger_v1":
			return 1
		"charging_via_external_heat_v1", "charging_via_internal_heat_v1":
			return 2
		"energy_drain_v1":
			return 3
		"processor_v1":
			return 3
		"processor_v2":
			return 4
		"processor_v3":
			return 5
		"gpu_v1":
			return 3
		"gpu_v2":
			return 4
		"gpu_v3":
			return 5
		"memory_v1", "memory_v2", "memory_v3":
			return 2
		"hard_drive_v1", "hard_drive_v2", "hard_drive_v3":
			return 3
		"internal_interface_v1", "internal_interface_v2", "internal_interface_v3", "external_interface_v1", "external_interface_v2", "external_interface_v3":
			return 1
		"targeting_computer_v1", "encryption_module_v1", "motor_controller_v1", "weapon_controller_v1", "firewall_module_v1", "auto_repair_unit_v1", "sample_analyzer_v1":
			return 1
		_:
			return 0



func get_internal_characteristics_text(module: BipobModule) -> String:
	var lines: Array[String] = []
	if module.cooling_value != 0:
		lines.append("Cooling: %d" % abs(module.cooling_value))
	elif module.heat_value > 0:
		lines.append("Overheat: +%d" % module.heat_value)
	if module.energy_capacity > 0:
		lines.append("Energy: +%d" % module.energy_capacity)
	if not module.energy_effect_text.is_empty():
		lines.append("Energy: %s" % module.energy_effect_text)
	if module.action_capacity > 0:
		lines.append("Actions: +%d" % module.action_capacity)
	if module.hack_value > 0:
		lines.append("Hack: +%d" % module.hack_value)
	if module.gpu_value > 0:
		lines.append("GPU: +%d" % module.gpu_value)
	if module.digital_storage_slots > 0:
		lines.append("Storage: +%d" % module.digital_storage_slots)
	if module.power_distribution > 0:
		lines.append("Power Distribution: +%d" % module.power_distribution)
	if module.power_ports > 0:
		lines.append("Power Ports: %d" % module.power_ports)
	if module.ports > 0:
		lines.append("Ports: %d" % module.ports)
	if not module.interface_role.is_empty():
		lines.append("Interface: %s" % module.interface_role)
	if not module.special_effect_text.is_empty():
		lines.append("Special: %s" % module.special_effect_text)
	return "\n".join(lines)

func get_internal_energy_effect_text(module_id: String) -> String:
	match module_id:
		"charging_via_external_heat_v1":
			return "+2 / one degree up"
		"charging_via_internal_heat_v1":
			return "+1 / one degree"
		"energy_drain_v1":
			return "+10 / action"
		_:
			return ""

func get_internal_special_effect_text(module_id: String) -> String:
	match module_id:
		"gpu_v1":
			return "All sensors +3 Range +15 Visibility"
		"gpu_v2":
			return "All sensors +5 Range +30 Visibility"
		"gpu_v3":
			return "All sensors +7 Range +45 Visibility"
		_:
			return ""

func get_internal_role_for_module_id(module_id: String) -> String:
	match module_id:
		"battery_v1", "battery_v2", "battery_v3":
			return "battery"
		"power_block_v1", "power_block_v2", "power_block_v3":
			return "power_block"
		"charger_v1":
			return "charger"
		"charging_via_external_heat_v1", "charging_via_internal_heat_v1", "energy_drain_v1":
			return "charger"
		"internal_interface_v1", "internal_interface_v2", "internal_interface_v3":
			return "internal_interface"
		"external_interface_v1", "external_interface_v2", "external_interface_v3":
			return "external_interface"
		"processor_v1", "processor_v2", "processor_v3":
			return "processor"
		"memory_v1", "memory_v2", "memory_v3":
			return "memory"
		"hard_drive_v1", "hard_drive_v2", "hard_drive_v3":
			return "storage"
		"cooler_v1", "radiator_v1", "water_tube_v1", "air_duct_v1":
			return "cooling"
		_:
			return "none"

func apply_thermal_metadata(module: BipobModule) -> void:
	if module == null:
		return
	module.cooling_type = "none"
	module.cooling_power = 0
	module.requires_air_intake = false
	module.is_non_volume_cooling_path = false
	if module.placement_type == "external":
		module.internal_role = "none"
	match module.id:
		"battery_v1":
			module.heat_idle = 1; module.heat_active = 1
		"battery_v2":
			module.heat_idle = 2; module.heat_active = 2
		"battery_v3":
			module.heat_idle = 3; module.heat_active = 3
		"processor_v1":
			module.heat_idle = 3; module.heat_active = 3
		"processor_v2":
			module.heat_idle = 4; module.heat_active = 4
		"processor_v3":
			module.heat_idle = 5; module.heat_active = 5
		"gpu_v1":
			module.heat_idle = 3; module.heat_active = 3
		"gpu_v2":
			module.heat_idle = 4; module.heat_active = 4
		"gpu_v3":
			module.heat_idle = 5; module.heat_active = 5
		"memory_v1":
			module.heat_idle = 1; module.heat_active = 1
		"memory_v2":
			module.heat_idle = 2; module.heat_active = 2
		"memory_v3":
			module.heat_idle = 3; module.heat_active = 3
		"hard_drive_v1":
			module.heat_idle = 2; module.heat_active = 2
		"hard_drive_v2":
			module.heat_idle = 3; module.heat_active = 3
		"hard_drive_v3":
			module.heat_idle = 4; module.heat_active = 4
		"power_block_v1":
			module.heat_idle = 1; module.heat_active = 1
		"power_block_v2":
			module.heat_idle = 2; module.heat_active = 2
		"power_block_v3":
			module.heat_idle = 3; module.heat_active = 3
		"charging_via_external_heat_v1", "charging_via_internal_heat_v1":
			module.heat_idle = 2; module.heat_active = 2
		"energy_drain_v1":
			module.heat_idle = 3; module.heat_active = 3
		"charger_v1":
			module.heat_idle = 1; module.heat_active = 1
		"capacitor_bank_v1":
			module.heat_idle = 3; module.heat_active = 3
		"internal_interface_v1", "external_interface_v1":
			module.heat_idle = 1; module.heat_active = 1
		"internal_interface_v2", "external_interface_v2":
			module.heat_idle = 2; module.heat_active = 2
		"internal_interface_v3", "external_interface_v3":
			module.heat_idle = 3; module.heat_active = 3
		"targeting_computer_v1", "encryption_module_v1", "motor_controller_v1", "weapon_controller_v1", "firewall_module_v1", "auto_repair_unit_v1", "sample_analyzer_v1":
			module.heat_idle = 1; module.heat_active = 1
		"cooler_v1":
			module.cooling_power = 2
			module.cooling_type = "air"
			module.requires_air_intake = true
		"radiator_v1":
			module.cooling_power = 1
			module.cooling_type = "passive"
		"water_tube_v1":
			module.cooling_power = 2
			module.cooling_type = "liquid"
			module.is_non_volume_cooling_path = true
		"air_duct_v1":
			module.cooling_power = 1
			module.cooling_type = "duct"
			module.requires_air_intake = true
			module.is_non_volume_cooling_path = true
		"air_intake_v1":
			module.cooling_power = 0
			module.cooling_type = "air"
	module.heat_value = maxi(int(module.heat_value), maxi(int(module.heat_idle), int(module.heat_active)))

func apply_damage_metadata(module: BipobModule) -> void:
	if module == null:
		return
	module.can_be_damaged = true
	module.damage_threshold_heat = 5
	module.repair_complexity = 1
	module.repair_category = "standard"
	match module.id:
		"processor_v1":
			module.repair_complexity = 3
			module.repair_category = "electronics"
		"memory_v1", "memory_v2", "memory_v3", "hard_drive_v1", "hard_drive_v2", "hard_drive_v3", "visor_v1", "visor_v2", "visor_v3":
			module.repair_complexity = 2
			module.repair_category = "electronics"
		"power_block_v1", "power_block_v2", "power_block_v3", "charger_v1":
			module.repair_complexity = 3
			module.repair_category = "power"
		"battery_v1", "battery_v2", "battery_v3":
			module.repair_complexity = 2
			module.repair_category = "power"
		"internal_interface_v1", "external_interface_v1", "interface_v1":
			module.repair_complexity = 2
			module.repair_category = "interface"
		"cooler_v1":
			module.repair_complexity = 2
			module.repair_category = "cooling"
		"radiator_v1", "water_tube_v1", "air_duct_v1", "air_intake_v1":
			module.repair_complexity = 1
			module.repair_category = "cooling"
		"wheels_v1", "legs_v1", "tracks_v1", "manipulator_v1":
			module.repair_complexity = 2
			module.repair_category = "mechanical"

func get_damage_planning_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Damage Preview")
	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("No internal modules placed.")
		lines.append("")
		lines.append("Rules:")
		lines.append("- Heat 5 will later damage devices.")
		lines.append("- Repair is not implemented yet.")
		return "\n".join(lines)
	for module in modules:
		if module == null:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
		var threshold: int = get_module_damage_threshold(module)
		lines.append("- %s: heat %d / overlay %d / threshold %d / %s / repair complexity %d" % [
			get_module_display_name(module),
			preview_heat,
			overlay_heat,
			threshold,
			get_repair_category_display_name(module.repair_category),
			module.repair_complexity
		])
	lines.append("")
	lines.append("Rules:")
	lines.append("- Damage is preview only.")
	lines.append("- No module is broken automatically.")
	lines.append("- Overlay Thermal is hypothetical only.")
	lines.append("- Repair in Box is not implemented yet.")
	return "\n".join(lines)

func get_damage_planning_compact_text() -> String:
	var critical_count: int = 0
	var warning_count: int = 0
	for module in get_unique_internal_modules():
		if module == null:
			continue
		if not module.can_be_damaged:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var threshold: int = get_module_damage_threshold(module)
		if preview_heat >= threshold:
			critical_count += 1
		elif preview_heat == threshold - 1:
			warning_count += 1
	return "Damage Preview: critical %d / warning %d" % [critical_count, warning_count]

func get_damage_preview_critical_count() -> int:
	var critical_count: int = 0
	for module in get_unique_internal_modules():
		if module == null or not module.can_be_damaged:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		if preview_heat >= get_module_damage_threshold(module):
			critical_count += 1
	return critical_count

func get_damage_preview_warning_count() -> int:
	var warning_count: int = 0
	for module in get_unique_internal_modules():
		if module == null or not module.can_be_damaged:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var threshold: int = get_module_damage_threshold(module)
		if preview_heat == threshold - 1:
			warning_count += 1
	return warning_count

func get_constructor_final_audit_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor Final Audit")
	lines.append("Box Storage: %d" % box_storage.size())
	lines.append("Internal Modules: %d" % get_unique_internal_modules().size())
	lines.append("External Modules: %d" % get_unique_external_modules().size())
	var overlay_paths_value: Variant = get("internal_overlay_paths")
	if overlay_paths_value is Array:
		lines.append("Overlay Paths: %d" % overlay_paths_value.size())
	lines.append("Highest Heat: %d" % get_highest_internal_preview_heat())
	lines.append("Damage Preview: critical %d / warning %d" % [
		get_damage_preview_critical_count(),
		get_damage_preview_warning_count()
	])
	lines.append("Consistency Issues: %d" % get_constructor_consistency_issue_count())
	lines.append("Power: %s" % ("OK" if is_virtual_power_available() else "MISSING"))
	lines.append("Internal Data: %s" % ("OK" if is_internal_data_network_available() else "MISSING"))
	lines.append("External Link: %s" % ("OK" if is_external_data_network_available() else "MISSING"))
	lines.append("")
	lines.append("Status:")
	lines.append("- UI-only constructor visuals are active.")
	lines.append("- Overlay thermal effects are hypothetical only.")
	lines.append("- Damage/repair is planning metadata only.")
	lines.append("- Constructor is not gameplay-authoritative yet.")
	lines.append("- Test Build is not implemented.")
	return "\n".join(lines)
func rebuild_internal_modules_by_cell() -> void:
	pass
	
func get_repair_planning_reference_text() -> String:
	var lines: Array[String] = []

	lines.append("Repair Planning Reference")
	lines.append("")
	lines.append("Current status:")
	lines.append("- Damage and repair are planning metadata only.")
	lines.append("- Modules do not break automatically.")
	lines.append("- Repair in Box is not implemented yet.")
	lines.append("- Missions are not blocked by damage preview.")
	lines.append("- Test Build is not implemented yet.")
	lines.append("")
	lines.append("Damage threshold:")
	lines.append("- damage_threshold_heat defines when a module would be at damage risk later.")
	lines.append("- Current default threshold is heat 5.")
	lines.append("- Heat 5 is critical preview.")
	lines.append("- Heat 4 is warning preview when threshold is 5.")
	lines.append("")
	lines.append("Damage preview:")
	lines.append("- Damage preview uses base thermal preview.")
	lines.append("- Overlay Thermal is shown only as hypothetical comparison.")
	lines.append("- Overlay does not reduce real warning/readiness counts.")
	lines.append("")
	lines.append("Repair complexity:")
	lines.append("- 1 = simple repair")
	lines.append("- 2 = normal repair")
	lines.append("- 3 = complex repair")
	lines.append("- Higher values may later require more parts, time, or tools.")
	lines.append("")
	lines.append("Repair categories:")
	lines.append("- Standard: fallback/common repair")
	lines.append("- Electronics: processor, memory, storage, vision electronics")
	lines.append("- Power: batteries, power block")
	lines.append("- Cooling: cooler, radiator, water tube, air duct, air intake")
	lines.append("- Mechanical: wheels, legs, tracks, manipulator")
	lines.append("- Interface: internal/external interfaces")
	lines.append("")
	lines.append("Future direction:")
	lines.append("- Critical heat may later create damaged state.")
	lines.append("- Damaged modules may later be disabled or degraded.")
	lines.append("- Box may later get Repair actions.")
	lines.append("- Repair may later consume resources.")
	lines.append("- Repair may later require specific tools or modules.")
	lines.append("")
	lines.append("Not implemented:")
	lines.append("- No damaged state.")
	lines.append("- No repair action.")
	lines.append("- No repair cost.")
	lines.append("- No repair time.")
	lines.append("- No mission failure from damage.")
	lines.append("- No automatic module disabling.")

	return "\n".join(lines)

func get_repair_planning_compact_reference_text() -> String:
	return "Repair Planning: threshold heat 5, complexity 1-3, metadata only"

func get_module_description_for_id(module_id: String) -> String:
	match module_id:
		"wheels_v1":
			return "Bottom locomotion module for flat terrain."
		"legs_v1":
			return "Bottom locomotion module for stepped terrain."
		"tracks_v1":
			return "Bottom locomotion module for rough terrain."
		"visor_v1":
			return "External vision module."
		"visor_v2":
			return "Improved external vision module with wider scan shape."
		"visor_v3":
			return "Advanced external vision module with the strongest visor scan shape."
		"manipulator_v1":
			return "External manipulation module for physical interactions."
		"interface_v1":
			return "External interface port for connecting external devices to the internal bridge."
		"air_intake_v1":
			return "External air intake required by internal air cooling modules."
		"battery_v1":
			return "Stores a basic amount of energy for movement, tools and other actions."
		"processor_v1":
			return "Internal processing module. Generates more heat under heavy load."
		"processor_v2":
			return "Processor V2 internal processing module. Higher hack performance with moderate heat."
		"processor_v3":
			return "Processor V3 internal processing module. Maximum hack performance with high heat risk."
		"memory_v1":
			return "Stores short-term operational data and increases the number of available actions during a mission."
		"memory_v2":
			return "Expands short-term memory capacity, allowing the robot to process more commands and perform longer action chains."
		"memory_v3":
			return "High-speed memory module for complex builds that require many actions, advanced control, and fast response."
		"hard_drive_v1":
			return "Provides basic digital storage for mission data, downloaded files, access keys, and collected information."
		"hard_drive_v2":
			return "Expands digital storage capacity for longer missions with more data, files, and collected digital items."
		"hard_drive_v3":
			return "High-capacity storage module for complex missions, large data packages, hidden archives, and advanced recovery objectives."
		"battery_v2":
			return "Accumulates an increased volume of energy, enabling the execution of longer missions and the use of enhanced modules."
		"battery_v3":
			return "A high-capacity energy storage unit for demanding builds equipped with heavy sensors, shields, weaponry, or advanced equipment."
		"power_block_v1":
			return "Distributes battery power between internal systems and connected external modules."
		"power_block_v2":
			return "It improves the distribution of power from the battery between internal systems and connected external modules."
		"power_block_v3":
			return "The ultimate power distributor for routing power from the battery to internal and external modules."
		"charger_v1":
			return "Allows batteries to be charged without removing them."
		"capacitor_bank_v1":
			return "Accumulates a short-duration impulse charge to execute powerful actions. An essential component for many advanced modules."
		"internal_interface_v1":
			return "Internal data network."
		"external_interface_v1":
			return "Bridge between internal systems and external modules."
		"cooler_v1":
			return "Active air-cooling unit that removes heat from nearby internal modules. Should external ventilation path."
		"radiator_v1":
			return "Passive cooling block that disperses accumulated heat without consuming additional control resources."
		"targeting_computer_v1":
			return "Calculates firing angles, movement prediction, and weapon correction to improve accuracy with ranged and precision weapons."
		"encryption_module_v1":
			return "Protects internal data channels from hacking, interception, and unauthorized access."
		"motor_controller_v1":
			return "Ensures the coordination of movement commands between core systems and installed equipment modules. Essential for the stable control of jumper and air-cushion-based movement."
		"weapon_controller_v1":
			return "Manages weapon activation, targeting signals, safety locks, and firing commands for complex weapon systems."
		"firewall_module_v1":
			return "Blocks hostile hacking attempts and protects the internal network from remote intrusion."
		"auto_repair_unit_v1":
			return "Performs slow automatic repairs on damaged internal modules using available repair resources."
		"sample_analyzer_v1":
			return "Analyzes collected samples, materials, biological traces, and objects directly inside."
		"water_tube_v1":
			return "Description will be added later."
		"air_duct_v1":
			return "Description will be added later."
		_:
			return ""

func add_internal_mvp_modules_to_box() -> void:
	var internal_specs: Array[Dictionary] = [
		{"id": "battery_v1", "name": "Battery V1", "size": Vector3i(2, 2, 1)},
		{"id": "power_block_v1", "name": "Power Block V1", "size": Vector3i(1, 2, 2)},
		{"id": "power_block_v2", "name": "Power Block V2", "size": Vector3i(1, 2, 2)},
		{"id": "power_block_v3", "name": "Power Block V3", "size": Vector3i(1, 2, 2)},
		{"id": "battery_v2", "name": "Battery V2", "size": Vector3i(2, 2, 1)},
		{"id": "battery_v3", "name": "Battery V3", "size": Vector3i(2, 2, 1)},
		{"id": "capacitor_bank_v1", "name": "Capacitor Bank V1", "size": Vector3i(1, 1, 1)},
		{"id": "charger_v1", "name": "Charger V1", "size": Vector3i(1, 1, 1)},
		{"id": "charging_via_external_heat_v1", "name": "Charging via External Heat V1", "size": Vector3i(1, 1, 2)},
		{"id": "charging_via_internal_heat_v1", "name": "Charging via Internal Heat V1", "size": Vector3i(1, 1, 2)},
		{"id": "energy_drain_v1", "name": "Energy Drain V1", "size": Vector3i(1, 1, 2)},
		{"id": "processor_v1", "name": "Processor V1", "size": Vector3i(1, 1, 1)},
		{"id": "processor_v2", "name": "Processor V2", "size": Vector3i(1, 1, 1)},
		{"id": "processor_v3", "name": "Processor V3", "size": Vector3i(1, 1, 1)},
		{"id": "gpu_v1", "name": "GPU V1", "size": Vector3i(1, 1, 1)},
		{"id": "gpu_v2", "name": "GPU V2", "size": Vector3i(1, 1, 1)},
		{"id": "gpu_v3", "name": "GPU V3", "size": Vector3i(1, 1, 1)},
		{"id": "memory_v1", "name": "Memory V1", "size": Vector3i(1, 1, 2)},
		{"id": "memory_v2", "name": "Memory V2", "size": Vector3i(1, 1, 2)},
		{"id": "memory_v3", "name": "Memory V3", "size": Vector3i(1, 1, 2)},
		{"id": "hard_drive_v1", "name": "Hard Drive V1", "size": Vector3i(2, 2, 1)},
		{"id": "hard_drive_v2", "name": "Hard Drive V2", "size": Vector3i(2, 2, 1)},
		{"id": "hard_drive_v3", "name": "Hard Drive V3", "size": Vector3i(2, 2, 1)},
		{"id": "internal_interface_v1", "name": "Internal Interface V1", "size": Vector3i(1, 1, 1)},
		{"id": "internal_interface_v2", "name": "Internal Interface V2", "size": Vector3i(1, 1, 1)},
		{"id": "internal_interface_v3", "name": "Internal Interface V3", "size": Vector3i(1, 1, 1)},
		{"id": "external_interface_v1", "name": "External Interface V1", "size": Vector3i(2, 2, 1)},
		{"id": "external_interface_v2", "name": "External Interface V2", "size": Vector3i(2, 2, 1)},
		{"id": "external_interface_v3", "name": "External Interface V3", "size": Vector3i(2, 2, 1)},
		{"id": "cooler_v1", "name": "Cooler V1", "size": Vector3i(1, 1, 1)},
		{"id": "radiator_v1", "name": "Radiator V1", "size": Vector3i(1, 1, 1)},
		{"id": "water_tube_v1", "name": "Water Tube V1", "size": Vector3i(0, 0, 0)},
		{"id": "air_duct_v1", "name": "Air Duct V1", "size": Vector3i(0, 0, 0)},
		{"id": "targeting_computer_v1", "name": "Targeting Computer V1", "size": Vector3i(1, 1, 1)},
		{"id": "encryption_module_v1", "name": "Encryption Module V1", "size": Vector3i(1, 1, 1)},
		{"id": "motor_controller_v1", "name": "Motor Controller V1", "size": Vector3i(1, 1, 1)},
		{"id": "weapon_controller_v1", "name": "Weapon Controller V1", "size": Vector3i(1, 1, 1)},
		{"id": "firewall_module_v1", "name": "Firewall Module V1", "size": Vector3i(1, 1, 1)},
		{"id": "auto_repair_unit_v1", "name": "Auto Repair Unit V1", "size": Vector3i(1, 1, 1)},
		{"id": "sample_analyzer_v1", "name": "Sample Analyzer V1", "size": Vector3i(1, 1, 1)}
	]
	for spec in internal_specs:
		var module_id := String(spec.get("id", ""))
		if has_module_id_anywhere(module_id):
			continue
		var module_name := String(spec.get("name", module_id))
		var module_size: Vector3i = spec.get("size", Vector3i.ONE)
		var module: BipobModule = create_internal_module(module_id, module_name, module_size)
		box_storage.append(module)

func create_visor_v2_module() -> BipobModule:
	var module: BipobModule = create_external_module_by_id("visor_v2")
	if module != null:
		return module
	module = BipobModule.new()
	module.id = "visor_v2"
	module.module_id = "visor_v2"
	module.display_name = "Visor V2"
	module.placement_type = "external"
	module.category = "Sensors"
	module.version = "V2"
	module.module_version = 2
	module.internal_role = "none"
	module.description = "Improved external vision module with wider scan shape."
	module.granted_commands = ["vision"]
	module.vision_bonus = 0
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

func create_gpu_v1_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "gpu_v1"
	module.display_name = "GPU V1"
	module.description = "Internal processing module. Increases vision range and supports hidden node detection."
	module.granted_commands = ["hidden_detection_support"]
	module.vision_bonus = 0
	return module

func create_legs_v1_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "legs_v1"
	module.display_name = "Legs V1"
	module.placement_type = "external"
	module.category = "locomotion"
	module.internal_role = "none"
	module.description = "Bottom locomotion module for stepped terrain."
	module.granted_commands = [
		"move_forward",
		"move_backward",
		"turn_left",
		"turn_right",
		"cross_stepped_floor"
	]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

func add_debug_mission4_modules_to_box() -> void:
	var visor_v2_module := create_visor_v2_module()
	if not has_module_id_anywhere(visor_v2_module.id):
		box_storage.append(visor_v2_module)

	var gpu_v1_module := create_gpu_v1_module()
	if not has_module_id_anywhere(gpu_v1_module.id):
		box_storage.append(gpu_v1_module)

	hint_requested.emit("Debug modules added to Box: Visor V2, GPU V1")
	status_changed.emit()


func get_module_display_name(module: BipobModule) -> String:
	if module == null:
		return "Unknown module"

	if not module.display_name.is_empty():
		return module.display_name

	if not module.id.is_empty():
		return module.id

	return "Unnamed module"

func get_module_availability_text(module: BipobModule) -> String:
	if module == null:
		return "Availability: none"

	var box_count: int = get_box_module_count_by_id(module.id)
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		var overlay_count: int = get_overlay_path_count_by_module_id(module.id)
		var overlay_total_count: int = box_count + overlay_count
		return "Availability: box %d / overlay %d / total %d" % [
			box_count,
			overlay_count,
			overlay_total_count
		]
	var external_count: int = get_external_module_count_by_id(module.id)
	var internal_count: int = get_internal_module_count_by_id(module.id)
	var total_count: int = box_count + external_count + internal_count

	return "Availability: box %d / external %d / internal %d / total %d" % [
		box_count,
		external_count,
		internal_count,
		total_count
	]

func get_module_storage_line(module: BipobModule, selected: bool = false) -> String:
	if module == null:
		return ""

	var prefix: String = "> " if selected else "  "
	var display_name: String = get_module_display_name(module)
	var box_count: int = get_box_module_count_by_id(module.id)
	var external_count: int = get_external_module_count_by_id(module.id)
	var internal_count: int = get_internal_module_count_by_id(module.id)

	return "%s%s  [box:%d ext:%d int:%d]" % [
		prefix,
		display_name,
		box_count,
		external_count,
		internal_count
	]

func get_first_module_by_id(module_id: String) -> BipobModule:
	for module in box_storage:
		if module != null and module.id == module_id:
			return module

	for module in get_unique_external_modules():
		if module != null and module.id == module_id:
			return module

	for module in get_unique_internal_modules():
		if module != null and module.id == module_id:
			return module

	return null

func get_module_availability_line_by_id(module_id: String, selected: bool = false) -> String:
	var module: BipobModule = get_first_module_by_id(module_id)
	if module == null:
		return ""

	var prefix: String = "> " if selected else "  "
	var display_name: String = get_module_display_name(module)
	var box_count: int = get_box_module_count_by_id(module_id)
	if module_id == "water_tube_v1" or module_id == "air_duct_v1":
		var overlay_count: int = get_overlay_path_count_by_module_id(module_id)
		return "%s%s  [box:%d overlay:%d]" % [
			prefix,
			display_name,
			box_count,
			overlay_count
		]
	var external_count: int = get_external_module_count_by_id(module_id)
	var internal_count: int = get_internal_module_count_by_id(module_id)

	return "%s%s  [box:%d ext:%d int:%d]" % [
		prefix,
		display_name,
		box_count,
		external_count,
		internal_count
	]

func add_module_to_box_storage(module: BipobModule) -> void:
	if module == null:
		return

	if installed_modules.has(module):
		return

	if box_storage.has(module):
		return

	box_storage.append(module)
	hint_requested.emit("Stored in box: " + get_module_display_name(module))
	status_changed.emit()

func install_module_from_box_storage(storage_index: int) -> bool:
	if storage_index < 0 or storage_index >= box_storage.size():
		hint_requested.emit("No module in that storage slot.")
		status_changed.emit()
		return false

	var module_to_install: BipobModule = box_storage[storage_index]
	if module_to_install == null:
		box_storage.remove_at(storage_index)
		hint_requested.emit("Removed empty module from box storage.")
		status_changed.emit()
		return false
	if is_module_broken(module_to_install):
		hint_requested.emit("Broken module cannot be installed.")
		status_changed.emit()
		return false
	if is_module_unknown(module_to_install):
		hint_requested.emit("Unknown module must be identified first.")
		status_changed.emit()
		return false

	box_storage.remove_at(storage_index)

	if installed_modules.has(module_to_install):
		hint_requested.emit("Module already installed: " + get_module_display_name(module_to_install))
		status_changed.emit()
		return false

	install_module(module_to_install)
	hint_requested.emit("Installed from box: " + get_module_display_name(module_to_install))
	status_changed.emit()
	return true

func is_module_broken(module: BipobModule) -> bool:
	return module != null and module.status == "broken"

func is_module_ready(module: BipobModule) -> bool:
	return module != null and module.status == "ready"

func is_module_unknown(module: BipobModule) -> bool:
	if module == null:
		return false
	return module.status == "unknown"

func is_module_functional(module: BipobModule) -> bool:
	return module != null and not is_module_broken(module) and not is_module_unknown(module)

func set_module_broken(module: BipobModule, value: bool) -> void:
	if module == null:
		return
	module.status = "broken" if value else "ready"
	module.is_broken = value

func identify_unknown_module(module: BipobModule) -> void:
	if module == null:
		return
	if module.status != "unknown":
		return
	module.status = "ready"
	module.is_broken = false

func get_broken_modules_for_repair() -> Array:
	var result: Array = []
	for module in box_storage:
		if is_module_broken(module):
			result.append(module)
	for module in pocket_items:
		if is_module_broken(module) and not result.has(module):
			result.append(module)
	for module in manipulator_items:
		if is_module_broken(module) and not result.has(module):
			result.append(module)
	return result

func get_damaged_bipobs_for_repair() -> Array:
	var result: Array = []
	for profile_id in ["alpha", "beta", "juggernaut"]:
		if is_bipob_damaged(profile_id):
			result.append({
				"profile_id": profile_id,
				"name": _get_bipob_profile_display_name(profile_id),
				"is_damaged": true,
				"current_armor": get_bipob_current_armor(profile_id),
				"max_armor": get_bipob_max_armor(profile_id)
			})
	return result

func repair_module(module: BipobModule) -> void:
	if module == null:
		return
	if not is_module_broken(module):
		return
	module.status = "ready"
	module.is_broken = false
	status_changed.emit()

func repair_bipob(bipob_data: Dictionary) -> void:
	var profile_id: String = String(bipob_data.get("profile_id", ""))
	if profile_id.is_empty():
		return
	set_bipob_current_armor(profile_id, get_bipob_max_armor(profile_id))
	bipob_damage_state_by_profile[profile_id] = false
	status_changed.emit()

func get_bipob_current_armor(profile_id: String = "") -> int:
	var resolved: String = "beta" if profile_id.is_empty() else profile_id
	return int((bipob_armor_state_by_profile.get(resolved, {"current": 20})).get("current", 20))

func get_bipob_max_armor(profile_id: String = "") -> int:
	var resolved: String = "beta" if profile_id.is_empty() else profile_id
	return int((bipob_armor_state_by_profile.get(resolved, {"max": 20})).get("max", 20))

func set_bipob_current_armor(profile_id: String, value: int) -> void:
	var max_armor: int = get_bipob_max_armor(profile_id)
	var state: Dictionary = bipob_armor_state_by_profile.get(profile_id, {"current": max_armor, "max": max_armor})
	state["current"] = clampi(value, 0, max_armor)
	bipob_armor_state_by_profile[profile_id] = state
	bipob_damage_state_by_profile[profile_id] = int(state["current"]) < max_armor

func is_bipob_damaged(profile_id: String) -> bool:
	return get_bipob_current_armor(profile_id) < get_bipob_max_armor(profile_id)

func _get_bipob_profile_display_name(profile_id: String) -> String:
	match profile_id:
		"alpha":
			return "Scout"
		"beta":
			return "Engineer"
		"juggernaut":
			return "Juggernaut"
		_:
			return profile_id.capitalize()

func return_installed_module_to_box_storage(module: BipobModule) -> void:
	if module == null:
		return

	var installed_index := installed_modules.find(module)
	if installed_index == -1:
		return

	installed_modules.remove_at(installed_index)

	if not box_storage.has(module):
		box_storage.append(module)

	recalculate_module_stats()
	status_changed.emit()

func remove_last_installed_module_to_box() -> bool:
	if installed_modules.is_empty():
		hint_requested.emit("No installed modules to remove.")
		status_changed.emit()
		return false

	var module_to_remove: BipobModule = installed_modules[installed_modules.size() - 1]
	if module_to_remove == null:
		installed_modules.remove_at(installed_modules.size() - 1)
		hint_requested.emit("Removed empty module slot.")
		status_changed.emit()
		return false

	installed_modules.remove_at(installed_modules.size() - 1)

	if not box_storage.has(module_to_remove):
		box_storage.append(module_to_remove)

	recalculate_module_stats()

	hint_requested.emit("Removed module to box: " + get_module_display_name(module_to_remove))
	status_changed.emit()
	return true

func remove_installed_module_to_box_by_index(module_index: int) -> bool:
	if module_index < 0 or module_index >= installed_modules.size():
		hint_requested.emit("No installed module in that slot.")
		status_changed.emit()
		return false

	var module_to_remove: BipobModule = installed_modules[module_index]
	if module_to_remove == null:
		installed_modules.remove_at(module_index)
		hint_requested.emit("Removed empty module slot.")
		status_changed.emit()
		return false

	installed_modules.remove_at(module_index)

	if not box_storage.has(module_to_remove):
		box_storage.append(module_to_remove)

	recalculate_module_stats()

	hint_requested.emit("Removed module to box: " + get_module_display_name(module_to_remove))
	status_changed.emit()
	return true

func set_found_module(module: BipobModule) -> void:
	found_module = module
	status_changed.emit()

func create_debug_found_module() -> void:
	var module := BipobModule.new()
	module.id = "battery_v1"
	module.display_name = "Battery V1"
	module.description = "Increases max energy by 10."
	module.energy_bonus = 10
	module.granted_commands = []
	found_module = module
	hint_requested.emit("Found module: " + module.display_name)
	status_changed.emit()

func install_found_module() -> bool:
	if found_module == null:
		print("No module to install.")
		hint_requested.emit("No module to install.")
		return false

	var module_to_install := found_module
	install_module(module_to_install)
	found_module = null
	print("Installed module: ", get_module_display_name(module_to_install))
	hint_requested.emit("Installed module: " + get_module_display_name(module_to_install))
	status_changed.emit()
	return true

func install_available_module() -> bool:
	if not box_storage.is_empty():
		return install_module_from_box_storage(0)

	if found_module != null:
		return install_found_module()

	hint_requested.emit("No module to install.")
	status_changed.emit()
	return false

func require_command(command_id: String, missing_message: String) -> bool:
	if has_command(command_id):
		return true

	print("Missing command: ", command_id, " | ", missing_message)
	hint_requested.emit(missing_message)
	return false

func setup_body() -> void:
	if top_face == null or left_face == null or right_face == null or front_accent == null:
		return

	top_face.polygon = PackedVector2Array([
		Vector2(0, -14),
		Vector2(10, -4),
		Vector2(0, 6),
		Vector2(-10, -4),
	])
	top_face.color = Color(0.2, 0.92, 0.9)
	left_face.polygon = PackedVector2Array([
		Vector2(-10, -4),
		Vector2(0, 6),
		Vector2(0, 16),
		Vector2(-10, 6),
	])
	left_face.color = Color(0.07, 0.42, 0.49)
	right_face.polygon = PackedVector2Array([
		Vector2(10, -4),
		Vector2(0, 6),
		Vector2(0, 16),
		Vector2(10, 6),
	])
	right_face.color = Color(0.11, 0.57, 0.64)
	front_accent.polygon = PackedVector2Array([
		Vector2(0, -19),
		Vector2(4, -13),
		Vector2(0, -11),
		Vector2(-4, -13),
	])
	front_accent.color = Color(0.55, 0.99, 0.97)
	if base_shadow != null:
		base_shadow.polygon = PackedVector2Array([
			Vector2(0, 13),
			Vector2(9, 17),
			Vector2(0, 20),
			Vector2(-9, 17),
		])
		base_shadow.color = Color(0.0, 0.0, 0.0, 0.2)

func _unhandled_input(event: InputEvent) -> void:
	if mission_finished:
		return
	if map_constructor_input_blocked:
		return
	
	if event.is_action_pressed("end_turn"):
		end_turn()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("cycle_world_action"):
		cycle_selected_world_action()
		return


func is_cell_under_fog(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.is_in_bounds(cell):
		return true
	if grid_manager.has_method("is_fog_enabled") and not bool(grid_manager.call("is_fog_enabled")):
		return false
	if grid_manager.has_method("is_explored"):
		return not bool(grid_manager.call("is_explored", cell))
	return false

func is_cell_visible_to_bipob(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.is_in_bounds(cell):
		return false
	if grid_manager.has_method("is_cell_visible"):
		return bool(grid_manager.call("is_cell_visible", cell))
	return false

func _get_world_object_at_cell(cell: Vector2i) -> Dictionary:
	if mission_manager == null:
		return {}
	return Dictionary(mission_manager.get_world_object_at_cell(cell))


func _get_runtime_passability_state(cell: Vector2i) -> Dictionary:
	if mission_manager == null:
		return {}
	if mission_manager.has_method("get_runtime_cell_state"):
		return Dictionary(mission_manager.call("get_runtime_cell_state", cell))
	return {}

func _is_runtime_cell_passable(cell: Vector2i) -> bool:
	if mission_manager != null and mission_manager.has_method("is_runtime_cell_passable"):
		return bool(mission_manager.call("is_runtime_cell_passable", cell))
	return false

func _get_runtime_cell_block_reason(cell: Vector2i) -> String:
	if mission_manager != null and mission_manager.has_method("get_runtime_cell_block_reason"):
		return String(mission_manager.call("get_runtime_cell_block_reason", cell))
	return ""

func is_runtime_door_cell_passable(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.is_in_bounds(cell):
		return false
	var tile_type: int = grid_manager.get_tile(cell)
	if tile_type != GridManager.TILE_DOOR and tile_type != GridManager.TILE_DIGITAL_DOOR and tile_type != GridManager.TILE_POWERED_GATE:
		return false
	var object_data: Dictionary = _get_world_object_at_cell(cell)
	if object_data.is_empty():
		return false
	var state: String = String(object_data.get("state", "")).to_lower()
	var is_open_flag: bool = bool(object_data.get("is_open", false))
	var is_open_state: bool = state == "open" or state == "opened"
	var access_state := {}
	if mission_manager != null and mission_manager.has_method("get_door_access_state"):
		access_state = Dictionary(mission_manager.call("get_door_access_state", String(object_data.get("id", ""))))
	var access_open: bool = bool(access_state.get("is_open", false)) or bool(access_state.get("can_open", false))
	var is_explicitly_open: bool = is_open_flag or is_open_state or access_open
	if state == "closed" or state == "locked" or state == "unpowered" or state == "damaged" or state == "broken" or state == "destroyed":
		return false
	if is_explicitly_open:
		return true
	if bool(object_data.get("is_locked", false)) or bool(object_data.get("locked", false)):
		return false
	if bool(object_data.get("blocks_movement", false)):
		return false
	return false

func is_cell_walkable_for_bipob(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.is_in_bounds(cell):
		return false
	if mission_manager != null and mission_manager.has_method("is_runtime_cell_passable"):
		return _is_runtime_cell_passable(cell)
	if grid_manager.is_walkable(cell):
		var object_data: Dictionary = _get_world_object_at_cell(cell)
		if not object_data.is_empty() and bool(object_data.get("blocks_movement", false)):
			return false
		return true
	return is_runtime_door_cell_passable(cell)

func _get_grid_tile_display_name(tile_type: int) -> String:
	if grid_manager == null:
		return "unknown"

	match tile_type:
		GridManager.TILE_FLOOR:
			return "floor"
		GridManager.TILE_WALL:
			return "wall"
		GridManager.TILE_DOOR:
			return "door"
		GridManager.TILE_KEY:
			return "key"
		GridManager.TILE_EXIT:
			return "exit"
		GridManager.TILE_TERMINAL:
			return "terminal"
		GridManager.TILE_DIGITAL_DOOR:
			return "digital door"
		GridManager.TILE_COMPONENT:
			return "component"
		GridManager.TILE_HIDDEN_ROUTE_NODE:
			return "hidden route node"
		GridManager.TILE_ROUTE_GATE:
			return "route gate"
		GridManager.TILE_HOT_NODE:
			return "hot node"
		GridManager.TILE_AIRFLOW_TERMINAL:
			return "airflow terminal"
		GridManager.TILE_FAN_PLATFORM:
			return "fan platform"
		GridManager.TILE_PLATFORM_CONTROL:
			return "platform control"
		GridManager.TILE_FAN_CONTROL:
			return "fan control"
		GridManager.TILE_AIRFLOW:
			return "airflow"
		GridManager.TILE_PLATFORM_CONTROL_LEFT:
			return "platform control left"
		GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			return "platform control right"
		GridManager.TILE_FAN_SPEED_UP_CONTROL:
			return "fan speed up control"
		GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			return "fan speed down control"
		GridManager.TILE_CABLE_REEL:
			return "cable reel"
		GridManager.TILE_SOCKET:
			return "socket"
		GridManager.TILE_POWERED_GATE:
			return "powered gate"
		GridManager.TILE_CABLE:
			return "cable"
		GridManager.TILE_STEPPED_FLOOR:
			return "stepped floor"
		_:
			return "tile %d" % tile_type

func get_cell_basic_composition_text(cell: Vector2i) -> String:
	if is_cell_under_fog(cell):
		return "Unknown cell."
	var parts: Array[String] = []
	var tile_type: int = grid_manager.get_tile(cell)
	parts.append(_get_grid_tile_display_name(tile_type).to_lower())
	var object_data: Dictionary = _get_world_object_at_cell(cell)
	if not object_data.is_empty():
		parts.append("object: %s" % String(object_data.get("display_name", "object")))
	if mission_manager != null and mission_manager.has_method("get_items_at_cell"):
		var items_variant: Variant = mission_manager.call("get_items_at_cell", cell)
		if typeof(items_variant) == TYPE_ARRAY:
			var item_count: int = (items_variant as Array).size()
			if item_count > 0:
				parts.append("items: %d" % item_count)
	return "Cell %s: %s." % [str(cell), ", ".join(parts)]

func get_cell_visible_info_text(cell: Vector2i) -> String:
	var base_text: String = get_cell_basic_composition_text(cell)
	if not is_cell_visible_to_bipob(cell):
		return base_text
	var object_data: Dictionary = _get_world_object_at_cell(cell)
	if object_data.is_empty():
		return base_text
	var info_parts: Array[String] = []
	info_parts.append("name=%s" % String(object_data.get("display_name", "object")))
	info_parts.append("group=%s" % String(object_data.get("object_group", "unknown")))
	info_parts.append("type=%s" % String(object_data.get("object_type", "unknown")))
	info_parts.append("state=%s" % String(object_data.get("state", "unknown")))
	info_parts.append("blocks=%s" % str(bool(object_data.get("blocks_movement", false))))
	if object_data.has("is_locked"):
		info_parts.append("locked=%s" % str(bool(object_data.get("is_locked", false))))
	if object_data.has("is_powered"):
		info_parts.append("powered=%s" % str(bool(object_data.get("is_powered", false))))
	return "%s | %s" % [base_text, ", ".join(info_parts)]

func get_cell_scanned_info_text(cell: Vector2i) -> String:
	var text: String = get_cell_visible_info_text(cell)
	var object_data: Dictionary = _get_world_object_at_cell(cell)
	if object_data.is_empty():
		return text
	var scan_level: int = int(object_data.get("scan_level", 0))
	var revealed_hidden: bool = bool(object_data.get("revealed_hidden_content", false))
	if scan_level <= 0 and not revealed_hidden:
		return text
	var details: Array[String] = ["scan_level=%d" % scan_level]
	for key_name in ["damaged", "broken", "destroyed"]:
		if object_data.has(key_name):
			details.append("%s=%s" % [key_name, str(bool(object_data.get(key_name, false)))])
	if object_data.has("power_network_id") and (scan_level > 0 or bool(object_data.get("power_network_revealed", false))):
		details.append("power_network_id=%s" % String(object_data.get("power_network_id", "")))
	if object_data.has("lock_type") and (scan_level > 0 or bool(object_data.get("lock_revealed", false))):
		details.append("lock_type=%s" % String(object_data.get("lock_type", "")))
	return "%s | %s" % [text, ", ".join(details)]

func get_selected_cell_info_text(cell: Vector2i) -> String:
	if is_cell_under_fog(cell):
		return "Unknown area. Cell is under fog of war."
	if not is_cell_visible_to_bipob(cell):
		return get_cell_basic_composition_text(cell)
	var object_data: Dictionary = _get_world_object_at_cell(cell)
	if not object_data.is_empty() and (int(object_data.get("scan_level", 0)) > 0 or bool(object_data.get("revealed_hidden_content", false))):
		return get_cell_scanned_info_text(cell)
	return get_cell_visible_info_text(cell)

func is_mouse_route_target_cell(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.is_in_bounds(cell) or is_cell_under_fog(cell):
		return false
	if not is_cell_walkable_for_bipob(cell):
		return false
	return true

func build_mouse_route_to_cell(target_cell: Vector2i) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	if grid_manager == null or not grid_manager.is_in_bounds(target_cell):
		return route
	var start_cell: Vector2i = grid_position
	if start_cell == target_cell:
		return route
	var queue: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: start_cell}
	var offsets: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == target_cell:
			break
		for delta in offsets:
			var nxt: Vector2i = current + delta
			if came_from.has(nxt):
				continue
			if not grid_manager.is_in_bounds(nxt) or is_cell_under_fog(nxt) or not is_cell_walkable_for_bipob(nxt):
				continue
			came_from[nxt] = current
			queue.append(nxt)
	if not came_from.has(target_cell):
		return []
	var cursor: Vector2i = target_cell
	while cursor != start_cell:
		route.push_front(cursor)
		cursor = came_from[cursor]
	return route

func set_selected_route(target_cell: Vector2i, route_cells: Array) -> void:
	selected_route_target_cell = target_cell
	selected_route_cells.clear()
	for route_cell_variant in route_cells:
		if route_cell_variant is Vector2i:
			selected_route_cells.append(route_cell_variant)
	if selected_route_cells.is_empty():
		hint_requested.emit("No route to selected cell.")
	else:
		hint_requested.emit("Route selected: %d steps." % selected_route_cells.size())
	status_changed.emit()

func clear_selected_route() -> void:
	selected_route_target_cell = Vector2i(-1, -1)
	selected_route_cells.clear()

func handle_grid_cell_left_click(cell: Vector2i) -> void:
	if mission_finished or grid_manager == null:
		return
	if not grid_manager.is_in_bounds(cell):
		hint_requested.emit("Invalid cell.")
		return
	selected_grid_cell = cell
	if is_cell_under_fog(cell):
		clear_selected_route()
		hint_requested.emit("Unknown area. Cell is under fog of war.")
		refresh_world_action_panel()
		status_changed.emit()
		return

	var cell_info_text: String = get_selected_cell_info_text(cell)
	hint_requested.emit(cell_info_text)

	var is_route_target: bool = is_mouse_route_target_cell(cell)
	if not is_route_target:
		clear_selected_route()
		refresh_world_action_panel()
		status_changed.emit()
		return

	if selected_route_target_cell == cell and not selected_route_cells.is_empty():
		execute_selected_mouse_route()
		return

	var route_cells: Array[Vector2i] = build_mouse_route_to_cell(cell)
	set_selected_route(cell, route_cells)
	hint_requested.emit(cell_info_text)
	refresh_world_action_panel()
	status_changed.emit()

func start_selected_mouse_route_execution() -> void:
	if mouse_route_execution_in_progress:
		return
	if selected_route_cells.is_empty():
		hint_requested.emit("No selected route.")
		return
	pending_mouse_route_cells.clear()
	for route_cell in selected_route_cells:
		pending_mouse_route_cells.append(route_cell)
	mouse_route_execution_in_progress = true
	execute_next_mouse_route_step()

func execute_next_mouse_route_step() -> void:
	if not mouse_route_execution_in_progress:
		return
	if pending_mouse_route_cells.is_empty():
		mouse_route_execution_in_progress = false
		clear_selected_route()
		refresh_world_action_panel()
		status_changed.emit()
		return
	if actions_left <= 0:
		mouse_route_execution_in_progress = false
		hint_requested.emit("Movement stopped: no actions remaining.")
		selected_route_cells.clear()
		for route_cell in pending_mouse_route_cells:
			selected_route_cells.append(route_cell)
		refresh_world_action_panel()
		status_changed.emit()
		return

	var next_cell: Vector2i = pending_mouse_route_cells[0]
	if not grid_manager.is_in_bounds(next_cell) or is_cell_under_fog(next_cell) or not is_cell_walkable_for_bipob(next_cell):
		mouse_route_execution_in_progress = false
		var runtime_block_reason: String = _get_runtime_cell_block_reason(next_cell)
		if runtime_block_reason.is_empty():
			hint_requested.emit("Movement stopped: route is blocked.")
		else:
			hint_requested.emit("Movement stopped: %s." % runtime_block_reason)
		selected_route_cells.clear()
		for route_cell in pending_mouse_route_cells:
			selected_route_cells.append(route_cell)
		refresh_world_action_panel()
		status_changed.emit()
		return

	var delta: Vector2i = next_cell - grid_position
	if delta == Vector2i.UP:
		direction = Direction.NORTH
	elif delta == Vector2i.RIGHT:
		direction = Direction.EAST
	elif delta == Vector2i.DOWN:
		direction = Direction.SOUTH
	elif delta == Vector2i.LEFT:
		direction = Direction.WEST
	update_visual_facing()

	if not try_move_to(next_cell):
		mouse_route_execution_in_progress = false
		hint_requested.emit("Movement stopped: unable to move to next cell.")
		selected_route_cells.clear()
		for route_cell in pending_mouse_route_cells:
			selected_route_cells.append(route_cell)
		refresh_world_action_panel()
		status_changed.emit()
		return

	spend_action(1, 0)
	register_successful_movement_cells(1, get_surface_id_for_position(next_cell), next_cell)
	pending_mouse_route_cells.remove_at(0)
	selected_route_cells.clear()
	for route_cell in pending_mouse_route_cells:
		selected_route_cells.append(route_cell)
	update_vision()
	update_threat_detection_preview()
	refresh_world_action_panel()
	status_changed.emit()

	if pending_mouse_route_cells.is_empty():
		mouse_route_execution_in_progress = false
		clear_selected_route()
		refresh_world_action_panel()
		status_changed.emit()
		return

	await get_tree().create_timer(0.1).timeout
	execute_next_mouse_route_step()

func handle_grid_cell_right_click(cell: Vector2i) -> void:
	selected_grid_cell = Vector2i(-1, -1)
	clear_selected_route()
	refresh_world_action_panel()
	status_changed.emit()
	if cell.x >= -1:
		hint_requested.emit("Selection cleared.")

func execute_selected_mouse_route() -> void:
	start_selected_mouse_route_execution()

func move_forward() -> void:
	if not require_command("move_forward", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 0):
		return
	
	var target_position := grid_position + get_direction_vector(direction)
	
	if try_move_to(target_position):
		spend_action(1, 0)
		register_successful_movement_cells(1, get_surface_id_for_position(target_position), target_position)

func move_backward() -> void:
	if not require_command("move_backward", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 0):
		return
	
	var target_position := grid_position - get_direction_vector(direction)
	
	if try_move_to(target_position):
		spend_action(1, 0)
		register_successful_movement_cells(1, get_surface_id_for_position(target_position), target_position)

func turn_left() -> void:
	if not require_command("turn_left", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 0):
		return
	
	direction = Direction.values()[(int(direction) + 3) % 4]
	update_visual_facing()
	update_vision()
	update_threat_detection_preview()
	spend_action(1, 0)

func turn_right() -> void:
	if not require_command("turn_right", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 0):
		return
	
	direction = Direction.values()[(int(direction) + 1) % 4]
	update_visual_facing()
	update_vision()
	update_threat_detection_preview()
	spend_action(1, 0)

func end_turn() -> void:
	if mission_manager != null:
		mission_manager.reset_world_object_turn_flags()
	actions_left = actions_per_turn
	turns_used += 1
	update_threat_detection_preview()
	print("End Turn. Actions restored.")
	print_status()
	status_changed.emit()

func get_turns_used() -> int:
	return maxi(0, turns_used)

func get_turn_limit() -> int:
	return 30

func can_spend_action(action_cost: int, energy_cost: int) -> bool:
	if actions_left < action_cost:
		print("Not enough actions. Press Space to end turn.")
		hint_requested.emit("No actions left. Press Space to end turn.")
		return false
	
	if energy < energy_cost:
		print("Not enough energy.")
		hint_requested.emit("Not enough energy. Return to the box and use Charge.")
		return false
	
	return true


func spend_action(action_cost: int, energy_cost: int) -> void:
	actions_left -= action_cost
	energy -= energy_cost
	
	print_status()
	status_changed.emit()
	
	if energy <= 0:
		print("Energy depleted. Mission failed.")
		mission_failed.emit()

func try_move_to(target_position: Vector2i) -> bool:
	if has_power_source() and not has_power_block():
		hint_requested.emit("Power Block broken. Restart mission or evacuate if possible.")
		status_changed.emit()
		return false
	if grid_manager == null:
		push_error("BipobController: grid_manager is null")
		return false
	
	var target_tile := grid_manager.get_tile(target_position)
	var target_surface_id: String = get_surface_id_for_tile(target_tile)
	var active_gear: BipobModule = get_active_gear_module()
	if active_gear == null:
		hint_requested.emit("Missing module: Wheels V1 required.")
		status_changed.emit()
		return false
	if not can_gear_move_on_surface(active_gear, target_surface_id):
		hint_requested.emit("Current gear cannot move on this surface.")
		status_changed.emit()
		return false

	if not is_cell_walkable_for_bipob(target_position):
		var runtime_block_reason: String = _get_runtime_cell_block_reason(target_position)
		if target_tile == GridManager.TILE_WALL:
			hint_requested.emit("Blocked by wall.")
		elif target_tile == GridManager.TILE_DOOR:
			if is_runtime_door_cell_passable(target_position):
				pass
			else:
				hint_requested.emit("Door is closed.")
		elif target_tile == GridManager.TILE_DIGITAL_DOOR:
			if is_runtime_door_cell_passable(target_position):
				pass
			else:
				hint_requested.emit("Digital door is closed.")
		elif target_tile == GridManager.TILE_HOT_NODE:
			hint_requested.emit("Hot Node blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_AIRFLOW_TERMINAL:
			hint_requested.emit("Terminal blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_FAN_PLATFORM:
			hint_requested.emit("Fan platform blocks the path. Use controls to rotate airflow.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_LEFT:
			hint_requested.emit("Use Interact to rotate fan platform left.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			hint_requested.emit("Use Interact to rotate fan platform right.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL:
			hint_requested.emit("Use Interact to rotate the fan platform.")
		elif target_tile == GridManager.TILE_FAN_CONTROL:
			hint_requested.emit("Use Interact to change fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_UP_CONTROL:
			hint_requested.emit("Use Interact to increase fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			hint_requested.emit("Use Interact to decrease fan speed.")
		elif target_tile == GridManager.TILE_POWERED_GATE:
			if is_runtime_door_cell_passable(target_position):
				pass
			else:
				hint_requested.emit("Powered gate is closed.")
		elif target_tile == GridManager.TILE_CABLE_REEL:
			hint_requested.emit("Cable reel. Use Interact to take the cable end.")
		elif target_tile == GridManager.TILE_SOCKET:
			hint_requested.emit("Socket. Bring the cable end here and use Interact.")
		else:
			if runtime_block_reason.is_empty():
				hint_requested.emit("Path is blocked.")
			else:
				hint_requested.emit("Blocked: %s." % runtime_block_reason)

		print("Blocked: ", target_position)
		return false

	if mission_manager != null:
		if mission_manager.has_method("can_move_between_height_levels"):
			var can_move_height_variant: Variant = mission_manager.call("can_move_between_height_levels", grid_position, target_position, self)
			if not bool(can_move_height_variant):
				hint_requested.emit("Height mismatch.")
				return false
		var blocking_obj: Dictionary = Dictionary(mission_manager.get_world_object_at_cell(target_position))
		if not blocking_obj.is_empty() and bool(blocking_obj.get("blocks_movement", false)) and not is_cell_walkable_for_bipob(target_position):
			hint_requested.emit("Blocked by %s." % blocking_obj.get("display_name", "object"))
			return false
	
	grid_position = target_position
	refresh_platform_height_state_after_move()
	clear_selected_world_action_if_invalid({}, target_position)
	update_world_position()
	if current_mission_index == 7 and mission7_is_dragging_cable:
		add_current_cell_to_mission7_cable_path()
	_register_successful_player_action()
	check_mission_complete()
	return true

func _register_successful_player_action() -> void:
	player_action_index += 1
	if mission_manager == null:
		return
	if not mission_manager.has_method("process_platform_turn_tick_once"):
		return
	var messages_variant: Variant = mission_manager.call("process_platform_turn_tick_once", player_action_index)
	if typeof(messages_variant) != TYPE_ARRAY:
		return
	for message_variant in messages_variant:
		var message := String(message_variant).strip_edges()
		if message.is_empty():
			continue
		hint_requested.emit(message)

func _register_successful_paid_player_action(action_spent: bool) -> void:
	if not action_spent:
		return
	_register_successful_player_action()

func get_player_action_index() -> int:
	return player_action_index

func set_platform_height_level(level: int, platform_id: String = "") -> void:
	platform_height_level = level
	carried_by_platform_id = platform_id

func refresh_platform_height_state_after_move() -> void:
	if mission_manager == null:
		platform_height_level = 0
		carried_by_platform_id = ""
		return

	var platform: Dictionary = {}
	if mission_manager.has_method("get_platform_for_cell"):
		var platform_variant: Variant = mission_manager.call("get_platform_for_cell", grid_position)
		if platform_variant is Dictionary:
			platform = platform_variant

	if not platform.is_empty() and String(platform.get("platform_type", "")) == "lifting":
		platform_height_level = int(platform.get("height_level", 0))
		carried_by_platform_id = String(platform.get("platform_id", ""))
		return

	if mission_manager.has_method("get_cell_height_level"):
		platform_height_level = int(mission_manager.call("get_cell_height_level", grid_position))
	else:
		platform_height_level = 0
	carried_by_platform_id = ""

func get_platform_height_level() -> int:
	return platform_height_level

func get_carried_by_platform_id() -> String:
	return carried_by_platform_id

func get_platform_height_debug_info() -> Dictionary:
	return {
		"platform_height_level": platform_height_level,
		"carried_by_platform_id": carried_by_platform_id
	}

func get_active_gear_module() -> BipobModule:
	for module in installed_modules:
		if module == null or module.placement_type != "external":
			continue
		if String(module.category).to_lower() == "gear":
			return module
	return null

func get_gear_energy_cost() -> int:
	var gear := get_active_gear_module()
	return gear.energy_cost if gear != null else 0

func get_gear_base_speed() -> int:
	var gear := get_active_gear_module()
	return gear.gear_speed if gear != null and gear.gear_speed > 0 else 1

func get_surface_id_for_position(cell_position: Vector2i) -> String:
	if grid_manager == null:
		return "flat"
	return get_surface_id_for_tile(grid_manager.get_tile(cell_position))

func get_surface_id_for_tile(tile_id: int) -> String:
	if tile_id == GridManager.TILE_STEPPED_FLOOR:
		return "mud"
	return "flat"

func can_gear_move_on_surface(gear: BipobModule, surface_id: String) -> bool:
	if gear == null:
		return false
	if String(gear.terrain_type).to_lower() == "any surface":
		return true
	return surface_id == "flat"

func get_effective_gear_speed_for_surface(gear: BipobModule, surface_id: String, terrain_modifier: int = 0) -> int:
	if gear == null:
		return 1
	var speed := maxi(1, gear.gear_speed)
	if gear.ignore_terrain_debuff:
		return speed
	if surface_id == "mud":
		speed -= 1
	elif surface_id == "water":
		speed -= 2
	speed += terrain_modifier
	return maxi(1, speed)

func get_floor_movement_modifier_for_position(cell_position: Vector2i, gear: BipobModule) -> int:
	if grid_manager == null:
		return 0
	if not grid_manager.has_method("get_floor_movement_modifier_for_gear"):
		return 0
	return int(grid_manager.call("get_floor_movement_modifier_for_gear", cell_position, gear))

func register_successful_movement_cells(cell_count: int, surface_id: String, cell_position: Vector2i = Vector2i(-1, -1)) -> void:
	if cell_count <= 0:
		return
	var gear := get_active_gear_module()
	if gear == null:
		return
	var terrain_modifier: int = get_floor_movement_modifier_for_position(cell_position, gear)
	var effective_speed: int = get_effective_gear_speed_for_surface(gear, surface_id, terrain_modifier)
	movement_cells_since_energy_spend += cell_count
	var spend_intervals: int = floori(float(movement_cells_since_energy_spend) / float(effective_speed))
	if spend_intervals <= 0:
		return
	var energy_to_spend: int = spend_intervals * maxi(0, gear.energy_cost)
	movement_cells_since_energy_spend = movement_cells_since_energy_spend % effective_speed
	if energy_to_spend > 0:
		energy = maxi(0, energy - energy_to_spend)
		print_status()
		status_changed.emit()
		if energy <= 0:
			print("Energy depleted. Mission failed.")
			mission_failed.emit()
	
func check_mission_complete() -> void:
	var current_tile := grid_manager.get_tile(grid_position)
	
	if current_tile == GridManager.TILE_EXIT:
		if current_mission_index == 4 and not mission4_hidden_route_node_discovered:
			hint_requested.emit("Exit route is incomplete. Find the hidden route-node first.")
			status_changed.emit()
			return
		complete_mission()

func complete_mission() -> void:
	if mission_finished:
		return
	
	mission_finished = true
	var stored_module_this_mission := false
	if held_module != null:
		add_module_to_box_storage(held_module)
		held_module = null
		stored_module_this_mission = true
	if stored_physical_module != null:
		add_module_to_box_storage(stored_physical_module)
		stored_physical_module = null
		stored_module_this_mission = true
	
	if mission_label != null:
		mission_label.text = "MISSION COMPLETE"
	
	print("MISSION COMPLETE")
	print("Bipob reached the exit.")
	if current_mission_index == 1:
		hint_requested.emit("Mission 1 complete. Return to the box, then start Mission 2.")
	elif current_mission_index == 2:
		hint_requested.emit("Mission 2 complete. Return to the box, then start Mission 3.")
	elif current_mission_index == 3:
		hint_requested.emit("Mission 3 complete. Return to the box, then start Mission 4.")
	elif current_mission_index == 4:
		hint_requested.emit("Mission 4 complete. Return to the box, then start Mission 5.")
	elif current_mission_index == 5:
		hint_requested.emit("Mission 5 complete. Return to the box, then start Mission 6.")
	elif current_mission_index == 6:
		hint_requested.emit("Mission 6 complete. Return to the box, then start Mission 7.")
	elif current_mission_index == 7:
		hint_requested.emit("Mission 7 complete. Return to the box, then start Mission 8.")
	elif current_mission_index == 8:
		hint_requested.emit("Mission 8 complete. Return to the box, then start Mission 9.")
	elif current_mission_index == 9:
		hint_requested.emit("Mission 9 complete. Return to the box, then start TASK TEST.")
	elif current_mission_index == 10:
		hint_requested.emit("TASK TEST complete. Extraction confirmed. Return to the box.")
	else:
		hint_requested.emit("Mission complete. Return to the box.")
	if current_mission_index == max_mission_index:
		sector_completed = true
		last_diagnostic_result = null

	if stored_module_this_mission:
		found_module = null
	else:
		create_debug_found_module()
	status_changed.emit()
	mission_completed.emit()
			

func setup_mission9() -> void:
	if grid_manager == null:
		return

	var module_position := Vector2i(3, 1)
	if not grid_manager.is_in_bounds(module_position):
		return

	if has_module_id_anywhere("legs_v1"):
		grid_manager.set_tile(module_position, GridManager.TILE_FLOOR)
		field_modules_by_position.erase(module_position)
		return

	grid_manager.set_tile(module_position, GridManager.TILE_COMPONENT)
	set_field_module(module_position, create_legs_v1_module())

func get_room_visual_renderer() -> RoomVisualRenderer:
	if grid_manager == null:
		return null
	var renderer_node: Node = grid_manager.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null:
		return null
	if renderer_node is RoomVisualRenderer:
		return renderer_node
	return null

func should_use_isometric_visual_position() -> bool:
	if use_isometric_visual_position:
		return true
	var room_visual_renderer: RoomVisualRenderer = get_room_visual_renderer()
	if room_visual_renderer == null:
		return false
	if room_visual_renderer.has_method("should_preview_drive_bipob_visual_position"):
		return bool(room_visual_renderer.call("should_preview_drive_bipob_visual_position"))
	return false

func get_square_world_position_for_grid_cell_as_parent_local(cell: Vector2i) -> Vector2:
	if grid_manager == null:
		return Vector2.ZERO

	var square_local: Vector2 = grid_manager.grid_to_world(cell)
	var square_global: Vector2 = grid_manager.global_position + square_local
	var parent_node: Node = get_parent()

	if parent_node != null and parent_node is Node2D:
		return (parent_node as Node2D).to_local(square_global)

	return square_global

func get_isometric_world_position_for_grid_cell(cell: Vector2i) -> Vector2:
	if grid_manager == null:
		return Vector2.ZERO
	var fallback_position: Vector2 = get_square_world_position_for_grid_cell_as_parent_local(cell)
	var room_visual_renderer: RoomVisualRenderer = get_room_visual_renderer()
	if room_visual_renderer == null:
		return fallback_position
	var iso_local: Vector2 = room_visual_renderer.grid_to_iso(cell)
	var iso_global: Vector2 = room_visual_renderer.to_global(iso_local)
	var parent_node: Node = get_parent()
	var final_parent_local: Vector2 = iso_global
	if parent_node != null and parent_node is Node2D:
		final_parent_local = (parent_node as Node2D).to_local(iso_global)
	return final_parent_local + Vector2(0.0, isometric_visual_y_offset)

func get_visual_world_position_for_grid_cell(cell: Vector2i) -> Vector2:
	if grid_manager == null:
		return Vector2.ZERO
	if should_use_isometric_visual_position():
		return get_isometric_world_position_for_grid_cell(cell)
	return grid_manager.grid_to_world(cell)

func update_world_position() -> void:
	if grid_manager == null:
		return

	var use_iso_visual_position: bool = should_use_isometric_visual_position()
	# Renderer preview preset is sampled only when Bipob updates visual world position.
	# It does not force any mission or gameplay state changes.
	if use_iso_visual_position:
		var iso_position: Vector2 = get_visual_world_position_for_grid_cell(grid_position)
		var parent_node: Node = get_parent()
		if parent_node != null and parent_node is Node2D:
			position = iso_position
		else:
			global_position = iso_position
		z_index = grid_position.x + grid_position.y + 10
	else:
		global_position = grid_manager.global_position + get_visual_world_position_for_grid_cell(grid_position)
	update_visual_facing()
	update_vision()
	update_threat_detection_preview()
	emit_facing_world_object_hint()
	refresh_world_action_panel()

func get_visual_position_debug_text() -> String:
	var room_visual_renderer: RoomVisualRenderer = get_room_visual_renderer()
	var renderer_drives_iso: bool = false
	if room_visual_renderer != null and room_visual_renderer.has_method("should_preview_drive_bipob_visual_position"):
		renderer_drives_iso = bool(room_visual_renderer.call("should_preview_drive_bipob_visual_position"))
	var iso_active: bool = should_use_isometric_visual_position()
	return "grid=%s isometric=%s explicit_iso=%s renderer_preview_iso=%s pos=%s global=%s" % [
		str(grid_position),
		str(iso_active),
		str(use_isometric_visual_position),
		str(renderer_drives_iso),
		str(position),
		str(global_position)
	]

func emit_facing_world_object_hint() -> void:
	if mission_manager == null:
		return
	var facing := get_facing_device_position()
	var object_data: Dictionary = Dictionary(mission_manager.get_world_object_at_cell(facing))
	if object_data.is_empty():
		var items: Array = mission_manager.get_items_at_cell(facing)
		if items.is_empty():
			return
		object_data = Dictionary(items[0])
	var scan_level := int(object_data.get("scan_level", 0))
	var generic := String(object_data.get("object_group", "Object")).capitalize()
	if String(object_data.get("object_group", "")) == "threat" and scan_level <= 0:
		generic = "Unknown movement"
	var display_name: String = generic if scan_level <= 0 else String(object_data.get("display_name", generic))
	var details: Array[String] = []
	details.append("State: %s" % String(object_data.get("state", "unknown")))
	if object_data.has("is_powered"):
		details.append("Powered: %s" % ("Yes" if bool(object_data.get("is_powered", false)) else "No"))
	if String(object_data.get("object_type", "")).begins_with("power_source"):
		var load_value := int(object_data.get("source_load", 0))
		var capacity_value := int(object_data.get("source_capacity", int(object_data.get("allowed_socket_connections", 1))))
		details.append("Load: %d / %d" % [load_value, maxi(1, capacity_value)])
		if bool(object_data.get("source_overloaded", false)):
			details.append("Status: overloaded")
		if String(object_data.get("state", "")).to_lower() == "overheated":
			details.append("Status: overheated")
			details.append("Reason: source overloaded")
	var power_reason := String(object_data.get("power_unavailable_reason", object_data.get("reason", ""))).strip_edges().to_lower()
	if power_reason == "blocked_by_gate":
		details.append("Reason: blocked by gate")
	elif power_reason == "no_powered_source":
		details.append("Reason: no powered source")
	if object_data.has("current_heat") and object_data.has("overheat_threshold"):
		var threshold := int(object_data.get("overheat_threshold", 0))
		if threshold > 0:
			details.append("Heat: %d / %d" % [int(object_data.get("current_heat", 0)), threshold])
	if String(object_data.get("object_group", "")) == "threat":
		details.append("Behavior: %s" % String(object_data.get("behavior_state", "idle")))
		if String(object_data.get("object_type", "")) == "turret":
			details.append("Attack Range: %d" % int(object_data.get("attack_range", 0)))
			if String(object_data.get("behavior_state", "")) == "alert":
				details.append("Target: Bipop")
	if scan_level >= 2 and bool(object_data.get("revealed_hidden_content", false)):
		details.append("Hidden: %s" % ", ".join(Array(object_data.get("hidden_content", []))))
	var actions := get_available_world_actions(object_data, facing)
	var display_actions: Array[String] = []
	for action_id in actions:
		if action_id == "pickup" and String(object_data.get("item_form", "physical")) == "digital":
			display_actions.append("pickup digital")
		else:
			display_actions.append(action_id)
	var action_text := "No available action for this object."
	if not actions.is_empty():
		if not selected_world_action.is_empty() and actions.has(selected_world_action):
			var selected_display := "pickup digital" if selected_world_action == "pickup" and String(object_data.get("item_form", "physical")) == "digital" else selected_world_action
			action_text = "Selected: %s" % selected_display
		else:
			action_text = "Action: %s" % display_actions[0]
		if actions.size() > 1:
			action_text += " | Available: %s" % ", ".join(display_actions)
	if not actions.is_empty():
		var selected_label := "None"
		if not selected_world_action.is_empty() and actions.has(selected_world_action):
			selected_label = get_world_action_display_label(selected_world_action, object_data)
		hint_requested.emit("Facing: %s | Selected: %s" % [display_name, selected_label])
		return
	hint_requested.emit("%s | %s | %s" % [display_name, " ; ".join(details), action_text])

func get_facing_world_action_target() -> Dictionary:
	var target_position := get_facing_device_position()
	var target_object: Dictionary = {}
	var actions: Array[String] = []
	if mission_manager != null:
		target_object = Dictionary(mission_manager.get_world_object_at_cell(target_position))
		if target_object.is_empty():
			var items: Array = mission_manager.get_items_at_cell(target_position)
			if not items.is_empty():
				target_object = Dictionary(items[0])
		if not target_object.is_empty():
			actions = get_available_world_actions(target_object, target_position)
	return {"target_position": target_position, "target_object": target_object, "actions": actions}

func get_world_action_display_label(action_id: String, object_data: Dictionary) -> String:
	match action_id:
		"open": return "Open"
		"unlock": return "Unlock"
		"input_password": return "Input Password"
		"cut": return "Cut"
		"impact": return "Impact"
		"force_open": return "Force Open"
		"connect": return "Connect"
		"scan": return "Scan"
		"hack": return "Hack"
		"drain_energy": return "Drain Energy"
		"pickup": return "Pickup Digital" if String(object_data.get("item_form", "physical")) == "digital" else "Pickup"
		"use_item": return "Use Item"
		"insert_fuse": return "Insert Fuse"
		"repair": return "Repair"
		"push": return "Push"
		"pull": return "Pull"
		"switch": return "Switch"
		"disable": return "Disable"
		"enable": return "Enable"
		"attack": return "Attack"
		"stun": return "Stun"
		"repair_ally": return "Repair Ally"
	return action_id.capitalize()

func set_selected_world_action(action_id: String) -> void:
	var target_data := get_facing_world_action_target()
	var actions: Array[String] = target_data.get("actions", [])
	if action_id.is_empty() or actions.is_empty() or not actions.has(action_id):
		selected_world_action = ""
		if not action_id.is_empty():
			hint_requested.emit("Selected action is not available for this target.")
	else:
		selected_world_action = action_id
	emit_facing_world_object_hint()
	refresh_world_action_panel()
	status_changed.emit()

func refresh_world_action_panel() -> void:
	var target_data: Dictionary = get_facing_world_action_target()
	var target_object: Dictionary = Dictionary(target_data.get("target_object", {}))
	var actions: Array = Array(target_data.get("actions", []))
	if target_object.is_empty():
		selected_world_action = ""
		world_action_panel_requested.emit({}, [], "")
		return
	if actions.is_empty() or not actions.has(selected_world_action):
		selected_world_action = ""
	world_action_panel_requested.emit(target_object, actions, selected_world_action)
	
func update_vision() -> void:
	if grid_manager == null:
		return

	if get_effective_visor_level() <= 0:
		if not missing_visor_hint_shown:
			hint_requested.emit("Missing module: Visor V1 required.")
			missing_visor_hint_shown = true
		grid_manager.reveal_current_cell_only(grid_position)
		return

	missing_visor_hint_shown = false
	var direction_vector := get_direction_vector(direction)
	var effective_range: int = get_effective_vision_range()
	var side_width: int = get_effective_vision_side_width()
	grid_manager.reveal_by_vision(grid_position, direction_vector, effective_range, side_width)
	if debug_show_hidden_route_node_logs:
		print("Vision update | visor: ", get_effective_visor_level(), " | gpu: ", get_effective_gpu_level(), " | can_detect_hidden_nodes: ", can_detect_hidden_nodes())
	if can_detect_hidden_nodes():
		detect_hidden_route_nodes_in_vision()

func detect_hidden_route_nodes_in_vision() -> void:
	if grid_manager == null:
		return

	var can_detect := can_detect_hidden_nodes()

	if debug_show_hidden_route_node_logs:
		print("Hidden detection check | can_detect: ", can_detect, " | visor: ", get_effective_visor_level(), " | gpu: ", get_effective_gpu_level())

	if not can_detect:
		return

	var visible_cells: Array[Vector2i] = grid_manager.get_visible_cells()

	if debug_show_hidden_route_node_logs:
		print("Visible cells count: ", visible_cells.size())
		print("Active hidden route-node position: ", active_hidden_route_node_position)

	for cell in visible_cells:
		if grid_manager.get_tile(cell) == GridManager.TILE_HIDDEN_ROUTE_NODE:
			if not grid_manager.is_hidden_route_node_discovered(cell):
				grid_manager.discover_hidden_route_node(cell)
				store_digital_record(
					DIGITAL_RECORD_ROUTE_DATA,
					"Route Data",
					"Recovered hidden route information."
				)
				if current_mission_index == 4:
					mission4_hidden_route_node_discovered = true
					hint_requested.emit("Hidden route-node found. Route Data stored. Reach the exit.")
				else:
					hint_requested.emit("Hidden route-node detected. Route Data stored.")
				status_changed.emit()
				return
	
func charge_to_full() -> void:
	# Box preparation action: refill battery without spending field actions/energy.
	energy = max_energy
	print("Bipob fully charged.")
	hint_requested.emit("Bipob fully charged.")
	status_changed.emit()
		
func get_forward_grid_delta_for_direction(direction_value: int) -> Vector2i:
	match direction_value:
		Direction.NORTH:
			return Vector2i.UP
		Direction.EAST:
			return Vector2i.RIGHT
		Direction.SOUTH:
			return Vector2i.DOWN
		Direction.WEST:
			return Vector2i.LEFT
	return Vector2i.ZERO

func get_direction_id(direction_value: int) -> String:
	match direction_value:
		Direction.NORTH:
			return "north"
		Direction.EAST:
			return "east"
		Direction.SOUTH:
			return "south"
		Direction.WEST:
			return "west"
		_:
			return "north"

func get_isometric_visual_rotation_for_direction(direction_value: int) -> float:
	if grid_manager == null:
		return 0.0
	var forward_delta: Vector2i = get_forward_grid_delta_for_direction(direction_value)
	if forward_delta == Vector2i.ZERO:
		return 0.0
	var current_cell: Vector2i = grid_position
	var next_cell: Vector2i = current_cell + forward_delta
	var current_visual: Vector2 = get_visual_world_position_for_grid_cell(current_cell)
	var next_visual: Vector2 = get_visual_world_position_for_grid_cell(next_cell)
	var movement_delta: Vector2 = next_visual - current_visual
	if movement_delta.length() <= 0.001:
		return 0.0
	return movement_delta.angle() + deg_to_rad(isometric_visual_rotation_offset_degrees)

func update_visual_facing() -> void:
	if should_use_isometric_visual_position():
		rotation = get_isometric_visual_rotation_for_direction(direction)
		return

	match direction:
		Direction.NORTH:
			rotation_degrees = 0
		Direction.EAST:
			rotation_degrees = 90
		Direction.SOUTH:
			rotation_degrees = 180
		Direction.WEST:
			rotation_degrees = 270

func update_rotation() -> void:
	update_visual_facing()

func get_direction_vector(current_direction: Direction) -> Vector2i:
	match current_direction:
		Direction.NORTH:
			return Vector2i(0, -1)
		Direction.EAST:
			return Vector2i(1, 0)
		Direction.SOUTH:
			return Vector2i(0, 1)
		Direction.WEST:
			return Vector2i(-1, 0)
	
	return Vector2i.ZERO

func get_facing_device_position() -> Vector2i:
	return grid_position + get_direction_vector(direction)

func get_device_definition_for_tile(tile_type: int) -> DeviceDefinition:
	var definition := DeviceDefinition.new()

	match tile_type:
		GridManager.TILE_TERMINAL:
			definition.device_type = "terminal"
			definition.display_name = "Terminal"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 1
			definition.supported_action = "download_info_key"
			return definition
		GridManager.TILE_DIGITAL_DOOR:
			definition.device_type = "digital_door"
			definition.display_name = "Digital Door"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 1
			definition.supported_action = "open_digital_door"
			return definition
		GridManager.TILE_HOT_NODE:
			definition.device_type = "hot_node"
			definition.display_name = "Hot Node"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 2
			definition.supported_action = "stabilize_hot_node"
			return definition
		GridManager.TILE_AIRFLOW_TERMINAL:
			definition.device_type = "airflow_terminal"
			definition.display_name = "Airflow Terminal"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 2
			definition.supported_action = "unlock_airflow_terminal"
			return definition
		_:
			return null

func get_facing_device_definition() -> DeviceDefinition:
	if grid_manager == null:
		return null

	var facing_cell := get_facing_device_position()
	var tile_type := grid_manager.get_tile(facing_cell)
	return get_device_definition_for_tile(tile_type)

func has_required_interface(required_interface: String) -> bool:
	if required_interface.is_empty():
		return true

	for module in installed_modules:
		if module == null:
			continue
		if module.id == required_interface:
			return true
		if required_interface in module.granted_commands:
			return true
		if "interface" in module.granted_commands:
			return true

	return false

func has_cooling_support() -> bool:
	return has_module_id("cooling_v1")

func evaluate_device_capability(device: DeviceDefinition) -> DiagnosticResult:
	var result := DiagnosticResult.new()

	if device == null:
		result.status = DiagnosticResult.STATUS_BLOCKED
		result.device_type = ""
		result.device_name = "Unknown"
		result.supported_action = ""
		result.reason = "No device detected."
		result.recommendation = "Face a digital device and scan again."
		result.estimated_risk = "none"
		return result

	if not has_required_interface(device.required_interface):
		result.status = DiagnosticResult.STATUS_BLOCKED
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		result.reason = "Missing required interface: " + device.required_interface
		result.recommendation = "Install Interface V1 or compatible module."
		result.estimated_risk = "low"
		return result

	if device.device_type == "airflow_terminal":
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		if not mission8_terminal_cooled:
			result.status = DiagnosticResult.STATUS_BLOCKED
			result.reason = "Terminal heat is too high without airflow."
			result.recommendation = "Rotate the fan platform and increase fan speed until airflow reaches the terminal."
			result.estimated_risk = "high"
			return result
		result.status = DiagnosticResult.STATUS_READY
		result.reason = "Terminal cooled by directed airflow."
		result.recommendation = "Proceed with Hack Device."
		result.estimated_risk = "low"
		return result

	if device.device_type == "hot_node":
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		if has_cooling_support():
			result.status = DiagnosticResult.STATUS_READY
			result.reason = "Cooling support detected."
			result.recommendation = "Hack Device can stabilize the node safely."
			result.estimated_risk = "low"
			return result
		result.status = DiagnosticResult.STATUS_RISKY
		result.reason = "No cooling support installed."
		result.recommendation = "Install Cooling V1 or proceed with extra energy cost."
		result.estimated_risk = "medium"
		return result

	result.status = DiagnosticResult.STATUS_READY
	result.device_type = device.device_type
	result.device_name = device.display_name
	result.supported_action = device.supported_action
	result.reason = "Current build can interact with this device."
	result.recommendation = "Proceed with Hack Device."
	result.estimated_risk = "low"
	return result

func evaluate_facing_device_capability() -> DiagnosticResult:
	var device := get_facing_device_definition()
	last_diagnostic_result = evaluate_device_capability(device)
	print(
		"Capability check | Status: ",
		last_diagnostic_result.status,
		" | Device: ",
		last_diagnostic_result.device_name,
		" | Action: ",
		last_diagnostic_result.supported_action
	)
	return last_diagnostic_result
	
func open_door(door_position: Vector2i, manipulator_module: BipobModule = null) -> void:
	if not can_use_physical_hand():
		hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
		status_changed.emit()
		return
	if not require_command("open_physical_door", "Missing module: Manipulator V1 required."):
		return
	if not has_key:
		print("Door is locked. Physical key required.")
		hint_requested.emit("Physical door locked. Find the physical key first.")
		return
	
	if not can_spend_action(1, 0):
		return
	if not spend_energy_for_manipulator_action(manipulator_module):
		hint_requested.emit("Not enough energy for manipulator action.")
		status_changed.emit()
		return

	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 0)
	print("Door opened.")
	hint_requested.emit("Physical door opened. Reach the exit.")
	print_status()
	
func open_digital_door(door_position: Vector2i) -> void:
	if not require_command("open_digital_door", "Missing module: Interface V1 required."):
		return
	if not has_info_key and not use_digital_record(DIGITAL_RECORD_INFO_KEY):
		print("Digital door locked. Info-Key required from terminal.")
		hint_requested.emit("Digital door requires Info-Key. Hack the terminal first.")
		return

	if not can_spend_action(1, 1):
		return

	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Digital door opened.")
	hint_requested.emit("Digital door opened. Info-Key remains stored.")
	status_changed.emit()


func scan_device() -> void:
	if mission_finished:
		return

	var facing_cell := get_facing_device_position()
	if mission_manager != null:
		var world_object: Dictionary = Dictionary(mission_manager.get_world_object_at_cell(facing_cell))
		if not world_object.is_empty():
			if not can_spend_action(1, 1):
				return
			# Scan spends action first; then temporary heat is applied.
			# If GPU overheats, the attempted scan still costs action and reveals no new data.
			spend_action(1, 1)
			var scan_type := get_world_scan_type_from_installed_modules()
			var overheat_action_id := ""
			if scan_type == "xray":
				overheat_action_id = "xray"
			elif scan_type == "thermal":
				overheat_action_id = "thermal_scan"
			if not overheat_action_id.is_empty():
				var overheat_result := apply_internal_overheat_if_needed(overheat_action_id, get_internal_action_temporary_heat_context(overheat_action_id))
				if bool(overheat_result.get("failed", false)):
					for overheat_message in overheat_result.get("messages", []):
						hint_requested.emit(String(overheat_message))
					status_changed.emit()
					return
			var result := ScanSystemRef.scan_object(world_object, scan_type, get_effective_visor_level())
			world_object["scan_level"] = int(result.get("scan_level", 1))
			if scan_type == "xray" and world_object.get("object_group", "") == "wall" and not Array(world_object.get("hidden_content", [])).is_empty():
				world_object["revealed_hidden_content"] = true
			mission_manager.set_world_object_at_cell(facing_cell, world_object)
			refresh_world_object_overlay()
			update_threat_detection_preview()
			var scan_text := ScanSystemRef.get_scan_display_text(world_object, scan_type)
			if String(world_object.get("object_group", "")) == "platform" and mission_manager.has_method("get_platform_state_summary"):
				scan_text += "\n" + String(mission_manager.call("get_platform_state_summary", world_object))
			hint_requested.emit("Scan: %s" % scan_text)
			clear_selected_world_action_if_invalid(world_object, facing_cell)
			emit_facing_world_object_hint()
			refresh_world_action_panel()
			status_changed.emit()
			return

	if not can_spend_action(1, 1):
		return

	var device := get_facing_device_definition()
	if device == null:
		var blocked_result := DiagnosticResult.new()
		blocked_result.status = DiagnosticResult.STATUS_BLOCKED
		blocked_result.device_name = "Unknown"
		blocked_result.reason = "No digital device detected."
		blocked_result.recommendation = "Face a terminal or digital door and scan again."
		blocked_result.estimated_risk = "none"
		last_diagnostic_result = blocked_result
		hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		status_changed.emit()
		return

	spend_action(1, 1)
	evaluate_facing_device_capability()
	if last_diagnostic_result.status == DiagnosticResult.STATUS_BLOCKED:
		hint_requested.emit("Scan complete: BLOCKED. Check Diagnostic panel for missing requirements.")
	else:
		hint_requested.emit("Scan complete: " + last_diagnostic_result.get_status_text() + ". Check Diagnostic panel, then use Hack Device if READY.")
	status_changed.emit()

func hack_device() -> void:
	if mission_finished:
		return

	if last_diagnostic_result == null:
		hint_requested.emit("Scan device first.")
		status_changed.emit()
		return

	if not last_diagnostic_result.is_action_allowed():
		hint_requested.emit("Hack blocked. Check Diagnostic panel.")
		status_changed.emit()
		return

	var device := get_facing_device_definition()
	if device == null:
		hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		status_changed.emit()
		return

	if device.device_type != last_diagnostic_result.device_type \
	or device.supported_action != last_diagnostic_result.supported_action:
		hint_requested.emit("Device changed. Scan this device again.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return
	# Hack checks action availability first. Temporary heat is only applied for an actual attempt.
	# With "affected" scope, only processor-heated modules can break for hack.
	var overheat_result := apply_internal_overheat_if_needed("hack", get_internal_action_temporary_heat_context("hack"))
	if bool(overheat_result.get("failed", false)):
		spend_action(1, 1)
		for overheat_message in overheat_result.get("messages", []):
			hint_requested.emit(String(overheat_message))
		status_changed.emit()
		return
	var hack_world_object: Dictionary = Dictionary(mission_manager.get_world_object_at_cell(get_facing_device_position()))
	if not hack_world_object.is_empty() and String(hack_world_object.get("object_group", "")) == "terminal":
		if not _is_terminal_powered_for_interaction(hack_world_object):
			hint_requested.emit("Terminal is unpowered.")
			status_changed.emit()
			return
		WorldObjectCatalog.update_world_object_heat_state(hack_world_object)
		if String(hack_world_object.get("state", "")) == "overheated":
			spend_action(1, 1)
			mission_manager.update_world_object_by_id(String(hack_world_object.get("id", "")), hack_world_object)
			hint_requested.emit("Terminal overheated. Hack failed.")
			status_changed.emit()
			return
		var hack_heat := maxi(0, int(hack_world_object.get("hack_heat", 1)))
		if WorldObjectCatalog.would_world_object_overheat_with_temporary_heat(hack_world_object, hack_heat):
			spend_action(1, 1)
			hack_world_object["current_heat"] = WorldObjectCatalog.get_world_object_current_heat(hack_world_object)
			WorldObjectCatalog.update_world_object_heat_state(hack_world_object)
			mission_manager.update_world_object_by_id(String(hack_world_object.get("id", "")), hack_world_object)
			hint_requested.emit("Terminal overheated. Hack failed.")
			status_changed.emit()
			return

	match device.supported_action:
		"download_info_key":
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			if current_mission_index == 2:
				hint_requested.emit("Terminal is silent. Interface calibration required. Return to the box.")
				complete_mission()
				return
			has_info_key = true
			store_digital_record(DIGITAL_RECORD_INFO_KEY, "Info-Key", "Digital authorization record for opening a digital door.")
			hint_requested.emit("Info-Key downloaded. Now find the digital door, scan it, then hack it.")
			status_changed.emit()
			return
		"open_digital_door":
			if not has_info_key and not use_digital_record(DIGITAL_RECORD_INFO_KEY):
				hint_requested.emit("Digital door requires Info-Key. Hack the terminal first.")
				status_changed.emit()
				return
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			grid_manager.set_tile(get_facing_device_position(), GridManager.TILE_FLOOR)
			hint_requested.emit("Digital door opened. Info-Key remains stored.")
			status_changed.emit()
			return
		"unlock_airflow_terminal":
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			mission8_terminal_hacked = true
			if grid_manager != null and grid_manager.is_in_bounds(mission8_door_position):
				grid_manager.set_tile(mission8_door_position, GridManager.TILE_FLOOR)
			hint_requested.emit("Airflow Terminal hacked. Path opened.")
			status_changed.emit()
			return
		"stabilize_hot_node":
			var energy_cost := 1
			if last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				energy_cost = 3
			if not can_spend_action(1, energy_cost):
				return
			spend_action(1, energy_cost)
			var hot_node_position := get_facing_device_position()
			grid_manager.set_tile(hot_node_position, GridManager.TILE_FLOOR)
			var adjacent_offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for offset in adjacent_offsets:
				var adjacent_position := hot_node_position + offset
				if grid_manager.get_tile(adjacent_position) == GridManager.TILE_DIGITAL_DOOR:
					grid_manager.set_tile(adjacent_position, GridManager.TILE_FLOOR)
			if last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				hint_requested.emit("Risky hack succeeded, but Bipob spent extra energy.")
			else:
				hint_requested.emit("Hot Node stabilized.")
			status_changed.emit()
			return
		_:
			hint_requested.emit("Unsupported hack action.")
			status_changed.emit()
			return

func open_route_gate(gate_position: Vector2i) -> void:
	if not has_digital_record(DIGITAL_RECORD_ROUTE_DATA):
		hint_requested.emit("Route Gate locked. Route Data required.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	grid_manager.set_tile(gate_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	hint_requested.emit("Route Gate opened using Route Data.")
	status_changed.emit()

func get_installed_manipulators() -> Array:
	var result: Array = []
	for module in installed_modules:
		if module != null and String(module.category) == "Manipulator":
			result.append(module)
	return result

func can_manipulator_interact(module: BipobModule, _target_position: Vector2i, _interaction_data: Dictionary = {}) -> bool:
	if module == null:
		return false
	if String(module.category) != "Manipulator":
		return false
	# TODO: add direction/reach/material/weight checks when mission objects expose metadata.
	return true

func get_best_manipulator_for_interaction(target_position: Vector2i = Vector2i.ZERO, interaction_data: Dictionary = {}) -> BipobModule:
	var manipulators: Array = get_installed_manipulators()
	for module in manipulators:
		if can_manipulator_interact(module, target_position, interaction_data):
			return module
	return null

func get_installed_tools() -> Array:
	var result: Array = []
	for module in installed_modules:
		if module != null and String(module.category) == "Tools":
			result.append(module)
	return result

func get_tool_for_action(action_id: String) -> BipobModule:
	for module_variant in get_installed_tools():
		var module: BipobModule = module_variant
		if module != null and String(module.tool_action) == action_id:
			return module
	return null

func spend_energy_for_tool_action(module: BipobModule) -> bool:
	if module == null:
		return false
	var cost := maxi(0, int(module.energy_cost))
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	return true

func has_installed_external_module_id(module_id: String) -> bool:
	for module in installed_modules:
		if module != null and module.placement_type == "external" and module.id == module_id:
			return true
	return false

func has_installed_beacon_module() -> bool:
	return has_installed_external_module_id("beacon_module_v1")

func get_installed_weapons() -> Array:
	var result: Array = []
	for module in installed_modules:
		if module != null and String(module.category) == "Weapons":
			result.append(module)
	return result

func can_weapon_attack(module: BipobModule, _attack_data: Dictionary = {}) -> bool:
	if module == null:
		return false
	if String(module.category) != "Weapons":
		return false
	if module.id == "gas_canister_v1":
		return false
	if not module.ammo_dependency_id.is_empty():
		if not has_installed_external_module_id(module.ammo_dependency_id):
			return false
	return true

func spend_energy_for_weapon_attack(module: BipobModule) -> bool:
	if module == null:
		return false
	var cost := maxi(0, int(module.energy_cost))
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	return true

# TODO(BIB-531): Wire weapon selection/attack flow to can_weapon_attack() and spend_energy_for_weapon_attack()
# when dedicated combat actions are implemented. Keep gas dependency + metadata checks in these helpers.

# TODO(BIB-529): validate concrete target metadata/range for weld/repair/cut interactions once mission objects expose these constraints.
func try_commit_tool_action(action_id: String) -> bool:
	var tool_module: BipobModule = get_tool_for_action(action_id)
	if tool_module == null:
		hint_requested.emit("Missing tool for action: %s." % action_id)
		status_changed.emit()
		return false
	if not spend_energy_for_tool_action(tool_module):
		hint_requested.emit("Not enough energy for tool action.")
		status_changed.emit()
		return false
	return true

func get_manipulator_energy_cost(module: BipobModule) -> int:
	if module == null:
		return 0
	return maxi(0, module.energy_cost)

func spend_energy_for_manipulator_action(module: BipobModule) -> bool:
	var cost := get_manipulator_energy_cost(module)
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	return true

func get_world_scan_type_from_installed_modules() -> String:
	if has_module_id("thermal_visor_v1"):
		return "thermal"
	if has_module_id("xray_v1"):
		return "xray"
	if has_module_id("radar_v1"):
		return "radar"
	return "visor"

func _extract_module_level_by_prefix(prefix: String) -> int:
	var best := 0
	for module in installed_modules:
		if module == null:
			continue
		var module_id := String(module.id)
		if not module_id.begins_with(prefix):
			continue
		var version_regex: RegEx = RegEx.new()
		version_regex.compile("_v(\\d+)$")
		var found: RegExMatch = version_regex.search(module_id)
		if found != null:
			best = maxi(best, int(found.get_string(1)))
		elif module_id.ends_with("_v1"):
			best = maxi(best, 1)
	return best

func get_installed_manipulator_arm_level() -> int:
	return _extract_module_level_by_prefix("manipulator_arm")

func get_installed_heavy_claw_level() -> int:
	return _extract_module_level_by_prefix("manipulator_heavy_claw")

func get_installed_manipulator_level() -> int:
	return get_installed_manipulator_arm_level()

func has_world_tool(module_id: String) -> bool:
	return has_module_id(module_id)

func has_plasma_cutter() -> bool:
	return has_world_tool("plasma_cutter_v1")

func has_sledgehammer() -> bool:
	return has_world_tool("sledgehammer_v1")

func has_repair_tool() -> bool:
	return has_world_tool("repair_v1")

func has_magnetic_manipulator() -> bool:
	return has_world_tool("magnetic_manipulator_v1")

func has_heavy_claw_capability() -> bool:
	if has_command("heavy_claw"):
		return true
	return get_installed_heavy_claw_level() > 0

func has_heavy_claw() -> bool:
	return has_heavy_claw_capability()

func has_manipulator_arm() -> bool:
	return get_installed_manipulator_arm_level() > 0

func get_installed_processor_level() -> int:
	return _extract_module_level_by_prefix("processor")

func _get_connector_module_prefix_for_kind(kind: String) -> String:
	match String(kind).strip_edges().to_lower():
		"wired":
			return "wired_connector"
		"optical":
			return "optical_connector"
		"wireless":
			return "wireless_connector"
		"high_bandwidth":
			return "high_bandwidth_connector"
		_:
			return ""

func get_installed_connector_level(kind: String = "") -> int:
	var port_state := preview_module_port_activity()
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var target_prefix := _get_connector_module_prefix_for_kind(kind)
	var best := 0
	for module in installed_modules:
		if module == null:
			continue
		var module_id := String(module.id)
		if not module_id.contains("_connector_v"):
			continue
		if not target_prefix.is_empty() and not module_id.begins_with(target_prefix):
			continue
		var state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		if not bool(state.get("active", false)):
			continue
		var version_regex: RegEx = RegEx.new()
		version_regex.compile("_v(\\d+)$")
		var found: RegExMatch = version_regex.search(module_id)
		if found != null:
			best = maxi(best, int(found.get_string(1)))
	return best

func get_bipob_power_class() -> String:
	var body_size: Vector3i = get_constructor_body_size()
	if body_size == CONSTRUCTOR_PROFILE_JUGGERNAUT_SIZE:
		return "juggernaut"
	if body_size == CONSTRUCTOR_PROFILE_ENGINEER_SIZE:
		return "engineer"
	return "scout"

func cycle_selected_world_action() -> void:
	var target_data := get_facing_world_action_target()
	var actions: Array[String] = target_data.get("actions", [])
	if actions.is_empty():
		selected_world_action = ""
		hint_requested.emit("No available action for this object.")
		refresh_world_action_panel()
		status_changed.emit()
		return
	if selected_world_action.is_empty() or not actions.has(selected_world_action):
		selected_world_action = actions[0]
	else:
		var idx := actions.find(selected_world_action)
		selected_world_action = actions[(idx + 1) % actions.size()]
	emit_facing_world_object_hint()
	refresh_world_action_panel()
	status_changed.emit()

func clear_selected_world_action_if_invalid(target_object: Dictionary, target_position: Vector2i) -> void:
	if target_object.is_empty():
		selected_world_action = ""
		return
	var actions := get_available_world_actions(target_object, target_position)
	if actions.is_empty() or not actions.has(selected_world_action):
		selected_world_action = ""

func get_world_object_action_for_context(world_object: Dictionary, _active_module: BipobModule, target_position: Vector2i) -> String:
	var actions := get_available_world_actions(world_object, target_position)
	if not selected_world_action.is_empty() and actions.has(selected_world_action):
		return selected_world_action
	if actions.is_empty():
		return ""
	return String(actions[0])


func get_grid_position() -> Vector2i:
	return grid_position

func set_direction(next_direction: String) -> void:
	match next_direction.strip_edges().to_upper():
		"NORTH":
			direction = Direction.NORTH
		"EAST":
			direction = Direction.EAST
		"SOUTH":
			direction = Direction.SOUTH
		"WEST":
			direction = Direction.WEST
		_:
			direction = Direction.NORTH

func get_direction() -> String:
	match direction:
		Direction.NORTH:
			return "NORTH"
		Direction.EAST:
			return "EAST"
		Direction.SOUTH:
			return "SOUTH"
		Direction.WEST:
			return "WEST"
		_:
			return "NORTH"

func get_heavy_claw_move_destination(object_cell: Vector2i, actor_cell: Vector2i, action_id: String) -> Vector2i:
	var direction_vector := object_cell - actor_cell
	if direction_vector == Vector2i.ZERO:
		return Vector2i(-1, -1)
	if abs(direction_vector.x) + abs(direction_vector.y) != 1:
		return Vector2i(-1, -1)
	if action_id == "push":
		return object_cell + direction_vector
	if action_id == "pull":
		# Pull for world cooling objects is intentionally unavailable in this milestone.
		return Vector2i(-1, -1)
	return Vector2i(-1, -1)

func has_collected_runtime_key(key_id: String) -> bool:
	if key_id.strip_edges().is_empty() or mission_manager == null or not mission_manager.has_method("has_collected_key"):
		return false
	return bool(mission_manager.call("has_collected_key", key_id))

func has_access_for_door(world_object: Dictionary) -> bool:
	var required_key_id: String = String(world_object.get("required_key_id", "")).strip_edges()
	if not required_key_id.is_empty() and has_collected_runtime_key(required_key_id):
		return true
	return has_key or has_held_world_item("mechanical_keycard") or has_digital_world_item("digital_key")

func get_collected_runtime_key_ids() -> Array:
	if mission_manager == null or not mission_manager.has_method("get_inventory_state"):
		return []
	var inventory: Dictionary = Dictionary(mission_manager.call("get_inventory_state"))
	return Array(inventory.get("collected_key_ids", []))

func get_available_world_actions(world_object: Dictionary, target_position: Vector2i) -> Array[String]:
	var actions: Array[String] = []
	var group := String(world_object.get("object_group", ""))
	var state := String(world_object.get("state", ""))
	var _items_here: Array[Dictionary] = mission_manager.get_items_at_cell(target_position) if mission_manager != null else []
	if group == "door":
		if state in ["damaged", "half_open", "jammed"] and has_heavy_claw():
			actions.append("force_open")
		if state == "locked":
			actions.append("unlock")
		if state == "closed" and has_manipulator_arm():
			actions.append("open")
		if has_plasma_cutter() and String(world_object.get("material", "")) in ["steel", "reinforced_steel"]:
			actions.append("cut")
		if has_sledgehammer() and String(world_object.get("material", "")) in ["steel", "reinforced_steel"]:
			actions.append("impact")
	elif group == "terminal":
		if bool(world_object.get("connected", false)) and get_installed_processor_level() > 0:
			actions.append("hack")
		if String(world_object.get("terminal_type", "")) == "platform" and get_installed_connector_level(String(world_object.get("connection_type", "wired"))) > 0:
			actions.append("activate_platform")
		if get_installed_connector_level(String(world_object.get("connection_type", "wired"))) > 0:
			actions.append("connect")
		if has_repair_tool() and state == "damaged":
			actions.append("repair")
	elif group == "wall":
		if has_plasma_cutter():
			actions.append("cut")
		if has_sledgehammer():
			actions.append("impact")
		if has_heavy_claw() and (state == "damaged" or String(world_object.get("material", "")) == "brick"):
			actions.append("force_open")
	elif String(world_object.get("object_type", "")) == "power_cable":
		if has_plasma_cutter():
			actions.append("cut")
		if has_repair_tool() and state == "damaged":
			actions.append("repair")
	elif String(world_object.get("object_type", "")) in ["circuit_breaker", "light_switch", "circuit_switch"]:
		actions.append("switch")
	elif String(world_object.get("object_type", "")).begins_with("fuse_box"):
		if has_held_world_item("fuse"):
			actions.append("insert_fuse")
		if has_repair_tool() and state == "damaged":
			actions.append("repair")
	elif group == "physical_object":
		if has_magnetic_manipulator() and (bool(world_object.get("magnetic", false)) or Array(world_object.get("material_tags", [])).has("metal")):
			actions.append("pull")
		if has_heavy_claw_capability() and not actions.has("push"):
			actions.append("push")
		if has_sledgehammer():
			actions.append("impact")
		if has_plasma_cutter():
			actions.append("cut")
	elif WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(world_object):
		if has_heavy_claw_capability() and not actions.has("push"):
			actions.append("push")
	elif group == "threat":
		if state in ["destroyed", "disabled"]:
			return actions
		var distance := mini(abs(target_position.x - grid_position.x) + abs(target_position.y - grid_position.y), 99)
		if has_module_id("laser_v1") and distance <= 4:
			actions.append("attack")
		if distance <= 1 and (has_module_id("saw_v1") or has_module_id("sledgehammer_v1") or has_module_id("gas_burner_v1")) and not actions.has("attack"):
			actions.append("attack")
		if has_module_id("shocker_v1") and distance <= 1:
			actions.append("stun")
		if has_module_id("energy_drain_v1") and distance <= 1:
			actions.append("drain_energy")
		if get_installed_processor_level() >= int(world_object.get("required_processor_level", 1)) and (has_module_id("wired_connector_v1") or has_module_id("wireless_connector_v1")):
			actions.append("hack")
		if has_heavy_claw() and distance <= 1:
			actions.append("push")
	elif group == "platform":
		if String(world_object.get("control_type", "internal")) == "internal" and get_installed_manipulator_arm_level() >= 1 and mission_manager != null and mission_manager.can_bipob_access_platform_switch(world_object, grid_position, get_direction_id(direction)):
			actions.append("activate_platform")
	elif group == "item":
		actions.append("pickup")
	return actions

func _module_dict(module_id: String) -> Dictionary:
	return {"id": module_id}

func get_world_action_module(action_id: String, world_object: Dictionary) -> Dictionary:
	var connection_type := String(world_object.get("connection_type", "wired"))
	match action_id:
		"open", "switch", "pickup", "activate_platform":
			if action_id == "open":
				var arm_level := get_installed_manipulator_arm_level()
				return _module_dict("manipulator_arm_v%d" % arm_level if arm_level > 0 else "")
			var manipulator := get_best_manipulator_for_interaction()
			return _module_dict(manipulator.id if manipulator != null else "")
		"unlock":
			var required_key_id: String = String(world_object.get("required_key_id", "")).strip_edges()
			if not required_key_id.is_empty() and has_collected_runtime_key(required_key_id):
				return _module_dict("mechanical_keycard")
			if has_key or has_held_world_item("mechanical_keycard"):
				return _module_dict("mechanical_keycard")
			if has_digital_world_item("digital_key", "opened"):
				return _module_dict("digital_key_opened")
			if has_digital_world_item("digital_key", "encrypted"):
				return _module_dict("digital_key_encrypted")
			if has_digital_world_item("digital_key", "damaged"):
				return _module_dict("digital_key_damaged")
			return _module_dict("")
		"connect":
			var level := get_installed_connector_level(connection_type)
			return _module_dict("%s_connector_v%d" % [connection_type, level] if level > 0 else "")
		"hack":
			if String(world_object.get("object_group", "")) == "threat":
				if has_module_id("wired_connector_v1"):
					return _module_dict("wired_connector_v1")
				if has_module_id("wireless_connector_v1"):
					return _module_dict("wireless_connector_v1")
				return _module_dict("")
			var processor_level := get_installed_processor_level()
			return _module_dict("processor_v%d" % processor_level if processor_level > 0 else "")
		"cut":
			return _module_dict("plasma_cutter_v1" if has_module_id("plasma_cutter_v1") else "")
		"impact":
			return _module_dict("sledgehammer_v1" if has_module_id("sledgehammer_v1") else "")
		"attack":
			var target_pos: Vector2i = Vector2i(world_object.get("position", get_facing_device_position()))
			var distance: int = abs(target_pos.x - grid_position.x) + abs(target_pos.y - grid_position.y)
			if has_module_id("laser_v1") and distance <= 4:
				return _module_dict("laser_v1")
			if has_module_id("saw_v1") and distance <= 1:
				return _module_dict("saw_v1")
			if has_module_id("sledgehammer_v1") and distance <= 1:
				return _module_dict("sledgehammer_v1")
			if has_module_id("gas_burner_v1") and distance <= 1:
				return _module_dict("gas_burner_v1")
			return _module_dict("")
		"stun":
			return _module_dict("shocker_v1" if has_module_id("shocker_v1") else "")
		"drain_energy":
			return _module_dict("energy_drain_v1" if has_module_id("energy_drain_v1") else "")
		"force_open", "push":
			return _module_dict("manipulator_heavy_claw_v1" if has_module_id("manipulator_heavy_claw_v1") else "")
		"repair":
			return _module_dict("repair_v1" if has_module_id("repair_v1") else "")
		"pull":
			if bool(world_object.get("magnetic", false)) or String(world_object.get("pull_mode", "")) == "magnetic":
				return _module_dict("magnetic_manipulator_v1" if has_module_id("magnetic_manipulator_v1") else "")
			return _module_dict("manipulator_heavy_claw_v1" if has_module_id("manipulator_heavy_claw_v1") else "")
		"insert_fuse":
			return _module_dict("fuse" if has_held_world_item("fuse") else "")
	return _module_dict("")

func interact() -> void:
	if mission_manager != null and mission_manager.has_method("set_active_bipob_ref"):
		mission_manager.set_active_bipob_ref(self)
	var target_position := get_facing_device_position()
	var target_tile := grid_manager.get_tile(target_position)

	# Legacy interact must not process digital devices.
	if target_tile == GridManager.TILE_TERMINAL:
		hint_requested.emit("Terminal is a digital device. Use Scan Device first, then Hack Device.")
		status_changed.emit()
		return

	if target_tile == GridManager.TILE_DIGITAL_DOOR:
		hint_requested.emit("Digital door cannot be opened with Interact. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_HOT_NODE:
		hint_requested.emit("Hot Node is a digital device. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_AIRFLOW_TERMINAL:
		hint_requested.emit("Airflow Terminal is a digital device. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL:
		hint_requested.emit("Use left/right platform controls.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL_LEFT:
		interact_mission8_platform_control_left()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
		interact_mission8_platform_control_right()
		return
	if target_tile == GridManager.TILE_FAN_CONTROL:
		hint_requested.emit("Use fan speed up/down controls.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_FAN_SPEED_UP_CONTROL:
		increase_mission8_fan_speed()
		return
	if target_tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
		decrease_mission8_fan_speed()
		return
	if target_tile == GridManager.TILE_CABLE_REEL:
		interact_mission7_cable_reel()
		return
	if target_tile == GridManager.TILE_SOCKET:
		interact_mission7_socket()
		return
	if target_tile == GridManager.TILE_POWERED_GATE:
		hint_requested.emit("Powered gate is closed. Connect the cable to the socket.")
		status_changed.emit()
		return
	if current_mission_index == 7 and mission7_is_dragging_cable and (target_tile == GridManager.TILE_COMPONENT or target_tile == GridManager.TILE_KEY or target_tile == GridManager.TILE_DOOR):
		hint_requested.emit("Cable in hand. Connect it to the socket or drop it first.")
		status_changed.emit()
		return
	
	var active_manipulator: BipobModule = get_best_manipulator_for_interaction(target_position)
	if mission_manager != null:
		var item_cells: Array[Vector2i] = [grid_position]
		if target_position != grid_position:
			item_cells.append(target_position)
		for item_cell in item_cells:
			var cell_items: Array = mission_manager.get_items_at_cell(item_cell)
			if cell_items.is_empty():
				continue
			var item: Dictionary = Dictionary(cell_items[0])
			var is_digital_item := String(item.get("item_form", "physical")) == "digital"
			var item_actor := {"manipulator_occupied": not is_digital_item and not can_use_physical_hand()}
			var item_result: Dictionary = Dictionary(InteractionSystemRef.apply_action(item_actor, {"id": active_manipulator.id if active_manipulator != null else ""}, item, "pickup"))
			if bool(item_result.get("success", false)):
				var item_id: String = String(item.get("id", ""))
				if mission_manager.has_method("pickup_world_item"):
					mission_manager.call("pickup_world_item", item_id)
				if String(item.get("key_kind", "")).strip_edges() != "" and mission_manager.has_method("mark_key_collected"):
					mission_manager.call("mark_key_collected", item_id)
				mission_manager.remove_first_item_at_cell(item_cell)
				if is_digital_item:
					store_digital_record(item_id if not item_id.is_empty() else "item_record", String(item.get("display_name", "Item")), "Recovered digital world item.")
					var item_type := String(item.get("item_type", item.get("id", "")))
					var digital_state := String(item.get("digital_state", item.get("state", "opened")))
					var item_family := String(item.get("item_family", infer_digital_item_family(item_type)))
					digital_world_records[item_family] = {"item_family": item_family, "item_type": item_type, "digital_state": digital_state}
					hint_requested.emit("Pickup digital: item stored.")
				elif can_use_physical_hand():
					buffer_item = item
					hint_requested.emit("Picked up %s" % String(item.get("display_name", "item")))
				else:
					hint_requested.emit("Manipulator is occupied.")
				clear_selected_world_action_if_invalid({}, item_cell)
				emit_facing_world_object_hint()
				refresh_world_action_panel()
			else:
				hint_requested.emit(String(item_result.get("message", "Pickup failed.")))
			status_changed.emit()
			return

		var world_object: Dictionary = Dictionary(mission_manager.get_world_object_at_cell(target_position))
		if not world_object.is_empty():
			var target_platform: Dictionary = Dictionary(mission_manager.get_platform_for_cell(target_position))
			if String(world_object.get("object_group", "")) == "platform":
				target_platform = world_object
			var actor := {
				"manipulator_level": get_installed_manipulator_arm_level(),
				"heavy_claw_level": get_installed_heavy_claw_level(),
				"connector_level": maxi(get_installed_connector_level("wired"), get_installed_connector_level("optical")),
				"wired_connector_level": get_installed_connector_level("wired"),
				"optical_connector_level": get_installed_connector_level("optical"),
				"wireless_connector_level": get_installed_connector_level("wireless"),
				"high_bandwidth_connector_level": get_installed_connector_level("high_bandwidth"),
				"processor_level": get_installed_processor_level(),
				"firewall_module_v1": has_module_id("firewall_module_v1"),
				"power_class": get_bipob_power_class(),
				"manipulator_occupied": not can_use_physical_hand(),
				"pocket_full": get_available_pocket_slots() <= 0,
				"range_to_target": 1,
				"is_straight_line": true,
				"magnetic_path_blocked": false,
				"target_is_grate": world_object.get("object_type", "") == "grate_wall",
				"facing_direction": get_direction_vector(direction),
				"target_position": target_position,
				"actor_position": grid_position,
				"platform_switch_access": mission_manager.can_bipob_access_platform_switch(target_platform, grid_position, get_direction_id(direction)),
				"collected_key_ids": get_collected_runtime_key_ids()
			}
			var action_id := get_world_object_action_for_context(world_object, active_manipulator, target_position)
			var _available_actions := get_available_world_actions(world_object, target_position)
			var module := get_world_action_module(action_id, world_object)
			if String(world_object.get("object_group", "")) == "terminal" and (action_id == "hack" or action_id == "activate_platform") and not _is_terminal_powered_for_interaction(world_object):
				hint_requested.emit("Terminal is unpowered.")
				status_changed.emit()
				return
			if String(world_object.get("object_group", "")) == "platform":
				if String(world_object.get("state", "active")) in ["unpowered", "disabled"] or not bool(world_object.get("is_powered", true)):
					hint_requested.emit("Platform is unpowered.")
					status_changed.emit()
					return
			if action_id.is_empty():
				if WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(world_object) and not has_heavy_claw_capability():
					hint_requested.emit("Heavy Claw required.")
				else:
					hint_requested.emit("No available action for this object.")
				status_changed.emit()
				return
			var action_result: Dictionary = Dictionary(InteractionSystemRef.apply_action(actor, module, world_object, action_id))
			if bool(action_result.get("success", false)):
				if not can_spend_action(1, 1):
					hint_requested.emit("Not enough action/energy.")
					status_changed.emit()
					return
				if action_id in ["push", "pull"] and WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(world_object):
					if not has_heavy_claw_capability():
						hint_requested.emit("Heavy Claw required.")
						status_changed.emit()
						return
					var target_destination := get_heavy_claw_move_destination(target_position, grid_position, action_id)
					if target_destination.x < 0 or target_destination.y < 0:
						hint_requested.emit("Heavy Claw move is unavailable for this direction.")
						status_changed.emit()
						return
					var move_result: Dictionary = Dictionary(mission_manager.move_world_object_by_heavy_claw(String(world_object.get("id", "")), target_destination))
					if bool(move_result.get("success", false)):
						spend_action(1, 1)
						_register_successful_paid_player_action(true)
						hint_requested.emit(String(move_result.get("message", "Moved object.")))
						refresh_world_object_overlay()
						update_threat_detection_preview()
						emit_facing_world_object_hint()
						refresh_world_action_panel()
						status_changed.emit()
						return
					hint_requested.emit(String(move_result.get("message", "Cannot move object there.")))
					status_changed.emit()
					return
				if action_id == "insert_fuse" and not consume_held_world_item_if_type("fuse"):
					hint_requested.emit("Fuse required.")
					status_changed.emit()
					return
				var moved := _apply_world_object_effects(action_result.get("effects", []), world_object, target_position, actor)
				if not moved:
					mission_manager.set_world_object_at_cell(target_position, world_object)
				if action_id == "switch":
					var object_type := String(world_object.get("object_type", "")).strip_edges().to_lower()
					object_type = object_type.replace(" ", "_").replace("-", "_")
					if object_type in ["light_switch", "circuit_switch", "circuit_breaker"]:
						var reason := "switch_toggled"
						if object_type == "circuit_breaker":
							reason = "circuit_breaker_toggled"
						var power_filter := ""
						if mission_manager.has_method("_get_power_event_filter_for_object"):
							power_filter = String(mission_manager.call("_get_power_event_filter_for_object", world_object))
						var apply_report := apply_power_network_after_explicit_power_event(reason, power_filter)
						if action_result is Dictionary:
							action_result["power_apply_report"] = apply_report
				elif action_id == "insert_fuse":
					var power_filter := ""
					if mission_manager.has_method("_get_power_event_filter_for_object"):
						power_filter = String(mission_manager.call("_get_power_event_filter_for_object", world_object))
					var apply_report := apply_power_network_after_explicit_power_event("fuse_inserted", power_filter)
					if action_result is Dictionary:
						action_result["power_apply_report"] = apply_report
				refresh_world_object_overlay()
				update_threat_detection_preview()
				clear_selected_world_action_if_invalid(world_object, target_position)
				emit_facing_world_object_hint()
				refresh_world_action_panel()
				spend_action(1, 1)
				_register_successful_paid_player_action(true)
				hint_requested.emit("%s (%s): %s | Action: %s" % [world_object.get("display_name", "Object"), world_object.get("state", "unknown"), String(action_result.get("message", "Action complete.")), action_id])
			else:
				hint_requested.emit(String(action_result.get("message", "Action failed.")))
			status_changed.emit()
			return

	match target_tile:
		GridManager.TILE_COMPONENT:
			pick_up_component(target_position, active_manipulator)
			return
		GridManager.TILE_KEY:
			if not can_use_physical_hand():
				hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
				status_changed.emit()
				return
			pick_up_key(target_position, active_manipulator)
		GridManager.TILE_DOOR:
			if not can_use_physical_hand():
				hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
				status_changed.emit()
				return
			open_door(target_position, active_manipulator)
		GridManager.TILE_ROUTE_GATE:
			open_route_gate(target_position)
		_:
			print("Nothing to interact with at: ", target_position)
			hint_requested.emit("Nothing to interact with. Face a key, door, or terminal and press E.")

func _apply_world_object_effects(effects: Array, world_object: Dictionary, target_position: Vector2i, actor: Dictionary = {}) -> bool:
	var object_moved := false
	for effect in effects:
		if effect is String and String(effect) == "power_recalc_needed":
			var network_id_text := String(world_object.get("power_network_id", ""))
			if not network_id_text.is_empty():
				PowerSystemRef.recalculate_network(mission_manager.mission_world_objects, network_id_text)
			continue
		if not (effect is Dictionary):
			continue
		var effect_type := String(effect.get("type", ""))
		if effect_type == "state_set":
			world_object["state"] = effect.get("state", world_object.get("state", ""))
		elif effect_type == "set_blocks_movement":
			world_object["blocks_movement"] = effect.get("value", world_object.get("blocks_movement", false))
		elif effect_type == "power_recalc_needed":
			var network_id := String(world_object.get("power_network_id", ""))
			if not network_id.is_empty():
				PowerSystemRef.recalculate_network(mission_manager.mission_world_objects, network_id)
		elif effect_type == "apply_terminal_controls":
			var control_messages := _apply_terminal_controls(world_object)
			if not control_messages.is_empty():
				hint_requested.emit(" ".join(control_messages))
		elif effect_type == "damage_target":
			var amount := int(effect.get("amount", 0))
			world_object["durability_current"] = maxi(0, int(world_object.get("durability_current", world_object.get("durability_max", 0))) - amount)
			if int(world_object.get("durability_current", 0)) <= 0:
				world_object["state"] = "destroyed"
				world_object["behavior_state"] = "idle"
				world_object["blocks_movement"] = false
				for drop_id in Array(world_object.get("drops", [])):
					var drop := WorldObjectCatalog.create_world_object(String(drop_id), "%s_drop_%s" % [String(world_object.get("id", "threat")), String(drop_id)])
					if not drop.is_empty():
						mission_manager.add_item_at_cell(target_position, drop)
		elif effect_type == "set_state":
			var next_state := String(effect.get("state", world_object.get("state", "")))
			if next_state == "stunned":
				if not world_object.has("state_before_stun"):
					world_object["state_before_stun"] = world_object.get("state", "active")
				if not world_object.has("behavior_before_stun"):
					world_object["behavior_before_stun"] = world_object.get("behavior_state", "idle")
			world_object["state"] = next_state
		elif effect_type == "set_behavior_state":
			world_object["behavior_state"] = effect.get("behavior_state", world_object.get("behavior_state", "idle"))
		elif effect_type == "set_stunned_turns":
			world_object["stunned_turns"] = int(effect.get("value", 1))
		elif effect_type == "drain_energy":
			var drained := mini(5, int(effect.get("amount", 0)))
			world_object["drain_energy_pool"] = maxi(0, int(world_object.get("drain_energy_pool", 0)) - drained)
			world_object["drained_this_turn"] = true
			energy = mini(max_energy, energy + drained)
		elif effect_type == "activate_platform":
			if String(world_object.get("object_group", "")) == "terminal" and String(world_object.get("terminal_type", "")) == "platform":
				var target_platform_id := String(world_object.get("target_platform_id", ""))
				if target_platform_id.is_empty():
					hint_requested.emit("Platform terminal target is missing.")
				else:
					var platform_result: Dictionary = Dictionary(mission_manager.activate_platform_by_id(target_platform_id, "terminal"))
					hint_requested.emit(String(platform_result.get("message", "Platform action.")))
			elif String(world_object.get("object_group", "")) == "platform":
				var platform_result_direct: Dictionary = Dictionary(mission_manager.activate_platform_by_id(String(world_object.get("platform_id", "")), "local_switch"))
				hint_requested.emit(String(platform_result_direct.get("message", "Platform action.")))
		elif effect_type == "object_move":
			var move_dir := Vector2i(effect.get("direction", actor.get("facing_direction", Vector2i.ZERO)))
			if move_dir == Vector2i.ZERO and effect.has("dx"):
				move_dir = Vector2i(int(effect.get("dx", 0)), int(effect.get("dy", 0)))
			var mode := String(effect.get("mode", "push"))
			var destination := target_position + move_dir
			if mode == "pull":
				destination = target_position + move_dir
			if mission_manager != null and mission_manager.has_method("can_move_between_height_levels"):
				var can_move_object_height_variant: Variant = mission_manager.call("can_move_between_height_levels", target_position, destination, null)
				if not bool(can_move_object_height_variant):
					hint_requested.emit("Height mismatch.")
					continue
			if grid_manager != null and grid_manager.is_in_bounds(destination) and grid_manager.is_walkable(destination) and mission_manager.get_world_object_at_cell(destination).is_empty():
				mission_manager.remove_world_object_at_cell(target_position)
				world_object["position"] = destination
				if mission_manager != null and mission_manager.has_method("refresh_world_object_platform_height_state"):
					mission_manager.call("refresh_world_object_platform_height_state", world_object)
				mission_manager.set_world_object_at_cell(destination, world_object)
				object_moved = true
	if world_object.get("state", "") in ["open", "destroyed", "inactive", "unpowered", "disabled"]:
		world_object["blocks_movement"] = false
	return object_moved

func _apply_terminal_controls(terminal: Dictionary) -> Array[String]:
	var messages: Array[String] = []
	var controls: Array = terminal.get("controls", [])
	if controls.is_empty():
		messages.append("Terminal hacked. No linked devices.")
		return messages
	for controlled_id in controls:
		var controlled: Dictionary = Dictionary(mission_manager.get_world_object_by_id(String(controlled_id)))
		if controlled.is_empty():
			messages.append("Terminal hacked. Linked device not found: %s." % String(controlled_id))
			continue
		var terminal_type := String(terminal.get("object_type", ""))
		if terminal_type == "door_terminal" and String(controlled.get("object_group", "")) == "door":
			controlled["state"] = "open"
			controlled["blocks_movement"] = false
			messages.append("Terminal control applied: %s opened." % String(controlled_id))
		elif terminal_type == "turret_terminal" and String(controlled.get("object_type", "")) == "turret":
			controlled["state"] = "disabled"
			messages.append("Terminal control applied: %s disabled." % String(controlled_id))
		elif terminal_type == "cooling_terminal":
			controlled["state"] = "unpowered" if String(controlled.get("state", "active")) == "active" else "active"
			messages.append("Terminal control applied: %s toggled." % String(controlled_id))
		elif terminal_type == "information_terminal":
			hint_requested.emit("Information downloaded.")
		mission_manager.update_world_object_by_id(String(controlled_id), controlled)
	return messages

func refresh_world_object_overlay() -> void:
	if mission_manager == null or grid_manager == null:
		return
	var markers := {}
	for cell_variant in mission_manager.world_objects_by_cell.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		var obj: Dictionary = {}
		if mission_manager.has_method("get_world_object_at_cell"):
			obj = Dictionary(mission_manager.call("get_world_object_at_cell", cell))
		else:
			var raw_value: Variant = mission_manager.world_objects_by_cell.get(cell_variant, {})
			if raw_value is Dictionary:
				obj = Dictionary(raw_value)
			elif raw_value is Array and not Array(raw_value).is_empty() and Array(raw_value)[0] is Dictionary:
				obj = Dictionary(Array(raw_value)[0])
		if obj.is_empty() or obj.get("state", "") in ["destroyed", "open", "inactive"]:
			continue
		markers[cell] = _get_world_marker(obj)
	for cell in mission_manager.cell_items.keys():
		if markers.has(cell):
			continue
		var items: Array = mission_manager.cell_items[cell]
		if items.is_empty():
			continue
		markers[cell] = _get_world_marker(items[0])
	grid_manager.set_world_overlay_markers(markers)

func update_threat_detection_preview() -> void:
	if mission_manager == null:
		return
	var threats: Array = mission_manager.get_threats()
	if threats.is_empty():
		return
	var detected_results: Array[Dictionary] = []
	var detected_ids: Dictionary = {}
	var threat_state_changed := false
	for threat_variant in threats:
		var threat: Dictionary = Dictionary(threat_variant)
		var threat_id := String(threat.get("id", ""))
		if threat_id.is_empty():
			continue
		var detection: Dictionary = Dictionary(mission_manager.get_threat_detection_result(threat, grid_position, grid_manager))
		var is_detected := bool(detection.get("detected", false))
		if is_detected:
			detected_results.append(detection)
			detected_ids[threat_id] = detection.get("detection_mode", "")
			if String(threat.get("behavior_state", "")) != "alert":
				threat["behavior_state"] = "alert"
				threat_state_changed = true
			if String(threat.get("object_type", "")) == "turret":
				if Vector2i(threat.get("target_position", Vector2i(-999, -999))) != grid_position:
					threat_state_changed = true
				threat["target_position"] = grid_position
		elif String(threat.get("behavior_state", "")) in ["alert", "attack_preview"] and mission_manager.is_threat_active(threat):
			threat["behavior_state"] = "idle"
			threat_state_changed = true
			if threat.has("target_position"):
				threat.erase("target_position")
				threat_state_changed = true
		if not mission_manager.is_threat_active(threat):
			if String(threat.get("behavior_state", "")) != "idle":
				threat["behavior_state"] = "idle"
				threat_state_changed = true
			if threat.has("target_position"):
				threat.erase("target_position")
				threat_state_changed = true
			mission_manager.last_threat_warning_ids.erase(threat_id)
	var previous: Dictionary = mission_manager.last_threat_warning_ids
	var should_warn := detected_results.size() != previous.size()
	if not should_warn:
		for threat_id in detected_ids.keys():
			if not previous.has(threat_id) or String(previous[threat_id]) != String(detected_ids[threat_id]):
				should_warn = true
				break
	mission_manager.last_threat_warning_ids = detected_ids.duplicate()
	if threat_state_changed or should_warn:
		refresh_world_object_overlay()
	if should_warn and not detected_results.is_empty():
		if detected_results.size() == 1:
			hint_requested.emit("Warning: %s detected Bipop." % String(detected_results[0].get("threat_name", "Threat")))
		else:
			hint_requested.emit("Warning: %d threats detected Bipop." % detected_results.size())
	elif should_warn and detected_results.is_empty() and previous.size() > 0:
		hint_requested.emit("Threat warning cleared.")

func _get_world_marker(object_data: Dictionary) -> String:
	var object_type := String(object_data.get("object_type", ""))
	var state := String(object_data.get("state", ""))
	if state == "destroyed":
		return "DB"
	if state == "stunned":
		return "ST"
	if state == "hacked":
		return "HK"
	if object_type == "turret" and state == "unpowered":
		return "TO"
	if object_type == "turret" and String(object_data.get("behavior_state", "")) in ["alert", "attack_preview"]:
		return "TA"
	var labels := {"steel_door":"D","energy_door":"ED","grid_door":"GD","brick_wall":"BW","damaged_wall":"DW","energy_wall":"EW","door_terminal":"T","information_terminal":"IT","power_cable":"C","power_source_class_1":"PS","circuit_breaker":"BR","fuse_box_installed":"FB","fuse_box_empty":"FE","fuse":"F","mechanical_keycard":"K","digital_key_opened":"DK","data_file_encrypted":"DF","normal_crate":"CR","heavy_crate":"HC","barrel":"BA","debris":"DB","enemy_robot":"ER","turret":"TU","bug":"BG","vagus":"VG"}
	return labels.get(object_type, String(object_data.get("object_group", "O")).substr(0, 2).to_upper())

func setup_mission8() -> void:
	mission8_fan_platform_position = Vector2i(4, 2)
	mission8_platform_control_position = Vector2i(2, 2)
	mission8_platform_left_control_position = Vector2i(2, 2)
	mission8_platform_right_control_position = Vector2i(5, 2)
	mission8_fan_control_position = Vector2i(2, 4)
	mission8_fan_speed_up_control_position = Vector2i(2, 3)
	mission8_fan_speed_down_control_position = Vector2i(2, 4)
	mission8_terminal_position = Vector2i(6, 3)
	mission8_door_position = Vector2i(6, 4)
	mission8_fan_direction = Direction.EAST
	mission8_fan_speed = 0
	mission8_terminal_cooled = false
	mission8_terminal_hacked = false
	mission8_airflow_cells.clear()
	update_mission8_airflow()

func get_direction_display_name(direction_value: Direction) -> String:
	match direction_value:
		Direction.NORTH:
			return "NORTH"
		Direction.EAST:
			return "EAST"
		Direction.SOUTH:
			return "SOUTH"
		Direction.WEST:
			return "WEST"
	return "UNKNOWN"

func get_direction_name(value: Direction) -> String:
	match value:
		Direction.NORTH:
			return "NORTH"
		Direction.EAST:
			return "EAST"
		Direction.SOUTH:
			return "SOUTH"
		Direction.WEST:
			return "WEST"
		_:
			return "UNKNOWN"

func get_mission8_airflow_status_text() -> String:
	if current_mission_index != 8:
		return ""

	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	return "Airflow: %s | Speed: %d | Range: %d | Terminal: %s" % [
		get_direction_display_name(mission8_fan_direction),
		mission8_fan_speed,
		airflow_range,
		get_mission8_terminal_state_text()
	]

func get_mission7_cable_status_text() -> String:
	if current_mission_index != 7:
		return ""
	if mission7_cable_connected:
		return "Cable: connected"
	if mission7_is_dragging_cable:
		return "Cable: dragging"
	return "Cable: idle"

func setup_mission7() -> void:
	mission7_is_dragging_cable = false
	mission7_cable_connected = false
	mission7_cable_reel_position = Vector2i(2, 1)
	mission7_socket_position = Vector2i(5, 3)
	mission7_powered_gate_position = Vector2i(6, 4)
	mission7_cable_path.clear()
	# TODO(BIB-360): cable max-length behavior is intentionally not enforced in MVP.

func interact_mission7_cable_reel() -> void:
	if mission7_cable_connected:
		hint_requested.emit("Cable is already connected.")
		return
	if mission7_is_dragging_cable:
		hint_requested.emit("Cable already in hand. Drag it to the socket.")
		return
	if held_module != null:
		hint_requested.emit("Hand occupied. Drop or store the item before taking the cable.")
		return
	if not can_spend_action(1, 1):
		return
	mission7_is_dragging_cable = true
	mission7_cable_path.clear()
	mission7_cable_path.append(grid_position)
	hint_requested.emit("Cable end taken. Drag it to the socket.")
	spend_action(1, 1)
	status_changed.emit()

func interact_mission7_socket() -> void:
	if not mission7_is_dragging_cable:
		hint_requested.emit("Take the cable end from the reel first.")
		return
	if mission7_cable_connected:
		hint_requested.emit("Socket already connected.")
		return
	if not can_spend_action(1, 1):
		return
	mission7_is_dragging_cable = false
	mission7_cable_connected = true
	if mission_manager != null:
		var mission7_cable_object: Dictionary = Dictionary(mission_manager.get_world_object_by_id("cable_a"))
		if not mission7_cable_object.is_empty():
			mission7_cable_object["state"] = "connected"
			mission7_cable_object["connected"] = true
			var power_filter := ""
			if mission_manager.has_method("_get_power_event_filter_for_object"):
				power_filter = String(mission_manager.call("_get_power_event_filter_for_object", mission7_cable_object))
			apply_power_network_after_explicit_power_event("cable_connected", power_filter)
	if grid_manager.get_tile(mission7_powered_gate_position) == GridManager.TILE_POWERED_GATE:
		grid_manager.set_tile(mission7_powered_gate_position, GridManager.TILE_FLOOR)
	hint_requested.emit("Cable connected. Powered gate opened.")
	spend_action(1, 1)
	status_changed.emit()

func add_current_cell_to_mission7_cable_path() -> void:
	if grid_manager == null or mission7_cable_connected or not mission7_is_dragging_cable:
		return
	if not mission7_cable_path.has(grid_position):
		mission7_cable_path.append(grid_position)
	var tile := grid_manager.get_tile(grid_position)
	if tile == GridManager.TILE_FLOOR:
		grid_manager.set_tile(grid_position, GridManager.TILE_CABLE)

func clear_mission7_cable_tiles() -> void:
	if grid_manager == null:
		mission7_cable_path.clear()
		return
	for cable_position in mission7_cable_path:
		if grid_manager.is_in_bounds(cable_position) and grid_manager.get_tile(cable_position) == GridManager.TILE_CABLE:
			grid_manager.set_tile(cable_position, GridManager.TILE_FLOOR)
	mission7_cable_path.clear()

func release_mission7_cable_end() -> void:
	if not mission7_is_dragging_cable:
		hint_requested.emit("No cable in hand.")
		return
	mission7_is_dragging_cable = false
	clear_mission7_cable_tiles()
	hint_requested.emit("Cable released. Return to the reel to take it again.")
	status_changed.emit()

func get_mission8_terminal_state_text() -> String:
	return "cooled" if mission8_terminal_cooled else "hot"

func rotate_mission8_fan_left() -> void:
	mission8_fan_direction = Direction.values()[(int(mission8_fan_direction) + 3) % 4]
	update_mission8_airflow()
	hint_requested.emit("Fan platform rotated left. Airflow: %s | Terminal: %s" % [get_direction_display_name(mission8_fan_direction), get_mission8_terminal_state_text()])
	status_changed.emit()

func rotate_mission8_fan_right() -> void:
	mission8_fan_direction = Direction.values()[(int(mission8_fan_direction) + 1) % 4]
	update_mission8_airflow()
	hint_requested.emit("Fan platform rotated right. Airflow: %s | Terminal: %s" % [get_direction_display_name(mission8_fan_direction), get_mission8_terminal_state_text()])
	status_changed.emit()

func interact_mission8_platform_control_left() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Platform control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	spend_action(1, 1)
	rotate_mission8_fan_left()

func interact_mission8_platform_control_right() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Platform control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	spend_action(1, 1)
	rotate_mission8_fan_right()

func interact_mission8_fan_control() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Fan control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	mission8_fan_speed = (mission8_fan_speed + 1) % 4
	spend_action(1, 1)
	update_mission8_airflow()
	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	hint_requested.emit("Fan speed set to %d. Airflow range: %d | Terminal: %s." % [mission8_fan_speed, airflow_range, get_mission8_terminal_state_text()])
	status_changed.emit()

func change_mission8_fan_speed(delta: int) -> void:
	if current_mission_index != 8:
		hint_requested.emit("Fan speed controls are inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return

	var previous_speed := mission8_fan_speed
	mission8_fan_speed = clampi(mission8_fan_speed + delta, 0, 3)
	if mission8_fan_speed == previous_speed:
		if delta > 0:
			hint_requested.emit("Fan speed already at maximum.")
		else:
			hint_requested.emit("Fan speed already at minimum.")
		status_changed.emit()
		return

	update_mission8_airflow()
	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	hint_requested.emit(
		"Fan speed set to %d. Airflow range: %d | Terminal: %s" % [
			mission8_fan_speed,
			airflow_range,
			get_mission8_terminal_state_text()
		]
	)
	spend_action(1, 1)
	status_changed.emit()

func increase_mission8_fan_speed() -> void:
	change_mission8_fan_speed(1)

func decrease_mission8_fan_speed() -> void:
	change_mission8_fan_speed(-1)

func get_mission8_airflow_range_for_speed(speed: int) -> int:
	match speed:
		0:
			return 0
		1:
			return 2
		2:
			return 4
		3:
			return 6
		_:
			return 0

func update_mission8_airflow() -> void:
	if grid_manager == null:
		return
	for cell in mission8_airflow_cells:
		if not grid_manager.is_in_bounds(cell):
			continue
		if grid_manager.get_tile(cell) == GridManager.TILE_AIRFLOW:
			grid_manager.set_tile(cell, GridManager.TILE_FLOOR)
	mission8_airflow_cells.clear()
	mission8_terminal_cooled = false
	grid_manager.set_fan_platform_marker(
		mission8_fan_platform_position,
		get_direction_vector(mission8_fan_direction)
	)

	if mission8_fan_speed <= 0:
		grid_manager.queue_redraw()
		status_changed.emit()
		return

	var max_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	var direction_vector := get_direction_vector(mission8_fan_direction)
	var current_position := mission8_fan_platform_position + direction_vector

	for _i in range(max_range):
		if not grid_manager.is_in_bounds(current_position):
			break
		if current_position == mission8_terminal_position:
			mission8_terminal_cooled = true
			break
		var tile := grid_manager.get_tile(current_position)
		if tile == GridManager.TILE_WALL or tile == GridManager.TILE_DIGITAL_DOOR or tile == GridManager.TILE_ROUTE_GATE:
			break
		if tile == GridManager.TILE_AIRFLOW_TERMINAL:
			mission8_terminal_cooled = true
			break
		if tile == GridManager.TILE_FAN_PLATFORM or tile == GridManager.TILE_PLATFORM_CONTROL or tile == GridManager.TILE_PLATFORM_CONTROL_LEFT or tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT or tile == GridManager.TILE_FAN_CONTROL or tile == GridManager.TILE_FAN_SPEED_UP_CONTROL or tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			break
		if tile == GridManager.TILE_FLOOR or tile == GridManager.TILE_AIRFLOW:
			grid_manager.set_tile(current_position, GridManager.TILE_AIRFLOW)
			mission8_airflow_cells.append(current_position)
		current_position += direction_vector

	grid_manager.queue_redraw()
	status_changed.emit()

func create_debug_field_component() -> BipobModule:
	var module := BipobModule.new()
	module.id = "cooling_v1"
	module.display_name = "Cooling V1"
	module.description = "Basic cooling component for future internal builds."
	module.energy_bonus = 0
	module.actions_bonus = 0
	module.vision_bonus = 0
	module.granted_commands = []
	return module

func get_position_key(cell_position_arg: Vector2i) -> String:
	return str(cell_position_arg.x) + "," + str(cell_position_arg.y)

func set_field_module(cell_position_arg: Vector2i, module: BipobModule) -> void:
	if grid_manager == null:
		return
	if module == null:
		return
	if not grid_manager.is_in_bounds(cell_position_arg):
		return

	grid_manager.set_tile(cell_position_arg, GridManager.TILE_COMPONENT)
	field_modules_by_position[get_position_key(cell_position_arg)] = module

func get_field_module(cell_position_arg: Vector2i) -> BipobModule:
	var key := get_position_key(cell_position_arg)
	if field_modules_by_position.has(key):
		return field_modules_by_position[key]
	return null

func clear_field_module(cell_position_arg: Vector2i) -> void:
	var key := get_position_key(cell_position_arg)
	if field_modules_by_position.has(key):
		field_modules_by_position.erase(key)

func place_visor_v2_field_module(slot_position: Vector2i) -> void:
	set_field_module(slot_position, create_visor_v2_module())

func place_gpu_v1_field_module(slot_position: Vector2i) -> void:
	set_field_module(slot_position, create_gpu_v1_module())

func setup_mission4_field_modules() -> void:
	if grid_manager == null:
		return

	var visor_position := Vector2i(4, 1)
	var gpu_position := Vector2i(2, 6)
	var hidden_node_position := Vector2i(4, 6)

	if not has_module_id_anywhere("visor_v2"):
		place_visor_v2_field_module(visor_position)
	else:
		grid_manager.set_tile(visor_position, GridManager.TILE_FLOOR)

	if not has_module_id_anywhere("gpu_v1"):
		place_gpu_v1_field_module(gpu_position)
	else:
		grid_manager.set_tile(gpu_position, GridManager.TILE_FLOOR)

	active_hidden_route_node_position = Vector2i(-1, -1)
	if grid_manager.is_in_bounds(hidden_node_position):
		grid_manager.set_tile(hidden_node_position, GridManager.TILE_HIDDEN_ROUTE_NODE)
		active_hidden_route_node_position = hidden_node_position

func place_debug_field_module_if_valid(slot_position: Vector2i, module_name: String, place_callback: Callable) -> void:
	if grid_manager == null:
		return
	if not grid_manager.is_in_bounds(slot_position):
		print("Skipping debug field module ", module_name, ": out of bounds at ", slot_position)
		hint_requested.emit("Debug module %s skipped: invalid position %s." % [module_name, str(slot_position)])
		return
	if grid_manager.get_tile(slot_position) != GridManager.TILE_FLOOR:
		print("Skipping debug field module ", module_name, ": blocked tile at ", slot_position)
		hint_requested.emit("Debug module %s skipped: tile blocked at %s." % [module_name, str(slot_position)])
		return
	place_callback.call(slot_position)

func place_debug_mission4_field_modules() -> void:
	place_debug_field_module_if_valid(Vector2i(4, 1), "Visor V2", Callable(self, "place_visor_v2_field_module"))
	place_debug_field_module_if_valid(Vector2i(4, 3), "GPU V1", Callable(self, "place_gpu_v1_field_module"))

func get_carried_physical_count() -> int:
	return get_manipulator_items().size() + get_pocket_items().size()

func is_hand_occupied() -> bool:
	return _get_first_free_manipulator_index() == -1

func can_use_physical_hand() -> bool:
	return not is_hand_occupied() and buffer_item.is_empty()

func get_held_world_item_type() -> String:
	if buffer_item.is_empty():
		return ""
	return String(buffer_item.get("item_type", buffer_item.get("id", "")))

func has_held_world_item(item_type: String) -> bool:
	return get_held_world_item_type() == item_type

func consume_held_world_item_if_type(item_type: String) -> bool:
	if not has_held_world_item(item_type):
		return false
	buffer_item.clear()
	return true

func infer_digital_item_family(item_type: String) -> String:
	if item_type.begins_with("digital_key"):
		return "digital_key"
	if item_type.begins_with("data_file"):
		return "data_file"
	return item_type

func has_digital_world_item(item_type: String, digital_state: String = "opened") -> bool:
	var record: Dictionary = digital_world_records.get(item_type, {})
	if record.is_empty():
		return false
	return String(record.get("digital_state", "opened")) == digital_state

func is_physical_storage_occupied() -> bool:
	return _get_first_free_pocket_index() == -1

func has_free_physical_storage() -> bool:
	return _get_first_free_pocket_index() != -1

func has_any_physical_item() -> bool:
	return get_carried_physical_count() > 0

func can_pick_up_physical_item() -> bool:
	return get_carried_physical_count() < (available_manipulator_slots + available_pocket_slots)

func pick_up_component(component_position: Vector2i, manipulator_module: BipobModule = null) -> void:
	if grid_manager == null:
		return
	if grid_manager.get_tile(component_position) != GridManager.TILE_COMPONENT:
		hint_requested.emit("No component to pick up here.")
		status_changed.emit()
		return
	if _get_first_free_manipulator_index() == -1 and is_physical_storage_occupied():
		hint_requested.emit("Physical storage full. Drop or deliver an item first.")
		status_changed.emit()
		return

	if not can_spend_action(1, 0):
		return
	if not spend_energy_for_manipulator_action(manipulator_module):
		hint_requested.emit("Not enough energy for manipulator action.")
		status_changed.emit()
		return

	var picked_module := get_field_module(component_position)
	if picked_module == null:
		picked_module = create_debug_field_component()

	clear_field_module(component_position)
	grid_manager.set_tile(component_position, GridManager.TILE_FLOOR)

	var free_manipulator_index := _get_first_free_manipulator_index()
	if free_manipulator_index != -1:
		manipulator_items[free_manipulator_index] = picked_module
		hint_requested.emit("Component collected in hand: %s." % get_module_display_name(picked_module))
	else:
		var free_pocket_index := _get_first_free_pocket_index()
		if free_pocket_index == -1:
			hint_requested.emit("No free pocket slot.")
			status_changed.emit()
			return
		pocket_items[free_pocket_index] = picked_module
		hint_requested.emit("Component stored in pocket: %s." % get_module_display_name(picked_module))

	if current_mission_index == 4:
		if picked_module.id == "visor_v2":
			hint_requested.emit("Visor V2 recovered. Return to the box and install it.")
		elif picked_module.id == "gpu_v1":
			hint_requested.emit("GPU V1 recovered. Return to the box and install it.")

	spend_action(1, 0)
	status_changed.emit()


func rotate_physical_storage() -> void:
	if mission_finished:
		return

	if not has_any_physical_item():
		hint_requested.emit("No physical items to rotate.")
		status_changed.emit()
		return

	if not can_spend_action(1, 0):
		return

	_rotate_first_manipulator_and_pocket()
	spend_action(1, 0)
	hint_requested.emit("Rotated physical storage.")
	status_changed.emit()

func drop_held_item() -> void:
	if mission_finished:
		return
	if current_mission_index == 7 and mission7_is_dragging_cable:
		release_mission7_cable_end()
		return

	var active_index := _get_first_occupied_manipulator_index()
	if active_index == -1:
		hint_requested.emit("Hand is empty. Nothing to drop.")
		status_changed.emit()
		return

	var target_position := grid_position + get_direction_vector(direction)
	if not grid_manager.is_in_bounds(target_position) or grid_manager.get_tile(target_position) != GridManager.TILE_FLOOR:
		hint_requested.emit("Cannot drop item here. Face an empty floor cell.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	var module_to_drop := manipulator_items[active_index]
	set_field_module(target_position, module_to_drop)
	spend_action(1, 1)
	hint_requested.emit("Dropped: %s." % get_module_display_name(module_to_drop))
	manipulator_items[active_index] = null
	_sync_legacy_physical_slots()
	status_changed.emit()

func break_installed_module(module: BipobModule, _bipob = null) -> void:
	if module == null:
		return
	var installed_index: int = installed_modules.find(module)
	if installed_index != -1:
		installed_modules.remove_at(installed_index)
	set_module_broken(module, true)
	var free_pocket_index: int = _get_first_free_pocket_index()
	if free_pocket_index != -1:
		pocket_items[free_pocket_index] = module
		hint_requested.emit("%s broke and moved to pocket." % get_module_display_name(module))
	else:
		var front_position: Vector2i = grid_position + get_direction_vector(direction)
		var drop_position: Vector2i = grid_position
		if grid_manager != null and grid_manager.is_in_bounds(front_position) and grid_manager.get_tile(front_position) == GridManager.TILE_FLOOR and get_field_module(front_position) == null:
			drop_position = front_position
		if grid_manager != null and grid_manager.is_in_bounds(drop_position):
			set_field_module(drop_position, module)
		else:
			# TODO(BIB-539): fallback when runtime grid context is unavailable.
			box_storage.append(module)
		hint_requested.emit("%s broke and dropped." % get_module_display_name(module))
	_sync_legacy_physical_slots()
	recalculate_module_stats()
	status_changed.emit()


func read_terminal(target_position: Vector2i) -> void:
	if not require_command("read_terminal", "Missing module: Interface V1 required."):
		return
	match current_mission_index:
		2:
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			print("Terminal is silent. Interface calibration required.")
			hint_requested.emit("Terminal is silent. Interface calibration required.")
			complete_mission()
			return
		3:
			if not can_spend_action(1, 1):
				return
			has_info_key = true
			store_digital_record(DIGITAL_RECORD_INFO_KEY, "Info-Key", "Digital authorization record for opening a digital door.")
			spend_action(1, 1)
			print("Terminal accessed at ", target_position, ". Info-Key downloaded.")
			hint_requested.emit("Info-Key downloaded. Find the digital door.")
			status_changed.emit()
			print_status()
			return
		_:
			print("Terminal is inactive in this mission.")
			hint_requested.emit("Terminal is inactive in this mission.")

func pick_up_key(key_position: Vector2i, manipulator_module: BipobModule = null) -> void:
	if not can_use_physical_hand():
		hint_requested.emit("Free manipulator required to use a key.")
		status_changed.emit()
		return
	if not require_command("interact_key", "Missing module: Manipulator V1 required."):
		return
	if not can_spend_action(1, 0):
		return
	if not spend_energy_for_manipulator_action(manipulator_module):
		hint_requested.emit("Not enough energy for manipulator action.")
		status_changed.emit()
		return
	has_key = true
	grid_manager.set_tile(key_position, GridManager.TILE_FLOOR)
	spend_action(1, 0)
	print("Picked up physical key.")
	hint_requested.emit("Physical key collected. Use Interact on the physical door.")
	print_status()

func get_available_manipulator_slots() -> int:
	return clampi(available_manipulator_slots, 0, get_max_manipulator_slots())

func get_max_manipulator_slots() -> int:
	return max_manipulator_slots

func get_manipulator_items() -> Array:
	return manipulator_items.duplicate()

func get_available_pocket_slots() -> int:
	return clampi(available_pocket_slots, 0, get_max_pocket_slots())

func get_max_pocket_slots() -> int:
	return max_pocket_slots

func get_pocket_items() -> Array:
	return pocket_items.duplicate()

func get_key_count() -> int:
	return 1 if has_key else 0

func get_available_digital_storage_slots() -> int:
	return clampi(available_digital_storage_slots, 0, get_max_digital_storage_slots())

func get_max_digital_storage_slots() -> int:
	return max_digital_storage_slots

func get_digital_storage_items() -> Array:
	var items: Array = []
	for key in digital_storage.keys():
		items.append(digital_storage[key])
	return items

func get_buffer_item() -> Variant:
	if buffer_item.is_empty():
		return null
	return buffer_item

func move_pocket_to_manipulator(pocket_index: int) -> bool:
	if pocket_index < 0 or pocket_index >= get_available_pocket_slots():
		return false
	if pocket_items[pocket_index] == null:
		hint_requested.emit("No pocket item selected.")
		return false
	var free_index := _get_first_free_manipulator_index()
	if free_index == -1:
		hint_requested.emit("No free manipulator slot.")
		return false
	manipulator_items[free_index] = pocket_items[pocket_index]
	pocket_items[pocket_index] = null
	_sync_legacy_physical_slots()
	status_changed.emit()
	return true

func move_manipulator_to_pocket(manipulator_index: int) -> bool:
	if manipulator_index < 0 or manipulator_index >= get_available_manipulator_slots():
		return false
	if manipulator_items[manipulator_index] == null:
		hint_requested.emit("No manipulator item selected.")
		return false
	var free_index := _get_first_free_pocket_index()
	if free_index == -1:
		hint_requested.emit("No free pocket slot.")
		return false
	pocket_items[free_index] = manipulator_items[manipulator_index]
	manipulator_items[manipulator_index] = null
	_sync_legacy_physical_slots()
	status_changed.emit()
	return true
	
func print_status() -> void:
	print(
		"Energy: ", energy, " / ", max_energy,
		" | Actions: ", actions_left, " / ", actions_per_turn,
		" | Has Key: ", has_key,
		" | Has Info Key: ", has_info_key,
		" | Hand: ", get_module_display_name(held_module) if held_module != null else "empty",
		" | Storage: ", get_module_display_name(stored_physical_module) if stored_physical_module != null else "empty",
		" | Carry: ", get_carried_physical_count(), " / ", physical_carry_capacity
	)
func _initialize_runtime_storage_slots() -> void:
	manipulator_items.resize(max_manipulator_slots)
	pocket_items.resize(max_pocket_slots)
	for i in range(manipulator_items.size()):
		manipulator_items[i] = null
	for i in range(pocket_items.size()):
		pocket_items[i] = null
	_sync_legacy_physical_slots()
	digital_storage_capacity = get_available_digital_storage_slots()

func _sync_legacy_physical_slots() -> void:
	held_module = manipulator_items[0] if manipulator_items.size() > 0 else null
	stored_physical_module = pocket_items[0] if pocket_items.size() > 0 else null
	physical_carry_capacity = get_available_manipulator_slots() + get_available_pocket_slots()

func _get_first_free_manipulator_index() -> int:
	for i in range(get_available_manipulator_slots()):
		if manipulator_items[i] == null:
			return i
	return -1

func _get_first_occupied_manipulator_index() -> int:
	for i in range(get_available_manipulator_slots()):
		if manipulator_items[i] != null:
			return i
	return -1

func _get_first_free_pocket_index() -> int:
	for i in range(get_available_pocket_slots()):
		if pocket_items[i] == null:
			return i
	return -1

func _get_first_occupied_pocket_index() -> int:
	for i in range(get_available_pocket_slots()):
		if pocket_items[i] != null:
			return i
	return -1

func _rotate_first_manipulator_and_pocket() -> void:
	var hand_module: BipobModule = manipulator_items[0]
	manipulator_items[0] = pocket_items[0]
	pocket_items[0] = hand_module
	_sync_legacy_physical_slots()


func _variant_to_dictionary(value: Variant, fallback: Dictionary = {}) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value)
	return fallback

func _variant_to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item_variant in value:
		if typeof(item_variant) == TYPE_DICTIONARY:
			result.append(Dictionary(item_variant))
	return result

func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item_variant in value:
		result.append(String(item_variant))
	return result

func get_terminal_action_availability(terminal_id: String, action: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_terminal_action_availability"):
		return {"available":false, "terminal_id":terminal_id, "action":action, "reasons":["terminal_missing"]}
	return _variant_to_dictionary(mission_manager.call("get_terminal_action_availability", terminal_id, action))

func get_terminal_hack_requirements(terminal_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_terminal_hack_requirements"):
		return {"can_hack":false, "terminal_id":terminal_id, "reasons":["terminal_missing"]}
	return _variant_to_dictionary(mission_manager.call("get_terminal_hack_requirements", terminal_id))

func attempt_terminal_hack(terminal_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("attempt_terminal_hack"):
		return {"success":false, "terminal_id":terminal_id, "reasons":["terminal_missing"]}
	return _variant_to_dictionary(mission_manager.call("attempt_terminal_hack", terminal_id))

func get_terminal_control_targets(terminal_id: String) -> Array[Dictionary]:
	if mission_manager == null or not mission_manager.has_method("get_terminal_control_targets"):
		return []
	return _variant_to_dictionary_array(mission_manager.call("get_terminal_control_targets", terminal_id))

func execute_terminal_control_action(terminal_id: String, target_id: String = "", action: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("execute_terminal_control_action"):
		return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":["terminal_missing"]}
	return _variant_to_dictionary(mission_manager.call("execute_terminal_control_action", terminal_id, target_id, action))

func get_door_access_state(door_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_door_access_state"):
		return {"door_id":door_id, "can_open":false, "reasons":["door_missing"]}
	return _variant_to_dictionary(mission_manager.call("get_door_access_state", door_id))

func can_use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("can_use_access_item_on_door"):
		return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["item_missing"]}
	return _variant_to_dictionary(mission_manager.call("can_use_access_item_on_door", item_id, door_id))

func use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("use_access_item_on_door"):
		return {"success":false, "item_id":item_id, "door_id":door_id, "reasons":["item_missing"]}
	return _variant_to_dictionary(mission_manager.call("use_access_item_on_door", item_id, door_id))

func get_actor_capability_levels() -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_actor_capability_levels"):
		var port_state := preview_module_port_activity()
		return {"manipulator_level": 0, "connector_level": 0, "processor_level": 0, "power_class": "none", "modules": [], "tools": [], "connector_types": [], "port_state": port_state}
	return _variant_to_dictionary(mission_manager.call("get_actor_capability_levels"))

func get_installed_module_port_state() -> Dictionary:
	return preview_module_port_activity()


func _get_module_port_priority(module_id: String) -> int:
	if module_id.begins_with("internal_interface_"):
		return 1
	if module_id.begins_with("power_block_") or module_id.begins_with("battery_"):
		return 2
	if module_id.begins_with("external_interface_"):
		return 3
	if module_id.begins_with("processor_") or module_id.begins_with("memory_"):
		return 4
	if module_id.contains("_connector_") or module_id.begins_with("hard_drive_"):
		return 5
	if module_id in ["wheels_v1", "legs_v1", "tracks_v1", "jumper_v1", "hover_pad_v1"]:
		return 6
	if module_id.begins_with("manipulator_") or module_id.begins_with("gpu_") or module_id.begins_with("visor_") or module_id.begins_with("xray_"):
		return 7
	if module_id.begins_with("radar_"):
		return 8
	return 9


func _get_internal_interface_port_capacity(module_id: String) -> int:
	if module_id.ends_with("_v1"):
		return 6
	if module_id.ends_with("_v2"):
		return 8
	if module_id.ends_with("_v3"):
		return 10
	return 6

func _module_requires_external_interface_port(module_id: String) -> bool:
	if module_id in ["pocket_v1", "air_duct_v1", "radiator_v1"]:
		return false
	if module_id.begins_with("processor_") or module_id.begins_with("memory_") or module_id.begins_with("gpu_"):
		return false
	if module_id.begins_with("hard_drive_") or module_id.begins_with("charger_") or module_id.begins_with("cooler_"):
		return false
	if module_id.begins_with("battery_") or module_id.begins_with("internal_interface_") or module_id.begins_with("external_interface_"):
		return false
	if module_id.begins_with("power_block_"):
		return false
	if module_id in ["wheels_v1", "legs_v1", "tracks_v1", "jumper_v1", "hover_pad_v1"]:
		return true
	if module_id.contains("_connector_"):
		return true
	if module_id.begins_with("visor_") or module_id.begins_with("manipulator_") or module_id.begins_with("radar_"):
		return true
	if module_id.begins_with("xray_") or module_id.begins_with("sensor_") or module_id.begins_with("sledgehammer_"):
		return true
	if module_id.begins_with("tool_"):
		return true
	return false

func _module_requires_internal_interface_port(module_id: String) -> bool:
	if module_id.begins_with("battery_") or module_id in ["radiator_v1", "air_duct_v1", "pocket_v1"]:
		return false
	if module_id.begins_with("internal_interface_"):
		return false
	if module_id.begins_with("external_interface_") or module_id.begins_with("power_block_"):
		return true
	if module_id in ["wheels_v1", "legs_v1", "tracks_v1", "jumper_v1", "hover_pad_v1"]:
		return false
	return module_id.begins_with("processor_") or module_id.begins_with("memory_") or module_id.begins_with("gpu_") or module_id.begins_with("hard_drive_") or module_id.begins_with("charger_") or module_id.begins_with("cooler_")

func _module_requires_power_block_port(module_id: String) -> bool:
	if module_id.begins_with("power_block_") or module_id in ["radiator_v1", "air_duct_v1", "pocket_v1"]:
		return false
	return true

func preview_module_port_activity() -> Dictionary:
	var modules: Dictionary = {}
	var warnings: Array[String] = []
	var internal_total := 0
	var external_total := 0
	var power_total := 0
	var internal_interface_count := 0
	var external_interface_count := 0
	for i in range(installed_modules.size()):
		var module: BipobModule = installed_modules[i]
		if module == null:
			continue
		var id := String(module.id)
		if id.begins_with("internal_interface_"):
			internal_interface_count += 1
			internal_total += _get_internal_interface_port_capacity(id)
		elif id.begins_with("external_interface_"):
			external_interface_count += 1
			external_total += 6
		elif id.begins_with("power_block_"):
			power_total += 15

	var internal_available: int = internal_total
	var internal_needed_for_internal_links: int = maxi(0, 2 * internal_interface_count - 2)
	if internal_available < internal_needed_for_internal_links:
		internal_needed_for_internal_links = internal_available
	internal_available -= internal_needed_for_internal_links
	var external_reserved: int = external_interface_count
	var external_available: int = maxi(0, external_total - external_reserved)
	var power_available: int = power_total

	var ordered_modules: Array[Dictionary] = []
	for i in range(installed_modules.size()):
		var module: BipobModule = installed_modules[i]
		if module == null:
			continue
		ordered_modules.append({"id": String(module.id), "index": i})
	ordered_modules.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var module_id_a: String = String(a.get("id", ""))
		var module_id_b: String = String(b.get("id", ""))
		var pa: int = _get_module_port_priority(module_id_a)
		var pb: int = _get_module_port_priority(module_id_b)
		if pa != pb:
			return pa < pb
		return int(a.get("index", 9999)) < int(b.get("index", 9999))
	)

	for ordered_module in ordered_modules:
		var module_id: String = String(ordered_module.get("id", ""))
		var state: Dictionary = {"id": module_id, "installed": true, "active": true, "inactive_reason": "ok", "port_priority": _get_module_port_priority(module_id), "internal_ports_used": 0, "external_ports_used": 0, "power_ports_used": 0}
		if module_id.begins_with("internal_interface_"):
			if internal_total <= 0:
				state["active"] = false; state["inactive_reason"] = "internal_interface_missing"
			elif internal_needed_for_internal_links <= 0 and internal_interface_count > 1:
				state["active"] = false; state["inactive_reason"] = "internal_interface_link_missing"
			else:
				state["internal_ports_used"] = 1 if internal_interface_count > 1 else 0
				if power_total <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_missing"
				elif power_available <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_port_missing"
				else:
					power_available -= 1
					state["power_ports_used"] = 1
		elif module_id.begins_with("external_interface_"):
			if internal_total <= 0:
				state["active"] = false; state["inactive_reason"] = "internal_interface_missing"
			elif internal_available <= 0:
				state["active"] = false; state["inactive_reason"] = "internal_interface_port_missing"
			else:
				internal_available -= 1
				state["internal_ports_used"] = 1
				if power_total <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_missing"
				elif power_available <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_port_missing"
				else:
					power_available -= 1
					state["power_ports_used"] = 1
		elif module_id.begins_with("power_block_"):
			if internal_total <= 0:
				state["active"] = false; state["inactive_reason"] = "internal_interface_missing"
			elif internal_available <= 0:
				state["active"] = false; state["inactive_reason"] = "internal_interface_port_missing"
			else:
				internal_available -= 1
				state["internal_ports_used"] = 1
		else:
			if _module_requires_internal_interface_port(module_id):
				if internal_total <= 0:
					state["active"] = false; state["inactive_reason"] = "internal_interface_missing"
				elif internal_available <= 0:
					state["active"] = false; state["inactive_reason"] = "internal_interface_port_missing"
				else:
					internal_available -= 1
					state["internal_ports_used"] = 1
			if bool(state["active"]) and _module_requires_external_interface_port(module_id):
				if external_total <= 0:
					state["active"] = false; state["inactive_reason"] = "external_interface_missing"
				elif external_available <= 0:
					state["active"] = false; state["inactive_reason"] = "external_interface_port_missing"
				else:
					external_available -= 1
					state["external_ports_used"] = 1
			if bool(state["active"]) and _module_requires_power_block_port(module_id):
				if power_total <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_missing"
				elif power_available <= 0:
					state["active"] = false; state["inactive_reason"] = "power_block_port_missing"
				else:
					power_available -= 1
					state["power_ports_used"] = 1
		modules[module_id] = state

	return {"modules": modules, "internal_interface": {"ports_total": internal_total, "ports_used_for_interface_links": internal_needed_for_internal_links}, "external_interface": {"ports_total": external_total, "reserved_ports": external_reserved}, "power_block": {"ports_total": power_total}, "warnings": warnings}
func recalculate_module_port_activity() -> Dictionary:
	return preview_module_port_activity()

func get_module_port_debug_report() -> Dictionary:
	var port_state: Dictionary = preview_module_port_activity()
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var internal_state: Dictionary = Dictionary(port_state.get("internal_interface", {}))
	var external_state: Dictionary = Dictionary(port_state.get("external_interface", {}))
	var power_state: Dictionary = Dictionary(port_state.get("power_block", {}))

	var modules: Array[Dictionary] = []
	var active_modules: Array[String] = []
	var inactive_modules: Array[Dictionary] = []
	var internal_ports_used: int = 0
	var external_ports_used: int = 0
	var power_ports_used: int = 0
	var non_link_internal_module_ports_used: int = 0

	var sorted_module_ids: Array[String] = []
	for module_id_variant in modules_state.keys():
		sorted_module_ids.append(String(module_id_variant))
	sorted_module_ids.sort_custom(func(a: String, b: String) -> bool:
		var pa: int = _get_module_port_priority(a)
		var pb: int = _get_module_port_priority(b)
		if pa != pb:
			return pa < pb
		return a < b
	)

	for module_id in sorted_module_ids:
		var module_state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		var module_internal_ports_used: int = int(module_state.get("internal_ports_used", 0))
		var module_external_ports_used: int = int(module_state.get("external_ports_used", 0))
		var module_power_ports_used: int = int(module_state.get("power_ports_used", 0))
		var module_active: bool = bool(module_state.get("active", false))
		var module_inactive_reason: String = String(module_state.get("inactive_reason", "module_installed_but_inactive"))
		var module_entry: Dictionary = {
			"module_id": module_id,
			"active": module_active,
			"inactive_reason": module_inactive_reason,
			"port_priority": int(module_state.get("port_priority", _get_module_port_priority(module_id))),
			"internal_ports_used": module_internal_ports_used,
			"external_ports_used": module_external_ports_used,
			"power_ports_used": module_power_ports_used
		}
		modules.append(module_entry)
		if not module_id.begins_with("internal_interface_"):
			non_link_internal_module_ports_used += module_internal_ports_used
		external_ports_used += module_external_ports_used
		power_ports_used += module_power_ports_used

		if module_active:
			active_modules.append(module_id)
		else:
			var inactive_entry: Dictionary = {
				"module_id": module_id,
				"inactive_reason": module_inactive_reason,
				"inactive_reasons": get_module_inactive_reasons(module_id),
				"port_priority": int(module_entry.get("port_priority", 9999))
			}
			inactive_modules.append(inactive_entry)

	var internal_ports_total: int = int(internal_state.get("ports_total", 0))
	var external_ports_total: int = int(external_state.get("ports_total", 0))
	var power_ports_total: int = int(power_state.get("ports_total", 0))
	var internal_interface_link_ports_reserved: int = int(internal_state.get("ports_used_for_interface_links", 0))
	var external_interface_link_ports_reserved: int = int(external_state.get("reserved_ports", 0))
	internal_ports_used = internal_interface_link_ports_reserved + non_link_internal_module_ports_used
	external_ports_used += external_interface_link_ports_reserved
	var internal_ports_remaining: int = maxi(0, internal_ports_total - internal_ports_used)
	var external_ports_remaining: int = maxi(0, external_ports_total - external_ports_used)
	var power_ports_remaining: int = maxi(0, power_ports_total - power_ports_used)

	return {
		"internal_ports_total": internal_ports_total,
		"internal_ports_used": internal_ports_used,
		"internal_ports_remaining": internal_ports_remaining,
		"external_ports_total": external_ports_total,
		"external_ports_used": external_ports_used,
		"external_ports_remaining": external_ports_remaining,
		"power_ports_total": power_ports_total,
		"power_ports_used": power_ports_used,
		"power_ports_remaining": power_ports_remaining,
		"internal_interface_link_ports_reserved": internal_interface_link_ports_reserved,
		"external_interface_link_ports_reserved": external_interface_link_ports_reserved,
		"active_modules": active_modules,
		"inactive_modules": inactive_modules,
		"modules": modules
	}

func get_module_port_debug_report_text() -> String:
	var report: Dictionary = get_module_port_debug_report()
	var lines: Array[String] = []
	lines.append("ModulePortDebugReport")
	lines.append("Internal: used=%d / total=%d / remaining=%d (reserved_links=%d)" % [int(report.get("internal_ports_used", 0)), int(report.get("internal_ports_total", 0)), int(report.get("internal_ports_remaining", 0)), int(report.get("internal_interface_link_ports_reserved", 0))])
	lines.append("External: used=%d / total=%d / remaining=%d (reserved_links=%d)" % [int(report.get("external_ports_used", 0)), int(report.get("external_ports_total", 0)), int(report.get("external_ports_remaining", 0)), int(report.get("external_interface_link_ports_reserved", 0))])
	lines.append("Power: used=%d / total=%d / remaining=%d" % [int(report.get("power_ports_used", 0)), int(report.get("power_ports_total", 0)), int(report.get("power_ports_remaining", 0))])
	lines.append("")
	lines.append("Active modules:")
	for module_entry_variant in Array(report.get("modules", [])):
		var module_entry: Dictionary = Dictionary(module_entry_variant)
		if not bool(module_entry.get("active", false)):
			continue
		lines.append("- %s priority=%d ports internal=%d external=%d power=%d" % [String(module_entry.get("module_id", "")), int(module_entry.get("port_priority", 0)), int(module_entry.get("internal_ports_used", 0)), int(module_entry.get("external_ports_used", 0)), int(module_entry.get("power_ports_used", 0))])
	lines.append("")
	lines.append("Inactive modules:")
	for module_entry_variant in Array(report.get("inactive_modules", [])):
		var module_entry: Dictionary = Dictionary(module_entry_variant)
		lines.append("- %s reason=%s priority=%d" % [String(module_entry.get("module_id", "")), String(module_entry.get("inactive_reason", "module_installed_but_inactive")), int(module_entry.get("port_priority", 0))])
	return "\n".join(lines)

func get_module_inactive_reasons(module_id: String) -> Array[String]:
	var state := preview_module_port_activity()
	var modules: Dictionary = Dictionary(state.get("modules", {}))
	if not modules.has(module_id):
		return ["module_not_installed"]
	var module_state: Dictionary = Dictionary(modules.get(module_id, {}))
	if bool(module_state.get("active", false)):
		return ["ok"]
	return [String(module_state.get("inactive_reason", "module_installed_but_inactive"))]

func check_world_object_requirements(object_id: String, action: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("check_world_object_requirements"):
		return {"allowed": false, "object_id": object_id, "action": action, "requirements": {}, "capabilities": get_actor_capability_levels(), "reasons": ["object_missing"]}
	return _variant_to_dictionary(mission_manager.call("check_world_object_requirements", object_id, action))

func get_inventory_state() -> Dictionary:
	return {} if mission_manager == null or not mission_manager.has_method("get_inventory_state") else _variant_to_dictionary(mission_manager.call("get_inventory_state"))

func can_pickup_world_item(item_id: String) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("can_pickup_world_item") else _variant_to_dictionary(mission_manager.call("can_pickup_world_item", item_id))

func pickup_world_item(item_id: String) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("pickup_world_item") else _variant_to_dictionary(mission_manager.call("pickup_world_item", item_id))

func can_drop_inventory_item(item_id: String) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("can_drop_inventory_item") else _variant_to_dictionary(mission_manager.call("can_drop_inventory_item", item_id))

func drop_inventory_item(item_id: String, target_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("drop_inventory_item") else _variant_to_dictionary(mission_manager.call("drop_inventory_item", item_id, target_cell))

func hold_item_in_manipulator(item_id: String) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("hold_item_in_manipulator") else _variant_to_dictionary(mission_manager.call("hold_item_in_manipulator", item_id))

func place_item_in_digital_buffer(item_id: String) -> Dictionary:
	return {"success": false, "item_id": item_id, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("place_item_in_digital_buffer") else _variant_to_dictionary(mission_manager.call("place_item_in_digital_buffer", item_id))

func use_inventory_item_on_world_object(item_id: String, target_id: String, action: String = "") -> Dictionary:
	return {"success": false, "item_id": item_id, "target_id": target_id, "action": action, "reasons": ["item_missing"]} if mission_manager == null or not mission_manager.has_method("use_inventory_item_on_world_object") else _variant_to_dictionary(mission_manager.call("use_inventory_item_on_world_object", item_id, target_id, action))

func validate_full_runtime_persistence() -> Array[String]:
	if mission_manager == null or not mission_manager.has_method("validate_full_runtime_persistence"):
		return ["validate_full_runtime_persistence_missing"]
	return _variant_to_string_array(mission_manager.call("validate_full_runtime_persistence"))

func get_developer_validation_menu_text() -> String:
	return "Validation unavailable." if mission_manager == null or not mission_manager.has_method("get_developer_validation_menu_text") else String(mission_manager.call("get_developer_validation_menu_text"))

func run_developer_validation_suite(suite: String = "all") -> Dictionary:
	return {"suite": suite, "suites_run": 0, "warnings_count": 1, "warnings_by_suite": {suite: ["suite_missing"]}} if mission_manager == null or not mission_manager.has_method("run_developer_validation_suite") else _variant_to_dictionary(mission_manager.call("run_developer_validation_suite", suite))

func get_developer_validation_suite_text(suite: String = "all") -> String:
	return "Validation unavailable." if mission_manager == null or not mission_manager.has_method("get_developer_validation_suite_text") else String(mission_manager.call("get_developer_validation_suite_text", suite))

func start_dev_task_test_mission() -> void:
	start_mission(10, true)

func get_door_debug_report_text(door_id: String = "") -> String:
	if mission_manager == null or not mission_manager.has_method("get_door_debug_report_text"):
		return "Door debug report unavailable: mission manager/helper missing."
	return String(mission_manager.call("get_door_debug_report_text", door_id))

func get_platform_action_availability(platform_id: String, action: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_platform_action_availability"):
		return {"available": false, "platform_id": platform_id, "action": action, "reasons": ["platform_missing"], "state": "", "is_powered": false, "control_type": "", "power_type": ""}
	return _variant_to_dictionary(mission_manager.call("get_platform_action_availability", platform_id, action))

func execute_platform_action(platform_id: String, action: String = "", controller_id: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("execute_platform_action"):
		return {"success": false, "reason": "platform_missing"}
	return _variant_to_dictionary(mission_manager.call("execute_platform_action", platform_id, action, controller_id))

func get_lifting_platform_carry_targets(platform_id: String) -> Array[Dictionary]:
	if mission_manager == null or not mission_manager.has_method("get_lifting_platform_carry_targets"):
		return []
	return _variant_to_dictionary_array(mission_manager.call("get_lifting_platform_carry_targets", platform_id))

func apply_lifting_platform_height_change(platform_id: String, delta: int, controller_id: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_lifting_platform_height_change"):
		return {"success": false, "reason": "platform_missing"}
	return _variant_to_dictionary(mission_manager.call("apply_lifting_platform_height_change", platform_id, delta, controller_id))

func apply_rotating_platform_rotation(platform_id: String, clockwise: bool = true, controller_id: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_rotating_platform_rotation"):
		return {"success": false, "reason": "platform_missing"}
	return _variant_to_dictionary(mission_manager.call("apply_rotating_platform_rotation", platform_id, clockwise, controller_id))

func get_scan_result_for_cell(cell: Vector2i, scan_mode: String = "basic") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_scan_result_for_cell"):
		return {"ok": false, "reason": "unavailable"}
	return _variant_to_dictionary(mission_manager.call("get_scan_result_for_cell", cell, scan_mode), {"ok": false, "reason": "invalid_result"})

func get_scan_result_for_object(object_id: String, scan_mode: String = "basic") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("get_scan_result_for_object"):
		return {"ok": false, "reason": "unavailable"}
	return _variant_to_dictionary(mission_manager.call("get_scan_result_for_object", object_id, scan_mode), {"ok": false, "reason": "invalid_result"})

func get_scan_text_for_object(object_id: String, scan_mode: String = "basic") -> String:
	if mission_manager == null or not mission_manager.has_method("get_scan_text_for_object"):
		return "{}"
	return String(mission_manager.call("get_scan_text_for_object", object_id, scan_mode))

func get_xray_visible_objects(filter: String = "") -> Array[Dictionary]:
	if mission_manager == null or not mission_manager.has_method("get_xray_visible_objects"):
		return []
	return _variant_to_dictionary_array(mission_manager.call("get_xray_visible_objects", filter))

func reveal_xray_objects(filter: String = "") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("reveal_xray_objects"):
		return {"success": false, "reason": "unavailable"}
	return _variant_to_dictionary(mission_manager.call("reveal_xray_objects", filter))

func is_world_object_visible_to_player(object_data: Dictionary, scan_mode: String = "basic") -> bool:
	if mission_manager == null or not mission_manager.has_method("is_world_object_visible_to_player"):
		return true
	return bool(mission_manager.call("is_world_object_visible_to_player", object_data, scan_mode))

func get_visible_world_objects_for_scan(scan_mode: String = "basic") -> Array[Dictionary]:
	if mission_manager == null or not mission_manager.has_method("get_visible_world_objects_for_scan"):
		return []
	return _variant_to_dictionary_array(mission_manager.call("get_visible_world_objects_for_scan", scan_mode))
