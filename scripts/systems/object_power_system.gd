extends RefCounted

# ObjectPowerSystem
# Вычисляет derived power_state из текущего world state и object links.
# UI не должен сам решать, powered объект или нет.

static func evaluate_all(objects: Array[Dictionary]) -> Array[Dictionary]:
	var objects_by_id: Dictionary = _index_objects_by_id(objects)
	var patches: Array[Dictionary] = []
	for object_data in objects:
		var object_id: String = str(object_data.get("id", ""))
		if object_id.is_empty():
			continue
		var next_power_state: String = evaluate_power_state(object_data, objects_by_id)
		if next_power_state.is_empty():
			continue
		if str(object_data.get("power_state", "")) != next_power_state:
			patches.append({"instance_id": object_id, "patch": {"power_state": next_power_state}})
	return patches


static func evaluate_power_state(object_data: Dictionary, objects_by_id: Dictionary) -> String:
	var object_type: String = str(object_data.get("object_type", ""))
	var power_mode: String = str(object_data.get("power_mode", "none")).to_lower()
	if object_type == "power_source":
		return "unpowered" if str(object_data.get("state", "on")).to_lower() == "off" else "powered"
	if power_mode == "none":
		return "none"
	if power_mode == "source":
		return "powered"
	if power_mode == "external":
		return _evaluate_external_power(object_data, objects_by_id)
	return str(object_data.get("power_state", "none"))


static func _evaluate_external_power(object_data: Dictionary, objects_by_id: Dictionary) -> String:
	var links: Dictionary = Dictionary(object_data.get("links", {}))
	var power_source_id: String = str(links.get("power_source", ""))
	if power_source_id.is_empty() or not objects_by_id.has(power_source_id):
		return "unpowered"
	var source: Dictionary = Dictionary(objects_by_id[power_source_id])
	if str(source.get("object_type", "")) != "power_source":
		return "unpowered"
	return "unpowered" if str(source.get("state", "on")).to_lower() == "off" else "powered"


static func _index_objects_by_id(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var object_id: String = str(object_data.get("id", ""))
		if not object_id.is_empty():
			result[object_id] = object_data
	return result
