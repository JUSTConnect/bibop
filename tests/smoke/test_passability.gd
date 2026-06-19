extends RefCounted

const RepositoryRef = preload("res://scripts/world/world_object_repository.gd")
const PassabilityRef = preload("res://scripts/world/passability_system.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var repository: RefCounted = RepositoryRef.new()
	var door: Dictionary = {
		"id": "door_1",
		"object_type": "door",
		"state": "closed",
		"placement": {"cell_x": 2, "cell_y": 2},
	}
	repository.call("add_object", door)
	if PassabilityRef.is_passable(Vector2i(2, 2), repository):
		errors.append("Closed door must block passage")
	repository.call("apply_patch", "door_1", {"state": "open"})
	if not PassabilityRef.is_passable(Vector2i(2, 2), repository):
		errors.append("Open door must be passable")
	return errors
