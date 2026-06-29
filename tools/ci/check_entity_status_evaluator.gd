extends SceneTree

const Evaluator = preload("res://scripts/world/entity_status_evaluator.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _door(overrides: Dictionary = {}) -> Dictionary:
	var data: Dictionary = {"map_constructor_prefab_id":"door", "intent_state":"on", "health_state":"healthy", "operational_state":"open", "is_powered":true}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data

func _run() -> void:
	var broken: Dictionary = Evaluator.evaluate(_door({"health_state":"broken", "thermal_state":"overheated", "intent_state":"off", "operational_state":"locked"}))
	_assert(str(broken.get("reason_code", "")) == "health.broken", "broken must win over all blockers")
	var hot: Dictionary = Evaluator.evaluate(_door({"thermal_state":"overheated", "intent_state":"off", "operational_state":"locked"}), {"entity_contract":{"capabilities":{"state":true, "health":true, "overheat":true, "power":true}}})
	_assert(str(hot.get("reason_code", "")) == "thermal.overheated", "overheated must win after health")
	var off: Dictionary = Evaluator.evaluate(_door({"intent_state":"off", "operational_state":"locked"}))
	_assert(str(off.get("reason_code", "")) == "intent.off", "off must win before operational restriction")
	var locked: Dictionary = Evaluator.evaluate(_door({"operational_state":"locked"}))
	_assert(str(locked.get("reason_code", "")) == "operational.locked", "operational restriction must block")
	var operational: Dictionary = Evaluator.evaluate(_door({"operational_state":"open"}))
	_assert(bool(operational.get("is_operational", false)), "open door should be operational")

	var unpowered_source: Dictionary = _door({"intent_state":"on", "health_state":"healthy", "operational_state":"open", "is_powered":false})
	var unpowered_before: Dictionary = unpowered_source.duplicate(true)
	var unpowered: Dictionary = Evaluator.evaluate(unpowered_source)
	_assert(str(unpowered.get("reason_code", "")) == "power.unpowered", "unpowered must be computed blocker")
	_assert(unpowered_source == unpowered_before, "unpowered evaluation must not mutate canonical axes")
	_assert(str(Dictionary(unpowered.get("real_values", {})).get("intent_state", "")) == "on", "power loss must preserve intent")

	_assert(str(Dictionary(Evaluator.evaluate(_door({"operational_state":"closed"})).get("real_values", {})).get("operational_state", "")) == "closed", "door closed must remain operational_state")
	_assert(str(Dictionary(Evaluator.evaluate({"map_constructor_prefab_id":"fuse_box", "operational_state":"empty"}).get("real_values", {})).get("operational_state", "")) == "empty", "fuse empty must remain operational_state")
	_assert(str(Dictionary(Evaluator.evaluate({"map_constructor_prefab_id":"power_cable", "connection_state":"disconnected"}).get("real_values", {})).get("operational_state", "")) == "disconnected", "cable connection must remain operational_state")

	var passive: Dictionary = Evaluator.evaluate({"map_constructor_prefab_id":"external_air_duct", "route_mode":"inner"})
	_assert(Dictionary(passive.get("sections", {})).is_empty(), "passive route must not receive fake status sections")
	var repeated_source: Dictionary = _door({"operational_state":"open"})
	_assert(Evaluator.evaluate(repeated_source) == Evaluator.evaluate(repeated_source), "evaluation must be deterministic")
	var immutable_before: Dictionary = repeated_source.duplicate(true)
	Evaluator.evaluate(repeated_source)
	_assert(repeated_source == immutable_before, "evaluation must not mutate input dictionaries")

	var override_source: Dictionary = _door({"supports_test_override":true, "test_override_values":{"intent_state":"off"}})
	var overridden: Dictionary = Evaluator.evaluate(override_source, {"mode":"map_constructor"})
	_assert(str(Dictionary(overridden.get("real_values", {})).get("intent_state", "")) == "on", "override real value missing")
	_assert(str(Dictionary(overridden.get("forced_values", {})).get("intent_state", "")) == "off", "override forced value missing")
	_assert(not Evaluator.serializable_source(override_source).has("test_override_values"), "override values must not serialize")

	var legacy: Dictionary = Evaluator.evaluate({"map_constructor_prefab_id":"door", "state":"broken", "status":"off", "durability":0})
	_assert(str(legacy.get("reason_code", "")) == "health.broken", "legacy input must be read through adapter")
	_assert(not Dictionary(legacy.get("real_values", {})).has("state"), "canonical output must not expose legacy double truth")

	if failures.is_empty():
		print("ENTITY_STATUS_EVALUATOR_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ENTITY_STATUS_EVALUATOR_GATE: FAIL: %s" % failure)
	quit(1)
