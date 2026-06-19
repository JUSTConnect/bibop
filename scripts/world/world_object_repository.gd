extends RefCounted

signal object_added(instance_id: String)
signal object_removed(instance_id: String)
signal object_changed(instance_id: String)
signal world_replaced()

var objects_by_id: Dictionary = {}
var cell_to_id: Dictionary = {}

func clear() -> void:
	objects_by_id.clear()
	cell_to_id.clear()
	world_replaced.emit()

func replace_all(objects: Array[Dictionary]) -> void:
	objects_by_id.clear()
	cell_to_id.clear()
	for data: Dictionary in objects:
		_register(data)
	world_replaced.emit()

func add_object(data: Dictionary) -> bool:
	var instance_id: String = str(data.get("id", data.get("instance_id", "")))
	if instance_id.is_empty() or objects_by_id.has(instance_id):
		return false
	var cell: Vector2i = _read_cell(data)
	if cell.x >= 0 and cell.y >= 0 and cell_to_id.has(_cell_key(cell)):
		return false
	_register(data)
	object_added.emit(instance_id)
	return true

func remove_object(instance_id: String) -> Dictionary:
	if not objects_by_id.has(instance_id):
		return {}
	var data: Dictionary = get_object(instance_id)
	var cell: Vector2i = _read_cell(data)
	if cell.x >= 0 and cell.y >= 0:
		cell_to_id.erase(_cell_key(cell))
	objects_by_id.erase(instance_id)
	object_removed.emit(instance_id)
	return data

func apply_patch(instance_id: String, patch: Dictionary) -> Dictionary:
	if not objects_by_id.has(instance_id):
		return {}
	var data: Dictionary = get_object(instance_id)
	var old_cell: Vector2i = _read_cell(data)
	for key: Variant in patch.keys():
		data[key] = patch[key]
	var new_cell: Vector2i = _read_cell(data)
	if old_cell != new_cell:
		if old_cell.x >= 0 and old_cell.y >= 0:
			cell_to_id.erase(_cell_key(old_cell))
		if new_cell.x >= 0 and new_cell.y >= 0:
			cell_to_id[_cell_key(new_cell)] = instance_id
	objects_by_id[instance_id] = data
	object_changed.emit(instance_id)
	return data.duplicate(true)

func get_object(instance_id: String) -> Dictionary:
	return Dictionary(objects_by_id.get(instance_id, {})).duplicate(true)

func get_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance_id: Variant in objects_by_id.keys():
		result.append(get_object(str(instance_id)))
	return result

func get_object_at_cell(cell: Vector2i) -> Dictionary:
	return get_object(str(cell_to_id.get(_cell_key(cell), "")))

func get_id_at_cell(cell: Vector2i) -> String:
	return str(cell_to_id.get(_cell_key(cell), ""))

func has_object_at_cell(cell: Vector2i) -> bool:
	return cell_to_id.has(_cell_key(cell))

func _register(data: Dictionary) -> void:
	var copy: Dictionary = data.duplicate(true)
	var instance_id: String = str(copy.get("id", copy.get("instance_id", "")))
	if instance_id.is_empty():
		return
	copy["id"] = instance_id
	copy["instance_id"] = instance_id
	objects_by_id[instance_id] = copy
	var cell: Vector2i = _read_cell(copy)
	if cell.x >= 0 and cell.y >= 0:
		cell_to_id[_cell_key(cell)] = instance_id

func _read_cell(data: Dictionary) -> Vector2i:
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	return Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
