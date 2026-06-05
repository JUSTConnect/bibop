extends RefCounted
class_name MapConstructorTerminalLinkFilterService

static func normalize_terminal_type(data: Dictionary) -> String:
	var terminal_type: String = str(data.get("terminal_type", data.get("terminal_mode", ""))).strip_edges().to_lower()
	if terminal_type in ["control", "controller", "control_terminal"]:
		return "control"
	return "information"

static func is_terminal_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	return object_group == "terminal" or object_type.contains("terminal")

static func is_control_terminal(data: Dictionary) -> bool:
	return is_terminal_data(data) and normalize_terminal_type(data) == "control"

static func is_information_terminal(data: Dictionary) -> bool:
	return is_terminal_data(data) and normalize_terminal_type(data) == "information"

static func is_door_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	return object_group == "door" or object_type.contains("door") or object_type.contains("gate")
