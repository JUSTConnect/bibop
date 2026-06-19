extends RefCounted

const TOOL_PLACE := "place"
const TOOL_ERASE := "erase"
const MODE_EDIT := "edit"
const MODE_PLAY := "play"

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_entity_kind: String = ""
var selected_entity_id: String = ""
var selected_definition_id: String = ""
var active_tool_mode: String = TOOL_PLACE
var app_mode: String = MODE_EDIT
var next_instance_index: int = 1

func reset() -> void:
	selected_cell = Vector2i(-1, -1)
	selected_entity_kind = ""
	selected_entity_id = ""
	selected_definition_id = ""
	active_tool_mode = TOOL_PLACE
	app_mode = MODE_EDIT
	next_instance_index = 1

func select_definition(definition_id: String) -> void:
	selected_definition_id = definition_id
	selected_entity_kind = "definition_preview"
	selected_entity_id = definition_id
	selected_cell = Vector2i(-1, -1)

func select_instance(instance_id: String, cell: Vector2i) -> void:
	selected_entity_kind = "placed_object"
	selected_entity_id = instance_id
	selected_cell = cell

func clear_instance_selection() -> void:
	selected_entity_kind = "definition_preview" if not selected_definition_id.is_empty() else ""
	selected_entity_id = selected_definition_id
	selected_cell = Vector2i(-1, -1)

func make_snapshot() -> Dictionary:
	return {
		"selected_definition_id": selected_definition_id,
		"selected_entity_kind": selected_entity_kind,
		"selected_entity_id": selected_entity_id,
		"active_tool_mode": active_tool_mode,
		"app_mode": app_mode,
		"selected_cell": {"x": selected_cell.x, "y": selected_cell.y},
		"next_instance_index": next_instance_index,
	}

func load_snapshot(snapshot: Dictionary) -> void:
	selected_definition_id = str(snapshot.get("selected_definition_id", ""))
	selected_entity_kind = str(snapshot.get("selected_entity_kind", ""))
	selected_entity_id = str(snapshot.get("selected_entity_id", ""))
	active_tool_mode = str(snapshot.get("active_tool_mode", TOOL_PLACE))
	app_mode = str(snapshot.get("app_mode", MODE_EDIT))
	var cell: Dictionary = Dictionary(snapshot.get("selected_cell", {}))
	selected_cell = Vector2i(int(cell.get("x", -1)), int(cell.get("y", -1)))
	next_instance_index = int(snapshot.get("next_instance_index", 1))
