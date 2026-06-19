extends RefCounted

const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")

static func make_snapshot(definitions_by_id: Dictionary) -> Dictionary:
	var power: Dictionary = _make_object(definitions_by_id, "power_source_basic", "power_source_basic_001", 1, 1)
	var cable: Dictionary = _make_object(definitions_by_id, "power_cable_basic", "power_cable_basic_002", 2, 1)
	var terminal: Dictionary = _make_object(definitions_by_id, "terminal_basic", "terminal_basic_003", 3, 1)
	var door: Dictionary = _make_object(definitions_by_id, "door_basic", "door_basic_004", 3, 2)
	terminal["links"] = {
		"power_source": str(power.get("id", "")),
		"controlled_targets": [str(door.get("id", ""))],
	}
	return {
		"version": 1,
		"selected_definition_id": "terminal_basic",
		"selected_entity_kind": "placed_object",
		"selected_entity_id": str(terminal.get("id", "")),
		"active_tool_mode": "place",
		"app_mode": "edit",
		"selected_cell": {"x": 3, "y": 1},
		"next_instance_index": 5,
		"placed_objects": [power, cable, terminal, door],
	}

static func _make_object(definitions_by_id: Dictionary, definition_id: String, instance_id: String, x: int, y: int) -> Dictionary:
	var definition: Dictionary = Dictionary(definitions_by_id.get(definition_id, {}))
	var data: Dictionary = ObjectDataFactoryRef.make_initial_object_data(definition)
	data["id"] = instance_id
	data["instance_id"] = instance_id
	data["definition_id"] = definition_id
	data["placement"] = {"cell_x": x, "cell_y": y}
	return data
