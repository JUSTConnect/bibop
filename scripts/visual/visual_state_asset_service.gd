extends RefCounted
class_name VisualStateAssetService

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")

const VISUAL_STATE_BASE := "base"
const VISUAL_STATE_OFF := "off"
const VISUAL_STATE_ON := "on"
const VISUAL_STATE_POLICY_STATIC := "static"
const VISUAL_STATE_POLICY_POWERED_THREE_STATE := "powered_three_state"

const POWER_OFF_STATES: Array[String] = ["unpowered", "no_power", "disconnected", "offline"]
const ACTIVE_STATES: Array[String] = ["on", "active", "ready", "enabled", "powered"]
const UNAVAILABLE_STATES: Array[String] = ["off", "locked", "blocked", "disabled", "overheated", "cooldown", "jammed"]
const AVAILABLE_INTERACTION_STATES: Array[String] = ["available", "ready"]
const UNAVAILABLE_INTERACTION_STATES: Array[String] = ["unavailable", "locked", "blocked"]

static func _normalized_text(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

static func _first_text(object_data: Dictionary, keys: Array[String], fallback: String = "") -> String:
	for key in keys:
		var value: String = _normalized_text(object_data.get(key, ""))
		if not value.is_empty():
			return value
	return fallback

static func _identity_blob(object_data: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["object_type", "type", "archetype_id", "catalog_id", "prefab", "prefab_id", "map_constructor_prefab_id", "id", "object_id", "visual_family", "visual_asset_family"]:
		parts.append(_normalized_text(object_data.get(key, "")))
	var blob: String = ""
	for part in parts:
		if not blob.is_empty():
			blob += " "
		blob += part
	return blob

static func is_light_object(object_data: Dictionary) -> bool:
	var blob: String = _identity_blob(object_data)
	if blob.contains("light_switch") or blob.contains("lightswitch"):
		return false
	return blob.contains("light")

static func object_uses_visual_states(object_data: Dictionary) -> bool:
	var policy: String = _normalized_text(object_data.get("visual_state_policy", ""))
	if policy == VISUAL_STATE_POLICY_POWERED_THREE_STATE:
		return true
	if policy == VISUAL_STATE_POLICY_STATIC:
		return false
	if bool(object_data.get("power_visual_state_enabled", false)):
		return true
	for key in ["visual_family", "visual_asset_family"]:
		if not _normalized_text(object_data.get(key, "")).is_empty():
			return true
	return is_light_object(object_data)

static func get_visual_family(object_data: Dictionary) -> String:
	var family: String = _first_text(object_data, ["visual_family", "visual_asset_family", "visual_category"])
	if not family.is_empty():
		return family
	if is_light_object(object_data):
		return "light"
	return "object"

static func get_visual_surface(object_data: Dictionary) -> String:
	var surface: String = _first_text(object_data, ["visual_surface", "surface"])
	if surface in ["wall", "floor"]:
		return surface
	var mount: String = _first_text(object_data, ["mount", "install_mode", "placement_mode", "placement"])
	if mount.contains("wall"):
		return "wall"
	if mount.contains("floor"):
		return "floor"
	if is_light_object(object_data):
		return "wall"
	return "floor"

static func _has_false_power_flag(object_data: Dictionary) -> bool:
	for key in ["is_powered", "powered", "has_power", "receives_power"]:
		if object_data.has(key) and not bool(object_data.get(key, false)):
			return true
	return false

static func _has_true_power_flag(object_data: Dictionary) -> bool:
	for key in ["is_powered", "powered", "has_power", "receives_power"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	return false

static func resolve_visual_state(object_data: Dictionary) -> String:
	if _has_false_power_flag(object_data):
		return VISUAL_STATE_BASE
	var power_state: String = _normalized_text(object_data.get("power_state", ""))
	if power_state in POWER_OFF_STATES:
		return VISUAL_STATE_BASE
	var powered: bool = _has_true_power_flag(object_data) or power_state in ACTIVE_STATES
	if not powered and (object_data.has("power_state") or object_data.has("is_powered") or object_data.has("powered") or object_data.has("has_power") or object_data.has("receives_power")):
		return VISUAL_STATE_BASE
	if object_data.has("is_on"):
		return VISUAL_STATE_ON if bool(object_data.get("is_on", false)) else VISUAL_STATE_OFF
	var switch_state: String = _normalized_text(object_data.get("switch_state", ""))
	if switch_state == "on":
		return VISUAL_STATE_ON
	if switch_state == "off":
		return VISUAL_STATE_OFF
	for key in ["state", "status"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in ACTIVE_STATES:
			return VISUAL_STATE_ON
		if value in UNAVAILABLE_STATES:
			return VISUAL_STATE_OFF
	var interaction_state: String = _normalized_text(object_data.get("interaction_state", ""))
	if interaction_state in AVAILABLE_INTERACTION_STATES:
		return VISUAL_STATE_ON
	if interaction_state in UNAVAILABLE_INTERACTION_STATES:
		return VISUAL_STATE_OFF
	return VISUAL_STATE_ON if powered else VISUAL_STATE_BASE

static func _legacy_asset_id(object_data: Dictionary) -> String:
	return _first_text(object_data, ["texture_asset_id", "visual_texture_asset_id", "visual_asset_id", "asset_id"])

static func _state_candidates(family: String, state: String, surface: String) -> Array[String]:
	return ["%s_%s_%s_01" % [family, state, surface]]

static func resolve_visual_asset_id(object_data: Dictionary) -> String:
	if not object_uses_visual_states(object_data):
		var legacy_static: String = _legacy_asset_id(object_data)
		return VisualAssetCatalogRef.resolve_object_asset_id(legacy_static) if not legacy_static.is_empty() else "object_generic"
	var family: String = get_visual_family(object_data)
	var surface: String = get_visual_surface(object_data)
	var state: String = resolve_visual_state(object_data)
	var fallback_states: Array[String] = [state]
	if state == VISUAL_STATE_ON:
		fallback_states.append(VISUAL_STATE_OFF)
	if not fallback_states.has(VISUAL_STATE_BASE):
		fallback_states.append(VISUAL_STATE_BASE)
	# Compatibility: no light_base_wall asset exists yet.
	if family == "light" and surface == "wall" and not fallback_states.has(VISUAL_STATE_OFF):
		fallback_states.append(VISUAL_STATE_OFF)
	for candidate_state in fallback_states:
		for candidate in _state_candidates(family, str(candidate_state), surface):
			if VisualAssetCatalogRef.has_asset(candidate):
				return candidate
	var legacy_id: String = _legacy_asset_id(object_data)
	if not legacy_id.is_empty():
		return VisualAssetCatalogRef.resolve_object_asset_id(legacy_id)
	return "object_generic"

static func resolve_overlay_asset_ids(object_data: Dictionary, selected_asset_id: String = "") -> Array[String]:
	if not object_uses_visual_states(object_data):
		return []
	var family: String = get_visual_family(object_data)
	var surface: String = get_visual_surface(object_data)
	var state: String = resolve_visual_state(object_data)
	var preferred: Array[String] = [
		"%s_%s_pulsar_overlay_%s_01" % [family, state, surface],
		"%s_%s_%s_pulsar_overlay_01" % [family, state, surface],
		"pulsar_overlay_%s_%s_%s_01" % [family, state, surface]
	]
	var resolved: Array[String] = []
	for candidate in preferred:
		if VisualAssetCatalogRef.has_asset(candidate) and not resolved.has(candidate):
			resolved.append(candidate)
	if not selected_asset_id.is_empty():
		var normalized_selected: String = VisualAssetCatalogRef.normalize_asset_id(selected_asset_id)
		if not normalized_selected.contains("_%s_" % state):
			return []
	for asset_id in VisualAssetCatalogRef.get_all_asset_paths().keys():
		var normalized_id: String = VisualAssetCatalogRef.normalize_asset_id(str(asset_id))
		if normalized_id.contains("pulsar_overlay") and normalized_id.contains(family) and normalized_id.contains(state) and normalized_id.contains(surface) and not resolved.has(normalized_id):
			resolved.append(normalized_id)
	return resolved

static func get_pulsar_overlay_alpha(time_seconds: float, _object_data: Dictionary = {}) -> float:
	var wave: float = (sin(time_seconds * TAU * 0.65) + 1.0) * 0.5
	return lerpf(0.22, 0.42, wave)

static func get_soft_glow_alpha(time_seconds: float, _object_data: Dictionary = {}) -> float:
	var wave: float = (sin(time_seconds * TAU * 0.55 + 0.8) + 1.0) * 0.5
	return lerpf(0.08, 0.18, wave)
