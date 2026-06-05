extends RefCounted
class_name MapConstructorInspectorVisibilityService

static func get_object_type(data: Dictionary) -> String:
	return _normalize_text(data.get("object_type", data.get("item_type", "")))

static func is_power_source(data: Dictionary) -> bool:
	return get_object_type(data).begins_with("power_source")

static func normalize_terminal_type(data: Dictionary) -> String:
	var terminal_type: String = _normalize_text(data.get("terminal_type", data.get("terminal_mode", "")))
	if terminal_type in ["info", "data", "storage"]:
		return "information"
	if terminal_type in ["controller", "control_terminal"]:
		return "control"
	return terminal_type if terminal_type in ["information", "control"] else "information"

static func is_information_terminal(data: Dictionary) -> bool:
	return normalize_terminal_type(data) == "information"

static func is_control_terminal(data: Dictionary) -> bool:
	return normalize_terminal_type(data) == "control"

static func normalize_stored_data_type(data: Dictionary) -> String:
	var stored_data_type: String = _normalize_text(data.get("stored_data_type", data.get("digital_payload_type", data.get("payload_type", ""))))
	if stored_data_type in ["code", "password"]:
		return "access_code"
	if stored_data_type in ["key", "digitalkey"]:
		return "digital_key"
	if stored_data_type in ["file", "record", "datafile"]:
		return "data_file"
	return stored_data_type if stored_data_type in ["access_code", "digital_key", "data_file"] else "access_code"

static func should_show_terminal_controlled_target(data: Dictionary) -> bool:
	return is_control_terminal(data)

static func should_show_terminal_stored_data(data: Dictionary) -> bool:
	return is_information_terminal(data)

static func should_show_terminal_stored_data_damage_flags(data: Dictionary) -> bool:
	return should_show_terminal_stored_data(data) and normalize_stored_data_type(data) == "data_file"

static func normalize_control_type(data: Dictionary) -> String:
	var control_type: String = _normalize_text(data.get("control_type", data.get("control_mode", "")))
	if control_type.is_empty():
		control_type = "external" if bool(data.get("requires_external_control", false)) else "internal"
	control_type = control_type.trim_suffix("_control")
	if control_type in ["external control", "terminal"]:
		return "external"
	if control_type in ["internal control"]:
		return "internal"
	if control_type == "none" or control_type == "non":
		return "none"
	return control_type

static func normalize_power_type(data: Dictionary) -> String:
	var power_type: String = _normalize_text(data.get("power_type", data.get("power_mode", "")))
	if power_type.is_empty():
		power_type = "external" if bool(data.get("requires_external_power", false)) else "internal"
	power_type = power_type.trim_suffix("_power")
	if power_type in ["external power"]:
		return "external"
	if power_type in ["internal power"]:
		return "internal"
	if power_type == "none" or power_type == "non":
		return "none"
	return power_type

static func should_show_external_control_selector(data: Dictionary) -> bool:
	return normalize_control_type(data) == "external"

static func should_show_internal_control_settings(data: Dictionary, type_group: String) -> bool:
	if normalize_control_type(data) != "internal":
		return false
	if type_group in ["control", "platform"]:
		return true
	return get_object_type(data) == "platform"

static func should_show_external_power_source_selector(data: Dictionary) -> bool:
	return normalize_power_type(data) == "external" and not is_power_source(data)

static func should_show_external_circuit_selector(data: Dictionary) -> bool:
	if not should_show_external_power_source_selector(data):
		return false
	return has_selected_power_source(data)

static func should_show_power_source_circuit_management(data: Dictionary) -> bool:
	return is_power_source(data)

static func should_show_same_circuit_summary(data: Dictionary) -> bool:
	return is_power_source(data)

static func has_selected_power_source(data: Dictionary) -> bool:
	for field_name in ["power_source_id", "source_object_id", "linked_power_source_id", "external_power_source_id"]:
		if not _normalize_text(data.get(field_name, "")).is_empty():
			return true
	return false

static func _normalize_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower()
