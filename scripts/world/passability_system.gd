extends RefCounted

const PassabilityResultRef = preload("res://scripts/world/passability_result.gd")

static func can_enter_cell(cell: Vector2i, repository: RefCounted) -> RefCounted:
	var object_id: String = str(repository.call("get_id_at_cell", cell))
	if object_id.is_empty():
		return PassabilityResultRef.allow()
	var data: Dictionary = Dictionary(repository.call("get_object", object_id))
	return evaluate_object(data)

static func evaluate_object(data: Dictionary) -> RefCounted:
	var object_id: String = str(data.get("id", ""))
	var object_type: String = str(data.get("object_type", ""))
	if object_type == "power_cable":
		return PassabilityResultRef.allow()
	if object_type == "door":
		return _evaluate_door(data, object_id)
	if not bool(data.get("occupies_cell", true)):
		return PassabilityResultRef.allow()
	var mode: String = str(data.get("passability_mode", "solid"))
	if mode == "passable":
		return PassabilityResultRef.allow()
	return PassabilityResultRef.block(mode, object_id)

static func _evaluate_door(data: Dictionary, object_id: String) -> RefCounted:
	var state: String = str(data.get("state", "closed")).to_lower()
	if state == "open":
		return PassabilityResultRef.allow()
	if state == "destroyed":
		return PassabilityResultRef.allow()
	if state == "jammed" or bool(data.get("jammed", false)):
		return PassabilityResultRef.block("door_jammed", object_id)
	if bool(data.get("damaged", false)):
		return PassabilityResultRef.block("door_damaged", object_id)
	return PassabilityResultRef.block("door_closed", object_id)

static func is_passable(cell: Vector2i, repository: RefCounted) -> bool:
	var result: RefCounted = can_enter_cell(cell, repository)
	return bool(result.get("passable"))
