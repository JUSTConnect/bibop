extends RefCounted
class_name ScanSystem

static func can_scan_through_wall(wall_data: Dictionary, scan_type: String) -> bool:
	var wall_type: String = wall_data.get("object_type", "")
	if wall_type == "outer_wall":
		return false
	if scan_type in ["visor", "radar"]:
		return wall_type in ["grate_wall", "energy_wall", "damaged_wall"]
	if scan_type in ["xray", "thermal"]:
		return wall_type != "outer_wall"
	return false

static func scan_object(object_data: Dictionary, scan_type: String, scanner_level: int = 1) -> Dictionary:
	var level := clampi(scanner_level, 0, 3)
	var out := {"scan_level": level, "name": "Unknown", "details": []}
	if level == 0:
		return out
	out["name"] = object_data.get("display_name", "Object") if level >= 2 else object_data.get("object_group", "Object").capitalize()
	if object_data.get("object_group", "") == "door":
		if scan_type == "visor":
			out["details"].append("Lock: %s" % object_data.get("lock_type", "unknown"))
		if level >= 3:
			out["details"].append("Power: %s" % object_data.get("power_mode", "unknown"))
			out["details"].append("Controlled by: %s" % ", ".join(object_data.get("controlled_by", [])))
	elif object_data.get("object_group", "") == "terminal":
		out["details"].append("Status: %s" % object_data.get("state", "unknown"))
		if level >= 2:
			out["details"].append("Connection: %s" % object_data.get("connection_type", "unknown"))
		if level >= 3 or scan_type == "interface":
			out["details"].append("Controls: %s" % ", ".join(object_data.get("controls", [])))
			out["details"].append("Class: %s" % str(object_data.get("terminal_class", 1)))
	elif object_data.get("object_group", "") == "wall":
		if scan_type == "xray" and level >= 2:
			out["details"].append("Embedded: %s" % ", ".join(object_data.get("hidden_content", [])))
	elif object_data.get("object_group", "") == "item":
		if level >= 2:
			out["details"].append("Storage: %s" % object_data.get("item_storage", "unknown"))
	elif object_data.get("object_group", "") == "physical_object":
		if level >= 2:
			out["details"].append("Weight: %s" % object_data.get("weight_class", "normal"))
	elif object_data.get("object_group", "") == "threat":
		if level >= 2:
			out["details"].append("Behavior: %s" % object_data.get("behavior_state", "idle"))
	return out

static func get_scan_display_text(object_data: Dictionary, scan_type: String) -> String:
	var result := scan_object(object_data, scan_type, object_data.get("scan_level", 1))
	var lines := [str(result.get("name", "Unknown"))]
	for detail in result.get("details", []):
		lines.append(str(detail))
	return "\n".join(lines)
