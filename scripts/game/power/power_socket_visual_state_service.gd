extends RefCounted
class_name PowerSocketVisualStateService

const STATE_BASE: String = "base"
const STATE_OFF: String = "off"
const STATE_ON: String = "on"

const FALSE_POWER_STATES: Array[String] = ["unpowered", "no_power", "offline", "disconnected"]
const TRUE_POWER_STATES: Array[String] = ["powered", "active", "ready", "source_on", "on"]

static func resolve_visual_state(object_data: Dictionary) -> String:
	if not _has_source_power(object_data):
		return STATE_BASE
	if _has_connected_cable(object_data):
		return STATE_ON
	return STATE_OFF

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _has_source_power(object_data: Dictionary) -> bool:
	var power_state: String = _normalized_text(object_data.get("power_state", ""))
	if power_state in FALSE_POWER_STATES:
		return false
	if power_state in TRUE_POWER_STATES:
		return true
	var status: String = _normalized_text(object_data.get("status", ""))
	if status in FALSE_POWER_STATES:
		return false
	if status in TRUE_POWER_STATES:
		return true
	var connection_state: String = _normalized_text(object_data.get("state", ""))
	if connection_state in ["unpowered", "no_power", "offline"]:
		return false
	if connection_state in TRUE_POWER_STATES:
		return true
	for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	return false

static func _has_connected_cable(object_data: Dictionary) -> bool:
	for key in ["has_connected_cable", "connected_cable", "connected", "is_connected"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	for key in ["connected_cable_id", "connected_reel_id", "connection_id"]:
		if not _normalized_text(object_data.get(key, "")).is_empty():
			return true
	if _normalized_text(object_data.get("state", "")) == "connected":
		return true
	if object_data.has("disconnected") and not bool(object_data.get("disconnected", true)) and _has_connection_evidence(object_data):
		return true
	for key in ["connected_endpoint_count", "socket_connected_endpoint_count"]:
		if object_data.has(key) and int(object_data.get(key, 0)) > 0:
			return true
	for key in ["endpoint_a_id", "endpoint_b_id", "socket_id"]:
		if not _normalized_text(object_data.get(key, "")).is_empty() and _has_connection_evidence(object_data):
			return true
	for key in ["connected_ends", "cable_endpoints", "endpoints", "connections"]:
		if _count_connected_entries(object_data.get(key, [])) > 0:
			return true
	return false

static func _has_connection_evidence(object_data: Dictionary) -> bool:
	for key in ["connected_cable_id", "connected_reel_id", "connection_id", "endpoint_a_id", "endpoint_b_id", "socket_id"]:
		if not _normalized_text(object_data.get(key, "")).is_empty():
			return true
	for key in ["connected_endpoint_count", "socket_connected_endpoint_count"]:
		if object_data.has(key) and int(object_data.get(key, 0)) > 0:
			return true
	return false

static func _count_connected_entries(value: Variant) -> int:
	if typeof(value) == TYPE_ARRAY:
		var count: int = 0
		for entry in Array(value):
			count += _count_connected_entries(entry)
		return count
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		if dict.has("connected") and not bool(dict.get("connected", false)):
			return 0
		if dict.has("is_connected") and not bool(dict.get("is_connected", false)):
			return 0
		return 1 if not dict.is_empty() else 0
	return 0
