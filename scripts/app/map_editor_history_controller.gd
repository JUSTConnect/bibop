extends "res://scripts/app/map_editor_controller.gd"

const ReplaceWorldCommandRef = preload("res://scripts/map_constructor/commands/replace_world_command.gd")

func clear_map_keep_palette() -> void:
	if app_mode() != "edit":
		return
	var empty_world: Array[Dictionary] = []
	var command: RefCounted = ReplaceWorldCommandRef.new().setup(repository, empty_world, "Clear map")
	history.call("execute", command)
	state.call("clear_instance_selection")
	state.set("next_instance_index", 1)
