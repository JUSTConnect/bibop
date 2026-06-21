extends RefCounted
class_name BipobModuleCatalog

const BipobCapabilityServiceRef = preload("res://scripts/game/bipob_capability_service.gd")

const EXTERNAL_SIDE_TOP := "top"
const EXTERNAL_SIDE_BOTTOM := "bottom"
const EXTERNAL_SIDE_LEFT := "left"
const EXTERNAL_SIDE_RIGHT := "right"
const EXTERNAL_SIDE_FRONT := "front"
const EXTERNAL_SIDE_BACK := "back"

const EXTERNAL_SIDE_ORDER: Array[String] = [
	EXTERNAL_SIDE_TOP,
	EXTERNAL_SIDE_FRONT,
	EXTERNAL_SIDE_LEFT,
	EXTERNAL_SIDE_RIGHT,
	EXTERNAL_SIDE_BACK,
	EXTERNAL_SIDE_BOTTOM
]

const EXTERNAL_CATEGORY_MAP: Dictionary = {"movement":"Gear","sensor":"Sensors","manipulator":"Manipulator","connector":"Interface","tool":"Tools","repair":"Tools","weapon":"Weapons","armor":"Defense","other":"Other"}

const MODULE_ALIASES: Dictionary = {
	"manipulator_v1": "manipulator_arm_v1",
	"manipulator_tentacle_v1": "manipulator_arm_v1",
	"manipulator_magnetic_v1": "magnetic_manipulator_v1",
	"interface_v1": "external_interface_connector_v1",
	"connector_v1": "external_interface_connector_v1",
	"shock_device_v1": "shocker_v1",
	"hammer_v1": "sledgehammer_v1",
	"repair_module_v1": "repair_v1",
	"energy_shield_v1": "shield_module_v1"
}

const EXTERNAL_MODULES: Dictionary = {
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
"wired_connector_v1":{"name":"Wired Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Basic wired connector for direct device links.","energy":1,"connection":"wired","connection_range":"contact"},"high_bandwidth_connector_v1":{"name":"High-Bandwidth Connector","cat":"Interface","size":Vector2i(1,2),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"High-capacity external data channel for demanding modules such as radar, X-Ray systems, heavy sensors, turrets, and advanced tools.","energy":3,"connection":"high-bandwidth","connection_range":"contact","special":"heavy modules"},"external_interface_connector_v1":{"name":"External Interface Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Basic physical connector for linking external body modules to the robot’s internal control and power systems.","energy":1,"connection":"physical","connection_range":"contact"},"optical_connector_v1":{"name":"Optical Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Fast optical communication channel with reduced interference, designed for sensors, cameras, and precision data transfer.","energy":1,"connection":"optical","connection_range":"contact","special":"reduced interference"},"wireless_connector_v1":{"name":"Wireless Connector","cat":"Interface","size":Vector2i(1,1),"sides":[EXTERNAL_SIDE_LEFT,EXTERNAL_SIDE_RIGHT,EXTERNAL_SIDE_FRONT],"desc":"Wireless connection module that allows nearby devices and external systems to exchange data without direct physical contact, but remains vulnerable to jamming.","energy":2,"connection":"wireless","connection_range":"3","special":"vulnerable to jamming"},
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

const INTERNAL_MODULE_SPECS: Array[Dictionary] = [
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

static func resolve_module_id(module_id: String) -> String:
	var normalized_id := str(module_id).strip_edges()
	return str(MODULE_ALIASES.get(normalized_id, normalized_id))

static func get_external_definition(module_id: String) -> Dictionary:
	var normalized_id := resolve_module_id(module_id)
	var definition: Variant = EXTERNAL_MODULES.get(normalized_id, {})
	return Dictionary(definition).duplicate(true) if definition is Dictionary else {}

static func get_external_module_ids() -> Array[String]:
	var result: Array[String] = []
	for module_id_variant in EXTERNAL_MODULES.keys():
		result.append(str(module_id_variant))
	return result

static func is_external_module_id(module_id: String) -> bool:
	return EXTERNAL_MODULES.has(resolve_module_id(module_id))

static func get_external_side_order() -> Array[String]:
	return EXTERNAL_SIDE_ORDER.duplicate()

static func get_external_category_map() -> Dictionary:
	return EXTERNAL_CATEGORY_MAP.duplicate(true)

static func get_internal_module_specs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec_variant in INTERNAL_MODULE_SPECS:
		result.append(Dictionary(spec_variant).duplicate(true))
	return result

static func get_internal_spec(module_id: String) -> Dictionary:
	for spec_variant in INTERNAL_MODULE_SPECS:
		var spec: Dictionary = spec_variant
		if str(spec.get("id", "")) == module_id:
			return spec.duplicate(true)
	return {}

static func is_internal_module_id(module_id: String) -> bool:
	return not get_internal_spec(module_id).is_empty()

static func get_internal_definition(module_id: String) -> Dictionary:
	var spec := get_internal_spec(module_id)
	if spec.is_empty():
		return {}
	return {
		"id": module_id,
		"name": str(spec.get("name", module_id)),
		"size": Vector3i(spec.get("size", Vector3i.ONE)),
		"family": get_internal_family_for_module_id(module_id),
		"category": get_internal_category_for_module_id(module_id),
		"role": get_internal_role_for_module_id(module_id),
		"version": get_module_version_for_module_id(module_id),
		"battery_capacity": get_internal_battery_capacity(module_id),
		"storage_capacity": get_internal_storage_capacity(module_id),
		"actions_capacity": get_internal_actions_capacity(module_id),
		"hack_level": get_internal_hack_level(module_id),
		"gpu_value": get_internal_gpu_value(module_id),
		"sensor_range_bonus": get_internal_sensor_range_bonus(module_id),
		"sensor_visibility_bonus": get_internal_sensor_visibility_bonus(module_id),
		"cooling_value": get_internal_cooling_value(module_id),
		"power_distribution": get_internal_power_distribution(module_id),
		"power_ports": get_internal_power_ports(module_id),
		"interface_role": get_internal_interface_role(module_id),
		"ports": get_internal_interface_ports(module_id),
		"description": get_internal_description_for_module_id(module_id),
		"heat": get_internal_overheat_for_module_id(module_id),
		"energy_effect": get_internal_energy_effect_text(module_id),
		"special_effect": get_internal_special_effect_text(module_id)
	}

static func validate_catalog() -> Dictionary:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for module_id_variant in EXTERNAL_MODULES.keys():
		var module_id := str(module_id_variant)
		if seen.has(module_id):
			errors.append("Duplicate module id: %s" % module_id)
		seen[module_id] = true
		var definition: Dictionary = EXTERNAL_MODULES[module_id]
		if str(definition.get("name", "")).is_empty():
			errors.append("External module missing name: %s" % module_id)
		var size: Vector2i = definition.get("size", Vector2i.ZERO)
		if size.x <= 0 or size.y <= 0:
			errors.append("External module has invalid size: %s" % module_id)
		var sides: Array = definition.get("sides", [])
		if sides.is_empty():
			errors.append("External module has no allowed sides: %s" % module_id)
		for side_variant in sides:
			if str(side_variant) not in EXTERNAL_SIDE_ORDER:
				errors.append("External module has invalid side %s: %s" % [str(side_variant), module_id])
	for spec_variant in INTERNAL_MODULE_SPECS:
		var spec: Dictionary = spec_variant
		var module_id := str(spec.get("id", ""))
		if module_id.is_empty():
			errors.append("Internal module missing id")
			continue
		if seen.has(module_id):
			errors.append("Duplicate module id: %s" % module_id)
		seen[module_id] = true
		if str(spec.get("name", "")).is_empty():
			errors.append("Internal module missing name: %s" % module_id)
		var size: Vector3i = spec.get("size", Vector3i.ZERO)
		if size.x < 0 or size.y < 0 or size.z < 0:
			errors.append("Internal module has invalid size: %s" % module_id)
	for alias_variant in MODULE_ALIASES.keys():
		var alias_id := str(alias_variant)
		var target_id := str(MODULE_ALIASES[alias_id])
		if not EXTERNAL_MODULES.has(target_id) and not is_internal_module_id(target_id):
			errors.append("Alias %s targets missing module %s" % [alias_id, target_id])
	return {"valid": errors.is_empty(), "errors": errors, "external_count": EXTERNAL_MODULES.size(), "internal_count": INTERNAL_MODULE_SPECS.size(), "alias_count": MODULE_ALIASES.size()}

static func get_internal_category_for_module_id(module_id: String) -> String:
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

static func get_internal_family_for_module_id(module_id: String) -> String:
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

static func get_module_version_for_module_id(module_id: String) -> int:
	return BipobCapabilityServiceRef.get_module_version_for_module_id(module_id)

static func get_internal_battery_capacity(module_id: String) -> int:
	if not module_id.begins_with("battery_"):
		return 0
	match get_module_version_for_module_id(module_id):
		1: return 30
		2: return 40
		3: return 50
		_: return 0

static func get_internal_storage_capacity(module_id: String) -> int:
	if not module_id.begins_with("hard_drive_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3)

static func get_internal_actions_capacity(module_id: String) -> int:
	if not module_id.begins_with("memory_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3) * 5

static func get_internal_hack_level(module_id: String) -> int:
	if not module_id.begins_with("processor_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3)

static func get_internal_gpu_value(module_id: String) -> int:
	if not module_id.begins_with("gpu_"):
		return 0
	return clampi(get_module_version_for_module_id(module_id), 1, 3) + 2

static func get_internal_sensor_range_bonus(module_id: String) -> int:
	match module_id:
		"gpu_v1":
			return 3
		"gpu_v2":
			return 5
		"gpu_v3":
			return 7
		_:
			return 0

static func get_internal_sensor_visibility_bonus(module_id: String) -> int:
	match module_id:
		"gpu_v1":
			return 15
		"gpu_v2":
			return 30
		"gpu_v3":
			return 45
		_:
			return 0

static func get_internal_cooling_value(module_id: String) -> int:
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

static func get_internal_power_distribution(module_id: String) -> int:
	return 1 if module_id.begins_with("power_block_") else 0

static func get_internal_power_ports(module_id: String) -> int:
	match module_id:
		"power_block_v1":
			return 15
		"power_block_v2":
			return 17
		"power_block_v3":
			return 20
		_:
			return 0

static func get_internal_interface_role(module_id: String) -> String:
	if module_id.begins_with("internal_interface_"):
		return "internal"
	if module_id.begins_with("external_interface_"):
		return "external"
	return ""

static func get_internal_interface_ports(module_id: String) -> int:
	match module_id:
		"internal_interface_v1", "external_interface_v1":
			return 6
		"internal_interface_v2", "external_interface_v2":
			return 7
		"internal_interface_v3", "external_interface_v3":
			return 8
		_:
			return 0

static func get_internal_description_for_module_id(module_id: String) -> String:
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

static func get_internal_overheat_for_module_id(module_id: String) -> int:
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

static func get_internal_energy_effect_text(module_id: String) -> String:
	match module_id:
		"charging_via_external_heat_v1":
			return "+2 / one degree up"
		"charging_via_internal_heat_v1":
			return "+1 / one degree"
		"energy_drain_v1":
			return "+10 / action"
		_:
			return ""

static func get_internal_special_effect_text(module_id: String) -> String:
	match module_id:
		"gpu_v1":
			return "All sensors +3 Range +15 Visibility"
		"gpu_v2":
			return "All sensors +5 Range +30 Visibility"
		"gpu_v3":
			return "All sensors +7 Range +45 Visibility"
		_:
			return ""

static func get_internal_role_for_module_id(module_id: String) -> String:
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

static func get_module_description_for_id(module_id: String) -> String:
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
