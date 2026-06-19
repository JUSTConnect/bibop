extends RefCounted

const VERSION := 2

static func from_edit_state(snapshot: Dictionary, map_id: String = "test_map") -> Dictionary:
	return {
		"version": VERSION,
		"map_id": map_id,
		"grid": {"columns": 6, "rows": 5},
		"selected_definition_id": str(snapshot.get("selected_definition_id", "")),
		"active_tool_mode": str(snapshot.get("active_tool_mode", "place")),
		"selected_entity_id": str(snapshot.get("selected_entity_id", "")),
		"next_instance_index": int(snapshot.get("next_instance_index", 1)),
		"objects": Array(snapshot.get("placed_objects", [])),
		"metadata": {},
	}

static func to_edit_snapshot(document: Dictionary) -> Dictionary:
	if int(document.get("version", 1)) < 2:
		return document
	return {
		"version": 1,
		"selected_definition_id": str(document.get("selected_definition_id", "")),
		"selected_entity_kind": "placed_object" if not str(document.get("selected_entity_id", "")).is_empty() else "definition_preview",
		"selected_entity_id": str(document.get("selected_entity_id", "")),
		"active_tool_mode": str(document.get("active_tool_mode", "place")),
		"selected_cell": {"x": -1, "y": -1},
		"next_instance_index": int(document.get("next_instance_index", 1)),
		"placed_objects": Array(document.get("objects", [])),
	}

static func is_valid(document: Dictionary) -> bool:
	return int(document.get("version", 0)) == VERSION and document.has("objects") and document.has("grid")
