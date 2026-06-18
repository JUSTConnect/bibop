extends RefCounted

# Target class: ObjectVisualFactory
# Creates object visuals from ObjectRenderModel and visual catalog.

static func create_visual(render_model: Dictionary) -> Node2D:
	var node := Sprite2D.new()
	node.name = str(render_model.get("id", "ObjectVisual"))
	return node
