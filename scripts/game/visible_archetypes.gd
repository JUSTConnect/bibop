extends RefCounted
class_name visible_archetypes

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

static func has(archetype_id: String) -> bool:
	return not WorldObjectCatalogRef.get_archetype_definition(archetype_id).is_empty()
