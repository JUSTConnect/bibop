extends RefCounted

func can_mutate_world() -> bool:
	return false

func enter(map_editor: RefCounted, world_session: RefCounted) -> void:
	world_session.call("capture", map_editor.call("make_snapshot"))
	map_editor.call("set_app_mode", "play")

func reset(map_editor: RefCounted, world_session: RefCounted) -> bool:
	if not bool(world_session.call("has_snapshot")):
		return false
	map_editor.call("load_snapshot", world_session.call("restore"))
	map_editor.call("set_app_mode", "play")
	return true
