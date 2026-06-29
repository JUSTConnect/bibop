extends SceneTree

const MigrationService = preload("res://scripts/world/versioned_snapshot_migration_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _entity_by_id(snapshot: Dictionary, entity_id: String) -> Dictionary:
	for value in Array(snapshot.get("entities", [])):
		if value is Dictionary and str(Dictionary(value).get("id", "")) == entity_id:
			return Dictionary(value)
	return {}

func _bindings_for(snapshot: Dictionary, role: String, source_id: String, target_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in Array(snapshot.get("bindings", [])):
		if not value is Dictionary:
			continue
		var binding: Dictionary = Dictionary(value)
		if str(binding.get("role", "")) == role and str(binding.get("source_id", "")) == source_id and str(binding.get("target_id", "")) == target_id:
			result.append(binding)
	return result

func _issue_codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for value in Array(result.get("issues", [])):
		if value is Dictionary:
			var code: String = str(Dictionary(value).get("code", ""))
			if not codes.has(code):
				codes.append(code)
	return codes

func _legacy_document() -> Dictionary:
	return {
		"format_version": 0,
		"objects": [
			{"id":"terminal_a", "position":Vector2i(0, 0), "object_group":"terminal", "object_type":"terminal", "state":"active"},
			{"id":"door_a", "position":Vector2i(1, 0), "object_group":"door", "object_type":"door", "control_terminal_id":"terminal_a", "required_key_id":"key_a", "state":"closed"},
			{"id":"key_a", "position":Vector2i(2, 0), "object_group":"item", "object_type":"key_card", "item_type":"key_card"},
			{"id":"source_a", "position":Vector2i(0, 2), "object_group":"power", "object_type":"power_source_class_1", "state":"on"},
			{"id":"socket_a", "position":Vector2i(1, 2), "object_group":"power", "object_type":"power_socket", "preferred_source_id":"source_a", "power_source_id":"source_a", "resolved_source_id":"source_a"},
			{"id":"reel_a", "position":Vector2i(2, 2), "object_group":"item", "object_type":"power_cable_reel", "end_1_state":"connected", "end_1_target_id":"socket_a", "end_2_state":"held", "end_2_target_id":"", "cable_path_cells":[Vector2i(1, 2), Vector2i(2, 2)], "connection_state":"partial"},
			{"id":"parts_world", "position":Vector2i(3, 2), "object_group":"item", "object_type":"parts_medium", "item_type":"parts_medium", "amount":10},
			{"id":"heavy_crate_a", "position":Vector2i(3, 0), "object_group":"physical_object", "object_type":"heavy_crate", "weight_class":"heavy", "required_bipob_power_class":"engineer", "heavy_claw_movable":true},
			{"id":"duct_a", "position":Vector2i(4, 0), "object_group":"cooling", "object_type":"external_air_duct", "wall_side":"SW", "wall_side_1":"NW", "wall_side_2":"SE", "cooling_contour_id":"manual", "cooling_contour_member_ids":["duct_a"], "state":"active", "durability":5}
		],
		"bindings": [
			{"id":"duplicate_control_a", "role":"control_terminal", "source_id":"terminal_a", "target_id":"door_a", "parameters":{}},
			{"id":"physical_reel_binding", "role":"runtime_power_feed", "source_id":"reel_a", "target_id":"socket_a", "parameters":{"path_cells":[Vector2i(1, 2)]}}
		],
		"runtime_inventory_state": {
			"pocket_items":["parts_stack", "repair_kit_a"],
			"manipulator_hold":"",
			"box_storage":[],
			"item_amounts":{"parts_stack":5},
			"world_item_runtime":{
				"parts_stack":{"in_inventory":true, "item_data":{"id":"parts_stack", "item_type":"parts"}},
				"repair_kit_a":{"in_inventory":true, "item_data":{"id":"repair_kit_a", "item_type":"repair_kit"}}
			},
			"consumed_item_ids":[]
		},
		"center_storage":{"parts":7, "items":[]}
	}

func _run() -> void:
	await process_frame
	var source: Dictionary = _legacy_document()
	var source_before: String = var_to_str(source)
	var migrated: Dictionary = MigrationService.migrate_document(source)
	_assert(bool(migrated.get("success", false)), "v0 migration failed: %s" % str(migrated))
	_assert(var_to_str(source) == source_before, "migration mutated source document")
	_assert(str(migrated.get("code", "")) == MigrationService.CODE_MIGRATED, "migration result code mismatch")
	_assert(int(migrated.get("source_format_version", -1)) == 0, "source version missing")
	_assert(int(migrated.get("target_format_version", -1)) == MigrationService.CURRENT_FORMAT_VERSION, "target version missing")
	_assert(Array(migrated.get("applied_steps", [])) == [MigrationService.STEP_V0_TO_V1, MigrationService.STEP_V1_TO_V2], "migration steps are not sequential")

	var snapshot: Dictionary = Dictionary(migrated.get("snapshot", {}))
	_assert(int(snapshot.get("format_version", 0)) == MigrationService.CURRENT_FORMAT_VERSION, "canonical format version missing")
	_assert(not snapshot.has("objects") and not snapshot.has("runtime_inventory_state"), "legacy envelope fields remained")
	_assert(Array(snapshot.get("entities", [])).size() == 9, "entity count changed")

	var door: Dictionary = _entity_by_id(snapshot, "door_a")
	_assert(not door.has("control_terminal_id") and not door.has("required_key_id"), "legacy door links remained")
	_assert(_bindings_for(snapshot, BindingContract.ROLE_CONTROL_TERMINAL, "terminal_a", "door_a").size() == 1, "control binding missing or duplicated")
	_assert(_bindings_for(snapshot, BindingContract.ROLE_ACCESS_ITEM, "key_a", "door_a").size() == 1, "access-item binding missing")
	_assert(_bindings_for(snapshot, BindingContract.ROLE_PREFERRED_POWER_SOURCE, "socket_a", "source_a").size() == 1, "preferred-source binding missing")
	for binding_value in Array(snapshot.get("bindings", [])):
		if binding_value is Dictionary:
			_assert(not BindingContract.PHYSICAL_RELATION_ROLES.has(str(Dictionary(binding_value).get("role", ""))), "physical relation survived in BindingStore")
	_assert(_issue_codes(migrated).has(MigrationService.CODE_BINDING_PHYSICAL_REMOVED), "physical binding removal issue missing")

	var socket: Dictionary = _entity_by_id(snapshot, "socket_a")
	_assert(not socket.has("preferred_source_id") and not socket.has("power_source_id") and not socket.has("resolved_source_id"), "legacy or derived power-source fields remained")
	var reel: Dictionary = _entity_by_id(snapshot, "reel_a")
	_assert(reel.get("end_1", {}) is Dictionary and reel.get("end_2", {}) is Dictionary, "reel nested endpoints missing")
	_assert(Array(reel.get("path_cells", [])).size() == 2, "reel path was not migrated")
	for field_name in ["end_1_state", "end_1_target_id", "end_2_state", "end_2_target_id", "cable_path_cells"]:
		_assert(not reel.has(field_name), "legacy reel alias remained: %s" % field_name)

	var world_parts: Dictionary = _entity_by_id(snapshot, "parts_world")
	_assert(str(world_parts.get("object_type", "")) == "details_pickup" and int(world_parts.get("amount", 0)) == 10, "world parts pickup was not migrated")
	var details: Dictionary = Dictionary(snapshot.get("details_currency", {}))
	_assert(int(details.get("balance", 0)) == 12, "inventory and center Details total changed")
	var inventory: Dictionary = Dictionary(snapshot.get("inventory_state", {}))
	_assert(not inventory.has("item_amounts"), "legacy inventory amount map remained")
	_assert(not Array(inventory.get("pocket_items", [])).has("parts_stack"), "legacy parts remained in pocket")
	_assert(Array(inventory.get("pocket_items", [])).has("repair_kit_a"), "normal inventory item was lost")
	_assert(not Dictionary(snapshot.get("center_storage", {})).has("parts"), "center parts balance remained")

	var crate: Dictionary = _entity_by_id(snapshot, "heavy_crate_a")
	_assert(str(crate.get("weight_class", "")) == "heavy", "crate weight class changed")
	_assert(crate.get("movement_requirement", {}) is Dictionary, "crate movement requirement missing")
	_assert(not crate.has("required_bipob_power_class") and not crate.has("heavy_claw_movable"), "legacy crate requirements remained")
	var duct: Dictionary = _entity_by_id(snapshot, "duct_a")
	_assert(str(duct.get("object_type", "")) == "air_duct", "passive route subtype was not canonicalized")
	_assert(str(duct.get("route_shape", "")) == "straight", "passive route geometry missing")
	for field_name in ["wall_side_1", "wall_side_2", "cooling_contour_id", "cooling_contour_member_ids", "state", "durability"]:
		_assert(not duct.has(field_name), "legacy passive-route field remained: %s" % field_name)

	var second: Dictionary = MigrationService.migrate_document(snapshot)
	_assert(bool(second.get("success", false)), "current snapshot validation failed")
	_assert(str(second.get("code", "")) == MigrationService.CODE_ALREADY_CURRENT, "current snapshot was remigrated")
	_assert(not bool(second.get("migrated", true)), "current snapshot marked migrated")
	_assert(Array(second.get("applied_steps", [])).is_empty(), "current snapshot applied migration steps")
	_assert(var_to_str(Dictionary(second.get("snapshot", {}))) == var_to_str(snapshot), "second migration changed canonical snapshot")

	var version_one: Dictionary = source.duplicate(true)
	version_one["format_version"] = 1
	version_one["entities"] = Array(version_one.get("objects", [])).duplicate(true)
	version_one.erase("objects")
	var migrated_v1: Dictionary = MigrationService.migrate_document(version_one)
	_assert(bool(migrated_v1.get("success", false)), "v1 migration failed")
	_assert(Array(migrated_v1.get("applied_steps", [])) == [MigrationService.STEP_V1_TO_V2], "v1 applied wrong steps")

	var newer: Dictionary = {"format_version":MigrationService.CURRENT_FORMAT_VERSION + 1, "entities":[], "bindings":[]}
	var newer_before: String = var_to_str(newer)
	var newer_result: Dictionary = MigrationService.migrate_document(newer)
	_assert(not bool(newer_result.get("success", true)), "newer format accepted")
	_assert(str(newer_result.get("code", "")) == MigrationService.CODE_UNSUPPORTED_NEWER_VERSION, "newer-format code mismatch")
	_assert(var_to_str(newer) == newer_before, "newer snapshot was mutated")

	var malformed: Dictionary = {"format_version":0, "objects":["bad"], "bindings":[]}
	var malformed_result: Dictionary = MigrationService.migrate_document(malformed)
	_assert(not bool(malformed_result.get("success", true)), "malformed entity row accepted")
	_assert(_issue_codes(malformed_result).has(MigrationService.CODE_ENTITY_NOT_DICTIONARY), "malformed entity issue missing")

	var unknown_binding: Dictionary = _legacy_document()
	unknown_binding["bindings"] = [{"id":"unknown", "role":"mystery_role", "source_id":"terminal_a", "target_id":"door_a", "parameters":{}}]
	var unknown_result: Dictionary = MigrationService.migrate_document(unknown_binding)
	_assert(bool(unknown_result.get("success", false)), "recoverable unknown binding blocked migration")
	_assert(bool(unknown_result.get("task_test_allowed", false)), "recoverable migration blocked TASK TEST")
	_assert(not bool(unknown_result.get("promotion_allowed", true)), "unknown binding did not block promotion")
	_assert(_issue_codes(unknown_result).has(MigrationService.CODE_BINDING_UNSUPPORTED_REMOVED), "unknown binding issue missing")

	await process_frame
	if failures.is_empty():
		print("VERSIONED_SNAPSHOT_MIGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("VERSIONED_SNAPSHOT_MIGRATION_GATE: FAIL: %s" % failure)
	quit(1)
