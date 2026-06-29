extends SceneTree

const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")
const MigrationService = preload("res://scripts/world/versioned_snapshot_migration_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _legacy_document() -> Dictionary:
	return {
		"format_version": 0,
		"objects": [
			{"id":"terminal", "position":Vector2i(0, 0), "object_group":"terminal", "object_type":"terminal", "state":"active"},
			{"id":"door", "position":Vector2i(1, 0), "object_group":"door", "object_type":"door", "control_terminal_id":"terminal", "state":"closed"},
			{"id":"parts_pickup", "position":Vector2i(2, 0), "object_group":"item", "object_type":"parts_small", "item_type":"parts_small", "amount":5}
		],
		"bindings": [],
		"runtime_inventory_state": {
			"pocket_items":["parts_stack"],
			"manipulator_hold":"",
			"box_storage":[],
			"item_amounts":{"parts_stack":4},
			"world_item_runtime":{"parts_stack":{"in_inventory":true, "item_data":{"id":"parts_stack", "item_type":"parts"}}},
			"consumed_item_ids":[]
		},
		"center_storage":{"parts":3, "items":[]}
	}

func _has_binding(snapshot: Dictionary, role: String, source_id: String, target_id: String) -> bool:
	for value in Array(snapshot.get("bindings", [])):
		if not value is Dictionary:
			continue
		var binding: Dictionary = Dictionary(value)
		if str(binding.get("role", "")) == role and str(binding.get("source_id", "")) == source_id and str(binding.get("target_id", "")) == target_id:
			return true
	return false

func _run() -> void:
	await process_frame
	var manager = MissionManagerRef.new()
	root.add_child(manager)
	var legacy: Dictionary = _legacy_document()
	var legacy_before: String = var_to_str(legacy)
	var load_result: Dictionary = manager.replace_world_state_serialized_snapshot(legacy)
	_assert(bool(load_result.get("success", false)), "legacy load failed: %s" % str(load_result))
	_assert(bool(load_result.get("migrated", false)), "legacy load did not report migration")
	_assert(int(load_result.get("source_format_version", -1)) == 0, "source version missing from load result")
	_assert(int(load_result.get("target_format_version", -1)) == MigrationService.CURRENT_FORMAT_VERSION, "target version missing from load result")
	_assert(var_to_str(legacy) == legacy_before, "MissionManager load mutated source document")
	_assert(manager.world_state_store.get_all_objects().size() == 3, "migrated world object count mismatch")
	_assert(manager.world_state_store.get_all_bindings().size() == 1, "legacy logical binding was not restored")
	_assert(manager.get_details_balance() == 7, "legacy inventory and center Details sum changed")
	_assert(not manager.get_inventory_state().has("item_amounts"), "legacy item amount map reached live inventory")

	var canonical: Dictionary = manager.get_world_state_serializable_snapshot()
	_assert(int(canonical.get("format_version", 0)) == MigrationService.CURRENT_FORMAT_VERSION, "save did not write current format")
	_assert(not canonical.has("objects") and not canonical.has("runtime_inventory_state"), "save contains legacy envelope fields")
	_assert(_has_binding(canonical, BindingContract.ROLE_CONTROL_TERMINAL, "terminal", "door"), "save lost migrated binding")
	_assert(int(Dictionary(canonical.get("details_currency", {})).get("balance", 0)) == 7, "save lost Details balance")

	var restored = MissionManagerRef.new()
	root.add_child(restored)
	var restore_result: Dictionary = restored.replace_world_state_serialized_snapshot(canonical)
	_assert(bool(restore_result.get("success", false)), "canonical reload failed: %s" % str(restore_result))
	_assert(not bool(restore_result.get("migrated", true)), "canonical reload reported migration")
	_assert(restored.world_state_store.get_all_bindings().size() == 1, "canonical reload lost binding")
	_assert(restored.get_details_balance() == 7, "canonical reload lost Details")
	_assert(var_to_str(restored.get_world_state_serializable_snapshot()) == var_to_str(canonical), "canonical roundtrip changed document")

	var stable_before: String = var_to_str(restored.get_world_state_serializable_snapshot())
	var malformed: Dictionary = {"format_version":MigrationService.CURRENT_FORMAT_VERSION, "entities":"bad", "bindings":[], "details_currency":{}}
	var malformed_result: Dictionary = restored.replace_world_state_serialized_snapshot(malformed)
	_assert(not bool(malformed_result.get("success", true)), "malformed current document loaded")
	_assert(str(malformed_result.get("code", "")) == MigrationService.CODE_INVALID_DOCUMENT, "malformed load code mismatch")
	_assert(var_to_str(restored.get_world_state_serializable_snapshot()) == stable_before, "failed load mutated live state")

	var newer: Dictionary = {"format_version":MigrationService.CURRENT_FORMAT_VERSION + 1, "entities":[], "bindings":[]}
	var newer_result: Dictionary = restored.replace_world_state_serialized_snapshot(newer)
	_assert(str(newer_result.get("code", "")) == MigrationService.CODE_UNSUPPORTED_NEWER_VERSION, "newer format was not rejected")
	_assert(var_to_str(restored.get_world_state_serializable_snapshot()) == stable_before, "newer-format rejection mutated live state")

	var recoverable: Dictionary = _legacy_document()
	recoverable["bindings"] = [{"id":"unknown_binding", "role":"unknown_role", "source_id":"terminal", "target_id":"door", "parameters":{}}]
	var recoverable_result: Dictionary = restored.replace_world_state_serialized_snapshot(recoverable)
	_assert(bool(recoverable_result.get("success", false)), "recoverable migration did not load")
	_assert(bool(recoverable_result.get("draft_save_allowed", false)), "recoverable migration blocked draft save")
	_assert(bool(recoverable_result.get("task_test_allowed", false)), "recoverable migration blocked TASK TEST")
	_assert(not bool(recoverable_result.get("promotion_allowed", true)), "recoverable migration did not block promotion")

	manager.queue_free()
	restored.queue_free()
	await process_frame
	if failures.is_empty():
		print("VERSIONED_SNAPSHOT_MIGRATION_MISSION_MANAGER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("VERSIONED_SNAPSHOT_MIGRATION_MISSION_MANAGER_GATE: FAIL: %s" % failure)
	quit(1)
