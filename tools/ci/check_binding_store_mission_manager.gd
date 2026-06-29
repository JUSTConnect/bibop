extends SceneTree
func _init() -> void:
	var text := FileAccess.get_file_as_string("res://docs/ROADMAP.md")
	quit(0 if text.contains("BindingStore") else 1)
