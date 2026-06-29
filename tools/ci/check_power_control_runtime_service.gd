extends SceneTree

const StoreRef = preload("res://scripts/world/world_state_store.gd")
const RuntimeRef = preload("res://scripts/world/power_control_runtime_service.gd")
const BindingContractRef = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _contract(entity_type: String, capabilities: Array[String]) -> Dictionary:
	var capability_map: Dictionary = {}
	for name in ["state", "power", "health", "energy", "overheat", "control", "access", "bindings", "mount", "side", "routing", "test_override"]:
		capability_map[name] = capabilities.has(name)
	return {"entity_type":entity_type, "capabilities":capability_map}

func _source(id: String, cell: Vector2i, circuit: String) -> Dictionary:
	return {
		"id":id, "position":cell, "object_group":"power", "object_type":"power_source_class_1",
		"generic_power_role":"power_source", "power_mode":"internal", "control_mode":"internal",
		"power_network_id":circuit, "intent_state":"on", "health_state":"healthy", "thermal_state":"normal",
		"operational_state":"active", "entity_contract":_contract("object", ["state", "power", "health", "overheat", "control", "bindings"])
	}

func _cable(id: String, cell: Vector2i, circuit: String) -> Dictionary:
	return {
		"id":id, "position":cell, "object_group":"cable", "object_type":"power_cable",
		"power_network_id":circuit, "health_state":"healthy", "operational_state":"connected", "connected":true,
		"entity_contract":_contract("cable", ["state", "routing"])
	}

func _target(id: String, cell: Vector2i, circuit: String, control_mode: String = "none") -> Dictionary:
	return {
		"id":id, "position":cell, "object_group":"machine", "object_type":"machine",
		"power_mode":"external", "control_mode":control_mode, "control_loss_behavior":"safe_off",
		"power_network_id":circuit, "intent_state":"on", "health_state":"healthy", "thermal_state":"normal",
		"operational_state":"active", "entity_contract":_contract("object", ["state", "power", "health", "overheat", "control", "bindings"])
	}

func _terminal(id: String, cell: Vector2i) -> Dictionary:
	return {
		"id":id, "position":cell, "object_group":"terminal", "object_type":"control_terminal",
		"power_mode":"internal", "control_mode":"internal", "intent_state":"on", "health_state":"healthy",
		"thermal_state":"normal", "operational_state":"active",
		"entity_contract":_contract("object", ["state", "power", "health", "overheat", "control", "bindings"])
	}

func _run() -> void:
	await process_frame
	var store = StoreRef.new()
	var objects: Array[Dictionary] = [
		_source("source_alpha", Vector2i(0, 0), "alpha"),
		_cable("cable_alpha", Vector2i(1, 0), "alpha"),
		_target("target_alpha", Vector2i(2, 0), "alpha", "external"),
		_terminal("terminal_alpha", Vector2i(4, 0)),
		_source("source_beta", Vector2i(0, 3), "beta"),
		_cable("cable_beta", Vector2i(1, 3), "beta"),
		_target("target_beta", Vector2i(2, 3), "beta")
	]
	var loaded: Dictionary = store.replace_snapshot(objects)
	_assert(bool(loaded.get("ok", false)), "runtime fixture failed to load: %s" % str(loaded))
	var control_binding: Dictionary = store.create_binding({
		"id":"control_alpha", "role":BindingContractRef.ROLE_CONTROL_TERMINAL,
		"source_id":"terminal_alpha", "target_id":"target_alpha", "parameters":{},
		"format_version":BindingContractRef.FORMAT_VERSION
	})
	_assert(bool(control_binding.get("success", false)), "control binding rejected: %s" % str(control_binding))

	var before_preview: String = var_to_str(store.get_serializable_snapshot())
	var preview: Dictionary = RuntimeRef.preview(store, {"network_id":"alpha"})
	_assert(bool(preview.get("success", false)), "runtime preview failed")
	_assert(var_to_str(store.get_serializable_snapshot()) == before_preview, "runtime preview mutated WorldStateStore")
	var preview_control: Dictionary = Dictionary(Dictionary(preview.get("control_results", {})).get("target_alpha", {}))
	_assert(bool(preview_control.get("available", false)), "runtime preview did not resolve canonical control binding")

	store.update_object_state("target_beta", {"power_state":"sentinel"})
	var applied: Dictionary = RuntimeRef.apply_event(store, {"event_type":"power.cable_connected", "network_id":"alpha"})
	_assert(bool(applied.get("success", false)), "runtime apply failed: %s" % str(applied))
	var alpha_target: Dictionary = store.get_object_by_id("target_alpha")
	var beta_target: Dictionary = store.get_object_by_id("target_beta")
	_assert(str(alpha_target.get("power_state", "")) == "powered", "runtime apply did not power alpha target")
	_assert(str(alpha_target.get("resolved_source_id", "")) == "source_alpha", "runtime apply resolved wrong alpha source")
	_assert(str(beta_target.get("power_state", "")) == "sentinel", "runtime apply mutated unrelated beta network")
	_assert(Array(applied.get("affected_entity_ids", [])).has("target_alpha"), "runtime apply omitted affected target")
	_assert(not Array(applied.get("affected_entity_ids", [])).has("target_beta"), "runtime apply included unrelated target")

	var removed: Dictionary = store.remove_object_by_id("terminal_alpha")
	_assert(bool(removed.get("ok", false)), "terminal removal failed")
	var missing_control: Dictionary = RuntimeRef.resolve_entity_control(store, "target_alpha")
	_assert(str(missing_control.get("reason_code", "")) == "control.controller_missing", "preserved broken binding returned wrong control code")
	var loss_result: Dictionary = RuntimeRef.apply_control_loss(store, "target_alpha")
	_assert(bool(loss_result.get("success", false)), "control loss application failed")
	_assert(str(store.get_object_by_id("target_alpha").get("intent_state", "")) == "off", "safe_off control loss behavior was not committed")

	if failures.is_empty():
		print("POWER_CONTROL_RUNTIME_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("POWER_CONTROL_RUNTIME_GATE: FAIL: %s" % failure)
	quit(1)
