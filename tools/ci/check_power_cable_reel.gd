extends SceneTree
const Catalog = preload("res://scripts/world/world_object_catalog.gd")
func _init() -> void:
	var definition: Dictionary = Catalog.get_archetype_definition("power_cable_reel")
	quit(0 if str(definition.get("object_type", "")) == "power_cable_reel" else 1)
