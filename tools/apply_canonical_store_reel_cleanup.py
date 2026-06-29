#!/usr/bin/env python3
from pathlib import Path
import re

store_path = Path("scripts/world/world_state_store.gd")
store = store_path.read_text()
pattern = r"func replace_serialized_snapshot\(snapshot: Dictionary\) -> Dictionary:\n.*?\nfunc add_object\(object_data: Dictionary\) -> Dictionary:"
replacement = '''func replace_serialized_snapshot(snapshot: Dictionary) -> Dictionary:
	var source_version: int = int(snapshot.get("format_version", -1))
	if source_version != WORLD_SNAPSHOT_FORMAT_VERSION:
		return BindingStoreContractRef.make_result("invalid_format_version", {}, {"expected":WORLD_SNAPSHOT_FORMAT_VERSION, "actual":source_version})
	var raw_entities: Variant = snapshot.get("entities", null)
	if not raw_entities is Array:
		return BindingStoreContractRef.make_result("missing", {}, {"field":"entities"})
	var entities: Array[Dictionary] = []
	for entity_value in Array(raw_entities):
		if not entity_value is Dictionary:
			return BindingStoreContractRef.make_result("missing", {}, {"field":"entities", "reason":"entity_not_dictionary"})
		entities.append(Dictionary(entity_value).duplicate(true))
	var raw_bindings: Variant = snapshot.get("bindings", null)
	if not raw_bindings is Array:
		return BindingStoreContractRef.make_result("missing", {}, {"field":"bindings"})
	var bindings: Array[Dictionary] = []
	for binding_value in Array(raw_bindings):
		if not binding_value is Dictionary:
			return BindingStoreContractRef.make_result("missing", {}, {"field":"bindings", "reason":"binding_not_dictionary"})
		bindings.append(Dictionary(binding_value).duplicate(true))
	var built: Dictionary = _build_state_from_objects(entities)
	if not bool(built.get("ok", false)):
		return built
	var objects_by_id: Dictionary = Dictionary(built.get("objects_by_id", {}))
	var binding_built: Dictionary = BindingStoreContractRef.build_state(bindings, objects_by_id, true)
	if not bool(binding_built.get("ok", false)):
		return binding_built
	_commit_state(objects_by_id, Array(built.get("object_order", [])), Dictionary(built.get("indexes", {})))
	_commit_binding_state(Dictionary(binding_built.get("bindings_by_id", {})), Dictionary(binding_built.get("indexes", {})))
	var diagnostics: Array = Array(binding_built.get("diagnostics", [])).duplicate(true)
	changed.emit({"action":"replace_serialized_snapshot", "warnings":[], "count":_object_order.size(), "binding_count":_bindings_by_id.size(), "binding_diagnostics":diagnostics})
	return _ok({"object_count":_object_order.size(), "binding_count":_bindings_by_id.size(), "binding_diagnostics":diagnostics})

func get_serializable_snapshot() -> Dictionary:
	var entities: Array[Dictionary] = []
	for object_id in _object_order:
		entities.append(Dictionary(_objects_by_id[object_id]).duplicate(true))
	return {"format_version":WORLD_SNAPSHOT_FORMAT_VERSION, "entities":entities, "bindings":get_all_bindings()}

func add_object(object_data: Dictionary) -> Dictionary:'''
store, count = re.subn(pattern, replacement, store, count=1, flags=re.S)
if count != 1:
    raise SystemExit(f"WorldStateStore snapshot block replaced {count}")
migrate_pattern = r"\nfunc migrate_legacy_bindings\(\) -> Dictionary:\n.*?\nfunc _duplicate_objects_by_id"
store, count = re.subn(migrate_pattern, "\nfunc _duplicate_objects_by_id", store, count=1, flags=re.S)
if count != 1:
    raise SystemExit(f"WorldStateStore legacy binding method removed {count}")
store_path.write_text(store)

reel_path = Path("scripts/game/power_cable_reel_service.gd")
reel = reel_path.read_text()
canonical_pattern = r"static func canonicalize_reel\(reel: Dictionary\) -> Dictionary:\n.*?\n\treturn result\n"
canonical_replacement = '''static func migrate_legacy_reel(source: Dictionary) -> Dictionary:
	var migrated: Dictionary = source.duplicate(true)
	if not migrated.get(END_1, {}) is Dictionary or Dictionary(migrated.get(END_1, {})).is_empty():
		migrated[END_1] = {"state":str(migrated.get("end_1_state", END_ON_REEL)), "target_id":str(migrated.get("end_1_target_id", ""))}
	if not migrated.get(END_2, {}) is Dictionary or Dictionary(migrated.get(END_2, {})).is_empty():
		migrated[END_2] = {"state":str(migrated.get("end_2_state", END_ON_REEL)), "target_id":str(migrated.get("end_2_target_id", ""))}
	if not migrated.has("path_cells") and migrated.has("cable_path_cells"):
		migrated["path_cells"] = Array(migrated.get("cable_path_cells", [])).duplicate(true)
	return canonicalize_reel(migrated)

static func canonicalize_reel(reel: Dictionary) -> Dictionary:
	var result: Dictionary = reel.duplicate(true)
	result["format_version"] = FORMAT_VERSION
	result["runtime_power_profile"] = "power_cable_reel"
	result[END_1] = _canonical_endpoint(result.get(END_1, {}))
	result[END_2] = _canonical_endpoint(result.get(END_2, {}))
	result["path_cells"] = _to_cells(result.get("path_cells", []))
	result["connection_state"] = str(result.get("connection_state", CONNECTION_DISCONNECTED)).strip_edges().to_lower()
	if str(result.get("connection_state", "")) not in [CONNECTION_DISCONNECTED, CONNECTION_PARTIAL, CONNECTION_COMPLETE, CONNECTION_INVALID, CONNECTION_BROKEN]:
		result["connection_state"] = CONNECTION_INVALID
	result["reconnect_required"] = bool(result.get("reconnect_required", false))
	for legacy_field in ["end_1_state", "end_1_target_id", "end_2_state", "end_2_target_id", "cable_path_cells", "connected_side_1", "connected_side_2", "connected", "disconnected"]:
		result.erase(legacy_field)
	result["cable_length"] = maxi(0, Array(result.get("path_cells", [])).size() - 1)
	result["is_connected"] = _both_ends_connected(result)
	return result
'''
reel, count = re.subn(canonical_pattern, canonical_replacement, reel, count=1, flags=re.S)
if count != 1:
    raise SystemExit(f"reel canonical block replaced {count}")
reel = reel.replace("\t_sync_legacy_aliases(reel)\n", "")
reel = reel.replace("\t_sync_legacy_aliases(next_reel)\n", "")
endpoint_pattern = r"static func _canonical_endpoint\(value: Variant, legacy_state: Variant, legacy_target_id: Variant\) -> Dictionary:\n.*?\n\treturn \{\"state\": state, \"target_id\": target_id\}\n\nstatic func _sync_legacy_aliases\(reel: Dictionary\) -> void:\n.*?\n\treel\[\"disconnected\"\] = not bool\(reel.get\(\"is_connected\", false\)\)\n"
endpoint_replacement = '''static func _canonical_endpoint(value: Variant) -> Dictionary:
	var endpoint: Dictionary = {}
	if value is Dictionary:
		endpoint = Dictionary(value).duplicate(true)
	var state: String = str(endpoint.get("state", END_ON_REEL)).strip_edges().to_lower()
	if state not in END_STATES:
		state = END_ON_REEL
	var target_id: String = str(endpoint.get("target_id", "")).strip_edges()
	if state != END_CONNECTED:
		target_id = ""
	return {"state":state, "target_id":target_id}
'''
reel, count = re.subn(endpoint_pattern, endpoint_replacement, reel, count=1, flags=re.S)
if count != 1:
    raise SystemExit(f"reel alias helper removed {count}")
reel_path.write_text(reel)

migration_path = Path("scripts/world/versioned_snapshot_migration_service.gd")
migration = migration_path.read_text()
old_call = "entity = PowerCableReelServiceRef.canonicalize_reel(entity)"
if migration.count(old_call) != 1:
    raise SystemExit("versioned reel migration call marker missing")
migration_path.write_text(migration.replace(old_call, "entity = PowerCableReelServiceRef.migrate_legacy_reel(entity)", 1))
