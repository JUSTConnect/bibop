extends RefCounted

var object_id_by_cell: Dictionary = {}

func rebuild(objects: Array[Dictionary]) -> void:
	object_id_by_cell.clear()
	for data: Dictionary in objects:
		var placement: Dictionary = Dictionary(data.get("placement", {}))
		var cell := Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))
		if cell.x >= 0 and cell.y >= 0:
			object_id_by_cell[_cell_key(cell)] = str(data.get("id", ""))

func get_object_id(cell: Vector2i) -> String:
	return str(object_id_by_cell.get(_cell_key(cell), ""))

func is_occupied(cell: Vector2i) -> bool:
	return object_id_by_cell.has(_cell_key(cell))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
