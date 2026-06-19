extends RefCounted

const MapDocumentRef = preload("res://scripts/map_constructor/map_document.gd")
const DEFAULT_PATH := "user://newbip_map_document.json"
const LEGACY_PATH := "user://newbip_map_snapshot.json"

static func save_document(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var document: Dictionary = MapDocumentRef.from_edit_state(snapshot)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Cannot save map document."}
	file.store_string(JSON.stringify(document, "\t"))
	return {"ok": true, "message": "Map document saved.", "document": document}

static func load_document(path: String = DEFAULT_PATH) -> Dictionary:
	if FileAccess.file_exists(path):
		return _load_versioned(path)
	if FileAccess.file_exists(LEGACY_PATH):
		return _load_legacy(LEGACY_PATH)
	return {"ok": false, "message": "Map document not found."}

static func _load_versioned(path: String) -> Dictionary:
	var parsed: Variant = _read_json(path)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Map document JSON is invalid."}
	var document: Dictionary = Dictionary(parsed)
	return {
		"ok": true,
		"message": "Map document loaded.",
		"snapshot": MapDocumentRef.to_edit_snapshot(document),
		"document": document,
	}

static func _load_legacy(path: String) -> Dictionary:
	var parsed: Variant = _read_json(path)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Legacy snapshot JSON is invalid."}
	return {"ok": true, "message": "Legacy snapshot loaded.", "snapshot": Dictionary(parsed)}

static func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
