extends RefCounted

const EditorStateRef = preload("res://scripts/map_constructor/editor_state.gd")
const WorldRepositoryRef = preload("res://scripts/world/world_object_repository.gd")
const ObjectDataFactoryRef = preload("res://scripts/domain/object_data_factory.gd")
const ObjectConfigSchemaRef = preload("res://scripts/domain/object_config_schema.gd")

var state: RefCounted = null
var repository: RefCounted = null

func setup() -> void:
	state = EditorStateRef.new()
	repository = WorldRepositoryRef.new()
	state.call("reset")

func set_tool(tool_mode: String) -> void:
	if tool_mode in ["place", "erase"]:
		state.set("active_tool_mode", tool_mode)

func set_app_mode(mode: String) -> void:
	if mode in ["edit", "play"]:
		state.set("app_mode", mode)

func select_definition(definition_id: String) -> void:
	state.call("select_definition", definition_id)

func handle_cell(cell: Vector2i, selected_definition: Dictionary) -> Dictionary:
	if app_mode() != "edit":
		var selected_id: String = get_instance_id_at_cell(cell)
		if not selected_id.is_empty():
			_select_instance(selected_id)
		return {"kind": "select", "data": get_instance_data(selected_id), "cell": cell}
	if active_tool_mode() == "erase":
		var erased: Dictionary = erase_cell(cell)
		return {"kind": "erase", "data": erased, "cell": cell}
	var existing_id: String = get_instance_id_at_cell(cell)
	if not existing_id.is_empty():
		_select_instance(existing_id)
		return {"kind": "select", "data": get_instance_data(existing_id), "cell": cell}
	var placed: Dictionary = place_object(cell, selected_definition)
	return {"kind": "place", "data": placed, "cell": cell}

func place_object(cell: Vector2i, definition: Dictionary) -> Dictionary:
	if definition.is_empty() or repository.call("has_object_at_cell", cell):
		return {}
	var data: Dictionary = ObjectDataFactoryRef.make_initial_object_data(definition)
	var definition_id: String = str(definition.get("id", "object"))
	var index: int = int(state.get("next_instance_index"))
	var instance_id: String = "%s_%03d" % [definition_id, index]
	state.set("next_instance_index", index + 1)
	data["id"] = instance_id
	data["instance_id"] = instance_id
	data["definition_id"] = definition_id
	data["placement"] = {"cell_x": cell.x, "cell_y": cell.y}
	data["display_name"] = "%s %03d" % [str(definition.get("display_name", definition_id)), index]
	if not bool(repository.call("add_object", data)):
		return {}
	state.call("select_instance", instance_id, cell)
	return repository.call("get_object", instance_id)

func erase_cell(cell: Vector2i) -> Dictionary:
	var instance_id: String = get_instance_id_at_cell(cell)
	if instance_id.is_empty():
		return {}
	var removed: Dictionary = Dictionary(repository.call("remove_object", instance_id))
	if selected_entity_id() == instance_id:
		state.call("clear_instance_selection")
	return removed

func clear_map_keep_palette() -> void:
	repository.call("clear")
	state.call("clear_instance_selection")
	state.set("next_instance_index", 1)

func patch_instance(instance_id: String, patch: Dictionary) -> Dictionary:
	var data: Dictionary = get_instance_data(instance_id)
	if data.is_empty():
		return {}
	var normalized: Dictionary = patch.duplicate(true)
	var base_config: Dictionary = Dictionary(data.get("base_config", {}))
	var overrides: Dictionary = Dictionary(data.get("config_overrides", {})).duplicate(true)
	for key_value: Variant in patch.keys():
		var key: String = str(key_value)
		if not base_config.has(key) and not overrides.has(key):
			continue
		var value: Variant = patch[key_value]
		var base_value: Variant = base_config.get(key)
		if ObjectConfigSchemaRef.values_equal(value, base_value):
			overrides.erase(key)
			normalized[key] = base_value
		else:
			overrides[key] = value
	normalized["config_overrides"] = overrides
	return Dictionary(repository.call("apply_patch", instance_id, normalized))

func load_snapshot(snapshot: Dictionary) -> void:
	var objects: Array[Dictionary] = []
	for value: Variant in Array(snapshot.get("placed_objects", snapshot.get("objects", []))):
		objects.append(Dictionary(value))
	repository.call("replace_all", objects)
	state.call("load_snapshot", snapshot)
	var selected_id: String = selected_entity_id()
	if not selected_id.is_empty() and get_instance_data(selected_id).is_empty():
		state.call("clear_instance_selection")

func make_snapshot() -> Dictionary:
	var snapshot: Dictionary = Dictionary(state.call("make_snapshot"))
	snapshot["version"] = 1
	snapshot["placed_objects"] = get_placed_objects()
	return snapshot

func get_selected_instance_data() -> Dictionary:
	return get_instance_data(selected_entity_id())

func get_instance_data(instance_id: String) -> Dictionary:
	return Dictionary(repository.call("get_object", instance_id))

func get_placed_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(repository.call("get_objects")):
		result.append(Dictionary(value))
	return result

func get_instance_id_at_cell(cell: Vector2i) -> String:
	return str(repository.call("get_id_at_cell", cell))

func has_instance_at_cell(cell: Vector2i) -> bool:
	return bool(repository.call("has_object_at_cell", cell))

func is_selected_instance(instance_id: String) -> bool:
	return selected_entity_kind() == "placed_object" and selected_entity_id() == instance_id

func selected_definition_id() -> String:
	return str(state.get("selected_definition_id"))

func selected_entity_kind() -> String:
	return str(state.get("selected_entity_kind"))

func selected_entity_id() -> String:
	return str(state.get("selected_entity_id"))

func selected_cell() -> Vector2i:
	var value: Variant = state.get("selected_cell")
	return value if value is Vector2i else Vector2i(-1, -1)

func active_tool_mode() -> String:
	return str(state.get("active_tool_mode"))

func app_mode() -> String:
	return str(state.get("app_mode"))

func _select_instance(instance_id: String) -> void:
	var data: Dictionary = get_instance_data(instance_id)
	var placement: Dictionary = Dictionary(data.get("placement", {}))
	var cell := Vector2i(int(placement.get("cell_x", -1)), int(placement.get("cell_y", -1)))
	state.call("select_instance", instance_id, cell)
