extends RefCounted
class_name ConnectorCapabilityService

# Connector/device-link capability helpers.
# Foundation only: no HUD drawing, no scene mutation, no GameUI integration.

const ItemFileTypesRef = preload("res://scripts/game/inventory/item_file_types.gd")

const CONNECTOR_NONE: String = "none"
const CONNECTOR_BASIC: String = "basic_connector"
const CONNECTOR_ADVANCED: String = "advanced_connector"
const CONNECTOR_WIRELESS: String = "wireless_connector"

const DEVICE_CLASS_C1: String = "C1"
const DEVICE_CLASS_C2: String = "C2"
const DEVICE_CLASS_C3: String = "C3"

const ACTION_CONNECT: String = "connect"
const ACTION_SCAN: String = "scan"
const ACTION_HACK: String = "hack"
const ACTION_UNLOCK: String = "unlock"
const ACTION_OPEN: String = "open"
const ACTION_DISCONNECT: String = "disconnect"

const CONTROL_INTERNAL: String = "internal"
const CONTROL_EXTERNAL: String = "external"
const POWER_INTERNAL: String = "internal"
const POWER_EXTERNAL: String = "external"

const ACCESS_NONE: String = "none"
const ACCESS_DIGITAL_KEY: String = "digital_key"
const ACCESS_PHYSICAL_KEY: String = "physical_key"
const ACCESS_ACCESS_CODE: String = "access_code"
const ACCESS_HACK_ONLY: String = "hack_only"

static func normalize_device_class(device_class: String) -> String:
	var normalized: String = str(device_class).strip_edges().to_upper()
	if normalized in [DEVICE_CLASS_C1, DEVICE_CLASS_C2, DEVICE_CLASS_C3]:
		return normalized
	return DEVICE_CLASS_C1

static func get_class_level(device_class: String) -> int:
	match normalize_device_class(device_class):
		DEVICE_CLASS_C1:
			return 1
		DEVICE_CLASS_C2:
			return 2
		DEVICE_CLASS_C3:
			return 3
		_:
			return 1

static func get_version_level(version_value: Variant) -> int:
	if version_value is int:
		return max(0, int(version_value))
	var text: String = str(version_value).strip_edges().to_lower()
	if text.begins_with("v"):
		text = text.substr(1)
	return max(0, int(text))

static func can_connect(connector_profile: Dictionary, device_profile: Dictionary) -> Dictionary:
	var connector_type: String = str(connector_profile.get("type", CONNECTOR_NONE))
	if connector_type == CONNECTOR_NONE or connector_type.is_empty():
		return {"ok": false, "message": "No connector installed."}
	var connector_version: int = get_version_level(connector_profile.get("version", 1))
	var required_version: int = get_version_level(device_profile.get("required_connector_version", 1))
	if connector_version < required_version:
		return {"ok": false, "message": "Connector version is too weak.", "required_version": required_version, "connector_version": connector_version}
	return {"ok": true, "message": "Connected.", "connector_version": connector_version}

static func can_scan(is_connected: bool) -> Dictionary:
	if not is_connected:
		return {"ok": false, "message": "Connect first."}
	return {"ok": true, "message": "Scan ready."}

static func can_hack(processor_profile: Dictionary, device_profile: Dictionary, is_connected: bool) -> Dictionary:
	if not is_connected:
		return {"ok": false, "message": "Connect first."}
	var processor_version: int = get_version_level(processor_profile.get("version", 0))
	if processor_version <= 0:
		return {"ok": false, "message": "No processor installed."}
	var device_level: int = get_class_level(str(device_profile.get("device_class", DEVICE_CLASS_C1)))
	if processor_version < device_level:
		return {
			"ok": false,
			"message": "Hack failed: processor is too weak.",
			"processor_version": processor_version,
			"required_level": device_level
		}
	return {"ok": true, "message": "Hack succeeded.", "processor_version": processor_version, "required_level": device_level}

static func build_scan_result(device_profile: Dictionary, current_state: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"action": ACTION_SCAN,
		"device_id": str(device_profile.get("id", device_profile.get("object_id", ""))),
		"display_name": str(device_profile.get("display_name", device_profile.get("name", "Device"))),
		"device_kind": str(device_profile.get("device_kind", device_profile.get("kind", "unknown"))),
		"device_class": normalize_device_class(str(device_profile.get("device_class", DEVICE_CLASS_C1))),
		"power_mode": str(device_profile.get("power_mode", POWER_INTERNAL)),
		"control_mode": str(device_profile.get("control_mode", CONTROL_INTERNAL)),
		"access_mode": str(device_profile.get("access_mode", ACCESS_NONE)),
		"is_locked": bool(current_state.get("is_locked", device_profile.get("is_locked", false))),
		"is_open": bool(current_state.get("is_open", device_profile.get("is_open", false))),
		"stored_key_terminal_id": str(device_profile.get("stored_key_terminal_id", "")),
		"control_terminal_id": str(device_profile.get("control_terminal_id", "")),
		"messages": []
	}
	var messages: Array[String] = []
	if str(result.get("access_mode", "")) == ACCESS_DIGITAL_KEY and bool(result.get("is_locked", false)):
		if not str(result.get("stored_key_terminal_id", "")).is_empty():
			messages.append("Digital key is stored in terminal: %s" % str(result.get("stored_key_terminal_id", "")))
		else:
			messages.append("Digital key is required.")
	if bool(result.get("is_open", false)):
		messages.append("Device is already open.")
	elif not bool(result.get("is_locked", false)):
		messages.append("Device is unlocked.")
	result["messages"] = messages
	result["available_actions"] = get_available_actions_after_scan(result)
	return result

static func get_available_actions_after_scan(scan_result: Dictionary) -> Array[String]:
	var actions: Array[String] = [ACTION_DISCONNECT]
	var access_mode: String = str(scan_result.get("access_mode", ACCESS_NONE))
	var is_locked: bool = bool(scan_result.get("is_locked", false))
	var is_open: bool = bool(scan_result.get("is_open", false))
	if is_locked:
		if access_mode == ACCESS_DIGITAL_KEY or access_mode == ACCESS_PHYSICAL_KEY or access_mode == ACCESS_ACCESS_CODE:
			actions.insert(0, ACTION_UNLOCK)
		actions.insert(0, ACTION_HACK)
	else:
		if not is_open:
			actions.insert(0, ACTION_OPEN)
	return actions

static func find_digital_key_in_buffer(buffer_files: Array[Dictionary], required_key_id: String = "") -> Dictionary:
	for entry in buffer_files:
		var file_entry: Dictionary = Dictionary(entry)
		if not ItemFileTypesRef.is_digital_key_file(file_entry):
			continue
		if not ItemFileTypesRef.is_open_file(file_entry):
			continue
		if required_key_id.is_empty() or str(file_entry.get("id", "")) == required_key_id or str(file_entry.get("key_id", "")) == required_key_id:
			return file_entry.duplicate(true)
	return {}

static func unlock_with_digital_key(device_profile: Dictionary, buffer_files: Array[Dictionary], required_key_id: String = "") -> Dictionary:
	var key_file: Dictionary = find_digital_key_in_buffer(buffer_files, required_key_id)
	if key_file.is_empty():
		return {"ok": false, "message": "Digital key is absent in buffer.", "consumed_file_id": "", "device_state": {"is_locked": true}}
	return {
		"ok": true,
		"message": "Door unlocked.",
		"consumed_file_id": str(key_file.get("id", "")),
		"device_state": {"is_locked": false, "is_open": bool(device_profile.get("is_open", false))},
		"next_actions": [ACTION_OPEN, ACTION_DISCONNECT]
	}

static func consume_file_from_buffer_and_storage(buffer_files: Array[Dictionary], storage_files: Array[Dictionary], file_id: String) -> Dictionary:
	return {
		"buffer_files": _remove_entry_by_id(buffer_files, file_id),
		"storage_files": _remove_entry_by_id(storage_files, file_id),
		"consumed_file_id": file_id
	}

static func make_disconnect_result() -> Dictionary:
	return {"ok": true, "message": "Disconnected.", "close_hud": true, "clear_history": true}

static func _remove_entry_by_id(entries: Array[Dictionary], entry_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		var entry_dict: Dictionary = Dictionary(entry)
		if str(entry_dict.get("id", "")) != str(entry_id):
			result.append(entry_dict.duplicate(true))
	return result
