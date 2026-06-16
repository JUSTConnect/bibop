extends RefCounted
class_name VisualStateAssetService

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const CableReelVisualStateServiceRef = preload("res://scripts/game/cable/cable_reel_visual_state_service.gd")
const PowerSocketVisualStateServiceRef = preload("res://scripts/game/power/power_socket_visual_state_service.gd")

const VISUAL_STATE_BASE := "base"
const VISUAL_STATE_OFF := "off"
const VISUAL_STATE_ON := "on"
const VISUAL_STATE_POLICY_STATIC := "static"
const VISUAL_STATE_POLICY_POWERED_THREE_STATE := "powered_three_state"
const VISUAL_STATE_POLICY_CABLE_REEL_CONNECTION_STATE := "cable_reel_connection_state"
const VISUAL_STATE_POLICY_POWER_SOCKET_CONNECTION_STATE := "power_socket_connection_state"

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



static func normalize_direction_variant(value: Variant) -> String:
	var normalized: String = _normalized_text(value)
	match normalized:
		"ne", "north_east", "up_right", "right_up":
			return "ne"
		"nw", "north_west", "up_left", "left_up":
			return "nw"
		"se", "south_east", "down_right", "right_down":
			return "se"
		"sw", "south_west", "down_left", "left_down":
			return "sw"
		_:
			# TODO: Do not guess cardinal strings such as "right" without a project-wide isometric convention.
			return ""

static func get_logical_visual_variant(object_data: Dictionary, config: Dictionary) -> String:
	for key in ["airflow_direction", "flow_direction", "facing_side", "facing_dir", "direction", "visual_variant", "variant"]:
		var normalized: String = normalize_direction_variant(object_data.get(key, ""))
		if not normalized.is_empty():
			return normalized
	return normalize_direction_variant(config.get("default_variant", ""))

static func resolve_direction_variant_mapping(config: Dictionary, logical_variant: String) -> Dictionary:
	var default_variant: String = normalize_direction_variant(config.get("default_variant", ""))
	var normalized_variant: String = normalize_direction_variant(logical_variant)
	if normalized_variant.is_empty():
		normalized_variant = default_variant
	var variants: Dictionary = Dictionary(config.get("direction_variants", {})) if typeof(config.get("direction_variants", {})) == TYPE_DICTIONARY else {}
	if not variants.has(normalized_variant):
		normalized_variant = default_variant
	if variants.has(normalized_variant) and typeof(variants.get(normalized_variant)) == TYPE_DICTIONARY:
		var mapping: Dictionary = Dictionary(variants.get(normalized_variant)).duplicate(true)
		mapping["logical_variant"] = normalized_variant
		mapping["source_variant"] = _normalized_text(mapping.get("source", normalized_variant))
		mapping["mirror_x"] = bool(mapping.get("mirror_x", mapping.get("flip_x", false)))
		return mapping
	return {"logical_variant": normalized_variant, "source_variant": normalized_variant, "source": normalized_variant, "mirror_x": false}

static func resolve_visual_asset_descriptor(object_data: Dictionary) -> Dictionary:
	var asset_id: String = resolve_visual_asset_id(object_data)
	var family: String = get_visual_family(object_data)
	var config: Dictionary = get_visual_state_family_config(family)
	var mapping: Dictionary = resolve_direction_variant_mapping(config, get_logical_visual_variant(object_data, config)) if not config.is_empty() else {}
	return {
		"asset_id": asset_id,
		"visual_asset_id": asset_id,
		"mirror_x": bool(mapping.get("mirror_x", false)),
		"mirror_h": bool(mapping.get("mirror_x", false)),
		"logical_variant": str(mapping.get("logical_variant", "")),
		"source_variant": str(mapping.get("source_variant", ""))
	}

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

static func resolve_configured_state_asset_id(family: String, state: String, surface: String, variant: String = "") -> String:
	var config: Dictionary = get_visual_state_family_config(family)
	if config.is_empty():
		return ""
	var normalized_state: String = _normalized_text(state)
	var states_variant: Variant = config.get("states", {})
	if normalized_state.is_empty() or typeof(states_variant) != TYPE_DICTIONARY:
		return ""
	var states: Dictionary = Dictionary(states_variant)
	var normalized_variant: String = _normalized_text(variant)
	if not normalized_variant.is_empty() and states.has(normalized_variant) and typeof(states.get(normalized_variant)) == TYPE_DICTIONARY:
		var variant_states: Dictionary = Dictionary(states.get(normalized_variant))
		if variant_states.has(normalized_state):
			var variant_asset_id: String = VisualAssetCatalogRef.normalize_asset_id(str(variant_states.get(normalized_state, "")))
			return variant_asset_id if VisualAssetCatalogRef.has_asset(variant_asset_id) else ""
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

static func resolve_configured_overlay_asset_ids(family: String, state: String, surface: String, source_variant: String = "") -> Array[String]:
	var config: Dictionary = get_visual_state_family_config(family)
	var resolved: Array[String] = []
	if config.is_empty():
		return resolved
	var normalized_state: String = _normalized_text(state)
	var overlays_variant: Variant = config.get("overlays", {})
	if normalized_state.is_empty() or typeof(overlays_variant) != TYPE_DICTIONARY:
		return resolved
	var overlays: Dictionary = Dictionary(overlays_variant)
	var configured_variant: Variant = null
	var normalized_source_variant: String = _normalized_text(source_variant)
	if not normalized_source_variant.is_empty() and overlays.has(normalized_source_variant) and typeof(overlays.get(normalized_source_variant)) == TYPE_DICTIONARY:
		configured_variant = Dictionary(overlays.get(normalized_source_variant)).get(normalized_state, [])
	elif not normalized_surface.is_empty() and overlays.has(normalized_surface) and typeof(overlays.get(normalized_surface)) == TYPE_DICTIONARY and Dictionary(overlays.get(normalized_surface)).has(normalized_state):
		configured_variant = Dictionary(overlays.get(normalized_surface)).get(normalized_state, [])
	elif overlays.has(normalized_state):
		configured_variant = overlays.get(normalized_state, [])
	else:
		return resolved
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
	for key in ["visual_family", "visual_asset_family"]:
		var family: String = _normalized_text(object_data.get(key, ""))
		if has_visual_state_family(family):
			return true
	if policy == VISUAL_STATE_POLICY_STATIC:
		return false
	if policy == VISUAL_STATE_POLICY_POWERED_THREE_STATE:
		return true
	if policy == VISUAL_STATE_POLICY_CABLE_REEL_CONNECTION_STATE:
		return true
	if policy == VISUAL_STATE_POLICY_POWER_SOCKET_CONNECTION_STATE:
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


static func _configured_default_variant(family: String) -> String:
	var config: Dictionary = get_visual_state_family_config(family)
	return _normalized_text(config.get("default_variant", ""))

static func _resolve_door_pose_variant(object_data: Dictionary, fallback: String) -> String:
	for key in ["is_open", "open", "opened", "door_open"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return "open"
	var open_values: Array[String] = ["open", "opened", "unsealed"]
	var close_values: Array[String] = ["close", "closed", "sealed", "locked", "jammed", "unpowered"]
	for key in ["open_state", "door_state", "state", "status"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in open_values:
			return "open"
		if value in close_values:
			return "close"
	return fallback if not fallback.is_empty() else "close"

static func resolve_visual_variant(object_data: Dictionary) -> String:
	var family: String = get_visual_family(object_data)
	var config: Dictionary = get_visual_state_family_config(family)
	var fallback: String = _configured_default_variant(family)
	var explicit_variant: String = _first_text(object_data, ["visual_variant", "visual_pose", "variant", "pose"])
	if not explicit_variant.is_empty():
		return explicit_variant
	var policy: String = _normalized_text(config.get("variant_policy", object_data.get("variant_policy", "")))
	if policy == "door_pose":
		return _resolve_door_pose_variant(object_data, fallback)
	return fallback

static func get_visual_variant(object_data: Dictionary) -> String:
	return resolve_visual_variant(object_data)

static func _is_hard_unavailable_state(value: String) -> bool:
	return value in UNAVAILABLE_STATES and not POWER_FLAG_OVERRIDE_OFF_STATES.has(value)

static func _has_false_power_flag(object_data: Dictionary) -> bool:
	for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered"]:
		if object_data.has(key) and not bool(object_data.get(key, false)):
			return true
	return false

static func _has_true_power_flag(object_data: Dictionary) -> bool:
	for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered"]:
		if object_data.has(key) and bool(object_data.get(key, false)):
			return true
	return false

static func _is_power_socket_object(object_data: Dictionary, family: String = "") -> bool:
	if _normalized_text(family) == "power_socket":
		return true
	for key in ["object_type", "type", "archetype_id", "visual_family", "socket_type"]:
		var value: String = _normalized_text(object_data.get(key, ""))
		if value in ["power_socket", "outlet", "power_outlet"]:
			return true
	return bool(object_data.get("is_power_socket", false))

static func _has_connected_cable(object_data: Dictionary) -> bool:
	if object_data.has("connected") and not bool(object_data.get("connected", false)):
		return false
	if object_data.has("is_connected") and not bool(object_data.get("is_connected", false)):
		return false
	if bool(object_data.get("connected", false)) or bool(object_data.get("is_connected", false)):
		return true
	if _normalized_text(object_data.get("state", "")) == "connected":
		return true
	return not _normalized_text(object_data.get("connection_id", "")).is_empty()

static func _has_source_power(object_data: Dictionary) -> bool:
	var power_state: String = _normalized_text(object_data.get("power_state", ""))
	if _has_true_power_flag(object_data):
		return true
	if power_state in ACTIVE_STATES:
		return true
	if _has_false_power_flag(object_data):
		return false
	if power_state in POWER_OFF_STATES or power_state in UNAVAILABLE_STATES:
		return false
	return false

static func _resolve_power_socket_visual_state(object_data: Dictionary) -> String:
	if not _has_source_power(object_data):
		return VISUAL_STATE_BASE
	return VISUAL_STATE_ON if _has_connected_cable(object_data) else VISUAL_STATE_OFF

static func resolve_visual_state(object_data: Dictionary) -> String:
	var family: String = get_visual_family(object_data)
	var config: Dictionary = get_visual_state_family_config(family)
	var policy: String = _normalized_text(config.get("visual_state_policy", object_data.get("visual_state_policy", "")))
	if policy == VISUAL_STATE_POLICY_CABLE_REEL_CONNECTION_STATE:
		return CableReelVisualStateServiceRef.resolve_visual_state(object_data)
	if _is_power_socket_object(object_data, family):
		return _resolve_power_socket_visual_state(object_data)
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
	if object_data.has("fan_enabled"):
		return VISUAL_STATE_ON if bool(object_data.get("fan_enabled", false)) else VISUAL_STATE_OFF
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

static func resolve_visual_variant(object_data: Dictionary) -> String:
	return _first_text(object_data, ["station_type", "visual_variant", "variant"])

static func _family_uses_static_visual_policy(config: Dictionary, object_data: Dictionary) -> bool:
	return _normalized_text(config.get("visual_state_policy", object_data.get("visual_state_policy", ""))) == VISUAL_STATE_POLICY_STATIC

static func resolve_configured_variant_asset_id(family: String, variant: String, surface: String) -> String:
	var config: Dictionary = get_visual_state_family_config(family)
	if config.is_empty():
		return ""
	var normalized_variant: String = _normalized_text(variant)
	if normalized_variant.is_empty():
		normalized_variant = _normalized_text(config.get("default_variant", "lab"))
	var variants_value: Variant = config.get("variants", {})
	if typeof(variants_value) == TYPE_DICTIONARY:
		var variants: Dictionary = Dictionary(variants_value)
		if variants.has(normalized_variant):
			var configured_asset_id: String = VisualAssetCatalogRef.normalize_asset_id(str(variants.get(normalized_variant, "")))
			if VisualAssetCatalogRef.has_asset(configured_asset_id):
				return configured_asset_id
	var normalized_surface: String = _normalized_text(surface)
	var convention_asset_id: String = "%s_%s_%s_01" % [_normalized_text(family), normalized_variant, normalized_surface]
	if VisualAssetCatalogRef.has_asset(convention_asset_id):
		return convention_asset_id
	var default_variant: String = _normalized_text(config.get("default_variant", "lab"))
	if default_variant != normalized_variant:
		return resolve_configured_variant_asset_id(family, default_variant, surface)
	return VisualAssetCatalogRef.resolve_object_asset_id(family)

static func _state_candidates(family: String, state: String, surface: String, variant: String = "") -> Array[String]:
	var normalized_variant: String = _normalized_text(variant)
	if not normalized_variant.is_empty():
		return ["%s_%s_%s_%s_01" % [family, normalized_variant, state, surface], "%s_%s_%s_01" % [family, state, surface]]
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
	var config: Dictionary = get_visual_state_family_config(family)
	if _family_uses_static_visual_policy(config, object_data):
		var static_asset_id: String = resolve_configured_variant_asset_id(family, resolve_visual_variant(object_data), surface)
		return static_asset_id if not static_asset_id.is_empty() else "object_generic"
	var state: String = resolve_visual_state(object_data)
	var config: Dictionary = get_visual_state_family_config(family)
	var variant_mapping: Dictionary = resolve_direction_variant_mapping(config, get_logical_visual_variant(object_data, config)) if not config.is_empty() else {}
	var source_variant: String = str(variant_mapping.get("source_variant", ""))
	var fallback_states: Array[String] = _fallback_state_order(state)
	for candidate_state in fallback_states:
		var configured_asset_id: String = resolve_configured_state_asset_id(family, candidate_state, surface, source_variant)
		if not configured_asset_id.is_empty():
			return configured_asset_id
		for candidate in _state_candidates(family, str(candidate_state), surface, variant):
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
	var config: Dictionary = get_visual_state_family_config(family)
	var variant_mapping: Dictionary = resolve_direction_variant_mapping(config, get_logical_visual_variant(object_data, config)) if not config.is_empty() else {}
	var source_variant: String = str(variant_mapping.get("source_variant", ""))
	var resolved: Array[String] = resolve_configured_overlay_asset_ids(family, state, surface, source_variant)
	if not source_variant.is_empty():
		return resolved
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
