extends RefCounted
class_name ScanSystem
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")

static func can_scan_through_wall(wall_data: Dictionary, scan_type: String) -> bool:
	var wall_type: String = wall_data.get("object_type", "")
	if wall_type == "outer_wall":
		return false
	if scan_type in ["visor", "radar"]:
		return wall_type in ["grate_wall", "energy_wall"]
	if scan_type in ["xray", "thermal"]:
		return wall_type != "outer_wall"
	return false

static func scan_object(object_data: Dictionary, scan_type: String, scanner_level: int = 1) -> Dictionary:
	var level := clampi(scanner_level, 0, 3)
	var out := {"scan_level": level, "name": "Unknown", "details": []}
	if level == 0:
		return out
	if object_data.get("object_group", "") == "threat" and level <= 1:
		out["name"] = "Unknown movement"
	else:
		out["name"] = object_data.get("display_name", "Object") if level >= 2 else object_data.get("object_group", "Object").capitalize()
	if object_data.get("object_group", "") == "door":
		if scan_type == "visor":
			out["details"].append("Lock: %s" % object_data.get("lock_type", "unknown"))
		if level >= 3:
			out["details"].append("Power: %s" % object_data.get("power_mode", "unknown"))
			out["details"].append("Controlled by: %s" % ", ".join(object_data.get("controlled_by", [])))
	elif object_data.get("object_group", "") == "terminal":
		out["details"].append("Status: %s" % object_data.get("state", "unknown"))
		if String(object_data.get("terminal_type", "")) == "platform":
			out["details"].append("Platform Terminal")
			out["details"].append("Target: %s" % String(object_data.get("target_platform_id", "")))
			out["details"].append("Control enabled: %s" % str(bool(object_data.get("platform_control_enabled", false))))
		if level >= 2:
			out["details"].append("Connection: %s" % object_data.get("connection_type", "unknown"))
			if object_data.has("overheat_threshold"):
				out["details"].append("Heat: %d / %d" % [WorldObjectCatalog.get_world_object_current_heat(object_data), int(object_data.get("overheat_threshold", 0))])
				out["details"].append("Cooling: %d" % maxi(0, int(object_data.get("cooling_received", 0))))
		if level >= 3 or scan_type == "interface":
			out["details"].append("Controls: %s" % ", ".join(object_data.get("controls", [])))
			out["details"].append("Class: %s" % str(object_data.get("terminal_class", 1)))
	elif object_data.get("object_group", "") == "power":
		out["details"].append("Status: %s" % object_data.get("state", "unknown"))
		if level >= 2 and object_data.has("overheat_threshold"):
			out["details"].append("Heat: %d / %d" % [WorldObjectCatalog.get_world_object_current_heat(object_data), int(object_data.get("overheat_threshold", 0))])
			out["details"].append("Cooling: %d" % maxi(0, int(object_data.get("cooling_received", 0))))
		if level >= 3:
			var connected_count := Array(object_data.get("connected_device_ids", [])).size()
			out["details"].append("Connections: %d / %d" % [connected_count, maxi(0, int(object_data.get("allowed_socket_connections", 0)))])
	elif object_data.get("object_group", "") == "wall":
		if scan_type == "xray" and level >= 2:
			out["details"].append("Embedded: %s" % ", ".join(object_data.get("hidden_content", [])))
	elif object_data.get("object_group", "") == "item":
		if level >= 2:
			var storage: String = String(object_data.get("storage_type", object_data.get("item_storage", "unknown")))
			out["details"].append("Storage: %s" % storage)
	elif object_data.get("object_group", "") == "physical_object":
		if level >= 2:
			out["details"].append("Weight: %s" % object_data.get("weight_class", "normal"))
	elif object_data.get("object_group", "") == "cooling":
		out["details"].append("Status: %s" % object_data.get("state", "unknown"))
		if WorldObjectCatalog.can_world_object_be_moved_by_heavy_claw(object_data):
			out["details"].append("Movable: Heavy Claw")
		var cooling_output := maxi(0, int(object_data.get("cooling_output", 0)))
		if String(object_data.get("cooling_device_type", "")) == "radiator":
			out["details"].append("Cooling output: %d" % cooling_output)
			out["details"].append("Metal boost: adjacent metal object increases radiator cooling to 2")
		elif String(object_data.get("cooling_device_type", "")) == "air_cooler":
			out["details"].append("Cooling output: %d" % cooling_output)
			out["details"].append("Facing: %s" % String(object_data.get("facing_dir", "right")))
		elif String(object_data.get("cooling_device_type", "")) == "water_pipe":
			out["details"].append("Cooling output: %d" % cooling_output)
			out["details"].append("Water cooling: adjacent heat device receives cooling")
		elif String(object_data.get("cooling_device_type", "")) == "air_duct":
			out["details"].append("Carries airflow")
			out["details"].append("Requires External Air Cooler facing duct line")
		elif bool(object_data.get("cooling_amplifier", false)):
			out["details"].append("Cooling amplifier")


	elif object_data.get("object_group", "") == "platform":
		out["details"].append("Platform type: %s" % String(object_data.get("platform_type", "unknown")))
		out["details"].append("Status: %s" % String(object_data.get("state", "unknown")))
		out["details"].append("Power/control: %s / %s" % [String(object_data.get("power_type", "internal")), String(object_data.get("control_type", "internal"))])
		out["details"].append("Activation: %s" % String(object_data.get("activation_mode", "instant")))
		if object_data.has("height_level"):
			out["details"].append("Height: %d" % int(object_data.get("height_level", 0)))
		if object_data.has("linked_terminal_id") and String(object_data.get("linked_terminal_id", "")) != "":
			out["details"].append("Linked terminal: %s" % String(object_data.get("linked_terminal_id", "")))
		if object_data.has("timer_remaining_turns"):
			out["details"].append("Timer: %d" % int(object_data.get("timer_remaining_turns", 0)))
	elif object_data.get("object_group", "") == "threat":
		if level >= 2:
			out["details"].append("Behavior: %s" % object_data.get("behavior_state", "idle"))
		if scan_type == "thermal" and bool(object_data.get("heat_signature", false)):
			out["details"].append("Heat signature detected")
			if String(object_data.get("object_type", "")) == "turret" and String(object_data.get("state", "")) == "active":
				out["details"].append("Active turret")
		if scan_type == "radar" and String(object_data.get("behavior_state", "")) in ["patrolling", "active"]:
			out["details"].append("Patrol movement detected")
			out["details"].append("Threat outline")
		if scan_type == "xray" and level >= 2:
			out["details"].append("Power source: %s" % object_data.get("power_mode", "unknown"))
			out["details"].append("Armor: %s" % ", ".join(Array(object_data.get("material_tags", []))))
			out["details"].append("Weakness: energy overload")
	if bool(object_data.get("cooling_amplifier", false)) and not out["details"].has("Cooling amplifier"):
		out["details"].append("Cooling amplifier")
	return out

static func get_scan_display_text(object_data: Dictionary, scan_type: String) -> String:
	var result := scan_object(object_data, scan_type, object_data.get("scan_level", 1))
	var lines := [str(result.get("name", "Unknown"))]
	for detail in result.get("details", []):
		lines.append(str(detail))
	return "\n".join(lines)
