extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted
var before_objects: Array[Dictionary] = []
var after_objects: Array[Dictionary] = []

func setup(target_repository: RefCounted, next_objects: Array[Dictionary], command_label: String = "Replace world") -> RefCounted:
	repository = target_repository
	for value: Variant in Array(repository.call("get_objects")):
		before_objects.append(Dictionary(value))
	after_objects = next_objects.duplicate(true)
	label = command_label
	return self

func execute() -> bool:
	repository.call("replace_all", after_objects)
	return true

func undo() -> void:
	repository.call("replace_all", before_objects)
