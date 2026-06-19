extends RefCounted

const MapDocumentRef = preload("res://scripts/map_constructor/map_document.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var snapshot: Dictionary = {
		"version": 1,
		"selected_definition_id": "terminal_basic",
		"selected_entity_id": "terminal_1",
		"active_tool_mode": "place",
		"next_instance_index": 2,
		"placed_objects": [{
			"id": "terminal_1",
			"definition_id": "terminal_basic",
			"links": {"power_source": "power_1"},
			"placement": {"cell_x": 1, "cell_y": 1},
		}],
	}
	var document: Dictionary = MapDocumentRef.from_edit_state(snapshot)
	var restored: Dictionary = MapDocumentRef.to_edit_snapshot(document)
	var objects: Array = Array(restored.get("placed_objects", []))
	if objects.size() != 1:
		errors.append("Document roundtrip lost objects")
	elif str(Dictionary(objects[0]).get("definition_id", "")) != "terminal_basic":
		errors.append("Document roundtrip lost definition_id")
	return errors
