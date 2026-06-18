extends RefCounted

# Target class: ItemVisualFactory
# Creates item visuals from ItemRenderModel.

static func create_visual(render_model: Dictionary) -> Node2D:
	var node := Sprite2D.new()
	node.name = str(render_model.get("id", "ItemVisual"))
	return node
