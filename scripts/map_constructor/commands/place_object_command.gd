extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted = null
var object_data: Dictionary = {}

func setup(target_repository: RefCounted, data: Dictionary) -> RefCounted:
	repository = target_repository
	object_data = data.duplicate(true)
	label = "Place %s" % str(object_data.get("display_name", object_data.get("id", "object")))
	return self

func execute() -> bool:
	return bool(repository.call("add_object", object_data))

func undo() -> void:
	repository.call("remove_object", str(object_data.get("id", "")))
