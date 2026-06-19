extends RefCounted

static func solve(graph: Dictionary) -> Dictionary:
	var nodes_by_id: Dictionary = Dictionary(graph.get("nodes_by_id", {}))
	var adjacency: Dictionary = Dictionary(graph.get("adjacency", {}))
	var visited: Dictionary = {}
	var powered_by_id: Dictionary = {}
	var circuit_by_id: Dictionary = {}
	var circuit_index: int = 0
	for object_id_value: Variant in nodes_by_id.keys():
		var object_id: String = str(object_id_value)
		if visited.has(object_id):
			continue
		var component: Array[String] = _collect_component(object_id, adjacency, visited)
		var powered: bool = _component_has_active_source(component, nodes_by_id)
		var circuit_id: String = "circuit_%03d" % circuit_index
		circuit_index += 1
		for member_id: String in component:
			powered_by_id[member_id] = powered
			circuit_by_id[member_id] = circuit_id
	return {"powered_by_id": powered_by_id, "circuit_by_id": circuit_by_id}

static func _collect_component(start_id: String, adjacency: Dictionary, visited: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var frontier: Array[String] = [start_id]
	visited[start_id] = true
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		result.append(current)
		for neighbor_value: Variant in Array(adjacency.get(current, [])):
			var neighbor: String = str(neighbor_value)
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			frontier.append(neighbor)
	return result

static func _component_has_active_source(component: Array[String], nodes_by_id: Dictionary) -> bool:
	for object_id: String in component:
		var node: RefCounted = nodes_by_id[object_id]
		if bool(node.get("source_active")):
			return true
	return false
