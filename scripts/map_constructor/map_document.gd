extends RefCounted

const VERSION := 3

static func from_edit_state(snapshot: Dictionary, map_id: String = "test_map") -> Dictionary:
	var editor_state: Dictionary = {
		"selected_definition_id": str(snapshot.get("selected_definition_id", "")),
		"selected_entity_kind": str(snapshot.get("selected_entity_kind", "definition_preview")),
		"selected_entity_id": str(snapshot.get("selected_entity_id", "")),
		"active_tool_mode": str(snapshot.get("active_tool_mode", "place")),
		"app_mode": str(snapshot.get("app_mode", "edit")),
		"selected_cell": Dictionary(snapshot.get("selected_cell", {"x": -1, "y": -1})),
		"next_instance_index": int(snapshot.get("next_instance_index", 1)),
	}
	return {
		"version": VERSION,
		"map_id": map_id,
		"grid": {"columns": 6, "rows": 5},
		"objects": Array(snapshot.get("placed_objects", snapshot.get("objects", []))).duplicate(true),
		"editor_state": editor_state,
		"metadata": Dictionary(snapshot.get("metadata", {})).duplicate(true),
	}

static func to_edit_snapshot(document: Dictionary) -> Dictionary:
	var editor_state: Dictionary = Dictionary(document.get("editor_state", {}))
	return {
		"version": 1,
		"selected_definition_id": str(editor_state.get("selected_definition_id", "")),
		"selected_entity_kind": str(editor_state.get("selected_entity_kind", "definition_preview")),
		"selected_entity_id": str(editor_state.get("selected_entity_id", "")),
		"active_tool_mode": str(editor_state.get("active_tool_mode", "place")),
		"app_mode": str(editor_state.get("app_mode", "edit")),
		"selected_cell": Dictionary(editor_state.get("selected_cell", {"x": -1, "y": -1})),
		"next_instance_index": int(editor_state.get("next_instance_index", 1)),
		"placed_objects": Array(document.get("objects", [])).duplicate(true),
	}

static func is_valid(document: Dictionary) -> bool:
	return int(document.get("version", 0)) == VERSION and document.has("objects") and document.has("grid") and document.has("editor_state")
