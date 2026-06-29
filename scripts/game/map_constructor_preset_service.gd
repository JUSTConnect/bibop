extends RefCounted
class_name MapConstructorPresetService

const VersionedSnapshotMigrationServiceRef = preload("res://scripts/world/versioned_snapshot_migration_service.gd")

const SCHEMA_VERSION: int = 2
const MIN_SUPPORTED_SCHEMA_VERSION: int = 0
const DEFAULT_PRESET_DIR: String = "user://constructor_presets"
const PRESET_FILE_EXTENSION: String = ".json"
const WORLD_SNAPSHOT_FIELD: String = "world_state_snapshot"

const CODE_VALID := "valid"
const CODE_MIGRATED := "migrated"
const CODE_ALREADY_CURRENT := "already_current"
const CODE_UNSUPPORTED_SCHEMA_VERSION := "unsupported_schema_version"
const CODE_MISSING_SNAPSHOT := "missing_snapshot"
const CODE_WORLD_MIGRATION_FAILED := "world_migration_failed"

const SNAPSHOT_FIELDS: Array[String] = [
	"constructor_map_width",
	"constructor_map_height",
	"constructor_start_marker",
	"constructor_exit_marker",
	"_task_test_constructor_base_tiles",
	"_map_constructor_wall_material_overrides",
	"_map_constructor_floor_material_overrides",
	"map_constructor_door_visual_preset_overrides",
	"map_constructor_terminal_visual_preset_overrides",
	"current_mission_id"
]

const LEGACY_WORLD_FIELDS: Array[String] = [
	"mission_world_objects",
	"cell_items",
	"world_objects_by_cell",
	"bindings",
	"runtime_inventory_state"
]

static func sanitize_preset_id(preset_id: String) -> String:
	var source: String = str(preset_id).strip_edges().to_lower().replace(" ", "_")
	var result: String = ""
	for index in range(source.length()):
		var ch: String = source.substr(index, 1)
		if _is_allowed_preset_char(ch):
			result += ch
		elif ch in [".", "/", "\\", ":"]:
			result += "_"
	if result.begins_with("_"):
		result = result.trim_prefix("_")
	while result.ends_with("_"):
		result = result.substr(0, result.length() - 1)
	return result

static func _is_allowed_preset_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code: int = ch.unicode_at(0)
	var is_digit: bool = code >= 48 and code <= 57
	var is_lower_letter: bool = code >= 97 and code <= 122
	return is_digit or is_lower_letter or ch == "_" or ch == "-"

static func get_preset_file_path(preset_id: String, preset_dir: String = DEFAULT_PRESET_DIR) -> String:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return ""
	var clean_dir: String = str(preset_dir).strip_edges()
	while clean_dir.ends_with("/"):
		clean_dir = clean_dir.substr(0, clean_dir.length() - 1)
	return "%s/%s%s" % [clean_dir, safe_id, PRESET_FILE_EXTENSION]

static func ensure_preset_dir(preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var clean_dir: String = str(preset_dir).strip_edges()
	if clean_dir.is_empty():
		return {"ok":false, "success":false, "code":"preset_dir_empty", "message":"Preset directory is empty.", "preset_dir":clean_dir}
	var error_code: int = DirAccess.make_dir_recursive_absolute(clean_dir)
	if error_code != OK:
		return {"ok":false, "success":false, "code":"preset_dir_create_failed", "message":"Failed to create preset directory.", "error_code":error_code, "preset_dir":clean_dir}
	return {"ok":true, "success":true, "code":CODE_VALID, "message":"OK", "preset_dir":clean_dir}

static func snapshot_from_owner(owner: Object) -> Dictionary:
	var snapshot: Dictionary = {}
	if owner == null:
		return snapshot
	if owner.has_method("get_world_state_serializable_snapshot"):
		var world_snapshot: Variant = owner.call("get_world_state_serializable_snapshot")
		if world_snapshot is Dictionary:
			snapshot[WORLD_SNAPSHOT_FIELD] = Dictionary(world_snapshot).duplicate(true)
	for field_name in SNAPSHOT_FIELDS:
		snapshot[field_name] = _duplicate_if_possible(owner.get(field_name))
	return snapshot

static func migrate_preset_snapshot(source_snapshot: Dictionary) -> Dictionary:
	var source: Dictionary = source_snapshot.duplicate(true)
	var canonical: Dictionary = source.duplicate(true)
	var world_document: Dictionary = {}
	if source.get(WORLD_SNAPSHOT_FIELD, {}) is Dictionary and not Dictionary(source.get(WORLD_SNAPSHOT_FIELD, {})).is_empty():
		world_document = Dictionary(source.get(WORLD_SNAPSHOT_FIELD, {})).duplicate(true)
	elif source.get("mission_world_objects", []) is Array:
		world_document = {
			"format_version":0,
			"objects":Array(source.get("mission_world_objects", [])).duplicate(true),
			"bindings":Array(source.get("bindings", [])).duplicate(true),
			"runtime_inventory_state":Dictionary(source.get("runtime_inventory_state", {})).duplicate(true),
			"center_storage":Dictionary(source.get("center_storage", {})).duplicate(true),
			"details_currency":Dictionary(source.get("details_currency", {})).duplicate(true)
		}
	if not world_document.is_empty():
		var world_migration: Dictionary = VersionedSnapshotMigrationServiceRef.migrate_document(world_document)
		if not bool(world_migration.get("success", false)):
			return {
				"ok":false,
				"success":false,
				"code":CODE_WORLD_MIGRATION_FAILED,
				"reason_code":CODE_WORLD_MIGRATION_FAILED,
				"issues":Array(world_migration.get("issues", [])).duplicate(true),
				"snapshot":source
			}
		canonical[WORLD_SNAPSHOT_FIELD] = Dictionary(world_migration.get("snapshot", {})).duplicate(true)
	for field_name in LEGACY_WORLD_FIELDS:
		canonical.erase(field_name)
	canonical.erase("center_storage")
	canonical.erase("details_currency")
	return {"ok":true, "success":true, "code":CODE_VALID, "reason_code":CODE_VALID, "issues":[], "snapshot":canonical}

static func migrate_preset_document(source_document: Dictionary) -> Dictionary:
	var source: Dictionary = source_document.duplicate(true)
	var source_version: int = int(source.get("schema_version", 0))
	if source_version > SCHEMA_VERSION or source_version < MIN_SUPPORTED_SCHEMA_VERSION:
		return _migration_result(false, CODE_UNSUPPORTED_SCHEMA_VERSION, source_version, source, {}, [{"code":CODE_UNSUPPORTED_SCHEMA_VERSION, "severity":"fatal"}])
	if not source.has("snapshot") or not source.get("snapshot", {}) is Dictionary:
		return _migration_result(false, CODE_MISSING_SNAPSHOT, source_version, source, {}, [{"code":CODE_MISSING_SNAPSHOT, "severity":"fatal"}])
	var snapshot_result: Dictionary = migrate_preset_snapshot(Dictionary(source.get("snapshot", {})))
	if not bool(snapshot_result.get("success", false)):
		return _migration_result(false, str(snapshot_result.get("code", CODE_WORLD_MIGRATION_FAILED)), source_version, source, Dictionary(snapshot_result.get("snapshot", {})), Array(snapshot_result.get("issues", [])).duplicate(true))
	var canonical_snapshot: Dictionary = Dictionary(snapshot_result.get("snapshot", {})).duplicate(true)
	var document: Dictionary = source.duplicate(true)
	document["schema_version"] = SCHEMA_VERSION
	document["snapshot"] = canonical_snapshot
	var migrated: bool = source_version < SCHEMA_VERSION or var_to_str(canonical_snapshot) != var_to_str(Dictionary(source.get("snapshot", {})))
	var code: String = CODE_MIGRATED if migrated else CODE_ALREADY_CURRENT
	return _migration_result(true, code, source_version, document, canonical_snapshot, [])

static func apply_snapshot_to_owner(owner: Object, snapshot: Dictionary) -> Dictionary:
	if owner == null:
		return {"ok":false, "success":false, "code":"owner_missing", "message":"Owner is null.", "applied_fields":[]}
	var migration: Dictionary = migrate_preset_snapshot(snapshot)
	if not bool(migration.get("success", false)):
		return migration
	var effective_snapshot: Dictionary = Dictionary(migration.get("snapshot", {})).duplicate(true)
	if effective_snapshot.get(WORLD_SNAPSHOT_FIELD, {}) is Dictionary and owner.has_method("replace_world_state_serialized_snapshot"):
		var load_result: Dictionary = Dictionary(owner.call("replace_world_state_serialized_snapshot", Dictionary(effective_snapshot.get(WORLD_SNAPSHOT_FIELD, {}))))
		if not bool(load_result.get("success", load_result.get("ok", false))):
			return {"ok":false, "success":false, "code":"world_snapshot_apply_failed", "reason_code":"world_snapshot_apply_failed", "world_result":load_result, "applied_fields":[]}
	if owner.has_method("normalize_map_constructor_surface_override_snapshot"):
		var normalized_surface: Dictionary = owner.call("normalize_map_constructor_surface_override_snapshot", {
			"wall_material_overrides":effective_snapshot.get("_map_constructor_wall_material_overrides", {}),
			"floor_material_overrides":effective_snapshot.get("_map_constructor_floor_material_overrides", {})
		})
		effective_snapshot["_map_constructor_wall_material_overrides"] = Dictionary(normalized_surface.get("wall_material_overrides", {})).duplicate(true)
		effective_snapshot["_map_constructor_floor_material_overrides"] = Dictionary(normalized_surface.get("floor_material_overrides", {})).duplicate(true)
	var applied_fields: Array[String] = []
	for field_name in SNAPSHOT_FIELDS:
		if not effective_snapshot.has(field_name):
			continue
		owner.set(field_name, _duplicate_if_possible(effective_snapshot.get(field_name)))
		applied_fields.append(field_name)
	return {"ok":true, "success":true, "code":CODE_VALID, "message":"Snapshot applied.", "applied_fields":applied_fields, "migration":migration}

static func build_preset_document(preset_id: String, snapshot: Dictionary, display_name: String = "", metadata: Dictionary = {}) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	var resolved_display_name: String = str(display_name).strip_edges()
	if resolved_display_name.is_empty():
		resolved_display_name = safe_id
	return {
		"schema_version":SCHEMA_VERSION,
		"preset_id":safe_id,
		"display_name":resolved_display_name,
		"created_at_unix":int(Time.get_unix_time_from_system()),
		"metadata":metadata.duplicate(true),
		"snapshot":_to_json_safe(snapshot)
	}

static func validate_preset_document(document: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var source_version: int = int(document.get("schema_version", 0))
	if source_version < MIN_SUPPORTED_SCHEMA_VERSION or source_version > SCHEMA_VERSION:
		warnings.append(CODE_UNSUPPORTED_SCHEMA_VERSION)
	if str(document.get("preset_id", "")).strip_edges().is_empty():
		warnings.append("missing_preset_id")
	if not document.has("snapshot"):
		warnings.append(CODE_MISSING_SNAPSHOT)
	return warnings

static func save_preset(preset_id: String, snapshot: Dictionary, preset_dir: String = DEFAULT_PRESET_DIR, display_name: String = "", metadata: Dictionary = {}) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok":false, "success":false, "code":"preset_id_invalid", "message":"Preset id is empty or invalid.", "preset_id":preset_id, "path":""}
	var migration: Dictionary = migrate_preset_snapshot(snapshot)
	if not bool(migration.get("success", false)):
		return migration
	var dir_result: Dictionary = ensure_preset_dir(preset_dir)
	if not bool(dir_result.get("ok", false)):
		return dir_result
	var canonical_snapshot: Dictionary = Dictionary(migration.get("snapshot", {})).duplicate(true)
	var document: Dictionary = build_preset_document(safe_id, canonical_snapshot, display_name, metadata)
	var path: String = get_preset_file_path(safe_id, preset_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok":false, "success":false, "code":"preset_write_failed", "message":"Failed to open preset file for writing.", "preset_id":safe_id, "path":path, "error_code":FileAccess.get_open_error()}
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return {"ok":true, "success":true, "code":CODE_VALID, "message":"Preset saved.", "preset_id":safe_id, "path":path, "document":document}

static func load_preset(preset_id: String, preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok":false, "success":false, "code":"preset_id_invalid", "message":"Preset id is empty or invalid.", "preset_id":preset_id, "path":"", "snapshot":{}}
	var path: String = get_preset_file_path(safe_id, preset_dir)
	if not FileAccess.file_exists(path):
		return {"ok":false, "success":false, "code":"preset_missing", "message":"Preset file does not exist.", "preset_id":safe_id, "path":path, "snapshot":{}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok":false, "success":false, "code":"preset_read_failed", "message":"Failed to open preset file for reading.", "preset_id":safe_id, "path":path, "snapshot":{}, "error_code":FileAccess.get_open_error()}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return {"ok":false, "success":false, "code":"preset_json_invalid", "message":"Preset JSON is invalid.", "preset_id":safe_id, "path":path, "snapshot":{}}
	var decoded_document: Dictionary = Dictionary(parsed).duplicate(true)
	decoded_document["snapshot"] = _from_json_safe(decoded_document.get("snapshot", {}))
	var warnings: Array[String] = validate_preset_document(decoded_document)
	if not warnings.is_empty():
		return {"ok":false, "success":false, "code":str(warnings[0]), "message":"Preset document is invalid.", "preset_id":safe_id, "path":path, "warnings":warnings, "snapshot":{}}
	var migration: Dictionary = migrate_preset_document(decoded_document)
	if not bool(migration.get("success", false)):
		return migration
	var canonical_snapshot: Dictionary = Dictionary(migration.get("snapshot", {})).duplicate(true)
	var canonical_document: Dictionary = Dictionary(migration.get("document", {})).duplicate(true)
	canonical_document["snapshot"] = _to_json_safe(canonical_snapshot)
	return {"ok":true, "success":true, "code":str(migration.get("code", CODE_VALID)), "message":"Preset loaded.", "preset_id":safe_id, "path":path, "document":canonical_document, "snapshot":canonical_snapshot, "migration":migration}

static func list_presets(preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var dir_result: Dictionary = ensure_preset_dir(preset_dir)
	if not bool(dir_result.get("ok", false)):
		return {"ok":false, "success":false, "code":str(dir_result.get("code", "preset_dir_unavailable")), "message":str(dir_result.get("message", "Preset directory unavailable.")), "presets":[]}
	var dir := DirAccess.open(preset_dir)
	if dir == null:
		return {"ok":false, "success":false, "code":"preset_dir_open_failed", "message":"Failed to open preset directory.", "presets":[]}
	var presets: Array[Dictionary] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(PRESET_FILE_EXTENSION):
			var preset_id: String = file_name.trim_suffix(PRESET_FILE_EXTENSION)
			var loaded: Dictionary = load_preset(preset_id, preset_dir)
			var row: Dictionary = {"preset_id":preset_id, "file_name":file_name, "path":get_preset_file_path(preset_id, preset_dir), "valid":bool(loaded.get("ok", false))}
			if bool(loaded.get("ok", false)):
				var document: Dictionary = Dictionary(loaded.get("document", {}))
				row["display_name"] = str(document.get("display_name", preset_id))
				row["created_at_unix"] = int(document.get("created_at_unix", 0))
				row["metadata"] = Dictionary(document.get("metadata", {})).duplicate(true)
				row["schema_version"] = int(document.get("schema_version", 0))
			else:
				row["message"] = str(loaded.get("message", "Invalid preset."))
			presets.append(row)
		file_name = dir.get_next()
	dir.list_dir_end()
	presets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("preset_id", "")) < str(b.get("preset_id", ""))
	)
	return {"ok":true, "success":true, "code":CODE_VALID, "message":"OK", "preset_dir":preset_dir, "presets":presets}

static func delete_preset(preset_id: String, preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok":false, "success":false, "code":"preset_id_invalid", "message":"Preset id is empty or invalid.", "preset_id":preset_id}
	var path: String = get_preset_file_path(safe_id, preset_dir)
	if not FileAccess.file_exists(path):
		return {"ok":false, "success":false, "code":"preset_missing", "message":"Preset file does not exist.", "preset_id":safe_id, "path":path}
	var error_code: int = DirAccess.remove_absolute(path)
	if error_code != OK:
		return {"ok":false, "success":false, "code":"preset_delete_failed", "message":"Failed to delete preset file.", "preset_id":safe_id, "path":path, "error_code":error_code}
	return {"ok":true, "success":true, "code":CODE_VALID, "message":"Preset deleted.", "preset_id":safe_id, "path":path}

static func _migration_result(success: bool, code: String, source_version: int, document: Dictionary, snapshot: Dictionary, issues: Array) -> Dictionary:
	return {
		"ok":success,
		"success":success,
		"code":code,
		"reason_code":code,
		"source_schema_version":source_version,
		"target_schema_version":SCHEMA_VERSION,
		"migrated":success and code == CODE_MIGRATED,
		"issues":issues.duplicate(true),
		"document":document.duplicate(true),
		"snapshot":snapshot.duplicate(true)
	}

static func _duplicate_if_possible(value: Variant) -> Variant:
	if value is Dictionary:
		return Dictionary(value).duplicate(true)
	if value is Array:
		return Array(value).duplicate(true)
	return value

static func _to_json_safe(value: Variant) -> Variant:
	var value_type: int = typeof(value)
	match value_type:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_VECTOR2I:
			var v2i: Vector2i = Vector2i(value)
			return {"__type":"Vector2i", "x":v2i.x, "y":v2i.y}
		TYPE_VECTOR2:
			var v2: Vector2 = Vector2(value)
			return {"__type":"Vector2", "x":v2.x, "y":v2.y}
		TYPE_COLOR:
			var color: Color = Color(value)
			return {"__type":"Color", "r":color.r, "g":color.g, "b":color.b, "a":color.a}
		TYPE_ARRAY:
			var encoded_array: Array = []
			for entry in Array(value):
				encoded_array.append(_to_json_safe(entry))
			return {"__type":"Array", "items":encoded_array}
		TYPE_DICTIONARY:
			var encoded_entries: Array = []
			var source_dict: Dictionary = Dictionary(value)
			for key_variant in source_dict.keys():
				encoded_entries.append({"key":_to_json_safe(key_variant), "value":_to_json_safe(source_dict.get(key_variant))})
			return {"__type":"Dictionary", "entries":encoded_entries}
		_:
			return str(value)

static func _from_json_safe(value: Variant) -> Variant:
	if not value is Dictionary:
		return value
	var data: Dictionary = Dictionary(value)
	var type_name: String = str(data.get("__type", ""))
	match type_name:
		"Vector2i":
			return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
		"Vector2":
			return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
		"Color":
			return Color(float(data.get("r", 0.0)), float(data.get("g", 0.0)), float(data.get("b", 0.0)), float(data.get("a", 1.0)))
		"Array":
			var decoded_array: Array = []
			for item_variant in Array(data.get("items", [])):
				decoded_array.append(_from_json_safe(item_variant))
			return decoded_array
		"Dictionary":
			var decoded_dict: Dictionary = {}
			for entry_variant in Array(data.get("entries", [])):
				var entry: Dictionary = Dictionary(entry_variant)
				decoded_dict[_from_json_safe(entry.get("key"))] = _from_json_safe(entry.get("value"))
			return decoded_dict
		_:
			var plain_dict: Dictionary = {}
			for key_variant in data.keys():
				plain_dict[key_variant] = _from_json_safe(data.get(key_variant))
			return plain_dict
