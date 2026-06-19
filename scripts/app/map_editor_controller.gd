extends RefCounted

const MapEditStateRef = preload("res://scripts/map_constructor/map_edit_state.gd")

var state: RefCounted = null

func setup() -> void:
	state = MapEditStateRef.new()
	state.call("reset")

func set_tool(tool_mode: String) -> void:
	state.call("set_tool_mode", tool_mode)

func select_definition(definition_id: String) -> void:
	state.call("set_selected_definition", definition_id)

func handle_cell(cell: Vector2i, selected_definition: Dictionary) -> Dictionary:
	if str(state.get("active_tool_mode")) == "erase":
		var erased: Dictionary = Dictionary(state.call("erase_cell", cell))
		return {"kind": "erase", "data": erased, "cell": cell}
	var existed: bool = bool(state.call("has_instance_at_cell", cell))
	var data: Dictionary = Dictionary(state.call("place_or_select_cell", cell, selected_definition))
	return {"kind": "select" if existed else "place", "data": data, "cell": cell}

func clear_map_keep_palette() -> void:
	state.call("clear_map_keep_palette")

func patch_instance(instance_id: String, patch: Dictionary) -> Dictionary:
	return Dictionary(state.call("patch_instance", instance_id, patch))

func load_snapshot(snapshot: Dictionary) -> void:
	state.call("load_snapshot", snapshot)

func make_snapshot() -> Dictionary:
	return Dictionary(state.call("make_snapshot"))

func get_selected_instance_data() -> Dictionary:
	return Dictionary(state.call("get_selected_instance_data"))

func get_instance_data(instance_id: String) -> Dictionary:
	return Dictionary(state.call("get_instance_data", instance_id))

func get_placed_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(state.call("get_placed_objects")):
		result.append(Dictionary(value))
	return result

func get_instance_id_at_cell(cell: Vector2i) -> String:
	return str(state.call("get_instance_id_at_cell", cell))

func is_selected_instance(instance_id: String) -> bool:
	return bool(state.call("is_selected_instance", instance_id))

func selected_definition_id() -> String:
	return str(state.get("selected_definition_id"))

func selected_entity_kind() -> String:
	return str(state.get("selected_entity_kind"))

func selected_entity_id() -> String:
	return str(state.get("selected_entity_id"))

func selected_cell() -> Vector2i:
	return Vector2i(state.get("selected_cell"))

func active_tool_mode() -> String:
	return str(state.get("active_tool_mode"))
