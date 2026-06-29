extends RefCounted
class_name EntityStatusEvaluator

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const HEALTH_VALUES: Array[String] = ["healthy", "damaged", "broken"]
const THERMAL_VALUES: Array[String] = ["normal", "overheated"]
const DEFAULT_OPERATIONAL_STATE := "operational"
const COMPUTED_AND_OVERRIDE_FIELDS: Array[String] = [
	"effective_state", "is_operational", "blocking_reason", "reason_code",
	"sections", "real_values", "forced_values", "test_override_enabled",
	"test_override_values", "override_values", "test_forced_values"
]

static func evaluate(object_data: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = object_data.duplicate(true)
	var contract: Dictionary = _contract_for(source, context)
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {}))
	var adapter: Dictionary = _legacy_status_adapter(source, contract, context)
	var real_values: Dictionary = _read_real_values(source, capabilities, adapter)
	var forced_values: Dictionary = _read_forced_values(source, capabilities, context, contract)
	var effective_values: Dictionary = real_values.duplicate(true)
	for key in forced_values.keys():
		effective_values[key] = forced_values[key]
	var sections: Dictionary = _build_sections(effective_values, real_values, forced_values, capabilities)
	var external_blocker: String = _external_blocker(source, context, capabilities, adapter)
	var block: Dictionary = _blocking_result(effective_values, external_blocker, contract, context)
	return {
		"effective_state":str(block.get("effective_state", "operational")),
		"is_operational":bool(block.get("is_operational", true)),
		"blocking_reason":str(block.get("blocking_reason", "")),
		"reason_code":str(block.get("reason_code", "operational")),
		"sections":sections,
		"real_values":real_values,
		"forced_values":forced_values
	}

static func serializable_source(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	for key in COMPUTED_AND_OVERRIDE_FIELDS:
		result.erase(key)
	return result

static func _contract_for(source: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("entity_contract", {}) is Dictionary and not Dictionary(context.get("entity_contract", {})).is_empty():
		return Dictionary(context.get("entity_contract", {})).duplicate(true)
	if source.get("entity_contract", {}) is Dictionary and not Dictionary(source.get("entity_contract", {})).is_empty():
		return Dictionary(source.get("entity_contract", {})).duplicate(true)
	return WorldObjectCatalogRef.get_entity_definition_contract_for_object(source)

static func _read_real_values(source: Dictionary, capabilities: Dictionary, adapter: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	if bool(capabilities.get("state", false)):
		values["intent_state"] = _intent(source, adapter)
		values["operational_state"] = _operational(source, adapter)
	if bool(capabilities.get("health", false)):
		values["health_state"] = _health(source, adapter)
	if bool(capabilities.get("overheat", false)):
		values["thermal_state"] = _thermal(source, adapter)
	return values

static func _read_forced_values(source: Dictionary, capabilities: Dictionary, context: Dictionary, contract: Dictionary) -> Dictionary:
	var contract_capabilities: Dictionary = Dictionary(contract.get("capabilities", {}))
	if not bool(contract_capabilities.get("test_override", false)):
		return {}
	if not bool(context.get("supports_test_override", source.get("supports_test_override", false))):
		return {}
	var mode: String = str(context.get("mode", context.get("context", ""))).strip_edges().to_lower().replace(" ", "_")
	if not (mode in ["map_constructor", "task_test", "task_test_context"]):
		return {}
	var raw: Variant = context.get("forced_values", source.get("forced_values", source.get("test_override_values", source.get("override_values", {}))))
	if not (raw is Dictionary):
		return {}
	var result: Dictionary = {}
	var allowed: Dictionary = _read_real_values(source, capabilities, _legacy_status_adapter(source, contract, context))
	for key in Dictionary(raw).keys():
		if allowed.has(key):
			result[key] = _normalize_axis(str(key), Dictionary(raw)[key])
	return result

static func _build_sections(values: Dictionary, real_values: Dictionary, forced_values: Dictionary, capabilities: Dictionary) -> Dictionary:
	var sections: Dictionary = {}
	if bool(capabilities.get("state", false)):
		sections["intent"] = {"value":values.get("intent_state", "on"), "real_value":real_values.get("intent_state", "on")}
		sections["operational"] = {"value":values.get("operational_state", DEFAULT_OPERATIONAL_STATE), "real_value":real_values.get("operational_state", DEFAULT_OPERATIONAL_STATE)}
	if bool(capabilities.get("health", false)):
		sections["health"] = {"value":values.get("health_state", "healthy"), "real_value":real_values.get("health_state", "healthy")}
	if bool(capabilities.get("overheat", false)):
		sections["thermal"] = {"value":values.get("thermal_state", "normal"), "real_value":real_values.get("thermal_state", "normal")}
	for key in forced_values.keys():
		var section_name: String = key.trim_suffix("_state")
		if sections.has(section_name):
			var section: Dictionary = Dictionary(sections[section_name])
			section["forced_value"] = forced_values[key]
			sections[section_name] = section
	return sections

static func _blocking_result(values: Dictionary, external_blocker: String, contract: Dictionary, context: Dictionary) -> Dictionary:
	if str(values.get("health_state", "healthy")) == "broken":
		return _blocked("broken", "health.broken", "Health state is broken.")
	if str(values.get("thermal_state", "normal")) == "overheated":
		return _blocked("overheated", "thermal.overheated", "Thermal state is overheated.")
	if str(values.get("intent_state", "on")) == "off":
		return _blocked("off", "intent.off", "Intent state is off.")
	if not external_blocker.is_empty():
		var blocker_state: String = external_blocker
		if external_blocker.contains("."):
			blocker_state = external_blocker.get_slice(".", 1)
		return _blocked(blocker_state, external_blocker, "External blocker: %s." % external_blocker)
	var operational_state: String = str(values.get("operational_state", DEFAULT_OPERATIONAL_STATE))
	var restriction_code: String = _operational_restriction_code(operational_state, contract, context)
	if not restriction_code.is_empty():
		return _blocked(operational_state, restriction_code, "Operational state is %s." % operational_state)
	return {"effective_state":operational_state, "is_operational":true, "blocking_reason":"", "reason_code":"operational"}

static func _blocked(state: String, code: String, reason: String) -> Dictionary:
	return {"effective_state":state, "is_operational":false, "blocking_reason":reason, "reason_code":code}

static func _external_blocker(source: Dictionary, context: Dictionary, capabilities: Dictionary, adapter: Dictionary) -> String:
	var blocker: String = str(context.get("external_blocker", source.get("external_blocker", adapter.get("external_blocker", "")))).strip_edges().to_lower()
	if not blocker.is_empty() and blocker != "power.unpowered":
		return blocker
	if bool(capabilities.get("power", false)) and blocker == "power.unpowered":
		return blocker
	if bool(capabilities.get("power", false)) and (source.get("is_powered", true) == false or str(source.get("power_state", "")).to_lower() == "unpowered" or str(source.get("object_power_state", "")).to_lower() == "unpowered"):
		return "power.unpowered"
	return ""

static func _legacy_status_adapter(source: Dictionary, contract: Dictionary, context: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var subtype: String = _entity_subtype(source, contract, context)
	var legacy_state: String = _normalized_legacy_state(source)
	if legacy_state.is_empty():
		return result
	if subtype == "power_cable" and legacy_state in ["connected", "disconnected", "broken", "invalid_path"]:
		result["operational_state"] = legacy_state
		return result
	if legacy_state in ["broken", "destroyed"]:
		result["health_state"] = "broken"
		return result
	if legacy_state == "damaged":
		result["health_state"] = "damaged"
		return result
	if legacy_state in ["overheat", "overheated"]:
		result["thermal_state"] = "overheated"
		return result
	if legacy_state == "off":
		result["intent_state"] = "off"
		return result
	if legacy_state == "unpowered":
		result["external_blocker"] = "power.unpowered"
		return result
	if subtype == "door" and legacy_state in ["open", "closed", "locked", "jammed"]:
		result["operational_state"] = legacy_state
	elif subtype in ["item", "digital_item", "access_item", "physical_item", "module_item", "power_cable_reel", "fuse", "repair_kit", "reinforcement"] and legacy_state in ["available", "collected", "disabled"]:
		result["operational_state"] = legacy_state
	elif subtype == "fuse_box" and legacy_state in ["installed", "empty"]:
		result["operational_state"] = legacy_state
	return result

static func _intent(source: Dictionary, adapter: Dictionary) -> String:
	if source.has("intent_state"):
		return _normalize_axis("intent_state", source.get("intent_state"))
	if adapter.has("intent_state"):
		return str(adapter.get("intent_state", "on"))
	if source.has("is_on"):
		return "on" if bool(source.get("is_on", true)) else "off"
	if source.has("enabled"):
		return "on" if bool(source.get("enabled", true)) else "off"
	return "on"

static func _health(source: Dictionary, adapter: Dictionary) -> String:
	if source.has("health_state"):
		return _normalize_axis("health_state", source.get("health_state"))
	if adapter.has("health_state"):
		return str(adapter.get("health_state", "healthy"))
	if bool(source.get("broken", false)):
		return "broken"
	if bool(source.get("destroyed", false)):
		return "broken"
	if bool(source.get("damaged", false)):
		return "damaged"
	if source.has("durability") and int(source.get("durability", 1)) <= 0:
		return "broken"
	return "healthy"

static func _thermal(source: Dictionary, adapter: Dictionary) -> String:
	if source.has("thermal_state"):
		return _normalize_axis("thermal_state", source.get("thermal_state"))
	if adapter.has("thermal_state"):
		return str(adapter.get("thermal_state", "normal"))
	if bool(source.get("overheated", false)):
		return "overheated"
	if source.has("current_heat") and source.has("overheat_threshold") and int(source.get("current_heat", 0)) >= int(source.get("overheat_threshold", 1)):
		return "overheated"
	return "normal"

static func _operational(source: Dictionary, adapter: Dictionary) -> String:
	if source.has("operational_state"):
		return _normalize_axis("operational_state", source.get("operational_state"))
	if adapter.has("operational_state"):
		return str(adapter.get("operational_state", DEFAULT_OPERATIONAL_STATE))
	if source.has("door_state"):
		return _normalize_axis("operational_state", source.get("door_state"))
	if source.has("fuse_state"):
		return _normalize_axis("operational_state", source.get("fuse_state"))
	if source.has("connection_state"):
		return _normalize_axis("operational_state", source.get("connection_state"))
	return DEFAULT_OPERATIONAL_STATE

static func _operational_restriction_code(operational_state: String, contract: Dictionary, context: Dictionary) -> String:
	var explicit_states: Array = Array(context.get("blocking_operational_states", []))
	if explicit_states.has(operational_state):
		return "operational.%s" % operational_state
	var subtype: String = str(context.get("entity_subtype", contract.get("entity_subtype", ""))).strip_edges().to_lower()
	var status_profile: String = str(context.get("status_profile", contract.get("status_profile", ""))).strip_edges().to_lower()
	if subtype == "door" and operational_state in ["locked", "jammed"]:
		return "operational.%s" % operational_state
	if status_profile == "item_standard" and operational_state == "disabled":
		return "operational.disabled"
	if subtype == "power_cable" and operational_state in ["broken", "invalid_path"]:
		return "operational.%s" % operational_state
	return ""

static func _entity_subtype(source: Dictionary, contract: Dictionary, context: Dictionary) -> String:
	var subtype: String = str(context.get("entity_subtype", contract.get("entity_subtype", ""))).strip_edges().to_lower()
	if not subtype.is_empty():
		return subtype
	return str(source.get("object_type", source.get("archetype_id", source.get("map_constructor_prefab_id", "")))).strip_edges().to_lower()

static func _normalized_legacy_state(source: Dictionary) -> String:
	var has_legacy: bool = source.has("state") or source.has("status") or source.has("object_state")
	if not has_legacy:
		return ""
	return str(source.get("state", source.get("status", source.get("object_state", "")))).strip_edges().to_lower().replace("-", "_").replace(" ", "_")

static func _normalize_axis(axis: String, value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if axis == "intent_state":
		if normalized in ["off", "false", "disabled"]:
			return "off"
		return "on"
	if axis == "health_state":
		return normalized if normalized in HEALTH_VALUES else "healthy"
	if axis == "thermal_state":
		if normalized in ["overheat", "overheated"]:
			return "overheated"
		return "normal"
	return DEFAULT_OPERATIONAL_STATE if normalized.is_empty() or normalized in ["on", "ready", "ok", "active", "inactive"] else normalized
