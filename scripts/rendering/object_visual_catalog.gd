extends RefCounted

var entries_by_id: Dictionary = {}

func load_from_path(path: String = "res://data/visual/object_visual_catalog.json") -> void:
	entries_by_id.clear()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	for key in Dictionary(parsed).keys():
		entries_by_id[str(key)] = Dictionary(Dictionary(parsed)[key]).duplicate(true)

func get_entry(visual_id: String) -> Dictionary:
	return Dictionary(entries_by_id.get(visual_id, {})).duplicate(true)
