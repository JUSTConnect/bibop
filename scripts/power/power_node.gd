extends RefCounted

var object_id: String = ""
var cell: Vector2i = Vector2i(-1, -1)
var node_type: String = ""
var source_active: bool = false

static func from_object(data: Dictionary) -> RefCounted:
	var node: RefCounted = new()
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	var object_type: String = str(data.get("object_type", ""))
	node.set("object_id", str(data.get("id", "")))
	node.set("cell", Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1))))
	node.set("node_type", object_type)
	node.set("source_active", object_type == "power_source" and str(data.get("state", "on")).to_lower() != "off")
	return node
