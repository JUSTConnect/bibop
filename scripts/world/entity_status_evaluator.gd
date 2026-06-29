extends RefCounted
class_name EntityStatusEvaluator

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const INTENT_VALUES: Array[String] = ["on", "off"]
const HEALTH_VALUES: Array[String] = ["healthy", "damaged", "broken"]
const THERMAL_VALUES: Array[String] = ["normal", "overheated"]
const DEFAULT_OPERATIONAL_STATE := "operational"

static func evaluate(object_data: Dictionary, context: Dictionary = {}) -> Dictionary:
	var source: Dictionary = object_data.duplicate(true)
	var contract: Dictionary = _contract_for(source, context)
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {}))
	var real_values: Dictionary = _read_real_values(source, capabilities)
	var forced_values: Dictionary = _read_forced_values(source, capabilities, context)
	var effective_values: Dictionary = real_values.duplicate(true)
	for key in forced_values.keys():
		effective_values[key] = forced_values[key]
	var sections: Dictionary = _build_sections(effective_values, real_values, forced_values, capabilities)
	var external_blocker: String = _external_blocker(source, context, capabilities)
	var block: Dictionary = _blocking_result(effective_values, external_blocker)
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
	for key in ["test_override_enabled", "test_override_values", "forced_values", "override_values"]:
		result.erase(key)
	return result

static func _contract_for(source: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("entity_contract", {}) is Dictionary and not Dictionary(context.get("entity_contract", {})).is_empty():
		return Dictionary(context.get("entity_contract", {})).duplicate(true)
	if source.get("entity_contract", {}) is Dictionary and not Dictionary(source.get("entity_contract", {})).is_empty():
		return Dictionary(source.get("entity_contract", {})).duplicate(true)
	return WorldObjectCatalogRef.get_entity_definition_contract_for_object(source)

static func _read_real_values(source: Dictionary, capabilities: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	if bool(capabilities.get("state", false)):
		values["intent_state"] = _intent(source)
		values["operational_state"] = _operational(source)
	if bool(capabilities.get("health", false)):
		values["health_state"] = _health(source)
	if bool(capabilities.get("overheat", false)):
		values["thermal_state"] = _thermal(source)
	return values

static func _read_forced_values(source: Dictionary, capabilities: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(source.get("supports_test_override", context.get("supports_test_override", false))):
		return {}
	var mode: String = str(context.get("mode", context.get("context", ""))).strip_edges().to_lower().replace(" ", "_")
	if not (mode in ["map_constructor", "task_test", "task_test_context"]):
		return {}
	var raw: Variant = context.get("forced_values", source.get("forced_values", source.get("test_override_values", source.get("override_values", {}))))
	if not (raw is Dictionary):
		return {}
	var result: Dictionary = {}
	var allowed: Dictionary = _read_real_values(source, capabilities)
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

static func _blocking_result(values: Dictionary, external_blocker: String) -> Dictionary:
	if str(values.get("health_state", "healthy")) == "broken":
		return _blocked("broken", "health.broken", "Health state is broken.")
	if str(values.get("thermal_state", "normal")) == "overheated":
		return _blocked("overheated", "thermal.overheated", "Thermal state is overheated.")
	if str(values.get("intent_state", "on")) == "off":
		return _blocked("off", "intent.off", "Intent state is off.")
	if not external_blocker.is_empty():
		return _blocked(external_blocker.get_slice(".", 1) if external_blocker.contains(".") else external_blocker, external_blocker, "External blocker: %s." % external_blocker)
	var op: String = str(values.get("operational_state", DEFAULT_OPERATIONAL_STATE))
	if op in ["locked", "closed", "empty", "disconnected", "jammed", "blocked"]:
		return _blocked(op, "operational.%s" % op, "Operational state is %s." % op)
	return {"effective_state":op, "is_operational":true, "blocking_reason":"", "reason_code":"operational"}

static func _blocked(state: String, code: String, reason: String) -> Dictionary:
	return {"effective_state":state, "is_operational":false, "blocking_reason":reason, "reason_code":code}

static func _external_blocker(source: Dictionary, context: Dictionary, capabilities: Dictionary) -> String:
	var blocker: String = str(context.get("external_blocker", source.get("external_blocker", ""))).strip_edges().to_lower()
	if not blocker.is_empty():
		return blocker
	if bool(capabilities.get("power", false)) and (source.get("is_powered", true) == false or str(source.get("power_state", "")).to_lower() == "unpowered" or str(source.get("object_power_state", "")).to_lower() == "unpowered"):
		return "power.unpowered"
	return ""

static func _intent(source: Dictionary) -> String:
	return _normalize_axis("intent_state", source.get("intent_state", source.get("is_on", source.get("enabled", source.get("state", source.get("status", "on"))))))

static func _health(source: Dictionary) -> String:
	if bool(source.get("broken", false)):
		return "broken"
	if source.has("durability") and int(source.get("durability", 1)) <= 0:
		return "broken"
	return _normalize_axis("health_state", source.get("health_state", "damaged" if bool(source.get("damaged", false)) else "healthy"))

static func _thermal(source: Dictionary) -> String:
	if bool(source.get("overheated", false)):
		return "overheated"
	if source.has("current_heat") and source.has("overheat_threshold") and int(source.get("current_heat", 0)) >= int(source.get("overheat_threshold", 1)):
		return "overheated"
	return _normalize_axis("thermal_state", source.get("thermal_state", "normal"))

static func _operational(source: Dictionary) -> String:
	return _normalize_axis("operational_state", source.get("operational_state", source.get("door_state", source.get("fuse_state", source.get("connection_state", DEFAULT_OPERATIONAL_STATE)))))

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
	return DEFAULT_OPERATIONAL_STATE if normalized.is_empty() or normalized in ["on", "ready", "ok"] else normalized
