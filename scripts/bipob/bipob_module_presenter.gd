extends RefCounted
class_name BipobModulePresenter

static func get_module_visual_key(module: BipobModule) -> String:
	if module == null:
		return "unknown"

	var module_id: String = module.id

	if module_id.contains("battery"):
		return "battery"
	if module_id.contains("processor"):
		return "processor"
	if module_id.contains("memory"):
		return "memory"
	if module_id.contains("hard_drive") or module_id.contains("hdd") or module_id.contains("ssd"):
		return "storage"
	if module_id.contains("power_block"):
		return "power"
	if module_id.contains("cooler"):
		return "cooler"
	if module_id.contains("radiator"):
		return "radiator"
	if module_id.contains("water_tube"):
		return "water_tube"
	if module_id.contains("air_duct"):
		return "air_duct"
	if module_id.contains("air_intake"):
		return "air_intake"
	match module_id:
		"manipulator_arm_v1", "manipulator_v1":
			return "manipulator_arm"
		"manipulator_tentacle_v1":
			return "manipulator_tentacle"
		"manipulator_magnetic_v1":
			return "manipulator_magnetic"
		"connector_v1", "interface_v1":
			return "connector"
		"legs_v1":
			return "legs"
		"wheels_v1":
			return "wheels"
		"tracks_v1":
			return "tracks"
		"radar_v1":
			return "radar"
		"visor_v1":
			return "visor"
		"visor_v2":
			return "visor_v2"
		"thermal_visor_v1":
			return "thermal_visor"
		"xray_v1":
			return "xray"
		"pocket_v1":
			return "pocket"
		"air_duct_external_v1":
			return "air_duct_external"
		"motion_detector_v1":
			return "motion_detector"
		"torch_v1":
			return "torch"
		"gas_tank_v1":
			return "gas_tank"
		"plasma_cutter_v1":
			return "plasma_cutter"
		"laser_v1":
			return "laser"
		"shock_device_v1":
			return "shock_device"
		"saw_v1":
			return "saw"
		"sledgehammer_v1":
			return "sledgehammer"
		"repair_module_v1":
			return "repair_module"
		"welder_v1":
			return "welder"

	if module_id.contains("visor"):
		return "visor"
	if module_id.contains("wheel"):
		return "wheels"
	if module_id.contains("leg"):
		return "legs"
	if module_id.contains("track"):
		return "tracks"
	if module_id.contains("manipulator"):
		return "manipulator_arm"
	if module_id.contains("interface"):
		return "connector"
	if module_id.contains("gpu"):
		return "gpu"

	return "module"

static func get_module_visual_short_label(module: BipobModule) -> String:
	if module == null:
		return "?"
	if module.id == "intiradar_v1":
		return "ARD"
	if module.id == "gas_burner_v1":
		return "BRN"
	if module.id == "gas_canister_v1":
		return "GAS"
	if module.id == "ventilation_port_v1":
		return "VNT"
	if module.id == "charging_via_external_heat_v1":
		return "CEH"
	if module.id == "charging_via_internal_heat_v1":
		return "CIH"
	if module.id == "energy_drain_v1":
		return "END"

	var key: String = get_module_visual_key(module)
	match key:
		"battery": return "BAT"
		"processor": return "CPU"
		"memory": return "MEM"
		"storage": return "DRV"
		"power": return "PWR"
		"cooler": return "FAN"
		"radiator": return "RAD"
		"water_tube": return "TUBE"
		"air_duct": return "DUCT"
		"air_intake": return "AIR"
		"air_duct_external": return "DUCT"
		"manipulator_arm": return "ARM"
		"manipulator_tentacle": return "TENT"
		"manipulator_magnetic": return "MAG"
		"connector": return "CON"
		"radar": return "RAD"
		"visor": return "VIS"
		"visor_v2": return "VIS2"
		"thermal_visor": return "THM"
		"xray": return "XRY"
		"pocket": return "PCK"
		"motion_detector": return "MOV"
		"torch": return "TOR"
		"gas_tank": return "GAS"
		"plasma_cutter": return "PLC"
		"laser": return "LSR"
		"shock_device": return "SHK"
		"saw": return "SAW"
		"sledgehammer": return "HAM"
		"repair_module": return "REP"
		"welder": return "WLD"
		"wheels": return "WHL"
		"legs": return "LEG"
		"tracks": return "TRK"
		"manipulator": return "ARM"
		"interface": return "I/O"
		"gpu": return "GPU"
		_: return "MOD"
