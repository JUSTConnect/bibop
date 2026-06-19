extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted
var instance_id: String = ""
var next_values: Dictionary = {}
var old_values: Dictionary = {}

func setup(target_repository: RefCounted, target_id: String, values: Dictionary, command_label: String = "Patch object") -> RefCounted:
	repository = target_repository
	instance_id = target_id
	next_values = values.duplicate(true)
	label = command_label
	var current: Dictionary = Dictionary(repository.call("get_object", instance_id))
	for field: Variant in next_values.keys():
		old_values[field] = current.get(field, null)
	return self

func execute() -> bool:
	var result: Dictionary = Dictionary(repository.call("apply_patch", instance_id, next_values))
	return not result.is_empty()

func undo() -> void:
	repository.call("apply_patch", instance_id, old_values)
