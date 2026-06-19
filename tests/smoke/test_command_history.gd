extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const EditorRef = preload("res://scripts/app/map_editor_history_controller.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var catalog: RefCounted = CatalogRef.new()
	catalog.call("load_paths", ["res://data/objects/power_source_basic.json"])
	var definition: Dictionary = Dictionary(catalog.call("get_definition", "power_source_basic"))
	var editor: RefCounted = EditorRef.new()
	editor.call("setup")
	editor.call("place_object", Vector2i(1, 1), definition)
	if Array(editor.call("get_placed_objects")).size() != 1:
		errors.append("Place command failed")
	editor.call("undo")
	if not Array(editor.call("get_placed_objects")).is_empty():
		errors.append("Undo place failed")
	editor.call("redo")
	if Array(editor.call("get_placed_objects")).size() != 1:
		errors.append("Redo place failed")
	editor.call("clear_map_keep_palette")
	editor.call("undo")
	if Array(editor.call("get_placed_objects")).size() != 1:
		errors.append("Undo clear failed")
	return errors
