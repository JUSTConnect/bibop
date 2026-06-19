extends RefCounted

var object_id: String = ""
var cell: Vector2i = Vector2i(-1, -1)
var node_type: String = ""
var source_active: bool = false

static func from_object(data: Dictionary) -> RefCounted:
	var node := new()
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	node.object_id = str(data.get("id", ""))
	node.cell = Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))
	node.node_type = str(data.get("object_type", ""))
	node.source_active = node.node_type == "power_source" and str(data.get("state", "on")).to_lower() != "off"
	return node
