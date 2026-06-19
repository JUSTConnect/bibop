extends "res://scripts/map_constructor/commands/map_command.gd"

var repository: RefCounted
var instance_id: String = ""
var next_links: Dictionary = {}
var old_links: Dictionary = {}

func setup(target_repository: RefCounted, target_id: String, links: Dictionary) -> RefCounted:
	repository = target_repository
	instance_id = target_id
	next_links = links.duplicate(true)
	var current: Dictionary = Dictionary(repository.call("get_object", instance_id))
	old_links = Dictionary(current.get("links", {})).duplicate(true)
	label = "Change links"
	return self

func execute() -> bool:
	var result: Dictionary = Dictionary(repository.call("apply_patch", instance_id, {"links": next_links}))
	return not result.is_empty()

func undo() -> void:
	repository.call("apply_patch", instance_id, {"links": old_links})
