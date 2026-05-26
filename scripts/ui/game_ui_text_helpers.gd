extends RefCounted
class_name GameUITextHelpers

static func get_module_characteristics_lines(module: BipobModule, _context: String = "") -> Array:
	var lines: Array = []
	if module == null:
		return lines

	var is_internal_module: bool = module.placement_type == "internal" or module.placement_type == "internal_overlay"
	if is_internal_module:
		return get_internal_characteristics_lines(module)
	if module.placement_type == "external" and String(module.category).to_lower() == "gear":
		lines.append("Energy: %d" % module.energy_cost)
		if not module.terrain_type.is_empty():
			lines.append("Terrain: %s" % module.terrain_type)
		if not module.movement_type.is_empty():
			lines.append("Movement: %s" % module.movement_type)
		if module.gear_speed > 0:
			lines.append("Speed: %d" % module.gear_speed)
		if module.ignore_terrain_debuff:
			lines.append("Special: ignore debuff")
		return lines

	if module.placement_type == "external" and String(module.category) == "Manipulator":
		lines.append("Energy: %d" % module.energy_cost)
		if module.reach_value > 0:
			lines.append("Reach: %d" % module.reach_value)
		if not module.direction_text.is_empty():
			lines.append("Direction: %s" % module.direction_text)
		if not module.carry_text.is_empty():
			lines.append("Carry: %s" % module.carry_text)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.placement_type == "external" and String(module.category) == "Sensors":
		lines.append("Energy: %d" % module.energy_cost)
		if not module.sensor_direction.is_empty():
			lines.append("Direction: %s" % module.sensor_direction)
		lines.append("Range: %d" % module.scan_range)
		lines.append("Visibility: %d" % module.visibility_value)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.placement_type == "external" and String(module.category) == "Interface":
		if module.energy_cost > 0:
			lines.append("Energy: %d" % module.energy_cost)
		if not module.connection_type.is_empty():
			lines.append("Connection: %s" % module.connection_type)
		if not module.connection_range_text.is_empty():
			lines.append("Range: %s" % module.connection_range_text)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.placement_type == "external" and String(module.category) == "Defense":
		lines.append("Energy: %d" % module.energy_cost)
		if not module.defense_type.is_empty():
			lines.append("Type Defense: %s" % module.defense_type)
		if not module.damage_value.is_empty() and module.damage_value != "0":
			lines.append("Damage: +%s" % module.damage_value)
		if module.armor_bonus != 0:
			lines.append("Armor: +%d" % module.armor_bonus)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.placement_type == "external" and String(module.category) == "Other":
		lines.append("Energy: %d" % module.energy_cost)
		if not module.action_text.is_empty():
			lines.append("Action: %s" % module.action_text)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.placement_type == "external" and String(module.category) == "Weapons":
		lines.append("Energy: %d" % module.energy_cost)
		if module.fuel_capacity > 0:
			lines.append("Fuel: %d" % module.fuel_capacity)
		if module.range_value > 0:
			lines.append("Range: %d" % module.range_value)
		if not module.damage_value.is_empty() and module.damage_value != "0":
			lines.append("Damage: %s" % module.damage_value)
		if not module.direction_text.is_empty():
			lines.append("Direction: %s" % module.direction_text)
		if not module.span_text.is_empty():
			lines.append("Span: %s" % module.span_text)
		if not module.special_effect_text.is_empty():
			lines.append("Special: %s" % module.special_effect_text)
		return lines

	if module.energy_cost != 0:
		lines.append("Energy: %d" % module.energy_cost)
	if module.heat_value != 0:
		lines.append("Heat: %d" % module.heat_value)
	if module.scan_range != 0:
		lines.append("Scan Range: %d" % module.scan_range)
	if module.scan_accuracy != 0:
		lines.append("Scan Accuracy: %d" % module.scan_accuracy)
	if not module.damage_value.is_empty() and module.damage_value != "0":
		lines.append("Damage: %s" % module.damage_value)
	if not module.weapon_range_type.is_empty():
		lines.append("Weapon Type: %s" % module.weapon_range_type)
	if module.armor_bonus != 0:
		lines.append("Armor: +%d" % module.armor_bonus)
	if module.shield_value != 0:
		lines.append("Shield: %d" % module.shield_value)
	if module.action_modifier != 0:
		lines.append("Actions: %+d" % module.action_modifier)
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
	if module.sensor_range_bonus > 0 or module.sensor_visibility_bonus > 0:
		lines.append("Special: All sensors +%d Range +%d Visibility" % [module.sensor_range_bonus, module.sensor_visibility_bonus])
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
	if not module.special_effect_text.is_empty() and not (module.sensor_range_bonus > 0 or module.sensor_visibility_bonus > 0):
		lines.append("Special: %s" % module.special_effect_text)

	return lines

static func get_internal_characteristics_lines(module: BipobModule) -> Array:
	var lines: Array = []
	if module.cooling_value != 0:
		lines.append("Cooling: %d" % abs(module.cooling_value))
	elif module.heat_value > 0:
		lines.append("Overheat: +%d" % module.heat_value)
	if module.power_ports > 0:
		lines.append("Power Ports: %d" % module.power_ports)
	if String(module.internal_family).to_lower() == "battery" and module.energy_capacity > 0:
		lines.append("Energy: %d / %d" % [clampi(int(module.current_charge), 0, int(module.energy_capacity)), int(module.energy_capacity)])
	elif module.energy_capacity > 0:
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
	if module.cooling_power != 0:
		lines.append("Cooling Power: %d" % module.cooling_power)
	if not String(module.cooling_type).is_empty() and String(module.cooling_type).to_lower() != "none":
		lines.append("Cooling Type: %s" % module.cooling_type)
	if module.requires_air_intake:
		lines.append("Requires: Air Intake")
	if module.is_non_volume_cooling_path:
		lines.append("Cooling Path: non-volume")
	if module.power_distribution > 0:
		lines.append("Power Distribution: +%d" % module.power_distribution)
	if module.power_ports > 0:
		lines.append("Power Ports: %d" % module.power_ports)
	if module.ports > 0:
		lines.append("Ports: %d" % module.ports)
	if not module.interface_role.is_empty():
		lines.append("Interface: %s" % module.interface_role)
	if bool(module.is_builtin):
		lines.append("Special: Built-in, non-removable")
	if not module.special_effect_text.is_empty():
		lines.append("Special: %s" % module.special_effect_text)
	if lines.is_empty():
		lines.append("Characteristics will be added later.")
	return lines
