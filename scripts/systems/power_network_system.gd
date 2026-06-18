extends RefCounted

# PowerNetworkSystem
# Минимальная основа power circuit: source supplies circuit, consumers read circuit/power_source.

static func build_power_context(objects: Array[Dictionary]) -> Dictionary:
	var objects_by_id: Dictionary = {}
	var powered_circuits: Dictionary = {}
	for object_data in objects:
		var object_id := str(object_data.get("id", ""))
		if not object_id.is_empty():
			objects_by_id[object_id] = object_data
		if str(object_data.get("object_type", "")) == "power_source" and str(object_data.get("state", "on")).to_lower() != "off":
			var circuit_id := _get_circuit_id(object_data)
			if not circuit_id.is_empty():
				powered_circuits[circuit_id] = true
	return {"objects_by_id": objects_by_id, "powered_circuits": powered_circuits}

static func is_powered_by_context(object_data: Dictionary, context: Dictionary) -> bool:
	var links: Dictionary = Dictionary(object_data.get("links", {}))
	var power_source_id := str(links.get("power_source", ""))
	var objects_by_id: Dictionary = Dictionary(context.get("objects_by_id", {}))
	if not power_source_id.is_empty() and objects_by_id.has(power_source_id):
		var source: Dictionary = Dictionary(objects_by_id[power_source_id])
		return str(source.get("object_type", "")) == "power_source" and str(source.get("state", "on")).to_lower() != "off"
	var circuit_id := _get_circuit_id(object_data)
	if circuit_id.is_empty():
		return false
	return bool(Dictionary(context.get("powered_circuits", {})).get(circuit_id, false))

static func _get_circuit_id(object_data: Dictionary) -> String:
	var links: Dictionary = Dictionary(object_data.get("links", {}))
	if links.has("power_circuit"):
		return str(links.get("power_circuit", ""))
	return str(object_data.get("power_circuit", ""))
