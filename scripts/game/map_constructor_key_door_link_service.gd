extends RefCounted
class_name MapConstructorKeyDoorLinkService

const ACCESS_TYPE_NO_KEY: String = "none"
const ACCESS_TYPE_MECHANICAL_KEY: String = "mechanical_key"
const ACCESS_TYPE_DIGITAL_KEY: String = "digital_key"
const ACCESS_TYPE_ACCESS_CODE: String = "access_code"
const ACCESS_TYPE_TERMINAL: String = "terminal_access"

static func normalize_access_type(value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	normalized = normalized.replace(" ", "_")
	normalized = normalized.replace("-", "_")
	match normalized:
		"", "none", "no_key", "open":
			return ACCESS_TYPE_NO_KEY
		"key", "mechanical", "mechanical_key", "key_card", "keycard", "physical_key":
			return ACCESS_TYPE_MECHANICAL_KEY
		"digital", "digital_key", "digital_keycard", "digital_access":
			return ACCESS_TYPE_DIGITAL_KEY
		"code", "access_code", "digital_code", "pin", "pin_code":
			return ACCESS_TYPE_ACCESS_CODE
		"terminal", "terminal_access", "access_terminal":
			return ACCESS_TYPE_TERMINAL
	return normalized

static func get_key_access_type(key_data: Dictionary) -> String:
	for field_name in ["access_type", "key_access_type", "key_type", "key_kind", "digital_payload_type", "item_type", "object_type", "map_constructor_prefab_id", "id"]:
		var value: String = str(key_data.get(field_name, "")).strip_edges().to_lower()
		if value.is_empty():
			continue
		if value.contains("digital"):
			return ACCESS_TYPE_DIGITAL_KEY
		if value.contains("access_code") or value.contains("digital_code") or value.contains("pin"):
			return ACCESS_TYPE_ACCESS_CODE
		if value.contains("mechanical") or value.contains("keycard") or value.contains("key_card"):
			return ACCESS_TYPE_MECHANICAL_KEY
	var normalized: String = normalize_access_type(key_data.get("key_type", key_data.get("key_kind", key_data.get("item_type", ""))))
	if normalized == ACCESS_TYPE_NO_KEY:
		return ACCESS_TYPE_MECHANICAL_KEY
	return normalized

static func get_door_access_type(door_data: Dictionary) -> String:
	var access_type: String = normalize_access_type(door_data.get("access_type", door_data.get("lock_type", "")))
	if access_type != ACCESS_TYPE_NO_KEY:
		return access_type
	var classifier: String = "%s %s %s %s" % [str(door_data.get("id", "")).to_lower(), str(door_data.get("object_type", "")).to_lower(), str(door_data.get("display_name", "")).to_lower(), str(door_data.get("map_constructor_prefab_id", "")).to_lower()]
	if classifier.contains("digital"):
		return ACCESS_TYPE_DIGITAL_KEY
	if classifier.contains("code") or classifier.contains("pin"):
		return ACCESS_TYPE_ACCESS_CODE
	if classifier.contains("terminal"):
		return ACCESS_TYPE_TERMINAL
	if classifier.contains("mechanical") or classifier.contains("key"):
		return ACCESS_TYPE_MECHANICAL_KEY
	return ACCESS_TYPE_NO_KEY

static func can_key_link_to_door(key_data: Dictionary, door_data: Dictionary) -> bool:
	var key_access_type: String = get_key_access_type(key_data)
	var door_access_type: String = get_door_access_type(door_data)
	if door_access_type == ACCESS_TYPE_NO_KEY:
		return false
	if key_access_type == ACCESS_TYPE_ACCESS_CODE:
		return door_access_type == ACCESS_TYPE_ACCESS_CODE
	if key_access_type == ACCESS_TYPE_DIGITAL_KEY:
		return door_access_type == ACCESS_TYPE_DIGITAL_KEY
	if key_access_type == ACCESS_TYPE_MECHANICAL_KEY:
		return door_access_type == ACCESS_TYPE_MECHANICAL_KEY
	return key_access_type == door_access_type

static func is_digital_key(data: Dictionary) -> bool:
	return get_key_access_type(data) == ACCESS_TYPE_DIGITAL_KEY

static func is_digital_door(data: Dictionary) -> bool:
	return get_door_access_type(data) == ACCESS_TYPE_DIGITAL_KEY
