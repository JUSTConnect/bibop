extends RefCounted

static func index_by_id(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for data: Dictionary in objects:
		var instance_id: String = str(data.get("id", ""))
		if not instance_id.is_empty():
			result[instance_id] = data
	return result

static func filter_by_type(objects: Array[Dictionary], object_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data: Dictionary in objects:
		if str(data.get("object_type", "")) == object_type:
			result.append(data.duplicate(true))
	return result

static func find_by_definition(objects: Array[Dictionary], definition_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data: Dictionary in objects:
		if str(data.get("definition_id", "")) == definition_id:
			result.append(data.duplicate(true))
	return result
