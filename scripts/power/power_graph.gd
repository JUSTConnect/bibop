extends RefCounted

const PowerNodeRef = preload("res://scripts/power/power_node.gd")
const PowerConnectionRef = preload("res://scripts/power/power_connection.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

static func build(objects: Array[Dictionary]) -> Dictionary:
	var nodes_by_id: Dictionary = {}
	var id_by_cell: Dictionary = {}
	for data: Dictionary in objects:
		if not _is_power_node(data):
			continue
		var node: RefCounted = PowerNodeRef.from_object(data)
		var object_id: String = str(node.get("object_id"))
		var cell_value: Variant = node.get("cell")
		var cell: Vector2i = cell_value if cell_value is Vector2i else Vector2i(-1, -1)
		if object_id.is_empty() or cell.x < 0 or cell.y < 0:
			continue
		nodes_by_id[object_id] = node
		id_by_cell[_cell_key(cell)] = object_id
	var adjacency: Dictionary = {}
	var connections: Array[RefCounted] = []
	for object_id_value: Variant in nodes_by_id.keys():
		var object_id: String = str(object_id_value)
		var neighbors: Array[String] = []
		var node: RefCounted = nodes_by_id[object_id]
		var cell_value: Variant = node.get("cell")
		var cell: Vector2i = cell_value if cell_value is Vector2i else Vector2i(-1, -1)
		for direction: Vector2i in DIRECTIONS:
			var neighbor_id: String = str(id_by_cell.get(_cell_key(cell + direction), ""))
			if neighbor_id.is_empty() or neighbor_id == object_id:
				continue
			neighbors.append(neighbor_id)
			if object_id < neighbor_id:
				connections.append(PowerConnectionRef.make(object_id, neighbor_id))
		adjacency[object_id] = neighbors
	return {"nodes_by_id": nodes_by_id, "adjacency": adjacency, "connections": connections}

static func _is_power_node(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", ""))
	if object_type in ["power_source", "power_cable"]:
		return true
	return str(data.get("power_mode", "none")).to_lower() == "external"

static func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
