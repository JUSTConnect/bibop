extends RefCounted
class_name MapConstructorInformationTerminalService

const TYPE_CONTROL: String = "control"
const TYPE_INFORMATION: String = "information"
const DATA_NONE: String = "none"
const DATA_ACCESS_CODE: String = "access_code"
const DATA_DIGITAL_KEY: String = "digital_key"
const DATA_FILE: String = "data_file"

static func normalize_terminal_type(value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match normalized:
		"control", "controller", "control_terminal":
			return TYPE_CONTROL
		"info", "information", "information_terminal", "data", "storage":
			return TYPE_INFORMATION
	return TYPE_INFORMATION

static func normalize_stored_data_type(value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match normalized:
		"", "none", "no_data", "empty":
			return DATA_NONE
		"code", "password", "pin", "pin_code", "access_code":
			return DATA_ACCESS_CODE
		"key", "digital", "digitalkey", "digital_key":
			return DATA_DIGITAL_KEY
		"file", "record", "datafile", "data_file":
			return DATA_FILE
	return DATA_NONE

static func is_information_terminal(data: Dictionary) -> bool:
	return normalize_terminal_type(data.get("terminal_type", data.get("terminal_mode", ""))) == TYPE_INFORMATION

static func is_control_terminal(data: Dictionary) -> bool:
	return normalize_terminal_type(data.get("terminal_type", data.get("terminal_mode", ""))) == TYPE_CONTROL

static func get_stored_data_type(data: Dictionary) -> String:
	return normalize_stored_data_type(data.get("stored_data_type", data.get("digital_payload_type", data.get("payload_type", ""))))

static func sanitize_information_terminal_data(data: Dictionary) -> Dictionary:
	var sanitized: Dictionary = data.duplicate(true)
	sanitized["terminal_type"] = normalize_terminal_type(sanitized.get("terminal_type", sanitized.get("terminal_mode", "")))
	if sanitized["terminal_type"] != TYPE_INFORMATION:
		return sanitized
	sanitized["controlled_target_type"] = "none"
	var stored_type: String = get_stored_data_type(sanitized)
	sanitized["stored_data_type"] = stored_type
	sanitized["digital_payload_type"] = stored_type
	match stored_type:
		DATA_NONE:
			_clear_payload_fields(sanitized)
		DATA_ACCESS_CODE:
			var code: String = str(sanitized.get("access_code_value", sanitized.get("stored_access_code", sanitized.get("access_code", "")))).strip_edges()
			sanitized["access_code_value"] = code
			sanitized["stored_access_code"] = code
			sanitized["access_code"] = code
			sanitized["encrypted"] = false
			sanitized["damaged"] = false
			sanitized["stored_digital_key_id"] = ""
			sanitized["stored_key_id"] = ""
			_clear_data_file_fields(sanitized)
		DATA_DIGITAL_KEY:
			var key_id: String = str(sanitized.get("stored_digital_key_id", sanitized.get("stored_key_id", sanitized.get("stored_item_id", "")))).strip_edges()
			sanitized["stored_digital_key_id"] = key_id
			sanitized["stored_key_id"] = key_id
			sanitized["stored_item_id"] = key_id
			sanitized["encrypted"] = false
			sanitized["damaged"] = false
			sanitized["access_code_value"] = ""
			sanitized["stored_access_code"] = ""
			sanitized["access_code"] = ""
			_clear_data_file_fields(sanitized)
		DATA_FILE:
			var file_id: String = str(sanitized.get("stored_data_file_id", sanitized.get("payload_id", sanitized.get("data_file_id", "")))).strip_edges()
			sanitized["stored_data_file_id"] = file_id
			sanitized["payload_id"] = file_id
			sanitized["data_file_id"] = file_id
			sanitized["stored_digital_key_id"] = ""
			sanitized["stored_key_id"] = ""
			sanitized["stored_item_id"] = ""
			sanitized["access_code_value"] = ""
			sanitized["stored_access_code"] = ""
			sanitized["access_code"] = ""
	return sanitized

static func validate_information_terminal_data(data: Dictionary) -> Dictionary:
	var sanitized: Dictionary = sanitize_information_terminal_data(data)
	if not is_information_terminal(sanitized):
		return {"ok": true, "errors": [], "data": sanitized, "message": "Control terminal."}
	var errors: Array[String] = []
	match get_stored_data_type(sanitized):
		DATA_ACCESS_CODE:
			var code: String = str(sanitized.get("access_code_value", "")).strip_edges()
			if code.length() != 4 or not code.is_valid_int():
				errors.append("Access code must be exactly 4 digits.")
		DATA_DIGITAL_KEY:
			if str(sanitized.get("stored_digital_key_id", "")).strip_edges().is_empty():
				errors.append("Digital key payload requires a key item.")
		DATA_FILE:
			if str(sanitized.get("stored_data_file_id", sanitized.get("payload_id", ""))).strip_edges().is_empty():
				errors.append("Data file payload requires an id or label.")
	var message: String = "OK"
	if not errors.is_empty():
		message = ""
		for error_text in errors:
			if not message.is_empty():
				message += "; "
			message += error_text
	return {"ok": errors.is_empty(), "errors": errors, "data": sanitized, "message": message}

static func get_information_terminal_summary(data: Dictionary) -> String:
	match get_stored_data_type(data):
		DATA_NONE:
			return "No data stored."
		DATA_ACCESS_CODE:
			return "Stores access code."
		DATA_DIGITAL_KEY:
			var key_id: String = str(data.get("stored_digital_key_id", data.get("stored_key_id", ""))).strip_edges()
			return "Stores digital key%s." % (": %s" % key_id if not key_id.is_empty() else "")
		DATA_FILE:
			var file_id: String = str(data.get("stored_data_file_id", data.get("payload_id", ""))).strip_edges()
			return "Stores data file%s." % (": %s" % file_id if not file_id.is_empty() else "")
	return "No data stored."

static func _clear_payload_fields(data: Dictionary) -> void:
	data["stored_digital_key_id"] = ""
	data["stored_key_id"] = ""
	data["stored_item_id"] = ""
	data["access_code_value"] = ""
	data["stored_access_code"] = ""
	data["access_code"] = ""
	_clear_data_file_fields(data)
	data["encrypted"] = false
	data["damaged"] = false

static func _clear_data_file_fields(data: Dictionary) -> void:
	data["stored_data_file_id"] = ""
	data["payload_id"] = ""
	data["data_file_id"] = ""
