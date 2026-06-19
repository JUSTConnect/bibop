extends RefCounted

func can_mutate_world() -> bool:
	return true

func enter(map_editor: RefCounted) -> void:
	map_editor.call("set_app_mode", "edit")
