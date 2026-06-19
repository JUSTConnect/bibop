extends RefCounted

const CatalogRef = preload("res://scripts/domain/object_definition_catalog.gd")
const EditorRef = preload("res://scripts/app/map_editor_history_controller.gd")

static func run() -> Array[String]:
	var result: Array[String] = []
	var catalog: RefCounted = CatalogRef.new()
	catalog.call("load_paths", ["res://data/objects/door_basic.json"])
	var definition: Dictionary = Dictionary(catalog.call("get_definition", "door_basic"))
	var editor: RefCounted = EditorRef.new()
	editor.call("setup")
	editor.call("set_app_mode", "play")
	editor.call("handle_cell", Vector2i(1, 1), definition)
	if Array(editor.call("get_placed_objects")).size() != 0:
		result.append("Play mode changed world")
	editor.call("set_app_mode", "edit")
	editor.call("handle_cell", Vector2i(1, 1), definition)
	if Array(editor.call("get_placed_objects")).size() != 1:
		result.append("Edit mode did not place object")
	return result
