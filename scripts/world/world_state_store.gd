extends RefCounted
class_name WorldStateStore

signal changed(change: Dictionary)

const STRUCTURAL_FIELDS := {"id": true, "position": true, "object_group": true, "object_type": true, "mount": true, "wall_side": true, "mount_side": true, "surface": true, "placement_mode": true, "placement": true, "is_wall_mounted": true}

var _objects_by_id: Dictionary = {}
var _object_order: Array[String] = []
var _floor_object_ids_by_cell: Dictionary = {}
var _item_ids_by_cell: Dictionary = {}
var _wall_mount_ids_by_cell: Dictionary = {}

func clear() -> void:
	_objects_by_id.clear()
	_object_order.clear()
	_floor_object_ids_by_cell.clear()
	_item_ids_by_cell.clear()
	_wall_mount_ids_by_cell.clear()
	changed.emit({"action": "clear", "warnings": []})

func replace_snapshot(objects: Array[Dictionary]) -> Dictionary:
	var seen: Dictionary = {}
	for object_data in objects:
		var object_id := _object_id(object_data)
		if object_id.is_empty():
			return _fail("empty_object_id")
		if seen.has(object_id):
			return _fail("duplicate_object_id")
		seen[object_id] = true
	clear()
	for object_data in objects:
		var stored := object_data.duplicate(true)
		var object_id := _object_id(stored)
		_objects_by_id[object_id] = stored
		_object_order.append(object_id)
	_rebuild_indexes()
	changed.emit({"action": "replace_snapshot", "warnings": [], "count": _object_order.size()})
	return _ok({"object_count": _object_order.size()})

func add_object(object_data: Dictionary) -> Dictionary:
	var object_id := _object_id(object_data)
	if object_id.is_empty():
		return _fail("empty_object_id")
	if _objects_by_id.has(object_id):
		return _fail("duplicate_object_id")
	var stored := object_data.duplicate(true)
	_objects_by_id[object_id] = stored
	_object_order.append(object_id)
	_index_object(object_id)
	changed.emit({"action": "add", "object_id": object_id, "current_cell": _cell(stored), "layer": _layer(stored), "warnings": []})
	return _ok({"object": stored})

func upsert_object(object_data: Dictionary) -> Dictionary:
	var object_id := _object_id(object_data)
	if object_id.is_empty():
		return _fail("empty_object_id")
	if not _objects_by_id.has(object_id):
		return add_object(object_data)
	_unindex_object(object_id)
	var stored := object_data.duplicate(true)
	_objects_by_id[object_id] = stored
	_index_object(object_id)
	changed.emit({"action": "upsert", "object_id": object_id, "current_cell": _cell(stored), "layer": _layer(stored), "warnings": []})
	return _ok({"object": stored})

func update_object_state(object_id: String, patch: Dictionary) -> Dictionary:
	if not _objects_by_id.has(object_id):
		return _fail("missing_object_id")
	for key in patch.keys():
		if STRUCTURAL_FIELDS.has(str(key)):
			return _fail("structural_field_patch")
	var object_data: Dictionary = _objects_by_id[object_id]
	for key in patch.keys():
		object_data[key] = patch[key]
	changed.emit({"action": "update_state", "object_id": object_id, "warnings": []})
	return _ok({"object": object_data})

func move_object(object_id: String, destination: Vector2i, structural_patch: Dictionary = {}) -> Dictionary:
	if not _objects_by_id.has(object_id):
		return _fail("missing_object_id")
	var object_data: Dictionary = _objects_by_id[object_id]
	var previous_cell := _cell(object_data)
	_unindex_object(object_id)
	object_data["position"] = destination
	for key in structural_patch.keys():
		object_data[key] = structural_patch[key]
	_index_object(object_id)
	changed.emit({"action": "move", "object_id": object_id, "previous_cell": previous_cell, "current_cell": destination, "layer": _layer(object_data), "warnings": []})
	return _ok({"object": object_data})

func remove_object_by_id(object_id: String) -> Dictionary:
	if not _objects_by_id.has(object_id):
		return _fail("missing_object_id")
	var removed: Dictionary = _objects_by_id[object_id]
	var previous_cell := _cell(removed)
	_unindex_object(object_id)
	_objects_by_id.erase(object_id)
	_object_order.erase(object_id)
	changed.emit({"action": "remove", "object_id": object_id, "previous_cell": previous_cell, "warnings": []})
	return _ok({"removed": removed})

func remove_object_at_cell(cell: Vector2i) -> Dictionary:
	var object_data := get_floor_object_at_cell(cell)
	if object_data.is_empty():
		return _fail("missing_object_at_cell")
	return remove_object_by_id(_object_id(object_data))

func add_item(cell: Vector2i, item_data: Dictionary) -> Dictionary:
	var stored := item_data.duplicate(true)
	stored["position"] = cell
	stored["object_group"] = "item"
	if str(stored.get("object_type", "")).strip_edges().is_empty():
		stored["object_type"] = "item"
	return add_object(stored)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var ids: Array = Array(_item_ids_by_cell.get(cell, []))
	if ids.is_empty():
		return _fail("missing_item_at_cell")
	return remove_object_by_id(str(ids[0]))

func has_object(object_id: String) -> bool:
	return _objects_by_id.has(object_id)

func get_object_by_id(object_id: String) -> Dictionary:
	return _objects_by_id.get(object_id, {})

func get_floor_object_at_cell(cell: Vector2i) -> Dictionary:
	var object_id := str(_floor_object_ids_by_cell.get(cell, ""))
	return get_object_by_id(object_id) if not object_id.is_empty() else {}

func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_id in Array(_item_ids_by_cell.get(cell, [])):
		var object_data := get_object_by_id(str(object_id))
		if not object_data.is_empty():
			result.append(object_data)
	return result

func get_wall_mounted_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_id in Array(_wall_mount_ids_by_cell.get(cell, [])):
		var object_data := get_object_by_id(str(object_id))
		if not object_data.is_empty():
			result.append(object_data)
	return result

func get_all_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_id in _object_order:
		if _objects_by_id.has(object_id):
			result.append(_objects_by_id[object_id])
	return result

func get_object_count() -> int:
	return _object_order.size()

func get_floor_lookup_snapshot() -> Dictionary:
	var result := {}
	for cell in _floor_object_ids_by_cell.keys():
		result[cell] = get_object_by_id(str(_floor_object_ids_by_cell[cell]))
	return result

func get_cell_items_snapshot() -> Dictionary:
	var result := {}
	for cell in _item_ids_by_cell.keys():
		result[cell] = get_items_at_cell(cell)
	return result

func get_wall_mount_lookup_snapshot() -> Dictionary:
	var result := {}
	for cell in _wall_mount_ids_by_cell.keys():
		result[cell] = get_wall_mounted_objects_at_cell(cell)
	return result

func validate_consistency() -> Array[String]:
	var warnings: Array[String] = []
	var order_seen := {}
	for object_id in _object_order:
		if str(object_id).strip_edges().is_empty(): warnings.append("empty_ordered_id")
		if order_seen.has(object_id): warnings.append("duplicate_ordered_id:%s" % object_id)
		order_seen[object_id] = true
		if not _objects_by_id.has(object_id): warnings.append("ordered_id_missing_object:%s" % object_id)
	for object_id in _objects_by_id.keys():
		var text_id := str(object_id)
		var object_data: Dictionary = _objects_by_id[object_id]
		if text_id.strip_edges().is_empty() or _object_id(object_data).is_empty(): warnings.append("empty_object_id")
		if not order_seen.has(text_id): warnings.append("object_missing_order:%s" % text_id)
		var layer := _layer(object_data)
		var cell := _cell(object_data)
		if layer == "item" and not Array(_item_ids_by_cell.get(cell, [])).has(text_id): warnings.append("item_missing_index:%s" % text_id)
		if layer == "wall" and not Array(_wall_mount_ids_by_cell.get(cell, [])).has(text_id): warnings.append("wall_missing_index:%s" % text_id)
		if layer == "floor" and str(_floor_object_ids_by_cell.get(cell, "")) != text_id: warnings.append("floor_missing_index:%s" % text_id)
		if layer != "item" and _id_in_index(_item_ids_by_cell, text_id): warnings.append("non_item_in_item_index:%s" % text_id)
		if layer != "wall" and _id_in_index(_wall_mount_ids_by_cell, text_id): warnings.append("non_wall_in_wall_index:%s" % text_id)
		if layer != "floor" and _floor_object_ids_by_cell.values().has(text_id): warnings.append("non_floor_in_floor_index:%s" % text_id)
	_validate_index_ids(_floor_object_ids_by_cell, warnings, false)
	_validate_index_ids(_item_ids_by_cell, warnings, true)
	_validate_index_ids(_wall_mount_ids_by_cell, warnings, true)
	return warnings

func get_diagnostic_snapshot() -> Dictionary:
	return {"object_ids": _object_order.duplicate(), "floor": _floor_object_ids_by_cell.duplicate(true), "items": _item_ids_by_cell.duplicate(true), "wall": _wall_mount_ids_by_cell.duplicate(true)}

func _index_object(object_id: String) -> void:
	var object_data: Dictionary = _objects_by_id.get(object_id, {})
	var cell := _cell(object_data)
	match _layer(object_data):
		"item":
			var ids: Array = Array(_item_ids_by_cell.get(cell, []))
			if not ids.has(object_id): ids.append(object_id)
			_item_ids_by_cell[cell] = ids
		"wall":
			var ids: Array = Array(_wall_mount_ids_by_cell.get(cell, []))
			if not ids.has(object_id): ids.append(object_id)
			_wall_mount_ids_by_cell[cell] = ids
		_:
			if not _floor_object_ids_by_cell.has(cell):
				_floor_object_ids_by_cell[cell] = object_id

func _unindex_object(object_id: String) -> void:
	for cell in _floor_object_ids_by_cell.keys().duplicate():
		if str(_floor_object_ids_by_cell[cell]) == object_id: _floor_object_ids_by_cell.erase(cell)
	_remove_from_multi_index(_item_ids_by_cell, object_id)
	_remove_from_multi_index(_wall_mount_ids_by_cell, object_id)

func _rebuild_indexes() -> void:
	_floor_object_ids_by_cell.clear(); _item_ids_by_cell.clear(); _wall_mount_ids_by_cell.clear()
	for object_id in _object_order:
		_index_object(object_id)

func _layer(object_data: Dictionary) -> String:
	if str(object_data.get("object_group", "")).to_lower() == "item": return "item"
	var placement := str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	var mount := str(object_data.get("mount", "")).strip_edges().to_lower()
	if placement == "wall_mounted" or mount in ["wall", "wall_mounted"] or bool(object_data.get("is_wall_mounted", false)): return "wall"
	return "floor"

func _cell(object_data: Dictionary) -> Vector2i:
	var raw: Variant = object_data.get("position", Vector2i(-1, -1))
	if raw is Vector2i: return raw
	if raw is Vector2: return Vector2i(int(raw.x), int(raw.y))
	if raw is Array and raw.size() >= 2: return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

func _object_id(object_data: Dictionary) -> String:
	return str(object_data.get("id", "")).strip_edges()

func _remove_from_multi_index(index: Dictionary, object_id: String) -> void:
	for cell in index.keys().duplicate():
		var ids: Array = Array(index[cell])
		ids.erase(object_id)
		if ids.is_empty(): index.erase(cell)
		else: index[cell] = ids

func _id_in_index(index: Dictionary, object_id: String) -> bool:
	for ids in index.values():
		if Array(ids).has(object_id): return true
	return false

func _validate_index_ids(index: Dictionary, warnings: Array[String], multi: bool) -> void:
	for cell in index.keys():
		var ids: Array = Array(index[cell]) if multi else [str(index[cell])]
		for object_id in ids:
			if not _objects_by_id.has(str(object_id)): warnings.append("stale_index_id:%s" % str(object_id))
			elif _cell(_objects_by_id[str(object_id)]) != cell: warnings.append("wrong_index_cell:%s" % str(object_id))

func _ok(extra: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "warnings": []}
	for key in extra.keys(): result[key] = extra[key]
	return result

func _fail(reason: String, warnings: Array[String] = []) -> Dictionary:
	return {"ok": false, "reason": reason, "warnings": warnings}
