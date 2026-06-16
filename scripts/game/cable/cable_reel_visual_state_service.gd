extends RefCounted
class_name CableReelVisualStateService

const STATE_BASE: String = "base"
const STATE_OFF: String = "off"
const STATE_ON: String = "on"
const SOCKET_ALIASES: Array[String] = ["power_socket", "socket", "outlet", "power_outlet", "connector_socket", "cable_socket"]
const ENDPOINT_COLLECTION_KEYS: Array[String] = ["connected_ends", "cable_endpoints", "wire_endpoints", "endpoints", "connections", "connected_objects", "connected_object_ids", "endpoint_connections"]
const TARGET_KEYS: Array[String] = ["target", "target_object", "object", "connected_object", "connected_target", "socket", "outlet"]
const TARGET_ID_KEYS: Array[String] = ["target_id", "target_object_id", "object_id", "connected_object_id", "connected_id", "socket_id", "outlet_id"]

static func resolve_visual_state(object_data: Dictionary) -> String:
	var connected_endpoint_count: int = _get_connected_endpoint_count(object_data)
	var socket_connected_endpoint_count: int = _get_socket_connected_endpoint_count(object_data)
	if connected_endpoint_count >= 2 and socket_connected_endpoint_count >= 1:
		return STATE_ON
	if connected_endpoint_count == 1 and socket_connected_endpoint_count == 1:
		return STATE_OFF
	return STATE_BASE

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _get_connected_endpoint_count(object_data: Dictionary) -> int:
	var explicit_count: int = max(0, int(object_data.get("connected_endpoint_count", 0))) if object_data.has("connected_endpoint_count") else 0
	var count: int = 0
	for key in ENDPOINT_COLLECTION_KEYS:
		if object_data.has(key):
			count += _count_connected_entries(object_data.get(key))
	return explicit_count if explicit_count > 0 else count

static func _get_socket_connected_endpoint_count(object_data: Dictionary) -> int:
	var explicit_count: int = 0
	for key in ["socket_connected_endpoint_count", "connected_socket_count"]:
		if object_data.has(key):
			explicit_count = max(explicit_count, int(object_data.get(key, 0)))
	var count: int = 0
	for key in ENDPOINT_COLLECTION_KEYS:
		if object_data.has(key):
			count += _count_socket_entries(object_data.get(key))
	return explicit_count if explicit_count > 0 else count

static func _count_connected_entries(value: Variant) -> int:
	if typeof(value) == TYPE_ARRAY:
		var count: int = 0
		for entry in Array(value):
			if _entry_is_connected(entry):
				count += 1
		return count
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		var count: int = 0
		for key in dict.keys():
			if _entry_is_connected(dict.get(key)):
				count += 1
		return count
	return 1 if _normalized_text(value) != "" else 0

static func _count_socket_entries(value: Variant) -> int:
	if typeof(value) == TYPE_ARRAY:
		var count: int = 0
		for entry in Array(value):
			if _entry_is_connected_to_socket(entry):
				count += 1
		return count
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		var count: int = 0
		for key in dict.keys():
			if _entry_is_connected_to_socket(dict.get(key)):
				count += 1
		return count
	return 1 if _is_socket_like(value) else 0

static func _entry_is_connected(entry: Variant) -> bool:
	if typeof(entry) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(entry)
		if dict.has("connected"):
			return bool(dict.get("connected", false))
		if dict.has("is_connected"):
			return bool(dict.get("is_connected", false))
		if dict.has("disconnected") and bool(dict.get("disconnected", false)):
			return false
		if dict.has("state") and _normalized_text(dict.get("state")) in ["disconnected", "free", "on_reel", "empty", "none"]:
			return false
		for target_key in TARGET_KEYS + TARGET_ID_KEYS:
			if dict.has(target_key) and _normalized_text(dict.get(target_key)) != "":
				return true
		return _is_socket_like(dict)
	return _normalized_text(entry) != ""

static func _entry_is_connected_to_socket(entry: Variant) -> bool:
	if not _entry_is_connected(entry):
		return false
	if _is_socket_like(entry):
		return true
	if typeof(entry) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(entry)
		for target_key in TARGET_KEYS + TARGET_ID_KEYS:
			if dict.has(target_key) and _is_socket_like(dict.get(target_key)):
				return true
	return false

static func _is_socket_like(value: Variant) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		if bool(dict.get("is_socket", false)) or bool(dict.get("is_power_socket", false)):
			return true
		if _normalized_text(dict.get("socket_type", "")) != "":
			return true
		for key in ["object_type", "type", "archetype_id", "visual_family", "group", "object_group"]:
			var token: String = _normalized_text(dict.get(key, ""))
			if token in SOCKET_ALIASES:
				return true
		return false
	var text: String = _normalized_text(value)
	if text in SOCKET_ALIASES:
		return true
	for alias in SOCKET_ALIASES:
		if text.ends_with("_" + alias) or text.begins_with(alias + "_"):
			return true
	return false
