extends SceneTree

const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")

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

func _entity(object_id: String, cell: Vector2i, group: String, object_type: String, capabilities: Array[String], extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"id": object_id,
		"position": cell,
		"object_group": group,
		"object_type": object_type,
		"entity_contract": {
			"entity_type": "object",
			"capabilities": _capabilities(capabilities)
		}
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result

func _find_entity(snapshot: Dictionary, object_id: String) -> Dictionary:
	for value in Array(snapshot.get("entities", [])):
		if value is Dictionary and str(Dictionary(value).get("id", "")) == object_id:
			return Dictionary(value)
	return {}

func _run() -> void:
	await process_frame
	var manager = MissionManagerRef.new()
	root.add_child(manager)
	var legacy_objects: Array[Dictionary] = [
		_entity("legacy_terminal", Vector2i(0, 0), "terminal", "terminal", ["state", "control", "bindings"]),
		_entity("legacy_door", Vector2i(1, 0), "door", "door", ["state", "control", "access", "bindings"], {"control_terminal_id": "legacy_terminal"})
	]
	var legacy_result: Dictionary = manager.replace_world_state_snapshot(legacy_objects)
	_assert(bool(legacy_result.get("ok", false)), "legacy MissionManager snapshot rejected: %s" % str(legacy_result))
	_assert(manager.world_state_store.get_all_bindings().size() == 1, "legacy MissionManager wrapper did not migrate logical relation")
	var canonical_snapshot: Dictionary = manager.get_world_state_serializable_snapshot()
	_assert(int(canonical_snapshot.get("format_version", 0)) == 1, "canonical snapshot version missing")
	_assert(Array(canonical_snapshot.get("bindings", [])).size() == 1, "canonical snapshot lost migrated binding")
	var serialized_door: Dictionary = _find_entity(canonical_snapshot, "legacy_door")
	_assert(not serialized_door.has("control_terminal_id"), "legacy logical field remained in canonical entity serialization")

	var restored_manager = MissionManagerRef.new()
	root.add_child(restored_manager)
	var canonical_result: Dictionary = restored_manager.replace_world_state_serialized_snapshot(canonical_snapshot)
	_assert(bool(canonical_result.get("ok", false)), "canonical MissionManager snapshot rejected: %s" % str(canonical_result))
	_assert(restored_manager.world_state_store.get_all_bindings().size() == 1, "canonical MissionManager roundtrip lost binding")
	_assert(restored_manager.world_state_store.validate_consistency().is_empty(), "MissionManager roundtrip consistency warnings: %s" % str(restored_manager.world_state_store.validate_consistency()))

	var malformed_result: Dictionary = restored_manager.replace_world_state_serialized_snapshot({"format_version": 1, "entities": "invalid", "bindings": []})
	_assert(str(malformed_result.get("code", "")) == "missing", "malformed canonical snapshot did not return machine-readable missing code")

	manager.queue_free()
	restored_manager.queue_free()
	await process_frame
	if failures.is_empty():
		print("BINDING_STORE_MISSION_MANAGER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("BINDING_STORE_MISSION_MANAGER_GATE: FAIL: %s" % failure)
	quit(1)
