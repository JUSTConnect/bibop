extends SceneTree

const ResolverRef = preload("res://scripts/world/power_control_resolver.gd")
const BindingContractRef = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _source(id: String, cell: Vector2i, circuit: String = "main") -> Dictionary:
	return {
		"id": id,
		"position": cell,
		"object_group": "power",
		"object_type": "power_source_class_1",
		"generic_power_role": "power_source",
		"power_mode": "internal",
		"control_mode": "internal",
		"intent_state": "on",
		"health_state": "healthy",
		"thermal_state": "normal",
		"operational_state": "active",
		"power_network_id": circuit,
		"outlet_capacity": 4
	}

func _cable(id: String, cell: Vector2i, circuit: String = "main", broken: bool = false) -> Dictionary:
	return {
		"id": id,
		"position": cell,
		"object_group": "cable",
		"object_type": "power_cable",
		"power_network_id": circuit,
		"health_state": "broken" if broken else "healthy",
		"operational_state": "broken" if broken else "connected",
		"connected": not broken
	}

func _consumer(id: String, cell: Vector2i, circuit: String = "main", control_mode: String = "none") -> Dictionary:
	return {
		"id": id,
		"position": cell,
		"object_group": "machine",
		"object_type": "machine",
		"power_mode": "external",
		"control_mode": control_mode,
		"control_loss_behavior": "keep_last_state",
		"power_network_id": circuit,
		"intent_state": "on",
		"health_state": "healthy",
		"thermal_state": "normal",
		"operational_state": "closed",
		"state": "closed"
	}

func _terminal(id: String, cell: Vector2i, powered: bool = true) -> Dictionary:
	return {
		"id": id,
		"position": cell,
		"object_group": "terminal",
		"object_type": "control_terminal",
		"power_mode": "internal" if powered else "external",
		"control_mode": "internal",
		"intent_state": "on",
		"health_state": "healthy",
		"thermal_state": "normal",
		"operational_state": "active"
	}

func _control_binding(id: String, terminal_id: String, target_id: String) -> Dictionary:
	return {
		"id": id,
		"role": BindingContractRef.ROLE_CONTROL_TERMINAL,
		"source_id": terminal_id,
		"target_id": target_id,
		"parameters": {},
		"format_version": BindingContractRef.FORMAT_VERSION
	}

func _preference_binding(id: String, consumer_id: String, source_id: String) -> Dictionary:
	return {
		"id": id,
		"role": BindingContractRef.ROLE_PREFERRED_POWER_SOURCE,
		"source_id": consumer_id,
		"target_id": source_id,
		"parameters": {},
		"format_version": BindingContractRef.FORMAT_VERSION
	}

func _power_result(resolution: Dictionary, entity_id: String) -> Dictionary:
	return Dictionary(Dictionary(resolution.get("power_results", {})).get(entity_id, {}))

func _control_result(resolution: Dictionary, entity_id: String) -> Dictionary:
	return Dictionary(Dictionary(resolution.get("control_results", {})).get(entity_id, {}))

func _run() -> void:
	await process_frame

	var internal_object: Dictionary = _consumer("internal", Vector2i(0, 0))
	internal_object["power_mode"] = "internal"
	internal_object["is_powered"] = false
	var internal_resolution: Dictionary = ResolverRef.resolve_world([internal_object])
	var internal_power: Dictionary = _power_result(internal_resolution, "internal")
	_assert(bool(internal_power.get("is_powered", false)), "internal power was allowed to become unpowered")
	_assert(str(internal_power.get("power_state", "")) == "powered", "internal power state is not powered")

	var none_object: Dictionary = _consumer("none", Vector2i(0, 0))
	none_object["power_mode"] = "none"
	var none_power: Dictionary = _power_result(ResolverRef.resolve_world([none_object]), "none")
	_assert(str(none_power.get("power_state", "")) == "none", "power_mode none did not produce a non-applicable state")

	var unpowered_objects: Array[Dictionary] = [_consumer("lonely", Vector2i(5, 5), "alpha")]
	var unpowered: Dictionary = _power_result(ResolverRef.resolve_world(unpowered_objects), "lonely")
	_assert(str(unpowered.get("power_state", "")) == "unpowered", "external consumer without topology was powered")
	_assert(str(unpowered.get("reason_code", "")) == "power.no_reachable_source", "missing topology reason code changed")

	var one_source_objects: Array[Dictionary] = [
		_source("source_a", Vector2i(0, 0), "alpha"),
		_cable("cable_a", Vector2i(1, 0), "alpha"),
		_consumer("consumer_a", Vector2i(2, 0), "alpha")
	]
	var one_source_resolution: Dictionary = ResolverRef.resolve_world(one_source_objects)
	var one_source_power: Dictionary = _power_result(one_source_resolution, "consumer_a")
	_assert(bool(one_source_power.get("is_powered", false)), "single physically reachable source did not power consumer")
	_assert(str(one_source_power.get("resolved_source_id", "")) == "source_a", "single source was not resolved deterministically")

	var state_preservation_objects: Array[Dictionary] = [_consumer("stateful", Vector2i(9, 9), "isolated")]
	var state_before: Dictionary = state_preservation_objects[0].duplicate(true)
	ResolverRef.apply_world_results(state_preservation_objects)
	for field_name in ["intent_state", "health_state", "thermal_state", "operational_state", "state"]:
		_assert(state_preservation_objects[0].get(field_name) == state_before.get(field_name), "power recalculation mutated canonical field %s" % field_name)
	_assert(not state_preservation_objects[0].has("state_before_unpowered"), "legacy state restoration field was recreated")

	var broken_objects: Array[Dictionary] = [
		_source("source_broken_path", Vector2i(0, 0), "broken_path"),
		_cable("broken_cable", Vector2i(1, 0), "broken_path", true),
		_consumer("broken_target", Vector2i(2, 0), "broken_path")
	]
	var broken_power: Dictionary = _power_result(ResolverRef.resolve_world(broken_objects), "broken_target")
	_assert(str(broken_power.get("power_state", "")) == "unpowered", "broken cable still delivered power")

	var virtual_objects: Array[Dictionary] = [
		_source("virtual_source", Vector2i(0, 0), "main_power_net"),
		_consumer("virtual_target", Vector2i(8, 8), "main_power_net")
	]
	var virtual_power: Dictionary = _power_result(ResolverRef.resolve_world(virtual_objects), "virtual_target")
	_assert(str(virtual_power.get("power_state", "")) == "unpowered", "main_power_net bypassed physical topology")

	var many_objects: Array[Dictionary] = [
		_source("source_left", Vector2i(0, 1), "shared"),
		_source("source_right", Vector2i(4, 1), "shared"),
		_cable("cable_left", Vector2i(1, 1), "shared"),
		_cable("cable_mid", Vector2i(2, 1), "shared"),
		_cable("cable_right", Vector2i(3, 1), "shared"),
		_consumer("shared_target", Vector2i(2, 2), "shared")
	]
	var ambiguous_power: Dictionary = _power_result(ResolverRef.resolve_world(many_objects), "shared_target")
	_assert(str(ambiguous_power.get("power_state", "")) == "ambiguous", "multiple reachable sources were not reported as ambiguous")
	_assert(not bool(ambiguous_power.get("is_powered", true)), "ambiguous network remained powered")
	var preferred_bindings: Array[Dictionary] = [_preference_binding("preferred_left", "shared_target", "source_left")]
	var preferred_power: Dictionary = _power_result(ResolverRef.resolve_world(many_objects, preferred_bindings), "shared_target")
	_assert(bool(preferred_power.get("is_powered", false)), "valid preferred source did not resolve ambiguity")
	_assert(str(preferred_power.get("resolved_source_id", "")) == "source_left", "preferred source binding selected wrong source")
	var invalid_preference: Array[Dictionary] = [_preference_binding("preferred_missing", "shared_target", "missing_source")]
	var invalid_preferred_power: Dictionary = _power_result(ResolverRef.resolve_world(many_objects, invalid_preference), "shared_target")
	_assert(str(invalid_preferred_power.get("power_state", "")) == "ambiguous", "invalid preference incorrectly powered ambiguous network")

	var reel_target: Dictionary = _consumer("reel_target", Vector2i(0, 0), "")
	reel_target["power_input_profile"] = "runtime_reel_feed"
	reel_target["runtime_reel_feed_active"] = true
	reel_target["resolved_source_id"] = "socket_source"
	var reel_power: Dictionary = _power_result(ResolverRef.resolve_world([reel_target]), "reel_target")
	_assert(bool(reel_power.get("is_powered", false)), "active runtime reel feed was ignored")
	_assert(str(reel_power.get("resolved_circuit_id", "")) == "main", "runtime reel feed circuit is not main")

	var internally_controlled: Dictionary = _consumer("internal_control", Vector2i(0, 0), "", "internal")
	internally_controlled["power_mode"] = "internal"
	var internal_control_result: Dictionary = _control_result(ResolverRef.resolve_world([internally_controlled]), "internal_control")
	_assert(bool(internal_control_result.get("available", false)), "internal control was unavailable for operational powered entity")
	_assert(bool(internal_control_result.get("local_control_available", false)), "internal control did not expose local action")

	var controlled_target: Dictionary = _consumer("controlled_target", Vector2i(2, 0), "", "external")
	controlled_target["power_mode"] = "internal"
	var terminal: Dictionary = _terminal("terminal_a", Vector2i(0, 0), true)
	var control_bindings: Array[Dictionary] = [_control_binding("control_a", "terminal_a", "controlled_target")]
	var external_resolution: Dictionary = ResolverRef.resolve_world([terminal, controlled_target], control_bindings)
	var external_control: Dictionary = _control_result(external_resolution, "controlled_target")
	_assert(bool(external_control.get("available", false)), "valid external control binding was unavailable")
	_assert(not bool(external_control.get("local_control_available", true)), "external control incorrectly exposed local action")
	_assert(bool(external_control.get("remote_control_available", false)), "external control did not expose terminal action")
	_assert(str(external_control.get("resolved_controller_id", "")) == "terminal_a", "external controller id was not resolved")

	var missing_control: Dictionary = _control_result(ResolverRef.resolve_world([controlled_target]), "controlled_target")
	_assert(str(missing_control.get("reason_code", "")) == "control.binding_missing", "missing external control binding returned wrong code")

	var unpowered_terminal: Dictionary = _terminal("terminal_off", Vector2i(0, 0), false)
	var off_bindings: Array[Dictionary] = [_control_binding("control_off", "terminal_off", "controlled_target")]
	var off_control: Dictionary = _control_result(ResolverRef.resolve_world([unpowered_terminal, controlled_target], off_bindings), "controlled_target")
	_assert(str(off_control.get("reason_code", "")) == "control.controller_unpowered", "unpowered controller returned wrong code")

	var safe_off_target: Dictionary = controlled_target.duplicate(true)
	safe_off_target["control_loss_behavior"] = "safe_off"
	var loss_patch: Dictionary = ResolverRef.build_control_loss_patch(safe_off_target, {"available":false})
	_assert(str(Dictionary(loss_patch.get("patch", {})).get("intent_state", "")) == "off", "safe_off control loss patch did not turn intent off")
	var custom_target: Dictionary = controlled_target.duplicate(true)
	custom_target["control_loss_behavior"] = "custom"
	var custom_patch: Dictionary = ResolverRef.build_control_loss_patch(custom_target, {"available":false})
	_assert(bool(custom_patch.get("custom_handler_required", false)), "custom control loss did not request a handler")

	var scoped_objects: Array[Dictionary] = [
		_source("alpha_source", Vector2i(0, 0), "alpha"),
		_cable("alpha_cable", Vector2i(1, 0), "alpha"),
		_consumer("alpha_target", Vector2i(2, 0), "alpha"),
		_source("beta_source", Vector2i(0, 3), "beta"),
		_cable("beta_cable", Vector2i(1, 3), "beta"),
		_consumer("beta_target", Vector2i(2, 3), "beta")
	]
	scoped_objects[5]["power_state"] = "sentinel"
	var scoped_result: Dictionary = ResolverRef.apply_scoped_event(scoped_objects, [], {"event_type":"power.cable_changed", "network_id":"alpha"})
	_assert(Array(scoped_result.get("affected_entity_ids", [])).has("alpha_target"), "scoped event omitted affected alpha target")
	_assert(not Array(scoped_result.get("affected_entity_ids", [])).has("beta_target"), "scoped event included unrelated beta target")
	_assert(str(scoped_objects[5].get("power_state", "")) == "sentinel", "scoped event mutated unrelated network")

	if failures.is_empty():
		print("POWER_CONTROL_RESOLVER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("POWER_CONTROL_RESOLVER_GATE: FAIL: %s" % failure)
	quit(1)
