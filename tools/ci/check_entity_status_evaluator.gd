extends SceneTree

const Evaluator = preload("res://scripts/world/entity_status_evaluator.gd")
const Catalog = preload("res://scripts/world/world_object_catalog.gd")
const StatusLayer = preload("res://scripts/world/object_status_layer.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _object(prefab_id: String, overrides: Dictionary = {}) -> Dictionary:
	var data: Dictionary = Catalog.create_world_object(prefab_id, "%s_status_eval_test" % prefab_id)
	if data.is_empty():
		data = {"map_constructor_prefab_id":prefab_id}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data

func _result_value(result: Dictionary, name: String) -> String:
	return str(Dictionary(result.get("real_values", {})).get(name, ""))

func _assert_catalog_profiles_known() -> void:
	for definitions_variant in [Catalog.ARCHETYPE_REGISTRY, Catalog.OBJECT_LIBRARY]:
		var definitions: Dictionary = Dictionary(definitions_variant)
		for definition_id_variant in definitions.keys():
			var definition_id: String = str(definition_id_variant)
			var definition: Dictionary = Dictionary(definitions[definition_id_variant])
			var contract: Dictionary = Dictionary(definition.get("entity_contract", {}))
			if str(contract.get("scope", "")) != "entity":
				continue
			var profile: String = str(contract.get("status_profile", ""))
			_assert(Evaluator.is_known_status_profile(profile), "unknown catalog status_profile %s on %s" % [profile, definition_id])

func _run() -> void:
	_assert_catalog_profiles_known()

	var broken: Dictionary = Evaluator.evaluate(_object("door", {"health_state":"broken", "thermal_state":"overheated", "intent_state":"off", "operational_state":"locked"}))
	_assert(str(broken.get("reason_code", "")) == "health.broken", "broken must win over all blockers")
	var hot_contract: Dictionary = {"entity_subtype":"thermal_test", "status_profile":"thermal_test", "capabilities":{"state":true, "health":true, "overheat":true, "power":false, "test_override":true}}
	var hot: Dictionary = Evaluator.evaluate_synthetic_for_test({"map_constructor_prefab_id":"thermal_test", "thermal_state":"overheated", "intent_state":"off", "operational_state":"locked"}, hot_contract)
	_assert(str(hot.get("reason_code", "")) == "thermal.overheated", "overheated must win after health when overheat is supported")
	var door_without_thermal: Dictionary = Evaluator.evaluate(_object("door", {"thermal_state":"overheated"}))
	_assert(not Dictionary(door_without_thermal.get("sections", {})).has("thermal"), "door contract must not receive a thermal section")
	var off: Dictionary = Evaluator.evaluate(_object("door", {"intent_state":"off", "operational_state":"locked"}))
	_assert(str(off.get("reason_code", "")) == "intent.off", "off must win before operational restriction")
	var locked: Dictionary = Evaluator.evaluate(_object("door", {"operational_state":"locked"}))
	_assert(str(locked.get("reason_code", "")) == "operational.locked", "locked door must be subtype operational restriction")
	var closed: Dictionary = Evaluator.evaluate(_object("door", {"operational_state":"closed"}))
	_assert(bool(closed.get("is_operational", false)), "closed healthy door remains a functioning door")
	var open: Dictionary = Evaluator.evaluate(_object("door", {"operational_state":"open"}))
	_assert(bool(open.get("is_operational", false)), "open door should be operational")

	var unpowered_source: Dictionary = _object("door", {"intent_state":"on", "health_state":"healthy", "operational_state":"closed", "is_powered":false})
	var unpowered_before: Dictionary = unpowered_source.duplicate(true)
	var unpowered: Dictionary = Evaluator.evaluate(unpowered_source)
	_assert(str(unpowered.get("reason_code", "")) == "power.unpowered", "unpowered must be computed blocker")
	_assert(str(unpowered.get("effective_state", "")) == "unavailable", "power.unpowered must expose effective_state=unavailable")
	_assert(unpowered_source == unpowered_before, "unpowered evaluation must not mutate canonical axes")
	_assert(_result_value(unpowered, "intent_state") == "on", "power loss must preserve intent")
	_assert(_result_value(unpowered, "health_state") == "healthy", "power loss must preserve health")
	_assert(_result_value(unpowered, "operational_state") == "closed", "power loss must preserve operational state")
	var forged_source_blocker: Dictionary = Evaluator.evaluate(_object("door", {"external_blocker":"power.unpowered", "is_powered":true, "operational_state":"closed"}))
	_assert(str(forged_source_blocker.get("reason_code", "")) == "operational", "persisted source external_blocker must not be authority")

	_assert(_result_value(Evaluator.evaluate(_object("door", {"state":"open"})), "operational_state") == "open", "legacy door open maps to operational_state")
	_assert(_result_value(Evaluator.evaluate(_object("door", {"state":"closed"})), "operational_state") == "closed", "legacy door closed maps to operational_state")
	_assert(_result_value(Evaluator.evaluate(_object("door", {"state":"locked"})), "operational_state") == "locked", "legacy door locked maps to operational_state")
	_assert(str(Evaluator.evaluate(_object("door", {"state":"broken"})).get("reason_code", "")) == "health.broken", "legacy state=broken works without durability=0")
	var legacy_hot: Dictionary = Evaluator.evaluate_synthetic_for_test({"map_constructor_prefab_id":"thermal_test", "state":"overheated"}, hot_contract)
	_assert(str(legacy_hot.get("reason_code", "")) == "thermal.overheated", "legacy state=overheated maps to thermal_state when overheat is supported")

	var fuse_empty_source: Dictionary = _object("fuse_box")
	var fuse_empty: Dictionary = Evaluator.evaluate(fuse_empty_source)
	_assert(_result_value(fuse_empty, "operational_state") == "empty", "catalog fuse box without fuse must resolve empty")
	_assert(str(fuse_empty.get("reason_code", "")) == "operational.empty", "fuse_box.empty blocker code must be explicit")
	var fuse_installed_source: Dictionary = fuse_empty_source.duplicate(true)
	fuse_installed_source["state"] = "installed"
	fuse_installed_source["fuse_present"] = true
	fuse_installed_source["fuse_installed"] = true
	var fuse_installed: Dictionary = Evaluator.evaluate(fuse_installed_source)
	_assert(_result_value(fuse_installed, "operational_state") == "installed", "installed fuse remains operational_state")

	var connected_cable_source: Dictionary = _object("power_cable")
	var connected_cable: Dictionary = Evaluator.evaluate(connected_cable_source)
	_assert(_result_value(connected_cable, "operational_state") == "connected", "untouched catalog power cable must resolve connected")
	var disconnected_cable_source: Dictionary = connected_cable_source.duplicate(true)
	disconnected_cable_source["is_connected"] = false
	disconnected_cable_source["connected"] = false
	disconnected_cable_source["disconnected"] = true
	var disconnected_cable: Dictionary = Evaluator.evaluate(disconnected_cable_source)
	_assert(_result_value(disconnected_cable, "operational_state") == "disconnected", "legacy connection booleans must resolve disconnected")
	_assert(str(disconnected_cable.get("reason_code", "")) == "operational.disconnected", "power_cable.disconnected blocker code must be explicit")
	var broken_cable_source: Dictionary = connected_cable_source.duplicate(true)
	broken_cable_source["broken"] = true
	broken_cable_source["cable_health_state"] = "broken"
	var broken_cable: Dictionary = Evaluator.evaluate(broken_cable_source)
	_assert(_result_value(broken_cable, "operational_state") == "broken", "power cable broken maps to operational_state")
	_assert(not bool(broken_cable.get("is_operational", true)), "power cable broken must be non-operational")
	_assert(str(broken_cable.get("reason_code", "")) == "operational.broken", "power cable broken must use operational.broken")
	var invalid_cable_source: Dictionary = connected_cable_source.duplicate(true)
	invalid_cable_source["connection_state"] = "invalid_path"
	_assert(str(Evaluator.evaluate(invalid_cable_source).get("reason_code", "")) == "operational.invalid_path", "power cable invalid_path must use operational restriction")

	_assert(_result_value(Evaluator.evaluate(_object("fuse", {"state":"available"})), "operational_state") == "available", "item available maps to operational_state")
	_assert(_result_value(Evaluator.evaluate(_object("fuse", {"state":"collected"})), "operational_state") == "collected", "item collected maps to operational_state")
	var cable_sections: Dictionary = Dictionary(connected_cable.get("sections", {}))
	_assert(not cable_sections.has("intent"), "power_cable must not receive intent section")
	var door_sections: Dictionary = Dictionary(closed.get("sections", {}))
	_assert(door_sections.has("intent") and door_sections.has("operational"), "door must expose intent and operational sections")
	var disabled_fuse: Dictionary = Evaluator.evaluate(_object("fuse", {"state":"disabled"}))
	_assert(_result_value(disabled_fuse, "operational_state") == "disabled", "physical item disabled maps to operational_state")
	_assert(str(disabled_fuse.get("reason_code", "")) == "operational.disabled", "item_standard physical item disabled must restrict operation")
	var disabled_module: Dictionary = Evaluator.evaluate(_object("module_internal", {"state":"disabled"}))
	_assert(_result_value(disabled_module, "operational_state") == "disabled", "module item disabled maps to operational_state")
	_assert(str(disabled_module.get("reason_code", "")) == "operational.disabled", "item_standard module item disabled must restrict operation")
	_assert(not Dictionary(disabled_fuse.get("sections", {})).has("intent"), "fuse physical item must not receive intent section")
	_assert(not Dictionary(disabled_module.get("sections", {})).has("intent"), "module item must not receive intent section")

	var crate_result: Dictionary = Evaluator.evaluate(_object("crate"))
	var crate_sections: Dictionary = Dictionary(crate_result.get("sections", {}))
	_assert(crate_sections.has("health") and crate_sections.has("operational"), "movable_standard crate must expose health and operational sections")
	_assert(not crate_sections.has("intent"), "movable_standard crate must not expose intent")
	var barrel_sections: Dictionary = Dictionary(Evaluator.evaluate(_object("barrel")).get("sections", {}))
	_assert(barrel_sections.has("health") and barrel_sections.has("operational"), "movable_standard barrel must expose status axes")

	var passive_air: Dictionary = Evaluator.evaluate(_object("external_air_duct", {"route_mode":"inner"}))
	var passive_water: Dictionary = Evaluator.evaluate(_object("external_water_pipe", {"route_mode":"inner"}))
	_assert(Dictionary(passive_air.get("sections", {})).is_empty(), "passive air duct must not receive fake status sections")
	_assert(Dictionary(passive_water.get("sections", {})).is_empty(), "passive water pipe must not receive fake status sections")
	var forged_passive_context: Dictionary = Evaluator.evaluate(_object("external_air_duct"), {"status_profile":"object_standard", "entity_subtype":"door", "allowed_status_axes":["intent", "operational"]})
	_assert(Dictionary(forged_passive_context.get("sections", {})).is_empty(), "context must not add axes forbidden by canonical contract")
	var no_power_item: Dictionary = Evaluator.evaluate(_object("fuse", {"state":"unpowered"}))
	_assert(str(no_power_item.get("reason_code", "")) == "operational", "legacy unpowered must be ignored when contract power=false")

	var repeated_source: Dictionary = _object("door", {"operational_state":"open"})
	_assert(Evaluator.evaluate(repeated_source) == Evaluator.evaluate(repeated_source), "evaluation must be deterministic")
	var immutable_before: Dictionary = repeated_source.duplicate(true)
	Evaluator.evaluate(repeated_source)
	_assert(repeated_source == immutable_before, "evaluation must not mutate input dictionaries")

	var unsupported_override_source: Dictionary = _object("door", {"test_override_values":{"intent_state":"off"}})
	var unsupported_override: Dictionary = Evaluator.evaluate(unsupported_override_source, {"mode":"map_constructor"})
	_assert(Dictionary(unsupported_override.get("forced_values", {})).is_empty(), "missing supports_test_override must prevent forced values")
	var override_source: Dictionary = _object("door", {"supports_test_override":true, "test_override_values":{"intent_state":"off"}})
	var overridden: Dictionary = Evaluator.evaluate(override_source, {"mode":"map_constructor"})
	_assert(_result_value(overridden, "intent_state") == "on", "override real value missing")
	_assert(str(Dictionary(overridden.get("forced_values", {})).get("intent_state", "")) == "off", "override forced value missing")
	var forged_source: Dictionary = _object("door", {"supports_test_override":true, "thermal_state":"overheated", "test_override_values":{"thermal_state":"overheated"}, "entity_contract":{"status_profile":"thermal_test", "capabilities":{"state":true, "health":true, "overheat":true, "power":true, "test_override":true}}})
	var forged_result: Dictionary = Evaluator.evaluate(forged_source, {"mode":"map_constructor", "entity_contract":hot_contract, "status_profile":"thermal_test", "allowed_status_axes":["thermal"]})
	_assert(not Dictionary(forged_result.get("sections", {})).has("thermal"), "forged source/context contract must not add thermal axis")
	_assert(Dictionary(forged_result.get("forced_values", {})).is_empty(), "forged source/context contract must not authorize unsupported forced values")
	var forbidden_contract: Dictionary = {"entity_subtype":"door", "status_profile":"object_standard", "capabilities":{"state":true, "health":true, "overheat":false, "power":true, "test_override":false}}
	var forbidden_override: Dictionary = Evaluator.evaluate_synthetic_for_test(_object("door", {"supports_test_override":true, "test_override_values":{"intent_state":"off"}}), forbidden_contract, {"mode":"map_constructor"})
	_assert(Dictionary(forbidden_override.get("forced_values", {})).is_empty(), "instance supports_test_override cannot bypass synthetic contract")

	var serializable: Dictionary = Evaluator.serializable_source({"effective_state":"off", "is_operational":false, "blocking_reason":"x", "reason_code":"x", "sections":{}, "real_values":{}, "forced_values":{}, "test_override_values":{"intent_state":"off"}, "intent_state":"on"})
	for computed_key in ["effective_state", "is_operational", "blocking_reason", "reason_code", "sections", "real_values", "forced_values", "test_override_values"]:
		_assert(not serializable.has(computed_key), "computed field serialized: %s" % computed_key)
	_assert(str(serializable.get("intent_state", "")) == "on", "serializable source must preserve canonical fields")

	var legacy: Dictionary = Evaluator.evaluate(_object("door", {"state":"broken", "status":"off"}))
	_assert(str(legacy.get("reason_code", "")) == "health.broken", "legacy input must be read through adapter")
	_assert(not Dictionary(legacy.get("real_values", {})).has("state"), "canonical output must not expose legacy double truth")

	var layer: ObjectStatusLayerService = StatusLayer.new()
	var ui_section: VBoxContainer = layer.build_read_only_status_section(null, _object("door", {"operational_state":"closed"}))
	_assert(ui_section != null and ui_section.get_child_count() > 1, "existing inspector status section must remain visible")
	_assert(_contains_interactive_control(ui_section) == false, "inspector status section must be read-only")

	if failures.is_empty():
		print("ENTITY_STATUS_EVALUATOR_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ENTITY_STATUS_EVALUATOR_GATE: FAIL: %s" % failure)
	quit(1)

func _contains_interactive_control(node: Node) -> bool:
	if node is OptionButton or node is SpinBox or node is CheckBox or node is LineEdit:
		return true
	for child in node.get_children():
		if _contains_interactive_control(child):
			return true
	return false
