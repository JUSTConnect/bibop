extends RefCounted

const PaletteControllerRef = preload("res://scripts/app/palette_controller.gd")
const MapEditorControllerRef = preload("res://scripts/app/map_editor_history_controller.gd")
const InspectorControllerRef = preload("res://scripts/app/play_safe_inspector_controller.gd")
const RuntimeControllerRef = preload("res://scripts/app/world_runtime_controller.gd")
const AppLayoutBuilderRef = preload("res://scripts/app/app_layout_builder.gd")
const MapDocumentStoreRef = preload("res://scripts/map_constructor/map_document_store.gd")
const TestRoomRef = preload("res://scripts/systems/first_playable_test_room.gd")
const AppModeControllerRef = preload("res://scripts/app/app_mode_controller.gd")
const EditModeControllerRef = preload("res://scripts/app/edit_mode_controller.gd")
const PlayModeControllerRef = preload("res://scripts/app/play_mode_controller.gd")
const WorldSessionRef = preload("res://scripts/world/world_session.gd")
const AgentControllerRef = preload("res://scripts/agents/test_agent_controller.gd")
const AgentVisualRef = preload("res://scripts/rendering/test_agent_visual.gd")
const ObjectVisualFactoryRef = preload("res://scripts/rendering/object_visual_factory.gd")
const ActionExecutorRef = preload("res://scripts/interactions/object_action_executor.gd")

const DEFINITION_PATHS: Array[String] = [
	"res://data/objects/power_source_basic.json",
	"res://data/objects/terminal_basic.json",
	"res://data/objects/door_basic.json",
	"res://data/objects/power_cable_basic.json",
]
const MAP_COLUMNS := 6
const MAP_ROWS := 5
const AGENT_START := Vector2i(0, 2)
const AGENT_GOAL := Vector2i(5, 2)

var root: Control
var palette: RefCounted
var map_editor: RefCounted
var inspector: RefCounted
var runtime: RefCounted
var mode_controller: RefCounted
var edit_mode_controller: RefCounted
var play_mode_controller: RefCounted
var world_session: RefCounted
var agent: RefCounted

var object_list: VBoxContainer
var map_canvas: Control
var selected_palette_label: Label
var tool_mode_label: Label
var app_mode_label: Label
var inspector_content: VBoxContainer
var status_label: Label

func setup(new_root: Control) -> void:
	root = new_root
	palette = PaletteControllerRef.new()
	map_editor = MapEditorControllerRef.new()
	inspector = InspectorControllerRef.new()
	runtime = RuntimeControllerRef.new()
	mode_controller = AppModeControllerRef.new()
	edit_mode_controller = EditModeControllerRef.new()
	play_mode_controller = PlayModeControllerRef.new()
	world_session = WorldSessionRef.new()
	agent = AgentControllerRef.new()
	map_editor.call("setup")
	palette.call("load_paths", DEFINITION_PATHS)
	_build_layout()
	inspector.call("setup", inspector_content, palette, map_editor, Callable(self, "_refresh_world"), Callable(self, "_set_status"), Callable(self, "_execute_action"))
	_select_palette(0)
	_reset_agent()
	_update_labels()

func _build_layout() -> void:
	var refs: Dictionary = AppLayoutBuilderRef.build(root, {
		"reload": Callable(self, "_reload"),
		"test_room": Callable(self, "_load_test_room"),
		"place": Callable(self, "_place_tool"),
		"erase": Callable(self, "_erase_tool"),
		"use": Callable(self, "_use_selected"),
		"undo": Callable(self, "_undo"),
		"redo": Callable(self, "_redo"),
		"clear": Callable(self, "_clear"),
		"edit_mode": Callable(self, "_enter_edit"),
		"play_mode": Callable(self, "_enter_play"),
		"reset_play": Callable(self, "_reset_play"),
		"agent_step": Callable(self, "_agent_step"),
		"save": Callable(self, "_save"),
		"load": Callable(self, "_load"),
		"cell_pressed": Callable(self, "_cell_pressed"),
	})
	object_list = refs["object_list"] as VBoxContainer
	map_canvas = refs["map_canvas"] as Control
	selected_palette_label = refs["selected_palette_label"] as Label
	tool_mode_label = refs["tool_mode_label"] as Label
	app_mode_label = refs["app_mode_label"] as Label
	inspector_content = refs["inspector_content"] as VBoxContainer
	status_label = refs["status_label"] as Label
	_rebuild_palette_buttons()

func _reload() -> void:
	_enter_edit()
	palette.call("load_paths", DEFINITION_PATHS)
	map_editor.call("setup")
	_rebuild_palette_buttons()
	_select_palette(0)
	_reset_agent()
	_refresh_world()
	_set_status("Definitions reloaded. World cleared.")

func _rebuild_palette_buttons() -> void:
	for child: Node in object_list.get_children():
		child.queue_free()
	var definitions: Array = Array(palette.get("definitions"))
	for index in range(definitions.size()):
		var definition: Dictionary = Dictionary(definitions[index])
		var button := Button.new()
		button.text = "%s\n%s" % [str(definition.get("display_name", definition.get("id", "Object"))), str(definition.get("object_type", "unknown"))]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.pressed.connect(func() -> void:
			_select_palette(index)
		)
		object_list.add_child(button)

func _select_palette(index: int) -> void:
	if _is_play_mode():
		_set_status("Palette is locked in Play mode.")
		return
	var definition: Dictionary = Dictionary(palette.call("select_index", index))
	if definition.is_empty():
		return
	map_editor.call("select_definition", str(definition.get("id", "")))
	map_editor.call("set_tool", "place")
	_refresh_map()
	inspector.call("render")
	_update_labels()
	_set_status("Palette selected: %s" % str(definition.get("display_name", "Object")))

func _cell_pressed(cell: Vector2i) -> void:
	var definition: Dictionary = Dictionary(palette.call("get_selected_definition"))
	var result: Dictionary = Dictionary(map_editor.call("handle_cell", cell, definition))
	_refresh_world()
	var kind: String = str(result.get("kind", "select"))
	var data: Dictionary = Dictionary(result.get("data", {}))
	if data.is_empty():
		_set_status("No object changed at %s." % str(cell))
	else:
		_set_status("%s: %s" % [kind.capitalize(), str(data.get("display_name", data.get("id", "object")))])

func _refresh_world() -> void:
	var objects: Array[Dictionary] = _objects()
	var raw_patches: Array = Array(runtime.call("evaluate_world", objects))
	var patches: Array[Dictionary] = []
	for value: Variant in raw_patches:
		patches.append(Dictionary(value))
	runtime.call("apply_patches", map_editor, patches)
	_refresh_map()
	inspector.call("render")
	_update_labels()

func _refresh_map() -> void:
	var visuals: Dictionary = {}
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var cell := Vector2i(x, y)
			visuals[_cell_key(cell)] = _visual_for_cell(cell)
	var selected_value: Variant = map_editor.call("selected_cell")
	var selected_cell: Vector2i = selected_value if selected_value is Vector2i else Vector2i(-1, -1)
	map_canvas.call("set_cell_visuals", MAP_COLUMNS, MAP_ROWS, visuals, selected_cell)

func _visual_for_cell(cell: Vector2i) -> Dictionary:
	var agent_cell_value: Variant = agent.call("cell")
	var agent_cell: Vector2i = agent_cell_value if agent_cell_value is Vector2i else Vector2i(-1, -1)
	if cell == agent_cell:
		var goal_value: Variant = agent.call("goal")
		var goal: Vector2i = goal_value if goal_value is Vector2i else Vector2i(-1, -1)
		return AgentVisualRef.create(cell, goal, bool(agent.call("reached_goal")))
	var instance_id: String = str(map_editor.call("get_instance_id_at_cell", cell))
	if instance_id.is_empty():
		return ObjectVisualFactoryRef.create_empty_cell_visual(cell)
	var data: Dictionary = Dictionary(map_editor.call("get_instance_data", instance_id))
	var definition: Dictionary = Dictionary(palette.call("get_definition", str(data.get("definition_id", ""))))
	return ObjectVisualFactoryRef.create_map_visual(data, definition, bool(map_editor.call("is_selected_instance", instance_id)))

func _use_selected() -> void:
	if not _is_play_mode():
		_set_status("Use is available only in Play mode.")
		return
	var data: Dictionary = Dictionary(map_editor.call("get_selected_instance_data"))
	if data.is_empty():
		_set_status("Select a placed object before Use.")
		return
	var result: Dictionary = Dictionary(runtime.call("use_object", data, _objects()))
	runtime.call("apply_patches", map_editor, Array(result.get("patches", [])))
	_refresh_world()
	_set_status(str(result.get("message", "Use finished.")))

func _execute_action(action_id: String) -> void:
	if not _is_play_mode():
		_set_status("Runtime actions are available only in Play mode.")
		return
	var data: Dictionary = Dictionary(map_editor.call("get_selected_instance_data"))
	if data.is_empty():
		return
	var result: Dictionary = ActionExecutorRef.execute(action_id, data, _objects())
	runtime.call("apply_patches", map_editor, Array(result.get("patches", [])))
	_refresh_world()
	_set_status(str(result.get("message", "Action finished.")))

func _place_tool() -> void:
	if _is_play_mode():
		_set_status("Place is locked in Play mode.")
		return
	map_editor.call("set_tool", "place")
	_update_labels()

func _erase_tool() -> void:
	if _is_play_mode():
		_set_status("Erase is locked in Play mode.")
		return
	map_editor.call("set_tool", "erase")
	_update_labels()

func _undo() -> void:
	if _is_play_mode():
		_set_status("Undo is available only in Edit mode.")
		return
	if bool(map_editor.call("undo")):
		_refresh_world()
		_set_status("Undo.")

func _redo() -> void:
	if _is_play_mode():
		_set_status("Redo is available only in Edit mode.")
		return
	if bool(map_editor.call("redo")):
		_refresh_world()
		_set_status("Redo.")

func _clear() -> void:
	if _is_play_mode():
		_set_status("Clear is available only in Edit mode.")
		return
	map_editor.call("clear_map_keep_palette")
	_refresh_world()
	_set_status("Map cleared. Undo can restore it.")

func _enter_edit() -> void:
	if bool(world_session.call("has_snapshot")):
		map_editor.call("load_snapshot", world_session.call("restore"))
		world_session.call("clear")
	mode_controller.call("enter_edit")
	edit_mode_controller.call("enter", map_editor)
	_reset_agent()
	_refresh_world()
	_set_status("Edit mode.")

func _enter_play() -> void:
	if _is_play_mode():
		return
	mode_controller.call("enter_play")
	play_mode_controller.call("enter", map_editor, world_session)
	_update_labels()
	_set_status("Play mode.")

func _reset_play() -> void:
	if bool(play_mode_controller.call("reset", map_editor, world_session)):
		_reset_agent()
		_refresh_world()
		_set_status("Play state reset.")

func _agent_step() -> void:
	if not _is_play_mode():
		_set_status("Agent moves only in Play mode.")
		return
	var repository_value: Variant = map_editor.get("repository")
	if not (repository_value is RefCounted):
		_set_status("World repository is unavailable.")
		return
	var repository: RefCounted = repository_value as RefCounted
	var result: Dictionary = Dictionary(agent.call("step", repository, MAP_COLUMNS, MAP_ROWS))
	_refresh_map()
	_set_status(str(result.get("message", "Agent step.")))

func _reset_agent() -> void:
	var corridor: Array[Vector2i] = []
	for x in range(MAP_COLUMNS):
		corridor.append(Vector2i(x, 2))
	agent.call("setup", AGENT_START, AGENT_GOAL, corridor)

func _save() -> void:
	if _is_play_mode():
		_set_status("Save is available only in Edit mode.")
		return
	var snapshot: Dictionary = Dictionary(map_editor.call("make_snapshot"))
	var result: Dictionary = MapDocumentStoreRef.save_document(snapshot)
	_set_status(str(result.get("message", "Save failed.")))

func _load() -> void:
	_enter_edit()
	var result: Dictionary = MapDocumentStoreRef.load_document()
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("message", "Load failed.")))
		return
	map_editor.call("load_snapshot", Dictionary(result.get("snapshot", {})))
	palette.call("select_definition_id", str(map_editor.call("selected_definition_id")))
	_reset_agent()
	_refresh_world()
	_set_status(str(result.get("message", "Map loaded.")))

func _load_test_room() -> void:
	_enter_edit()
	var definitions: Dictionary = Dictionary(palette.get("definitions_by_id"))
	map_editor.call("load_snapshot", TestRoomRef.make_snapshot(definitions))
	palette.call("select_definition_id", str(map_editor.call("selected_definition_id")))
	_reset_agent()
	_refresh_world()
	_set_status("Test room loaded.")

func _objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(map_editor.call("get_placed_objects")):
		result.append(Dictionary(value))
	return result

func _is_play_mode() -> bool:
	return str(map_editor.call("app_mode")) == "play"

func _update_labels() -> void:
	var definition: Dictionary = Dictionary(palette.call("get_selected_definition"))
	selected_palette_label.text = "Selected:\n%s" % str(definition.get("display_name", "none"))
	tool_mode_label.text = "Tool: %s" % str(map_editor.call("active_tool_mode")).capitalize()
	app_mode_label.text = "Mode: %s" % str(map_editor.call("app_mode")).capitalize()

func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
