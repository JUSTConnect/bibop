extends RefCounted

static func migrate(source: Dictionary) -> Dictionary:
	return {
		"version": 3,
		"map_id": str(source.get("map_id", "migrated_map")),
		"grid": Dictionary(source.get("grid", {"columns": 6, "rows": 5})).duplicate(true),
		"objects": Array(source.get("objects", [])).duplicate(true),
		"editor_state": {
			"selected_definition_id": str(source.get("selected_definition_id", "")),
			"selected_entity_kind": "placed_object" if not str(source.get("selected_entity_id", "")).is_empty() else "definition_preview",
			"selected_entity_id": str(source.get("selected_entity_id", "")),
			"active_tool_mode": str(source.get("active_tool_mode", "place")),
			"app_mode": "edit",
			"selected_cell": {"x": -1, "y": -1},
			"next_instance_index": int(source.get("next_instance_index", 1)),
		},
		"metadata": Dictionary(source.get("metadata", {})).duplicate(true),
	}
