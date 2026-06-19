extends RefCounted

const MapDocumentRef = preload("res://scripts/map_constructor/map_document.gd")
const MigratorRef = preload("res://scripts/map_constructor/map_document_migrator.gd")
const ValidatorRef = preload("res://scripts/map_constructor/map_document_validator.gd")
const DEFAULT_PATH := "user://newbip_map_document.json"
const LEGACY_PATH := "user://newbip_map_snapshot.json"

static func save_document(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var document: Dictionary = MapDocumentRef.from_edit_state(snapshot)
	var errors: Array[String] = ValidatorRef.validate(document)
	if not errors.is_empty():
		return {"ok": false, "message": "Map document validation failed.", "errors": errors}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Cannot save map document."}
	file.store_string(JSON.stringify(document, "\t"))
	return {"ok": true, "message": "Map document v3 saved.", "document": document}

static func load_document(path: String = DEFAULT_PATH) -> Dictionary:
	var source_path: String = path
	if not FileAccess.file_exists(source_path):
		source_path = LEGACY_PATH
	if not FileAccess.file_exists(source_path):
		return {"ok": false, "message": "Map document not found."}
	var parsed: Variant = _read_json(source_path)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Map document JSON is invalid."}
	var migrated: Dictionary = MigratorRef.migrate(Dictionary(parsed))
	if migrated.is_empty():
		return {"ok": false, "message": "Unsupported map document version."}
	var errors: Array[String] = ValidatorRef.validate(migrated)
	if not errors.is_empty():
		return {"ok": false, "message": "Map document validation failed.", "errors": errors}
	return {
		"ok": true,
		"message": "Map document v3 loaded.",
		"snapshot": MapDocumentRef.to_edit_snapshot(migrated),
		"document": migrated,
	}

static func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
