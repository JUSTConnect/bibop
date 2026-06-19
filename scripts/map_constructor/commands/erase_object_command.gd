extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted = null
var object_data: Dictionary = {}

func setup(target_repository: RefCounted, data: Dictionary) -> RefCounted:
	repository = target_repository
	object_data = data.duplicate(true)
	label = "Erase %s" % str(object_data.get("display_name", object_data.get("id", "object")))
	return self

func execute() -> bool:
	return not Dictionary(repository.call("remove_object", str(object_data.get("id", "")))).is_empty()

func undo() -> void:
	repository.call("add_object", object_data)
