extends RefCounted
class_name MapConstructorTerminalLinkFilterService

const InformationTerminalServiceRef = preload("res://scripts/game/map_constructor_information_terminal_service.gd")
const KeyDoorLinkServiceRef = preload("res://scripts/game/map_constructor_key_door_link_service.gd")

static func normalize_terminal_type(data: Dictionary) -> String:
	return InformationTerminalServiceRef.normalize_terminal_type(data.get("terminal_type", data.get("terminal_mode", "")))

static func normalize_stored_data_type(data: Dictionary) -> String:
	return InformationTerminalServiceRef.get_stored_data_type(data)

static func is_terminal_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	return object_group == "terminal" or object_type.contains("terminal")

static func is_control_terminal(data: Dictionary) -> bool:
	return is_terminal_data(data) and InformationTerminalServiceRef.is_control_terminal(data)

static func is_information_terminal(data: Dictionary) -> bool:
	return is_terminal_data(data) and InformationTerminalServiceRef.is_information_terminal(data)

static func is_door_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	return object_group == "door" or object_type.contains("door") or object_type.contains("gate")

static func can_information_terminal_store_for_door(terminal_data: Dictionary, door_data: Dictionary, key_lookup: Callable = Callable()) -> bool:
	if not is_information_terminal(terminal_data) or not is_door_data(door_data):
		return false
	var door_access: String = KeyDoorLinkServiceRef.get_door_access_type(door_data)
	var stored_type: String = normalize_stored_data_type(terminal_data)
	if door_access == KeyDoorLinkServiceRef.ACCESS_TYPE_DIGITAL_KEY:
		if stored_type != InformationTerminalServiceRef.DATA_DIGITAL_KEY:
			return false
		var stored_key_id: String = str(terminal_data.get("stored_digital_key_id", terminal_data.get("stored_key_id", terminal_data.get("stored_item_id", "")))).strip_edges()
		if stored_key_id.is_empty():
			return false
		var required_key_id: String = str(door_data.get("required_key_id", "")).strip_edges()
		if not required_key_id.is_empty() and stored_key_id != required_key_id:
			return false
		if key_lookup.is_valid():
			var key_data: Dictionary = Dictionary(key_lookup.call(stored_key_id))
			if not key_data.is_empty() and not KeyDoorLinkServiceRef.can_key_link_to_door(key_data, door_data):
				return false
		return true
	if door_access == KeyDoorLinkServiceRef.ACCESS_TYPE_ACCESS_CODE:
		if stored_type != InformationTerminalServiceRef.DATA_ACCESS_CODE:
			return false
		var terminal_code: String = str(terminal_data.get("access_code_value", terminal_data.get("stored_access_code", terminal_data.get("access_code", "")))).strip_edges()
		var door_code: String = str(door_data.get("access_code_value", door_data.get("access_code", door_data.get("password", "")))).strip_edges()
		return InformationTerminalServiceRef.is_four_digit_code(terminal_code) and (door_code.is_empty() or door_code == terminal_code)
	return false
