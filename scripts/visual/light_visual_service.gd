extends RefCounted
class_name LightVisualService

const LIGHT_OFF_WALL_ASSET_ID := "light_off_wall_01"
const LIGHT_ON_WALL_ASSET_ID := "light_on_wall_01"
const LIGHT_ON_WALL_PULSAR_OVERLAY_ASSET_ID := "light_on_wall_pulsar_overlay_01"

const _OFF_STATES: Array[String] = ["off", "inactive", "disabled", "broken", "damaged", "unpowered"]
const _ON_STATES: Array[String] = ["active", "on", "switch_on"]

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower()

static func _light_identity_blob(object_data: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["object_type", "type", "archetype_id", "catalog_id", "prefab", "prefab_id", "map_constructor_prefab_id", "id", "object_id"]:
		parts.append(_normalized_text(object_data.get(key, "")))
	var blob: String = ""
	for part in parts:
		if not blob.is_empty():
			blob += " "
		blob += str(part)
	return blob

static func is_light_object(object_data: Dictionary) -> bool:
	var blob: String = _light_identity_blob(object_data)
	if blob.contains("light_switch") or blob.contains("light switch") or blob.contains("lightswitch"):
		return false
	return blob.contains("light")

static func is_light_on(object_data: Dictionary) -> bool:
	if object_data.has("light_enabled") and not bool(object_data.get("light_enabled", true)):
		return false
	if object_data.has("is_on") and not bool(object_data.get("is_on", false)):
		return false
	for key in ["state", "status", "power_state"]:
		var state_value: String = _normalized_text(object_data.get(key, ""))
		if state_value in _OFF_STATES:
			return false
	if object_data.has("light_enabled") and bool(object_data.get("light_enabled", true)) and not object_data.has("is_on"):
		return true
	if object_data.has("is_on") and bool(object_data.get("is_on", false)):
		return true
	for key in ["state", "status"]:
		var on_state_value: String = _normalized_text(object_data.get(key, ""))
		if on_state_value in _ON_STATES:
			return true
	return not object_data.has("light_enabled")

static func get_light_base_asset_key(object_data: Dictionary) -> String:
	return LIGHT_ON_WALL_ASSET_ID if is_light_on(object_data) else LIGHT_OFF_WALL_ASSET_ID

static func get_light_overlay_asset_key(_object_data: Dictionary) -> String:
	return LIGHT_ON_WALL_PULSAR_OVERLAY_ASSET_ID

static func should_draw_pulsar_overlay(object_data: Dictionary) -> bool:
	return is_light_object(object_data) and is_light_on(object_data)

static func get_pulsar_overlay_alpha(time_seconds: float, _object_data: Dictionary = {}) -> float:
	var wave: float = (sin(time_seconds * TAU * 0.65) + 1.0) * 0.5
	return lerpf(0.22, 0.42, wave)

static func get_soft_glow_alpha(time_seconds: float, _object_data: Dictionary = {}) -> float:
	var wave: float = (sin(time_seconds * TAU * 0.55 + 0.8) + 1.0) * 0.5
	return lerpf(0.08, 0.18, wave)
