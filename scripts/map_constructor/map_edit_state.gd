extends RefCounted

# MapEditState
# Данные текущего состояния редактора карты.
# Не создаёт UI. Хранит выбранный palette definition, placed objects и selected instance.

const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")

const TOOL_PLACE := "place"
const TOOL_ERASE := "erase"

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_entity_kind: String = ""
var selected_entity_id: String = ""
var active_tool_mode: String = TOOL_PLACE
var active_inspector_tab_id: String = "objects"

var selected_definition_id: String = ""
var placed_objects_by_id: Dictionary = {}
var cell_to_instance_id: Dictionary = {}
var next_instance_index: int = 1

func reset() -> void:
	selected_cell = Vector2i(-1, -1)
	selected_entity_kind = ""
	selected_entity_id = ""
	selected_definition_id = ""
	active_tool_mode = TOOL_PLACE
	placed_objects_by_id.clear()
	cell_to_instance_id.clear()
	next_instance_index = 1


func clear_map_keep_palette() -> void:
	selected_cell = Vector2i(-1, -1)
	selected_entity_kind = "definition_preview" if not selected_definition_id.is_empty() else ""
	selected_entity_id = selected_definition_id
	placed_objects_by_id.clear()
	cell_to_instance_id.clear()
	next_instance_index = 1


func set_tool_mode(tool_mode: String) -> void:
	if tool_mode in [TOOL_PLACE, TOOL_ERASE]:
		active_tool_mode = tool_mode


func set_selected_definition(definition_id: String) -> void:
	selected_cell = Vector2i(-1, -1)
	selected_definition_id = definition_id
	selected_entity_kind = "definition_preview"
	selected_entity_id = definition_id


func clear_selected_instance() -> void:
	selected_cell = Vector2i(-1, -1)
	selected_entity_kind = "definition_preview" if not selected_definition_id.is_empty() else ""
	selected_entity_id = selected_definition_id


func place_or_select_cell(cell: Vector2i, definition: Dictionary) -> Dictionary:
	selected_cell = cell
	var key: String = _cell_key(cell)
	if cell_to_instance_id.has(key):
		select_instance(str(cell_to_instance_id[key]))
		return get_selected_instance_data()
	if definition.is_empty():
		return {}
	var instance_data: Dictionary = _make_instance_data(definition, cell)
	var instance_id: String = str(instance_data.get("id", ""))
	placed_objects_by_id[instance_id] = instance_data
	cell_to_instance_id[key] = instance_id
	select_instance(instance_id)
	return get_selected_instance_data()


func erase_cell(cell: Vector2i) -> Dictionary:
	var key: String = _cell_key(cell)
	if not cell_to_instance_id.has(key):
		return {}
	var instance_id: String = str(cell_to_instance_id[key])
	var erased_data: Dictionary = get_instance_data(instance_id)
	cell_to_instance_id.erase(key)
	placed_objects_by_id.erase(instance_id)
	if selected_entity_id == instance_id:
		clear_selected_instance()
	return erased_data


func select_instance(instance_id: String) -> void:
	if not placed_objects_by_id.has(instance_id):
		return
	selected_entity_kind = "placed_object"
	selected_entity_id = instance_id
	var data: Dictionary = Dictionary(placed_objects_by_id[instance_id])
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	selected_cell = Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))


func patch_selected_instance(patch: Dictionary) -> Dictionary:
	return patch_instance(selected_entity_id, patch)


func patch_instance(instance_id: String, patch: Dictionary) -> Dictionary:
	if not placed_objects_by_id.has(instance_id):
		return {}
	var data: Dictionary = Dictionary(placed_objects_by_id[instance_id]).duplicate(true)
	for key in patch.keys():
		data[key] = patch[key]
	data["power_state"] = ObjectDataFactoryRef.infer_power_state(data)
	placed_objects_by_id[instance_id] = data
	return data.duplicate(true)


func make_snapshot() -> Dictionary:
	return {
		"version": 1,
		"selected_definition_id": selected_definition_id,
		"selected_entity_kind": selected_entity_kind,
		"selected_entity_id": selected_entity_id,
		"active_tool_mode": active_tool_mode,
		"selected_cell": {"x": selected_cell.x, "y": selected_cell.y},
		"next_instance_index": next_instance_index,
		"placed_objects": get_placed_objects(),
	}


func load_snapshot(snapshot: Dictionary) -> void:
	clear_map_keep_palette()
	selected_definition_id = str(snapshot.get("selected_definition_id", selected_definition_id))
	active_tool_mode = str(snapshot.get("active_tool_mode", TOOL_PLACE))
	next_instance_index = int(snapshot.get("next_instance_index", 1))
	placed_objects_by_id.clear()
	cell_to_instance_id.clear()
	for placed_variant in Array(snapshot.get("placed_objects", [])):
		var placed_data: Dictionary = Dictionary(placed_variant).duplicate(true)
		var instance_id: String = str(placed_data.get("id", placed_data.get("instance_id", "")))
		if instance_id.is_empty():
			continue
		var placement: Dictionary = Dictionary(placed_data.get("placement", {}))
		var cell := Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))
		if cell.x < 0 or cell.y < 0:
			continue
		placed_objects_by_id[instance_id] = placed_data
		cell_to_instance_id[_cell_key(cell)] = instance_id
	var requested_selected_id: String = str(snapshot.get("selected_entity_id", ""))
	if placed_objects_by_id.has(requested_selected_id):
		select_instance(requested_selected_id)
	else:
		clear_selected_instance()


func get_selected_instance_data() -> Dictionary:
	return get_instance_data(selected_entity_id)


func get_instance_data(instance_id: String) -> Dictionary:
	return Dictionary(placed_objects_by_id.get(instance_id, {})).duplicate(true)


func get_instance_id_at_cell(cell: Vector2i) -> String:
	return str(cell_to_instance_id.get(_cell_key(cell), ""))


func has_instance_at_cell(cell: Vector2i) -> bool:
	return cell_to_instance_id.has(_cell_key(cell))


func get_placed_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance_id in placed_objects_by_id.keys():
		result.append(get_instance_data(str(instance_id)))
	return result


func is_selected_instance(instance_id: String) -> bool:
	return selected_entity_kind == "placed_object" and selected_entity_id == instance_id


func _make_instance_data(definition: Dictionary, cell: Vector2i) -> Dictionary:
	var data: Dictionary = ObjectDataFactoryRef.make_initial_object_data(definition)
	var definition_id: String = str(definition.get("id", "object"))
	var instance_id := "%s_%03d" % [definition_id, next_instance_index]
	next_instance_index += 1
	data["id"] = instance_id
	data["definition_id"] = definition_id
	data["instance_id"] = instance_id
	data["placement"] = {
		"cell_x": cell.x,
		"cell_y": cell.y,
	}
	data["display_name"] = "%s %03d" % [str(definition.get("display_name", definition_id)), next_instance_index - 1]
	return data


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
