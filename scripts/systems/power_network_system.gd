extends RefCounted

const PowerGraphRef = preload("res://scripts/power/power_graph.gd")
const PowerSolverRef = preload("res://scripts/power/power_network_solver.gd")

static func build_power_context(objects: Array[Dictionary]) -> Dictionary:
	var objects_by_id: Dictionary = {}
	for data: Dictionary in objects:
		var object_id: String = str(data.get("id", ""))
		if not object_id.is_empty():
			objects_by_id[object_id] = data
	var graph: Dictionary = PowerGraphRef.build(objects)
	var solved: Dictionary = PowerSolverRef.solve(graph)
	return {
		"objects_by_id": objects_by_id,
		"powered_by_id": Dictionary(solved.get("powered_by_id", {})),
		"circuit_by_id": Dictionary(solved.get("circuit_by_id", {})),
		"connections": Array(graph.get("connections", [])),
	}

static func is_powered_by_context(object_data: Dictionary, context: Dictionary) -> bool:
	var object_id: String = str(object_data.get("id", ""))
	var powered_by_id: Dictionary = Dictionary(context.get("powered_by_id", {}))
	if powered_by_id.has(object_id) and bool(powered_by_id[object_id]):
		return true
	return _legacy_direct_power(object_data, Dictionary(context.get("objects_by_id", {})))

static func get_circuit_id(object_id: String, context: Dictionary) -> String:
	return str(Dictionary(context.get("circuit_by_id", {})).get(object_id, ""))

static func _legacy_direct_power(object_data: Dictionary, objects_by_id: Dictionary) -> bool:
	var links: Dictionary = Dictionary(object_data.get("links", {}))
	var source_id: String = str(links.get("power_source", ""))
	if source_id.is_empty() or not objects_by_id.has(source_id):
		return false
	var source: Dictionary = Dictionary(objects_by_id[source_id])
	return str(source.get("object_type", "")) == "power_source" and str(source.get("state", "on")).to_lower() != "off"
