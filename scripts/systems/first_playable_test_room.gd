extends RefCounted

# FirstPlayableTestRoom
# Минимальный сценарий для системной проверки:
# Power Source -> Terminal -> Door.

static func make_objects(definitions_by_id: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var power := _make_object(definitions_by_id, "power_source_basic", "power_source_basic_001", 1, 2)
	var terminal := _make_object(definitions_by_id, "terminal_basic", "terminal_basic_002", 2, 2)
	var door := _make_object(definitions_by_id, "door_basic", "door_basic_003", 3, 2)
	terminal["links"] = {"power_source": power.get("id", ""), "controlled_targets": [door.get("id", "")]}
	result.append(power)
	result.append(terminal)
	result.append(door)
	return result

static func _make_object(definitions_by_id: Dictionary, definition_id: String, instance_id: String, x: int, y: int) -> Dictionary:
	var definition: Dictionary = Dictionary(definitions_by_id.get(definition_id, {}))
	var data: Dictionary = Dictionary(definition.get("base_parameters", {})).duplicate(true)
	data["id"] = instance_id
	data["instance_id"] = instance_id
	data["definition_id"] = definition_id
	data["object_type"] = str(definition.get("object_type", "object"))
	data["object_group"] = str(definition.get("object_group", "generic"))
	data["display_name"] = str(definition.get("display_name", definition_id))
	data["description"] = str(definition.get("description", ""))
	data["visual_id"] = str(definition.get("visual_id", ""))
	data["links"] = {}
	data["placement"] = {"cell_x": x, "cell_y": y}
	return data
