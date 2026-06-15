extends RefCounted
class_name VisualStateAssetService

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")

const VISUAL_STATE_BASE := "base"
const VISUAL_STATE_OFF := "off"
const VISUAL_STATE_ON := "on"
const VISUAL_STATE_POLICY_STATIC := "static"
const VISUAL_STATE_POLICY_POWERED_THREE_STATE := "powered_three_state"

const POWER_OFF_STATES: Array[String] = ["unpowered", "no_power", "disconnected", "offline"]
const ACTIVE_STATES: Array[String] = ["on", "active", "ready", "enabled", "powered", "source_on", "switch_on"]
const UNAVAILABLE_STATES: Array[String] = ["off", "source_off", "switch_off", "locked", "blocked", "disabled", "damaged", "error", "overheated", "cooldown", "jammed"]
const AVAILABLE_INTERACTION_STATES: Array[String] = ["available", "ready"]
const UNAVAILABLE_INTERACTION_STATES: Array[String] = ["unavailable", "locked", "blocked"]
const POWER_FLAG_OVERRIDE_OFF_STATES: Array[String] = ["off", "source_off", "switch_off"]

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


static func get_visual_state_family_config(family: String) -> Dictionary:
	var normalized_family: String = _normalized_text(family)
	if normalized_family.is_empty():
		return {}
	var families: Dictionary = VisualAssetCatalogRef.get_visual_state_asset_families()
	if not families.has(normalized_family):
		return {}
	var config_variant: Variant = families.get(normalized_family, {})
	if typeof(config_variant) != TYPE_DICTIONARY:
		return {}
	return Dictionary(config_variant).duplicate(true)

static func has_visual_state_family(family: String) -> bool:
	return not get_visual_state_family_config(family).is_empty()

static func resolve_configured_state_asset_id(family: String, state: String, surface: String) -> String:
	var config: Dictionary = get_visual_state_family_config(family)
	if config.is_empty():
		return ""
	var normalized_state: String = _normalized_text(state)
	var states_variant: Variant = config.get("states", {})
	if normalized_state.is_empty() or typeof(states_variant) != TYPE_DICTIONARY:
		return ""
	var states: Dictionary = Dictionary(states_variant)
	var normalized_surface: String = _normalized_text(surface)
	if states.has(normalized_surface) and typeof(states.get(normalized_surface)) == TYPE_DICTIONARY:
		var surface_states: Dictionary = Dictionary(states.get(normalized_surface))
		if surface_states.has(normalized_state):
			var surface_asset_id: String = VisualAssetCatalogRef.normalize_asset_id(str(surface_states.get(normalized_state, "")))
			return surface_asset_id if VisualAssetCatalogRef.has_asset(surface_asset_id) else ""
	if not states.has(normalized_state):
		return ""
	var asset_id: String = VisualAssetCatalogRef.normalize_asset_id(str(states.get(normalized_state, "")))
	return asset_id if VisualAssetCatalogRef.has_asset(asset_id) else ""

static func resolve_configured_overlay_asset_ids(family: String, state: String, surface: String) -> Array[String]:
	var config: Dictionary = get_visual_state_family_config(family)
	var resolved: Array[String] = []
	if config.is_empty():
		return resolved
	var normalized_state: String = _normalized_text(state)
	var overlays_variant: Variant = config.get("overlays", {})
	if normalized_state.is_empty() or typeof(overlays_variant) != TYPE_DICTIONARY:
		return resolved
	var overlays: Dictionary = Dictionary(overlays_variant)
	if not overlays.has(normalized_state):
		return resolved
	var configured_variant: Variant = overlays.get(normalized_state, [])
	var candidates: Array = []
	if typeof(configured_variant) == TYPE_STRING or typeof(configured_variant) == TYPE_STRING_NAME:
		candidates.append(str(configured_variant))
	elif typeof(configured_variant) == TYPE_ARRAY:
		candidates = Array(configured_variant)
	for candidate_variant in candidates:
		var asset_id: String = VisualAssetCatalogRef.normalize_asset_id(str(candidate_variant))
		if VisualAssetCatalogRef.has_asset(asset_id) and not resolved.has(asset_id):
			resolved.append(asset_id)
	return resolved

static func is_light_object(object_data: Dictionary) -> bool:
	var blob: String = _identity_blob(object_data)
	if blob.contains("light_switch") or blob.contains("lightswitch"):
		return false
	return blob.contains("light")

static func object_uses_visual_states(object_data: Dictionary) -> bool:
	var policy: String = _normalized_text(object_data.get("visual_state_policy", ""))
	if policy == VISUAL_STATE_POLICY_STATIC:
		return false
	for key in ["visual_family", "visual_asset_family"]:
		var family: String = _normalized_text(object_data.get(key, ""))
		if has_visual_state_family(family):
			return true
	if policy == VISUAL_STATE_POLICY_POWERED_THREE_STATE:
		return true
	if bool(object_data.get("power_visual_state_enabled", false)):
		return true
	return is_light_object(object_data)

static func get_visual_family(object_data: Dictionary) -> String:
	var family: String = _first_text(object_data, ["visual_family", "visual_asset_family"])
	if not family.is_empty():
		return family
	if is_light_object(object_data):
		return "light"
	return _first_text(object_data, ["object_type", "type"], "object")

static func get_visual_surface(object_data: Dictionary) -> String:
	var surface: String = _first_text(object_data, ["visual_surface", "surface"])
	if surface in ["wall", "floor"]:
		return surface
	var mount: String = _first_text(object_data, ["mount", "install_mode", "placement_mode", "placement"])
	if mount.contains("wall"):
		return "wall"
	if mount.contains("floor"):
		return "floor"
	var config: Dictionary = get_visual_state_family_config(get_visual_family(object_data))
	var configured_surface: String = _normalized_text(config.get("surface", ""))
	if configured_surface in ["wall", "floor"]:
		return configured_surface
	var default_surface: String = _normalized_text(config.get("default_surface", ""))
	if default_surface in ["wall", "floor"]:
		return default_surface
	if is_light_object(object_data):
		return "wall"
	return "floor"


static func _is_hard_unavailable_state(value: String) -> bool:
	return value in UNAVAILABLE_STATES and not POWER_FLAG_OVERRIDE_OFF_STATES.has(value)

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
	var power_state: String = _normalized_text(object_data.get("power_state", ""))
	if power_state in POWER_OFF_STATES:
		return VISUAL_STATE_BASE
	if _is_hard_unavailable_state(power_state):
		return VISUAL_STATE_OFF
	for key in ["state", "status"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if _is_hard_unavailable_state(value):
			return VISUAL_STATE_OFF
	if _has_false_power_flag(object_data):
		return VISUAL_STATE_BASE
	if power_state in ACTIVE_STATES:
		return VISUAL_STATE_ON
	if power_state in UNAVAILABLE_STATES:
		return VISUAL_STATE_OFF
	for key in ["state", "status"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in UNAVAILABLE_STATES:
			return VISUAL_STATE_OFF
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

static func _fallback_state_order(state: String) -> Array[String]:
	var normalized_state: String = _normalized_text(state)
	if normalized_state == VISUAL_STATE_ON:
		return [VISUAL_STATE_ON, VISUAL_STATE_OFF, VISUAL_STATE_BASE]
	if normalized_state == VISUAL_STATE_OFF:
		return [VISUAL_STATE_OFF, VISUAL_STATE_BASE]
	return [VISUAL_STATE_BASE]

static func resolve_visual_asset_id(object_data: Dictionary) -> String:
	if not object_uses_visual_states(object_data):
		var legacy_static: String = _legacy_asset_id(object_data)
		return VisualAssetCatalogRef.resolve_object_asset_id(legacy_static) if not legacy_static.is_empty() else "object_generic"
	var family: String = get_visual_family(object_data)
	var surface: String = get_visual_surface(object_data)
	var state: String = resolve_visual_state(object_data)
	var fallback_states: Array[String] = _fallback_state_order(state)
	for candidate_state in fallback_states:
		var configured_asset_id: String = resolve_configured_state_asset_id(family, candidate_state, surface)
		if not configured_asset_id.is_empty():
			return configured_asset_id
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
	if not selected_asset_id.is_empty():
		var normalized_selected: String = VisualAssetCatalogRef.normalize_asset_id(selected_asset_id)
		if normalized_selected != resolve_visual_asset_id(object_data):
			return []
	var resolved: Array[String] = resolve_configured_overlay_asset_ids(family, state, surface)
	var preferred: Array[String] = [
		"%s_%s_pulsar_overlay_%s_01" % [family, state, surface],
		"%s_%s_%s_pulsar_overlay_01" % [family, state, surface],
		"pulsar_overlay_%s_%s_%s_01" % [family, state, surface]
	]
	for candidate in preferred:
		if VisualAssetCatalogRef.has_asset(candidate) and not resolved.has(candidate):
			resolved.append(candidate)
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
