extends "res://scripts/app/map_editor_controller.gd"

const ClearMapCommandRef = preload("res://scripts/map_constructor/commands/clear_map_command.gd")

func clear_map_keep_palette() -> void:
	if app_mode() != "edit":
		return
	var command: RefCounted = ClearMapCommandRef.new().setup(repository, state)
	history.call("execute", command)
