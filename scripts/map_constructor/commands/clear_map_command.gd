extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted
var editor_state: RefCounted
var before_objects: Array[Dictionary] = []
var before_next_index: int = 1

func setup(target_repository: RefCounted, target_state: RefCounted) -> RefCounted:
	repository = target_repository
	editor_state = target_state
	for value: Variant in Array(repository.call("get_objects")):
		before_objects.append(Dictionary(value))
	before_next_index = int(editor_state.get("next_instance_index"))
	label = "Clear map"
	return self

func execute() -> bool:
	var empty_world: Array[Dictionary] = []
	repository.call("replace_all", empty_world)
	editor_state.call("clear_instance_selection")
	editor_state.set("next_instance_index", 1)
	return true

func undo() -> void:
	repository.call("replace_all", before_objects)
	editor_state.set("next_instance_index", before_next_index)
