extends RefCounted

const MapDocumentRef = preload("res://scripts/map_constructor/map_document.gd")
const DEFAULT_PATH := "user://newbip_map_document.json"

static func save_document(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var document: Dictionary = MapDocumentRef.from_edit_state(snapshot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false}
	file.store_string(JSON.stringify(document, "\t"))
	return {"ok": true, "document": document}

static func load_document(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false}
	return {"ok": true, "snapshot": MapDocumentRef.to_edit_snapshot(Dictionary(parsed)), "document": Dictionary(parsed)}
