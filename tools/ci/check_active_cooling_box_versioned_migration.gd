extends SceneTree

const MigrationService = preload("res://scripts/world/versioned_snapshot_migration_service.gd")

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

func _legacy_document() -> Dictionary:
	return {
		"format_version": 0,
		"objects": [
			{
				"id":"cooling_box_a",
				"position":Vector2i(5, 0),
				"object_group":"cooling",
				"object_type":"external_air_cooler",
				"output_ne":true,
				"output_se":false,
				"flow_state":"active",
				"linked_cooling_ids":["duct_a"]
			}
		],
		"bindings": [],
		"runtime_inventory_state": {},
		"center_storage": {}
	}

func _run() -> void:
	await process_frame
	var source: Dictionary = _legacy_document()
	var source_before: String = var_to_str(source)
	var migrated: Dictionary = MigrationService.migrate_document(source)
	_assert(bool(migrated.get("success", false)), "active cooling migration failed: %s" % str(migrated))
	_assert(var_to_str(source) == source_before, "active cooling migration mutated source")
	var snapshot: Dictionary = Dictionary(migrated.get("snapshot", {}))
	var cooling_box: Dictionary = _entity_by_id(snapshot, "cooling_box_a")
	_assert(str(cooling_box.get("object_type", "")) == "metal_cooling_block", "active cooling box subtype was not canonicalized")
	_assert(str(cooling_box.get("output_side", "")) == "NE", "active cooling output side was not normalized")
	_assert(str(cooling_box.get("cooling_output_side", "")) == "NE", "active cooling compatibility output side was not normalized")
	for field_name in ["output_ne", "output_se", "output_sw", "output_nw", "cooling_output_ne", "cooling_output_se", "cooling_output_sw", "cooling_output_nw", "flow_state", "linked_cooling_ids"]:
		_assert(not cooling_box.has(field_name), "legacy active-cooling field remained: %s" % field_name)
	var second: Dictionary = MigrationService.migrate_document(snapshot)
	_assert(bool(second.get("success", false)), "current active cooling snapshot validation failed")
	_assert(str(second.get("code", "")) == MigrationService.CODE_ALREADY_CURRENT, "current active cooling snapshot was remigrated")
	_assert(var_to_str(Dictionary(second.get("snapshot", {}))) == var_to_str(snapshot), "active cooling migration is not idempotent")

	await process_frame
	if failures.is_empty():
		print("ACTIVE_COOLING_BOX_VERSIONED_MIGRATION_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACTIVE_COOLING_BOX_VERSIONED_MIGRATION_GATE: FAIL: %s" % failure)
	quit(1)
