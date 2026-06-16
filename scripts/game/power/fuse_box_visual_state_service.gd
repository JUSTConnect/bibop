extends RefCounted
class_name FuseBoxVisualStateService

const STATE_BASE := "base"
const STATE_OFF := "off"
const STATE_ON := "on"
const POWER_OFF_STATES: Array[String] = ["unpowered", "no_power", "disconnected", "offline"]
const ACTIVE_STATES: Array[String] = ["on", "active", "ready", "enabled", "powered", "source_on", "switch_on"]
const UNAVAILABLE_STATES: Array[String] = ["off", "disabled", "error", "unavailable", "failed", "broken"]

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func resolve_visual_state(object_data: Dictionary) -> String:
	var has_line_power: bool = _has_line_power(object_data)
	var has_fuse: bool = _has_fuse(object_data)

	if not has_line_power:
		return STATE_BASE
	if not has_fuse:
		return STATE_OFF
	if _is_explicitly_unavailable(object_data):
		return STATE_OFF
	return STATE_ON

static func resolve_variant(object_data: Dictionary) -> String:
	return "with" if _has_fuse(object_data) else "without"

static func _has_fuse(object_data: Dictionary) -> bool:
	for key in ["has_fuse", "fuse_installed", "is_fuse_installed", "contains_fuse", "has_installed_fuse", "fuse_present", "inserted_fuse"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	for key in ["fuse_count", "inventory_fuse_count"]:
		if object_data.has(key) and int(object_data.get(key, 0)) > 0:
			return true
	return false

static func _has_line_power(object_data: Dictionary) -> bool:
	for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	for key in ["power_state", "status", "state"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in ACTIVE_STATES:
			return true
	for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"]:
		if object_data.has(key) and not bool(object_data.get(key, false)):
			return false
	for key in ["power_state", "status", "state"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in POWER_OFF_STATES:
			return false
	return false

static func _is_explicitly_unavailable(object_data: Dictionary) -> bool:
	for key in ["disabled", "unavailable", "error", "is_disabled", "is_unavailable", "has_error"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	for key in ["state", "status", "availability", "interaction_state"]:
		if _normalized_text(object_data.get(key, "")) in UNAVAILABLE_STATES:
			return true
	return false
