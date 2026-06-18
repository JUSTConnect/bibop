extends RefCounted

# Target class: ObjectPlacementSystem
# Placement validation and commands for objects/items/floor/walls.

var repository: RefCounted = null

func can_place_object(_definition_id: String, _cell: Vector2i) -> Dictionary:
	return {"ok": true, "message": "Can place object."}

func place_object(definition_id: String, cell: Vector2i, config: Dictionary = {}) -> Dictionary:
	return {"ok": true, "message": "Object placed.", "definition_id": definition_id, "cell": cell, "config": config}
