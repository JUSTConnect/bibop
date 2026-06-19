extends RefCounted

static func validate(document: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if int(document.get("version", 0)) <= 0:
		result.append("invalid version")
	if str(document.get("map_id", "")).is_empty():
		result.append("missing map_id")
	if not (document.get("grid", null) is Dictionary):
		result.append("invalid grid")
	if not (document.get("objects", null) is Array):
		result.append("invalid objects")
	if int(document.get("version", 0)) >= 3 and not (document.get("editor_state", null) is Dictionary):
		result.append("invalid editor_state")
	var ids: Dictionary = {}
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
	return result
