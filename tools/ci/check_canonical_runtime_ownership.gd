extends SceneTree

const StoreRef = preload("res://scripts/world/world_state_store.gd")
const MigrationRef = preload("res://scripts/world/versioned_snapshot_migration_service.gd")
const ReelRef = preload("res://scripts/game/power_cable_reel_service.gd")
const BindingContractRef = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _has_flat_reel_alias(reel: Dictionary) -> bool:
	for field_name in ["end_1_state", "end_1_target_id", "end_2_state", "end_2_target_id", "cable_path_cells"]:
		if reel.has(field_name):
			return true
	return false

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
	var store = StoreRef.new()
	var canonical: Dictionary = {
		"format_version":StoreRef.WORLD_SNAPSHOT_FORMAT_VERSION,
		"entities":[
			{"id":"terminal", "position":Vector2i.ZERO, "object_group":"terminal", "object_type":"terminal"},
			{"id":"door", "position":Vector2i(1, 0), "object_group":"door", "object_type":"door"}
		],
		"bindings":[]
	}
	var canonical_load: Dictionary = store.replace_serialized_snapshot(canonical)
	_assert(bool(canonical_load.get("ok", false)), "strict store rejected canonical v2")
	var stable_before: String = var_to_str(store.get_serializable_snapshot())
	var direct_legacy: Dictionary = store.replace_serialized_snapshot({"format_version":0, "objects":[]})
	_assert(str(direct_legacy.get("code", "")) == "invalid_format_version", "strict store accepted format0")
	_assert(var_to_str(store.get_serializable_snapshot()) == stable_before, "rejected format0 mutated strict store")
	var direct_v1: Dictionary = store.replace_serialized_snapshot({"format_version":1, "entities":[], "bindings":[]})
	_assert(str(direct_v1.get("code", "")) == "invalid_format_version", "strict store accepted format1")
	_assert(var_to_str(store.get_serializable_snapshot()) == stable_before, "rejected format1 mutated strict store")

	var legacy_reel: Dictionary = {
		"id":"reel",
		"position":Vector2i(2, 0),
		"object_group":"item",
		"object_type":"power_cable_reel",
		"end_1_state":"connected",
		"end_1_target_id":"terminal",
		"end_2_state":"held",
		"end_2_target_id":"",
		"cable_path_cells":[Vector2i.ZERO, Vector2i(1, 0)]
	}
	var migrated_reel: Dictionary = ReelRef.migrate_legacy_reel(legacy_reel)
	_assert(not _has_flat_reel_alias(migrated_reel), "reel migration retained flat aliases")
	_assert(Dictionary(migrated_reel.get("end_1", {})).get("state", "") == ReelRef.END_CONNECTED, "reel end 1 was not migrated")
	_assert(Array(migrated_reel.get("path_cells", [])).size() == 2, "reel path was not migrated")
	var nested_only: Dictionary = ReelRef.canonicalize_reel(migrated_reel)
	_assert(not _has_flat_reel_alias(nested_only), "normal reel canonicalizer recreated flat aliases")

	var legacy_document: Dictionary = {
		"format_version":0,
		"objects":[
			{"id":"terminal", "position":Vector2i.ZERO, "object_group":"terminal", "object_type":"terminal"},
			{"id":"door", "position":Vector2i(1, 0), "object_group":"door", "object_type":"door", "control_terminal_id":"terminal"},
			legacy_reel
		],
		"bindings":[]
	}
	var migration: Dictionary = MigrationRef.migrate_document(legacy_document)
	_assert(bool(migration.get("success", false)), "versioned loader rejected representative legacy document")
	var migrated_snapshot: Dictionary = Dictionary(migration.get("snapshot", {}))
	_assert(int(migrated_snapshot.get("format_version", 0)) == StoreRef.WORLD_SNAPSHOT_FORMAT_VERSION, "versioned loader did not emit current format")
	_assert(_has_binding(migrated_snapshot, BindingContractRef.ROLE_CONTROL_TERMINAL, "terminal", "door"), "versioned loader lost logical relation")
	var migrated_snapshot_reel: Dictionary = {}
	for value in Array(migrated_snapshot.get("entities", [])):
		if value is Dictionary and str(Dictionary(value).get("id", "")) == "reel":
			migrated_snapshot_reel = Dictionary(value)
	_assert(not migrated_snapshot_reel.is_empty(), "versioned loader lost reel")
	_assert(not _has_flat_reel_alias(migrated_snapshot_reel), "versioned loader emitted flat reel aliases")
	var migrated_store = StoreRef.new()
	var migrated_load: Dictionary = migrated_store.replace_serialized_snapshot(migrated_snapshot)
	_assert(bool(migrated_load.get("ok", false)), "strict store rejected versioned-loader output")

	await process_frame
	if failures.is_empty():
		print("CANONICAL_RUNTIME_OWNERSHIP_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("CANONICAL_RUNTIME_OWNERSHIP_GATE: FAIL: %s" % failure)
	quit(1)
