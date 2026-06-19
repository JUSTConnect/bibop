extends SceneTree

const GameUIRef = preload("res://scripts/ui/game_ui.gd")
const MapConstructorSessionStateRef = preload("res://scripts/ui/map_constructor/map_constructor_session_state.gd")

const PARSER_LOAD_PATHS: Array[String] = [
	"res://scripts/ui/map_constructor/map_constructor_screen.gd",
	"res://scripts/ui/map_constructor/map_constructor_tabs.gd",
	"res://scripts/ui/map_constructor/map_constructor_panel.gd",
	"res://scripts/ui/map_constructor/map_constructor_inspector.gd",
	"res://scripts/ui/map_constructor/map_constructor_scroll_state_service.gd",
	"res://scripts/ui/map_constructor/map_constructor_ui_bridge.gd",
]

var _failed: bool = false

func _initialize() -> void:
	_run()
	if _failed:
		quit(1)
		return
	print("OK: Map Constructor session state contract checks passed")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true

func _run() -> void:
	_check_no_game_ui_proxy_methods()
	_check_defaults_and_direct_fields()
	_check_parser_load_coverage()

func _has_method_named(script: Script, method_name: String) -> bool:
	for method_variant in script.get_script_method_list():
		var method: Dictionary = Dictionary(method_variant)
		if str(method.get("name", "")) == method_name:
			return true
	return false

func _check_no_game_ui_proxy_methods() -> void:
	_expect(not _has_method_named(GameUIRef, "_get"), "GameUI must not define a Map Constructor dynamic _get() proxy.")
	_expect(not _has_method_named(GameUIRef, "_set"), "GameUI must not define a Map Constructor dynamic _set() proxy.")
	_expect(not _has_method_named(MapConstructorSessionStateRef, "has_session_property"), "Session state must not expose has_session_property().")

func _check_defaults_and_direct_fields() -> void:
	var state = MapConstructorSessionStateRef.new()
	_expect(state.map_constructor_mode_active == false, "Map Constructor mode should default to inactive.")
	_expect(state.map_constructor_active_tab == "map_settings", "Active tab should default to map_settings.")
	_expect(state.map_constructor_inspector_expanded == false, "Inspector should default to collapsed.")
	_expect(state.selected_map_constructor_prefab_id == "", "Selected prefab should default empty.")
	_expect(state.pending_map_constructor_cell == Vector2i(-1, -1), "Pending hover cell should default unset.")
	_expect(state.map_constructor_pending_place_prefab_id == "", "Pending placement prefab should default empty.")
	_expect(state.map_constructor_pending_place_cell == Vector2i(-1, -1), "Pending placement cell should default unset.")
	_expect(state.map_constructor_pending_place_rotation == 0, "Pending placement rotation should default zero.")

	state.map_constructor_mode_active = true
	_expect(state.map_constructor_mode_active, "Activation should be stored directly on session state.")
	state.map_constructor_active_tab = "objects"
	_expect(state.map_constructor_active_tab == "objects", "Active tab should switch and persist.")

	state.selected_map_constructor_prefab_id = "crate"
	state.selected_map_constructor_entity_kind = "object"
	state.selected_map_constructor_entity_id = "obj_1"
	state.selected_map_constructor_entity_cell = Vector2i(3, 4)
	state.selected_map_constructor_wall_side = "east"
	state.selected_map_constructor_mounting_mode = "wall_mounted"
	_expect(state.selected_map_constructor_prefab_id == "crate", "Prefab selection should persist.")
	_expect(state.selected_map_constructor_entity_kind == "object", "Entity kind selection should persist.")
	_expect(state.selected_map_constructor_entity_id == "obj_1", "Entity id selection should persist.")
	_expect(state.selected_map_constructor_entity_cell == Vector2i(3, 4), "Entity cell selection should persist.")
	_expect(state.selected_map_constructor_wall_side == "east", "Wall side selection should persist.")

	state.map_constructor_pending_place_prefab_id = "door"
	state.map_constructor_pending_place_cell = Vector2i(7, 8)
	state.map_constructor_pending_place_rotation = 90
	_expect(state.map_constructor_pending_place_prefab_id == "door", "Pending prefab should persist.")
	_expect(state.map_constructor_pending_place_cell == Vector2i(7, 8), "Pending cell should persist.")
	_expect(state.map_constructor_pending_place_rotation == 90, "Pending rotation should persist.")
	state.reset_pending_placement()
	_expect(state.map_constructor_pending_place_prefab_id == "", "reset_pending_placement() should clear prefab.")
	_expect(state.map_constructor_pending_place_cell == Vector2i(-1, -1), "reset_pending_placement() should clear cell.")
	_expect(state.map_constructor_pending_place_rotation == 0, "reset_pending_placement() should clear rotation.")

	state.map_constructor_picker_entity_kind = "object"
	state.map_constructor_picker_entity_id = "door_1"
	state.map_constructor_picker_field_name = "linked_key_id"
	state.reset_picker()
	_expect(state.map_constructor_picker_entity_kind == "", "reset_picker() should clear picker kind.")
	_expect(state.map_constructor_picker_entity_id == "", "reset_picker() should clear picker id.")
	_expect(state.map_constructor_picker_field_name == "", "reset_picker() should clear picker field.")

	state.map_constructor_prefab_search_text = "power"
	state.map_constructor_prefab_category_filter = "Power"
	state.map_constructor_prefab_role_filter = "Producer"
	state.map_constructor_prefab_placement_filter = "floor"
	state.map_constructor_issue_filter = "Warnings"
	_expect(state.map_constructor_prefab_search_text == "power", "Search filter should persist.")
	_expect(state.map_constructor_prefab_category_filter == "Power", "Category filter should persist.")
	_expect(state.map_constructor_prefab_role_filter == "Producer", "Role filter should persist.")
	_expect(state.map_constructor_prefab_placement_filter == "floor", "Placement filter should persist.")
	_expect(state.map_constructor_issue_filter == "Warnings", "Issue filter should persist.")

	state.selected_map_constructor_prefab_id = "crate"
	state.pending_map_constructor_cell = Vector2i(1, 1)
	state.selected_map_constructor_entity_kind = "object"
	state.selected_map_constructor_entity_id = "obj_2"
	state.selected_map_constructor_entity_cell = Vector2i(2, 2)
	state.selected_map_constructor_wall_side = "north"
	state.available_map_constructor_wall_sides = ["north", "south"]
	state.map_constructor_active_tab = "warnings"
	state.map_constructor_prefab_search_text = "keep"
	state.reset_selection()
	_expect(state.selected_map_constructor_prefab_id == "", "reset_selection() should clear selected prefab.")
	_expect(state.pending_map_constructor_cell == Vector2i(-1, -1), "reset_selection() should clear pending hover cell.")
	_expect(state.selected_map_constructor_entity_kind == "", "reset_selection() should clear entity kind.")
	_expect(state.selected_map_constructor_entity_id == "", "reset_selection() should clear entity id.")
	_expect(state.selected_map_constructor_entity_cell == Vector2i(-1, -1), "reset_selection() should clear entity cell.")
	_expect(state.selected_map_constructor_wall_side == "", "reset_selection() should clear wall side.")
	_expect(state.available_map_constructor_wall_sides.is_empty(), "reset_selection() should clear available wall sides.")
	_expect(state.map_constructor_active_tab == "warnings", "reset_selection() should not clear active tab.")
	_expect(state.map_constructor_prefab_search_text == "keep", "reset_selection() should not clear filters.")

func _check_parser_load_coverage() -> void:
	for path in PARSER_LOAD_PATHS:
		var loaded: Variant = load(path)
		_expect(loaded != null, "%s should load successfully after session-state migration." % path)
