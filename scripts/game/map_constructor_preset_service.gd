extends RefCounted
class_name MapConstructorPresetService

# File IO and serialization helpers for TASK TEST Map Constructor presets.
# This service intentionally does not know gameplay rules. It only snapshots,
# saves, loads, lists and deletes constructor preset payloads.

const SCHEMA_VERSION: int = 1
const DEFAULT_PRESET_DIR: String = "user://constructor_presets"
const PRESET_FILE_EXTENSION: String = ".json"

const SNAPSHOT_FIELDS: Array[String] = [
	"mission_world_objects",
	"cell_items",
	"world_objects_by_cell",
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
		return {"ok": false, "message": "Preset directory is empty.", "preset_dir": clean_dir}
	var error_code: int = DirAccess.make_dir_recursive_absolute(clean_dir)
	if error_code != OK:
		return {"ok": false, "message": "Failed to create preset directory.", "error_code": error_code, "preset_dir": clean_dir}
	return {"ok": true, "message": "OK", "preset_dir": clean_dir}

static func snapshot_from_owner(owner: Object) -> Dictionary:
	var snapshot: Dictionary = {}
	if owner == null:
		return snapshot
	for field_name in SNAPSHOT_FIELDS:
		snapshot[field_name] = _duplicate_if_possible(owner.get(field_name))
	return snapshot

static func apply_snapshot_to_owner(owner: Object, snapshot: Dictionary) -> Dictionary:
	if owner == null:
		return {"ok": false, "message": "Owner is null.", "applied_fields": []}
	var effective_snapshot: Dictionary = snapshot.duplicate(true)
	if owner.has_method("normalize_map_constructor_surface_override_snapshot"):
		var normalized_surface: Dictionary = owner.call("normalize_map_constructor_surface_override_snapshot", {
			"wall_material_overrides": effective_snapshot.get("_map_constructor_wall_material_overrides", {}),
			"floor_material_overrides": effective_snapshot.get("_map_constructor_floor_material_overrides", {})
		})
		effective_snapshot["_map_constructor_wall_material_overrides"] = Dictionary(normalized_surface.get("wall_material_overrides", {})).duplicate(true)
		effective_snapshot["_map_constructor_floor_material_overrides"] = Dictionary(normalized_surface.get("floor_material_overrides", {})).duplicate(true)
	var applied_fields: Array[String] = []
	for field_name in SNAPSHOT_FIELDS:
		if not effective_snapshot.has(field_name):
			continue
		owner.set(field_name, _duplicate_if_possible(effective_snapshot.get(field_name)))
		applied_fields.append(field_name)
	return {"ok": true, "message": "Snapshot applied.", "applied_fields": applied_fields}

static func build_preset_document(preset_id: String, snapshot: Dictionary, display_name: String = "", metadata: Dictionary = {}) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	var resolved_display_name: String = str(display_name).strip_edges()
	if resolved_display_name.is_empty():
		resolved_display_name = safe_id
	return {
		"schema_version": SCHEMA_VERSION,
		"preset_id": safe_id,
		"display_name": resolved_display_name,
		"created_at_unix": int(Time.get_unix_time_from_system()),
		"metadata": metadata.duplicate(true),
		"snapshot": _to_json_safe(snapshot)
	}

static func validate_preset_document(document: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	if int(document.get("schema_version", -1)) != SCHEMA_VERSION:
		warnings.append("unsupported_schema_version")
	if str(document.get("preset_id", "")).strip_edges().is_empty():
		warnings.append("missing_preset_id")
	if not document.has("snapshot"):
		warnings.append("missing_snapshot")
	return warnings

static func save_preset(preset_id: String, snapshot: Dictionary, preset_dir: String = DEFAULT_PRESET_DIR, display_name: String = "", metadata: Dictionary = {}) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok": false, "message": "Preset id is empty or invalid.", "preset_id": preset_id, "path": ""}
	var dir_result: Dictionary = ensure_preset_dir(preset_dir)
	if not bool(dir_result.get("ok", false)):
		return dir_result
	var document: Dictionary = build_preset_document(safe_id, snapshot, display_name, metadata)
	var path: String = get_preset_file_path(safe_id, preset_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Failed to open preset file for writing.", "preset_id": safe_id, "path": path, "error_code": FileAccess.get_open_error()}
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return {"ok": true, "message": "Preset saved.", "preset_id": safe_id, "path": path, "document": document}

static func load_preset(preset_id: String, preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok": false, "message": "Preset id is empty or invalid.", "preset_id": preset_id, "path": "", "snapshot": {}}
	var path: String = get_preset_file_path(safe_id, preset_dir)
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset file does not exist.", "preset_id": safe_id, "path": path, "snapshot": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Failed to open preset file for reading.", "preset_id": safe_id, "path": path, "snapshot": {}, "error_code": FileAccess.get_open_error()}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Preset JSON is invalid.", "preset_id": safe_id, "path": path, "snapshot": {}}
	var document: Dictionary = Dictionary(parsed)
	var warnings: Array[String] = validate_preset_document(document)
	if not warnings.is_empty():
		return {"ok": false, "message": "Preset document is invalid.", "preset_id": safe_id, "path": path, "warnings": warnings, "snapshot": {}}
	var snapshot: Dictionary = Dictionary(_from_json_safe(document.get("snapshot", {})))
	return {"ok": true, "message": "Preset loaded.", "preset_id": safe_id, "path": path, "document": document, "snapshot": snapshot}

static func list_presets(preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var dir_result: Dictionary = ensure_preset_dir(preset_dir)
	if not bool(dir_result.get("ok", false)):
		return {"ok": false, "message": str(dir_result.get("message", "Preset directory unavailable.")), "presets": []}
	var dir := DirAccess.open(preset_dir)
	if dir == null:
		return {"ok": false, "message": "Failed to open preset directory.", "presets": []}
	var presets: Array[Dictionary] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(PRESET_FILE_EXTENSION):
			var preset_id: String = file_name.trim_suffix(PRESET_FILE_EXTENSION)
			var loaded: Dictionary = load_preset(preset_id, preset_dir)
			var row: Dictionary = {"preset_id": preset_id, "file_name": file_name, "path": get_preset_file_path(preset_id, preset_dir), "valid": bool(loaded.get("ok", false))}
			if bool(loaded.get("ok", false)):
				var document: Dictionary = Dictionary(loaded.get("document", {}))
				row["display_name"] = str(document.get("display_name", preset_id))
				row["created_at_unix"] = int(document.get("created_at_unix", 0))
				row["metadata"] = Dictionary(document.get("metadata", {})).duplicate(true)
			else:
				row["message"] = str(loaded.get("message", "Invalid preset."))
			presets.append(row)
		file_name = dir.get_next()
	dir.list_dir_end()
	presets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("preset_id", "")) < str(b.get("preset_id", ""))
	)
	return {"ok": true, "message": "OK", "preset_dir": preset_dir, "presets": presets}

static func delete_preset(preset_id: String, preset_dir: String = DEFAULT_PRESET_DIR) -> Dictionary:
	var safe_id: String = sanitize_preset_id(preset_id)
	if safe_id.is_empty():
		return {"ok": false, "message": "Preset id is empty or invalid.", "preset_id": preset_id}
	var path: String = get_preset_file_path(safe_id, preset_dir)
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset file does not exist.", "preset_id": safe_id, "path": path}
	var error_code: int = DirAccess.remove_absolute(path)
	if error_code != OK:
		return {"ok": false, "message": "Failed to delete preset file.", "preset_id": safe_id, "path": path, "error_code": error_code}
	return {"ok": true, "message": "Preset deleted.", "preset_id": safe_id, "path": path}

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
			return {"__type": "Vector2i", "x": v2i.x, "y": v2i.y}
		TYPE_VECTOR2:
			var v2: Vector2 = Vector2(value)
			return {"__type": "Vector2", "x": v2.x, "y": v2.y}
		TYPE_COLOR:
			var color: Color = Color(value)
			return {"__type": "Color", "r": color.r, "g": color.g, "b": color.b, "a": color.a}
		TYPE_ARRAY:
			var encoded_array: Array = []
			for entry in Array(value):
				encoded_array.append(_to_json_safe(entry))
			return {"__type": "Array", "items": encoded_array}
		TYPE_DICTIONARY:
			var encoded_entries: Array = []
			var source_dict: Dictionary = Dictionary(value)
			for key_variant in source_dict.keys():
				encoded_entries.append({"key": _to_json_safe(key_variant), "value": _to_json_safe(source_dict.get(key_variant))})
			return {"__type": "Dictionary", "entries": encoded_entries}
		_:
			return str(value)

static func _from_json_safe(value: Variant) -> Variant:
	if not (value is Dictionary):
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
