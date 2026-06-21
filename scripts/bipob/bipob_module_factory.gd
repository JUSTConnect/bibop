extends RefCounted
class_name BipobModuleFactory

const BipobModuleRef = preload("res://scripts/bipob/bipob_module.gd")
const BipobModuleCatalogRef = preload("res://scripts/bipob/bipob_module_catalog.gd")

static func create_external_module(module_id: String) -> BipobModule:
	var normalized_id := BipobModuleCatalogRef.resolve_module_id(module_id)
	var metadata := BipobModuleCatalogRef.get_external_definition(normalized_id)
	if metadata.is_empty():
		return null
	var module: BipobModule = BipobModuleRef.new()
	module.id = normalized_id
	module.module_id = normalized_id
	module.placement_type = "external"
	module.internal_role = "none"
	module.module_version = BipobModuleCatalogRef.get_module_version_for_module_id(normalized_id)
	module.version = "V%d" % module.module_version
	module.display_name = str(metadata.get("name", module_id))
	module.category = str(metadata.get("cat", "Other"))
	module.description = str(metadata.get("desc", ""))
	var external_size: Vector2i = metadata.get("size", Vector2i.ONE)
	module.external_width = external_size.x
	module.external_height = external_size.y
	module.allowed_external_sides.clear()
	for side_variant in Array(metadata.get("sides", [])):
		module.allowed_external_sides.append(str(side_variant))
	module.energy_cost = int(metadata.get("energy", 0))
	module.heat_value = int(metadata.get("heat", 0))
	module.scan_range = int(metadata.get("scan", 0))
	module.visibility_value = int(metadata.get("visibility", 0))
	module.scan_accuracy = int(metadata.get("accuracy", 0))
	module.sensor_direction = str(metadata.get("direction", ""))
	module.armor_bonus = int(metadata.get("armor", 0))
	module.shield_value = int(metadata.get("shield", 0))
	module.defense_type = str(metadata.get("defense_type", ""))
	module.damage_value = str(metadata.get("damage", ""))
	module.weapon_range_type = str(metadata.get("range", ""))
	module.special_effect_text = str(metadata.get("special", ""))
	module.action_modifier = int(metadata.get("actions", 0))
	module.movement_type = str(metadata.get("movement", ""))
	module.terrain_type = str(metadata.get("terrain", ""))
	module.gear_speed = int(metadata.get("speed", 0))
	module.ignore_terrain_debuff = bool(metadata.get("ignore_debuff", false))
	module.reach_value = int(metadata.get("reach", 0))
	module.range_value = int(metadata.get("range_value", module.reach_value))
	module.direction_text = str(metadata.get("direction", ""))
	module.span_text = str(metadata.get("span", module.weapon_range_type))
	module.fuel_capacity = int(metadata.get("fuel_capacity", 0))
	module.ammo_dependency_id = str(metadata.get("ammo_dependency_id", ""))
	module.tool_action = str(metadata.get("tool_action", ""))
	module.carry_text = str(metadata.get("carry", ""))
	module.connection_type = str(metadata.get("connection", ""))
	module.connection_range_text = str(metadata.get("connection_range", ""))
	module.action_text = str(metadata.get("action", ""))
	if module.id in ["manipulator_arm_v1", "manipulator_heavy_claw_v1", "magnetic_manipulator_v1", "tentacle_manipulator_v1", "telescopic_arm_v1"]:
		module.granted_commands = ["interact_key", "open_physical_door"]
	if module.id in ["external_interface_connector_v1", "wired_connector_v1", "high_bandwidth_connector_v1", "optical_connector_v1", "wireless_connector_v1"]:
		module.granted_commands = ["read_terminal", "open_digital_door"]
	if module.id == "wheels_v1":
		module.granted_commands = ["move_forward", "move_backward", "turn_left", "turn_right"]
	if module.id in ["visor_v1", "visor_v2", "visor_v3"]:
		module.granted_commands = ["vision"]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

static func create_internal_module(module_id: String, module_name: String = "", module_size: Vector3i = Vector3i(-1, -1, -1)) -> BipobModule:
	var definition := BipobModuleCatalogRef.get_internal_definition(module_id)
	if definition.is_empty():
		return null
	var resolved_name := module_name if not module_name.is_empty() else str(definition.get("name", module_id))
	var resolved_size := module_size
	if resolved_size.x < 0 or resolved_size.y < 0 or resolved_size.z < 0:
		resolved_size = Vector3i(definition.get("size", Vector3i.ONE))
	var module: BipobModule = BipobModuleRef.new()
	module.id = module_id
	module.module_id = module_id
	module.display_name = resolved_name
	module.placement_type = "internal_overlay" if resolved_size == Vector3i.ZERO else "internal"
	module.size_x = resolved_size.x
	module.size_y = resolved_size.y
	module.size_z = resolved_size.z
	module.internal_size = resolved_size
	module.internal_rotatable = true
	module.internal_role = str(definition.get("role", "none"))
	module.internal_family = str(definition.get("family", "none"))
	module.module_version = int(definition.get("version", 1))
	module.version = "V%d" % module.module_version
	module.battery_capacity = int(definition.get("battery_capacity", 0))
	module.storage_capacity = int(definition.get("storage_capacity", 0))
	module.actions_capacity = int(definition.get("actions_capacity", 0))
	module.hack_level = int(definition.get("hack_level", 0))
	module.energy_capacity = module.battery_capacity
	module.action_capacity = module.actions_capacity
	module.digital_storage_slots = module.storage_capacity
	module.hack_value = module.hack_level
	module.gpu_value = int(definition.get("gpu_value", 0))
	module.sensor_range_bonus = int(definition.get("sensor_range_bonus", 0))
	module.sensor_visibility_bonus = int(definition.get("sensor_visibility_bonus", 0))
	module.cooling_value = int(definition.get("cooling_value", 0))
	module.power_distribution = int(definition.get("power_distribution", 0))
	module.interface_role = str(definition.get("interface_role", ""))
	module.ports = int(definition.get("ports", 0))
	module.power_ports = int(definition.get("power_ports", 0))
	module.category = str(definition.get("category", "Other"))
	module.description = str(definition.get("description", ""))
	module.heat_value = int(definition.get("heat", 0))
	module.energy_effect_text = str(definition.get("energy_effect", ""))
	module.special_effect_text = str(definition.get("special_effect", ""))
	module.characteristics_text = get_internal_characteristics_text(module)
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

static func create_overlay_module(module_id: String) -> BipobModule:
	if module_id not in ["water_tube_v1", "air_duct_v1"]:
		return null
	var definition := BipobModuleCatalogRef.get_internal_definition(module_id)
	return create_internal_module(module_id, str(definition.get("name", module_id)), Vector3i(1, 1, 1))

static func create_debug_found_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "battery_v1"
	module.display_name = "Battery V1"
	module.description = "Increases max energy by 10."
	module.energy_bonus = 10
	module.granted_commands = []
	return module

static func create_debug_field_component() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "cooling_v1"
	module.module_id = "cooling_v1"
	module.display_name = "Cooling V1"
	module.description = "Basic cooling component for future internal builds."
	module.energy_bonus = 0
	module.actions_bonus = 0
	module.vision_bonus = 0
	module.granted_commands = []
	return module

static func create_legacy_gpu_v1_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "gpu_v1"
	module.display_name = "GPU V1"
	module.description = "Internal processing module. Increases vision range and supports hidden node detection."
	module.granted_commands = ["hidden_detection_support"]
	module.vision_bonus = 0
	return module

static func create_legacy_legs_v1_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "legs_v1"
	module.display_name = "Legs V1"
	module.placement_type = "external"
	module.category = "locomotion"
	module.internal_role = "none"
	module.description = "Bottom locomotion module for stepped terrain."
	module.granted_commands = ["move_forward", "move_backward", "turn_left", "turn_right", "cross_stepped_floor"]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

static func get_internal_characteristics_text(module: BipobModule) -> String:
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


static func apply_thermal_metadata(module: BipobModule) -> void:
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


static func apply_damage_metadata(module: BipobModule) -> void:
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

