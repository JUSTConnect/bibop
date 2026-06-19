extends RefCounted

static func migrate(source: Dictionary) -> Dictionary:
	return {
		"version": 2,
		"map_id": str(source.get("map_id", "migrated_map")),
		"grid": Dictionary(source.get("grid", {"columns": 6, "rows": 5})),
		"selected_definition_id": str(source.get("selected_definition_id", "")),
		"selected_entity_id": str(source.get("selected_entity_id", "")),
		"active_tool_mode": str(source.get("active_tool_mode", "place")),
		"next_instance_index": int(source.get("next_instance_index", 1)),
		"objects": Array(source.get("placed_objects", source.get("objects", []))).duplicate(true),
		"metadata": Dictionary(source.get("metadata", {})).duplicate(true),
	}
