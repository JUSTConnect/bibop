extends SceneTree

const PresetService = preload("res://scripts/game/map_constructor_preset_service.gd")
const MigrationService = preload("res://scripts/world/versioned_snapshot_migration_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

class FakeOwner:
	extends Node
	var constructor_map_width: int = 12
	var constructor_map_height: int = 8
	var constructor_start_marker: Dictionary = {}
	var constructor_exit_marker: Dictionary = {}
	var _task_test_constructor_base_tiles: Dictionary = {}
	var _map_constructor_wall_material_overrides: Dictionary = {}
	var _map_constructor_floor_material_overrides: Dictionary = {}
	var map_constructor_door_visual_preset_overrides: Dictionary = {}
	var map_constructor_terminal_visual_preset_overrides: Dictionary = {}
	var current_mission_id: String = "task_test"
	var applied_world: Dictionary = {}
	func get_world_state_serializable_snapshot() -> Dictionary:
		return {"format_version":MigrationService.CURRENT_FORMAT_VERSION, "entities":[], "bindings":[], "details_currency":{}, "inventory_state":{}, "center_storage":{}}
	func replace_world_state_serialized_snapshot(snapshot: Dictionary) -> Dictionary:
		applied_world = snapshot.duplicate(true)
		return {"ok":true, "success":true}
	func normalize_map_constructor_surface_override_snapshot(snapshot: Dictionary) -> Dictionary:
		return snapshot.duplicate(true)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _has_control_binding(snapshot: Dictionary) -> bool:
	for value in Array(snapshot.get("bindings", [])):
		if value is Dictionary:
			var row: Dictionary = Dictionary(value)
			if str(row.get("role", "")) == BindingContract.ROLE_CONTROL_TERMINAL and str(row.get("source_id", "")) == "terminal" and str(row.get("target_id", "")) == "door":
				return true
	return false

func _run() -> void:
	await process_frame
	var legacy: Dictionary = {"schema_version":1, "preset_id":"legacy", "snapshot":{"mission_world_objects":[{"id":"terminal", "position":Vector2i.ZERO, "object_group":"terminal", "object_type":"terminal"}, {"id":"door", "position":Vector2i(1, 0), "object_group":"door", "object_type":"door", "control_terminal_id":"terminal"}], "cell_items":{}, "world_objects_by_cell":{}, "constructor_map_width":10, "constructor_map_height":6}}
	var before: String = var_to_str(legacy)
	var migrated: Dictionary = PresetService.migrate_preset_document(legacy)
	_assert(bool(migrated.get("success", false)), "legacy preset migration failed")
	_assert(var_to_str(legacy) == before, "preset migration mutated source")
	var snapshot: Dictionary = Dictionary(migrated.get("snapshot", {}))
	_assert(int(Dictionary(migrated.get("document", {})).get("schema_version", 0)) == PresetService.SCHEMA_VERSION, "preset schema not upgraded")
	_assert(snapshot.has(PresetService.WORLD_SNAPSHOT_FIELD), "canonical world snapshot missing")
	for field_name in ["mission_world_objects", "cell_items", "world_objects_by_cell"]:
		_assert(not snapshot.has(field_name), "legacy preset field remained: %s" % field_name)
	var world: Dictionary = Dictionary(snapshot.get(PresetService.WORLD_SNAPSHOT_FIELD, {}))
	_assert(int(world.get("format_version", 0)) == MigrationService.CURRENT_FORMAT_VERSION, "world format not current")
	_assert(_has_control_binding(world), "preset migration lost logical binding")

	var owner = FakeOwner.new()
	root.add_child(owner)
	var apply_result: Dictionary = PresetService.apply_snapshot_to_owner(owner, snapshot)
	_assert(bool(apply_result.get("success", false)), "canonical preset apply failed")
	_assert(owner.constructor_map_width == 10 and owner.constructor_map_height == 6, "constructor fields not applied")
	_assert(int(owner.applied_world.get("format_version", 0)) == MigrationService.CURRENT_FORMAT_VERSION, "owner received noncanonical world")
	var new_snapshot: Dictionary = PresetService.snapshot_from_owner(owner)
	_assert(new_snapshot.has(PresetService.WORLD_SNAPSHOT_FIELD), "new preset snapshot lacks world document")
	_assert(not new_snapshot.has("mission_world_objects"), "new preset wrote legacy world objects")

	var current_document: Dictionary = Dictionary(migrated.get("document", {})).duplicate(true)
	current_document["snapshot"] = snapshot.duplicate(true)
	var second: Dictionary = PresetService.migrate_preset_document(current_document)
	_assert(str(second.get("code", "")) == PresetService.CODE_ALREADY_CURRENT, "current preset remigrated")
	_assert(var_to_str(Dictionary(second.get("snapshot", {}))) == var_to_str(snapshot), "current preset changed")
	var newer: Dictionary = {"schema_version":PresetService.SCHEMA_VERSION + 1, "preset_id":"newer", "snapshot":{}}
	_assert(str(PresetService.migrate_preset_document(newer).get("code", "")) == PresetService.CODE_UNSUPPORTED_SCHEMA_VERSION, "newer preset schema accepted")

	owner.queue_free()
	await process_frame
	if failures.is_empty():
		print("VERSIONED_MAP_CONSTRUCTOR_PRESET_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("VERSIONED_MAP_CONSTRUCTOR_PRESET_GATE: FAIL: %s" % failure)
	quit(1)
