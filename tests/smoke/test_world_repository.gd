extends RefCounted

const RepositoryRef = preload("res://scripts/world/world_object_repository.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var repository: RefCounted = RepositoryRef.new()
	var data: Dictionary = {"id": "object_1", "instance_id": "object_1", "placement": {"cell_x": 2, "cell_y": 3}}
	if not bool(repository.call("add_object", data)):
		errors.append("repository add failed")
	if str(repository.call("get_id_at_cell", Vector2i(2, 3))) != "object_1":
		errors.append("repository cell index failed")
	repository.call("apply_patch", "object_1", {"state": "active"})
	var updated: Dictionary = Dictionary(repository.call("get_object", "object_1"))
	if str(updated.get("state", "")) != "active":
		errors.append("repository patch failed")
	repository.call("remove_object", "object_1")
	if bool(repository.call("has_object_at_cell", Vector2i(2, 3))):
		errors.append("repository remove failed")
	return errors
