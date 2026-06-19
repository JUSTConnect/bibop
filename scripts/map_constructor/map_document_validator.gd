extends RefCounted

static func validate(document: Dictionary, known_definition_ids: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	var version: int = int(document.get("version", 0))
	if version <= 0:
		result.append("invalid version")
	if str(document.get("map_id", "")).is_empty():
		result.append("missing map_id")
	if not (document.get("grid", null) is Dictionary):
		result.append("invalid grid")
	if not (document.get("objects", null) is Array):
		result.append("invalid objects")
	if version >= 3 and not (document.get("editor_state", null) is Dictionary):
		result.append("invalid editor_state")
	var grid: Dictionary = Dictionary(document.get("grid", {}))
	var columns: int = int(grid.get("columns", 0))
	var rows: int = int(grid.get("rows", 0))
	if columns <= 0 or rows <= 0:
		result.append("invalid grid size")
	var ids: Dictionary = {}
	var cells: Dictionary = {}
	for item: Variant in Array(document.get("objects", [])):
		if not (item is Dictionary):
			result.append("invalid object entry")
			continue
		var data: Dictionary = Dictionary(item)
		var object_id: String = str(data.get("id", data.get("instance_id", "")))
		if object_id.is_empty():
			result.append("missing object id")
		elif ids.has(object_id):
			result.append("duplicate object id: %s" % object_id)
		ids[object_id] = true
		var definition_id: String = str(data.get("definition_id", ""))
		if definition_id.is_empty():
			result.append("missing definition id: %s" % object_id)
		elif not known_definition_ids.is_empty() and not known_definition_ids.has(definition_id):
			result.append("unknown definition id: %s" % definition_id)
		_validate_placement(data, object_id, columns, rows, cells, result)
	return result

static func _validate_placement(data: Dictionary, object_id: String, columns: int, rows: int, cells: Dictionary, errors: Array[String]) -> void:
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	var x: int = int(placement.get("cell_x", -1))
	var y: int = int(placement.get("cell_y", -1))
	if x < 0 or y < 0 or x >= columns or y >= rows:
		errors.append("object outside grid: %s" % object_id)
		return
	var key: String = "%d:%d" % [x, y]
	if cells.has(key):
		errors.append("duplicate occupied cell: %s" % key)
	cells[key] = object_id
