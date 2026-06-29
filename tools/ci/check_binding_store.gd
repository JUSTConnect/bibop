extends SceneTree

const StoreRef = preload("res://scripts/world/world_state_store.gd")
const ContractRef = preload("res://scripts/world/world_binding_store_contract.gd")
const MigrationServiceRef = preload("res://scripts/world/versioned_snapshot_migration_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _capabilities(enabled: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for capability in ["state", "power", "health", "energy", "overheat", "control", "access", "bindings", "mount", "side", "routing", "test_override"]:
		result[capability] = enabled.has(capability)
	return result

func _entity(object_id: String, cell: Vector2i, group: String, object_type: String, entity_type: String, capabilities: Array[String], extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"id": object_id,
		"position": cell,
		"object_group": group,
		"object_type": object_type,
		"entity_contract": {
			"entity_type": entity_type,
			"capabilities": _capabilities(capabilities)
		}
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result

func _binding(binding_id: String, role: String, source_id: String, target_id: String, parameters: Dictionary = {}) -> Dictionary:
	return {
		"id": binding_id,
		"role": role,
		"source_id": source_id,
		"target_id": target_id,
		"parameters": parameters.duplicate(true),
		"format_version": ContractRef.FORMAT_VERSION
	}

func _code(result: Dictionary) -> String:
	return str(result.get("code", result.get("reason_code", "")))

func _has_diagnostic(diagnostics: Array, binding_id: String, code: String) -> bool:
	for value in diagnostics:
		if not (value is Dictionary):
			continue
		var diagnostic: Dictionary = Dictionary(value)
		if str(diagnostic.get("binding_id", "")) == binding_id and _code(diagnostic) == code:
			return true
	return false

func _base_entities() -> Array[Dictionary]:
	return [
		_entity("terminal_a", Vector2i(0, 0), "terminal", "terminal", "object", ["state", "control", "bindings"]),
		_entity("terminal_b", Vector2i(1, 0), "terminal", "terminal", "object", ["state", "control", "bindings"]),
		_entity("door_a", Vector2i(2, 0), "door", "door", "object", ["state", "control", "access", "bindings"]),
		_entity("door_b", Vector2i(3, 0), "door", "door", "object", ["state", "control", "access", "bindings"]),
		_entity("key_a", Vector2i(4, 0), "item", "key_card", "item", ["state", "access", "bindings"]),
		_entity("light_a", Vector2i(5, 0), "lighting", "light", "light", ["state", "power", "bindings"]),
		_entity("source_a", Vector2i(6, 0), "power", "power_source_class_1", "object", ["state", "power"], {"generic_power_role":"power_source"}),
		_entity("consumer_a", Vector2i(7, 0), "machine", "machine", "object", ["state", "power", "bindings"]),
		_entity("platform_a", Vector2i(8, 0), "platform", "platform_controller", "object", ["state", "control", "bindings"]),
		_entity("platform_b", Vector2i(9, 0), "platform", "platform_controller", "object", ["state", "control", "bindings"]),
		_entity("cable_a", Vector2i(10, 0), "power", "power_cable", "cable", ["state", "bindings", "routing"]),
		_entity("reel_a", Vector2i(11, 0), "item", "power_cable_reel", "item", ["state", "routing"]),
		_entity("duct_a", Vector2i(12, 0), "cooling", "air_duct", "cooling_system", ["mount", "side", "routing"])
	]

func _run() -> void:
	await process_frame
	var store = StoreRef.new()
	var replaced: Dictionary = store.replace_snapshot(_base_entities())
	_assert(bool(replaced.get("ok", false)), "base snapshot rejected: %s" % str(replaced))

	var created: Dictionary = store.create_binding(_binding("control_1", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a", {"mode":"remote"}))
	_assert(bool(created.get("success", false)), "valid binding rejected: %s" % str(created))
	_assert(store.has_binding("control_1"), "created binding missing")
	_assert(store.get_bindings_by_source_id("terminal_a").size() == 1, "source reverse index missing")
	_assert(store.get_bindings_by_target_id("door_a").size() == 1, "target reverse index missing")
	_assert(store.get_bindings_by_role(ContractRef.ROLE_CONTROL_TERMINAL).size() == 1, "role reverse index missing")

	var copy: Dictionary = store.get_binding_by_id("control_1")
	copy["target_id"] = "door_b"
	var copied_parameters: Dictionary = Dictionary(copy.get("parameters", {}))
	copied_parameters["mode"] = "mutated"
	copy["parameters"] = copied_parameters
	_assert(str(store.get_binding_by_id("control_1").get("target_id", "")) == "door_a", "binding getter leaked mutable state")
	_assert(str(Dictionary(store.get_binding_by_id("control_1").get("parameters", {})).get("mode", "")) == "remote", "binding parameters leaked mutable state")

	_assert(_code(store.create_binding(_binding("control_2", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a"))) == "duplicate", "duplicate relation was accepted")
	_assert(_code(store.create_binding(_binding("control_1", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_b", "door_b"))) == "duplicate", "duplicate id was accepted")
	_assert(_code(store.create_binding(_binding("wrong_type", ContractRef.ROLE_ACCESS_ITEM, "terminal_b", "door_b"))) == "wrong_type", "wrong source type was accepted")
	_assert(_code(store.create_binding(_binding("control_capacity", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_b", "door_a"))) == "capacity_exceeded", "target cardinality was ignored")
	_assert(_code(store.create_binding(_binding("missing_direct", ContractRef.ROLE_CONTROL_TERMINAL, "missing_terminal", "door_b"))) == "source_missing", "direct create accepted missing endpoint")
	_assert(_code(store.create_binding(_binding("physical_role", "power_cable", "terminal_b", "door_b"))) == "physical_relation_forbidden", "physical role entered BindingStore")
	_assert(_code(store.create_binding(_binding("physical_parameter", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_b", "door_b", {"path_cells":[Vector2i(1, 1)]}))) == "physical_relation_forbidden", "physical path entered binding parameters")
	_assert(_code(store.create_binding(_binding("physical_object", ContractRef.ROLE_CONTROL_TERMINAL, "cable_a", "door_b"))) == "physical_relation_forbidden", "physical cable entered logical relation")

	var platform_first: Dictionary = store.create_binding(_binding("platform_1", ContractRef.ROLE_PLATFORM_CONTROLLER, "platform_a", "platform_b"))
	_assert(bool(platform_first.get("success", false)), "first platform relation rejected")
	_assert(_code(store.create_binding(_binding("platform_2", ContractRef.ROLE_PLATFORM_CONTROLLER, "platform_b", "platform_a"))) == "cycle", "binding cycle was accepted")

	var preferred: Dictionary = store.create_binding(_binding("preferred_1", ContractRef.ROLE_PREFERRED_POWER_SOURCE, "consumer_a", "source_a"))
	_assert(bool(preferred.get("success", false)), "preferred power source binding rejected")
	_assert(_code(store.create_binding(_binding("preferred_2", ContractRef.ROLE_PREFERRED_POWER_SOURCE, "consumer_a", "source_a", {"note":"duplicate"}))) == "duplicate", "preferred source duplicate accepted")

	var broken_store = StoreRef.new()
	var broken_load: Dictionary = broken_store.replace_snapshot(_base_entities(), [_binding("broken_1", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "missing_door")])
	_assert(bool(broken_load.get("ok", false)), "broken authoring binding was not preserved")
	_assert(broken_store.has_binding("broken_1"), "broken binding was discarded")
	_assert(_has_diagnostic(Array(broken_load.get("binding_diagnostics", [])), "broken_1", "target_missing"), "missing target diagnostic absent")
	_assert(_code(broken_store.get_binding_status("broken_1")) == "target_missing", "broken binding status changed")

	var deletion_store = StoreRef.new()
	deletion_store.replace_snapshot(_base_entities())
	deletion_store.create_binding(_binding("delete_preserve", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a"))
	_assert(bool(deletion_store.remove_object_by_id("terminal_a").get("ok", false)), "default preserve deletion failed")
	_assert(deletion_store.has_binding("delete_preserve"), "default deletion removed relation")
	_assert(_code(deletion_store.get_binding_status("delete_preserve")) == "source_missing", "preserved relation did not become source_missing")

	var reject_store = StoreRef.new()
	reject_store.replace_snapshot(_base_entities())
	reject_store.create_binding(_binding("delete_reject", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a"))
	_assert(_code(reject_store.remove_object_by_id("terminal_a", StoreRef.BINDING_POLICY_REJECT_IF_BOUND)) == "binding_cleanup_required", "reject-if-bound policy did not block deletion")
	_assert(reject_store.has_object("terminal_a"), "reject-if-bound removed endpoint")

	var cascade_store = StoreRef.new()
	cascade_store.replace_snapshot(_base_entities())
	cascade_store.create_binding(_binding("delete_related", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a"))
	_assert(bool(cascade_store.remove_object_by_id("terminal_a", StoreRef.BINDING_POLICY_REMOVE_RELATED).get("ok", false)), "remove-related deletion failed")
	_assert(not cascade_store.has_binding("delete_related"), "remove-related left relation behind")

	var serial_store = StoreRef.new()
	serial_store.replace_snapshot(_base_entities())
	serial_store.create_binding(_binding("z_binding", ContractRef.ROLE_ACCESS_ITEM, "key_a", "door_a"))
	serial_store.create_binding(_binding("a_binding", ContractRef.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a"))
	var snapshot: Dictionary = serial_store.get_serializable_snapshot()
	_assert(int(snapshot.get("format_version", 0)) == StoreRef.WORLD_SNAPSHOT_FORMAT_VERSION, "store did not write current format")
	_assert(snapshot.has("entities") and snapshot.has("bindings"), "bindings are not a separate serialized collection")
	var serialized_bindings: Array = Array(snapshot.get("bindings", []))
	_assert(serialized_bindings.size() == 2, "serialized binding count mismatch")
	_assert(str(Dictionary(serialized_bindings[0]).get("id", "")) == "a_binding", "serialization order is not deterministic")
	var roundtrip_store = StoreRef.new()
	var roundtrip: Dictionary = roundtrip_store.replace_serialized_snapshot(snapshot)
	_assert(bool(roundtrip.get("ok", false)), "serialized roundtrip failed: %s" % str(roundtrip))
	_assert(roundtrip_store.get_all_bindings().size() == 2, "roundtrip duplicated or lost bindings")
	_assert(roundtrip_store.validate_consistency().is_empty(), "roundtrip consistency warnings")

	var store_before_legacy: String = var_to_str(roundtrip_store.get_serializable_snapshot())
	var direct_legacy: Dictionary = roundtrip_store.replace_serialized_snapshot({"format_version":0, "objects":[]})
	_assert(_code(direct_legacy) == "invalid_format_version", "strict store accepted legacy format")
	_assert(var_to_str(roundtrip_store.get_serializable_snapshot()) == store_before_legacy, "rejected legacy load mutated store")

	var legacy_entities: Array[Dictionary] = [
		_entity("legacy_terminal", Vector2i(0, 1), "terminal", "terminal", "object", ["state", "control", "bindings"]),
		_entity("legacy_door", Vector2i(1, 1), "door", "door", "object", ["state", "control", "access", "bindings"], {"control_terminal_id":"legacy_terminal"}),
		_entity("legacy_reel", Vector2i(2, 1), "item", "power_cable_reel", "item", ["state", "routing"], {"end_1_state":"connected", "end_1_target_id":"legacy_terminal", "end_2_state":"connected", "end_2_target_id":"legacy_door", "cable_path_cells":[Vector2i(0, 1)]}),
		_entity("legacy_duct", Vector2i(3, 1), "cooling", "external_air_duct", "cooling_system", ["mount", "side", "routing"], {"wall_side":"SW", "wall_side_1":"NW", "wall_side_2":"SE", "cooling_contour_member_ids":["legacy_door"]})
	]
	var migration: Dictionary = MigrationServiceRef.migrate_document({"format_version":0, "objects":legacy_entities, "bindings":[]})
	_assert(bool(migration.get("success", false)), "versioned legacy migration failed: %s" % str(migration))
	var migration_store = StoreRef.new()
	var migration_load: Dictionary = migration_store.replace_serialized_snapshot(Dictionary(migration.get("snapshot", {})))
	_assert(bool(migration_load.get("ok", false)), "strict store rejected migrated v2 snapshot")
	_assert(migration_store.get_all_bindings().size() == 1, "physical topology was migrated as logical binding")
	_assert(str(migration_store.get_all_bindings()[0].get("role", "")) == ContractRef.ROLE_CONTROL_TERMINAL, "wrong legacy role migrated")

	var result_shape: Dictionary = store.get_binding_status("control_1")
	for field_name in ["success", "code", "reason_code", "binding_id", "source_id", "target_id", "role", "details"]:
		_assert(result_shape.has(field_name), "binding result missing field %s" % field_name)

	await process_frame
	if failures.is_empty():
		print("BINDING_STORE_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("BINDING_STORE_GATE: FAIL: %s" % failure)
	quit(1)
