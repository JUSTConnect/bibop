extends CanvasLayer
class_name GameUI

const GameUITextHelpersRef = preload("res://scripts/ui/game_ui_text_helpers.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const RuntimeMissionMenuRef = preload("res://scripts/ui/runtime/runtime_mission_menu.gd")
const CenterScreenRef = preload("res://scripts/ui/screens/center_screen.gd")
const RuntimeStoragePanelRef = preload("res://scripts/ui/runtime/runtime_storage_panel.gd")
const RuntimeControlPanelRef = preload("res://scripts/ui/runtime/runtime_control_panel.gd")
const RuntimeInteractionPresenterRef = preload("res://scripts/ui/runtime/runtime_interaction_presenter.gd")
const RuntimeBipobSwitcherRef = preload("res://scripts/ui/runtime/runtime_bipob_switcher.gd")
const RuntimeObjectHudRef = preload("res://scripts/ui/runtime/runtime_object_hud.gd")
const MapConstructorScreenRef = preload("res://scripts/ui/map_constructor/map_constructor_screen.gd")
const MapConstructorInspectorRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector.gd")
const MapConstructorPropertyControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_property_controls.gd")
const MapConstructorPropertyUpdateServiceRef = preload("res://scripts/game/map_constructor_property_update_service.gd")
const MapConstructorLinkControlsRef = preload("res://scripts/ui/map_constructor/map_constructor_link_controls.gd")
const MapConstructorSessionStateRef = preload("res://scripts/ui/map_constructor/map_constructor_session_state.gd")
const MapConstructorRefreshCoordinatorRef = preload("res://scripts/ui/map_constructor/map_constructor_refresh_coordinator.gd")


class InternalIsoPreviewControl:
	extends Control
	var ui_ref: GameUI

	func _init(ui_owner: GameUI) -> void:
		ui_ref = ui_owner
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ui_ref != null:
			ui_ref._draw_internal_isometric_preview(self)


class SelectedModuleMiniPreviewControl:
	extends Control
	var ui_ref: GameUI
	var module_ref: BipobModule
	var preview_context: String = ""

	func _init(ui_owner: GameUI, preview_module: BipobModule, context: String) -> void:
		ui_ref = ui_owner
		module_ref = preview_module
		preview_context = context
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ui_ref != null:
			ui_ref._draw_selected_module_mini_preview(self, module_ref, preview_context)

class ConstructorValidationOverlayControl:
	extends Control
	var ui_ref: GameUI

	func _init(ui_owner: GameUI) -> void:
		ui_ref = ui_owner
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ui_ref != null:
			ui_ref._draw_map_constructor_validation_overlay(self)



func _get(property: StringName) -> Variant:
	if map_constructor_state != null and map_constructor_state.has_session_property(property):
		return map_constructor_state.get(property)
	return null


func _set(property: StringName, value: Variant) -> bool:
	if map_constructor_state != null and map_constructor_state.has_session_property(property):
		map_constructor_state.set(property, value)
		return true
	return false

var bipob: BipobController = null
var field_runtime: GridManager = null
const FIELD_SCENE_PATH: String = "res://scenes/field/Field.tscn"
const BIPOB_SCENE_PATH: String = "res://scenes/bipob/Bipob.tscn"
const MISSION_MANAGER_SCRIPT_PATH: String = "res://scripts/game/mission_manager.gd"

@onready var mission_label: Label = $MissionLabel
@onready var hud_status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

var hud_diagnostic_label: Label
var runtime_mission_field_host: Control
var mission_manager_runtime: Node = null
var runtime_hud_root: Control = null
var runtime_bipob_switcher_panel: PanelContainer = null
var runtime_menu_button: Button = null
var runtime_menu_overlay: Control = null
var center_menu_overlay: Control = null
var runtime_pocket_flyout: PanelContainer = null
var runtime_storage_flyout: PanelContainer = null
var runtime_selected_mission_bipob_index: int = 0
var runtime_mission_bipob_cards: Array[Button] = []

var runtime_interaction_mode_active: bool = false
var runtime_interaction_actions_row: HBoxContainer = null
var runtime_base_controls_grid: GridContainer = null
var runtime_action_button: Button = null
var runtime_connect_button: Button = null
var runtime_heavy_claw_button: Button = null
var runtime_end_turn_button: Button = null
var runtime_notification_label: Label = null
var runtime_notification_panel: PanelContainer = null
var runtime_notification_timer: float = 0.0
var runtime_notification_role: String = "neutral"
var runtime_interaction_actions_signature: String = ""

@onready var box_status_label: Label = $BoxScreen/PanelContainer/VBoxContainer/StatusLabel
@onready var box_module_label: Label = $BoxScreen/PanelContainer/VBoxContainer/ModuleLabel
@onready var installed_modules_label: Label = $BoxScreen/PanelContainer/VBoxContainer/InstalledModulesLabel
var box_storage_label: Label
var digital_storage_label: Label
@onready var charge_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/ChargeButton
@onready var install_module_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/InstallModuleButton
@onready var start_mission_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/StartMissionButton
var remove_module_button: Button

@onready var box_title_label: Label = $BoxScreen/PanelContainer/VBoxContainer/TitleLabel
var box_content_scroll: ScrollContainer = null
var box_content_label: Label = null
var right_button_panel: VBoxContainer = null
var main_box_row: HBoxContainer = null
var left_panel: VBoxContainer = null
var box_constructor_content_root: Control = null
var box_top_bar_root: Control = null

@onready var move_forward_button: Button = $CommandPanel/CommandList/MoveForwardButton
@onready var move_backward_button: Button = $CommandPanel/CommandList/MoveBackwardButton
@onready var turn_left_button: Button = $CommandPanel/CommandList/TurnLeftButton
@onready var turn_right_button: Button = $CommandPanel/CommandList/TurnRightButton
@onready var interact_button: Button = $CommandPanel/CommandList/InteractButton
@onready var end_turn_button: Button = $CommandPanel/CommandList/EndTurnButton

var scan_device_button: Button
var hack_device_button: Button
var restart_mission_button: Button
var return_to_box_button: Button
var settings_button: Button
var exit_main_menu_button: Button
var drop_item_button: Button
var rotate_storage_button: Button
var mission_goal_value_label: Label
var storage_items_value_label: Label
var storage_information_value_label: Label
var storage_keys_value_label: Label
var runtime_storage_panel: PanelContainer
var runtime_storage_panel_collapsed: bool = false
var runtime_storage_panel_body: Control = null
var runtime_storage_collapse_button: Button = null
const Z_RUNTIME_WORLD_OVERLAY: int = 20
const Z_RUNTIME_HUD: int = 50
const Z_MAP_CONSTRUCTOR_UI: int = 90
const Z_RUNTIME_MODAL: int = 120
var runtime_manipulator_content_label: Button
var runtime_manipulator_slots: Array[Button] = []
var runtime_pocket_slots: Array[Button] = []
var runtime_digital_slots: Array[Button] = []
var runtime_pocket_take_buttons: Array[Button] = []
var runtime_digital_load_buttons: Array[Button] = []
var runtime_buffer_content_label: Button
var runtime_key_summary_label: Label
var runtime_pocket_title_label: Label
var runtime_digital_title_label: Label
var runtime_digital_store_title_label: Label
var runtime_energy_label: Label
var runtime_actions_label: Label
var runtime_info_actions_label: Label
var runtime_world_actions_panel: PanelContainer = null
var runtime_world_actions_target_label: Label = null
var runtime_world_actions_state_label: Label = null
var runtime_world_actions_behavior_label: Label = null
var runtime_world_actions_list: VBoxContainer = null
var runtime_world_actions_no_actions_label: Label = null
var runtime_world_actions_selected_button: Button = null
var map_constructor_state: MapConstructorSessionState = MapConstructorSessionStateRef.new()
var runtime_map_constructor_palette_panel: PanelContainer = null
var runtime_map_constructor_inspector_panel: PanelContainer = null
var runtime_map_constructor_inspector_scroll: ScrollContainer = null
var runtime_map_constructor_overview_hud_panel: PanelContainer = null
var runtime_map_constructor_overview_hud_scroll: ScrollContainer = null

var runtime_object_info_panel: PanelContainer = null
var runtime_object_info_cell: Vector2i = Vector2i(-1, -1)
var runtime_map_constructor_validation_overlay_control: ConstructorValidationOverlayControl = null
var runtime_map_constructor_place_confirm_panel: PanelContainer = null

var last_world_action_target_id: String = ""
var last_world_action_actions_key: String = ""
var last_world_action_selected: String = ""
var last_world_action_state_key: String = ""
var debug_ui_layout_logs: bool = false
var debug_world_logs: bool = false
var runtime_key_slots: Array[Control] = []
var selected_manipulator_slot: int = 0
var selected_pocket_slot: int = 0
var selected_digital_slot: int = 0
var start_mission_warning_acknowledged: bool = false
var should_advance_mission_on_start: bool = false
var selected_installed_module_index: int = 0
var selected_box_storage_index: int = 0
var selected_filtered_box_index: int = 0
var selected_grouped_module_index: int = 0
var external_filter_index: int = 0
var internal_filter_index: int = 0
const CONSTRUCTOR_FILTERS: Array[String] = [
	"all",
	"broken",
	"unknown",
	"cpu_gpu",
	"cooling",
	"ram_sd",
	"power",
	"gear",
	"visor_radar",
	"tool",
	"manipulator",
	"armor",
	"weapon",
	"interface",
	"other"
]
var prev_installed_button: Button
var next_installed_button: Button
var prev_box_button: Button
var next_box_button: Button
var box_tab_row: HBoxContainer = null
var mission_tab_button: Button
var modules_tab_button: Button
var external_tab_button: Button
var internal_tab_button: Button
var box_restart_button: Button
var box_return_button: Button
var bipob_alpha_button: Button
var bipob_beta_button: Button
var bipob_juggernaut_button: Button
var box_back_button: Button
var active_bipob_profile_id: String = "alpha"
var constructor_profiles: Dictionary = {}
const BIPOB_PROFILE_NAMES: Dictionary = {"alpha": "Scout", "beta": "Engineer", "juggernaut": "Juggernaut"}
const BIPOB_PROFILE_SIZES: Dictionary = {"alpha": Vector3i(3, 3, 4), "beta": Vector3i(5, 5, 6), "juggernaut": Vector3i(7, 7, 9)}

enum BoxMenuMode {
	EXTERNAL,
	INTERNAL
}

var box_menu_mode: BoxMenuMode = BoxMenuMode.EXTERNAL
var selected_external_side_index: int = 1
var selected_external_slot_position: Vector2i = Vector2i(1, 1)
var selected_constructor_module: BipobModule = null
var selected_module_source: String = "none"
var selected_install_record: Dictionary = {}
var selected_external_side: String = ""
var selected_external_cell: Vector2i = Vector2i.ZERO
var internal_view_mode: String = "modules"
var module_icon_texture_cache: Dictionary = {}
var module_type_icon_texture_cache: Dictionary = {}
var module_type_icon_atlas_region_cache: Dictionary = {}
var constructor_reference_text: String = ""

enum AppScreenMode {
	MAIN_MENU,
	CENTER,
	TASKS,
	GAMEPLAY,
	BOX_CONSTRUCTOR,
	MISSION_CONSTRUCTOR,
	MISSION_RESULT,
	SETTINGS_PLACEHOLDER,
	ABOUT_PLACEHOLDER,
	SHOP_PLACEHOLDER,
	RESEARCH_PLACEHOLDER,
	REPAIR_PLACEHOLDER,
	PROGRAMMER_MENU,
	CHARGING_MENU
}

var app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU
var previous_app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU
var last_mission_success: bool = true
var box_opened_from_center: bool = false
var placeholder_return_screen_mode: AppScreenMode = AppScreenMode.CENTER

var main_menu_root: Control
var center_menu_root: Control
var tasks_menu_root: Control
var mission_constructor_root: Control
var mission_result_root: Control = null
var placeholder_menu_root: Control
var placeholder_title_label: Label
var placeholder_body_label: Label
var tasks_tab_buttons: Dictionary = {}
var tasks_current_tab: String = "Career"
var tasks_mission_data: Array[Dictionary] = []
var tasks_selected_ids: Array[String] = ["alpha"]
var tasks_selected_mission_id: int = 1
var tasks_available_bipobs: Array[Dictionary] = [
	{"id": "alpha", "name": "Scout"},
	{"id": "beta", "name": "Engineer"},
	{"id": "juggernaut", "name": "Juggernaut"}
]
var tasks_selected_career_index: int = 0
var tasks_list_container: VBoxContainer
var tasks_title_label: Label
var tasks_difficulty_label: Label
var tasks_reward_label: Label
var tasks_description_label: Label
var tasks_main_goal_label: Label
var tasks_extra_goal_label: Label
var tasks_requirements_required_labels: Array[Label] = []
var tasks_requirements_current_labels: Array[RichTextLabel] = []
var tasks_warnings_label: RichTextLabel
var tasks_report_label: Label
var tasks_bipob_buttons_row: HBoxContainer
var charging_menu_root: Control = null
var box_menu_root: Control = null
var programmer_menu_root: Control = null
var programmer_message_label: Label = null
var programmer_pending_files: Array[Dictionary] = []
var programmer_completed_files: Array[Dictionary] = []
var programmer_pending_bipobs: Array[Dictionary] = []
var programmer_reprogrammed_bipobs: Array[Dictionary] = []
var charging_active_tab: String = "supercharger"
var tasks_validation_label: Label
var tasks_start_button: Button
var tasks_claim_button: Button
const MAP_CONSTRUCTOR_PREFAB_RECENT_LIMIT: int = 8
const MAP_CONSTRUCTOR_ISSUE_FILTER_OPTIONS: Array[String] = ["All", "Errors", "Warnings", "Info"]
const MAP_CONSTRUCTOR_HISTORY_FILTER_OPTIONS: Array[String] = ["All", "Placement", "Edit", "Cleanup", "Auto-fix", "Patch", "Reset"]
const MAP_CONSTRUCTOR_OVERVIEW_FILTER_OPTIONS: Array[String] = ["All", "Issues", "Errors", "Warnings", "Expected Invalid", "Objects", "Items", "Power", "Terminals", "Doors", "Wall-mounted", "History", "Selected"]

const MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES: Array[String] = ["All", "Structural", "Door", "Terminal", "Power", "Control", "Item", "Wall-mounted", "Diagnostic", "Expected Invalid", "Utility"]
const MAP_CONSTRUCTOR_PREFAB_FILTER_ROLES: Array[String] = ["All", "navigation", "blocking", "access_control", "power_source", "power_consumer", "power_network", "signal_control", "terminal_interaction", "key_item", "diagnostics", "readiness_test", "expected_invalid_test"]
const MAP_CONSTRUCTOR_PREFAB_FILTER_PLACEMENT_MODES: Array[String] = ["All", "tile", "object", "item", "wall_mounted"]
const MAP_CONSTRUCTOR_CONTROL_PREFAB_IDS: Array[String] = [
	"terminal",
	"circuit_switch",
	"circuit_breaker",
	"light_switch",
	"fuse_box"
]
const MAP_CONSTRUCTOR_POWER_PREFAB_IDS: Array[String] = [
	"power_source_class_1",
	"power_socket",
	"power_cable",
	"power_cable_reel"
]
const MAP_CONSTRUCTOR_PREFAB_CATEGORY_GROUP_ORDER: Array[String] = [
	"Structural",
	"Door",
	"Terminal",
	"Power",
	"Control",
	"Item",
	"Wall-mounted",
	"Diagnostic",
	"Expected Invalid",
	"Utility"
]
var edge_scroll_enabled: bool = true
var edge_scroll_margin_px: float = 28.0
var edge_scroll_speed: float = 540.0
var map_camera_scroll_speed: float = 600.0
var map_scroll_bounds_margin_px: float = 180.0
var tasks_actions_row: HBoxContainer
var tasks_dev_output_label: RichTextLabel
var tasks_dev_output_scroll: ScrollContainer
var mission_progress: Dictionary = {}
var repair_menu_root: Control = null

const CONSTRUCTOR_PANEL_BG_PATH: String = "res://assets/ui/constructor/panel_bg.png"
const CONSTRUCTOR_CELL_EMPTY_PATH: String = "res://assets/ui/constructor/cell_empty.png"
const CONSTRUCTOR_CELL_SELECTED_PATH: String = "res://assets/ui/constructor/cell_selected.png"
const CONSTRUCTOR_CELL_INVALID_PATH: String = "res://assets/ui/constructor/cell_invalid.png"
const CONSTRUCTOR_ROBOT_PLACEHOLDER_PATH: String = "res://assets/ui/constructor/robot_placeholder.png"
const CONSTRUCTOR_INTERNAL_CUBE_PLACEHOLDER_PATH: String = "res://assets/ui/constructor/internal_cube_placeholder.png"

const UI_COLOR_BG: Color = Color(0.035, 0.045, 0.060, 1.0)
const UI_COLOR_PANEL: Color = Color(0.075, 0.090, 0.115, 0.96)
const UI_COLOR_PANEL_DARK: Color = Color(0.045, 0.055, 0.075, 0.98)
const UI_COLOR_BORDER: Color = Color(0.220, 0.480, 0.620, 0.85)
const UI_COLOR_BORDER_DIM: Color = Color(0.120, 0.220, 0.280, 0.75)
const UI_COLOR_TEXT: Color = Color(0.820, 0.900, 0.920, 1.0)
const UI_COLOR_TEXT_DIM: Color = Color(0.520, 0.650, 0.690, 1.0)
const UI_COLOR_ACCENT: Color = Color(0.200, 0.760, 0.950, 1.0)
const UI_COLOR_SELECTED: Color = Color(0.950, 0.820, 0.250, 1.0)
const UI_COLOR_OK: Color = Color(0.250, 0.850, 0.480, 1.0)
const UI_COLOR_WARNING: Color = Color(0.950, 0.640, 0.230, 1.0)
const UI_COLOR_DANGER: Color = Color(0.950, 0.250, 0.250, 1.0)
const UI_COLOR_DISABLED: Color = Color(0.250, 0.280, 0.320, 1.0)

const STORAGE_CARD_MIN_SIZE: Vector2 = Vector2(110, 74)
const MENU_TOP_BUTTON_HEIGHT := 56
const BOX_TOP_BUTTON_HEIGHT := 56.0
const MENU_BACK_BUTTON_SIZE: Vector2 = Vector2(120, 56)
const REPAIR_BIPOB_CARD_SIZE: Vector2 = Vector2(120, 56)
const STORAGE_CARD_ICON_SIZE: Vector2 = Vector2(26, 26)
const MODULE_TYPE_ICON_BASE_PATH: String = "res://assets/visual/isometric/icons/modules/base_icon_inext.webp"
const MODULE_TYPE_ICON_ATLAS_PATH: String = "res://assets/visual/isometric/icons/modules/icon_inext.webp"
const MODULE_TYPE_ICON_FRAME_SIZE: Vector2i = Vector2i(64, 64)
const MODULE_TYPE_ICON_TILE_SIZE: Vector2 = Vector2(48, 48)
const MODULE_TYPE_ICON_PREVIEW_BADGE_SIZE: Vector2 = Vector2(48, 48)
const MODULE_TYPE_ICON_TILE_PADDING: float = 5.0
const MODULE_TYPE_ICON_OVERLAY_COLOR: Color = Color(0, 0, 0, 1)
const MODULE_VERSION_COLOR_V1: Color = Color("#78C850")
const MODULE_VERSION_COLOR_V2: Color = Color("#4DB6FF")
const MODULE_VERSION_COLOR_V3: Color = Color("#B56CFF")
const MODULE_VERSION_COLOR_UNKNOWN: Color = Color("#E84B4B")
const SELECTED_MODULE_ICON_SIZE: Vector2 = Vector2(68, 64)
const SELECTED_MODULE_VISUAL_PREVIEW_SIZE: Vector2 = Vector2(96, 72)
const SELECTED_MODULE_FOOTPRINT_PREVIEW_SIZE: Vector2 = Vector2(84, 64)
const SELECTED_MODULE_PREVIEW_CELL_SIZE: Vector2 = Vector2(18, 18)
const SELECTED_MODULE_PREVIEW_GAP: int = 3
const EXTERNAL_SLOT_CELL_SIZE: Vector2 = Vector2(22, 22)
const EXTERNAL_GRID_CELL_SIZE: Vector2 = EXTERNAL_SLOT_CELL_SIZE
const EXTERNAL_GRID_CELL_GAP: int = 2
const INTERNAL_GRID_CELL_SIZE: Vector2 = Vector2(22, 22)
const INTERNAL_GRID_CELL_GAP: int = 2
const CONSTRUCTOR_GRID_PREFERRED_CELL_SIZE: float = 28.0
const CONSTRUCTOR_GRID_MIN_CELL_SIZE: float = 12.0
const CONSTRUCTOR_SMALL_LABEL_CELL_SIZE: float = 16.0
const CONSTRUCTOR_TOP_BUTTON_HEIGHT: float = 32.0
const ACTION_BUTTON_MIN_SIZE: Vector2 = Vector2(100, 24)
const ACTION_BUTTON_COMPACT_SIZE: Vector2 = Vector2(46, 22)
const ACTION_GROUP_SPACING: int = 2
const ACTION_BUTTON_SPACING: int = 2
const STATUS_BADGE_MIN_SIZE: Vector2 = Vector2(96, 26)
const STATUS_BADGE_SMALL_SIZE: Vector2 = Vector2(70, 20)
const STATUS_BADGE_GAP: int = 4
const UI_ANIM_FAST: float = 0.12
const UI_ANIM_MEDIUM: float = 0.28
const UI_ANIM_PULSE_ALPHA_LOW: float = 0.72
const UI_ANIM_PULSE_ALPHA_HIGH: float = 1.0
const CONSTRUCTOR_SHOW_DEBUG_TEXT_IN_MAIN: bool = false
const CONSTRUCTOR_COMPACT_DETAILS: bool = true
const CONSTRUCTOR_COMPACT_STATUS: bool = true
const CONSTRUCTOR_SHOW_MODE_LAYOUT_TITLE: bool = false
const TASK_REQUIREMENT_ROW_HEIGHT: float = 32.0
const TASK_REQUIREMENT_REQUIRED_COL_WIDTH: float = 320.0
const TASK_REQUIREMENT_WARNING_MAX_HEIGHT: float = 140.0


func _disconnect_all_pressed_connections(button: Button) -> void:
	if button == null:
		return
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable.is_valid():
			button.pressed.disconnect(callable)


func _connect_button_pressed_once(button: Button, callback: Callable) -> void:
	if button == null:
		return
	if not callback.is_valid():
		return
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable == callback:
			return
	button.pressed.connect(callback)


func _has_gameplay_runtime() -> bool:
	return bipob != null and is_instance_valid(bipob) and field_runtime != null and is_instance_valid(field_runtime)

func _connect_bipob_runtime_signals_once() -> void:
	if bipob == null:
		return
	if not bipob.status_changed.is_connected(_on_runtime_bipob_status_changed):
		bipob.status_changed.connect(_on_runtime_bipob_status_changed)
	if not bipob.hint_requested.is_connected(show_hint):
		bipob.hint_requested.connect(show_hint)
	if not bipob.world_action_panel_requested.is_connected(_on_world_action_panel_requested):
		bipob.world_action_panel_requested.connect(_on_world_action_panel_requested)
	if not bipob.mission_completed.is_connected(_on_mission_completed):
		bipob.mission_completed.connect(_on_mission_completed)
	if not bipob.mission_failed.is_connected(_on_mission_failed):
		bipob.mission_failed.connect(_on_mission_failed)
	if not bipob.returned_to_box.is_connected(_on_returned_to_box):
		bipob.returned_to_box.connect(_on_returned_to_box)

func _initialize_runtime_profiles_if_needed() -> void:
	if bipob == null:
		return
	if constructor_profiles.is_empty():
		_ensure_constructor_profiles_initialized()
	if active_bipob_profile_id.is_empty():
		active_bipob_profile_id = "alpha"
	_load_bipob_profile(active_bipob_profile_id)

func _ensure_gameplay_runtime_created() -> bool:
	if _has_gameplay_runtime():
		return true
	var root: Node = get_parent()
	if root == null:
		push_error("GameUI: cannot create gameplay runtime without parent root.")
		return false
	var field_scene: PackedScene = load(FIELD_SCENE_PATH)
	if field_scene == null:
		push_error("GameUI: failed to load Field scene.")
		return false
	var field_node: Node = field_scene.instantiate()
	field_node.name = "Field"
	if field_node is Node2D:
		(field_node as Node2D).position = Vector2(100, 80)
	root.add_child(field_node)
	field_runtime = field_node as GridManager
	if field_runtime == null:
		push_error("GameUI: Field runtime is not GridManager.")
		field_node.queue_free()
		return false
	var mission_script: Script = load(MISSION_MANAGER_SCRIPT_PATH)
	if mission_script == null:
		push_error("GameUI: failed to load MissionManager script.")
		field_runtime.queue_free()
		field_runtime = null
		return false
	mission_manager_runtime = Node.new()
	mission_manager_runtime.name = "MissionManager"
	mission_manager_runtime.set_script(mission_script)
	root.add_child(mission_manager_runtime)
	if mission_manager_runtime.has_method("set_grid_manager_ref"):
		mission_manager_runtime.call("set_grid_manager_ref", field_runtime)
	elif _object_has_property(mission_manager_runtime, "grid_manager"):
		mission_manager_runtime.set("grid_manager", field_runtime)
	var bipob_scene: PackedScene = load(BIPOB_SCENE_PATH)
	if bipob_scene == null:
		push_error("GameUI: failed to load Bipob scene.")
		field_runtime.queue_free()
		field_runtime = null
		return false
	var bipob_node: Node = bipob_scene.instantiate()
	bipob_node.name = "Bipob"
	root.add_child(bipob_node)
	bipob = bipob_node as BipobController
	if bipob == null:
		push_error("GameUI: Bipob runtime is not BipobController.")
		bipob_node.queue_free()
		if mission_manager_runtime != null and is_instance_valid(mission_manager_runtime):
			mission_manager_runtime.queue_free()
		mission_manager_runtime = null
		field_runtime.queue_free()
		field_runtime = null
		return false
	if mission_manager_runtime != null and is_instance_valid(mission_manager_runtime):
		if mission_manager_runtime.has_method("set_active_bipob_ref"):
			mission_manager_runtime.call("set_active_bipob_ref", bipob)
		elif _object_has_property(mission_manager_runtime, "active_bipob_ref"):
			mission_manager_runtime.set("active_bipob_ref", bipob)
	if _object_has_property(bipob, "mission_manager") and bipob.mission_manager == null:
		bipob.mission_manager = mission_manager_runtime
	_initialize_runtime_profiles_if_needed()
	_connect_bipob_runtime_signals_once()
	_set_gameplay_visible(false)
	return true

func _destroy_gameplay_runtime() -> void:
	_deactivate_map_constructor_mode()
	if bipob != null and is_instance_valid(bipob):
		bipob.queue_free()
	if field_runtime != null and is_instance_valid(field_runtime):
		field_runtime.queue_free()
	if mission_manager_runtime != null and is_instance_valid(mission_manager_runtime):
		mission_manager_runtime.queue_free()
	bipob = null
	field_runtime = null
	mission_manager_runtime = null
	runtime_storage_panel_collapsed = false
	runtime_storage_panel_body = null
	runtime_storage_collapse_button = null

func _object_has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if String(property_data.get("name", "")) == property_name:
			return true
	return false

func _sync_runtime_bipob_visual_state() -> void:
	if bipob == null:
		return
	if bipob.has_method("update_visual_facing"):
		bipob.call("update_visual_facing")
	if bipob.has_method("update_world_position"):
		bipob.call("update_world_position")
	if field_runtime != null and is_instance_valid(field_runtime) and field_runtime.has_method("request_visual_refresh"):
		field_runtime.call("request_visual_refresh")

func _on_runtime_bipob_status_changed() -> void:
	update_status()
	update_diagnostic_status()
	update_box_status()
	call_deferred("_sync_runtime_bipob_visual_state")

func _safe_has_bipob_method(method_name: String) -> bool:
	if bipob == null:
		return false
	return bipob.has_method(method_name)

func _is_constructor_internal_mode() -> bool:
	return box_menu_mode == BoxMenuMode.INTERNAL

func _is_constructor_external_mode() -> bool:
	return box_menu_mode == BoxMenuMode.EXTERNAL

func _is_constructor_dashboard_mode() -> bool:
	return false

func _show_constructor_reference_text(title_text: String, body_text: String) -> void:
	var text: String = title_text
	if not body_text.is_empty():
		text += "\n\n" + body_text
	constructor_reference_text = text
	show_hint(text)
	update_box_status()

func _get_constructor_ui_smoke_check_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor UI Smoke Check")
	lines.append("Dashboard: OK")
	lines.append("External Mode: OK")
	lines.append("Internal Mode: OK")
	lines.append("Storage Cards: OK")
	lines.append("Selected Module Card: OK")
	lines.append("Action Panel: OK")
	lines.append("Status Badges: OK")
	lines.append("Readiness / Warnings: OK")
	lines.append("Reference / Preview: OK")
	lines.append("")
	lines.append("Manual checks still required:")
	lines.append("- Open Dashboard")
	lines.append("- Open External Modules")
	lines.append("- Open Internal Modules")
	lines.append("- Select storage cards")
	lines.append("- Place/remove external module")
	lines.append("- Place/remove/rotate internal module")
	lines.append("- Commit/remove overlay path")
	lines.append("- Toggle view modes")
	lines.append("- Open all reference reports")
	return "\n".join(lines)



func _make_panel_style(
	bg_color: Color,
	border_color: Color = UI_COLOR_BORDER_DIM,
	border_width: int = 1,
	corner_radius: int = 8
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _make_status_badge_style(role: String) -> StyleBoxFlat:
	var bg_color: Color = Color(0.080, 0.095, 0.115, 1.0)
	var border_color: Color = UI_COLOR_BORDER_DIM

	match role:
		"ok":
			bg_color = Color(0.045, 0.150, 0.095, 1.0)
			border_color = UI_COLOR_OK
		"warning":
			bg_color = Color(0.200, 0.120, 0.035, 1.0)
			border_color = UI_COLOR_WARNING
		"danger":
			bg_color = Color(0.200, 0.050, 0.050, 1.0)
			border_color = UI_COLOR_DANGER
		"info":
			bg_color = Color(0.055, 0.105, 0.160, 1.0)
			border_color = UI_COLOR_ACCENT
		"neutral":
			bg_color = Color(0.070, 0.080, 0.095, 1.0)
			border_color = UI_COLOR_BORDER_DIM
		_:
			pass

	return _make_panel_style(bg_color, border_color, 1, 6)


func _create_status_badge(label_text: String, role: String = "neutral", small: bool = false) -> Control:
	var panel: PanelContainer = PanelContainer.new()

	if small:
		panel.custom_minimum_size = STATUS_BADGE_SMALL_SIZE
	else:
		panel.custom_minimum_size = STATUS_BADGE_MIN_SIZE

	panel.add_theme_stylebox_override("panel", _make_status_badge_style(role))

	var label: Label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true

	match role:
		"ok":
			label.add_theme_color_override("font_color", UI_COLOR_OK.lightened(0.25))
		"warning":
			label.add_theme_color_override("font_color", UI_COLOR_WARNING.lightened(0.15))
		"danger":
			label.add_theme_color_override("font_color", UI_COLOR_DANGER.lightened(0.20))
		"info":
			label.add_theme_color_override("font_color", UI_COLOR_ACCENT.lightened(0.15))
		_:
			label.add_theme_color_override("font_color", UI_COLOR_TEXT)

	panel.add_child(label)
	_add_hover_scale_feedback(panel, Vector2(1.04, 1.04))
	if role == "danger":
		_apply_selected_pulse(panel)
	return panel


func _create_status_badge_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", STATUS_BADGE_GAP)
	return row


func _get_constructor_status_badges() -> Array[Dictionary]:
	var badges: Array[Dictionary] = []
	if bipob == null:
		return badges

	if bipob.has_method("is_virtual_power_available"):
		if bipob.is_virtual_power_available():
			badges.append({"label": "POWER OK", "role": "ok"})
		else:
			badges.append({"label": "POWER MISSING", "role": "danger"})

	if bipob.has_method("is_internal_data_network_available"):
		if bipob.is_internal_data_network_available():
			badges.append({"label": "DATA OK", "role": "ok"})
		else:
			badges.append({"label": "DATA MISSING", "role": "warning"})

	if bipob.has_method("is_external_data_network_available"):
		if bipob.is_external_data_network_available():
			badges.append({"label": "EXT LINK OK", "role": "ok"})
		else:
			badges.append({"label": "EXT LINK MISSING", "role": "warning"})

	if bipob.has_method("has_air_cooling_requiring_intake") and bipob.has_method("has_external_air_intake"):
		if bipob.has_air_cooling_requiring_intake():
			if bipob.has_external_air_intake():
				badges.append({"label": "AIR OK", "role": "ok"})
			else:
				badges.append({"label": "AIR REQUIRED", "role": "warning"})

	if bipob.has_method("get_highest_internal_preview_heat"):
		var highest_heat: int = bipob.get_highest_internal_preview_heat()
		if highest_heat >= 5:
			badges.append({"label": "THERMAL CRITICAL", "role": "danger"})
		elif highest_heat >= 4:
			badges.append({"label": "THERMAL WARNING", "role": "warning"})
		elif highest_heat > 0:
			badges.append({"label": "THERMAL OK", "role": "ok"})
		else:
			badges.append({"label": "THERMAL IDLE", "role": "neutral"})

	if bipob.has_method("get_overlay_heat_diff_compact_text"):
		var overlay_changed: bool = false
		if bipob.has_method("get_overlay_thermal_contribution_compact_text"):
			var compact_text: String = bipob.get_overlay_thermal_contribution_compact_text()
			overlay_changed = not compact_text.contains("affected 0")
		if overlay_changed:
			badges.append({"label": "OVERLAY ACTIVE", "role": "info"})
		else:
			badges.append({"label": "OVERLAY HYPOTH", "role": "neutral"})

	if bipob.has_method("get_damage_planning_compact_text"):
		var damage_text: String = bipob.get_damage_planning_compact_text()
		if damage_text.contains("critical 0 / warning 0"):
			badges.append({"label": "DAMAGE LOW", "role": "ok"})
		elif damage_text.contains("critical 0"):
			badges.append({"label": "DAMAGE WARN", "role": "warning"})
		else:
			badges.append({"label": "DAMAGE CRIT", "role": "danger"})

	var warning_count: int = 0
	if bipob.has_method("get_warning_count"):
		warning_count = bipob.get_warning_count()
	elif bipob.has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = bipob.get_constructor_warning_lines()
		warning_count = warning_lines.size()

	if warning_count <= 0:
		badges.append({"label": "NO WARNINGS", "role": "ok"})
	else:
		badges.append({"label": "WARNINGS %d" % warning_count, "role": "warning"})

	return badges


func _create_constructor_status_badges_panel(max_badges: int = -1) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)

	var title: Label = Label.new()
	title.text = "STATUS BADGES"
	_apply_label_style(title, false, true)
	root.add_child(title)

	var badges: Array[Dictionary] = _get_constructor_status_badges()
	if max_badges > 0 and badges.size() > max_badges:
		badges = badges.slice(0, max_badges)
	if badges.is_empty():
		root.add_child(_create_status_badge("NO STATUS", "neutral", false))
		panel.add_child(root)
		_fade_in_control(panel)
		return panel

	var row: HBoxContainer = _create_status_badge_row()
	var count_in_row: int = 0
	for badge in badges:
		var badge_label: String = String(badge.get("label", "STATUS"))
		var badge_role: String = String(badge.get("role", "neutral"))
		row.add_child(_create_status_badge(badge_label, badge_role, true))
		count_in_row += 1
		if count_in_row >= 3:
			root.add_child(row)
			row = _create_status_badge_row()
			count_in_row = 0

	if row.get_child_count() > 0:
		root.add_child(row)

	panel.add_child(root)
	_fade_in_control(panel)
	return panel




func _get_warning_category_title(category: String) -> String:
	match category:
		"power":
			return "POWER"
		"data":
			return "DATA NETWORK"
		"external":
			return "EXTERNAL LINK"
		"cooling":
			return "COOLING"
		"thermal":
			return "THERMAL"
		"damage":
			return "DAMAGE PREVIEW"
		"overlay":
			return "OVERLAY"
		"storage":
			return "BOX STORAGE"
		"placement":
			return "PLACEMENT"
		"consistency":
			return "CONSISTENCY"
		_:
			return "GENERAL"


func _get_warning_category_hint(category: String) -> String:
	match category:
		"power":
			return "Install Battery and Power Block."
		"data":
			return "Install Internal Interface and required data modules."
		"external":
			return "Install External Interface bridge for external devices."
		"cooling":
			return "Add Cooler/Radiator/Air Intake or adjust layout."
		"thermal":
			return "Reduce heat near hot modules or add cooling."
		"damage":
			return "Critical heat can damage modules later."
		"overlay":
			return "Overlay paths are hypothetical until committed."
		"storage":
			return "Check Box Storage availability."
		"placement":
			return "Move cursor or rotate selected module."
		"consistency":
			return "Constructor data needs cleanup."
		_:
			return "Check constructor setup."


func _get_warning_severity_role(severity: String) -> String:
	match severity:
		"ok":
			return "ok"
		"info":
			return "info"
		"warning":
			return "warning"
		"danger":
			return "danger"
		_:
			return "neutral"


func _make_constructor_warning_item(category: String, severity: String, message: String, hint: String = "") -> Dictionary:
	return {
		"category": category,
		"severity": severity,
		"message": message,
		"hint": hint
	}


func _infer_warning_category_from_text(text: String) -> String:
	var lower_text: String = text.to_lower()

	if lower_text.contains("power") or lower_text.contains("battery"):
		return "power"
	if lower_text.contains("data") or lower_text.contains("interface") or lower_text.contains("network"):
		return "data"
	if lower_text.contains("external"):
		return "external"
	if lower_text.contains("cool") or lower_text.contains("air") or lower_text.contains("intake"):
		return "cooling"
	if lower_text.contains("thermal") or lower_text.contains("heat"):
		return "thermal"
	if lower_text.contains("damage") or lower_text.contains("repair"):
		return "damage"
	if lower_text.contains("overlay") or lower_text.contains("tube") or lower_text.contains("duct"):
		return "overlay"
	if lower_text.contains("storage") or lower_text.contains("box"):
		return "storage"
	if lower_text.contains("place") or lower_text.contains("slot") or lower_text.contains("cell"):
		return "placement"
	if lower_text.contains("consistency") or lower_text.contains("invalid"):
		return "consistency"

	return "general"


func _infer_warning_severity_from_text(text: String) -> String:
	var lower_text: String = text.to_lower()

	if lower_text.contains("critical") or lower_text.contains("missing") or lower_text.contains("invalid"):
		return "danger"

	if lower_text.contains("warning") or lower_text.contains("required") or lower_text.contains("high"):
		return "warning"

	if lower_text.contains("info") or lower_text.contains("hypothetical"):
		return "info"

	return "warning"


func _get_constructor_warning_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if bipob == null:
		return items

	if bipob.has_method("is_virtual_power_available") and not bipob.is_virtual_power_available():
		items.append(_make_constructor_warning_item("power", "danger", "Virtual power network is incomplete.", "Install Battery and Power Block, then connect through automatic virtual wiring."))

	if bipob.has_method("is_internal_data_network_available") and not bipob.is_internal_data_network_available():
		items.append(_make_constructor_warning_item("data", "warning", "Internal data network is incomplete.", "Install Internal Interface and required processing/data modules."))

	if bipob.has_method("is_external_data_network_available") and not bipob.is_external_data_network_available():
		items.append(_make_constructor_warning_item("external", "warning", "External devices do not have a complete data bridge.", "Install External Interface and Internal Interface."))

	if bipob.has_method("has_air_cooling_requiring_intake") and bipob.has_method("has_external_air_intake"):
		if bipob.has_air_cooling_requiring_intake() and not bipob.has_external_air_intake():
			items.append(_make_constructor_warning_item("cooling", "warning", "Air cooling requires an external Air Intake.", "Place Air Intake Node on an external slot."))

	if bipob.has_method("get_highest_internal_preview_heat"):
		var highest_heat: int = bipob.get_highest_internal_preview_heat()
		if highest_heat >= 5:
			items.append(_make_constructor_warning_item("thermal", "danger", "Thermal preview reaches critical heat 5.", "Add cooling, move hot modules apart, or plan overlay cooling."))
		elif highest_heat >= 4:
			items.append(_make_constructor_warning_item("thermal", "warning", "Thermal preview has high heat 4.", "Consider cooler/radiator placement before mission use."))

	if bipob.has_method("get_damage_preview_critical_count") and bipob.has_method("get_damage_preview_warning_count"):
		var damage_critical_count: int = bipob.get_damage_preview_critical_count()
		var damage_warning_count: int = bipob.get_damage_preview_warning_count()
		if damage_critical_count > 0:
			items.append(_make_constructor_warning_item("damage", "danger", "Damage preview has %d critical module(s)." % damage_critical_count, "Lower heat below damage threshold."))
		elif damage_warning_count > 0:
			items.append(_make_constructor_warning_item("damage", "warning", "Damage preview has %d module(s) near threshold." % damage_warning_count, "Add cooling or move modules before using active abilities."))

	if bipob.has_method("get_overlay_heat_diff_compact_text"):
		var overlay_text: String = bipob.get_overlay_heat_diff_compact_text()
		if not overlay_text.contains("changed 0"):
			items.append(_make_constructor_warning_item("overlay", "info", "Overlay paths may improve hypothetical thermal preview.", "Overlay effects are informational until later gameplay rules."))

	if bipob.has_method("get_constructor_consistency_issue_count"):
		var consistency_count: int = bipob.get_constructor_consistency_issue_count()
		if consistency_count > 0:
			items.append(_make_constructor_warning_item("consistency", "danger", "Constructor consistency has %d issue(s)." % consistency_count, "Run Checkpoint and fix missing metadata or invalid records."))
	elif bipob.has_method("get_constructor_consistency_check_text"):
		var consistency_text: String = bipob.get_constructor_consistency_check_text()
		if not consistency_text.contains("OK") and not consistency_text.contains("ok"):
			items.append(_make_constructor_warning_item("consistency", "warning", "Constructor consistency needs review.", "Open Checkpoint or Overlay Check."))

	if bipob.has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = bipob.get_constructor_warning_lines()
		for warning_line in warning_lines:
			var line_text: String = String(warning_line)
			if line_text.is_empty():
				continue
			var already_covered: bool = false
			for item in items:
				if String(item.get("message", "")) == line_text:
					already_covered = true
					break
			if not already_covered:
				var inferred_category: String = _infer_warning_category_from_text(line_text)
				items.append(_make_constructor_warning_item(inferred_category, _infer_warning_severity_from_text(line_text), line_text, _get_warning_category_hint(inferred_category)))

	return items


func _get_constructor_readiness_state() -> Dictionary:
	var constructor_ready: bool = false
	var label: String = "NOT READY"
	var severity: String = "warning"
	var hint: String = "Review constructor warnings."
	if bipob == null:
		return {"ready": constructor_ready, "label": label, "severity": severity, "hint": hint, "danger_count": 0, "warning_count": 0}

	if bipob != null and bipob.has_method("is_constructor_ready"):
		constructor_ready = bipob.is_constructor_ready()
	elif bipob != null and bipob.has_method("get_constructor_readiness_compact_text"):
		var ready_text: String = bipob.get_constructor_readiness_compact_text()
		var ready_lower: String = ready_text.to_lower()
		constructor_ready = ready_lower.contains("ready") and not ready_lower.contains("not ready")

	if constructor_ready:
		label = "READY"
		severity = "ok"
		hint = "Configuration passes current constructor readiness checks."

	var warning_items: Array[Dictionary] = _get_constructor_warning_items()
	var danger_count: int = 0
	var warning_count: int = 0
	for item in warning_items:
		var item_severity: String = String(item.get("severity", "warning"))
		if item_severity == "danger":
			danger_count += 1
		elif item_severity == "warning":
			warning_count += 1

	if danger_count > 0:
		label = "BLOCKED"
		severity = "danger"
		hint = "Fix critical constructor issues first."
	elif warning_count > 0 and constructor_ready:
		label = "READY WITH WARNINGS"
		severity = "warning"
		hint = "Configuration can continue, but warnings remain."
	elif warning_count > 0:
		label = "NOT READY"
		severity = "warning"
		hint = "Fix warnings or complete required modules."

	return {"ready": constructor_ready, "label": label, "severity": severity, "hint": hint, "danger_count": danger_count, "warning_count": warning_count}


func _get_warning_severity_rank(severity: String) -> int:
	match severity:
		"danger":
			return 0
		"warning":
			return 1
		"info":
			return 2
		"ok":
			return 3
		_:
			return 4


func _sort_warning_items_for_display(items: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_items: Array[Dictionary] = items.duplicate()
	sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rank_a: int = _get_warning_severity_rank(String(a.get("severity", "warning")))
		var rank_b: int = _get_warning_severity_rank(String(b.get("severity", "warning")))
		if rank_a != rank_b:
			return rank_a < rank_b
		return String(a.get("category", "general")) < String(b.get("category", "general"))
	)
	return sorted_items


func _create_constructor_readiness_banner() -> Control:
	var state: Dictionary = _get_constructor_readiness_state()
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_status_badge_style(_get_warning_severity_role(String(state.get("severity", "warning")))))
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	var label: Label = Label.new()
	label.text = String(state.get("label", "NOT READY"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(label, false, true)
	root.add_child(label)
	var hint_text_label: Label = Label.new()
	hint_text_label.text = String(state.get("hint", "Review constructor setup."))
	hint_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(hint_text_label, true, false)
	root.add_child(hint_text_label)
	panel.add_child(root)
	return panel


func _create_warning_item_card(item: Dictionary) -> Control:
	var category: String = String(item.get("category", "general"))
	var severity: String = String(item.get("severity", "warning"))
	var message: String = String(item.get("message", "Warning"))
	var hint: String = String(item.get("hint", ""))
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_status_badge_style(_get_warning_severity_role(severity)))
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	var title: Label = Label.new()
	title.text = _get_warning_category_title(category)
	_apply_label_style(title, false, true)
	root.add_child(title)
	var message_label: Label = Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(message_label)
	root.add_child(message_label)
	if not hint.is_empty():
		var hint_text_label: Label = Label.new()
		hint_text_label.text = "Next: " + hint
		hint_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_label_style(hint_text_label, true, false)
		root.add_child(hint_text_label)
	panel.add_child(root)
	return panel


func _create_constructor_warning_readiness_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = "READINESS / WARNINGS"
	_apply_label_style(title, false, true)
	root.add_child(title)
	root.add_child(_create_constructor_readiness_banner())
	var items: Array[Dictionary] = _get_constructor_warning_items()
	if items.is_empty():
		root.add_child(_create_warning_item_card(_make_constructor_warning_item("general", "ok", "No constructor warnings.", "Configuration is clean for the current rule set.")))
	else:
		var sorted_items: Array[Dictionary] = _sort_warning_items_for_display(items)
		var shown_count: int = 0
		var max_shown: int = 6
		for item in sorted_items:
			if shown_count >= max_shown:
				break
			root.add_child(_create_warning_item_card(item))
			shown_count += 1
		if sorted_items.size() > max_shown:
			var more_label: Label = Label.new()
			more_label.text = "+%d more. Open Checkpoint for full details." % [sorted_items.size() - max_shown]
			_apply_label_style(more_label, true, false)
			root.add_child(more_label)
	panel.add_child(root)
	return panel


func _load_cached_module_type_icon_texture(path: String) -> Texture2D:
	if module_type_icon_texture_cache.has(path):
		return module_type_icon_texture_cache[path]
	if not ResourceLoader.exists(path):
		module_type_icon_texture_cache[path] = null
		return null
	var texture: Texture2D = load(path) as Texture2D
	module_type_icon_texture_cache[path] = texture
	return texture


func _has_module_type_icon_assets() -> bool:
	return _load_cached_module_type_icon_texture(MODULE_TYPE_ICON_BASE_PATH) != null and _load_cached_module_type_icon_texture(MODULE_TYPE_ICON_ATLAS_PATH) != null


func get_icon_rect(row: int, col: int) -> Rect2i:
	return Rect2i(
		(col - 1) * MODULE_TYPE_ICON_FRAME_SIZE.x,
		(row - 1) * MODULE_TYPE_ICON_FRAME_SIZE.y,
		MODULE_TYPE_ICON_FRAME_SIZE.x,
		MODULE_TYPE_ICON_FRAME_SIZE.y
	)


func _get_module_type_icon_atlas_texture(row: int, col: int) -> AtlasTexture:
	var atlas: Texture2D = _load_cached_module_type_icon_texture(MODULE_TYPE_ICON_ATLAS_PATH)
	if atlas == null:
		return null
	var cache_key: String = "%d:%d" % [row, col]
	if module_type_icon_atlas_region_cache.has(cache_key):
		return module_type_icon_atlas_region_cache[cache_key]
	var region_texture: AtlasTexture = AtlasTexture.new()
	region_texture.atlas = atlas
	region_texture.region = get_icon_rect(row, col)
	module_type_icon_atlas_region_cache[cache_key] = region_texture
	return region_texture


func _get_module_icon_version_number(module: BipobModule) -> int:
	if module == null:
		return 0
	var version_number: int = int(module.module_version)
	if version_number > 0:
		return version_number
	var version_text: String = String(module.version).strip_edges().to_lower()
	version_text = version_text.replace("version", "")
	version_text = version_text.replace("v", "")
	return int(version_text) if version_text.is_valid_int() else 0


func _get_module_icon_background_color(module: BipobModule) -> Color:
	if module == null or _is_module_unknown(module):
		return MODULE_VERSION_COLOR_UNKNOWN
	match _get_module_icon_version_number(module):
		1:
			return MODULE_VERSION_COLOR_V1
		2:
			return MODULE_VERSION_COLOR_V2
		3:
			return MODULE_VERSION_COLOR_V3
		_:
			return MODULE_VERSION_COLOR_UNKNOWN


func _module_search_text(module: BipobModule) -> String:
	if module == null:
		return ""
	var parts: Array[String] = []
	parts.append(String(module.id))
	parts.append(String(module.module_id))
	parts.append(String(module.display_name))
	parts.append(String(module.category))
	parts.append(String(module.placement_type))
	parts.append(String(module.internal_role))
	parts.append(String(module.internal_family))
	parts.append(String(module.interface_role))
	parts.append(String(module.movement_type))
	parts.append(String(module.tool_action))
	parts.append(String(module.connection_type))
	parts.append(String(module.defense_type))
	parts.append(String(module.scan_type))
	var tags_variant: Variant = module.get("tags")
	if tags_variant is Array:
		for tag in Array(tags_variant):
			parts.append(String(tag))
	return " ".join(parts).to_lower()


func _module_text_has_any(text: String, needles: Array) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false


func _is_module_icon_internal(module: BipobModule) -> bool:
	if module == null:
		return false
	if bipob != null and bipob.has_method("is_internal_module") and bipob.is_internal_module(module):
		return true
	var placement_text: String = String(module.placement_type).to_lower()
	var internal_role_text: String = String(module.internal_role).to_lower()
	return placement_text.contains("internal") or (not internal_role_text.is_empty() and internal_role_text != "none")


func _get_module_type_icon_atlas_cell(module: BipobModule) -> Vector2i:
	var search_text: String = _module_search_text(module)
	var is_internal_icon: bool = _is_module_icon_internal(module)
	if _is_module_unknown(module):
		return Vector2i(4, 4) if is_internal_icon else Vector2i(2, 4)
	if is_internal_icon:
		if _module_text_has_any(search_text, ["cooling", "cooler", "fan", "radiator"]):
			return Vector2i(3, 1)
		if _module_text_has_any(search_text, ["processor", "cpu"]):
			return Vector2i(3, 2)
		if _module_text_has_any(search_text, ["interface", "usb", "port", "network", "connector", "socket", "link"]):
			return Vector2i(3, 4)
		if _module_text_has_any(search_text, ["storage", "drive", "disk", "database", "hard_drive", "hdd", "ssd"]):
			return Vector2i(3, 5)
		if _module_text_has_any(search_text, ["ram", "memory"]):
			return Vector2i(4, 1)
		if _module_text_has_any(search_text, ["power", "battery", "energy"]):
			return Vector2i(4, 2)
		if _module_text_has_any(search_text, ["gpu", "graphics"]):
			return Vector2i(4, 3)
		if _module_text_has_any(search_text, ["unknown", "unk"]):
			return Vector2i(4, 4)
		return Vector2i(3, 3)

	if _module_text_has_any(search_text, ["sensor", "visor", "scanner", "radar", "xray", "motion_detector", "detector"]):
		return Vector2i(1, 1)
	if _module_text_has_any(search_text, ["manipulator", "arm", "tentacle", "claw", "magnetic"]):
		return Vector2i(1, 2)
	if _module_text_has_any(search_text, ["wheel", "leg", "track", "movement", "gear"]):
		return Vector2i(1, 3)
	if _module_text_has_any(search_text, ["armor", "armour", "shield", "defence", "defense"]):
		return Vector2i(1, 4)
	if _module_text_has_any(search_text, ["weapon", "laser", "missile", "gun", "shock"]):
		return Vector2i(1, 5)
	if _module_text_has_any(search_text, ["tool", "repair", "wrench", "torch", "cutter", "saw", "hammer", "welder"]):
		return Vector2i(2, 2)
	if _module_text_has_any(search_text, ["connector", "socket", "cable", "link", "interface"]):
		return Vector2i(2, 3)
	if _module_text_has_any(search_text, ["unknown", "unk"]):
		return Vector2i(2, 4)
	return Vector2i(2, 1)


func _create_texture_layer(texture: Texture2D, tint: Color) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.modulate = tint
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return texture_rect


func create_module_type_icon(module: BipobModule, display_size: Vector2 = MODULE_TYPE_ICON_TILE_SIZE) -> Control:
	var base_texture: Texture2D = _load_cached_module_type_icon_texture(MODULE_TYPE_ICON_BASE_PATH)
	var atlas_texture: Texture2D = _load_cached_module_type_icon_texture(MODULE_TYPE_ICON_ATLAS_PATH)
	if base_texture == null or atlas_texture == null:
		return null
	var container: Control = Control.new()
	container.custom_minimum_size = display_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.clip_contents = false
	container.add_child(_create_texture_layer(base_texture, _get_module_icon_background_color(module)))
	var border_texture: AtlasTexture = _get_module_type_icon_atlas_texture(4, 5)
	if border_texture == null:
		return null
	container.add_child(_create_texture_layer(border_texture, MODULE_TYPE_ICON_OVERLAY_COLOR))
	var icon_cell: Vector2i = _get_module_type_icon_atlas_cell(module)
	var icon_texture: AtlasTexture = _get_module_type_icon_atlas_texture(icon_cell.x, icon_cell.y)
	if icon_texture == null:
		return null
	container.add_child(_create_texture_layer(icon_texture, MODULE_TYPE_ICON_OVERLAY_COLOR))
	return container


func _anchor_module_type_icon_bottom_right(icon: Control, display_size: Vector2, padding: float) -> void:
	if icon == null:
		return
	icon.anchor_left = 1.0
	icon.anchor_top = 1.0
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.offset_left = -display_size.x - padding
	icon.offset_top = -display_size.y - padding
	icon.offset_right = -padding
	icon.offset_bottom = -padding
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_module_icon_badge(module: BipobModule, display_size: Vector2 = MODULE_TYPE_ICON_TILE_SIZE) -> Control:
	return create_module_type_icon(module, display_size)


func _apply_broken_overlay_to_module_tile(tile: Control, module: BipobModule) -> void:
	if tile == null or not _is_module_broken(module):
		return
	var overlay: ColorRect = ColorRect.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.85, 0.05, 0.05, 0.42)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(overlay)


func _apply_module_icon_badge_to_tile(tile: Control, module: BipobModule) -> void:
	if tile == null or not _has_module_type_icon_assets():
		return
	var overlay_icon: Control = _build_module_icon_badge(module, MODULE_TYPE_ICON_TILE_SIZE)
	if overlay_icon == null:
		return
	_anchor_module_type_icon_bottom_right(overlay_icon, MODULE_TYPE_ICON_TILE_SIZE, MODULE_TYPE_ICON_TILE_PADDING)
	tile.add_child(overlay_icon)


func _apply_module_icon_badge_to_preview_block(preview_block: Control, module: BipobModule, display_size: Vector2 = MODULE_TYPE_ICON_PREVIEW_BADGE_SIZE) -> Control:
	if preview_block == null or not _has_module_type_icon_assets():
		return preview_block
	var badge: Control = _build_module_icon_badge(module, display_size)
	if badge == null:
		return preview_block
	var wrapper: Control = Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.clip_contents = false
	var preview_min_size: Vector2 = preview_block.custom_minimum_size
	if preview_min_size == Vector2.ZERO:
		preview_min_size = preview_block.get_combined_minimum_size()
	if preview_min_size == Vector2.ZERO:
		preview_min_size = display_size + Vector2(MODULE_TYPE_ICON_TILE_PADDING * 2.0, MODULE_TYPE_ICON_TILE_PADDING * 2.0)
	wrapper.custom_minimum_size = preview_min_size
	wrapper.size_flags_horizontal = preview_block.size_flags_horizontal
	wrapper.size_flags_vertical = preview_block.size_flags_vertical
	preview_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_block.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_block.offset_left = 0.0
	preview_block.offset_top = 0.0
	preview_block.offset_right = 0.0
	preview_block.offset_bottom = 0.0
	wrapper.add_child(preview_block)
	_anchor_module_type_icon_bottom_right(badge, display_size, MODULE_TYPE_ICON_TILE_PADDING)
	wrapper.add_child(badge)
	return wrapper


func _load_module_icon_texture(module: BipobModule) -> Texture2D:
	if module == null:
		return null

	var key: String = bipob.get_module_visual_key(module)
	if module_icon_texture_cache.has(key):
		return module_icon_texture_cache[key]

	var path: String = bipob.get_module_icon_path_by_key(key)
	if not ResourceLoader.exists(path):
		module_icon_texture_cache[key] = null
		return null

	var texture: Texture2D = load(path) as Texture2D
	module_icon_texture_cache[key] = texture
	return texture

func _create_module_icon_control(module: BipobModule, size: Vector2 = Vector2(44, 44)) -> Control:
	var type_icon: Control = create_module_type_icon(module, size)
	if type_icon != null:
		return type_icon

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = size

	var bg_color: Color = bipob.get_module_visual_color(module)
	var border_color: Color = bipob.get_module_visual_border_color(module)
	panel.add_theme_stylebox_override("panel", _make_panel_style(bg_color.darkened(0.55), border_color, 1, 6))

	var texture: Texture2D = _load_module_icon_texture(module)
	if texture != null:
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(texture_rect)
	else:
		var label: Label = Label.new()
		label.text = bipob.get_module_visual_short_label(module)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		panel.add_child(label)

	return panel

func _create_module_placeholder_icon(module: BipobModule, size: Vector2 = Vector2(44, 44)) -> Control:
	return _create_module_icon_control(module, size)


func _make_storage_card_style(module: BipobModule, selected: bool = false, disabled: bool = false) -> StyleBoxFlat:
	var bg_color: Color = UI_COLOR_PANEL_DARK
	var border_color: Color = UI_COLOR_BORDER_DIM
	var border_width: int = 1

	if module != null and bipob.has_method("get_module_visual_color"):
		var module_color: Color = bipob.get_module_visual_color(module)
		bg_color = module_color.darkened(0.72)
		border_color = module_color.darkened(0.15)

	if selected:
		border_color = UI_COLOR_SELECTED
		border_width = 2

	if disabled:
		bg_color = Color(0.045, 0.048, 0.055, 0.85)
		border_color = UI_COLOR_DISABLED

	return _make_panel_style(bg_color, border_color, border_width, 6)


func _get_module_card_size_text(module: BipobModule) -> String:
	if module == null:
		return "?"

	if bipob.is_internal_overlay_module(module):
		return "overlay"

	if bipob.is_internal_module(module):
		var internal_size: Vector3i = bipob.get_internal_module_base_size(module)
		return "%dx%dx%d" % [internal_size.x, internal_size.y, internal_size.z]

	if bipob.is_external_module(module):
		var footprint_size: Vector2i = bipob.get_external_module_footprint_size(module)
		return "%dx%d" % [footprint_size.x, footprint_size.y]

	return "module"


func _get_selected_box_storage_module() -> BipobModule:
	if bipob == null:
		return null
	if selected_constructor_module != null:
		return selected_constructor_module
	if selected_module_source != "storage":
		return null
	if selected_box_storage_index < 0:
		return null
	if selected_box_storage_index >= bipob.box_storage.size():
		return null
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	return module


func _get_module_placement_display_text(module: BipobModule) -> String:
	if module == null:
		return "none"
	if bipob.is_internal_overlay_module(module):
		return "overlay path"
	if bipob.is_internal_module(module):
		return "internal volume"
	if bipob.is_external_module(module):
		return "external slots"
	return String(module.placement_type)


func _get_selected_module_size_text(module: BipobModule) -> String:
	if module == null:
		return "none"
	if bipob.is_internal_overlay_module(module):
		return "overlay path"
	if bipob.is_internal_module(module):
		var internal_size: Vector3i = bipob.get_internal_module_base_size(module)
		return "%dx%dx%d" % [internal_size.x, internal_size.y, internal_size.z]
	if bipob.is_external_module(module):
		var footprint_size: Vector2i = bipob.get_external_module_footprint_size(module)
		return "%dx%d" % [footprint_size.x, footprint_size.y]
	return "module"


func _get_module_heat_text(module: BipobModule) -> String:
	if module == null:
		return "Heat: none"

	if module.heat_idle <= 0 and module.heat_active <= 0:
		return "Heat: none"

	return "Heat: idle %d / active %d" % [
		module.heat_idle,
		module.heat_active
	]

func _get_module_role_text(module: BipobModule) -> String:
	if module == null:
		return "none"

	if bipob.is_internal_module(module):
		if not String(module.internal_role).is_empty():
			return String(module.internal_role)

	if bipob.is_external_module(module):
		return "external_device"

	if bipob.is_internal_overlay_module(module):
		if module.id.contains("air_duct"):
			return "duct_path"
		return "liquid_path"

	return "module"


func _get_module_visual_summary_text(module: BipobModule) -> String:
	if module == null:
		return "Visual: none"
	var key: String = "module"
	var label: String = "MOD"
	if bipob.has_method("get_module_visual_key"):
		key = bipob.get_module_visual_key(module)
	if bipob.has_method("get_module_visual_short_label"):
		label = bipob.get_module_visual_short_label(module)
	return "Visual: %s / %s" % [label, key]


func _get_selected_module_availability_text(module: BipobModule) -> String:
	if module == null:
		return "Availability: none"
	if bipob.has_method("get_module_availability_text"):
		return bipob.get_module_availability_text(module)
	var module_id: String = module.id
	var box_count: int = 0
	for stored_module in bipob.box_storage:
		if stored_module != null and stored_module.id == module_id:
			box_count += 1
	return "Availability: box %d" % box_count


func _get_selected_module_stat_lines(module: BipobModule) -> Array[String]:
	var lines: Array[String] = []
	if module == null:
		return lines
	lines.append("Placement: %s" % _get_module_placement_display_text(module))
	lines.append("Category: %s" % String(module.category))
	lines.append("Size: %s" % _get_selected_module_size_text(module))
	lines.append("Role: %s" % _get_module_role_text(module))
	if bipob.is_external_module(module):
		if bipob.has_method("get_allowed_external_sides_for_module"):
			var allowed_sides: Array[String] = bipob.get_allowed_external_sides_for_module(module)
			var side_names: Array[String] = []
			for side_id in allowed_sides:
				side_names.append(_get_external_side_display_name(String(side_id)))
			lines.append("Allowed: %s" % ", ".join(side_names))
		var footprint_size: Vector2i = bipob.get_external_module_footprint_size(module)
		lines.append("Footprint: %dx%d" % [footprint_size.x, footprint_size.y])
		if box_menu_mode == BoxMenuMode.EXTERNAL:
			lines.append("Selected Side: %s" % _get_external_side_display_name(String(bipob.selected_external_side)))
			lines.append("Selected Cell: %d,%d" % [bipob.selected_external_origin.x, bipob.selected_external_origin.y])
			var can_place_external: bool = bipob.can_place_external_module(module, bipob.selected_external_side, bipob.selected_external_origin)
			lines.append("Can Place: %s" % get_yes_no(can_place_external))
	if bipob.is_internal_module(module):
		var base_size: Vector3i = bipob.get_internal_module_base_size(module)
		var rotated_size: Vector3i = bipob.get_rotated_internal_size(module, bipob.selected_internal_rotation)
		lines.append("Base Volume: %dx%dx%d" % [base_size.x, base_size.y, base_size.z])
		lines.append("Rotated Volume: %dx%dx%d" % [rotated_size.x, rotated_size.y, rotated_size.z])
		if box_menu_mode == BoxMenuMode.INTERNAL:
			lines.append("Origin: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
			lines.append("Rotation: %d" % bipob.selected_internal_rotation)
			var can_place_internal: bool = bipob.can_place_internal_module(module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
			lines.append("Can Place: %s" % get_yes_no(can_place_internal))
	if bipob.is_internal_overlay_module(module):
		var overlay_type: String = "liquid"
		if module.id.contains("air_duct"):
			overlay_type = "duct"
		lines.append("Overlay Type: %s" % overlay_type)
		lines.append("Plan Cells: %d" % bipob.selected_overlay_cells.size())
		lines.append("Commit uses one module from Box Storage")
		lines.append("Note: does not consume Internal Volume")
	var heat_idle_value: int = int(module.get("heat_idle") if module.get("heat_idle") != null else 0)
	var heat_active_value: int = int(module.get("heat_active") if module.get("heat_active") != null else 0)
	if heat_idle_value > 0 or heat_active_value > 0:
		lines.append("Heat: idle %d / active %d" % [heat_idle_value, heat_active_value])
	var cooling_power_value: int = int(module.get("cooling_power") if module.get("cooling_power") != null else 0)
	if cooling_power_value > 0:
		lines.append("Cooling: %s %d" % [String(module.get("cooling_type")), cooling_power_value])
	if bool(module.get("requires_air_intake")):
		lines.append("Air Intake: required")
	if bool(module.get("can_be_damaged")):
		lines.append("Repair: threshold %d / complexity %d / %s" % [int(module.get("damage_threshold_heat")), int(module.get("repair_complexity")), String(module.get("repair_category"))])
	return lines


func _is_line_or_overlay_component(module: BipobModule) -> bool:
	if module == null:
		return false

	var module_id: String = String(module.id).to_lower()
	var line_ids: Array[String] = [
		"water_tube",
		"air_duct",
		"cooling_line",
		"power_line",
		"data_line",
		"overlay_path"
	]
	for line_id in line_ids:
		if module_id == line_id or module_id.begins_with("%s_" % line_id):
			return true

	var placement_type: String = String(module.placement_type).to_lower()
	if placement_type in ["overlay", "path", "line"]:
		return true

	return bool(module.get("is_non_volume_cooling_path"))


func _should_show_module_in_internal_storage(module: BipobModule) -> bool:
	if module == null:
		return false
	if _is_line_or_overlay_component(module):
		return false
	if bipob != null and bipob.has_method("is_internal_module") and bipob.is_internal_module(module):
		return true

	var placement_type: String = String(module.placement_type).to_lower()
	var internal_role: String = String(module.internal_role).to_lower()
	return placement_type.contains("internal") or (not internal_role.is_empty() and internal_role != "none")


func _is_module_valid_for_current_constructor_mode(module: BipobModule) -> bool:
	if module == null:
		return false

	if box_menu_mode == BoxMenuMode.INTERNAL:
		return _should_show_module_in_internal_storage(module)

	if box_menu_mode == BoxMenuMode.EXTERNAL:
		return bipob.is_external_module(module)

	return true


func _create_storage_module_card(module: BipobModule, storage_index: int, selected: bool) -> Control:
	var button: Button = Button.new()
	button.custom_minimum_size = STORAGE_CARD_MIN_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true

	var disabled_visual: bool = not _is_module_valid_for_current_constructor_mode(module)
	button.add_theme_stylebox_override("normal", _make_storage_card_style(module, selected, disabled_visual))
	button.add_theme_stylebox_override("hover", _make_storage_card_style(module, true, disabled_visual))
	button.add_theme_stylebox_override("pressed", _make_storage_card_style(module, true, disabled_visual))
	button.add_theme_color_override("font_color", UI_COLOR_TEXT)

	var root: VBoxContainer = VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var has_composed_icon: bool = _has_module_type_icon_assets()
	if not has_composed_icon:
		var icon: Control = _create_module_icon_control(module, STORAGE_CARD_ICON_SIZE)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.add_child(icon)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label: Label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = _get_module_known_label(module, bipob.is_external_module(module))
	name_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	name_label.clip_text = true

	var meta_label: Label = Label.new()
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label_text: String = "MOD"
	if bipob.has_method("get_module_visual_short_label"):
		label_text = bipob.get_module_visual_short_label(module)
	if has_composed_icon:
		meta_label.text = "UNK\nTBD" if _is_module_unknown(module) else _get_module_card_size_text(module)
	else:
		meta_label.text = "UNK\nTBD" if _is_module_unknown(module) else "%s\n%s" % [label_text, _get_module_card_size_text(module)]
	meta_label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.clip_text = true

	title_box.add_child(name_label)
	title_box.add_child(meta_label)
	top_row.add_child(title_box)
	root.add_child(top_row)

	button.add_child(root)
	_apply_broken_overlay_to_module_tile(button, module)
	if has_composed_icon:
		_apply_module_icon_badge_to_tile(button, module)
	_add_hover_scale_feedback(button)
	if selected:
		_apply_selected_pulse(button)

	if storage_index >= 0:
		button.pressed.connect(func() -> void:
			_on_storage_module_card_pressed(storage_index)
		)

	return button



func _make_button_style(
	bg_color: Color,
	border_color: Color,
	corner_radius: int = 6
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _apply_panel_style(panel: Control, accent: bool = false) -> void:
	if panel == null:
		return
	var border_color: Color = UI_COLOR_BORDER if accent else UI_COLOR_BORDER_DIM
	var style: StyleBoxFlat = _make_panel_style(UI_COLOR_PANEL, border_color, 1, 8)
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", style)
	elif panel is Panel:
		panel.add_theme_stylebox_override("panel", style)

func _apply_dark_panel_style(panel: Control) -> void:
	if panel == null:
		return
	var style: StyleBoxFlat = _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 8)
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", style)
	elif panel is Panel:
		panel.add_theme_stylebox_override("panel", style)

func _apply_label_style(label: Label, dim: bool = false, accent: bool = false) -> void:
	if label == null:
		return
	if accent:
		label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	elif dim:
		label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	else:
		label.add_theme_color_override("font_color", UI_COLOR_TEXT)

func _apply_button_style(button: Button, role: String = "normal") -> void:
	_apply_action_button_style(button, role, true)

func _create_ui_tween(node: Node) -> Tween:
	if node == null:
		return null
	if not is_instance_valid(node):
		return null
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween

func _apply_selected_pulse(control: Control) -> void:
	if control == null:
		return
	if not is_instance_valid(control):
		return
	if control.has_meta("selected_pulse_active"):
		return
	control.set_meta("selected_pulse_active", true)
	control.modulate.a = UI_ANIM_PULSE_ALPHA_HIGH
	var tween: Tween = _create_ui_tween(control)
	if tween == null:
		control.remove_meta("selected_pulse_active")
		return
	control.set_meta("selected_pulse_tween", tween)
	tween.set_loops()
	tween.tween_property(control, "modulate:a", UI_ANIM_PULSE_ALPHA_LOW, UI_ANIM_MEDIUM)
	tween.tween_property(control, "modulate:a", UI_ANIM_PULSE_ALPHA_HIGH, UI_ANIM_MEDIUM)

func _clear_selected_pulse(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	if control.has_meta("selected_pulse_tween"):
		var pulse_tween: Variant = control.get_meta("selected_pulse_tween")
		if pulse_tween is Tween and is_instance_valid(pulse_tween):
			pulse_tween.kill()
		control.remove_meta("selected_pulse_tween")
	if control.has_meta("selected_pulse_active"):
		control.remove_meta("selected_pulse_active")
	control.modulate = Color.WHITE

func _apply_invalid_preview_blink(control: Control) -> void:
	if control == null:
		return
	if not is_instance_valid(control):
		return
	var tween: Tween = _create_ui_tween(control)
	if tween == null:
		return
	tween.set_loops()
	tween.tween_property(control, "modulate:a", 0.55, 0.18)
	tween.tween_property(control, "modulate:a", 1.0, 0.18)

func _add_hover_scale_feedback(control: Control, hover_scale: Vector2 = Vector2(1.03, 1.03)) -> void:
	if control == null:
		return
	if control.has_meta("hover_feedback_added"):
		return
	control.set_meta("hover_feedback_added", true)
	control.pivot_offset = control.size * 0.5
	control.mouse_entered.connect(func() -> void:
		if not is_instance_valid(control):
			return
		control.pivot_offset = control.size * 0.5
		var tween: Tween = _create_ui_tween(control)
		if tween != null:
			tween.tween_property(control, "scale", hover_scale, UI_ANIM_FAST)
	)
	control.mouse_exited.connect(func() -> void:
		if not is_instance_valid(control):
			return
		var tween: Tween = _create_ui_tween(control)
		if tween != null:
			tween.tween_property(control, "scale", Vector2.ONE, UI_ANIM_FAST)
	)

func _flash_control(control: Control, flash_color: Color = Color(1, 1, 1, 1), duration: float = 0.16) -> void:
	if control == null:
		return
	if not is_instance_valid(control):
		return
	var original_modulate: Color = control.modulate
	var tween: Tween = _create_ui_tween(control)
	if tween == null:
		return
	tween.tween_property(control, "modulate", flash_color, duration)
	tween.tween_property(control, "modulate", original_modulate, duration)

func _fade_in_control(control: Control) -> void:
	if control == null:
		return
	control.modulate.a = 0.0
	var tween: Tween = _create_ui_tween(control)
	if tween == null:
		control.modulate.a = 1.0
		return
	tween.tween_property(control, "modulate:a", 1.0, UI_ANIM_MEDIUM)

func _apply_action_button_style(button: Button, role: String = "normal", available: bool = true) -> void:
	if button == null:
		return
	var actual_role: String = role
	if not available:
		actual_role = "disabled"
	var normal_bg: Color = Color(0.105, 0.130, 0.160, 1.0)
	var hover_bg: Color = Color(0.145, 0.185, 0.220, 1.0)
	var pressed_bg: Color = Color(0.070, 0.100, 0.130, 1.0)
	var border_color: Color = UI_COLOR_BORDER_DIM
	var font_color: Color = UI_COLOR_TEXT
	match actual_role:
		"primary":
			normal_bg = Color(0.060, 0.220, 0.160, 1.0)
			hover_bg = Color(0.080, 0.320, 0.220, 1.0)
			pressed_bg = Color(0.040, 0.150, 0.110, 1.0)
			border_color = UI_COLOR_OK
		"danger":
			normal_bg = Color(0.220, 0.065, 0.065, 1.0)
			hover_bg = Color(0.330, 0.090, 0.090, 1.0)
			pressed_bg = Color(0.150, 0.045, 0.045, 1.0)
			border_color = UI_COLOR_DANGER
		"warning":
			normal_bg = Color(0.240, 0.150, 0.050, 1.0)
			hover_bg = Color(0.340, 0.210, 0.070, 1.0)
			pressed_bg = Color(0.160, 0.095, 0.035, 1.0)
			border_color = UI_COLOR_WARNING
		"reference":
			normal_bg = Color(0.080, 0.110, 0.170, 1.0)
			hover_bg = Color(0.110, 0.150, 0.240, 1.0)
			pressed_bg = Color(0.055, 0.080, 0.130, 1.0)
			border_color = UI_COLOR_ACCENT
		"disabled":
			normal_bg = Color(0.055, 0.060, 0.070, 0.85)
			hover_bg = normal_bg
			pressed_bg = normal_bg
			border_color = UI_COLOR_DISABLED
			font_color = UI_COLOR_TEXT_DIM
		_:
			pass
	button.custom_minimum_size = ACTION_BUTTON_MIN_SIZE
	button.add_theme_stylebox_override("normal", _make_button_style(normal_bg, border_color, 6))
	button.add_theme_stylebox_override("hover", _make_button_style(hover_bg, border_color, 6))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed_bg, border_color, 6))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.050, 0.055, 0.065, 1.0), UI_COLOR_DISABLED, 6))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", UI_COLOR_TEXT_DIM)

func _get_status_color(status: String) -> Color:
	var normalized: String = status.to_lower()
	if normalized.contains("ok") or normalized.contains("available") or normalized.contains("ready"):
		return UI_COLOR_OK
	if normalized.contains("warning") or normalized.contains("missing"):
		return UI_COLOR_WARNING
	if normalized.contains("critical") or normalized.contains("danger") or normalized.contains("unavailable"):
		return UI_COLOR_DANGER
	return UI_COLOR_TEXT

func _get_button_role(button_text: String) -> String:
	match button_text:
		"Place", "Commit Plan", "Start", "Install", "Confirm":
			return "primary"
		"Remove", "Remove Path", "Clear Plan", "Clear Overlay", "Delete":
			return "danger"
		"Damage Plan", "Thermal Rules", "Repair Rules":
			return "warning"
		"Checkpoint", "Overlay Check", "Endpoints", "Overlay Thermal", "Overlay Diff":
			return "reference"
		_:
			return "normal"

func _create_action_group_panel(title_text: String) -> VBoxContainer:
	var group: VBoxContainer = VBoxContainer.new()
	group.add_theme_constant_override("separation", ACTION_BUTTON_SPACING)
	var title: Label = Label.new()
	title.text = title_text.to_upper()
	_apply_label_style(title, false, true)
	group.add_child(title)
	return group

func _create_action_button_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", ACTION_BUTTON_SPACING)
	return row

func _add_action_button(
	parent: Control,
	text: String,
	callback: Callable,
	role: String = "normal",
	available: bool = true,
	compact: bool = false
) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = ACTION_BUTTON_COMPACT_SIZE if compact else ACTION_BUTTON_MIN_SIZE
	_apply_action_button_style(button, role, available)
	_add_hover_scale_feedback(button, Vector2(1.025, 1.025))
	button.pressed.connect(func() -> void:
		_flash_control(button, Color(1.0, 1.0, 1.0, 1.0), 0.08)
		callback.call()
	)
	parent.add_child(button)
	return button

func _apply_constructor_ui_skin() -> void:
	_apply_dark_panel_style(command_panel)
	var panel: PanelContainer = box_screen.get_node_or_null("PanelContainer") if box_screen != null else null
	_apply_panel_style(panel, true)
	if box_content_scroll != null:
		box_content_scroll.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 8))
	if box_title_label != null:
		_apply_label_style(box_title_label, false, true)
	if box_content_label != null:
		box_content_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
		box_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if hud_status_label != null:
		_apply_label_style(hud_status_label)
	if hint_label != null:
		_apply_label_style(hint_label, true)
	if hud_diagnostic_label != null:
		_apply_label_style(hud_diagnostic_label, true)
	for tab_button in [external_tab_button, internal_tab_button, bipob_alpha_button, bipob_beta_button, box_back_button]:
		if tab_button != null:
			_apply_button_style(tab_button)
	if right_button_panel != null:
		for child in right_button_panel.get_children():
			if child is Button:
				_apply_button_style(child, _get_button_role(child.text))
			elif child is Label:
				var label_child: Label = child
				_apply_label_style(label_child, false, true)

func _configure_box_layout() -> void:
	if box_screen == null:
		return
	var panel: PanelContainer = box_screen.get_node_or_null("PanelContainer")
	var vbox: VBoxContainer = box_screen.get_node_or_null("PanelContainer/VBoxContainer")
	if panel == null or vbox == null:
		return
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -540
	panel.offset_top = 5
	panel.offset_right = -16
	panel.offset_bottom = -8
	panel.custom_minimum_size = Vector2(520, 0)
	vbox.add_theme_constant_override("separation", 5)

	main_box_row = vbox.get_node_or_null("MainBoxRow")
	if main_box_row == null:
		main_box_row = HBoxContainer.new()
		main_box_row.name = "MainBoxRow"
		vbox.add_child(main_box_row)
	if main_box_row.get_parent() == vbox:
		vbox.move_child(main_box_row, 0)

	left_panel = vbox.get_node_or_null("MainBoxRow/LeftPanel")
	if left_panel == null:
		left_panel = VBoxContainer.new()
		left_panel.name = "LeftPanel"
		main_box_row.add_child(left_panel)
	left_panel.custom_minimum_size = Vector2(350, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if box_title_label != null:
		box_title_label.reparent(left_panel)
		box_title_label.visible = false

	box_tab_row = left_panel.get_node_or_null("BoxTabRow")
	if box_tab_row == null:
		box_tab_row = HBoxContainer.new()
		box_tab_row.name = "BoxTabRow"
		left_panel.add_child(box_tab_row)
	box_tab_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box_tab_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	box_tab_row.custom_minimum_size = Vector2(0, 44)
	box_top_bar_root = box_tab_row

	box_content_scroll = left_panel.get_node_or_null("BoxContentScroll")
	if box_content_scroll == null:
		box_content_scroll = ScrollContainer.new()
		box_content_scroll.name = "BoxContentScroll"
		left_panel.add_child(box_content_scroll)
	box_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box_content_scroll.custom_minimum_size = Vector2(320, 320)
	box_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	box_content_label = box_content_scroll.get_node_or_null("BoxContentLabel")
	if box_content_label == null:
		box_content_label = Label.new()
		box_content_label.name = "BoxContentLabel"
		box_content_scroll.add_child(box_content_label)
	box_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_content_label.visible = false

	box_constructor_content_root = box_content_scroll.get_node_or_null("BoxConstructorContentRoot")
	if box_constructor_content_root == null:
		box_constructor_content_root = VBoxContainer.new()
		box_constructor_content_root.name = "BoxConstructorContentRoot"
		box_content_scroll.add_child(box_constructor_content_root)
	box_constructor_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_constructor_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if box_status_label != null:
		box_status_label.visible = false
		box_status_label.text = ""
		box_status_label.custom_minimum_size = Vector2.ZERO
	if box_module_label != null:
		box_module_label.visible = false
		box_module_label.text = ""
		box_module_label.custom_minimum_size = Vector2.ZERO
	if installed_modules_label != null:
		installed_modules_label.visible = false
		installed_modules_label.text = ""
		installed_modules_label.custom_minimum_size = Vector2.ZERO
	if box_storage_label != null:
		box_storage_label.visible = false
		box_storage_label.text = ""
	if digital_storage_label != null:
		digital_storage_label.visible = false
		digital_storage_label.text = ""

	var old_button_row := vbox.get_node_or_null("ButtonRow")
	if old_button_row != null:
		old_button_row.visible = false
		if old_button_row is Control:
			var old_button_row_control: Control = old_button_row
			old_button_row_control.custom_minimum_size = Vector2.ZERO
		for child in old_button_row.get_children():
			child.queue_free()

	for row_name in ["InstalledButtonRow", "BoxStorageButtonRow", "MissionButtonRow"]:
		var old_row := vbox.get_node_or_null(row_name)
		if old_row != null:
			old_row.visible = false
			for child in old_row.get_children():
				child.queue_free()

	right_button_panel = main_box_row.get_node_or_null("RightButtonPanel")
	if right_button_panel == null:
		right_button_panel = VBoxContainer.new()
		right_button_panel.name = "RightButtonPanel"
		main_box_row.add_child(right_button_panel)
	right_button_panel.custom_minimum_size = Vector2(230, 0)
	right_button_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_button_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func get_short_module_name(module: BipobModule) -> String:
	if module == null:
		return "empty"
	return bipob.get_module_display_name(module)

func get_selected_installed_module_text() -> String:
	if bipob == null or bipob.installed_modules.is_empty():
		return "Selected installed: none"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.installed_modules[selected_installed_module_index]
	return "Selected installed: " + get_short_module_name(module)

func get_selected_box_module_text() -> String:
	if bipob == null:
		return "Selected box: none"
	sync_selected_box_storage_index_from_filter()
	if bipob.box_storage.is_empty() or selected_box_storage_index < 0 or selected_box_storage_index >= bipob.box_storage.size():
		return "Selected box: none"
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	return "Selected box: " + get_short_module_name(module)

func _get_active_filter_index() -> int:
	return internal_filter_index if box_menu_mode == BoxMenuMode.INTERNAL else external_filter_index

func _set_active_filter_index(value: int) -> void:
	if box_menu_mode == BoxMenuMode.INTERNAL:
		internal_filter_index = value
	else:
		external_filter_index = value

func get_current_constructor_filter() -> String:
	var filter_index: int = _get_active_filter_index()
	if filter_index < 0:
		filter_index = CONSTRUCTOR_FILTERS.size() - 1
	elif filter_index >= CONSTRUCTOR_FILTERS.size():
		filter_index = 0
	_set_active_filter_index(filter_index)
	return String(CONSTRUCTOR_FILTERS[filter_index])

func _is_module_unknown(module: BipobModule) -> bool:
	if module == null:
		return false
	if module.get("status") != null:
		return String(module.get("status")) == "unknown"
	if module.get("is_unknown") != null:
		return bool(module.get("is_unknown"))
	if module.get("is_researched") != null:
		return not bool(module.get("is_researched"))
	if module.get("known") != null:
		return not bool(module.get("known"))
	if module.get("researched") != null:
		return not bool(module.get("researched"))
	return false

func _is_module_broken(module: BipobModule) -> bool:
	if module == null:
		return false
	if module.get("status") != null:
		return String(module.get("status")) == "broken"
	for key in ["is_broken", "broken", "is_damaged", "damaged"]:
		if module.get(key) != null:
			return bool(module.get(key))
	return false

func _is_module_ready(module: BipobModule) -> bool:
	if module == null:
		return false
	if module.get("status") != null:
		return String(module.get("status")) == "ready"
	return not _is_module_broken(module) and not _is_module_unknown(module)

func _text_contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false

func _get_module_filter_group(module: BipobModule, is_external: bool) -> String:
	if module == null:
		return "other"
	var values: Array[String] = []
	for key in ["id", "module_type", "category", "internal_role", "placement_type", "name", "description"]:
		var value = module.get(key)
		if value != null:
			values.append(String(value).to_lower())
	var haystack: String = " ".join(values)
	if is_external:
		if _text_contains_any(haystack, ["wheel", "wheels", "leg", "legs", "track", "tracks", "chassis", "gear", "movement"]):
			return "gear"
		if _text_contains_any(haystack, ["visor", "radar", "sensor", "scanner", "xray", "thermal"]):
			return "visor_radar"
		if String(module.category) == "Gear":
			return "gear"
		if String(module.category) == "Sensors":
			return "visor_radar"
		if String(module.category) == "Manipulator":
			return "manipulator"
		if String(module.category) == "Interface":
			return "interface"
		if String(module.category) == "Tools":
			return "tool"
		if String(module.category) == "Weapons":
			return "weapon"
		if String(module.category) == "Defense":
			return "armor"
		if String(module.category) == "Other":
			return "other"
		if _text_contains_any(haystack, ["tool", "welding", "welder", "repair", "cutter", "drill"]):
			return "tool"
		if _text_contains_any(haystack, ["manipulator", "arm", "claw", "hand", "magnetic"]):
			return "manipulator"
		if _text_contains_any(haystack, ["armor", "shield", "ram", "protection", "defense"]):
			return "armor"
		if _text_contains_any(haystack, ["weapon", "laser", "plasma", "shock", "shocker", "flame", "flamethrower", "saw", "hammer", "gun", "cannon"]):
			return "weapon"
	else:
		if String(module.category) == "Power":
			return "power"
		if String(module.category) == "CPU" or String(module.category) == "GPU":
			return "cpu_gpu"
		if String(module.category) == "RAM" or String(module.category) == "Storage":
			return "ram_sd"
		if String(module.category) == "Cooling":
			return "cooling"
		if String(module.category) == "Interface":
			return "interface"
		if String(module.category) == "Other":
			return "other"
		if _text_contains_any(haystack, ["processor", "cpu", "gpu"]):
			return "cpu_gpu"
		if _text_contains_any(haystack, ["cooler", "cooling", "radiator", "tube", "duct", "air"]):
			return "cooling"
		if _text_contains_any(haystack, ["memory", "ram", "hard_drive", "drive", "sd", "storage"]):
			return "ram_sd"
		if _text_contains_any(haystack, ["battery", "power"]):
			return "power"
	return "other"

func _does_module_match_filter(module: BipobModule, filter_name: String, is_external: bool) -> bool:
	if module == null:
		return false
	var broken: bool = _is_module_broken(module)
	match filter_name:
		"all":
			return true
		"broken":
			return broken
		"unknown":
			return _is_module_unknown(module)
		"other":
			return _get_module_filter_group(module, is_external) == "other"
		_:
			if is_external and filter_name in ["cpu_gpu", "cooling", "ram_sd", "power"]:
				return false
			if not is_external and filter_name in ["gear", "visor_radar", "tool", "manipulator", "armor", "weapon"]:
				return false
			if not _is_module_ready(module):
				return false
			return _get_module_filter_group(module, is_external) == filter_name

func _get_module_known_label(module: BipobModule, is_external: bool) -> String:
	if not _is_module_unknown(module):
		return bipob.get_module_display_name(module)
	var broad_type: String = _get_module_filter_group(module, is_external).replace("_", " ").capitalize()
	if broad_type == "Other":
		broad_type = "module"
	return "Unknown %s" % broad_type

func module_matches_constructor_filter(module: BipobModule, filter_id: String) -> bool:
	if module == null:
		return false
	return _does_module_match_filter(module, filter_id, bipob.is_external_module(module))

func _is_module_visible_in_current_constructor_mode(module: BipobModule) -> bool:
	if module == null:
		return false
	if box_menu_mode == BoxMenuMode.EXTERNAL:
		return bipob.is_external_module(module)
	if box_menu_mode == BoxMenuMode.INTERNAL:
		return _should_show_module_in_internal_storage(module)
	return true

func get_filtered_box_storage_indices(filter_id: String) -> Array[int]:
	var indices: Array[int] = []
	if bipob == null:
		return indices
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module_matches_constructor_filter(module, filter_id):
			indices.append(i)
	return indices

func get_filtered_internal_box_storage_indices(filter_id: String) -> Array[int]:
	var indices: Array[int] = []
	if bipob == null:
		return indices
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if not _should_show_module_in_internal_storage(module):
			continue
		if module_matches_constructor_filter(module, filter_id):
			indices.append(i)
	return indices

func get_current_filtered_box_storage_indices() -> Array[int]:
	var result: Array[int] = []
	if bipob == null:
		return result
	var filter_id: String = get_current_constructor_filter()
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module == null:
			continue
		if not _is_module_visible_in_current_constructor_mode(module):
			continue
		if not module_matches_constructor_filter(module, filter_id):
			continue
		result.append(i)
	return result

func get_selected_filtered_box_storage_index() -> int:
	var indices: Array[int] = get_current_filtered_box_storage_indices()
	if indices.is_empty():
		return -1
	selected_filtered_box_index = clampi(selected_filtered_box_index, 0, indices.size() - 1)
	return indices[selected_filtered_box_index]

func sync_selected_box_storage_index_from_filter() -> void:
	var raw_index: int = get_selected_filtered_box_storage_index()
	selected_box_storage_index = raw_index

func get_filtered_grouped_module_ids() -> Array[String]:
	var ids: Array[String] = []
	if bipob == null:
		return ids
	var filter_id: String = get_current_constructor_filter()
	var append_id := func(module_id: String) -> void:
		if module_id.is_empty() or ids.has(module_id):
			return
		var representative: BipobModule = bipob.get_first_module_by_id(module_id)
		if representative == null:
			return
		if not _is_module_visible_in_current_constructor_mode(representative):
			return
		if module_matches_constructor_filter(representative, filter_id):
			ids.append(module_id)

	for module in bipob.box_storage:
		if module != null:
			append_id.call(module.id)
	for module in bipob.get_unique_external_modules():
		if module != null:
			append_id.call(module.id)
	for module in bipob.get_unique_internal_modules():
		if module != null:
			append_id.call(module.id)
	return ids

func get_selected_grouped_module_id() -> String:
	var ids: Array[String] = get_filtered_grouped_module_ids()
	if ids.is_empty() or selected_grouped_module_index < 0:
		return ""
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, ids.size() - 1)
	return ids[selected_grouped_module_index]

func get_selected_grouped_module() -> BipobModule:
	var module_id: String = get_selected_grouped_module_id()
	if module_id.is_empty():
		return null
	return bipob.get_first_module_by_id(module_id)

func sync_selected_box_storage_index_from_grouped_selection() -> void:
	var module_id: String = get_selected_grouped_module_id()
	if module_id.is_empty():
		selected_box_storage_index = -1
		selected_constructor_module = null
		selected_module_source = "none"
		selected_install_record = {}
		return
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module != null and module.id == module_id:
			selected_box_storage_index = i
			selected_constructor_module = module
			selected_module_source = "storage"
			selected_install_record = {}
			return
	selected_box_storage_index = -1
	selected_constructor_module = bipob.get_first_module_by_id(module_id)
	selected_module_source = "none"
	selected_install_record = {}


func _clear_box_module_selection() -> void:
	selected_box_storage_index = -1
	selected_filtered_box_index = 0
	selected_grouped_module_index = -1
	selected_constructor_module = null
	selected_module_source = "none"
	selected_install_record = {}
	selected_external_side = ""
	selected_external_cell = Vector2i.ZERO


func _is_selected_box_module_valid_for_current_context() -> bool:
	if bipob == null or selected_constructor_module == null:
		return false
	if selected_module_source == "storage":
		if selected_box_storage_index < 0 or selected_box_storage_index >= bipob.box_storage.size():
			return false
		if bipob.box_storage[selected_box_storage_index] != selected_constructor_module:
			return false
		if not _is_module_visible_in_current_constructor_mode(selected_constructor_module):
			return false
		if not module_matches_constructor_filter(selected_constructor_module, get_current_constructor_filter()):
			return false
		return true
	if selected_module_source == "installed_internal":
		return box_menu_mode == BoxMenuMode.INTERNAL and bipob.is_internal_module(selected_constructor_module)
	if selected_module_source == "installed_external":
		return box_menu_mode == BoxMenuMode.EXTERNAL and bipob.is_external_module(selected_constructor_module)
	return false


func _clear_box_module_selection_if_invalid_for_current_context() -> void:
	if not _is_selected_box_module_valid_for_current_context():
		_clear_box_module_selection()


func _on_storage_module_card_pressed(storage_index: int) -> void:
	selected_box_storage_index = storage_index
	var module: BipobModule = bipob.box_storage[storage_index] if storage_index >= 0 and storage_index < bipob.box_storage.size() else null
	if module != null:
		selected_constructor_module = module
		selected_module_source = "storage"
		var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
		selected_grouped_module_index = maxi(grouped_ids.find(module.id), 0)
	_preserve_constructor_storage_scroll_and_update()


func _get_active_constructor_storage_scroll() -> ScrollContainer:
	if box_constructor_content_root == null:
		return null
	var scroll_name: String = "ExternalStorageScroll" if box_menu_mode == BoxMenuMode.EXTERNAL else "InternalStorageScroll"
	var preferred_scroll: Node = box_constructor_content_root.find_child(scroll_name, true, false)
	if preferred_scroll is ScrollContainer:
		return preferred_scroll
	for fallback_name in ["ExternalStorageScroll", "InternalStorageScroll"]:
		var fallback_scroll: Node = box_constructor_content_root.find_child(fallback_name, true, false)
		if fallback_scroll is ScrollContainer:
			return fallback_scroll
	return null


func _preserve_constructor_storage_scroll_and_update() -> void:
	var storage_scroll: ScrollContainer = _get_active_constructor_storage_scroll()
	var old_scroll_vertical: int = 0
	var old_scroll_horizontal: int = 0
	if storage_scroll != null:
		old_scroll_vertical = storage_scroll.scroll_vertical
		old_scroll_horizontal = storage_scroll.scroll_horizontal
	update_box_status()
	if storage_scroll == null:
		return
	await get_tree().process_frame
	var rebuilt_scroll: ScrollContainer = _get_active_constructor_storage_scroll()
	if rebuilt_scroll != null:
		rebuilt_scroll.scroll_vertical = old_scroll_vertical
		rebuilt_scroll.scroll_horizontal = old_scroll_horizontal



func _create_constructor_mode_layout(
	mode_title: String,
	workspace: Control,
	storage_panel: Control,
	details_panel: Control,
	side_panel: Control = null
) -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if CONSTRUCTOR_SHOW_MODE_LAYOUT_TITLE:
		var title_label: Label = Label.new()
		title_label.text = mode_title
		_apply_label_style(title_label, false, true)
		root.add_child(title_label)

	var main_row: HBoxContainer = HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 6)
	main_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if workspace != null:
		workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_row.add_child(workspace)

	if storage_panel != null:
		storage_panel.custom_minimum_size = Vector2(240, 0)
		storage_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		storage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_row.add_child(storage_panel)

	if details_panel != null:
		details_panel.custom_minimum_size = Vector2(260, 0)
		details_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_row.add_child(details_panel)

	if side_panel != null:
		side_panel.custom_minimum_size = Vector2(230, 0)
		side_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_row.add_child(side_panel)
	root.add_child(main_row)

	return root


func _build_storage_cards_panel(parent: Control) -> void:
	if box_menu_mode != BoxMenuMode.EXTERNAL and box_menu_mode != BoxMenuMode.INTERNAL:
		return

	if box_menu_mode == BoxMenuMode.EXTERNAL:
		var external_root: HBoxContainer = HBoxContainer.new()
		external_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		external_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		external_root.add_theme_constant_override("separation", 8)

		var external_layout: Control = _create_external_constructor_layout()
		external_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		external_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
		external_root.add_child(external_layout)

		parent.add_child(external_root)
		return

	var internal_layout: HBoxContainer = HBoxContainer.new()
	internal_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	internal_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	internal_layout.add_theme_constant_override("separation", 8)
	var workspace: Control = _create_internal_visual_workspace()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	internal_layout.add_child(workspace)
	var right_column: VBoxContainer = VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(330, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 6)
	right_column.add_child(_create_external_filter_panel())
	right_column.add_child(_create_internal_storage_components_panel())
	right_column.add_child(_create_selected_module_detail_card())
	internal_layout.add_child(right_column)
	parent.add_child(internal_layout)

func _get_storage_empty_state_text() -> String:
	if box_menu_mode == BoxMenuMode.EXTERNAL:
		return "No external modules in Box Storage."
	if box_menu_mode == BoxMenuMode.INTERNAL:
		return "No internal modules in Box Storage."
	return "No modules match current filter."


func _get_constructor_playable_status_text() -> String:
	var lines: Array[String] = []
	if box_menu_mode == BoxMenuMode.INTERNAL:
		lines.append("Mode: Internal Volume")
		lines.append("View: %s" % _get_internal_view_mode_display_name())
		lines.append("Cursor: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
		lines.append("Rotation: %d" % bipob.selected_internal_rotation)
		var selected_module: BipobModule = _get_selected_internal_candidate_module()
		if selected_module != null:
			var can_place: bool = bipob.can_place_internal_module(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
			lines.append("Can Place: %s" % ("yes" if can_place else "no"))
		else:
			lines.append("Can Place: n/a")
		if bipob.has_method("get_overlay_heat_diff_compact_text"):
			lines.append(str(bipob.get_overlay_heat_diff_compact_text()))
		if bipob.has_method("get_damage_planning_compact_text"):
			lines.append(str(bipob.get_damage_planning_compact_text()))
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		lines.append("Mode: External Slots")
		lines.append("Side: %s" % _get_external_side_display_name(bipob.selected_external_side))
		lines.append("Cell: %d,%d" % [bipob.selected_external_origin.x, bipob.selected_external_origin.y])
		var selected_external: BipobModule = _get_selected_external_candidate_module()
		if selected_external != null:
			var can_place_external: bool = bipob.can_place_external_module(selected_external, bipob.selected_external_side, bipob.selected_external_origin)
			var footprint_size: Vector2i = bipob.get_external_module_footprint_size(selected_external)
			lines.append("Footprint: %dx%d" % [footprint_size.x, footprint_size.y])
			lines.append("Can Place: %s" % ("yes" if can_place_external else "no"))
		else:
			lines.append("Footprint: n/a")
			lines.append("Can Place: n/a")
		if bipob.has_method("get_unique_external_modules"):
			lines.append("Installed External: %d" % bipob.get_unique_external_modules().size())
	else:
		lines.append("Mode: Constructor Dashboard")
		if bipob.has_method("get_constructor_checkpoint_compact_text"):
			lines.append(str(bipob.get_constructor_checkpoint_compact_text()))
		elif bipob.has_method("get_constructor_readiness_compact_text"):
			lines.append(str(bipob.get_constructor_readiness_compact_text()))
	return "\n".join(lines)


func _create_constructor_playable_status_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = "Constructor Status"
	_apply_label_style(title, false, true)
	root.add_child(title)
	root.add_child(_create_constructor_status_badges_panel(4))
	if not CONSTRUCTOR_COMPACT_STATUS:
		root.add_child(_create_constructor_warning_readiness_panel())
	var compact_panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(compact_panel)
	var compact_label: Label = Label.new()
	if CONSTRUCTOR_COMPACT_STATUS:
		var warning_count: int = bipob.get_constructor_warning_lines().size() if bipob.has_method("get_constructor_warning_lines") else 0
		var thermal_text: String = "WARN" if bipob.has_method("has_thermal_issues") and bipob.has_thermal_issues() else "OK"
		var power_text: String = "MISSING" if bipob.has_method("has_missing_power_for_critical_modules") and bipob.has_missing_power_for_critical_modules() else "OK"
		compact_label.text = "Power: %s | Thermal: %s | Warnings: %d" % [power_text, thermal_text, warning_count]
	else:
		compact_label.text = _get_constructor_playable_status_text()
	compact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	compact_label.clip_text = true
	_apply_label_style(compact_label, true, false)
	compact_panel.add_child(compact_label)
	root.add_child(compact_panel)
	panel.add_child(root)
	return panel


func _create_external_footprint_preview(module: BipobModule) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = "FOOTPRINT"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var footprint_size: Vector2i = bipob.get_external_module_footprint_size(module)
	var grid: GridContainer = GridContainer.new()
	grid.columns = max(1, footprint_size.x)
	grid.add_theme_constant_override("h_separation", SELECTED_MODULE_PREVIEW_GAP)
	grid.add_theme_constant_override("v_separation", SELECTED_MODULE_PREVIEW_GAP)
	for y in range(footprint_size.y):
		for x in range(footprint_size.x):
			var cell: PanelContainer = PanelContainer.new()
			cell.custom_minimum_size = SELECTED_MODULE_PREVIEW_CELL_SIZE
			var bg_color: Color = UI_COLOR_PANEL_DARK
			var border_color: Color = UI_COLOR_BORDER_DIM
			if bipob.has_method("get_module_visual_color"):
				var module_color: Color = bipob.get_module_visual_color(module)
				bg_color = module_color.darkened(0.62)
				border_color = module_color
			cell.add_theme_stylebox_override("panel", _make_panel_style(bg_color, border_color, 1, 4))
			grid.add_child(cell)
	root.add_child(grid)
	panel.add_child(root)
	return panel


func _create_internal_volume_preview(module: BipobModule) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = "VOLUME"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var size: Vector3i = bipob.get_rotated_internal_size(module, bipob.selected_internal_rotation)
	var size_label: Label = Label.new()
	size_label.text = "%dx%dx%d cells" % [size.x, size.y, size.z]
	_apply_label_style(size_label)
	root.add_child(size_label)
	var grid: GridContainer = GridContainer.new()
	var cols: int = max(1, size.x)
	var rows: int = max(1, size.y if size.y >= size.z else size.z)
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", SELECTED_MODULE_PREVIEW_GAP)
	grid.add_theme_constant_override("v_separation", SELECTED_MODULE_PREVIEW_GAP)
	for y in range(rows):
		for x in range(cols):
			var cell: PanelContainer = PanelContainer.new()
			cell.custom_minimum_size = SELECTED_MODULE_PREVIEW_CELL_SIZE
			var bg_color: Color = UI_COLOR_PANEL_DARK
			var border_color: Color = UI_COLOR_BORDER_DIM
			if bipob.has_method("get_module_visual_color"):
				var module_color: Color = bipob.get_module_visual_color(module)
				bg_color = module_color.darkened(0.62)
				border_color = module_color
			cell.add_theme_stylebox_override("panel", _make_panel_style(bg_color, border_color, 1, 4))
			grid.add_child(cell)
	root.add_child(grid)
	var note: Label = Label.new()
	note.text = "Projection preview"
	_apply_label_style(note, true, false)
	root.add_child(note)
	panel.add_child(root)
	return panel


func _create_overlay_module_preview(module: BipobModule) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	var root: VBoxContainer = VBoxContainer.new()
	var title: Label = Label.new()
	title.text = "OVERLAY PATH"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var type_label: Label = Label.new()
	var overlay_type: String = "Liquid Path"
	if module != null and module.id.contains("air_duct"):
		overlay_type = "Duct Path"
	type_label.text = overlay_type
	_apply_label_style(type_label)
	root.add_child(type_label)
	var note: Label = Label.new()
	note.text = "Does not consume Internal Volume"
	_apply_label_style(note, true, false)
	root.add_child(note)
	panel.add_child(root)
	return panel


func _create_selected_module_detail_card() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = "SELECTED MODULE"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var module: BipobModule = _get_selected_box_storage_module()
	if module == null:
		var empty_label: Label = Label.new()
		empty_label.text = "No module selected."
		_apply_label_style(empty_label, true, false)
		root.add_child(empty_label)
		panel.add_child(root)
		return panel
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	var icon: Control = _build_module_icon_badge(module, MODULE_TYPE_ICON_PREVIEW_BADGE_SIZE)
	if icon != null:
		header_row.add_child(icon)
	var name_box: VBoxContainer = VBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = bipob.get_module_display_name(module)
	_apply_label_style(name_label)
	name_box.add_child(name_label)
	var visual_label: Label = Label.new()
	visual_label.text = _get_module_visual_summary_text(module)
	_apply_label_style(visual_label, true, false)
	name_box.add_child(visual_label)
	var availability_label: Label = Label.new()
	availability_label.text = _get_selected_module_availability_text(module)
	_apply_label_style(availability_label, true, false)
	name_box.add_child(availability_label)
	header_row.add_child(name_box)
	root.add_child(header_row)
	if bipob.is_external_module(module):
		root.add_child(_apply_module_icon_badge_to_preview_block(_create_external_footprint_preview(module), module))
	elif bipob.is_internal_module(module):
		root.add_child(_apply_module_icon_badge_to_preview_block(_create_internal_volume_preview(module), module))
	elif bipob.is_internal_overlay_module(module):
		root.add_child(_apply_module_icon_badge_to_preview_block(_create_overlay_module_preview(module), module))
	var stats_panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(stats_panel)
	var stats_box: VBoxContainer = VBoxContainer.new()
	var stats_title: Label = Label.new()
	stats_title.text = "CHARACTERISTICS"
	_apply_label_style(stats_title, false, true)
	stats_box.add_child(stats_title)
	var stat_lines: Array[String] = _get_selected_module_stat_lines(module)
	var stat_limit: int = mini(4, stat_lines.size()) if CONSTRUCTOR_COMPACT_DETAILS else stat_lines.size()
	for index in range(stat_limit):
		var line: String = stat_lines[index]
		var stat_label: Label = Label.new()
		stat_label.text = line
		_apply_label_style(stat_label, true, false)
		stats_box.add_child(stat_label)
	stats_panel.add_child(stats_box)
	root.add_child(stats_panel)
	var description_panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(description_panel)
	var desc_box: VBoxContainer = VBoxContainer.new()
	var desc_title: Label = Label.new()
	desc_title.text = "DESCRIPTION"
	_apply_label_style(desc_title, false, true)
	desc_box.add_child(desc_title)
	var desc_label: Label = Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_text = CONSTRUCTOR_COMPACT_DETAILS
	var description_value: Variant = module.get("description")
	desc_label.text = String(description_value) if description_value != null else ""
	if CONSTRUCTOR_COMPACT_DETAILS:
		desc_label.text = "More details in Reference / Preview."
	elif desc_label.text.is_empty():
		desc_label.text = "No description."
	_apply_label_style(desc_label, true, false)
	desc_box.add_child(desc_label)
	description_panel.add_child(desc_box)
	root.add_child(description_panel)
	panel.add_child(root)
	_fade_in_control(panel)
	return panel



func _get_external_side_display_name(side_id: String) -> String:
	match side_id:
		"top":
			return "UP"
		"bottom":
			return "DOWN"
		"left":
			return "LEFT SIDE" if _is_juggernaut_profile() else "LEFT"
		"right":
			return "RIGHT SIDE" if _is_juggernaut_profile() else "RIGHT"
		"front":
			return "FRONT"
		"back":
			return "BACK"
		_:
			return side_id.to_upper()


func _make_external_cell_style(
	module: BipobModule,
	selected: bool,
	preview: bool,
	invalid_preview: bool,
	reserved_for_pocket: bool
) -> StyleBoxFlat:
	var bg_color: Color = Color(0.035, 0.050, 0.060, 1.0)
	var border_color: Color = UI_COLOR_BORDER_DIM

	if module != null:
		if bipob.has_method("get_module_visual_color"):
			var module_color: Color = bipob.get_module_visual_color(module)
			bg_color = module_color.darkened(0.62)
			border_color = module_color
		else:
			bg_color = Color(0.120, 0.160, 0.180, 1.0)

	if reserved_for_pocket and module == null:
		bg_color = Color(0.110, 0.090, 0.180, 1.0)
		border_color = Color(0.640, 0.480, 0.900, 0.95)

	if preview:
		bg_color = Color(0.100, 0.230, 0.130, 1.0)
		border_color = UI_COLOR_OK

	if invalid_preview:
		bg_color = Color(0.260, 0.070, 0.070, 1.0)
		border_color = UI_COLOR_DANGER

	if selected:
		border_color = UI_COLOR_SELECTED

	return _make_panel_style(bg_color, border_color, 1, 5)


func _apply_external_cell_visual(
	cell: Button,
	module: BipobModule,
	selected: bool,
	preview: bool,
	invalid_preview: bool,
	reserved_for_pocket: bool,
	cell_size: Vector2
) -> void:
	if cell == null:
		return

	cell.custom_minimum_size = cell_size
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cell.focus_mode = Control.FOCUS_NONE
	cell.clip_text = false
	cell.text = ""
	if reserved_for_pocket and module == null:
		_set_external_cell_label(cell, "P", cell_size)
	else:
		_set_external_cell_label(cell, _get_external_cell_label(module) if cell_size.x >= CONSTRUCTOR_SMALL_LABEL_CELL_SIZE else "", cell_size)

	var style: StyleBoxFlat = _make_external_cell_style(module, selected, preview, invalid_preview, reserved_for_pocket)
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", style)
	cell.add_theme_stylebox_override("pressed", style)


func _set_external_cell_label(cell: Button, text_value: String, cell_size: Vector2) -> void:
	var label: Label = cell.get_node_or_null("CellLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "CellLabel"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2.ZERO
		cell.add_child(label)
	label.add_theme_font_size_override("font_size", 11 if cell_size.x >= CONSTRUCTOR_SMALL_LABEL_CELL_SIZE else 8)
	label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	label.text = text_value


func _get_selected_external_candidate_module() -> BipobModule:
	var selected_module: BipobModule = selected_constructor_module if selected_module_source == "storage" else null

	if selected_module != null and bipob.is_external_module(selected_module):
		return selected_module

	return null


func _get_external_preview_cells_for_side(side_id: String) -> Dictionary:
	var result: Dictionary = {}
	var module: BipobModule = _get_selected_external_candidate_module()

	if module == null:
		return result

	if side_id != get_selected_external_side_id():
		return result

	var origin: Vector2i = selected_external_slot_position
	var can_place: bool = bipob.can_place_external_module(module, side_id, origin)
	var covered_cells: Array[Vector2i] = bipob.get_external_module_covered_cells(side_id, origin, module)

	for cell in covered_cells:
		var key: String = bipob.get_external_slot_key(side_id, cell)
		result[key] = can_place

	return result


func _get_external_cell_label(module: BipobModule) -> String:
	if module == null:
		return ""

	var group: String = _get_module_filter_group(module, true)
	var short_map: Dictionary = {"gear":"GER","visor_radar":"VIS","tool":"TOL","manipulator":"ARM","armor":"AMR","weapon":"WPN","other":"MOD"}
	return String(short_map.get(group, "MOD"))


func _on_external_visual_cell_pressed(side_id: String, cell: Vector2i) -> void:
	_set_external_selection_from_side_and_cell(side_id, cell)
	selected_external_side = side_id
	selected_external_cell = cell
	selected_install_record = {}
	var installed_module: BipobModule = bipob.get_external_module_at(side_id, cell)
	if installed_module != null:
		selected_constructor_module = installed_module
		selected_module_source = "installed_external"
		selected_install_record = bipob.get_external_module_record_at(side_id, cell)
	else:
		selected_constructor_module = null
		selected_module_source = "none"
	update_box_status()


func _create_external_side_grid(side_id: String) -> Control:
	var side_panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(side_panel)
	side_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	side_panel.custom_minimum_size = _get_external_side_panel_size(side_id)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)

	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = _get_external_side_display_name(side_id)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	header.add_child(title)
	var pockets_wrap: HBoxContainer = HBoxContainer.new()
	pockets_wrap.add_theme_constant_override("separation", 2)
	pockets_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	pockets_wrap.custom_minimum_size = Vector2(66, 0)
	if side_id in ["front", "back", "left", "right"] and bipob.has_method("get_max_pockets_per_side"):
		for pocket_index in range(bipob.get_max_pockets_per_side()):
			var pocket_button: Button = Button.new()
			pocket_button.custom_minimum_size = Vector2(20, 18)
			var is_valid_pocket: bool = true
			if bipob.has_method("is_external_pocket_index_valid_for_side"):
				is_valid_pocket = bipob.is_external_pocket_index_valid_for_side(side_id, pocket_index)
			var enabled: bool = bipob.is_external_pocket_enabled(side_id, pocket_index) if bipob.has_method("is_external_pocket_enabled") else false
			pocket_button.text = "-" if enabled else "P"
			pocket_button.disabled = not is_valid_pocket
			pocket_button.pressed.connect(func() -> void:
				bipob.toggle_external_pocket(side_id, pocket_index)
				update_box_status()
			)
			pockets_wrap.add_child(pocket_button)
	header.add_child(pockets_wrap)
	root.add_child(header)

	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var preview_cells: Dictionary = _get_external_preview_cells_for_side(side_id)
	var selected_side_id: String = get_selected_external_side_id()
	var cell_size: Vector2 = _get_external_adaptive_cell_size(side_id)
	var grid_gap: int = EXTERNAL_GRID_CELL_GAP
	var pocket_reserved_map: Dictionary = {}
	if side_id in ["front", "back", "left", "right"] and bipob.has_method("get_max_pockets_per_side") and bipob.has_method("is_external_pocket_enabled") and bipob.has_method("get_external_pocket_reserved_cells"):
		for pocket_index in range(bipob.get_max_pockets_per_side()):
			if not bipob.is_external_pocket_enabled(side_id, pocket_index):
				continue
			var reserved_cells: Array = bipob.get_external_pocket_reserved_cells(side_id, pocket_index)
			for reserved_cell_variant in reserved_cells:
				var reserved_cell: Vector2i = reserved_cell_variant
				var reserved_key: String = bipob.get_external_slot_key(side_id, reserved_cell)
				pocket_reserved_map[reserved_key] = true

	var grid: GridContainer = GridContainer.new()
	grid.columns = side_size.x
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", grid_gap)
	grid.add_theme_constant_override("v_separation", grid_gap)
	for y in range(side_size.y):
		for x in range(side_size.x):
			var cell: Vector2i = Vector2i(x, y)
			var key: String = bipob.get_external_slot_key(side_id, cell)
			var module: BipobModule = bipob.get_external_module_at(side_id, cell)
			var reserved_for_pocket: bool = bool(pocket_reserved_map.get(key, false))
			if not reserved_for_pocket and bipob.has_method("is_external_cell_reserved_for_pocket"):
				reserved_for_pocket = bipob.is_external_cell_reserved_for_pocket(side_id, cell)

			var selected: bool = side_id == selected_side_id and cell == selected_external_slot_position

			var preview: bool = false
			var invalid_preview: bool = false
			if preview_cells.has(key):
				var can_place_preview: bool = bool(preview_cells[key])
				preview = can_place_preview
				invalid_preview = not can_place_preview

			var cell_button: Button = Button.new()
			_apply_external_cell_visual(cell_button, module, selected, preview, invalid_preview, reserved_for_pocket, cell_size)
			cell_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cell_button.pressed.connect(func() -> void:
				_on_external_visual_cell_pressed(side_id, cell)
			)
			if selected:
				_apply_selected_pulse(cell_button)
			if invalid_preview:
				_apply_invalid_preview_blink(cell_button)
			grid.add_child(cell_button)

	root.add_child(grid)
	side_panel.add_child(root)
	return side_panel


func _is_juggernaut_profile() -> bool:
	return active_bipob_profile_id == "juggernaut"

func _is_engineer_profile() -> bool:
	return active_bipob_profile_id == "beta" or active_bipob_profile_id == "engineer"

func _is_scout_profile() -> bool:
	return not _is_juggernaut_profile() and not _is_engineer_profile()

func _get_external_profile_cell_scale() -> float:
	if _is_juggernaut_profile():
		return 0.66
	if _is_engineer_profile():
		return 0.945
	return 1.40


func _get_external_side_panel_size(side_id: String) -> Vector2:
	match side_id:
		"top":
			if _is_juggernaut_profile():
				return Vector2(180.0, 96.0)
			if _is_scout_profile():
				return Vector2(182.0, 107.0)
			return Vector2(170.0, 95.0)
		"left", "right":
			if _is_juggernaut_profile():
				return Vector2(160.0, 138.0)
			if _is_scout_profile():
				return Vector2(162.0, 152.0)
			return Vector2(150.0, 140.0)
		"front", "bottom", "back":
			if _is_juggernaut_profile():
				return Vector2(155.0, 112.0)
			if _is_scout_profile():
				return Vector2(157.0, 137.0)
			return Vector2(145.0, 125.0)
		_:
			return Vector2(180.0, 150.0)


func _get_external_adaptive_cell_size(side_id: String) -> Vector2:
	if bipob == null:
		return Vector2(18, 18)
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var largest_side: int = maxi(side_size.x, side_size.y)
	var base_cell: float = 19.0
	if largest_side >= 7:
		base_cell = 15.0
	elif largest_side >= 5:
		base_cell = 17.0
	var scaled_cell: float = base_cell * _get_external_profile_cell_scale()
	scaled_cell = clampf(scaled_cell, 9.0, 30.0)
	return Vector2(scaled_cell, scaled_cell)


func _create_external_robot_preview_panel(preview_size: Vector2 = Vector2(136, 130)) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	panel.custom_minimum_size = preview_size

	var root: VBoxContainer = VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var title: Label = Label.new()
	title.text = "ROBOT PREVIEW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	root.add_child(title)

	var robot_label: Label = Label.new()
	robot_label.text = "[ BIPOB BODY ]"
	robot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	robot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(robot_label)
	root.add_child(robot_label)

	var hint: Label = Label.new()
	hint.text = "External Slots"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(hint, true, false)
	root.add_child(hint)

	panel.add_child(root)
	return panel


func _get_external_selected_slot_summary_text() -> String:
	var side_id: String = get_selected_external_side_id()
	var side_name: String = _get_external_side_display_name(side_id)
	var cell: Vector2i = selected_external_slot_position
	var module: BipobModule = _get_selected_external_candidate_module()
	var can_place_text: String = "n/a"
	var selected_module_text: String = "none"
	var selected_footprint_text: String = "n/a"

	if module != null:
		var can_place: bool = bipob.can_place_external_module(module, side_id, cell)
		can_place_text = "yes" if can_place else "no"
		selected_module_text = bipob.get_module_display_name(module)
		var footprint: Vector2i = bipob.get_external_module_footprint_size(module)
		selected_footprint_text = "%dx%d" % [footprint.x, footprint.y]

	return "Selected External Slot: Side: %s / Cell: %d,%d\nSelected Module: %s / Footprint: %s / Can place: %s" % [
		side_name,
		cell.x,
		cell.y,
		selected_module_text,
		selected_footprint_text,
		can_place_text
	]


func _create_external_visual_workspace_juggernaut() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_theme_constant_override("separation", 6)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 6)

	var info_panel: Control = _create_external_info_stub_panel("", _get_external_left_info_text())
	info_panel.custom_minimum_size = Vector2(180, 82)
	var warning_panel: Control = _create_external_warning_panel()
	warning_panel.custom_minimum_size = Vector2(180, 82)

	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 6)
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_child(info_panel)
	left_column.add_child(_create_external_side_grid("left"))
	top_row.add_child(left_column)

	var center_column: VBoxContainer = VBoxContainer.new()
	center_column.add_theme_constant_override("separation", 6)
	center_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var up_grid: Control = _create_external_side_grid("top")
	var preview: Control = _create_external_robot_preview_panel(Vector2(180, 96))
	center_column.add_child(up_grid)
	center_column.add_child(preview)
	top_row.add_child(center_column)

	var right_column: VBoxContainer = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 6)
	right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_column.add_child(warning_panel)
	right_column.add_child(_create_external_side_grid("right"))
	top_row.add_child(right_column)
	root.add_child(top_row)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 6)
	bottom_row.add_child(_create_external_side_grid("front"))
	bottom_row.add_child(_create_external_side_grid("bottom"))
	bottom_row.add_child(_create_external_side_grid("back"))
	root.add_child(bottom_row)

	margin.add_child(root)
	panel.add_child(margin)
	return panel


func _create_external_visual_workspace() -> Control:
	if _is_juggernaut_profile():
		return _create_external_visual_workspace_juggernaut()

	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 0)

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.add_theme_constant_override("separation", 6)

	var left_info: Control = _create_external_info_stub_panel("", _get_external_left_info_text())
	left_info.custom_minimum_size = Vector2(190, 86)
	left_info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.add_child(left_info)

	var up_wrap: VBoxContainer = VBoxContainer.new()
	up_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	up_wrap.alignment = BoxContainer.ALIGNMENT_BEGIN
	var up_grid: Control = _create_external_side_grid("top")
	up_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	up_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	up_wrap.add_child(up_grid)
	top_row.add_child(up_wrap)

	var right_info: Control = _create_external_warning_panel()
	right_info.custom_minimum_size = Vector2(190, 86)
	right_info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	right_info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_row.add_child(right_info)
	root.add_child(top_row)

	var grid_area: Control = _create_external_side_grid_workspace()
	grid_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(grid_area)

	margin.add_child(root)
	panel.add_child(margin)
	return panel


func get_compact_module_window(modules: Array, selected_index: int, max_lines: int = 4) -> Array[String]:
	if modules.is_empty():
		return ["empty"]

	var total: int = modules.size()
	var safe_index: int = clampi(selected_index, 0, total - 1)
	var window_size: int = mini(max_lines, total)
	var start_idx: int = clampi(safe_index - floori(float(window_size) / 2.0), 0, total - window_size)
	var end_idx: int = start_idx + window_size - 1
	var lines: Array[String] = []

	if start_idx > 0:
		lines.append("... ")

	for index in range(start_idx, end_idx + 1):
		var marker := "  "
		if index == safe_index:
			marker = "> "
		lines.append("%s%s" % [marker, get_short_module_name(modules[index])])

	if end_idx < total - 1:
		lines.append("... ")

	return lines
func _get_viewport_size() -> Vector2:
	if get_viewport() == null:
		return Vector2(1280, 768)

	return get_viewport().get_visible_rect().size
	
func _get_viewport_width() -> float:
	return _get_viewport_size().x
	
func _get_viewport_height() -> float:
	return _get_viewport_size().y

func _get_box_half_width_estimate() -> float:
	return maxf(320.0, _get_viewport_width() * 0.5)


func _get_storage_grid_columns(available_width: float, card_width: float = 86.0, gap: float = 6.0) -> int:
	var columns: int = int(floor((available_width + gap) / (card_width + gap)))
	return maxi(1, columns)


func _get_box_storage_grid_columns() -> int:
	var right_column_width_estimate: float = maxf(200.0, _get_box_half_width_estimate() - 24.0)
	return _get_storage_grid_columns(right_column_width_estimate, STORAGE_CARD_MIN_SIZE.x, 6.0)


func _get_constructor_cell_size(max_columns: int, max_rows: int, available_size: Vector2, preferred: float = CONSTRUCTOR_GRID_PREFERRED_CELL_SIZE, minimum: float = CONSTRUCTOR_GRID_MIN_CELL_SIZE) -> Vector2:
	var safe_columns: int = max(1, max_columns)
	var safe_rows: int = max(1, max_rows)
	var gap: float = 3.0
	var cell_w: float = floor((available_size.x - float(safe_columns - 1) * gap) / float(safe_columns))
	var cell_h: float = floor((available_size.y - float(safe_rows - 1) * gap) / float(safe_rows))
	var raw_size: float = minf(cell_w, cell_h)
	var size: float = clampf(raw_size, minimum, preferred)
	return Vector2(size, size)


func _get_constructor_profile_size(profile_id: String = "") -> Vector3i:
	var resolved_profile_id: String = active_bipob_profile_id if profile_id.is_empty() else profile_id
	var profile_size: Vector3i = BIPOB_PROFILE_SIZES.get(resolved_profile_id, Vector3i(3, 3, 4))
	return profile_size


func _get_constructor_profile_name(profile_id: String = "") -> String:
	var resolved_profile_id: String = active_bipob_profile_id if profile_id.is_empty() else profile_id
	return String(BIPOB_PROFILE_NAMES.get(resolved_profile_id, "Scout"))


func _get_constructor_body_summary(profile_id: String = "") -> String:
	var body_size: Vector3i = _get_constructor_profile_size(profile_id)
	return "%s %dx%dx%d" % [_get_constructor_profile_name(profile_id), body_size.x, body_size.y, body_size.z]

func _get_external_installed_unique_modules() -> Array[BipobModule]:
	if bipob == null or not bipob.has_method("get_unique_external_modules"):
		return []
	return bipob.get_unique_external_modules()

func _does_external_module_deal_damage(module: BipobModule) -> bool:
	return _get_external_module_damage_value(module) > 0

func _get_external_module_damage_value(module: BipobModule) -> int:
	if module == null:
		return 0
	if not module.damage_value.is_empty():
		var token: String = module.damage_value.split("-")[0]
		if token.is_valid_int():
			return int(token)
	return 0

func _get_external_module_damage_type(module: BipobModule) -> String:
	if module == null:
		return ""
	return module.weapon_range_type.to_lower()


func _apply_constructor_profile_dimensions(profile_id: String) -> void:
	if bipob == null or not bipob.has_method("set_constructor_body_size"):
		return
	bipob.set_constructor_body_size(_get_constructor_profile_size(profile_id))
	clamp_external_selection()
	_clamp_internal_selection()


func _get_constructor_grid_gap(max_columns: int, max_rows: int) -> int:
	if max_columns >= 7 or max_rows >= 7:
		return 1
	if max_columns >= 5 or max_rows >= 5:
		return 2
	return 3


func _get_external_grid_available_size(side_id: String) -> Vector2:
	var half_width: float = _get_box_half_width_estimate()
	var grid_width: float = maxf(110.0, (half_width - 72.0) / 3.0)
	var grid_height: float = 124.0
	if side_id == "top" or side_id == "bottom":
		grid_height = 110.0
	return Vector2(grid_width, grid_height)


func _get_internal_grid_available_size(columns: int, rows: int) -> Vector2:
	var half_width: float = _get_box_half_width_estimate()
	var grid_width: float = maxf(110.0, (half_width - 76.0) / 3.0)
	var grid_height: float = 146.0
	if columns == rows:
		grid_height = 118.0
	return Vector2(grid_width, grid_height)


func _get_external_bottom_bar_height() -> float:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	if viewport_height < 720.0:
		return 42.0
	return 48.0


func _create_external_constructor_layout() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)

	var top_content_row: HBoxContainer = HBoxContainer.new()
	top_content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_content_row.add_theme_constant_override("separation", 6)

	var left_wrapper: PanelContainer = PanelContainer.new()
	left_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_wrapper.size_flags_stretch_ratio = 1.05
	left_wrapper.custom_minimum_size = Vector2(590, 0)
	left_wrapper.add_child(_create_external_visual_workspace())
	top_content_row.add_child(left_wrapper)

	var right_wrapper: PanelContainer = PanelContainer.new()
	right_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_wrapper.size_flags_stretch_ratio = 0.95
	right_wrapper.custom_minimum_size = Vector2(520, 0)
	right_wrapper.add_child(_create_external_storage_right_column())
	top_content_row.add_child(right_wrapper)

	root.add_child(top_content_row)

	var bottom_bar: Control = _create_external_bottom_action_bar()
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_bar.custom_minimum_size = Vector2(0, _get_external_bottom_bar_height())
	root.add_child(bottom_bar)

	return root


func _create_internal_constructor_layout() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)

	var top_content_row: HBoxContainer = HBoxContainer.new()
	# IMPORTANT: Keep left/right BOX split 50/50.
	# Do not set fixed right_column width here.
	# Both children must use EXPAND_FILL + stretch_ratio 1.0.
	top_content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_content_row.add_theme_constant_override("separation", 8)
	top_content_row.alignment = BoxContainer.ALIGNMENT_BEGIN

	var workspace: Control = _create_internal_visual_workspace()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_stretch_ratio = 1.0
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_content_row.add_child(workspace)

	var right_column: Control = _create_internal_storage_right_column()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_stretch_ratio = 1.0
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_content_row.add_child(right_column)

	root.add_child(top_content_row)

	var bottom_bar: Control = _create_internal_bottom_action_bar()
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_bar.custom_minimum_size = Vector2(0, _get_internal_bottom_bar_height())
	root.add_child(bottom_bar)

	return root


func _create_internal_storage_right_column() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)

	var filters_panel: Control = _create_internal_filter_panel()
	filters_panel.custom_minimum_size = Vector2(0, 46)
	filters_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	column.add_child(filters_panel)

	var storage_panel: Control = _create_internal_storage_components_panel()
	storage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(storage_panel)

	var selected_panel: Control = _create_selected_module_info_panel(_get_selected_module_for_context("internal"), "internal")
	selected_panel.custom_minimum_size = Vector2(0, 180)
	selected_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	column.add_child(selected_panel)

	return column


func _create_internal_filter_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, 46)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 0)
	root.add_child(_create_filter_dropdown_button(true))

	panel.add_child(root)
	return panel


func _create_external_info_stub_panel(title_text: String, _body_text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(190, 86)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 2)

	if not title_text.is_empty():
		var title: Label = _create_nowrap_label(title_text)
		_apply_label_style(title, false, true)
		root.add_child(title)

	for info_row in _get_external_left_info_lines():
		_add_nowrap_info_label(root, info_row)

	panel.add_child(root)
	return panel


func _add_nowrap_info_label(vbox: VBoxContainer, text: String) -> void:
	var row_label: Label = _create_nowrap_label(text)
	_apply_label_style(row_label, true, false)
	vbox.add_child(row_label)


func _create_nowrap_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label

func _format_warning_name(raw: String) -> String:
	var words: PackedStringArray = raw.strip_edges().replace("_", " ").split(" ", false)
	var formatted_words: Array[String] = []
	for word in words:
		if word.is_empty():
			continue
		formatted_words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(formatted_words)


func _get_external_build_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var modules: Array[BipobModule] = _get_external_installed_unique_modules()
	var has_gear: bool = false
	var has_visor: bool = false
	var has_manipulator: bool = false
	for module in modules:
		if module == null:
			continue
		var text: String = ("%s %s %s" % [module.id, module.display_name, module.category]).to_lower()
		if text.contains("wheel") or text.contains("track") or text.contains("leg") or text.contains("chassis") or text.contains("gear"):
			has_gear = true
		if text.contains("visor") or text.contains("radar"):
			has_visor = true
		if text.contains("manipulator"):
			has_manipulator = true
		for key in ["is_broken", "broken", "is_damaged", "damaged"]:
			if module.get(key) != null and bool(module.get(key)):
				var damaged_name: String = "module"
				if text.contains("visor") or text.contains("radar"):
					damaged_name = "visor"
				elif text.contains("hard_drive") or text.contains("hard drive") or text.contains("storage"):
					damaged_name = "hard drive"
				elif text.contains("manipulator"):
					damaged_name = "manipulator"
				elif text.contains("gear") or text.contains("wheel") or text.contains("track") or text.contains("leg"):
					damaged_name = "gear"
				warnings.append(_format_warning_name("damaged %s" % damaged_name))
				break
	if not has_gear:
		warnings.append(_format_warning_name("gear"))
	if not has_visor:
		warnings.append(_format_warning_name("visor"))
	if not has_manipulator:
		warnings.append(_format_warning_name("manipulator"))
	var has_ventilation_port: bool = false
	var has_gas_burner: bool = false
	var has_gas_canister: bool = false
	var has_jumper_or_air_cushion: bool = false
	for module in modules:
		if module == null:
			continue
		if module.id == "ventilation_port_v1":
			has_ventilation_port = true
		elif module.id == "gas_burner_v1":
			has_gas_burner = true
		elif module.id == "gas_canister_v1":
			has_gas_canister = true
		elif module.id == "jumper_v1" or module.id == "hover_pad_v1":
			has_jumper_or_air_cushion = true
	if bipob != null and not has_ventilation_port:
		var needs_airflow_dependency: bool = false
		for internal_module in bipob.installed_modules:
			if internal_module == null:
				continue
			if not bipob.is_internal_module(internal_module):
				continue
			if internal_module.id == "cooler_v1" or internal_module.id == "air_duct_v1" or bool(internal_module.requires_air_intake):
				needs_airflow_dependency = true
				break
		if needs_airflow_dependency:
			warnings.append("Ventilation Port")
	if has_gas_burner and not has_gas_canister:
		warnings.append("Gas Canister")
	if has_jumper_or_air_cushion and bipob != null and not bipob.has_module_id_anywhere("motor_controller_v1"):
		warnings.append("Motor Controller")
	if bipob != null and bipob.has_method("is_power_port_overloaded") and bipob.is_power_port_overloaded():
		if not warnings.has("Power ports shortage"):
			warnings.append("Power ports shortage")
	if bipob != null and bipob.has_method("get_external_connected_module_count") and bipob.has_method("get_external_interface_port_capacity"):
		var external_connected_count: int = bipob.get_external_connected_module_count()
		var external_port_capacity: int = bipob.get_external_interface_port_capacity()
		if external_connected_count > external_port_capacity and not warnings.has("Too many external devices"):
			warnings.append("Too many external devices")
	return warnings

func _create_external_warning_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(190, 86)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var warning_label: Label = Label.new()
	warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.clip_text = true
	warning_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	warning_label.text = " ".join(_get_external_build_warnings())
	_apply_label_style(warning_label, true, false)
	warning_label.add_theme_color_override("font_color", UI_COLOR_DANGER)
	root.add_child(warning_label)
	panel.add_child(root)
	return panel


func _create_filter_dropdown_button(is_internal: bool) -> Control:
	var option: OptionButton = OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.focus_mode = Control.FOCUS_NONE
	var entries: Array[Dictionary] = []
	if is_internal:
		entries = [{"id":"all","label":"ALL"},{"id":"broken","label":"BROKEN"},{"id":"unknown","label":"UNKNOWN"},{"id":"cpu_gpu","label":"CPU | GPU"},{"id":"cooling","label":"COOLING"},{"id":"ram_sd","label":"RAM | SD"},{"id":"power","label":"POWER"},{"id":"interface","label":"INTERFACE"},{"id":"other","label":"OTHER"}]
	else:
		entries = [{"id":"all","label":"ALL"},{"id":"broken","label":"BROKEN"},{"id":"unknown","label":"UNKNOWN"},{"id":"gear","label":"GEAR"},{"id":"visor_radar","label":"VISOR | RADAR"},{"id":"tool","label":"TOOL"},{"id":"manipulator","label":"MANIPULATOR"},{"id":"armor","label":"ARMOR"},{"id":"weapon","label":"WEAPON"},{"id":"interface","label":"INTERFACE"},{"id":"other","label":"OTHER"}]
	for i in range(entries.size()):
		option.add_item(entries[i]["label"], i)
		if String(entries[i]["id"]) == get_current_constructor_filter():
			option.select(i)
	option.item_selected.connect(func(index: int) -> void:
		var filter_id: String = String(entries[index]["id"])
		_set_active_filter_index(maxi(CONSTRUCTOR_FILTERS.find(filter_id), 0))
		selected_filtered_box_index = 0
		update_box_status()
	)
	return option


func _create_external_side_grid_workspace() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3 if _is_juggernaut_profile() else 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2.ZERO

	var middle_row: HBoxContainer = HBoxContainer.new()
	middle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	middle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_row.add_theme_constant_override("separation", 6)
	middle_row.add_child(_create_external_side_grid("left"))
	middle_row.add_child(_create_external_robot_preview_panel())
	middle_row.add_child(_create_external_side_grid("right"))
	root.add_child(middle_row)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 6)
	bottom_row.add_child(_create_external_side_grid("front"))
	bottom_row.add_child(_create_external_side_grid("bottom"))
	bottom_row.add_child(_create_external_side_grid("back"))
	root.add_child(bottom_row)

	return root

func _get_external_left_info_text() -> String:
	return "\n".join(_get_external_left_info_lines())


func _get_external_left_info_lines() -> Array[String]:
	var lines: Array[String] = []
	var armor_max: int = bipob.get_bipop_body_armor_max(active_bipob_profile_id) if bipob.has_method("get_bipop_body_armor_max") else 10
	var armor_bonus: int = 0
	for module in _get_external_installed_unique_modules():
		if module != null:
			armor_bonus += module.armor_bonus
	lines.append("Armor: %d / %d" % [armor_max + armor_bonus, armor_max + armor_bonus])
	var damage_lines: Array[String] = _get_external_damage_lines()
	if damage_lines.size() > 0:
		var max_damage_rows: int = mini(3, damage_lines.size())
		for i in range(max_damage_rows):
			lines.append("Damage: %s" % damage_lines[i])
	var shield_max: int = 0
	for module in _get_external_installed_unique_modules():
		if module != null:
			shield_max += module.shield_value
	var shield_current: int = mini(shield_max, bipob.energy)
	lines.append("Energy Shield: %d / %d" % [shield_current, shield_max])
	var used_pockets: int = 0
	var max_pockets: int = 4
	if bipob.has_method("get_max_pockets_per_side"):
		max_pockets = bipob.get_max_pockets_per_side() * 4
	for side_id in ["front", "back", "left", "right"]:
		for pocket_index in range(3):
			if bipob.has_method("is_external_pocket_enabled") and bipob.is_external_pocket_enabled(side_id, pocket_index):
				used_pockets += 1
	lines.append("Pocket: %d / %d" % [used_pockets, max_pockets])
	return lines


func _get_external_damage_lines() -> Array[String]:
	var lines: Array[String] = []
	for module in _get_external_installed_unique_modules():
		if not _does_external_module_deal_damage(module):
			continue
		lines.append("%d %s" % [_get_external_module_damage_value(module), _get_external_module_damage_type(module)])
	return lines


func _create_external_storage_right_column() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size = Vector2.ZERO
	column.add_theme_constant_override("separation", 6)

	var filters_panel: Control = _create_external_filter_panel()
	filters_panel.custom_minimum_size = Vector2(0, 46)
	filters_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	column.add_child(filters_panel)

	var storage_panel: Control = _create_external_storage_components_panel()
	storage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(storage_panel)

	var selected_panel: Control = _create_selected_module_info_panel(_get_selected_module_for_context("external"), "external")
	selected_panel.custom_minimum_size = Vector2(0, 145)
	selected_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	column.add_child(selected_panel)

	return column


func _create_external_filter_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, 46)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)

	root.add_child(_create_filter_dropdown_button(false))

	panel.add_child(root)
	return panel


func _create_external_storage_components_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL


	var storage_scroll: ScrollContainer = ScrollContainer.new()
	storage_scroll.name = "ExternalStorageScroll"
	storage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	storage_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(storage_scroll)

	var grid: GridContainer = GridContainer.new()
	grid.columns = _get_box_storage_grid_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_scroll.add_child(grid)

	var storage_indices: Array[int] = get_current_filtered_box_storage_indices()
	var has_external_modules: bool = false
	for storage_index in storage_indices:
		var module: BipobModule = bipob.box_storage[storage_index]
		if module == null:
			continue
		if not bipob.is_external_module(module):
			continue
		has_external_modules = true
		var selected: bool = storage_index == selected_box_storage_index
		grid.add_child(_create_storage_module_card(module, storage_index, selected))

	if not has_external_modules:
		var empty_label: Label = Label.new()
		empty_label.text = "No external modules in storage."
		_apply_label_style(empty_label, true, false)
		grid.add_child(empty_label)

	panel.add_child(root)
	return panel

func _create_external_bottom_action_bar() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, _get_external_bottom_bar_height())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_END

	var actions_row: HBoxContainer = HBoxContainer.new()
	actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_row.add_theme_constant_override("separation", 6)
	actions_row.add_spacer(true)

	var selected_external_slot_module: BipobModule = selected_constructor_module if selected_module_source == "installed_external" else bipob.get_external_module_at(
		bipob.selected_external_side,
		bipob.selected_external_origin
	)

	var buttons: Array[Dictionary] = [
		{"text": "Place", "handler": Callable(self, "_on_place_external_module_pressed"), "role": "primary", "enabled": _can_place_selected_external_visual()},
		{"text": "Remove", "handler": Callable(self, "_on_remove_external_module_pressed"), "role": "danger", "enabled": selected_external_slot_module != null},
		{"text": "Clear Plan", "handler": Callable(self, "_on_clear_plan_pressed"), "role": "danger", "enabled": true},
		{"text": "Auto Configure", "handler": Callable(self, "_on_auto_configure_pressed"), "role": "primary", "enabled": true},
	]

	for config in buttons:
		_add_action_button(
			actions_row,
			String(config.get("text", "")),
			config.get("handler", Callable()),
			String(config.get("role", "normal")),
			bool(config.get("enabled", true)),
			true
		)
	actions_row.add_spacer(true)

	panel.add_child(actions_row)
	return panel


func _create_internal_storage_components_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL


	var storage_scroll: ScrollContainer = ScrollContainer.new()
	storage_scroll.name = "InternalStorageScroll"
	storage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	storage_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(storage_scroll)

	var grid: GridContainer = GridContainer.new()
	var columns: int = _get_box_storage_grid_columns()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_scroll.add_child(grid)

	var storage_indices: Array[int] = get_current_filtered_box_storage_indices()
	var has_internal_modules: bool = false
	for storage_index in storage_indices:
		var module: BipobModule = bipob.box_storage[storage_index]
		if module == null:
			continue
		if not _should_show_module_in_internal_storage(module):
			continue
		has_internal_modules = true
		var selected: bool = storage_index == selected_box_storage_index
		grid.add_child(_create_storage_module_card(module, storage_index, selected))

	if not has_internal_modules:
		var empty_label: Label = Label.new()
		empty_label.text = "No internal modules in storage."
		_apply_label_style(empty_label, true, false)
		grid.add_child(empty_label)


	panel.add_child(root)
	return panel


func _create_internal_interfaces_placeholder_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(170, 140)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = "INTERFACES"
	_apply_label_style(title, false, true)
	root.add_child(title)
	for row_title in ["Power", "Data", "Cooling"]:
		var line_label: Label = Label.new()
		line_label.text = "%s Line" % row_title
		_apply_label_style(line_label, true, false)
		root.add_child(line_label)
	panel.add_child(root)
	return panel



func _get_selected_module_for_context(_context: String) -> BipobModule:
	return _get_selected_box_storage_module()


func _create_selected_module_size_preview(module: BipobModule, context: String) -> Control:
	return _create_selected_module_footprint_preview(module, context)


func _create_selected_module_visual_preview(module: BipobModule, _context: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SELECTED_MODULE_VISUAL_PREVIEW_SIZE
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 4))
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var preview_texture: Texture2D = _load_module_icon_texture(module)
	if preview_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = preview_texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview_root.add_child(texture_rect)
	else:
		var preview_label := Label.new()
		preview_label.text = bipob.get_module_visual_short_label(module) if bipob != null and bipob.has_method("get_module_visual_short_label") else "MOD"
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_apply_label_style(preview_label, false, true)
		preview_root.add_child(preview_label)

	panel.add_child(preview_root)
	return panel


func _create_selected_module_footprint_preview(module: BipobModule, context: String) -> Control:
	if context == "internal" or (module != null and module.placement_type.begins_with("internal")):
		return _create_internal_footprint_size_preview(module, context)
	return _create_external_flat_size_preview(module)


func _create_external_flat_size_preview(module: BipobModule) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SELECTED_MODULE_FOOTPRINT_PREVIEW_SIZE
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 4))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	if module == null:
		panel.add_child(root)
		return panel

	var footprint_size: Vector2i = Vector2i(maxi(1, module.external_width), maxi(1, module.external_height))
	var preview_columns: int = maxi(1, footprint_size.x)
	var preview_rows: int = maxi(1, footprint_size.y)
	var grid := GridContainer.new()
	grid.columns = preview_columns
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for y in range(preview_rows):
		for x in range(preview_columns):
			var cell := ColorRect.new()
			cell.custom_minimum_size = SELECTED_MODULE_PREVIEW_CELL_SIZE
			cell.color = Color(0.35, 0.75, 0.95, 0.55)
			grid.add_child(cell)
	root.add_child(grid)
	var size_label := Label.new()
	size_label.text = "%dx%d" % [footprint_size.x, footprint_size.y]
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(size_label, true, false)
	root.add_child(size_label)
	panel.add_child(root)
	return panel


func _create_internal_footprint_size_preview(module: BipobModule, context: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(84, 64)
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 4))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	if module == null:
		panel.add_child(root)
		return panel
	var is_overlay: bool = context == "internal" and (bipob.is_internal_overlay_module(module) or module.placement_type == "internal_overlay" or module.get_internal_size() == Vector3i.ZERO)
	if is_overlay:
		var overlay_label := Label.new()
		overlay_label.text = "Overlay"
		_apply_label_style(overlay_label, true, false)
		overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(overlay_label)
		panel.add_child(root)
		return panel

	var internal_size: Vector3i = module.get_internal_size()
	var footprint_size: Vector2i = Vector2i(maxi(1, internal_size.x), maxi(1, internal_size.y))
	var preview_columns: int = maxi(4, footprint_size.x)
	var preview_rows: int = maxi(4, footprint_size.y)
	var grid := GridContainer.new()
	grid.columns = preview_columns
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for y in range(preview_rows):
		for x in range(preview_columns):
			var c := ColorRect.new()
			c.custom_minimum_size = SELECTED_MODULE_PREVIEW_CELL_SIZE
			var is_filled: bool = x < footprint_size.x and y < footprint_size.y
			c.color = Color(0.35, 0.75, 0.95, 0.55) if is_filled else Color(0.2, 0.24, 0.3, 0.35)
			grid.add_child(c)
	root.add_child(grid)
	var height_label := Label.new()
	height_label.text = "H:%d" % maxi(1, internal_size.z)
	_apply_label_style(height_label, true, false)
	height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(height_label)
	panel.add_child(root)
	return panel


func _draw_selected_module_mini_preview(control: Control, module: BipobModule, context: String) -> void:
	if control == null or module == null:
		return
	var rect_size: Vector2 = control.size
	var is_overlay: bool = context == "internal" and (bipob.is_internal_overlay_module(module) or module.placement_type == "internal_overlay" or module.get_internal_size() == Vector3i.ZERO)
	if is_overlay:
		var mid_y: float = rect_size.y * 0.52
		var line_color: Color = Color(0.35, 0.75, 0.95, 0.72)
		control.draw_line(Vector2(14, mid_y), Vector2(rect_size.x - 14, mid_y), line_color, 2.0, true)
		control.draw_line(Vector2(20, mid_y - 6), Vector2(rect_size.x - 20, mid_y + 6), Color(0.35, 0.75, 0.95, 0.35), 1.0, true)
		return

	var module_size: Vector3i = module.get_internal_size()
	var size_x: int = maxi(1, module_size.x)
	var size_y: int = maxi(1, module_size.y)
	var size_z: int = maxi(1, module_size.z)

	var margin: float = 10.0
	var available_w: float = maxf(8.0, rect_size.x - margin * 2.0)
	var available_h: float = maxf(8.0, rect_size.y - margin * 2.0)
	var sx: float = available_w / float(size_x + size_y + 1)
	var sy: float = available_h / float((size_x + size_y) * 0.5 + size_z + 1)
	var unit: float = maxf(2.0, minf(sx, sy))

	var local_origin: Vector2 = Vector2.ZERO
	var min_point: Vector2 = _project_selected_module_iso_point(local_origin, unit, 0, 0, 0)
	var max_point: Vector2 = min_point
	for z in range(size_z + 1):
		for y in range(size_y + 1):
			for x in range(size_x + 1):
				var corner: Vector2 = _project_selected_module_iso_point(local_origin, unit, x, y, z)
				min_point.x = minf(min_point.x, corner.x)
				min_point.y = minf(min_point.y, corner.y)
				max_point.x = maxf(max_point.x, corner.x)
				max_point.y = maxf(max_point.y, corner.y)
	var shape_size: Vector2 = max_point - min_point
	var origin: Vector2 = Vector2(
		margin + (available_w - shape_size.x) * 0.5 - min_point.x,
		margin + (available_h - shape_size.y) * 0.5 - min_point.y
	)

	for z in range(size_z):
		for y in range(size_y):
			for x in range(size_x):
				_draw_selected_module_mini_iso_cell(control, origin, unit, x, y, z)



func _project_selected_module_iso_point(origin: Vector2, unit: float, x: int, y: int, z: int) -> Vector2:
	return origin + Vector2((float(x) - float(y)) * unit, -(float(x + y)) * unit * 0.5 - float(z) * unit)


func _draw_selected_module_mini_iso_cell(control: Control, origin: Vector2, unit: float, x: int, y: int, z: int) -> void:
	var p000: Vector2 = _project_selected_module_iso_point(origin, unit, x, y, z)
	var p100: Vector2 = _project_selected_module_iso_point(origin, unit, x + 1, y, z)
	var p010: Vector2 = _project_selected_module_iso_point(origin, unit, x, y + 1, z)
	var p001: Vector2 = _project_selected_module_iso_point(origin, unit, x, y, z + 1)
	var p101: Vector2 = _project_selected_module_iso_point(origin, unit, x + 1, y, z + 1)
	var p011: Vector2 = _project_selected_module_iso_point(origin, unit, x, y + 1, z + 1)
	var p111: Vector2 = _project_selected_module_iso_point(origin, unit, x + 1, y + 1, z + 1)

	control.draw_colored_polygon(PackedVector2Array([p001, p101, p111, p011]), Color(0.20, 0.56, 0.74, 0.52))
	control.draw_colored_polygon(PackedVector2Array([p000, p100, p101, p001]), Color(0.12, 0.34, 0.50, 0.58))
	control.draw_colored_polygon(PackedVector2Array([p000, p001, p011, p010]), Color(0.09, 0.28, 0.44, 0.62))

	var edge_color: Color = Color(0.36, 0.82, 1.0, 0.92)
	var edge_width: float = 0.95
	control.draw_line(p001, p101, edge_color, edge_width, true)
	control.draw_line(p101, p111, edge_color, edge_width, true)
	control.draw_line(p111, p011, edge_color, edge_width, true)
	control.draw_line(p011, p001, edge_color, edge_width, true)
	control.draw_line(p000, p001, edge_color, edge_width, true)
	control.draw_line(p000, p100, edge_color, edge_width, true)
	control.draw_line(p000, p010, edge_color, edge_width, true)

func _get_module_size_text(module: BipobModule) -> String:
	if module == null:
		return ""

	if module.placement_type == "external":
		return "%dx%d" % [module.external_width, module.external_height]

	if module.placement_type == "internal_overlay":
		return "Overlay"

	var size := module.get_internal_size()
	if size == Vector3i.ZERO:
		return "Overlay"

	return "%dx%dx%d" % [size.x, size.y, size.z]


func _format_external_sides_for_ui(sides: Array) -> String:
	var normalized: Array = []
	for side_variant in sides:
		normalized.append(String(side_variant))

	if normalized.is_empty():
		return ""

	var has_top := "top" in normalized
	var has_bottom := "bottom" in normalized
	var has_left := "left" in normalized
	var has_right := "right" in normalized
	var has_front := "front" in normalized
	var has_back := "back" in normalized

	if has_top and has_bottom and has_left and has_right and has_front and has_back:
		return "All"

	if has_left and has_right and has_front and has_back and not has_top and not has_bottom:
		return "Side/Front/Back"

	if has_left and has_right and has_front and not has_back and not has_top and not has_bottom:
		return "Side/Front"

	if has_left and has_right and not has_front and not has_back and not has_top and not has_bottom:
		return "Side"

	var names: Array = []
	if has_top:
		names.append("Top")
	if has_bottom:
		names.append("Bottom")
	if has_front:
		names.append("Front")
	if has_back:
		names.append("Back")
	if has_left or has_right:
		names.append("Side")

	return ", ".join(names)


func _get_module_install_text(module: BipobModule) -> String:
	if module == null:
		return ""
	if module.placement_type == "external":
		var sides: Array = []
		if bipob.has_method("get_allowed_external_sides_for_module"):
			sides = bipob.get_allowed_external_sides_for_module(module)
		var sides_text := _format_external_sides_for_ui(sides)
		return "Install: %s" % sides_text if not sides_text.is_empty() else ""
	var notes := String(module.install_notes).strip_edges()
	return "Install: %s" % notes if not notes.is_empty() else ""

func _get_module_type_text(module: BipobModule) -> String:
	if module == null:
		return "Other"
	var type_text := String(module.category).strip_edges()
	if type_text.is_empty():
		type_text = "Other"
	return type_text


func _get_module_characteristics_lines(module: BipobModule, context: String = "") -> Array:
	return GameUITextHelpersRef.get_module_characteristics_lines(module, context)

func _get_internal_characteristics_lines(module: BipobModule) -> Array:
	return GameUITextHelpersRef.get_internal_characteristics_lines(module)

func _get_module_version_display_text(module: BipobModule) -> String:
	var version_number: int = _get_module_icon_version_number(module)
	if version_number > 0:
		return "V%d" % version_number
	if module != null:
		var version_text: String = String(module.version).strip_edges()
		if not version_text.is_empty():
			return version_text
	return "Unknown"


func _create_selected_module_info_panel(module: BipobModule, context: String) -> Control:
	var panel := PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, 190)
	var info_root := HBoxContainer.new()
	info_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_root.add_theme_constant_override("separation", 6)
	if module == null:
		var empty := Label.new()
		empty.text = "Select a module"
		_apply_label_style(empty, true, false)
		info_root.add_child(empty)
		panel.add_child(info_root)
		return panel
	if _is_module_unknown(module):
		var unknown_label := Label.new()
		unknown_label.text = "UNKNOWN"
		unknown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unknown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		unknown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_apply_label_style(unknown_label, false, true)
		panel.add_child(unknown_label)
		var unknown_badge: Control = _build_module_icon_badge(module, MODULE_TYPE_ICON_PREVIEW_BADGE_SIZE)
		if unknown_badge != null:
			_anchor_module_type_icon_bottom_right(unknown_badge, MODULE_TYPE_ICON_PREVIEW_BADGE_SIZE, MODULE_TYPE_ICON_TILE_PADDING)
			panel.add_child(unknown_badge)
		return panel
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(192, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 4)
	var previews := HBoxContainer.new()
	previews.add_theme_constant_override("separation", 6)
	previews.add_child(_apply_module_icon_badge_to_preview_block(_create_selected_module_visual_preview(module, context), module))
	previews.add_child(_create_selected_module_footprint_preview(module, context))
	left.add_child(previews)
	var name_label := Label.new(); name_label.text = _get_module_title_for_selected_info(module); _apply_label_style(name_label); left.add_child(name_label)
	var type_label := Label.new(); type_label.text = "Type: %s" % _get_module_type_text(module); _apply_label_style(type_label, true, false); left.add_child(type_label)
	var version_label := Label.new(); version_label.text = "Version: %s" % _get_module_version_display_text(module); _apply_label_style(version_label, true, false); left.add_child(version_label)
	var install_text := _get_module_install_text(module)
	if not install_text.is_empty():
		var install_label := Label.new(); install_label.text = install_text; install_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _apply_label_style(install_label, true, false); left.add_child(install_label)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(0, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 2)
	var c_title := Label.new(); c_title.text = "Characteristics"; _apply_label_style(c_title, false, true); right.add_child(c_title)
	var characteristic_lines: Array = _get_module_characteristics_lines(module, context)
	var characteristic_label := Label.new()
	characteristic_label.text = "Characteristics will be added later." if characteristic_lines.is_empty() else "\n".join(characteristic_lines)
	characteristic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	characteristic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_style(characteristic_label, true, false)
	right.add_child(characteristic_label)
	var d_title := Label.new(); d_title.text = "Description"; _apply_label_style(d_title, false, true); right.add_child(d_title)
	var description_text := module.description.strip_edges()
	if description_text.is_empty():
		description_text = "Description will be added later."
	var description_label := Label.new()
	description_label.text = description_text
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_apply_label_style(description_label, true, false)
	right.add_child(description_label)
	info_root.add_child(left)
	info_root.add_child(right)
	panel.add_child(info_root)
	if _is_module_broken(module):
		var overlay := ColorRect.new()
		overlay.color = Color(0.35, 0.05, 0.08, 0.55)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.add_child(overlay)
		var broken_label := Label.new()
		broken_label.text = "BROKEN"
		broken_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		broken_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		broken_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_apply_label_style(broken_label, false, true)
		panel.add_child(broken_label)
	return panel

func _get_module_title_for_selected_info(module: BipobModule) -> String:
	if module == null:
		return ""

	var title: String = module.get_display_name()
	var version_text: String = module.version.strip_edges()

	if not version_text.is_empty():
		var suffix: String = " " + version_text
		if title.ends_with(suffix):
			title = title.substr(0, title.length() - suffix.length())

	return title

func _create_internal_bottom_action_bar() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.custom_minimum_size = Vector2(0, _get_internal_bottom_bar_height())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_END

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)

	var row_one: HBoxContainer = HBoxContainer.new()
	row_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_one.alignment = BoxContainer.ALIGNMENT_CENTER
	row_one.add_theme_constant_override("separation", 4)
	row_one.add_spacer(true)

	var internal_remove_available: bool = _can_remove_selected_internal_module()
	# View/overlay debug controls intentionally hidden from player-facing Internal UI.
	# They can be reintroduced under Reference / Preview later.
	var row_one_buttons: Array[Dictionary] = [
		{"text": "Rotate", "handler": Callable(self, "_on_rotate_internal_pressed"), "role": "normal", "enabled": true, "compact": true},
		{"text": "Place", "handler": Callable(self, "_on_place_internal_pressed"), "role": "primary", "enabled": _can_place_selected_internal_visual(), "compact": true},
		{"text": "Remove", "handler": Callable(self, "_on_remove_internal_pressed"), "role": "danger", "enabled": internal_remove_available, "compact": true},
		{"text": "Clear Plan", "handler": Callable(self, "_on_clear_plan_pressed"), "role": "danger", "enabled": true, "compact": true},
		{"text": "Auto Configure", "handler": Callable(self, "_on_auto_configure_pressed"), "role": "primary", "enabled": true, "compact": true},
	]


	for config in row_one_buttons:
		_add_action_button(
			row_one,
			String(config.get("text", "")),
			config.get("handler", Callable()),
			String(config.get("role", "normal")),
			bool(config.get("enabled", true)),
			bool(config.get("compact", true))
		)
	row_one.add_spacer(true)

	root.add_child(row_one)
	panel.add_child(root)
	return panel


func _get_internal_storage_grid_columns() -> int:
	return _get_box_storage_grid_columns()


func _get_internal_bottom_bar_height() -> float:
	var viewport_height: float = _get_viewport_height()

	if viewport_height < 720.0:
		return 44.0

	return 52.0


func _reorder_indices_right_to_left_by_rows(indices: Array[int], columns: int) -> Array[int]:
	if columns <= 1:
		return indices
	var result: Array[int] = []
	var row_start: int = 0
	while row_start < indices.size():
		var row: Array[int] = []
		for i in range(columns):
			var source_index: int = row_start + i
			if source_index >= indices.size():
				break
			row.append(indices[source_index])
		row.reverse()
		result.append_array(row)
		row_start += columns
	return result


func _create_constructor_dashboard_layout() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var title: Label = Label.new()
	title.text = "CONSTRUCTOR DASHBOARD"
	_apply_label_style(title, false, true)
	root.add_child(title)

	if _safe_has_bipob_method("get_constructor_readiness_summary_text"):
		root.add_child(_create_constructor_playable_status_panel())

	var hint_text_label: Label = Label.new()
	hint_text_label.text = "Select External or Internal tab to configure BOX."
	hint_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(hint_text_label, true, false)
	root.add_child(hint_text_label)

	panel.add_child(root)
	return panel


func get_digital_storage_short_text() -> String:
	if bipob == null:
		return "Digital: empty"
	if bipob.has_method("get_digital_storage_short_text"):
		var short_text := str(bipob.get_digital_storage_short_text())
		if short_text.is_empty() or short_text == "empty":
			return "Digital: empty"
		return "Digital: %s" % short_text
	if bipob.has_method("get_digital_storage_text"):
		var full_text := str(bipob.get_digital_storage_text())
		if full_text.begins_with("Digital storage:\n- "):
			var list_text := full_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
			if list_text.is_empty():
				return "Digital: empty"
			return "Digital: %s" % list_text
		if full_text.begins_with("Digital storage: "):
			var one_line := full_text.trim_prefix("Digital storage: ")
			if one_line.is_empty() or one_line == "empty":
				return "Digital: empty"
			return "Digital: %s" % one_line
	return "Digital: empty"

func format_2d_size(size: Vector2i) -> String:
	return "%d×%d" % [size.x, size.y]

func format_3d_size(size: Vector3i) -> String:
	return "%d×%d×%d" % [size.x, size.y, size.z]

func get_module_details_text(module: BipobModule) -> String:
	if module == null:
		return "Selected Module:\nnone"
	var lines: Array[String] = []
	lines.append("Selected Module:")
	lines.append("Selected: %s" % bipob.get_module_display_name(module))
	lines.append("ID: %s" % module.id)
	lines.append("Visual: %s / %s" % [bipob.get_module_visual_short_label(module), bipob.get_module_visual_key(module)])
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		lines.append("Placement: overlay path")
		lines.append("Overlay Type: liquid" if module.id == "water_tube_v1" else "Overlay Type: duct")
	else:
		lines.append("Placement: %s" % ("external slot" if module.placement_type == "external" else "internal volume"))
	lines.append("Category: %s" % bipob.get_module_category(module))
	if module.placement_type == "external":
		var module_size_2d: Vector2i = bipob.get_external_module_size(module)
		lines.append("Size: %s external" % format_2d_size(module_size_2d))
		lines.append("Allowed sides: %s" % bipob.get_allowed_external_sides_text(module))
	elif module.placement_type == "internal":
		var module_size_3d := Vector3i(module.size_x, module.size_y, module.size_z)
		lines.append("Size: %s" % format_3d_size(module_size_3d))
		lines.append("Role: %s" % _get_module_role_text(module))
		lines.append("Heat: %d / %d" % [module.heat_idle, module.heat_active])
		if module.cooling_power > 0 or module.cooling_type != "none":
			if module.cooling_type == "none":
				lines.append("Cooling: %d" % module.cooling_power)
			elif module.cooling_power > 0:
				lines.append("Cooling: %s %d" % [module.cooling_type, module.cooling_power])
			else:
				lines.append("Cooling: %s" % module.cooling_type)
		else:
			lines.append("Cooling: none")
		lines.append("Air Intake: %s" % ("required" if module.requires_air_intake else "no"))
		lines.append("Allowed sides: n/a")
	else:
		lines.append("Size: n/a")
		lines.append("Allowed sides: n/a")
	if not module.description.is_empty():
		lines.append("Description: %s" % module.description)
	lines.append(str(bipob.get_module_repair_metadata_text(module)))
	lines.append(bipob.get_module_availability_text(module))
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		lines.append("Note: does not consume Internal Volume")
	return "\n".join(lines)



# -----------------------------------------------------------------------------
# Runtime HUD
# -----------------------------------------------------------------------------

func _get_runtime_sidebar_width() -> float:
	var viewport_width: float = _get_viewport_width()
	if viewport_width <= 1100.0:
		return 330.0
	if viewport_width <= 1500.0:
		return 380.0
	return 420.0


func _get_runtime_margin() -> float:
	return 12.0


func _get_runtime_top_panel_height() -> float:
	return 68.0


func _get_runtime_bottom_panel_height() -> float:
	return 150.0


func _get_map_constructor_palette_rect() -> Rect2:
	var safe_margin: float = maxf(_get_runtime_margin(), 12.0)
	var viewport: Vector2 = _get_viewport_size()
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root) and runtime_hud_root.size.x > 0.0 and runtime_hud_root.size.y > 0.0:
		viewport = Vector2(minf(viewport.x, runtime_hud_root.size.x), minf(viewport.y, runtime_hud_root.size.y))
	viewport.x = maxf(viewport.x, safe_margin * 2.0 + 1.0)
	viewport.y = maxf(viewport.y, safe_margin * 2.0 + 1.0)

	var desired_width: float = _get_runtime_sidebar_width_adaptive()
	var available_width: float = maxf(viewport.x - safe_margin * 2.0, 1.0)
	var minimum_usable_width: float = minf(280.0, available_width)
	var palette_width: float = minf(maxf(desired_width, minimum_usable_width), available_width)
	var left_limit: float = safe_margin
	var right_limit: float = maxf(left_limit, viewport.x - safe_margin - palette_width)
	var palette_x: float = clampf(viewport.x - palette_width - safe_margin, left_limit, right_limit)
	if palette_x + palette_width > viewport.x - safe_margin:
		palette_width = maxf(1.0, viewport.x - safe_margin - palette_x)

	# The runtime Things | Storage preview is bottom-right now, so constructor
	# palettes can continue to use the top-right space without overlap.
	var top_y: float = safe_margin
	var mission_panel_top_y: float = viewport.y - _get_runtime_bottom_panel_height() - safe_margin
	var bottom_y: float = viewport.y - safe_margin if map_constructor_state.map_constructor_mode_active else mission_panel_top_y - 8.0
	var bottom_limit: float = maxf(top_y + 1.0, viewport.y - safe_margin)
	var minimum_bottom_y: float = minf(top_y + 72.0, bottom_limit)
	bottom_y = clampf(bottom_y, minimum_bottom_y, bottom_limit)
	var palette_height: float = maxf(bottom_y - top_y, 1.0)

	return Rect2(Vector2(palette_x, top_y), Vector2(palette_width, palette_height))


func _get_map_constructor_bottom_inspector_rect() -> Rect2:
	var margin: float = _get_runtime_margin()
	var viewport: Vector2 = _get_viewport_size()
	var palette_rect: Rect2 = _get_map_constructor_palette_rect()
	var base_height: float = clampf(_get_runtime_bottom_panel_height() + 90.0, 230.0, 290.0)
	var height: float = base_height * 2.0 if map_constructor_state.map_constructor_inspector_expanded else base_height
	var left: float = margin
	var right: float = clampf(palette_rect.position.x - margin, left + 1.0, viewport.x - margin)
	var bottom: float = viewport.y - margin
	var top: float = maxf(margin, bottom - height)
	return Rect2(Vector2(left, top), Vector2(maxf(right - left, 1.0), maxf(bottom - top, 1.0)))


func _set_runtime_bottom_hud_visible(visible_state: bool) -> void:
	if runtime_hud_root == null or not is_instance_valid(runtime_hud_root):
		return
	var bottom_left: Control = runtime_hud_root.get_node_or_null("RuntimeBottomLeft") as Control
	if bottom_left != null:
		bottom_left.visible = visible_state
	RuntimeStoragePanelRef.set_visible(self, visible_state)


func _toggle_map_constructor_inspector_expanded() -> void:
	map_constructor_state.map_constructor_inspector_expanded = not map_constructor_state.map_constructor_inspector_expanded
	_show_map_constructor_inspector(map_constructor_state.selected_map_constructor_entity_cell, map_constructor_state.selected_map_constructor_entity_kind, map_constructor_state.selected_map_constructor_entity_id)


func _safe_reparent_control(control: Control, new_parent: Node) -> void:
	if control == null or new_parent == null:
		return
	var current_parent: Node = control.get_parent()
	if current_parent == new_parent:
		return
	if current_parent != null:
		current_parent.remove_child(control)
	new_parent.add_child(control)



func _get_runtime_play_area_rect() -> Rect2:
	var margin: float = _get_safe_margin()
	var top_h: float = _get_runtime_top_panel_height()
	var bottom_h: float = _get_runtime_bottom_panel_height()
	var viewport: Vector2 = _get_viewport_size()
	var left: float = margin
	var top: float = margin + top_h + margin
	var right: float = viewport.x - margin
	var bottom: float = viewport.y - bottom_h - margin * 2.0
	return Rect2(Vector2(left, top), Vector2(maxf(right - left, 1.0), maxf(bottom - top, 1.0)))


func _attach_runtime_gameplay_view() -> void:
	_apply_runtime_gameplay_field_transform()
	call_deferred("_sync_runtime_bipob_visual_state")


func _apply_runtime_gameplay_field_transform() -> void:
	var grid: GridManager = get_node_or_null("../Field") as GridManager
	var field: Node2D = grid as Node2D
	if field == null:
		return
	if runtime_mission_field_host == null or not is_instance_valid(runtime_mission_field_host):
		return
	field.visible = true
	field.z_index = 0
	var play_rect: Rect2 = _get_runtime_play_area_rect()
	runtime_mission_field_host.global_position = play_rect.position
	runtime_mission_field_host.size = play_rect.size
	var board_size: Vector2 = Vector2(grid.get_map_width() * grid.cell_size, grid.get_map_height() * grid.cell_size)
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return
	var target_origin := play_rect.position + (play_rect.size - board_size) * 0.5
	field.global_position = target_origin

	var player: Node2D = get_node_or_null("../Bipob") as Node2D
	if player != null:
		player.visible = true
		player.z_index = 1
		var body_marker: CanvasItem = player.get_node_or_null("Body") as CanvasItem
		if body_marker != null:
			body_marker.visible = true


func _ensure_runtime_hud_root() -> Control:
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		return runtime_hud_root
	runtime_hud_root = Control.new()
	runtime_hud_root.name = "RuntimeHudRoot"
	runtime_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	runtime_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	runtime_hud_root.z_index = Z_RUNTIME_HUD
	runtime_hud_root.z_as_relative = false
	add_child(runtime_hud_root)
	return runtime_hud_root


func _get_mission_bipobs() -> Array[Dictionary]:
	return get_selected_bipobs_for_mission()


func _has_multiple_mission_bipobs() -> bool:
	return _get_mission_bipobs().size() > 1


func _get_mission_bipob_display_name(bipob_data: Dictionary, index: int) -> String:
	var display_name: String = str(bipob_data.get("name", "")).strip_edges()
	if display_name.is_empty():
		var profile_id: String = str(bipob_data.get("id", "")).strip_edges()
		if BIPOB_PROFILE_NAMES.has(profile_id):
			display_name = str(BIPOB_PROFILE_NAMES[profile_id])
	if display_name.is_empty():
		display_name = "Bipob %d" % (index + 1)
	return display_name


func _set_active_mission_bipob(index: int) -> void:
	var mission_bipobs: Array[Dictionary] = _get_mission_bipobs()
	if mission_bipobs.is_empty():
		runtime_selected_mission_bipob_index = 0
		return
	var clamped_index: int = clampi(index, 0, mission_bipobs.size() - 1)
	if clamped_index == runtime_selected_mission_bipob_index and bipob != null:
		return
	runtime_selected_mission_bipob_index = clamped_index
	_clear_box_module_selection()
	var selected_data: Dictionary = mission_bipobs[clamped_index]
	var profile_id: String = str(selected_data.get("id", "")).strip_edges()
	if not profile_id.is_empty() and profile_id != active_bipob_profile_id:
		_save_active_bipob_profile()
		_load_bipob_profile(profile_id)
	_refresh_active_mission_bipob_hud()


func _refresh_active_mission_bipob_hud() -> void:
	update_status()
	_update_runtime_bipob_switch_card_styles()


func _select_runtime_mission_bipob(index: int) -> void:
	var mission_bipobs: Array[Dictionary] = _get_mission_bipobs()
	if index < 0 or index >= mission_bipobs.size():
		_update_runtime_bipob_switch_card_styles()
		return
	if index == runtime_selected_mission_bipob_index:
		_update_runtime_bipob_switch_card_styles()
		show_hint("Active Bipob: %s" % _get_mission_bipob_display_name(mission_bipobs[index], index))
		return
	_set_active_mission_bipob(index)
	update_diagnostic_status()
	_refresh_runtime_storage_panel()
	_refresh_runtime_interaction_controls()
	show_hint("Active Bipob: %s" % _get_mission_bipob_display_name(mission_bipobs[index], index))


func _on_bipob_switch_card_pressed(index: int) -> void:
	_select_runtime_mission_bipob(index)


func _update_runtime_bipob_switch_card_styles() -> void:
	RuntimeBipobSwitcherRef.refresh(self)


func _create_bipob_switcher_panel() -> PanelContainer:
	var margin: float = _get_runtime_margin()
	var top_offset: float = margin + RuntimeMissionMenuRef.MENU_BUTTON_SIZE.y + 6.0
	return RuntimeBipobSwitcherRef.build(self, runtime_hud_root, margin, top_offset)


func _apply_runtime_hud_layout() -> void:
	var root: Control = _ensure_runtime_hud_root()
	root.visible = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		child.queue_free()
	runtime_energy_label = null
	runtime_actions_label = null
	runtime_info_actions_label = null
	mission_goal_value_label = null
	runtime_notification_label = null
	runtime_notification_panel = null

	if hud_status_label != null:
		hud_status_label.visible = false
	if hint_label != null:
		hint_label.visible = false
	if hud_diagnostic_label != null:
		hud_diagnostic_label.visible = false

	var margin: float = _get_runtime_margin()
	var top_panel_height: float = _get_runtime_top_panel_height()
	var bottom_area_height: float = _get_runtime_bottom_panel_height()
	var sidebar_width: float = _get_runtime_sidebar_width_adaptive()
	var viewport: Vector2 = _get_viewport_size()
	var stats_height: float = 34.0
	var bottom_y: float = viewport.y - bottom_area_height - margin

	var top_row := HBoxContainer.new()
	top_row.name = "RuntimeTopNotificationRow"
	top_row.position = Vector2(margin, margin)
	top_row.size = Vector2(maxf(viewport.x - sidebar_width - margin * 3.0, 200.0), top_panel_height)
	top_row.add_theme_constant_override("separation", 8)
	root.add_child(top_row)

	var objective_panel := PanelContainer.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_panel.custom_minimum_size = Vector2(220, top_panel_height)
	objective_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER, 1, 8))
	top_row.add_child(objective_panel)
	var objective_margin := MarginContainer.new()
	objective_margin.add_theme_constant_override("margin_left", 10)
	objective_margin.add_theme_constant_override("margin_right", 10)
	objective_margin.add_theme_constant_override("margin_top", 6)
	objective_margin.add_theme_constant_override("margin_bottom", 6)
	objective_panel.add_child(objective_margin)
	objective_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var objective_lines: VBoxContainer = VBoxContainer.new()
	objective_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_lines.size_flags_vertical = Control.SIZE_EXPAND_FILL
	objective_lines.add_theme_constant_override("separation", 2)
	objective_margin.add_child(objective_lines)
	runtime_info_actions_label = Label.new()
	runtime_info_actions_label.name = "RuntimeObjectiveHeadingLabel"
	runtime_info_actions_label.text = "GOAL"
	runtime_info_actions_label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	objective_lines.add_child(runtime_info_actions_label)
	mission_goal_value_label = Label.new()
	mission_goal_value_label.name = "RuntimeObjectiveLabel"
	mission_goal_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_goal_value_label.clip_text = true
	mission_goal_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission_goal_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_goal_value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mission_goal_value_label.text = _get_runtime_mission_objective_text()
	objective_lines.add_child(mission_goal_value_label)

	runtime_notification_panel = PanelContainer.new()
	runtime_notification_panel.name = "RuntimeNotificationPanel"
	runtime_notification_panel.custom_minimum_size = Vector2(300, top_panel_height)
	runtime_notification_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 8))
	top_row.add_child(runtime_notification_panel)
	var notification_margin := MarginContainer.new()
	notification_margin.add_theme_constant_override("margin_left", 10)
	notification_margin.add_theme_constant_override("margin_right", 10)
	notification_margin.add_theme_constant_override("margin_top", 6)
	notification_margin.add_theme_constant_override("margin_bottom", 6)
	runtime_notification_panel.add_child(notification_margin)
	notification_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notification_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	runtime_notification_label = Label.new()
	runtime_notification_label.name = "RuntimeNotificationLabel"
	runtime_notification_label.text = ""
	runtime_notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	runtime_notification_label.clip_text = true
	runtime_notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	runtime_notification_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	runtime_notification_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	runtime_notification_label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	notification_margin.add_child(runtime_notification_label)
	_refresh_runtime_notification_fallback()

	var menu_height: float = RuntimeMissionMenuRef.build(self, root, margin)
	runtime_bipob_switcher_panel = RuntimeBipobSwitcherRef.build(self, root, margin, margin + menu_height + 6.0)

	runtime_storage_panel = _create_runtime_storage_panel()

	var mission_field_panel := Control.new()
	mission_field_panel.name = "MissionFieldPanel"
	var play_rect: Rect2 = _get_runtime_play_area_rect()
	mission_field_panel.position = play_rect.position
	mission_field_panel.size = play_rect.size
	mission_field_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mission_field_panel)
	var mission_field_host := Control.new()
	mission_field_host.name = "MissionFieldHost"
	runtime_mission_field_host = mission_field_host
	mission_field_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_field_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mission_field_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_field_panel.add_child(mission_field_host)

	var bottom_left_vbox := VBoxContainer.new()
	bottom_left_vbox.name = "RuntimeBottomLeft"
	bottom_left_vbox.position = Vector2(margin, bottom_y)
	var reserved_storage_width: float = RuntimeStoragePanelRef.get_reserved_bottom_width(self, margin)
	bottom_left_vbox.size = Vector2(maxf(viewport.x - reserved_storage_width - margin * 2.0, 1.0), bottom_area_height)
	bottom_left_vbox.add_theme_constant_override("separation", 4)
	root.add_child(bottom_left_vbox)

	var stats_strip := _create_runtime_stats_strip()
	bottom_left_vbox.add_child(stats_strip)

	var controls_panel := _create_runtime_controls_panel()
	controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_panel.custom_minimum_size = Vector2(0, maxf(bottom_area_height - stats_height - 4.0, 88.0))
	controls_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	bottom_left_vbox.add_child(controls_panel)

	var world_actions_panel: PanelContainer = _create_runtime_world_actions_panel()
	var wa_top: float = margin + top_panel_height + 8.0
	var mission_reserved: float = bottom_area_height + 8.0
	var available_wa_height: float = maxf((viewport.y - margin) - wa_top - mission_reserved, 92.0)
	var wa_left: float = margin
	world_actions_panel.anchor_left = 0.0
	world_actions_panel.anchor_right = 0.0
	world_actions_panel.anchor_top = 0.0
	world_actions_panel.anchor_bottom = 0.0
	world_actions_panel.offset_left = wa_left
	world_actions_panel.offset_top = wa_top
	world_actions_panel.offset_right = wa_left + sidebar_width
	world_actions_panel.offset_bottom = wa_top + available_wa_height
	root.add_child(world_actions_panel)
	runtime_world_actions_panel = world_actions_panel
	_refresh_runtime_mission_objective_label()
	_refresh_map_constructor_panels()


func _refresh_runtime_mission_objective_label() -> void:
	var actions_text: String = _get_runtime_actions_text()
	if runtime_actions_label != null and is_instance_valid(runtime_actions_label):
		runtime_actions_label.text = actions_text
	if mission_goal_value_label != null and is_instance_valid(mission_goal_value_label):
		mission_goal_value_label.text = _get_runtime_mission_objective_text()
	if runtime_notification_timer <= 0.0:
		_refresh_runtime_notification_fallback()


func _get_runtime_secondary_objective_text() -> String:
	var view_model: Dictionary = _get_runtime_mission_objective_view_model()
	var objective_hint: String = String(view_model.get("objective_hint", "")).strip_edges()
	if not objective_hint.is_empty() and not objective_hint.contains("legacy BipobController logic"):
		return objective_hint
	return String(view_model.get("goal_text", "No active objective")).strip_edges()


func _refresh_runtime_notification_fallback() -> void:
	RuntimeNotifications.refresh_runtime_notification_fallback(self)


func _get_runtime_mission_objective_view_model() -> Dictionary:
	if mission_manager_runtime != null and is_instance_valid(mission_manager_runtime) and mission_manager_runtime.has_method("get_current_mission_objective_view_model"):
		var view_model_variant: Variant = mission_manager_runtime.call("get_current_mission_objective_view_model")
		if view_model_variant is Dictionary:
			return view_model_variant
	return {
		"mission_id": "",
		"title": "",
		"goal_title": "Goal",
		"goal_text": "No active objective",
		"objective_hint": "",
		"progress_text": "",
		"status": "active",
		"is_completed": false,
		"is_failed": false,
		"steps": []
	}


func _get_runtime_mission_objective_text() -> String:
	var view_model: Dictionary = _get_runtime_mission_objective_view_model()
	var lines: Array[String] = []
	var title: String = String(view_model.get("title", "")).strip_edges()
	var goal_text: String = String(view_model.get("goal_text", "No active objective")).strip_edges()
	var progress_text: String = String(view_model.get("progress_text", "")).strip_edges()
	var status: String = String(view_model.get("status", "active")).strip_edges()
	if not title.is_empty():
		lines.append(title)
	lines.append(goal_text if not goal_text.is_empty() else "No active objective")
	if not progress_text.is_empty():
		lines.append(progress_text)
	var steps_variant: Variant = view_model.get("steps", [])
	if steps_variant is Array:
		for step_variant in steps_variant:
			if not (step_variant is Dictionary):
				continue
			var step: Dictionary = step_variant
			var step_label: String = String(step.get("label", "")).strip_edges()
			if not step_label.is_empty():
				lines.append("- %s" % step_label)
	if status == "completed":
		lines.append("Status: Completed")
	elif status == "failed":
		lines.append("Status: Failed")
	return "\n".join(lines)


func _create_runtime_stats_strip() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "RuntimeStatsStrip"
	panel.custom_minimum_size = Vector2(0, 32)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 6))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var energy_label: Label = Label.new()
	energy_label.name = "RuntimeEnergyLabel"
	energy_label.text = _get_runtime_energy_text()
	row.add_child(energy_label)
	runtime_energy_label = energy_label

	var actions_label: Label = Label.new()
	actions_label.name = "RuntimeActionsLabel"
	actions_label.text = _get_runtime_actions_text()
	row.add_child(actions_label)
	runtime_actions_label = actions_label

	return panel


func _create_runtime_controls_panel() -> Control:
	return RuntimeControlPanelRef.build(self)


func _create_runtime_control_button(label_text: String, action_callable: Callable, role: String = "normal") -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_action_button_style(button, role, action_callable.is_valid())
	button.disabled = not action_callable.is_valid()
	if action_callable.is_valid():
		button.pressed.connect(action_callable)
	return button


func _get_runtime_energy_text() -> String:
	if bipob == null:
		return "ENERGY --/--"
	return "ENERGY %d/%d" % [int(bipob.energy), int(bipob.max_energy)]


func _get_runtime_actions_text() -> String:
	if bipob == null:
		return "ACTIONS --/--"
	return "ACTIONS %d/%d" % [int(bipob.actions_left), int(bipob.actions_per_turn)]


func _create_runtime_mission_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RuntimeMissionPanel"
	panel.visible = true
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	if restart_mission_button != null:
		_disconnect_all_pressed_connections(restart_mission_button)
		restart_mission_button.pressed.connect(_on_restart_mission_button_pressed)
		restart_mission_button.text = "Restart Mission"
		restart_mission_button.custom_minimum_size = Vector2(0, 28)
		restart_mission_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		restart_mission_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_safe_reparent_control(restart_mission_button, vbox)
	if return_to_box_button != null:
		_disconnect_all_pressed_connections(return_to_box_button)
		return_to_box_button.pressed.connect(_on_runtime_return_to_center_pressed)
		return_to_box_button.text = "Return to Center"
		return_to_box_button.custom_minimum_size = Vector2(0, 28)
		return_to_box_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return_to_box_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_safe_reparent_control(return_to_box_button, vbox)
	if settings_button != null:
		_disconnect_all_pressed_connections(settings_button)
		settings_button.pressed.connect(_on_runtime_settings_pressed)
		settings_button.text = "Settings"
		settings_button.custom_minimum_size = Vector2(0, 28)
		settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_safe_reparent_control(settings_button, vbox)
	if exit_main_menu_button != null:
		_disconnect_all_pressed_connections(exit_main_menu_button)
		exit_main_menu_button.pressed.connect(_on_runtime_exit_to_main_menu_pressed)
		exit_main_menu_button.text = "Exit to Main Menu"
		exit_main_menu_button.custom_minimum_size = Vector2(0, 28)
		exit_main_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		exit_main_menu_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_safe_reparent_control(exit_main_menu_button, vbox)
	return panel

func _create_runtime_world_actions_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RuntimeWorldActionsPanel"
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Actions"
	vbox.add_child(title)
	runtime_world_actions_target_label = Label.new()
	runtime_world_actions_target_label.text = "-"
	vbox.add_child(runtime_world_actions_target_label)
	runtime_world_actions_state_label = Label.new()
	runtime_world_actions_state_label.text = ""
	vbox.add_child(runtime_world_actions_state_label)
	runtime_world_actions_behavior_label = Label.new()
	runtime_world_actions_behavior_label.text = ""
	vbox.add_child(runtime_world_actions_behavior_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	runtime_world_actions_list = VBoxContainer.new()
	runtime_world_actions_list.add_theme_constant_override("separation", 4)
	scroll.add_child(runtime_world_actions_list)
	runtime_world_actions_no_actions_label = Label.new()
	runtime_world_actions_no_actions_label.text = "No available actions"
	runtime_world_actions_list.add_child(runtime_world_actions_no_actions_label)
	var use_button := Button.new()
	use_button.text = "Use Selected"
	use_button.pressed.connect(_on_use_selected_world_action_pressed)
	vbox.add_child(use_button)
	return panel

func _create_runtime_storage_panel() -> PanelContainer:
	return RuntimeStoragePanelRef.build(self, runtime_hud_root, _get_runtime_margin())


func _ready() -> void:
	if hint_label != null:
		hint_label.text = "Mission 1: pick up the key-card, open the door, reach the exit."

	hud_diagnostic_label = Label.new()
	hud_diagnostic_label.name = "DiagnosticLabel"
	hud_diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_diagnostic_label.custom_minimum_size = Vector2(700, 140)
	hud_diagnostic_label.text = "Diagnostic: none"
	add_child(hud_diagnostic_label)

	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = false
	_ensure_action_panel_scrollable()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if box_storage_label == null:
		box_storage_label = Label.new()
		box_storage_label.name = "BoxStorageLabel"
		box_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if box_vbox != null:
			box_vbox.add_child(box_storage_label)
			if start_mission_button != null:
				box_vbox.move_child(box_storage_label, start_mission_button.get_index())

	if digital_storage_label == null:
		digital_storage_label = Label.new()
		digital_storage_label.name = "DigitalStorageLabel"
		digital_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var digital_box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if digital_box_vbox != null:
			digital_box_vbox.add_child(digital_storage_label)
			if start_mission_button != null:
				digital_box_vbox.move_child(digital_storage_label, start_mission_button.get_index())

	if move_forward_button != null:
		move_forward_button.focus_mode = Control.FOCUS_NONE
		move_forward_button.text = "Forward"
	if move_backward_button != null:
		move_backward_button.focus_mode = Control.FOCUS_NONE
		move_backward_button.text = "Backward"
	if turn_left_button != null:
		turn_left_button.focus_mode = Control.FOCUS_NONE
		turn_left_button.text = "Turn Left"
	if turn_right_button != null:
		turn_right_button.focus_mode = Control.FOCUS_NONE
		turn_right_button.text = "Turn Right"
	if interact_button != null:
		interact_button.focus_mode = Control.FOCUS_NONE
	if end_turn_button != null:
		end_turn_button.focus_mode = Control.FOCUS_NONE

	rotate_storage_button = Button.new()
	rotate_storage_button.name = "RotateStorageButton"
	rotate_storage_button.text = "Rotate Storage"
	rotate_storage_button.focus_mode = Control.FOCUS_NONE

	scan_device_button = Button.new()
	scan_device_button.name = "ScanDeviceButton"
	scan_device_button.text = "Scan Device"
	scan_device_button.focus_mode = Control.FOCUS_NONE
	var command_list: Node = null
	if command_panel != null:
		command_list = command_panel.get_node_or_null("CommandList")
	if command_list != null:
		command_list.add_child(rotate_storage_button)
		rotate_storage_button.pressed.connect(_on_rotate_storage_button_pressed)
		command_list.add_child(scan_device_button)
		scan_device_button.pressed.connect(_on_scan_device_button_pressed)
		hack_device_button = Button.new()
		hack_device_button.name = "HackDeviceButton"
		hack_device_button.text = "Hack Device"
		hack_device_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(hack_device_button)
		hack_device_button.pressed.connect(_on_hack_device_button_pressed)
		restart_mission_button = Button.new()
		restart_mission_button.name = "RestartMissionButton"
		restart_mission_button.text = "Restart Mission"
		restart_mission_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(restart_mission_button)
		restart_mission_button.pressed.connect(_on_restart_mission_button_pressed)
		return_to_box_button = Button.new()
		return_to_box_button.name = "ReturnToBoxButton"
		return_to_box_button.text = "Return to Box"
		return_to_box_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(return_to_box_button)
		return_to_box_button.pressed.connect(_on_return_to_box_button_pressed)
		settings_button = Button.new()
		settings_button.name = "SettingsButton"
		settings_button.text = "Settings"
		settings_button.focus_mode = Control.FOCUS_NONE
		settings_button.pressed.connect(_on_runtime_settings_pressed)
		command_list.add_child(settings_button)
		exit_main_menu_button = Button.new()
		exit_main_menu_button.name = "ExitMainMenuButton"
		exit_main_menu_button.text = "Exit to Main Menu"
		exit_main_menu_button.focus_mode = Control.FOCUS_NONE
		exit_main_menu_button.pressed.connect(_on_runtime_exit_to_main_menu_pressed)
		command_list.add_child(exit_main_menu_button)

	_apply_runtime_hud_layout()
	call_deferred("_attach_runtime_gameplay_view")
	_assert_single_active_major_screen()

	if move_forward_button != null:
		move_forward_button.pressed.connect(_on_move_forward_pressed)
	if move_backward_button != null:
		move_backward_button.pressed.connect(_on_move_backward_pressed)
	if turn_left_button != null:
		turn_left_button.pressed.connect(_on_turn_left_pressed)
	if turn_right_button != null:
		turn_right_button.pressed.connect(_on_turn_right_pressed)
	if interact_button != null:
		interact_button.pressed.connect(_on_interact_pressed)
	if end_turn_button != null:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	if charge_button != null:
		charge_button.text = "Charge"
		charge_button.visible = false
		charge_button.focus_mode = Control.FOCUS_NONE
	if install_module_button != null:
		install_module_button.text = "Install"
		install_module_button.visible = false
		install_module_button.focus_mode = Control.FOCUS_NONE
	if start_mission_button != null:
		start_mission_button.text = "Start"
		start_mission_button.visible = false
		start_mission_button.focus_mode = Control.FOCUS_NONE

	remove_module_button = null

	prev_installed_button = null

	next_installed_button = null

	prev_box_button = null

	next_box_button = null

	external_tab_button = null
	internal_tab_button = null
	bipob_alpha_button = null
	bipob_beta_button = null
	bipob_juggernaut_button = null
	box_back_button = null

	box_restart_button = null

	box_return_button = null

	_create_app_menu_roots()

	_apply_constructor_visual_style()

	_apply_constructor_ui_skin()
	show_main_menu_screen()


func _apply_constructor_visual_style() -> void:
	if box_screen == null:
		return
	var panel: PanelContainer = box_screen.get_node_or_null("PanelContainer")
	if panel != null:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#0b1118")
		panel_style.border_width_left = 1
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.border_color = Color("#31d4e2")
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_left = 4
		panel_style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", panel_style)

	if box_content_label != null:
		box_content_label.add_theme_color_override("font_color", Color("#cbe9ef"))

	for button in [external_tab_button, internal_tab_button, bipob_alpha_button, bipob_beta_button, box_back_button]:
		if button == null:
			continue
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#162635")
		normal.border_color = Color("#2abfd0")
		normal.set_border_width_all(1)
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color("#2d6030")
		pressed.border_color = Color("#7ce293")
		pressed.set_border_width_all(1)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", pressed)
		button.add_theme_color_override("font_color", Color("#d6f5ff"))


func _create_app_menu_roots() -> void:
	main_menu_root = _build_fullscreen_root("MainMenuRoot")
	center_menu_root = _build_fullscreen_root("CenterMenuRoot")
	tasks_menu_root = _build_fullscreen_root("TasksMenuRoot")
	mission_constructor_root = _build_fullscreen_root("MissionConstructorRoot")
	placeholder_menu_root = _build_fullscreen_root("PlaceholderMenuRoot")
	add_child(main_menu_root)
	add_child(center_menu_root)
	add_child(tasks_menu_root)
	add_child(mission_constructor_root)
	add_child(placeholder_menu_root)
	_build_main_menu_layout()
	_build_center_menu_layout()
	_build_tasks_menu_layout()
	_build_placeholder_layout()

func _build_fullscreen_root(node_name: String) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 100
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return root

func _hide_all_app_screens() -> void:
	if main_menu_root != null:
		main_menu_root.visible = false
	if center_menu_root != null:
		center_menu_root.visible = false
	if tasks_menu_root != null:
		tasks_menu_root.visible = false
	if placeholder_menu_root != null:
		placeholder_menu_root.visible = false
	if mission_constructor_root != null:
		mission_constructor_root.visible = false
	if mission_result_root != null:
		mission_result_root.visible = false
	if charging_menu_root != null:
		charging_menu_root.visible = false
	if programmer_menu_root != null:
		programmer_menu_root.visible = false
	if box_menu_root != null:
		box_menu_root.visible = false
	if box_screen != null:
		box_screen.visible = false
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		runtime_hud_root.visible = false

func _hide_runtime_mission_ui() -> void:
	if mission_label != null:
		mission_label.visible = false
		mission_label.text = ""
	if hud_status_label != null:
		hud_status_label.visible = false
		hud_status_label.text = ""
	if hint_label != null:
		hint_label.visible = false
		hint_label.text = ""
	if command_panel != null:
		command_panel.visible = false
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		runtime_hud_root.visible = false
	if runtime_mission_field_host != null and is_instance_valid(runtime_mission_field_host):
		runtime_mission_field_host.visible = false

func _set_gameplay_visible(visible_state: bool) -> void:
	if not visible_state:
		_hide_runtime_mission_ui()
	if command_panel != null:
		command_panel.visible = false
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		runtime_hud_root.visible = visible_state
	if mission_label != null:
		mission_label.visible = false
	if hud_status_label != null:
		hud_status_label.visible = false
	if hint_label != null:
		hint_label.visible = false
	if hud_diagnostic_label != null:
		hud_diagnostic_label.visible = false
	if _has_gameplay_runtime():
		field_runtime.visible = visible_state
		bipob.visible = visible_state


func _is_small_viewport() -> bool:
	var vp := _get_viewport_size()
	return vp.x < 1100.0 or vp.y < 720.0

func _get_safe_margin() -> float:
	return 16.0 if _is_small_viewport() else 24.0

func _get_runtime_sidebar_width_adaptive() -> float:
	return 280.0 if _is_small_viewport() else _get_runtime_sidebar_width()

func _get_menu_content_max_width() -> float:
	var vp := _get_viewport_size()
	var safe_width: float = maxf(vp.x - _get_safe_margin() * 2.0, 0.0)
	return safe_width

func _get_menu_content_max_height() -> float:
	var vp := _get_viewport_size()
	var safe_height: float = maxf(vp.y - _get_safe_margin() * 2.0, 0.0)
	return safe_height

func get_ui_layout_audit_report() -> String:
	var vp := _get_viewport_size()
	var roots := {"main": main_menu_root, "center": center_menu_root, "tasks": tasks_menu_root, "box": box_menu_root, "charging": charging_menu_root, "repair": repair_menu_root, "programmer": programmer_menu_root, "hud": runtime_hud_root}
	var is_visible_flag := 0
	var lines: Array[String] = ["UI Audit", "screen=%s" % str(app_screen_mode), "small_viewport=%s" % str(_is_small_viewport()), "viewport=%.0fx%.0f" % [vp.x, vp.y]]
	for k in roots.keys():
		var n: Control = roots[k]
		var ex := n != null and is_instance_valid(n)
		var vis := ex and n.visible
		if vis:
			is_visible_flag += 1
		lines.append("%s: exists=%s visible=%s" % [k, str(ex), str(vis)])
	lines.insert(2, "visible_major=%d" % is_visible_flag)
	var wap_exists := runtime_world_actions_panel != null and is_instance_valid(runtime_world_actions_panel)
	var wap_visible := wap_exists and runtime_world_actions_panel.visible
	lines.append("world_actions: exists=%s visible=%s cache_keys={target:%s actions:%s state:%s selected:%s}" % [str(wap_exists), str(wap_visible), str(not last_world_action_target_id.is_empty()), str(not last_world_action_actions_key.is_empty()), str(not last_world_action_state_key.is_empty()), str(not last_world_action_selected.is_empty())])
	lines.append("menu_content_max=%.0fx%.0f" % [_get_menu_content_max_width(), _get_menu_content_max_height()])
	if mission_result_root == null or not is_instance_valid(mission_result_root):
		lines.append("warning: missing mission_result_root")
	return "\n".join(lines)

func print_ui_layout_audit_if_debug() -> void:
	if debug_world_logs or debug_ui_layout_logs:
		print(get_ui_layout_audit_report())

func get_full_menu_ui_smoke_check_text() -> String:
	return "\n".join([
		"UI Smoke Checklist:",
		"- Main Menu",
		"- Center Menu",
		"- Task Menu",
		"  - Small viewport requirement rows are stacked and wrapped",
		"  - Warnings remain visible",
		"  - Back visible",
		"  - Start reachable",
		"- Box External",
		"- Box Internal",
		"- Charging",
		"  - Charging Station / Supercharger / Back visible",
		"  - Rows scroll vertically",
		"  - Disabled charge buttons are gray",
		"  - No overlap on small viewport",
		"- Repair",
		"  - Service Center / Back visible",
		"  - Empty state shown once",
		"  - Damaged rows scroll",
		"  - Repair buttons reachable",
		"- Programmer",
		"  - Back visible",
		"  - File and bipob rows scroll",
		"  - Completed rows move to the bottom",
		"- Gameplay HUD",
		"- World Action Panel",
		"- Mission Result",
		"- Small viewport checks"
	])

func navigate_to_screen(target_screen: AppScreenMode, payload: Dictionary = {}) -> void:
	match target_screen:
		AppScreenMode.MAIN_MENU:
			show_main_menu_screen()
		AppScreenMode.CENTER:
			show_center_screen()
		AppScreenMode.TASKS:
			show_tasks_screen()
		AppScreenMode.BOX_CONSTRUCTOR:
			show_box_constructor_from_center()
		AppScreenMode.MISSION_CONSTRUCTOR:
			show_mission_constructor_screen()
		AppScreenMode.CHARGING_MENU:
			show_charging_menu()
		AppScreenMode.REPAIR_PLACEHOLDER:
			show_repair_menu()
		AppScreenMode.PROGRAMMER_MENU:
			show_programmer_menu()
		AppScreenMode.GAMEPLAY:
			start_gameplay_from_center()
		AppScreenMode.MISSION_RESULT:
			show_mission_result_screen(bool(payload.get("success", false)), int(payload.get("mission_index", -1)))
		AppScreenMode.RESEARCH_PLACEHOLDER:
			show_placeholder_screen("Research")
		AppScreenMode.SHOP_PLACEHOLDER:
			show_placeholder_screen("Shop")
		AppScreenMode.SETTINGS_PLACEHOLDER:
			show_placeholder_screen("Settings")
		AppScreenMode.ABOUT_PLACEHOLDER:
			show_placeholder_screen("About")
		_:
			show_center_screen()

func _assert_single_active_major_screen() -> void:
	var root_map: Dictionary = {
		"MainMenu": main_menu_root,
		"CenterMenu": center_menu_root,
		"TasksMenu": tasks_menu_root,
		"MissionConstructor": mission_constructor_root,
		"PlaceholderMenu": placeholder_menu_root,
		"MissionResult": mission_result_root,
		"ChargingMenu": charging_menu_root,
		"RepairMenu": repair_menu_root,
		"ProgrammerMenu": programmer_menu_root,
		"BoxMenu": box_menu_root,
		"LegacyBoxScreen": box_screen,
		"RuntimeHUD": runtime_hud_root
	}
	var visible_roots: Array[String] = []
	for root_name in root_map.keys():
		var root: Control = root_map[root_name]
		if root != null and is_instance_valid(root) and root.visible:
			visible_roots.append(root_name)
	if visible_roots.size() > 1:
		push_warning("More than one major screen visible: %s" % ", ".join(visible_roots))

func show_main_menu_screen() -> void:
	_deactivate_map_constructor_mode()
	app_screen_mode = AppScreenMode.MAIN_MENU
	box_opened_from_center = false
	_hide_runtime_mission_ui()
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	_destroy_gameplay_runtime()
	if main_menu_root != null:
		main_menu_root.visible = true
	_assert_single_active_major_screen()

func show_center_screen() -> void:
	_deactivate_map_constructor_mode()
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.CENTER
	_hide_runtime_mission_ui()
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	if center_menu_root != null:
		center_menu_root.visible = true
	_assert_single_active_major_screen()

func show_tasks_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.TASKS
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	_refresh_tasks_content()
	if tasks_menu_root != null:
		tasks_menu_root.visible = true
	_assert_single_active_major_screen()

func show_placeholder_screen(title_text: String, body_text: String = "This section will be added later.") -> void:
	previous_app_screen_mode = app_screen_mode
	placeholder_return_screen_mode = previous_app_screen_mode
	app_screen_mode = AppScreenMode.SETTINGS_PLACEHOLDER
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	if placeholder_title_label != null:
		placeholder_title_label.text = title_text
	if placeholder_body_label != null:
		placeholder_body_label.text = body_text
	if placeholder_menu_root != null:
		placeholder_menu_root.visible = true
	_assert_single_active_major_screen()

func start_gameplay_from_center() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.GAMEPLAY
	box_opened_from_center = false
	_hide_all_app_screens()
	_set_active_mission_bipob(0)
	_apply_runtime_hud_layout()
	_set_gameplay_visible(true)
	_on_start_mission_button_pressed()
	call_deferred("_attach_runtime_gameplay_view")
	_assert_single_active_major_screen()

func _enter_gameplay_screen_without_starting_mission() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.GAMEPLAY
	box_opened_from_center = false
	_hide_all_app_screens()
	_set_active_mission_bipob(0)
	_apply_runtime_hud_layout()
	_set_gameplay_visible(true)
	call_deferred("_attach_runtime_gameplay_view")
	_assert_single_active_major_screen()
	update_status()
	update_diagnostic_status()
	update_box_status()


func _build_tasks_mission_data() -> void:
	tasks_mission_data.clear()
	var total_missions: int = 9
	for i in range(total_missions):
		var mission_id: int = i + 1
		var mission_title_short := "Mission %d" % mission_id
		var mission_title_full := "Mission %d" % mission_id
		var short_description := "Reach extraction."
		var main_goal := "Find the way to reach extraction."
		var extra_goals: Array[String] = ["Find the key.", "Open the door."]
		tasks_mission_data.append({
			"id": mission_id,
			"title_short": mission_title_short,
			"title_full": mission_title_full,
			"category": "career",
			"short_description": short_description,
			"main_goal": main_goal,
			"extra_goals": extra_goals,
			"reward": "TBD",
			"difficulty": "TBD",
			"required_bipob_type": "Scout",
			"required_bipob_count": 1,
			"required_movement_type": "basic movement",
			"required_sensor_type": "basic sensor",
			"required_battery": 50,
			"required_pocket": 1,
			"warnings_default": ["Battery may be insufficient.", "Sensor module recommended."]
		})
	if tasks_selected_career_index >= tasks_mission_data.size():
		tasks_selected_career_index = maxi(tasks_mission_data.size() - 1, 0)
	tasks_selected_mission_id = tasks_selected_career_index + 1

func _get_mission_progress(mission_id: int) -> Dictionary:
	if not mission_progress.has(mission_id):
		var new_progress: Dictionary = {
			"completed": false,
			"claimed": false,
			"stars": 0,
			"turns_used": 0,
			"turn_limit": 0,
			"main_goal_completed": false,
			"extra_goals": {},
			"reward_claimed_text": ""
		}
		mission_progress[mission_id] = new_progress
	return Dictionary(mission_progress.get(mission_id, {}))

func _is_mission_claimed(mission_id: int) -> bool:
	return bool(_get_mission_progress(mission_id).get("claimed", false))

func _is_mission_completed_unclaimed(mission_id: int) -> bool:
	var progress: Dictionary = _get_mission_progress(mission_id)
	return bool(progress.get("completed", false)) and not bool(progress.get("claimed", false))

func _get_mission_display_title(mission_data: Dictionary) -> String:
	var mission_id: int = int(mission_data.get("id", 0))
	var base_title: String = "Mission %d" % mission_id
	var progress: Dictionary = _get_mission_progress(mission_id)
	var stars: int = int(progress.get("stars", 0))
	if bool(progress.get("claimed", false)):
		return "%s — Claimed%s" % [base_title, " %s" % ("★".repeat(stars)) if stars > 0 else ""]
	if bool(progress.get("completed", false)):
		return "%s — Completed%s" % [base_title, " %s" % ("★".repeat(stars)) if stars > 0 else ""]
	return base_title

func start_selected_task_mission() -> void:
	var mission: Dictionary = get_selected_task_mission()
	var selected_bipobs: Array[Dictionary] = get_selected_bipobs_for_mission()
	var validation: Dictionary = validate_mission_requirements(mission, selected_bipobs)
	if not bool(validation.get("valid", false)):
		show_hint("Mission config invalid. Check warnings.")
		_refresh_tasks_content()
		return
	if bipob != null:
		bipob.current_mission_index = int(mission.get("id", tasks_selected_career_index + 1))
	start_gameplay_from_center()

func show_box_constructor_from_center() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.BOX_CONSTRUCTOR
	box_opened_from_center = true
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	show_box_screen()
	set_box_menu_mode_external()
	_assert_single_active_major_screen()

func show_mission_constructor_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Mission constructor unavailable: gameplay runtime failed to load.")
		show_main_menu_screen()
		return
	app_screen_mode = AppScreenMode.MISSION_CONSTRUCTOR
	box_opened_from_center = false
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	if mission_constructor_root == null or not is_instance_valid(mission_constructor_root):
		mission_constructor_root = _build_fullscreen_root("MissionConstructorRoot")
		add_child(mission_constructor_root)
	_build_mission_constructor_screen()
	if mission_constructor_root != null:
		mission_constructor_root.visible = true
	_assert_single_active_major_screen()

func _ensure_mission_result_root() -> Control:
	if mission_result_root != null:
		return mission_result_root
	mission_result_root = _build_fullscreen_root("MissionResultRoot")
	add_child(mission_result_root)
	return mission_result_root

func _clear_children(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		child.queue_free()

func show_mission_result_screen(success: bool, mission_index: int = -1) -> void:
	_deactivate_map_constructor_mode()
	app_screen_mode = AppScreenMode.MISSION_RESULT
	_hide_runtime_mission_ui()
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	last_mission_success = success
	var root: Control = _ensure_mission_result_root()
	root.visible = true
	_clear_children(root)
	var result_data: Dictionary = _build_mission_result_data(success, mission_index)
	if success:
		var result_mission_id: int = int(result_data.get("mission_id", mission_index if mission_index > 0 else 1))
		var progress: Dictionary = _get_mission_progress(result_mission_id)
		progress["completed"] = true
		progress["claimed"] = bool(progress.get("claimed", false))
		progress["stars"] = int(result_data.get("stars", progress.get("stars", 0)))
		progress["turns_used"] = int(result_data.get("turns_used", 0))
		progress["turn_limit"] = int(result_data.get("turn_limit", 0))
		progress["main_goal_completed"] = true
		progress["extra_goals"] = {
			"find_key": "TBD",
			"open_door": "TBD"
		}
		if String(progress.get("reward_claimed_text", "")).is_empty():
			progress["reward_claimed_text"] = "TBD"
		mission_progress[result_mission_id] = progress
	var layout: Control = _create_mission_result_layout(result_data)
	root.add_child(layout)
	_assert_single_active_major_screen()

func _refresh_tasks_content() -> void:
	if tasks_mission_data.is_empty():
		_build_tasks_mission_data()
	for tab_name in tasks_tab_buttons.keys():
		var button: Button = tasks_tab_buttons[tab_name]
		var selected : bool = tab_name == tasks_current_tab
		button.modulate = UI_COLOR_SELECTED if selected else Color(1, 1, 1, 1)
	if tasks_list_container == null:
		return
	for child in tasks_list_container.get_children():
		child.queue_free()
	if tasks_current_tab == "Dev":
		_build_tasks_dev_content()
		return
	_reset_tasks_actions_row_for_standard_tabs()
	if tasks_current_tab != "Career":
		var placeholder: Label = Label.new()
		placeholder.text = "No tasks in this category yet."
		_apply_label_style(placeholder)
		tasks_list_container.add_child(placeholder)
		_apply_tasks_placeholder_details()
		return
	var sorted_missions: Array = _sort_missions_for_task_list(tasks_mission_data)
	for mission_variant in sorted_missions:
		var mission: Dictionary = Dictionary(mission_variant)
		var i: int = int(mission.get("source_index", 0))
		var mission_id: int = int(mission.get("id", i + 1))
		var progress: Dictionary = _get_mission_progress(mission_id)
		var card: Button = Button.new()
		var suffix: String = ""
		if bool(progress.get("claimed", false)):
			suffix = " — Claimed"
		elif bool(progress.get("completed", false)):
			suffix = " — Completed"
		card.text = "%s%s\n%s\nReward preview: TBD" % [str(mission.get("title_short", "Mission %d" % mission_id)), suffix, mission.get("main_goal", "Find the way to reach extraction.")]
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size = Vector2(0, 86)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_menu_button_theme(card)
		card.pressed.connect(_on_tasks_career_selected.bind(i))
		if bool(progress.get("claimed", false)):
			card.modulate = Color(0.62, 0.62, 0.62, 1.0)
		elif bool(progress.get("completed", false)):
			card.modulate = Color(0.62, 1.0, 0.72, 1.0) if i != tasks_selected_career_index else UI_COLOR_SELECTED
		else:
			card.modulate = UI_COLOR_SELECTED if i == tasks_selected_career_index else Color(1, 1, 1, 1)
		tasks_list_container.add_child(card)
	_refresh_tasks_bipob_buttons()
	_update_tasks_details_panel()
	if tasks_dev_output_label != null:
		tasks_dev_output_label.visible = false
	if tasks_dev_output_scroll != null:
		tasks_dev_output_scroll.visible = false

func _reset_tasks_actions_row_for_standard_tabs() -> void:
	if tasks_actions_row == null:
		return
	for child in tasks_actions_row.get_children():
		if child == tasks_start_button or child == tasks_claim_button:
			continue
		child.queue_free()
	if tasks_start_button != null:
		tasks_start_button.visible = true
	if tasks_dev_output_label != null:
		tasks_dev_output_label.visible = false
	if tasks_dev_output_scroll != null:
		tasks_dev_output_scroll.visible = false
func _refresh_tasks_bipob_buttons() -> void:
	if tasks_bipob_buttons_row == null:
		return
	for child in tasks_bipob_buttons_row.get_children():
		child.queue_free()
	for entry in tasks_available_bipobs:
		var bipob_id: String = String(entry.get("id", ""))
		if bipob == null:
			return
		var current_armor: int = 0
		var max_armor: int = 0
		if bipob != null and bipob.has_method("get_bipob_current_armor"):
			current_armor = int(bipob.get_bipob_current_armor(bipob_id))
		if bipob != null and bipob.has_method("get_bipob_max_armor"):
			max_armor = int(bipob.get_bipob_max_armor(bipob_id))
		var button: Button = _create_menu_button("%s\n%d / %d" % [String(entry.get("name", bipob_id)), current_armor, max_armor], Callable(self, "_on_tasks_bipob_selected").bind(bipob_id), MENU_BACK_BUTTON_SIZE)
		button.modulate = UI_COLOR_SELECTED if tasks_selected_ids.has(bipob_id) else Color(1, 1, 1, 1)
		tasks_bipob_buttons_row.add_child(button)

func _on_tasks_bipob_selected(bipob_id: String) -> void:
	if tasks_selected_ids.has(bipob_id):
		tasks_selected_ids.erase(bipob_id)
	else:
		tasks_selected_ids.append(bipob_id)
	_refresh_tasks_content()

func _apply_menu_button_theme(button: Button) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", UI_COLOR_TEXT)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = UI_COLOR_PANEL
	normal.border_color = UI_COLOR_BORDER_DIM
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)

	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = UI_COLOR_PANEL_DARK
	hover.border_color = UI_COLOR_BORDER
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)

	var pressed: StyleBoxFlat = StyleBoxFlat.new()
	pressed.bg_color = Color(0.08, 0.20, 0.14, 1.0)
	pressed.border_color = UI_COLOR_OK
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	
func _apply_tasks_placeholder_details() -> void:
	if tasks_title_label != null:
		tasks_title_label.text = "%s Tasks" % tasks_current_tab
	if tasks_difficulty_label != null:
		tasks_difficulty_label.text = "Difficulty: TBD"
	if tasks_reward_label != null:
		tasks_reward_label.text = "Reward: TBD"
	if tasks_main_goal_label != null:
		tasks_main_goal_label.text = "This category is not available yet."
	if tasks_extra_goal_label != null:
		tasks_extra_goal_label.text = "—"
	for i in range(tasks_requirements_required_labels.size()):
		var required_text: String = "TBD" if i == 0 else ""
		tasks_requirements_required_labels[i].text = "Required: %s" % required_text if _is_small_viewport() and not required_text.is_empty() else required_text
	for i in range(tasks_requirements_current_labels.size()):
		var current_text: String = "TBD" if i == 0 else ""
		tasks_requirements_current_labels[i].text = "[color=#9ed6df]Current:[/color] %s" % current_text if _is_small_viewport() and not current_text.is_empty() else current_text
	if tasks_warnings_label != null:
		tasks_warnings_label.text = "No warnings."

func _update_tasks_details_panel() -> void:
	if tasks_current_tab == "Dev":
		return
	if tasks_current_tab != "Career":
		return
	if tasks_mission_data.is_empty():
		return
	tasks_selected_career_index = clampi(tasks_selected_career_index, 0, tasks_mission_data.size() - 1)
	tasks_selected_mission_id = tasks_selected_career_index + 1
	var task: Dictionary = Dictionary(tasks_mission_data[tasks_selected_career_index])
	var selected_bipobs: Array[Dictionary] = get_selected_bipobs_for_mission()
	var validation: Dictionary = validate_mission_requirements(task, selected_bipobs)
	var mission_id: int = int(task.get("id", tasks_selected_mission_id))
	var progress: Dictionary = _get_mission_progress(mission_id)
	var critical_warnings: Array = _get_mission_critical_warnings(task, selected_bipobs)
	var recommendations: Array = _get_mission_recommendations(task, selected_bipobs)
	if tasks_title_label != null:
		tasks_title_label.text = _get_mission_display_title(task)
	if tasks_difficulty_label != null:
		tasks_difficulty_label.text = "Difficulty: %s" % str(task.get("difficulty", "TBD"))
	if tasks_reward_label != null:
		tasks_reward_label.text = "Reward: %s" % str(task.get("reward", "TBD"))
	if tasks_main_goal_label != null:
		tasks_main_goal_label.text = str(task.get("main_goal", "Find the way to reach extraction."))
	if tasks_extra_goal_label != null:
		tasks_extra_goal_label.text = "- %s" % "\n- ".join(task.get("extra_goals", []))
	var requirements_ui: Dictionary = build_requirements_text(task, selected_bipobs, validation)
	var required_rows: Array = Array(requirements_ui.get("required_rows", []))
	var current_rows: Array = Array(requirements_ui.get("current_rows", []))
	for i in range(tasks_requirements_required_labels.size()):
		var required_text: String = String(required_rows[i]) if i < required_rows.size() else ""
		tasks_requirements_required_labels[i].text = "Required: %s" % required_text if _is_small_viewport() and not required_text.is_empty() else required_text
	for i in range(tasks_requirements_current_labels.size()):
		var current_text: String = String(current_rows[i]) if i < current_rows.size() else ""
		tasks_requirements_current_labels[i].text = "[color=#9ed6df]Current:[/color] %s" % current_text if _is_small_viewport() and not current_text.is_empty() else current_text
	if tasks_warnings_label != null:
		tasks_warnings_label.text = _build_warnings_block_text(critical_warnings, recommendations)
	if tasks_report_label != null:
		tasks_report_label.text = _build_mission_report_text(task, progress)
	if tasks_start_button != null:
		tasks_start_button.disabled = not bool(validation.get("valid", false))
		tasks_start_button.visible = not bool(progress.get("completed", false))
	if tasks_claim_button != null:
		tasks_claim_button.visible = _is_mission_completed_unclaimed(mission_id)
	if tasks_start_button != null and _is_mission_completed_unclaimed(mission_id):
		tasks_start_button.text = "Restart"
		tasks_start_button.disabled = false
	elif tasks_start_button != null:
		tasks_start_button.text = "Start"
	if tasks_validation_label != null:
		tasks_validation_label.text = ""


func get_selected_task_mission() -> Dictionary:
	if tasks_mission_data.is_empty():
		_build_tasks_mission_data()
	if tasks_mission_data.is_empty():
		return {}
	tasks_selected_career_index = clampi(tasks_selected_career_index, 0, tasks_mission_data.size() - 1)
	return Dictionary(tasks_mission_data[tasks_selected_career_index])

func get_selected_bipobs_for_mission() -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for bipob_id in tasks_selected_ids:
		for entry in tasks_available_bipobs:
			if String(entry.get("id", "")) == bipob_id:
				selected.append(entry)
	return selected

func get_bipob_movement_modules() -> Array[String]:
	var names: Array[String] = []
	if bipob == null:
		return names
	for module in bipob.get_unique_external_modules():
		if module != null and String(module.movement_type) != "":
			names.append(bipob.get_module_display_name(module))
	return names

func get_bipob_sensor_modules() -> Array[String]:
	var names: Array[String] = []
	if bipob == null:
		return names
	for module in bipob.get_unique_external_modules():
		if module != null and String(module.sensor_direction) != "":
			names.append(bipob.get_module_display_name(module))
	return names

func get_bipob_total_battery_capacity() -> int:
	return 0 if bipob == null else int(bipob.max_energy)

func get_bipob_remaining_battery() -> int:
	return 0 if bipob == null else int(bipob.energy)

func get_bipob_pocket_slots() -> int:
	return 0 if bipob == null else int(bipob.get_available_pocket_slots())

func validate_mission_requirements(mission_data: Dictionary, selected_bipobs: Array[Dictionary]) -> Dictionary:
	var messages: Array[String] = []
	var required_bipobs: int = int(mission_data.get("required_bipob_count", 1))
	var required_bipob_type: String = String(mission_data.get("required_bipob_type", "Scout"))
	var selected_names: Array[String] = []
	for row in selected_bipobs:
		selected_names.append(String(row.get("name", "")))
	if selected_bipobs.size() < required_bipobs:
		messages.append("Selected bipob does not match mission requirement.")
	if selected_names.count(required_bipob_type) < required_bipobs:
		messages.append("Selected bipob does not match mission requirement.")
	if get_bipob_movement_modules().is_empty():
		messages.append("Missing required movement module.")
	if get_bipob_sensor_modules().is_empty():
		messages.append("Missing required sensor module.")
	if get_bipob_remaining_battery() < int(mission_data.get("required_battery", 50)):
		messages.append("Low battery charge for mission.")
	if get_bipob_pocket_slots() < int(mission_data.get("required_pocket", 1)):
		messages.append("Pocket capacity is insufficient.")
	return {"valid": messages.is_empty(), "messages": messages}

func _get_mission_critical_warnings(mission_data: Dictionary, selected_bipobs: Array[Dictionary]) -> Array:
	var validation: Dictionary = validate_mission_requirements(mission_data, selected_bipobs)
	var messages_variant: Variant = validation.get("messages", [])
	if typeof(messages_variant) != TYPE_ARRAY:
		return []
	return Array(messages_variant)

func _get_mission_recommendations(_mission_data: Dictionary, _selected_bipobs: Array[Dictionary]) -> Array:
	var recommendations: Array = []
	if get_bipob_remaining_battery() < get_bipob_total_battery_capacity():
		recommendations.append("Charge the battery before the mission.")
	if _bipob_has_damage():
		recommendations.append("Repair the bipob before the mission.")
	if not _has_installed_beacon_module_for_recovery():
		recommendations.append("Install Beacon Module to recover the bipob if the mission fails.")
	return recommendations

func _bipob_has_damage() -> bool:
	if bipob == null:
		return false
	for entry in tasks_available_bipobs:
		var profile_id: String = String(entry.get("id", ""))
		if bipob.has_method("is_bipob_damaged") and bipob.is_bipob_damaged(profile_id):
			return true
	return false

func _build_warnings_block_text(critical_warnings: Array, recommendations: Array) -> String:
	var lines: Array[String] = []
	if critical_warnings.is_empty() and recommendations.is_empty():
		lines.append("[color=#%s]No warnings.[/color]" % UI_COLOR_TEXT.to_html(false))
		return "\n".join(lines)
	for warning in critical_warnings:
		lines.append("[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), str(warning)])
	for warning in recommendations:
		lines.append("[color=#%s]%s[/color]" % [UI_COLOR_WARNING.to_html(false), str(warning)])
	return "\n".join(lines)

func _build_mission_report_text(task: Dictionary, progress: Dictionary) -> String:
	if not bool(progress.get("completed", false)):
		return ""
	var lines: Array[String] = ["Mission Report"]
	lines.append("Turns: %d / %s" % [int(progress.get("turns_used", 0)), str(progress.get("turn_limit", int(task.get("turn_limit", 0))))])
	lines.append("Main Goal:")
	lines.append("- Reach extraction — %s" % ("completed" if bool(progress.get("main_goal_completed", false)) else "failed"))
	lines.append("Extra Goals:")
	var extra_goals: Dictionary = progress.get("extra_goals", {})
	lines.append("- Find the key — %s" % str(extra_goals.get("find_key", "TBD")))
	lines.append("- Open the door — %s" % str(extra_goals.get("open_door", "TBD")))
	var stars: int = int(progress.get("stars", 0))
	lines.append("Stars: %s" % ("★".repeat(stars) if stars > 0 else "0 / 3"))
	lines.append("Reward: %s" % str(progress.get("reward_claimed_text", "TBD")))
	return "\n".join(lines)

func _sort_missions_for_task_list(missions: Array) -> Array:
	var active: Array[Dictionary] = []
	var completed: Array[Dictionary] = []
	var claimed: Array[Dictionary] = []
	for i in range(missions.size()):
		var mission_source: Dictionary = Dictionary(missions[i])
		var mission: Dictionary = mission_source.duplicate(true)
		mission["source_index"] = i
		var mission_id: int = int(mission.get("id", i + 1))
		if _is_mission_claimed(mission_id):
			claimed.append(mission)
		elif _is_mission_completed_unclaimed(mission_id):
			completed.append(mission)
		else:
			active.append(mission)
	var result: Array[Dictionary] = []
	result.append_array(active)
	result.append_array(completed)
	result.append_array(claimed)
	return result

func _build_validation_summary(validation: Dictionary) -> String:
	if bool(validation.get("valid", false)):
		return "READY: Configuration is valid."
	var messages: Array = Array(validation.get("messages", []))
	var message_lines: Array[String] = []
	for message_variant in messages:
		message_lines.append(String(message_variant))
	return "- %s" % "\n- ".join(message_lines)

func _configure_requirement_cell_label(label: Label, is_required_column: bool) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(TASK_REQUIREMENT_REQUIRED_COL_WIDTH if is_required_column else 0.0, TASK_REQUIREMENT_ROW_HEIGHT)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if is_required_column else Control.SIZE_EXPAND_FILL
	_apply_label_style(label)

func _configure_requirement_cell_rich_label(label: RichTextLabel) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_contents = true
	label.custom_minimum_size = Vector2(0.0, TASK_REQUIREMENT_ROW_HEIGHT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("default_color", UI_COLOR_TEXT)

func build_requirements_text(mission_data: Dictionary, selected_bipobs: Array[Dictionary], validation: Dictionary) -> Dictionary:
	var req_battery: int = int(mission_data.get("required_battery", 50))
	var rem: int = get_bipob_remaining_battery()
	var max_b: int = get_bipob_total_battery_capacity()
	var selected_names: Array[String] = []
	for row in selected_bipobs:
		selected_names.append(String(row.get("name", "")))
	var missing := "— !"
	var movement: Array[String] = get_bipob_movement_modules()
	var sensors: Array[String] = get_bipob_sensor_modules()
	var pocket: int = get_bipob_pocket_slots()
	var req_pocket: int = int(mission_data.get("required_pocket", 1))
	var required_rows: Array[String] = []
	required_rows.append("Bipobs: %d %s" % [int(mission_data.get("required_bipob_count", 1)), String(mission_data.get("required_bipob_type", "Scout"))])
	required_rows.append("Movement: %s" % String(mission_data.get("required_movement_type", "basic movement")))
	required_rows.append("Sensor: %s" % String(mission_data.get("required_sensor_type", "basic sensor")))
	required_rows.append("Battery: %d" % req_battery)
	required_rows.append("Pocket: %d" % req_pocket)
	var current_rows: Array[String] = []
	current_rows.append(", ".join(selected_names) if not selected_names.is_empty() else "[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), missing])
	current_rows.append(", ".join(movement) if not movement.is_empty() else "[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), missing])
	current_rows.append(", ".join(sensors) if not sensors.is_empty() else "[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), missing])
	var battery_text: String = "Max: %d / Remaining: %d" % [max_b, rem]
	if rem < req_battery:
		battery_text = "[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), battery_text]
	current_rows.append(battery_text)
	var pocket_text: String = str(pocket)
	if pocket < req_pocket:
		pocket_text = "[color=#%s]%s[/color]" % [UI_COLOR_DANGER.to_html(false), missing]
	current_rows.append(pocket_text)
	return {"required_rows": required_rows, "current_rows": current_rows, "valid": validation.get("valid", false)}

func charge_bipob_from_center() -> void:
	if bipob == null:
		return
	if bipob.has_method("charge"):
		bipob.charge()
	elif bipob.has_method("restore_energy"):
		bipob.restore_energy()
	else:
		bipob.energy = bipob.max_energy
	show_hint("Bipob charged.")
	update_status()

func _on_charge_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.charge_to_full()
	start_mission_warning_acknowledged = false
	update_status()
	update_box_status()
	update_diagnostic_status()
	call_deferred("_sync_runtime_bipob_visual_state")

func _on_install_module_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	_on_install_selected_box_module_pressed()

func clamp_box_selection_indexes() -> void:
	if bipob == null:
		selected_installed_module_index = 0
		_clear_box_module_selection()
		return

	if bipob.installed_modules.is_empty():
		selected_installed_module_index = 0
	else:
		selected_installed_module_index = clampi(selected_installed_module_index, 0, bipob.installed_modules.size() - 1)

	var filtered_indices: Array[int] = get_current_filtered_box_storage_indices()
	if selected_module_source == "none":
		selected_box_storage_index = -1
		selected_filtered_box_index = 0
		return
	if bipob.box_storage.is_empty():
		selected_box_storage_index = -1
		selected_filtered_box_index = 0
	elif selected_module_source == "storage":
		if selected_box_storage_index < 0 or selected_box_storage_index >= bipob.box_storage.size():
			_clear_box_module_selection()
			return
		if filtered_indices.is_empty() or not (selected_box_storage_index in filtered_indices):
			_clear_box_module_selection()
			return
		selected_filtered_box_index = filtered_indices.find(selected_box_storage_index)
	else:
		selected_filtered_box_index = 0

func _on_prev_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index -= 1
	if selected_installed_module_index < 0:
		selected_installed_module_index = bipob.installed_modules.size() - 1
	update_box_status()

func _on_next_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index += 1
	if selected_installed_module_index >= bipob.installed_modules.size():
		selected_installed_module_index = 0
	update_box_status()

func _on_remove_selected_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules to remove.")
		return
	clamp_box_selection_indexes()
	bipob.remove_installed_module_to_box_by_index(selected_installed_module_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_prev_box_pressed() -> void:
	if bipob == null:
		return
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	if grouped_ids.is_empty():
		show_hint("No module matches current filter.")
		return
	selected_grouped_module_index = grouped_ids.size() - 1 if selected_grouped_module_index < 0 else posmod(selected_grouped_module_index - 1, grouped_ids.size())
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_box_selection_indexes()
	update_box_status()

func _on_next_box_pressed() -> void:
	if bipob == null:
		return
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	if grouped_ids.is_empty():
		show_hint("No module matches current filter.")
		return
	selected_grouped_module_index = 0 if selected_grouped_module_index < 0 else posmod(selected_grouped_module_index + 1, grouped_ids.size())
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_box_selection_indexes()
	update_box_status()

func _on_install_selected_box_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("No module in Box Storage to install.")
		return
	sync_selected_box_storage_index_from_filter()
	clamp_box_selection_indexes()
	bipob.install_module_from_box_storage(selected_box_storage_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_remove_module_button_pressed() -> void:
	_on_remove_selected_module_pressed()

func get_selected_external_side_id() -> String:
	if bipob == null:
		return ""
	if selected_external_side_index < 0:
		selected_external_side_index = 0
	if selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0
	return String(bipob.EXTERNAL_SIDE_ORDER[selected_external_side_index])

func clamp_external_selection() -> void:
	if bipob == null:
		return

	if selected_external_side_index < 0:
		selected_external_side_index = bipob.EXTERNAL_SIDE_ORDER.size() - 1
	elif selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0

	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	selected_external_slot_position.x = clampi(selected_external_slot_position.x, 0, side_size.x - 1)
	selected_external_slot_position.y = clampi(selected_external_slot_position.y, 0, side_size.y - 1)
	bipob.selected_external_side = get_selected_external_side_id()
	bipob.selected_external_origin = selected_external_slot_position

func _set_external_selection_from_side_and_cell(side_id: String, cell: Vector2i) -> void:
	if bipob == null:
		return
	var side_index: int = bipob.EXTERNAL_SIDE_ORDER.find(side_id)
	if side_index >= 0:
		selected_external_side_index = side_index
	selected_external_slot_position = cell
	bipob.selected_external_side = side_id
	bipob.selected_external_origin = cell

func _build_box_menu_layout() -> void:
	if box_menu_root != null and is_instance_valid(box_menu_root):
		box_menu_root.queue_free()
	box_menu_root = _build_fullscreen_root("BoxMenuRoot")
	add_child(box_menu_root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	box_menu_root.add_child(margin)
	var panel := PanelContainer.new()
	_apply_panel_style(panel, true)
	margin.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	box_top_bar_root = HBoxContainer.new()
	box_top_bar_root.name = "TopRow"
	(box_top_bar_root as HBoxContainer).add_theme_constant_override("separation", 8)
	vbox.add_child(box_top_bar_root)

	box_constructor_content_root = VBoxContainer.new()
	box_constructor_content_root.name = "MainConstructorContent"
	box_constructor_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_constructor_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box_constructor_content_root.add_theme_constant_override("separation", 8)
	vbox.add_child(box_constructor_content_root)

	box_content_scroll = null

	box_content_label = Label.new()
	box_content_label.name = "BoxContentLabel"
	box_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_content_label.visible = false
	box_constructor_content_root.add_child(box_content_label)

	right_button_panel = VBoxContainer.new()
	right_button_panel.name = "BottomActionRow"
	right_button_panel.add_theme_constant_override("separation", 8)
	right_button_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(right_button_panel)
	if box_screen != null:
		box_screen.visible = false
	_setup_box_top_bar()



func _on_viewport_size_changed() -> void:
	if box_menu_root != null and box_menu_root.visible:
		if box_menu_mode == BoxMenuMode.EXTERNAL or box_menu_mode == BoxMenuMode.INTERNAL:
			update_box_status()
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root) and runtime_hud_root.visible:
		_apply_runtime_hud_layout()
		call_deferred("_attach_runtime_gameplay_view")
func _apply_box_screen_fullscreen_layout() -> void:
	if box_menu_root != null and is_instance_valid(box_menu_root):
		return
	if box_screen == null:
		return
	box_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	box_screen.offset_left = 0
	box_screen.offset_top = 0
	box_screen.offset_right = 0
	box_screen.offset_bottom = 0
	box_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box_panel: Control = box_screen.get_node_or_null("PanelContainer")
	if box_panel != null:
		box_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		box_panel.offset_left = 4
		box_panel.offset_top = 4
		box_panel.offset_right = -4
		box_panel.offset_bottom = -4
		box_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var box_vbox: VBoxContainer = box_panel.get_node_or_null("VBoxContainer")
		if box_vbox != null:
			box_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _ensure_action_panel_scrollable() -> void:
	if right_button_panel == null:
		return
	right_button_panel.custom_minimum_size = Vector2(230, 0)
	right_button_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func get_external_module_marker(module: BipobModule) -> String:
	if module == null:
		return "M"
	match module.id:
		"wheels_v1":
			return "W"
		"legs_v1":
			return "L"
		"tracks_v1":
			return "T"
		"visor_v1", "visor_v2", "visor_v3":
			return "V"
		"manipulator_v1":
			return "M"
		"interface_v1":
			return "I"
		_:
			var module_name: String = bipob.get_module_display_name(module).to_upper()
			if module_name.is_empty():
				return "M"
			return module_name.substr(0, 1)

func get_yes_no(value: bool) -> String:
	return "yes" if value else "no"

func get_selected_box_module_allowed_sides_text() -> String:
	if bipob == null or bipob.box_storage.is_empty():
		return "Allowed sides: n/a"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	if module == null:
		return "Allowed sides: n/a"
	return "Allowed sides: %s" % bipob.get_allowed_external_sides_text(module)

func get_external_side_orientation_text(side_id: String) -> String:
	var lines: Array[String] = []
	match side_id:
		bipob.EXTERNAL_SIDE_TOP:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BOTTOM:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
			lines.append("Note: viewed from outside bottom.")
		bipob.EXTERNAL_SIDE_FRONT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BACK:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / RIGHT ← / LEFT →")
			lines.append("Note: viewed from outside back.")
		bipob.EXTERNAL_SIDE_LEFT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / FRONT ← / BACK →")
		bipob.EXTERNAL_SIDE_RIGHT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / BACK ← / FRONT →")
		_:
			lines.append("Orientation: n/a")
	return "\n".join(lines)

func get_external_side_installed_list_text(side_id: String) -> String:
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var lines: Array[String] = []
	var seen_modules: Array[BipobModule] = []
	for y in range(side_size.y):
		for x in range(side_size.x):
			var module: BipobModule = bipob.get_external_module_at(side_id, Vector2i(x, y))
			if module == null or seen_modules.has(module):
				continue
			seen_modules.append(module)
			var origin := Vector2i(side_size.x, side_size.y)
			for yy in range(side_size.y):
				for xx in range(side_size.x):
					if bipob.get_external_module_at(side_id, Vector2i(xx, yy)) == module:
						origin.x = mini(origin.x, xx)
						origin.y = mini(origin.y, yy)
			var module_size: Vector2i = bipob.get_external_module_size(module)
			lines.append("- x%d,y%d: %s (%dx%d)" % [origin.x, origin.y, bipob.get_module_display_name(module), module_size.x, module_size.y])
	if lines.is_empty():
		return "none"
	return "\n".join(lines)

func _on_start_mission_button_pressed() -> void:
	if bipob == null:
		return

	# BoxScreen preparation action: starts mission flow without field action/energy spend.
	if bipob.sector_completed and should_advance_mission_on_start:
		bipob.start_next_mission()
		start_mission_warning_acknowledged = false
		update_status()
		update_box_status()
		update_diagnostic_status()
		return

	var warnings: Array[String] = bipob.get_pre_mission_warnings()
	if not bipob.can_start_mission_from_box():
		show_hint("Cannot start mission. Battery depleted. Charge first.")
		start_mission_warning_acknowledged = false
		update_box_status()
		return

	if not warnings.is_empty() and not start_mission_warning_acknowledged:
		start_mission_warning_acknowledged = true
		show_hint("Warnings before mission. Press Start Mission again to continue anyway.")
		update_box_status()
		return

	if should_advance_mission_on_start:
		bipob.start_next_mission()
	else:
		bipob.start_mission(bipob.current_mission_index)
	should_advance_mission_on_start = false
	start_mission_warning_acknowledged = false
	if not bipob.sector_completed:
		hide_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_mission_completed() -> void:
	should_advance_mission_on_start = true
	_refresh_runtime_mission_objective_label()
	show_mission_result_screen(true)

func _on_mission_failed() -> void:
	should_advance_mission_on_start = false
	_refresh_runtime_mission_objective_label()
	show_mission_result_screen(false)

func _on_returned_to_box() -> void:
	should_advance_mission_on_start = false
	box_opened_from_center = false
	show_box_screen()
	update_box_status()

func show_box_screen() -> void:
	if box_menu_root == null or not is_instance_valid(box_menu_root):
		_build_box_menu_layout()
	if box_menu_root != null:
		box_menu_root.visible = true
	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = false
	start_mission_warning_acknowledged = false
	update_box_status()
	
func hide_box_screen() -> void:
	if box_menu_root != null:
		box_menu_root.visible = false
	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	update_status()
	update_box_status()
	update_diagnostic_status()
	
func update_box_status() -> void:
	if bipob == null:
		return
	_ensure_action_panel_scrollable()
	_clear_box_module_selection_if_invalid_for_current_context()

	clamp_box_selection_indexes()
	update_diagnostic_status()

	if box_title_label != null:
		box_title_label.text = ""

	var content_text: String = ""

	update_box_button_visibility()
	_setup_box_top_bar()
	if box_menu_mode == BoxMenuMode.EXTERNAL or box_menu_mode == BoxMenuMode.INTERNAL:
		if box_content_label != null:
			box_content_label.text = ""
			box_content_label.visible = false
		_rebuild_box_constructor_content()
		_rebuild_box_actions_for_current_mode()
		update_box_button_visibility()
		return

	if box_content_label != null:
		box_content_label.visible = true
		box_content_label.text = content_text
	_clear_box_constructor_content()
	_rebuild_box_actions_for_current_mode()

func _clear_box_constructor_content() -> void:
	if box_constructor_content_root == null:
		return
	for child in box_constructor_content_root.get_children():
		child.queue_free()

func _rebuild_box_constructor_content() -> void:
	_clear_box_constructor_content()
	if box_constructor_content_root == null:
		return
	var layout: Control = null
	match box_menu_mode:
		BoxMenuMode.EXTERNAL:
			layout = _create_external_constructor_layout()
		BoxMenuMode.INTERNAL:
			layout = _create_internal_constructor_layout()
		_:
			box_menu_mode = BoxMenuMode.EXTERNAL
			layout = _create_external_constructor_layout()
	if layout != null:
		layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box_constructor_content_root.add_child(layout)

func _clear_box_top_bar() -> void:
	if box_top_bar_root == null:
		return
	for child in box_top_bar_root.get_children():
		child.queue_free()

func _clear_box_actions() -> void:
	if right_button_panel == null:
		return
	for child in right_button_panel.get_children():
		child.queue_free()

func _rebuild_box_actions_for_current_mode() -> void:
	_clear_box_actions()
	rebuild_box_action_buttons()

func get_box_mission_menu_text() -> String:
	if bipob == null:
		return "\n".join([
			"Mission:",
			"Runtime not loaded.",
			"",
			"Press Play to enter the Center before opening mission systems."
		])
	var content_lines: Array[String] = []
	var mission_name := "n/a"
	if bipob.has_method("get_mission_name"):
		mission_name = str(bipob.get_mission_name(bipob.current_mission_index))
	content_lines.append("Mission:")
	content_lines.append("Mission %d — %s" % [bipob.current_mission_index + 1, mission_name])
	content_lines.append("")
	content_lines.append("Energy:")
	content_lines.append("%d / %d" % [bipob.energy, bipob.max_energy])
	content_lines.append("")
	content_lines.append(bipob.get_constructor_readiness_summary_text())
	content_lines.append("")
	content_lines.append(bipob.get_constructor_warning_summary_text())

	var warnings: Array = bipob.get_pre_mission_warnings()
	content_lines.append("")
	if warnings.is_empty():
		content_lines.append("Warnings: none")
	else:
		content_lines.append("Warnings:")
		var warning_limit: int = mini(2, warnings.size())
		for index in range(warning_limit):
			content_lines.append("- %s" % str(warnings[index]))
		if warnings.size() > warning_limit:
			content_lines.append("- ... +%d more" % (warnings.size() - warning_limit))

	var hand_text := "empty"
	if bipob.held_module != null:
		hand_text = bipob.get_module_display_name(bipob.held_module)
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)
	content_lines.append("")
	content_lines.append("Carry:")
	content_lines.append("Hand: %s" % hand_text)
	content_lines.append("Box Storage: %s" % storage_text)
	content_lines.append("Carry: %d / %d" % [bipob.get_carried_physical_count(), bipob.physical_carry_capacity])

	content_lines.append("")
	content_lines.append(get_digital_storage_short_text())
	content_lines.append("")
	if bipob.found_module != null:
		content_lines.append("Found: %s" % bipob.get_module_display_name(bipob.found_module))
	else:
		content_lines.append("Found: none")
	content_lines.append("Box Storage: %d modules" % bipob.box_storage.size())
	content_lines.append("Installed: %d modules" % bipob.installed_modules.size())
	return "\n".join(content_lines)

func get_box_modules_menu_text() -> String:
	sync_selected_box_storage_index_from_grouped_selection()
	var filter_id: String = get_current_constructor_filter()
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	var content_lines: Array[String] = []
	content_lines.append("CONSTRUCTOR DASHBOARD")
	content_lines.append(_get_constructor_dashboard_playable_summary_text())
	content_lines.append("")
	content_lines.append("Components in Box Storage")
	content_lines.append("Filter: %s" % filter_id.capitalize())
	content_lines.append("Available / Installed:")
	if grouped_ids.is_empty():
		content_lines.append("empty")
	else:
		selected_grouped_module_index = clampi(selected_grouped_module_index, 0, grouped_ids.size() - 1)
		for i in range(grouped_ids.size()):
			var availability_line: String = bipob.get_module_availability_line_by_id(grouped_ids[i], i == selected_grouped_module_index)
			var group_module: BipobModule = bipob.get_first_module_by_id(grouped_ids[i])
			var group_label: String = bipob.get_module_visual_short_label(group_module)
			content_lines.append("[%s] %s" % [group_label, availability_line])
	content_lines.append("")
	var selected_module: BipobModule = get_selected_grouped_module()
	content_lines.append("Selected Module:")
	content_lines.append(get_module_details_text(selected_module))
	if CONSTRUCTOR_SHOW_DEBUG_TEXT_IN_MAIN:
		content_lines.append("")
		content_lines.append(bipob.get_constructor_dashboard_text())
	return "\n".join(content_lines)


func _get_constructor_dashboard_playable_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor Overview")
	if bipob.has_method("get_unique_internal_modules"):
		lines.append("Internal Modules: %d" % bipob.get_unique_internal_modules().size())
	if bipob.has_method("get_unique_external_modules"):
		lines.append("External Modules: %d" % bipob.get_unique_external_modules().size())
	var has_internal_overlay_paths: bool = false
	for property_data in bipob.get_property_list():
		if String(property_data.get("name", "")) == "internal_overlay_paths":
			has_internal_overlay_paths = true
			break
	if has_internal_overlay_paths:
		lines.append("Overlay Paths: %d" % bipob.internal_overlay_paths.size())
	lines.append("Box Storage: %d" % bipob.box_storage.size())
	if bipob.has_method("get_constructor_checkpoint_compact_text"):
		lines.append(str(bipob.get_constructor_checkpoint_compact_text()))
	return "\n".join(lines)

func get_box_external_menu_text() -> String:
	clamp_external_selection()
	sync_selected_box_storage_index_from_grouped_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var side_name: String = bipob.get_external_side_display_name(side_id)
	var slot_module: BipobModule = bipob.get_external_module_at(side_id, selected_external_slot_position)
	var content_lines: Array[String] = []
	content_lines.append("CONSTRUCTOR LAYOUT")
	content_lines.append("TOP BAR: External Modules | Internal Modules | Available Bipobs")
	content_lines.append("MAIN ROW: Workspace | Components in Box Storage")
	content_lines.append("BOTTOM INFO BAR: Status | Selected Module")
	content_lines.append("")
	content_lines.append("EXTERNAL MODULES ON BODY")
	content_lines.append("[UP 3x3] above [ROBOT PREVIEW] [DOWN 3x3]")
	content_lines.append("[LEFT SIDE 3x4] [ROBOT PREVIEW] [RIGHT SIDE 3x4]")
	content_lines.append("[FRONT 3x4] lower-left | [BACK 3x4] lower-right")
	content_lines.append("")

	var selected_box_module: BipobModule = get_selected_grouped_module()

	var placement_error := ""
	var preview_footprint: Array[Vector2i] = []
	var preview_safe_area: Array[Vector2i] = []
	if selected_box_module != null:
		preview_footprint = bipob.get_external_module_footprint_cells(selected_box_module, selected_external_slot_position)
		preview_safe_area = bipob.get_external_module_safe_area_cells(selected_box_module, selected_external_slot_position)
		placement_error = bipob.get_external_module_placement_error(selected_box_module, side_id, selected_external_slot_position)

	content_lines.append("Selected side: %s" % side_name)
	content_lines.append("Filter: %s" % get_current_constructor_filter().capitalize())
	content_lines.append(bipob.get_constructor_readiness_compact_text())
	content_lines.append("Side size: %d x %d" % [side_size.x, side_size.y])
	content_lines.append(get_external_side_orientation_text(side_id))
	content_lines.append("")

	var header_cells: Array[String] = ["   "]
	for x in range(side_size.x):
		header_cells.append("x%d" % x)
	content_lines.append("  ".join(header_cells))
	for y in range(side_size.y):
		var row_cells: Array[String] = ["y%d" % y]
		for x in range(side_size.x):
			var slot_pos := Vector2i(x, y)
			var module: BipobModule = bipob.get_external_module_at(side_id, slot_pos)
			var is_selected: bool = slot_pos == selected_external_slot_position
			var has_footprint_preview := selected_box_module != null and preview_footprint.has(slot_pos)
			var has_safe_preview := selected_box_module != null and preview_safe_area.has(slot_pos)
			var cell_text := "[ ]"
			if has_safe_preview:
				cell_text = "[.]" if module == null else "[x]"
			if module != null:
				cell_text = "[%s]" % get_external_module_marker(module)
			if has_footprint_preview:
				cell_text = "[+]" if module == null else "[!]"
			if is_selected and selected_box_module == null:
				cell_text = "[>]" if module == null else "[>%s]" % get_external_module_marker(module)
			row_cells.append(cell_text)
		content_lines.append(" ".join(row_cells))

	content_lines.append("")
	content_lines.append("Selected slot: x=%d, y=%d" % [selected_external_slot_position.x, selected_external_slot_position.y])
	if slot_module == null:
		content_lines.append("Slot status: empty")
	else:
		content_lines.append("Slot status: %s" % bipob.get_module_display_name(slot_module))

	if selected_box_module == null:
		content_lines.append("Selected Box module: none")
		content_lines.append("Module size: n/a")
		content_lines.append("Allowed sides: n/a")
		content_lines.append("Placement: n/a")
	else:
		var module_size: Vector2i = bipob.get_external_module_size(selected_box_module)
		content_lines.append("Selected Box module: %s" % bipob.get_module_display_name(selected_box_module))
		content_lines.append("Module size: %d x %d" % [module_size.x, module_size.y])
		content_lines.append("Allowed sides: %s" % bipob.get_allowed_external_sides_text(selected_box_module))
		if placement_error.is_empty():
			content_lines.append("Placement: valid")
		else:
			content_lines.append("Placement: invalid — %s" % placement_error)
		if selected_box_module.id == "air_intake_v1":
			content_lines.append("Purpose: supplies air to internal air cooling modules.")
			content_lines.append("Allowed sides: Any")
		if selected_box_module.placement_type != "external":
			content_lines.append("Cannot place: module is not external.")
		if bipob.get_box_module_count_by_id(selected_box_module.id) <= 0:
			content_lines.append("No available copy in Box Storage.")

	content_lines.append("")
	content_lines.append(get_module_details_text(selected_box_module))

	content_lines.append("")
	content_lines.append("Air intake requirement:")
	content_lines.append("- internal air cooling: %s" % get_yes_no(bipob.has_air_cooling_requiring_intake()))
	content_lines.append("- air intake installed: %s" % get_yes_no(bipob.has_external_air_intake()))
	if bipob.has_method("get_air_intake_warning_text"):
		var air_intake_warning: String = str(bipob.get_air_intake_warning_text())
		if not air_intake_warning.is_empty():
			content_lines.append(air_intake_warning)
	content_lines.append("")
	content_lines.append(bipob.get_constructor_warning_compact_text())
	var constructor_warnings: Array[String] = bipob.get_constructor_warning_lines()
	var warning_limit: int = mini(2, constructor_warnings.size())
	for index in range(warning_limit):
		content_lines.append("- %s" % constructor_warnings[index])
	content_lines.append("")
	content_lines.append("Installed on %s:" % side_name)
	content_lines.append(get_external_side_installed_list_text(side_id))
	content_lines.append("")
	content_lines.append(bipob.get_external_build_summary_text())

	return "\n".join(content_lines)

func _add_box_action_button(button_text: String, handler: Callable) -> void:
	if right_button_panel == null:
		return
	_add_action_button(right_button_panel, button_text, handler, _get_button_role(button_text), true, false)

func _can_place_selected_internal_visual() -> bool:
	var module: BipobModule = _get_selected_internal_candidate_module()
	if module == null:
		return false
	if _is_module_broken(module):
		return false
	if _is_module_unknown(module):
		return false
	return bipob.can_place_internal_module(module, bipob.selected_internal_origin, bipob.selected_internal_rotation)

func _can_place_selected_external_visual() -> bool:
	var module: BipobModule = _get_selected_external_candidate_module()
	if module == null:
		return false
	if _is_module_broken(module):
		return false
	if _is_module_unknown(module):
		return false
	return bipob.can_place_external_module(module, bipob.selected_external_side, bipob.selected_external_origin)

func _can_commit_overlay_plan_visual() -> bool:
	if bipob.selected_overlay_cells.is_empty():
		return false
	var module_id: String = bipob.get_selected_overlay_module_id()
	if bipob.has_method("get_box_module_count_by_id"):
		return bipob.get_box_module_count_by_id(module_id) > 0
	return true

func _has_selected_overlay_path_visual() -> bool:
	if not bipob.has_method("get_selected_overlay_path_record"):
		return false
	var record: Dictionary = bipob.get_selected_overlay_path_record()
	return not record.is_empty()

func rebuild_box_action_buttons() -> void:
	if right_button_panel == null:
		return
	_clear_box_actions()
	right_button_panel.visible = not (box_menu_mode == BoxMenuMode.EXTERNAL or box_menu_mode == BoxMenuMode.INTERNAL)

	var actions_label: Label = Label.new()
	actions_label.name = "ActionsLabel"
	actions_label.text = "Actions"
	right_button_panel.add_theme_constant_override("separation", ACTION_GROUP_SPACING)

	if box_menu_mode == BoxMenuMode.EXTERNAL or box_menu_mode == BoxMenuMode.INTERNAL:
		_apply_constructor_ui_skin()
		return

	right_button_panel.add_child(actions_label)
	_apply_label_style(actions_label, false, true)

	if box_menu_mode == BoxMenuMode.INTERNAL:
		var internal_remove_available: bool = _can_remove_selected_internal_module()
		var selection_group: VBoxContainer = _create_action_group_panel("Selection")
		right_button_panel.add_child(selection_group)
		var filter_row: HBoxContainer = _create_action_button_row()
		selection_group.add_child(filter_row)
		_add_action_button(filter_row, "Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"), "normal", true, true)
		_add_action_button(filter_row, "Next Filter", Callable(self, "_on_next_constructor_filter_pressed"), "normal", true, true)
		var box_row: HBoxContainer = _create_action_button_row()
		selection_group.add_child(box_row)
		_add_action_button(box_row, "Prev Box", Callable(self, "_on_prev_internal_box_pressed"), "normal", true, true)
		_add_action_button(box_row, "Next Box", Callable(self, "_on_next_internal_box_pressed"), "normal", true, true)
		var position_group: VBoxContainer = _create_action_group_panel("Position")
		right_button_panel.add_child(position_group)
		for row_data in [["X-", "_on_internal_x_minus_pressed", "X+", "_on_internal_x_plus_pressed"], ["Y-", "_on_internal_y_minus_pressed", "Y+", "_on_internal_y_plus_pressed"], ["Z-", "_on_internal_z_minus_pressed", "Z+", "_on_internal_z_plus_pressed"]]:
			var row: HBoxContainer = _create_action_button_row()
			position_group.add_child(row)
			_add_action_button(row, row_data[0], Callable(self, row_data[1]), "normal", true, true)
			_add_action_button(row, row_data[2], Callable(self, row_data[3]), "normal", true, true)
		var module_group: VBoxContainer = _create_action_group_panel("Module")
		right_button_panel.add_child(module_group)
		_add_action_button(module_group, "Rotate", Callable(self, "_on_rotate_internal_pressed"))
		_add_action_button(module_group, "Place", Callable(self, "_on_place_internal_pressed"), "primary", _can_place_selected_internal_visual())
		_add_action_button(module_group, "Remove", Callable(self, "_on_remove_internal_pressed"), "danger", internal_remove_available)
		var view_group: VBoxContainer = _create_action_group_panel("View")
		right_button_panel.add_child(view_group)
		_add_action_button(view_group, "Toggle View", Callable(self, "_on_toggle_internal_view_pressed"))
		var overlay_plan_group: VBoxContainer = _create_action_group_panel("Overlay Plan")
		right_button_panel.add_child(overlay_plan_group)
		_add_action_button(overlay_plan_group, "Overlay Type", Callable(self, "_on_overlay_type_pressed"))
		_add_action_button(overlay_plan_group, "Toggle Cell", Callable(self, "_on_toggle_overlay_cell_pressed"))
		for overlay_row_data in [["+X", "_on_extend_overlay_pos_x_pressed", "-X", "_on_extend_overlay_neg_x_pressed"], ["+Y", "_on_extend_overlay_pos_y_pressed", "-Y", "_on_extend_overlay_neg_y_pressed"], ["+Z", "_on_extend_overlay_pos_z_pressed", "-Z", "_on_extend_overlay_neg_z_pressed"]]:
			var overlay_row: HBoxContainer = _create_action_button_row()
			overlay_plan_group.add_child(overlay_row)
			_add_action_button(overlay_row, overlay_row_data[0], Callable(self, overlay_row_data[1]), "normal", true, true)
			_add_action_button(overlay_row, overlay_row_data[2], Callable(self, overlay_row_data[3]), "normal", true, true)
		_add_action_button(overlay_plan_group, "Undo Cell", Callable(self, "_on_undo_overlay_cell_pressed"))
		_add_action_button(overlay_plan_group, "Clear Plan", Callable(self, "_on_clear_overlay_pressed"), "danger")
		var overlay_paths_group: VBoxContainer = _create_action_group_panel("Overlay Paths")
		right_button_panel.add_child(overlay_paths_group)
		var path_row: HBoxContainer = _create_action_button_row()
		overlay_paths_group.add_child(path_row)
		_add_action_button(path_row, "Prev Path", Callable(self, "_on_prev_overlay_pressed"), "normal", true, true)
		_add_action_button(path_row, "Next Path", Callable(self, "_on_next_overlay_pressed"), "normal", true, true)
		_add_action_button(overlay_paths_group, "Remove Path", Callable(self, "_on_remove_selected_overlay_pressed"), "danger", _has_selected_overlay_path_visual())
		var reference_group: VBoxContainer = _create_action_group_panel("Reference / Preview")
		right_button_panel.add_child(reference_group)
		_add_action_button(reference_group, "Overlay Diff", Callable(self, "_on_overlay_diff_pressed"), "reference")
	else:
		_add_box_action_button("Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"))
		_add_box_action_button("Next Filter", Callable(self, "_on_next_constructor_filter_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Remove", Callable(self, "_on_remove_selected_module_pressed"))
		_add_box_action_button("Prev Inst", Callable(self, "_on_prev_installed_pressed"))
		_add_box_action_button("Next Inst", Callable(self, "_on_next_installed_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Install", Callable(self, "_on_install_selected_box_module_pressed"))
		_add_box_action_button("Prev Box", Callable(self, "_on_prev_box_pressed"))
		_add_box_action_button("Next Box", Callable(self, "_on_next_box_pressed"))
		_add_box_action_button("Consistency", Callable(self, "_on_constructor_consistency_button_pressed"))
		_add_box_action_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"))
		_add_box_action_button("Constructor Dashboard", Callable(self, "_on_constructor_dashboard_button_pressed"))
		_add_box_action_button("Repair Rules", Callable(self, "_on_repair_rules_pressed"))
	_apply_constructor_ui_skin()

func _make_box_top_button(
	text: String,
	callback: Callable,
	active: bool = false,
	role: String = "normal"
) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(120, MENU_TOP_BUTTON_HEIGHT)
	var style_role: String = "primary" if active else role
	_apply_action_button_style(button, style_role, true)
	button.pressed.connect(callback)
	_apply_box_top_button(button)
	return button

func _apply_box_top_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 118.0)
	button.custom_minimum_size.y = BOX_TOP_BUTTON_HEIGHT
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.autowrap_mode = TextServer.AUTOWRAP_OFF

func _setup_box_top_bar() -> void:
	if box_top_bar_root == null:
		return
	for child in box_top_bar_root.get_children():
		child.queue_free()
	if _is_small_viewport():
		var compact_root := VBoxContainer.new()
		compact_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		compact_root.add_theme_constant_override("separation", 6)
		box_top_bar_root.add_child(compact_root)
		var row_one := HBoxContainer.new()
		row_one.add_theme_constant_override("separation", 8)
		row_one.add_child(_make_box_top_button("External", Callable(self, "set_box_menu_mode_external"), box_menu_mode == BoxMenuMode.EXTERNAL))
		row_one.add_child(_make_box_top_button("Internal", Callable(self, "set_box_menu_mode_internal"), box_menu_mode == BoxMenuMode.INTERNAL))
		var row_one_spacer := Control.new()
		row_one_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_one.add_child(row_one_spacer)
		row_one.add_child(_make_box_top_button("Back", Callable(self, "_on_box_back_pressed")))
		compact_root.add_child(row_one)
		var row_two := HBoxContainer.new()
		row_two.add_theme_constant_override("separation", 4)
		row_two.add_child(_make_box_top_button("Scout", Callable(self, "_on_bipob_alpha_pressed"), active_bipob_profile_id == "alpha"))
		row_two.add_child(_make_box_top_button("Engineer", Callable(self, "_on_bipob_beta_pressed"), active_bipob_profile_id == "beta"))
		row_two.add_child(_make_box_top_button("Juggernaut", Callable(self, "_on_bipob_juggernaut_pressed"), active_bipob_profile_id == "juggernaut"))
		compact_root.add_child(row_two)
		return
	var root: HBoxContainer = HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	box_top_bar_root.add_child(root)
	var left_tabs: HBoxContainer = HBoxContainer.new()
	left_tabs.add_child(_make_box_top_button(
		"External",
		Callable(self, "set_box_menu_mode_external"),
		box_menu_mode == BoxMenuMode.EXTERNAL
	))
	left_tabs.add_child(_make_box_top_button(
		"Internal",
		Callable(self, "set_box_menu_mode_internal"),
		box_menu_mode == BoxMenuMode.INTERNAL
	))
	root.add_child(left_tabs)
	var spacer_left: Control = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_left)
	var bipob_row: HBoxContainer = HBoxContainer.new()
	bipob_row.add_theme_constant_override("separation", 4)
	bipob_row.add_child(_make_box_top_button(
		"Scout",
		Callable(self, "_on_bipob_alpha_pressed"),
		active_bipob_profile_id == "alpha"
	))
	bipob_row.add_child(_make_box_top_button(
		"Engineer",
		Callable(self, "_on_bipob_beta_pressed"),
		active_bipob_profile_id == "beta"
	))
	bipob_row.add_child(_make_box_top_button(
		"Juggernaut",
		Callable(self, "_on_bipob_juggernaut_pressed"),
		active_bipob_profile_id == "juggernaut"
	))
	root.add_child(bipob_row)
	var spacer_right: Control = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_right)
	root.add_child(_make_box_top_button(
		"Back",
		Callable(self, "_on_box_back_pressed"),
		false,
		"normal"
	))

func _make_module_by_id(module_id: String) -> BipobModule:
	if module_id.is_empty() or bipob == null:
		return null
	var ext: BipobModule = bipob.create_external_module_by_id(module_id)
	if ext != null:
		return ext
	var overlay: BipobModule = bipob.create_overlay_module_by_id(module_id)
	if overlay != null:
		return overlay
	var internal_specs := {
		"battery_v1": {"name": "Battery V1", "size": Vector3i(2,2,1)},
		"battery_v2": {"name": "Battery V2", "size": Vector3i(2,2,1)},
		"battery_v3": {"name": "Battery V3", "size": Vector3i(2,2,1)},
		"processor_v1": {"name": "Processor V1", "size": Vector3i(1,1,1)},
		"processor_v2": {"name": "Processor V2", "size": Vector3i(1,1,1)},
		"processor_v3": {"name": "Processor V3", "size": Vector3i(1,1,1)},
		"gpu_v1": {"name": "GPU V1", "size": Vector3i(1,1,1)},
		"gpu_v2": {"name": "GPU V2", "size": Vector3i(1,1,1)},
		"gpu_v3": {"name": "GPU V3", "size": Vector3i(1,1,1)},
		"external_interface_v1": {"name": "External Interface V1", "size": Vector3i(2,2,1)},
		"external_interface_v2": {"name": "External Interface V2", "size": Vector3i(2,2,1)},
		"external_interface_v3": {"name": "External Interface V3", "size": Vector3i(2,2,1)},
		"internal_interface_v1": {"name": "Internal Interface V1", "size": Vector3i(1,1,1)},
		"internal_interface_v2": {"name": "Internal Interface V2", "size": Vector3i(1,1,1)},
		"internal_interface_v3": {"name": "Internal Interface V3", "size": Vector3i(1,1,1)},
		"memory_v1": {"name": "Memory V1", "size": Vector3i(1,1,2)},
		"power_block_v1": {"name": "Power Block V1", "size": Vector3i(1,2,2)},
		"power_block_v2": {"name": "Power Block V2", "size": Vector3i(1,2,2)},
		"power_block_v3": {"name": "Power Block V3", "size": Vector3i(1,2,2)},
		"capacitor_bank_v1": {"name": "Capacitor Bank V1", "size": Vector3i(1,1,1)},
		"charger_v1": {"name": "Charger V1", "size": Vector3i(1,1,1)},
		"hard_drive_v1": {"name": "Hard Drive V1", "size": Vector3i(2,2,1)},
		"hard_drive_v2": {"name": "Hard Drive V2", "size": Vector3i(2,2,1)},
		"hard_drive_v3": {"name": "Hard Drive V3", "size": Vector3i(2,2,1)},
		"memory_v2": {"name": "Memory V2", "size": Vector3i(1,1,2)},
		"memory_v3": {"name": "Memory V3", "size": Vector3i(1,1,2)},
		"cooler_v1": {"name": "Cooler V1", "size": Vector3i(1,1,1)},
		"radiator_v1": {"name": "Radiator V1", "size": Vector3i(1,1,1)},
		"water_tube_v1": {"name": "Water Tube V1", "size": Vector3i(0,0,0)},
		"air_duct_v1": {"name": "Air Duct V1", "size": Vector3i(0,0,0)},
		"targeting_computer_v1": {"name": "Targeting Computer V1", "size": Vector3i(1,1,1)},
		"encryption_module_v1": {"name": "Encryption Module V1", "size": Vector3i(1,1,1)},
		"motor_controller_v1": {"name": "Motor Controller V1", "size": Vector3i(1,1,1)},
		"weapon_controller_v1": {"name": "Weapon Controller V1", "size": Vector3i(1,1,1)},
		"firewall_module_v1": {"name": "Firewall Module V1", "size": Vector3i(1,1,1)},
		"auto_repair_unit_v1": {"name": "Auto Repair Unit V1", "size": Vector3i(1,1,1)},
		"sample_analyzer_v1": {"name": "Sample Analyzer V1", "size": Vector3i(1,1,1)}
	}
	if not internal_specs.has(module_id):
		return null
	var spec: Dictionary = internal_specs[module_id]
	return bipob.create_internal_module(module_id, String(spec["name"]), spec["size"])

func _capture_module_profile_record(module: BipobModule) -> Dictionary:
	if module == null:
		return {}
	return {
		"id": module.id,
		"module_id": module.module_id,
		"status": module.status,
		"is_broken": module.is_broken,
		"current_charge": module.current_charge,
		"is_builtin": module.is_builtin,
		"is_removable": module.is_removable,
		"energy_capacity": module.energy_capacity,
		"battery_capacity": module.battery_capacity
	}

func _restore_module_from_profile_record(record: Dictionary) -> BipobModule:
	var module := _make_module_by_id(String(record.get("id", "")))
	if module == null:
		return null
	module.module_id = String(record.get("module_id", module.module_id))
	module.status = String(record.get("status", module.status))
	module.is_broken = bool(record.get("is_broken", module.status == "broken"))
	module.current_charge = int(record.get("current_charge", module.current_charge))
	module.is_builtin = bool(record.get("is_builtin", module.is_builtin))
	module.is_removable = bool(record.get("is_removable", module.is_removable))
	module.energy_capacity = int(record.get("energy_capacity", module.energy_capacity))
	module.battery_capacity = int(record.get("battery_capacity", module.battery_capacity))
	return module

func _capture_constructor_profile_state() -> Dictionary:
	var data: Dictionary = {
		"installed_modules": [], "box_modules": [], "external_slots": {}, "placed_internal": bipob.placed_internal_modules.duplicate(true),
		"placed_external": bipob.placed_external_modules.duplicate(true),
		"external_pockets": bipob.external_pockets_by_side.duplicate(true),
		"overlay_paths": bipob.internal_overlay_paths.duplicate(true), "next_overlay_id": bipob.next_internal_overlay_path_id
	}
	for module in bipob.installed_modules:
		data["installed_modules"].append(_capture_module_profile_record(module))
	for module in bipob.box_storage:
		data["box_modules"].append(_capture_module_profile_record(module))
	for key in bipob.external_modules_by_slot.keys():
		data["external_slots"][key] = _capture_module_profile_record(bipob.external_modules_by_slot[key])
	return data

func _apply_constructor_profile_state(data: Dictionary) -> void:
	bipob.installed_modules.clear(); bipob.box_storage.clear(); bipob.external_modules_by_slot.clear(); bipob.internal_modules_by_cell.clear(); bipob.placed_external_modules.clear()
	bipob.placed_internal_modules = data.get("placed_internal", []).duplicate(true)
	bipob.external_pockets_by_side = data.get("external_pockets", {}).duplicate(true)
	bipob._ensure_external_pockets_shape()
	bipob.internal_overlay_paths = data.get("overlay_paths", []).duplicate(true)
	bipob.next_internal_overlay_path_id = int(data.get("next_overlay_id", 1))
	for record_variant in data.get("installed_modules", []):
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var m := _restore_module_from_profile_record(record_variant)
		if m != null:
			bipob.installed_modules.append(m)
	for record_variant in data.get("box_modules", []):
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var m := _restore_module_from_profile_record(record_variant)
		if m != null:
			bipob.box_storage.append(m)
	for key in data.get("external_slots", {}).keys():
		var slot_record: Variant = data["external_slots"][key]
		if typeof(slot_record) != TYPE_DICTIONARY:
			continue
		var m := _restore_module_from_profile_record(slot_record)
		if m != null:
			bipob.external_modules_by_slot[key] = m
	bipob.placed_external_modules = data.get("placed_external", []).duplicate(true)
	bipob.rebuild_internal_modules_by_cell()
	bipob.recalculate_module_stats()

func _can_remove_selected_internal_module() -> bool:
	var module: BipobModule = selected_constructor_module if selected_module_source == "installed_internal" else bipob.get_internal_module_at_cell(bipob.selected_internal_origin)
	return module != null and bool(module.is_removable)

func _add_juggernaut_builtin_batteries() -> void:
	var size: Vector3i = bipob.get_internal_volume_size()
	var right_origin_x: int = maxi(0, size.x - 2)
	var builtins: Array[Dictionary] = [
		{"origin": Vector3i(0, 0, 0)},
		{"origin": Vector3i(right_origin_x, 0, 0)}
	]
	for entry in builtins:
		var module: BipobModule = _make_module_by_id("battery_v3")
		if module == null:
			continue
		module.is_builtin = true
		module.is_removable = false
		module.status = "ready"
		module.energy_capacity = 50
		module.current_charge = maxi(int(module.energy_capacity), 0)
		bipob.place_internal_module(module, entry.get("origin", Vector3i.ZERO), 0)

func _ensure_constructor_profiles_initialized() -> void:
	if not constructor_profiles.is_empty():
		return
	_apply_constructor_profile_dimensions("alpha")
	constructor_profiles["alpha"] = _capture_constructor_profile_state()
	bipob.add_internal_mvp_modules_to_box()
	var battery_module: BipobModule = _make_module_by_id("battery_v1")
	if battery_module != null:
		bipob.box_storage.append(battery_module)
	var cooler_module: BipobModule = _make_module_by_id("cooler_v1")
	if cooler_module != null:
		bipob.box_storage.append(cooler_module)
	bipob.recalculate_module_stats()
	_apply_constructor_profile_dimensions("beta")
	constructor_profiles["beta"] = _capture_constructor_profile_state()
	_apply_constructor_profile_dimensions("juggernaut")
	_add_juggernaut_builtin_batteries()
	constructor_profiles["juggernaut"] = _capture_constructor_profile_state()
	_apply_constructor_profile_dimensions("alpha")
	_apply_constructor_profile_state(constructor_profiles["alpha"])

func _save_active_bipob_profile() -> void:
	constructor_profiles[active_bipob_profile_id] = _capture_constructor_profile_state()

func _load_bipob_profile(profile_id: String) -> void:
	if not constructor_profiles.has(profile_id):
		return
	_apply_constructor_profile_dimensions(profile_id)
	_apply_constructor_profile_state(constructor_profiles[profile_id])
	active_bipob_profile_id = profile_id
	_update_bipob_selector_visuals()

func _switch_active_bipob(profile_id: String) -> void:
	if profile_id == active_bipob_profile_id:
		return
	_clear_box_module_selection()
	_save_active_bipob_profile()
	_load_bipob_profile(profile_id)
	update_box_status()
	rebuild_box_action_buttons()

func _on_bipob_alpha_pressed() -> void:
	_switch_active_bipob("alpha")

func _on_bipob_beta_pressed() -> void:
	_switch_active_bipob("beta")

func _on_bipob_juggernaut_pressed() -> void:
	_switch_active_bipob("juggernaut")

func _update_bipob_selector_visuals() -> void:
	_setup_box_top_bar()

func _on_box_back_pressed() -> void:
	_save_active_bipob_profile()
	if box_menu_root != null and is_instance_valid(box_menu_root):
		box_menu_root.queue_free()
	box_menu_root = null
	show_center_screen()

func update_box_button_visibility() -> void:
	_setup_box_top_bar()

func set_box_menu_mode_mission() -> void:
	set_box_menu_mode_external()

func set_box_menu_mode_modules() -> void:
	set_box_menu_mode_external()

func set_box_menu_mode_external() -> void:
	if box_menu_mode == BoxMenuMode.EXTERNAL:
		return
	_clear_box_module_selection()
	box_menu_mode = BoxMenuMode.EXTERNAL
	clamp_external_selection()
	update_box_status()
	rebuild_box_action_buttons()


func set_box_menu_mode_internal() -> void:
	if box_menu_mode == BoxMenuMode.INTERNAL:
		return
	_clear_box_module_selection()
	box_menu_mode = BoxMenuMode.INTERNAL
	if get_current_constructor_filter() in ["gear", "visor_radar", "tool", "manipulator", "armor", "weapon"]:
		internal_filter_index = CONSTRUCTOR_FILTERS.find("all")
	_clamp_internal_selection()
	update_box_status()
	rebuild_box_action_buttons()

func _get_internal_box_modules() -> Array[BipobModule]:
	if bipob == null:
		return []
	var modules: Array[BipobModule] = []
	var filtered_indices: Array[int] = get_filtered_internal_box_storage_indices(get_current_constructor_filter())
	for raw_index in filtered_indices:
		modules.append(bipob.box_storage[raw_index])
	return modules

func get_internal_role_display_name(role_id: String) -> String:
	match role_id:
		"battery":
			return "Battery"
		"power_block":
			return "Power Block"
		"internal_interface":
			return "Internal Interface"
		"external_interface":
			return "External Interface"
		"processor":
			return "Processor"
		"memory":
			return "Memory"
		"storage":
			return "Storage"
		"cooling":
			return "Cooling"
		_:
			return "None"

func get_internal_module_info_text(module: BipobModule) -> String:
	if module == null:
		return "Selected Module: none"
	var base_size: Vector3i = bipob.get_internal_module_base_size(module)
	var lines: Array[String] = []
	lines.append("Selected Module:")
	lines.append(bipob.get_module_display_name(module))
	lines.append("Size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
	lines.append("Role: %s" % _get_module_role_text(module))
	lines.append("Placement: %s" % ("external slot" if module.placement_type == "external" else "internal volume"))
	if not module.description.is_empty():
		lines.append("Description: %s" % module.description)
	return "\n".join(lines)

func _clamp_internal_selection() -> void:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		bipob.selected_internal_box_index = 0
	else:
		bipob.selected_internal_box_index = clampi(bipob.selected_internal_box_index, 0, modules.size() - 1)
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation, 3)
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z, 0, v.z - 1)

func _get_selected_internal_module() -> BipobModule:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		return null
	_clamp_internal_selection()
	return modules[bipob.selected_internal_box_index]

func get_internal_module_marker(module: BipobModule) -> String:
	if module == null:
		return "X"
	match module.internal_role:
		"battery":
			return "B"
		"processor":
			return "P"
		"external_interface":
			return "E"
		"internal_interface":
			return "I"
		"memory":
			return "M"
		"power_block":
			return "W"
		"storage":
			return "H"
		_:
			return "X"

func _build_internal_axis_header(prefix: String, count: int) -> String:
	var labels: Array[String] = []
	for i in range(count):
		labels.append("%s%d" % [prefix, i])
	return "    %s" % " ".join(labels)


func _get_internal_view_mode_display_name() -> String:
	match internal_view_mode:
		"modules":
			return "Modules"
		"thermal":
			return "Thermal"
		"overlay":
			return "Overlay"
		"thermal_overlay":
			return "Thermal+Overlay"
		_:
			return String(internal_view_mode)

func _get_internal_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	if internal_view_mode == "thermal":
		return _get_internal_thermal_cell_marker(cell, preview_cells_map, can_place)
	if internal_view_mode == "overlay":
		return _get_internal_overlay_cell_marker(cell, preview_cells_map, can_place)
	if internal_view_mode == "thermal_overlay":
		return _get_internal_thermal_overlay_cell_marker(cell, preview_cells_map, can_place)
	return _get_internal_module_cell_marker(cell, preview_cells_map, can_place)

func _get_internal_module_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_origin and is_occupied:
		return "[>%s]" % get_internal_module_marker(occupied_module)
	if is_origin:
		return "[>]"
	if is_occupied:
		return "[%s]" % get_internal_module_marker(occupied_module)
	if not overlay_marker.is_empty():
		return "[%s]" % overlay_marker
	return "[ ]"

func _get_internal_thermal_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_occupied:
		var heat: int = bipob.get_preview_heat_after_cooling_for_internal_module(occupied_module)
		heat = clampi(heat, 0, 5)
		return "[>%d]" % heat if is_origin else "[%d]" % heat
	if is_origin:
		return "[>]"
	if not overlay_marker.is_empty():
		return "[%s]" % overlay_marker
	return "[ ]"

func _get_internal_thermal_overlay_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if occupied_module != null:
		var heat: int = bipob.get_hypothetical_heat_after_overlay_for_module(occupied_module)
		heat = clampi(heat, 0, 5)
		if is_origin:
			return "[>%d]" % heat
		return "[%d]" % heat
	if not overlay_marker.is_empty():
		if is_origin:
			return "[>%s]" % overlay_marker
		return "[%s]" % overlay_marker
	if is_origin:
		return "[>]"
	return "[ ]"

func _get_internal_background_module_marker(module: BipobModule) -> String:
	if module == null:
		return " "
	var marker: String = get_internal_module_marker(module)
	return marker.to_lower()

func _get_internal_overlay_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if not overlay_marker.is_empty():
		return "[>%s]" % overlay_marker if is_origin else "[%s]" % overlay_marker
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_occupied:
		var background_marker: String = _get_internal_background_module_marker(occupied_module)
		return "[>%s]" % background_marker if is_origin else "[%s]" % background_marker
	if is_origin:
		return "[>]"
	return "[ ]"

func get_air_intake_status_text() -> String:
	if bipob == null:
		return "unknown"
	if bipob.has_method("get_air_intake_status_text"):
		return str(bipob.get_air_intake_status_text())
	return "unknown"

func _on_prev_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index -= 1
	clamp_external_selection()
	update_box_status()

func _on_next_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index += 1
	clamp_external_selection()
	update_box_status()

func _move_external_slot_by(delta: int) -> void:
	if bipob == null:
		return
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var width := side_size.x
	var total_slots := width * side_size.y
	if total_slots <= 0:
		return
	var index := selected_external_slot_position.y * width + selected_external_slot_position.x
	index = (index + delta) % total_slots
	if index < 0:
		index += total_slots
	selected_external_slot_position.x = index % width
	selected_external_slot_position.y = floori(float(index) / float(width))

func _on_prev_external_slot_pressed() -> void:
	_move_external_slot_by(-1)
	update_box_status()

func _on_next_external_slot_pressed() -> void:
	_move_external_slot_by(1)
	update_box_status()

func _on_place_external_module_pressed() -> void:
	if bipob == null:
		return
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_external_selection()
	var selected_module: BipobModule = get_selected_grouped_module()
	if selected_module == null:
		show_hint("No module matches current filter.")
		return
	if bipob.get_box_module_count_by_id(selected_module.id) <= 0:
		show_hint("No available copy in Box Storage.")
		return
	if selected_box_storage_index < 0:
		show_hint("No available copy in Box Storage.")
		return
	var side_id := get_selected_external_side_id()
	if bipob.place_external_module_from_box_storage(
		selected_box_storage_index,
		side_id,
		selected_external_slot_position
	):
		clamp_box_selection_indexes()
		clamp_external_selection()
		update_box_status()

func _on_remove_external_module_pressed() -> void:
	if bipob == null:
		return
	clamp_external_selection()
	if selected_module_source != "installed_external":
		show_hint("Select an installed external module first.")
		return
	var side_id: String = selected_external_side if not selected_external_side.is_empty() else get_selected_external_side_id()
	var cell: Vector2i = selected_external_cell if selected_external_side == side_id else selected_external_slot_position
	var record: Dictionary = selected_install_record
	if record.is_empty():
		record = bipob.get_external_module_record_at(side_id, cell)
	if record.is_empty():
		show_hint("Cannot remove: installed external module record not found.")
		update_box_status()
		return
	if bipob.remove_external_module_record(record, true):
		selected_constructor_module = null
		selected_module_source = "none"
		selected_install_record = {}
		clamp_box_selection_indexes()
		update_box_status()

func show_hint(message: String) -> void:
	RuntimeNotifications.show_hint(self, message)


func _on_constructor_dashboard_button_pressed() -> void:
	if bipob == null:
		return
	var dashboard_text: String = bipob.get_constructor_dashboard_text()
	dashboard_text += "\nIcon system: texture icons optional, missing icons use placeholders."
	show_hint(dashboard_text)

func _on_constructor_warnings_button_pressed() -> void:
	if bipob == null:
		return
	show_hint(bipob.get_constructor_warning_summary_text())
	update_box_status()

func _on_constructor_consistency_button_pressed() -> void:
	if bipob == null:
		return
	show_hint(bipob.get_constructor_consistency_summary_text())
	update_box_status()

func _on_constructor_checkpoint_pressed() -> void:
	if _safe_has_bipob_method("get_constructor_planning_checkpoint_text"):
		_show_constructor_reference_text("CHECKPOINT", str(bipob.get_constructor_planning_checkpoint_text()))
	else:
		_show_constructor_reference_text("CHECKPOINT", "Checkpoint helper is unavailable.")


func _create_menu_button(text: String, callback: Callable = Callable(), min_size: Vector2 = Vector2(150, 34), role: String = "normal") -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(button, role, true)
	if not callback.is_null() and callback.is_valid():
		button.pressed.connect(callback)
	else:
		button.disabled = true
		button.tooltip_text = "Placeholder"
	return button

func _create_top_right_back_button(callback: Callable) -> Button:
	var button := _create_menu_button("Back", callback, MENU_BACK_BUTTON_SIZE)
	_set_menu_top_button_height(button)
	return button

func _set_menu_top_button_height(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size.y = MENU_TOP_BUTTON_HEIGHT

func _build_mission_result_data(success: bool, mission_index: int = -1) -> Dictionary:
	var resolved_index: int = mission_index if mission_index > 0 else _get_current_mission_index_safe()
	var turns_used: int = _get_turns_used_safe()
	var turn_limit: int = _get_turn_limit_safe()
	return {
		"success": success,
		"mission_index": resolved_index,
		"mission_title": _get_mission_result_title(resolved_index),
		"turns_used": turns_used,
		"turn_limit": turn_limit,
		"stars": _calculate_mission_result_stars(success, turns_used, turn_limit),
		"completed_main_goals": _get_completed_main_goals_safe(success),
		"failed_main_goals": _get_failed_main_goals_safe(success),
		"completed_optional_goals": _get_completed_optional_goals_safe(),
		"failed_optional_goals": _get_failed_optional_goals_safe(),
		"rewards": _get_mission_rewards_safe(),
		"can_return_to_center": _can_return_to_center_after_result(success)
	}

func _safe_int(value: Variant, fallback: int = 0) -> int:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		return int(value)
	if typeof(value) == TYPE_STRING:
		var text: String = String(value)
		if text.is_valid_int():
			return text.to_int()
		if text.is_valid_float():
			return int(text.to_float())
	return fallback

func _calculate_mission_result_stars(success: bool, turns_used: int, turn_limit: int) -> int:
	var safe_turns_used: int = maxi(0, _safe_int(turns_used, 0))
	var safe_turn_limit: int = _safe_int(turn_limit, 0)
	if not success:
		return 0
	if safe_turn_limit <= 0:
		return 1
	var ratio: float = float(safe_turns_used) / float(safe_turn_limit)
	if ratio <= 0.5:
		return 3
	if ratio <= 0.8:
		return 2
	return 1

func _get_current_mission_index_safe() -> int:
	return maxi(1, _safe_int(bipob.current_mission_index, 1)) if bipob != null else 1

func _get_mission_result_title(mission_index: int) -> String:
	return "Mission %d" % maxi(1, _safe_int(mission_index, 1))

func _get_turns_used_safe() -> int:
	if bipob != null and bipob.has_method("get_turns_used"):
		return maxi(0, _safe_int(bipob.get_turns_used(), 0))
	return 0

func _get_turn_limit_safe() -> int:
	if bipob != null and bipob.has_method("get_turn_limit"):
		return maxi(1, _safe_int(bipob.get_turn_limit(), 30))
	return 30

func _get_completed_main_goals_safe(success: bool) -> Array[String]:
	var goals: Array[String] = []
	if success:
		goals.append("Main: Reach extraction — completed")
	return goals

func _get_failed_main_goals_safe(success: bool) -> Array[String]:
	var goals: Array[String] = []
	if not success:
		goals.append("Main: Reach extraction — failed")
	return goals

func _get_completed_optional_goals_safe() -> Array[String]:
	var goals: Array[String] = []
	return goals

func _get_failed_optional_goals_safe() -> Array[String]:
	var goals: Array[String] = []
	return goals

func _get_mission_rewards_safe() -> Array[String]:
	var rewards: Array[String] = []
	rewards.append("No rewards")
	return rewards

func _build_main_menu_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	main_menu_root.add_child(margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 380)
	_apply_panel_style(panel, true)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "BIPOB"
	_apply_label_style(title, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_create_menu_button("Play", Callable(self, "_on_main_play_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("Settings", Callable(self, "_on_main_settings_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("About", Callable(self, "_on_main_about_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("Exit Game", Callable(self, "_on_exit_game_pressed"), Vector2(180, 36), "danger"))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer)

	var social := Label.new()
	social.text = "Social media"
	_apply_label_style(social, true, false)
	social.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(social)

	var version := Label.new()
	version.text = "version"
	_apply_label_style(version, true, false)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)

func _build_center_menu_layout() -> void:
	CenterScreenRef.build(self)

func _build_tasks_menu_layout() -> void:
	if tasks_menu_root == null:
		return
	for child in tasks_menu_root.get_children():
		child.queue_free()
	tasks_tab_buttons.clear()

	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_panel_style(background, true)
	tasks_menu_root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	background.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	root.add_child(top_row)
	for tab_name in ["Career", "Daily", "Defense", "Support", "Dev"]:
		var tab_button := _create_menu_button(tab_name, Callable(self, "_on_tasks_tab_pressed").bind(tab_name), Vector2(102, 34))
		tasks_tab_buttons[tab_name] = tab_button
		top_row.add_child(tab_button)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	tasks_bipob_buttons_row = HBoxContainer.new()
	tasks_bipob_buttons_row.custom_minimum_size = Vector2(0, 34)
	tasks_bipob_buttons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tasks_bipob_buttons_row.add_theme_constant_override("separation", 6)
	top_row.add_child(tasks_bipob_buttons_row)
	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(8, 0)
	top_row.add_child(top_gap)
	top_row.add_child(_create_top_right_back_button(Callable(self, "show_center_screen")))

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 10)
	root.add_child(content_row)

	var left_panel_container := PanelContainer.new()
	_apply_panel_style(left_panel_container)
	left_panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(left_panel_container)

	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 10)
	left_margin.add_theme_constant_override("margin_right", 10)
	left_margin.add_theme_constant_override("margin_top", 10)
	left_margin.add_theme_constant_override("margin_bottom", 10)
	left_panel_container.add_child(left_margin)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 8)
	left_margin.add_child(left_vbox)

	var list_scroll: ScrollContainer = ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(list_scroll)

	tasks_list_container = VBoxContainer.new()
	tasks_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tasks_list_container.add_theme_constant_override("separation", 6)
	list_scroll.add_child(tasks_list_container)

	var right_panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(right_panel)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(right_panel)
	left_panel_container.size_flags_stretch_ratio = 1.2
	right_panel.size_flags_stretch_ratio = 2.0

	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 10)
	right_margin.add_theme_constant_override("margin_right", 10)
	right_margin.add_theme_constant_override("margin_top", 10)
	right_margin.add_theme_constant_override("margin_bottom", 10)
	right_panel.add_child(right_margin)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	right_margin.add_child(right_vbox)

	var details_scroll: ScrollContainer = ScrollContainer.new()
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(details_scroll)

	var details_content := VBoxContainer.new()
	details_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_content.add_theme_constant_override("separation", 8)
	details_scroll.add_child(details_content)

	tasks_title_label = Label.new()
	_apply_label_style(tasks_title_label, false, true)
	details_content.add_child(tasks_title_label)

	var header_line := HBoxContainer.new()
	header_line.add_theme_constant_override("separation", 14)
	details_content.add_child(header_line)
	tasks_difficulty_label = Label.new()
	_apply_label_style(tasks_difficulty_label)
	header_line.add_child(tasks_difficulty_label)
	tasks_reward_label = Label.new()
	_apply_label_style(tasks_reward_label)
	header_line.add_child(tasks_reward_label)

	var goals_panel := PanelContainer.new()
	goals_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 6))
	details_content.add_child(goals_panel)
	var goals_row := HBoxContainer.new()
	goals_row.add_theme_constant_override("separation", 10)
	goals_panel.add_child(goals_row)
	var main_goal_box := VBoxContainer.new()
	main_goal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_row.add_child(main_goal_box)
	var main_goal_title := Label.new()
	main_goal_title.text = "Main Goal"
	_apply_label_style(main_goal_title, true)
	main_goal_box.add_child(main_goal_title)
	tasks_main_goal_label = Label.new()
	tasks_main_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(tasks_main_goal_label)
	main_goal_box.add_child(tasks_main_goal_label)
	var extra_goal_box := VBoxContainer.new()
	extra_goal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_row.add_child(extra_goal_box)
	var extra_goal_title := Label.new()
	extra_goal_title.text = "Extra Goal"
	_apply_label_style(extra_goal_title, true)
	extra_goal_box.add_child(extra_goal_title)
	tasks_extra_goal_label = Label.new()
	tasks_extra_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(tasks_extra_goal_label)
	extra_goal_box.add_child(tasks_extra_goal_label)

	var requirements_panel := PanelContainer.new()
	requirements_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 6))
	details_content.add_child(requirements_panel)
	var requirements_grid := GridContainer.new()
	requirements_grid.columns = 1 if _is_small_viewport() else 2
	requirements_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	requirements_grid.add_theme_constant_override("h_separation", 12)
	requirements_grid.add_theme_constant_override("v_separation", 4)
	requirements_panel.add_child(requirements_grid)
	tasks_requirements_required_labels.clear()
	tasks_requirements_current_labels.clear()
	if not _is_small_viewport():
		var required_title := Label.new()
		required_title.text = "Required"
		_configure_requirement_cell_label(required_title, true)
		_apply_label_style(required_title, true)
		requirements_grid.add_child(required_title)
		var current_title := Label.new()
		current_title.text = "Current"
		_configure_requirement_cell_label(current_title, false)
		_apply_label_style(current_title, true)
		requirements_grid.add_child(current_title)
	for _idx in 5:
		var required_cell := Label.new()
		_configure_requirement_cell_label(required_cell, true)
		if _is_small_viewport():
			required_cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			required_cell.custom_minimum_size = Vector2(0, 0)
		requirements_grid.add_child(required_cell)
		tasks_requirements_required_labels.append(required_cell)
		var current_cell := RichTextLabel.new()
		_configure_requirement_cell_rich_label(current_cell)
		if _is_small_viewport():
			current_cell.custom_minimum_size = Vector2(0, 28)
		requirements_grid.add_child(current_cell)
		tasks_requirements_current_labels.append(current_cell)

	var warnings_panel := PanelContainer.new()
	warnings_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 6))
	warnings_panel.custom_minimum_size = Vector2(0, 100)
	details_content.add_child(warnings_panel)
	var warnings_v := VBoxContainer.new(); warnings_panel.add_child(warnings_v)
	var warnings_title := Label.new(); warnings_title.text = "Warnings"; _apply_label_style(warnings_title, true); warnings_v.add_child(warnings_title)
	var warnings_scroll := ScrollContainer.new()
	warnings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	warnings_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	warnings_scroll.custom_minimum_size = Vector2(0, 72)
	warnings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warnings_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _is_small_viewport():
		warnings_scroll.custom_minimum_size = Vector2(0, 56)
		warnings_scroll.custom_minimum_size.y = minf(TASK_REQUIREMENT_WARNING_MAX_HEIGHT, _get_menu_content_max_height() * 0.22)
	warnings_v.add_child(warnings_scroll)
	tasks_warnings_label = RichTextLabel.new(); tasks_warnings_label.bbcode_enabled = true; tasks_warnings_label.fit_content = true
	tasks_warnings_label.add_theme_color_override("default_color", UI_COLOR_TEXT)
	warnings_scroll.add_child(tasks_warnings_label)

	tasks_report_label = Label.new()
	tasks_report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(tasks_report_label, true, false)
	details_content.add_child(tasks_report_label)
	tasks_dev_output_scroll = ScrollContainer.new()
	tasks_dev_output_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tasks_dev_output_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tasks_dev_output_scroll.custom_minimum_size = Vector2(0, 140)
	tasks_dev_output_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tasks_dev_output_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_content.add_child(tasks_dev_output_scroll)
	tasks_dev_output_label = RichTextLabel.new()
	tasks_dev_output_label.bbcode_enabled = false
	tasks_dev_output_label.fit_content = false
	tasks_dev_output_label.scroll_active = false
	tasks_dev_output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tasks_dev_output_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tasks_dev_output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tasks_dev_output_label.add_theme_color_override("default_color", UI_COLOR_TEXT)
	tasks_dev_output_scroll.add_child(tasks_dev_output_label)

	var actions := HBoxContainer.new()
	tasks_actions_row = actions
	actions.add_theme_constant_override("separation", 8)
	right_vbox.add_child(actions)
	tasks_start_button = _create_menu_button("Start", Callable(self, "_on_tasks_start_pressed"), Vector2(120, 34))
	actions.add_child(tasks_start_button)
	tasks_claim_button = _create_menu_button("Claim Reward", Callable(self, "_on_tasks_claim_reward_pressed"), Vector2(160, 34), "warning")
	tasks_claim_button.visible = false
	actions.add_child(tasks_claim_button)
	var actions_spacer := Control.new(); actions_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; actions.add_child(actions_spacer)
	_refresh_tasks_content()

func _build_mission_constructor_screen() -> void:
	if mission_constructor_root == null:
		return
	for child in mission_constructor_root.get_children():
		child.queue_free()

	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_panel_style(background, true)
	mission_constructor_root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	background.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Constructor — Mission"
	_apply_label_style(title, false, true)
	content.add_child(title)

	var body := Label.new()
	body.text = get_box_mission_menu_text()
	_apply_label_style(body)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(body)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	actions.add_child(_create_menu_button("Charge", Callable(self, "_on_charge_button_pressed"), Vector2(140, 34)))
	actions.add_child(_create_menu_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"), Vector2(140, 34)))
	actions.add_child(_create_menu_button("Start", Callable(self, "start_gameplay_from_center"), Vector2(140, 34)))
	actions.add_child(_create_menu_button("Restart", Callable(self, "_on_restart_mission_button_pressed"), Vector2(140, 34)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	actions.add_child(_create_top_right_back_button(Callable(self, "show_center_screen")))

func _build_placeholder_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	placeholder_menu_root.add_child(margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 220)
	_apply_panel_style(panel, true)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	placeholder_title_label = Label.new()
	_apply_label_style(placeholder_title_label, false, true)
	placeholder_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(placeholder_title_label)

	placeholder_body_label = Label.new()
	placeholder_body_label.text = "This section will be added later."
	_apply_label_style(placeholder_body_label)
	placeholder_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(placeholder_body_label)

	vbox.add_child(_create_top_right_back_button(Callable(self, "_on_placeholder_back_pressed")))

func _has_installed_beacon_module_for_recovery() -> bool:
	if bipob == null:
		return false
	if bipob.has_method("has_installed_beacon_module"):
		return bool(bipob.has_installed_beacon_module())
	if bipob.has_method("has_installed_external_module_id"):
		return bool(bipob.has_installed_external_module_id("beacon_module_v1"))
	return false

func _can_return_to_center_after_result(success: bool) -> bool:
	if success:
		return true
	return _has_installed_beacon_module_for_recovery()

func _create_mission_result_layout(data: Dictionary) -> Control:
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.78)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	background.add_child(margin)
	var panel := PanelContainer.new()
	_apply_panel_style(panel, true)
	margin.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = str(data.get("mission_title", "Mission 1"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, true)
	vbox.add_child(title)
	var status := Label.new()
	var success: bool = bool(data.get("success", false))
	status.text = "COMPLETE" if success else "FAIL"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 38)
	status.add_theme_color_override("font_color", UI_COLOR_OK if success else UI_COLOR_DANGER)
	vbox.add_child(status)
	var turns_used: int = _safe_int(data.get("turns_used", 0), 0)
	var turn_limit: int = _safe_int(data.get("turn_limit", 0), 0)
	var stars: int = _safe_int(data.get("stars", 0), 0)
	var score := Label.new()
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.text = "Turns: %d / %s\nStars: %d/3 %s" % [turns_used, str(turn_limit) if turn_limit > 0 else "—", stars, "★".repeat(stars)]
	_apply_label_style(score)
	vbox.add_child(score)
	var goals_row := HBoxContainer.new()
	goals_row.add_theme_constant_override("separation", 10)
	goals_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(goals_row)
	goals_row.add_child(_create_mission_result_goal_panel("Completed Goals", data.get("completed_main_goals", []), data.get("completed_optional_goals", [])))
	goals_row.add_child(_create_mission_result_goal_panel("Failed Goals", data.get("failed_main_goals", []), data.get("failed_optional_goals", [])))
	vbox.add_child(_create_mission_result_rewards_panel(data.get("rewards", [])))
	var button_column := VBoxContainer.new()
	button_column.add_theme_constant_override("separation", 8)
	button_column.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_column)
	button_column.add_child(_create_menu_button("Restart", Callable(self, "_on_mission_result_restart_pressed"), Vector2(220, 38)))
	var center_button: Button = _create_menu_button("Center", Callable(self, "_on_mission_result_center_pressed"), Vector2(220, 38))
	var allow_center_return: bool = bool(data.get("can_return_to_center", true))
	if not allow_center_return:
		center_button.disabled = true
		center_button.tooltip_text = "Beacon Module required"
	button_column.add_child(center_button)
	button_column.add_child(_create_menu_button("Main Menu", Callable(self, "_on_mission_result_main_menu_pressed"), Vector2(220, 38)))
	return background

func _create_mission_result_goal_panel(title_text: String, main_goals: Array, optional_goals: Array) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = title_text
	_apply_label_style(title, true)
	vbox.add_child(title)
	for item in main_goals:
		var line := Label.new()
		line.text = str(item)
		_apply_label_style(line)
		vbox.add_child(line)
	for item in optional_goals:
		var line := Label.new()
		line.text = str(item)
		_apply_label_style(line)
		vbox.add_child(line)
	if main_goals.is_empty() and optional_goals.is_empty():
		var empty := Label.new()
		empty.text = "—"
		_apply_label_style(empty)
		vbox.add_child(empty)
	return panel

func _create_mission_result_rewards_panel(rewards: Array) -> Control:
	var panel := PanelContainer.new()
	_apply_panel_style(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Rewards"
	_apply_label_style(title, true)
	vbox.add_child(title)
	var source_rewards: Array = rewards if not rewards.is_empty() else ["No rewards"]
	for reward in source_rewards:
		var line := Label.new()
		line.text = str(reward)
		_apply_label_style(line)
		vbox.add_child(line)
	return panel

func _on_main_play_pressed() -> void:
	navigate_to_screen(AppScreenMode.CENTER)
func _on_main_settings_pressed() -> void:
	show_placeholder_screen("Settings")
func _on_main_about_pressed() -> void:
	show_placeholder_screen("About")
func _on_main_exit_pressed() -> void:
	_on_exit_game_pressed()

func _on_exit_game_pressed() -> void:
	get_tree().quit()
func _on_center_tasks_pressed() -> void:
	navigate_to_screen(AppScreenMode.TASKS)
func _on_center_box_pressed() -> void:
	navigate_to_screen(AppScreenMode.BOX_CONSTRUCTOR)
func _on_center_constructor_pressed() -> void:
	navigate_to_screen(AppScreenMode.MISSION_CONSTRUCTOR)
func _on_center_charge_pressed() -> void:
	navigate_to_screen(AppScreenMode.CHARGING_MENU)
func _on_center_research_pressed() -> void:
	navigate_to_screen(AppScreenMode.RESEARCH_PLACEHOLDER)
func _on_center_repair_pressed() -> void:
	navigate_to_screen(AppScreenMode.REPAIR_PLACEHOLDER)
func _on_center_programmer_pressed() -> void:
	navigate_to_screen(AppScreenMode.PROGRAMMER_MENU)
func _on_center_shop_pressed() -> void:
	navigate_to_screen(AppScreenMode.SHOP_PLACEHOLDER)
func _on_center_settings_pressed() -> void:
	navigate_to_screen(AppScreenMode.SETTINGS_PLACEHOLDER)
func _on_center_menu_pressed() -> void:
	CenterScreenRef.show_menu(self)
func _on_center_main_menu_pressed() -> void:
	navigate_to_screen(AppScreenMode.MAIN_MENU)

func show_charging_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.CHARGING_MENU
	_hide_all_app_screens()
	_set_gameplay_visible(false)
	if charging_menu_root != null and is_instance_valid(charging_menu_root):
		charging_menu_root.queue_free()
	charging_menu_root = _build_fullscreen_root("ChargingMenuRoot")
	add_child(charging_menu_root)
	_build_charging_menu_layout()
	charging_menu_root.visible = true
	_assert_single_active_major_screen()

func _build_charging_menu_layout() -> void:
	if charging_menu_root == null:
		return
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe_margin: int = int(_get_safe_margin())
	margin.add_theme_constant_override("margin_left", safe_margin)
	margin.add_theme_constant_override("margin_right", safe_margin)
	margin.add_theme_constant_override("margin_top", safe_margin)
	margin.add_theme_constant_override("margin_bottom", safe_margin)
	charging_menu_root.add_child(margin)
	var panel := PanelContainer.new()
	_apply_panel_style(panel, true)
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var charging_station_button := _create_menu_button("Charging Station", Callable(self, "_on_charging_tab_pressed").bind("station"), Vector2(210, MENU_TOP_BUTTON_HEIGHT))
	_set_menu_top_button_height(charging_station_button)
	charging_station_button.disabled = charging_active_tab == "station"
	tabs.add_child(charging_station_button)
	var supercharger_button := _create_menu_button("Supercharger", Callable(self, "_on_charging_tab_pressed").bind("supercharger"), Vector2(180, MENU_TOP_BUTTON_HEIGHT), "primary")
	_set_menu_top_button_height(supercharger_button)
	supercharger_button.disabled = charging_active_tab == "supercharger"
	tabs.add_child(supercharger_button)
	var tabs_spacer := Control.new()
	tabs_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(tabs_spacer)
	var back_button := _create_top_right_back_button(Callable(self, "show_center_screen"))
	_set_menu_top_button_height(back_button)
	tabs.add_child(back_button)
	root.add_child(tabs)

	var rows_scroll := ScrollContainer.new()
	rows_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(rows_scroll)
	var rows_vbox := VBoxContainer.new()
	rows_vbox.name = "RowsVBox"
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 8)
	rows_scroll.add_child(rows_vbox)

	if charging_active_tab == "station":
		var placeholder := Label.new()
		placeholder.text = "Charging Station will be added later."
		_apply_label_style(placeholder)
		rows_vbox.add_child(placeholder)
		return

	# TODO: replace test cost with real charging price.
	for entry in get_chargeable_bipobs():
		rows_vbox.add_child(_create_charge_row(entry, true))
	for module in get_chargeable_batteries():
		rows_vbox.add_child(_create_charge_row(module, false))

func _create_charge_row(entry: Variant, is_bipob_row: bool) -> Control:
	var row := PanelContainer.new()
	_apply_panel_style(row)
	row.custom_minimum_size.y = 96
	var is_small: bool = _is_small_viewport()
	var row_container: BoxContainer = null
	if is_small:
		row_container = VBoxContainer.new()
	else:
		row_container = HBoxContainer.new()
	row_container.add_theme_constant_override("separation", 8)
	row.add_child(row_container)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 0 if is_small else 280
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	var card_text := Label.new()
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(card_text)
	var energy_label := Label.new()
	energy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(energy_label)
	var warning_label := Label.new()
	warning_label.custom_minimum_size.x = 0 if is_small else 260
	warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(warning_label)
	var warning_text := ""
	var cost_label := Label.new()
	cost_label.custom_minimum_size.x = 120 if not is_small else 0
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if not is_small else HORIZONTAL_ALIGNMENT_LEFT
	_apply_label_style(cost_label)
	cost_label.text = "Cost: 0"
	if is_bipob_row:
		var max_energy_value := get_bipob_max_energy(entry)
		var current_energy := get_bipob_current_energy(entry)
		card_text.text = String(entry.get("name", "Bipob"))
		energy_label.text = "Energy: -" if max_energy_value <= 0 else "Energy: %d / %d" % [current_energy, max_energy_value]
	else:
		var module: BipobModule = entry
		var current_charge := get_battery_current_charge(module)
		var capacity := get_battery_capacity(module)
		card_text.text = module.get_display_name()
		energy_label.text = "Energy: %d / %d" % [current_charge, capacity]

	var action_button := _create_menu_button("Charge", Callable(), Vector2(120, 56))
	var is_full := is_bipob_fully_charged(entry) if is_bipob_row else is_battery_fully_charged(entry)
	var can_charge_now := false
	if is_bipob_row:
		warning_text = get_bipob_charge_warning(entry)
		can_charge_now = can_charge_bipob(entry)
		action_button.text = "Charged" if is_full else "Charge"
		action_button.disabled = not can_charge_now
	else:
		var battery: BipobModule = entry
		if battery != null and String(battery.status).to_lower() == "broken":
			warning_text = "broken"
		can_charge_now = can_charge_loose_battery(battery)
		action_button.text = "Charged" if is_full else "Charge"
		action_button.disabled = not can_charge_now
	warning_label.text = warning_text
	var warning_color: Color = UI_COLOR_DANGER
	if warning_text == "Charger" or warning_text == "Need charger module":
		warning_color = UI_COLOR_WARNING
		cost_label.text = "Need charger module"
		cost_label.add_theme_color_override("font_color", UI_COLOR_DANGER)
	warning_label.add_theme_color_override("font_color", warning_color)
	if is_full:
		action_button.text = "Charged"
		action_button.disabled = true
	if not action_button.disabled:
		action_button.pressed.connect(_on_charge_entry_pressed.bind(entry, is_bipob_row))
	_apply_action_button_style(action_button, "primary" if not action_button.disabled else "disabled", not action_button.disabled)
	if action_button.disabled:
		action_button.modulate = Color(0.65, 0.65, 0.65, 1.0)

	left.add_child(card_text)
	left.add_child(energy_label)
	row_container.add_child(left)
	row_container.add_child(warning_label)
	row_container.add_child(cost_label)
	row_container.add_child(action_button)
	return row

func _on_charging_tab_pressed(tab_id: String) -> void:
	charging_active_tab = tab_id
	show_charging_menu()

func _on_charge_entry_pressed(entry: Variant, is_bipob_row: bool) -> void:
	if is_bipob_row:
		charge_bipob_to_full(entry)
	else:
		charge_battery_to_full(entry)
	_refresh_all_energy_dependent_ui()

func get_chargeable_bipobs() -> Array:
	var items: Array = []
	for bipob_data in tasks_available_bipobs:
		var profile_id: String = String(bipob_data.get("id", ""))
		var current_and_max: Dictionary = _get_profile_energy_summary(profile_id)
		var item := {
			"id": profile_id,
			"name": String(bipob_data.get("name", "Bipob")),
			"current_energy": int(current_and_max.get("current", 0)),
			"max_energy": int(current_and_max.get("max", 0)),
			"has_charger": _profile_has_charger(profile_id)
		}
		if profile_id == active_bipob_profile_id:
			item["current_energy"] = int(current_and_max.get("current", 0))
		items.append(item)
	return items

func get_chargeable_batteries() -> Array:
	var batteries: Array = []
	if bipob == null:
		return batteries
	for module in bipob.box_storage:
		if module == null:
			continue
		if not is_loose_battery_module(module):
			continue
		batteries.append(module)
	return batteries

func is_loose_battery_module(module: BipobModule) -> bool:
	if module == null:
		return false
	return module.id in ["battery_v1", "battery_v2", "battery_v3"]

func is_bipob_fully_charged(bipob_data: Dictionary) -> bool:
	return get_bipob_current_energy(bipob_data) >= get_bipob_max_energy(bipob_data)

func bipob_has_any_battery(bipob_data: Dictionary) -> bool:
	return get_bipob_max_energy(bipob_data) > 0


func get_bipob_current_energy(bipob_data: Dictionary) -> int:
	return maxi(int(bipob_data.get("current_energy", 0)), 0)

func get_bipob_max_energy(bipob_data: Dictionary) -> int:
	return maxi(int(bipob_data.get("max_energy", 0)), 0)

func charge_bipob_to_full(bipob_data: Dictionary) -> void:
	var profile_id: String = String(bipob_data.get("id", ""))
	if profile_id.is_empty():
		return
	if not _profile_has_charger(profile_id):
		return
	for module in _get_profile_battery_modules(profile_id):
		if module != null:
			module.current_charge = get_battery_capacity(module)
	_mark_energy_state_dirty()
	_sync_profile_energy_cache(profile_id)

func is_battery_fully_charged(module: BipobModule) -> bool:
	if module == null:
		return true
	return get_battery_current_charge(module) >= get_battery_capacity(module)

func get_battery_capacity(module: BipobModule) -> int:
	if module == null:
		return 0
	match module.id:
		"battery_v1":
			return 30
		"battery_v2":
			return 40
		"battery_v3":
			return 50
	if module.energy_capacity > 0:
		return module.energy_capacity
	if module.battery_capacity > 0:
		return module.battery_capacity
	match module.version:
		"V1":
			return 30
		"V2":
			return 40
		"V3":
			return 50
	return 0

func get_battery_current_charge(module: BipobModule) -> int:
	if module == null:
		return 0
	return maxi(module.current_charge, 0)

func charge_battery_to_full(module: BipobModule) -> void:
	if module == null:
		return
	charge_loose_battery(module)
	# TODO: persist battery charging state when save system is implemented.

func can_charge_loose_battery(module: BipobModule) -> bool:
	if not is_loose_battery_module(module):
		return false
	var status_text: String = String(module.status).to_lower()
	if status_text == "broken" or status_text == "unknown":
		return false
	return get_battery_current_charge(module) < get_battery_capacity(module)

func charge_loose_battery(module: BipobModule) -> void:
	if module == null:
		return
	if not is_loose_battery_module(module):
		return
	var status_text: String = String(module.status).to_lower()
	if status_text == "broken" or status_text == "unknown":
		return
	module.current_charge = get_battery_capacity(module)
	_mark_energy_state_dirty()

func _mark_energy_state_dirty() -> void:
	_save_active_bipob_profile()
	if bipob != null:
		bipob.recalculate_module_stats()
	_sync_profile_energy_cache(active_bipob_profile_id)

func _refresh_all_energy_dependent_ui() -> void:
	if app_screen_mode == AppScreenMode.CHARGING_MENU:
		show_charging_menu()
	if app_screen_mode == AppScreenMode.BOX_CONSTRUCTOR:
		update_box_status()
		rebuild_box_action_buttons()
	_setup_mission_field_hud()
	update_status()

func _setup_mission_field_hud() -> void:
	# Keep mission gameplay HUD in sync after screen hierarchy/runtime refreshes.
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	_hide_all_app_screens()
	_apply_runtime_hud_layout()
	_set_gameplay_visible(true)
	call_deferred("_attach_runtime_gameplay_view")

func _get_profile_battery_modules(profile_id: String) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	if profile_id == active_bipob_profile_id:
		for module in _get_internal_installed_modules():
			if module != null and String(module.internal_family).to_lower() == "battery":
				modules.append(module)
		return modules
	if not constructor_profiles.has(profile_id):
		return modules
	var profile_data: Dictionary = constructor_profiles[profile_id]
	for record_variant in profile_data.get("placed_internal", []):
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var module: BipobModule = record_variant.get("module", null)
		if module != null and String(module.internal_family).to_lower() == "battery":
			modules.append(module)
	return modules

func _sync_profile_energy_cache(profile_id: String) -> void:
	if not constructor_profiles.has(profile_id):
		return
	var summary: Dictionary = _get_profile_energy_summary(profile_id)
	var profile_data: Dictionary = constructor_profiles[profile_id]
	profile_data["current_energy"] = int(summary.get("current", 0))
	profile_data["max_energy"] = int(summary.get("max", 0))
	constructor_profiles[profile_id] = profile_data

func get_bipob_charge_warning(bipob_data: Dictionary) -> String:
	if not bipob_has_any_battery(bipob_data):
		return "Need battery"
	if not bipob_has_charger(bipob_data):
		return "Need charger module"
	return ""

func can_charge_bipob(bipob_data: Dictionary) -> bool:
	if not bipob_has_any_battery(bipob_data):
		return false
	if not bipob_has_charger(bipob_data):
		return false
	return get_bipob_current_energy(bipob_data) < get_bipob_max_energy(bipob_data)

func show_programmer_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.PROGRAMMER_MENU
	_hide_all_app_screens()
	if programmer_menu_root != null and is_instance_valid(programmer_menu_root):
		programmer_menu_root.queue_free()
	programmer_menu_root = _build_fullscreen_root("ProgrammerMenuRoot")
	add_child(programmer_menu_root)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe_margin: int = int(_get_safe_margin())
	margin.add_theme_constant_override("margin_left", safe_margin)
	margin.add_theme_constant_override("margin_right", safe_margin)
	margin.add_theme_constant_override("margin_top", safe_margin)
	margin.add_theme_constant_override("margin_bottom", safe_margin)
	programmer_menu_root.add_child(margin)
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	margin.add_child(panel)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	root.add_child(top_row)
	var title: Label = Label.new()
	title.text = "Programmer"
	_apply_label_style(title, false, true)
	top_row.add_child(title)
	var top_spacer: Control = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	top_row.add_child(_create_menu_button("Back", Callable(self, "_on_programmer_back_pressed"), Vector2(120, MENU_TOP_BUTTON_HEIGHT)))
	programmer_message_label = Label.new()
	programmer_message_label.text = "Decrypt/recover files and reprogram found or damaged bipobs."
	programmer_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(programmer_message_label, true, false)
	root.add_child(programmer_message_label)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ProgrammerScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var rows_vbox: VBoxContainer = VBoxContainer.new()
	rows_vbox.name = "ProgrammerRowsVBox"
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(rows_vbox)
	_refresh_programmer_menu()
	_assert_single_active_major_screen()

func _refresh_programmer_menu() -> void:
	if programmer_menu_root == null or not is_instance_valid(programmer_menu_root):
		return
	_sync_programmer_runtime_lists()
	var rows_vbox: VBoxContainer = programmer_menu_root.find_child("ProgrammerRowsVBox", true, false)
	if rows_vbox == null:
		return
	var old_children: Array = rows_vbox.get_children().duplicate()
	for child_variant in old_children:
		var child: Node = child_variant
		if child != null and is_instance_valid(child):
			child.queue_free()
	rows_vbox.add_child(_create_programmer_section_header("Files for decryption or recovery"))
	if programmer_pending_files.is_empty() and programmer_completed_files.is_empty():
		rows_vbox.add_child(_create_programmer_empty_label("No files in inventory or on the field."))
	else:
		for file_record in programmer_pending_files:
			rows_vbox.add_child(_create_programmer_file_row(file_record, false))
		for file_record in programmer_completed_files:
			rows_vbox.add_child(_create_programmer_file_row(file_record, true))
	rows_vbox.add_child(_create_programmer_section_header("Damaged / found bipobs"))
	if programmer_pending_bipobs.is_empty() and programmer_reprogrammed_bipobs.is_empty():
		rows_vbox.add_child(_create_programmer_empty_label("No damaged or found bipobs available."))
	else:
		for bipob_record in programmer_pending_bipobs:
			rows_vbox.add_child(_create_programmer_bipob_row(bipob_record, false))
		for bipob_record in programmer_reprogrammed_bipobs:
			rows_vbox.add_child(_create_programmer_bipob_row(bipob_record, true))

func _sync_programmer_runtime_lists() -> void:
	var pending_file_by_id: Dictionary = _programmer_dictionary_by_id(programmer_pending_files)
	var completed_file_by_id: Dictionary = _programmer_dictionary_by_id(programmer_completed_files)
	for source_file in _get_programmer_source_files():
		var file_id: String = _programmer_safe_string(source_file.get("id", "")).strip_edges()
		if file_id.is_empty():
			continue
		var state: String = _programmer_safe_string(source_file.get("state", source_file.get("digital_state", "encrypted"))).strip_edges().to_lower()
		if completed_file_by_id.has(file_id):
			completed_file_by_id[file_id] = _merge_programmer_record(Dictionary(completed_file_by_id[file_id]), source_file)
		elif ["decrypted", "recovered", "opened", "complete", "completed"].has(state):
			completed_file_by_id[file_id] = source_file
		elif not pending_file_by_id.has(file_id):
			pending_file_by_id[file_id] = source_file
		else:
			pending_file_by_id[file_id] = _merge_programmer_record(Dictionary(pending_file_by_id[file_id]), source_file)
	programmer_pending_files = _programmer_sorted_records(pending_file_by_id)
	programmer_completed_files = _programmer_sorted_records(completed_file_by_id)
	var pending_bipob_by_id: Dictionary = _programmer_dictionary_by_id(programmer_pending_bipobs)
	var completed_bipob_by_id: Dictionary = _programmer_dictionary_by_id(programmer_reprogrammed_bipobs)
	for source_bipob in _get_programmer_source_bipobs():
		var bipob_id: String = _programmer_safe_string(source_bipob.get("id", source_bipob.get("profile_id", ""))).strip_edges()
		if bipob_id.is_empty():
			continue
		source_bipob["id"] = bipob_id
		if completed_bipob_by_id.has(bipob_id):
			completed_bipob_by_id[bipob_id] = _merge_programmer_record(Dictionary(completed_bipob_by_id[bipob_id]), source_bipob)
		elif not pending_bipob_by_id.has(bipob_id):
			pending_bipob_by_id[bipob_id] = source_bipob
		else:
			pending_bipob_by_id[bipob_id] = _merge_programmer_record(Dictionary(pending_bipob_by_id[bipob_id]), source_bipob)
	programmer_pending_bipobs = _programmer_sorted_records(pending_bipob_by_id)
	programmer_reprogrammed_bipobs = _programmer_sorted_records(completed_bipob_by_id)

func _get_programmer_source_files() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var seen: Dictionary = {}
	if bipob != null:
		if _object_has_property(bipob, "digital_world_records"):
			var digital_records: Dictionary = Dictionary(bipob.get("digital_world_records"))
			for key_variant in digital_records.keys():
				var record: Dictionary = _programmer_as_dictionary(digital_records.get(key_variant, {}))
				record["id"] = _programmer_safe_string(record.get("id", key_variant)).strip_edges()
				_append_programmer_file_if_relevant(records, seen, record, "bipob")
		if bipob.has_method("get_digital_storage_items"):
			for item_variant in Array(bipob.call("get_digital_storage_items")):
				_append_programmer_file_if_relevant(records, seen, _programmer_as_dictionary(item_variant), "storage")
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_inventory_state"):
		var inv: Dictionary = Dictionary(mission_manager_runtime.call("get_inventory_state"))
		for item_id_variant in Array(inv.get("digital_buffer", [])):
			var item_id: String = _programmer_safe_string(item_id_variant).strip_edges()
			if item_id.is_empty():
				continue
			var runtime_map: Dictionary = Dictionary(inv.get("world_item_runtime", {}))
			var runtime_entry: Dictionary = _programmer_as_dictionary(runtime_map.get(item_id, {}))
			var item_data: Dictionary = _programmer_as_dictionary(runtime_entry.get("item_data", runtime_entry))
			item_data["id"] = item_id
			_append_programmer_file_if_relevant(records, seen, item_data, "inventory")
		var runtime_items: Dictionary = Dictionary(inv.get("world_item_runtime", {}))
		for runtime_key_variant in runtime_items.keys():
			var runtime_record: Dictionary = _programmer_as_dictionary(runtime_items.get(runtime_key_variant, {}))
			var runtime_item_data: Dictionary = _programmer_as_dictionary(runtime_record.get("item_data", runtime_record))
			runtime_item_data["id"] = _programmer_safe_string(runtime_item_data.get("id", runtime_key_variant)).strip_edges()
			_append_programmer_file_if_relevant(records, seen, runtime_item_data, "inventory")
	if mission_manager_runtime != null and _object_has_property(mission_manager_runtime, "mission_world_objects"):
		for object_variant in Array(mission_manager_runtime.get("mission_world_objects")):
			_append_programmer_file_if_relevant(records, seen, _programmer_as_dictionary(object_variant), "field")
	if mission_manager_runtime != null and _object_has_property(mission_manager_runtime, "cell_items"):
		var cell_items_map: Dictionary = Dictionary(mission_manager_runtime.get("cell_items"))
		for cell_variant in cell_items_map.keys():
			for item_variant in Array(cell_items_map.get(cell_variant, [])):
				_append_programmer_file_if_relevant(records, seen, _programmer_as_dictionary(item_variant), "field")
	return records

func _append_programmer_file_if_relevant(records: Array[Dictionary], seen: Dictionary, data: Dictionary, source: String) -> void:
	if data.is_empty():
		return
	var file_id: String = _programmer_safe_string(data.get("id", data.get("record_id", ""))).strip_edges()
	if file_id.is_empty():
		return
	var combined_text: String = (file_id + " " + _programmer_safe_string(data.get("display_name", data.get("name", ""))) + " " + _programmer_safe_string(data.get("item_type", data.get("object_type", ""))) + " " + _programmer_safe_string(data.get("item_family", ""))).to_lower()
	var state: String = _programmer_safe_string(data.get("digital_state", data.get("state", ""))).strip_edges().to_lower()
	var is_file: bool = combined_text.contains("file") or combined_text.contains("data") or combined_text.contains("record") or combined_text.contains("digital")
	var needs_programmer: bool = ["encrypted", "corrupted", "damaged", "recover", "recovery", "lost"].has(state) or combined_text.contains("encrypted") or combined_text.contains("corrupt")
	var is_completed: bool = ["decrypted", "recovered", "opened", "complete", "completed"].has(state)
	if not is_file and not needs_programmer and not is_completed:
		return
	if seen.has(file_id):
		return
	seen[file_id] = true
	var record: Dictionary = data.duplicate(true)
	record["id"] = file_id
	record["source"] = source
	if _programmer_safe_string(record.get("display_name", "")).strip_edges().is_empty():
		record["display_name"] = file_id.capitalize()
	if state.is_empty():
		record["state"] = "encrypted" if needs_programmer else "opened"
	else:
		record["state"] = state
	record["action"] = "Decrypt"
	if ["corrupted", "damaged", "recover", "recovery", "lost"].has(_programmer_safe_string(record.get("state", "")).to_lower()):
		record["action"] = "Recover"
	records.append(record)

func _get_programmer_source_bipobs() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var seen: Dictionary = {}
	if bipob != null and bipob.has_method("get_damaged_bipobs_for_repair"):
		for row_variant in Array(bipob.call("get_damaged_bipobs_for_repair")):
			var row: Dictionary = _programmer_as_dictionary(row_variant)
			var row_id: String = _programmer_safe_string(row.get("profile_id", row.get("id", ""))).strip_edges()
			if row_id.is_empty() or seen.has(row_id):
				continue
			seen[row_id] = true
			row["id"] = row_id
			row["type"] = _programmer_safe_string(row.get("name", "Bipob"))
			records.append(row)
	if mission_manager_runtime != null and _object_has_property(mission_manager_runtime, "mission_world_objects"):
		for object_variant in Array(mission_manager_runtime.get("mission_world_objects")):
			var object_data: Dictionary = _programmer_as_dictionary(object_variant)
			var object_id: String = _programmer_safe_string(object_data.get("id", "")).strip_edges()
			if object_id.is_empty() or seen.has(object_id):
				continue
			var text: String = (object_id + " " + _programmer_safe_string(object_data.get("display_name", object_data.get("name", ""))) + " " + _programmer_safe_string(object_data.get("object_type", object_data.get("item_type", "")))).to_lower()
			var state: String = _programmer_safe_string(object_data.get("state", object_data.get("status", ""))).to_lower()
			if not text.contains("bipob") and not text.contains("bipop"):
				continue
			if not ["damaged", "broken", "found", "disabled", "corrupted", ""].has(state):
				continue
			seen[object_id] = true
			object_data["id"] = object_id
			object_data["type"] = _programmer_safe_string(object_data.get("display_name", object_data.get("name", "Found Bipob")))
			records.append(object_data)
	return records

func _create_programmer_section_header(text: String) -> Control:
	var label: Label = Label.new()
	label.text = text
	_apply_label_style(label, false, true)
	return label

func _create_programmer_empty_label(text: String) -> Control:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(label, true, false)
	return label

func _create_programmer_file_row(file_record: Dictionary, completed: bool) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: BoxContainer = null
	if _is_small_viewport():
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_create_programmer_icon_card("FILE", _programmer_safe_string(file_record.get("display_name", file_record.get("id", "File")))))
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = _programmer_safe_string(file_record.get("display_name", file_record.get("id", "File")))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(title)
	info.add_child(title)
	var details: Label = Label.new()
	details.text = "State: %s | Cost: %d energy | Time: %s" % [_programmer_safe_string(file_record.get("state", "encrypted")), _get_programmer_file_cost(file_record), _programmer_safe_string(file_record.get("time", "1 turn"))]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(details, true, false)
	info.add_child(details)
	row.add_child(info)
	var button_text: String = _programmer_safe_string(file_record.get("action", "Decrypt"))
	var callback: Callable = Callable(self, "_on_programmer_file_action_pressed").bind(_programmer_safe_string(file_record.get("id", "")))
	if completed:
		button_text = "Move to Storage"
		callback = Callable(self, "_on_programmer_move_file_pressed").bind(_programmer_safe_string(file_record.get("id", "")))
	var action_button: Button = _create_menu_button(button_text, callback, Vector2(160, 38), "primary")
	row.add_child(action_button)
	return panel

func _create_programmer_bipob_row(bipob_record: Dictionary, completed: bool) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: BoxContainer = null
	if _is_small_viewport():
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_create_programmer_icon_card("BIPOB", _programmer_safe_string(bipob_record.get("type", bipob_record.get("name", "Bipob")))))
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = _programmer_safe_string(bipob_record.get("type", bipob_record.get("name", "Bipob")))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(title)
	info.add_child(title)
	var details: Label = Label.new()
	details.text = "Cost: %d energy | Time: %s" % [_get_programmer_bipob_cost(bipob_record), _programmer_safe_string(bipob_record.get("time", "1 turn"))]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(details, true, false)
	info.add_child(details)
	row.add_child(info)
	var button_text: String = "Reprogram"
	var callback: Callable = Callable(self, "_on_programmer_bipob_action_pressed").bind(_programmer_safe_string(bipob_record.get("id", "")))
	if completed:
		button_text = "Take to Box"
		callback = Callable(self, "_on_programmer_take_bipob_pressed").bind(_programmer_safe_string(bipob_record.get("id", "")))
	var action_button: Button = _create_menu_button(button_text, callback, Vector2(150, 38), "primary")
	row.add_child(action_button)
	return panel

func _create_programmer_icon_card(kind: String, label_text: String) -> Control:
	var card: Button = Button.new()
	card.disabled = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(110, 54)
	card.text = "%s\n%s" % [kind, label_text.left(14)]
	_apply_action_button_style(card, "normal", true)
	return card

func _on_programmer_file_action_pressed(file_id: String) -> void:
	var index: int = _programmer_find_record_index(programmer_pending_files, file_id)
	if index < 0:
		_set_programmer_message("File is no longer available.")
		_refresh_programmer_menu()
		return
	if not _has_programmer_module():
		_set_programmer_message("Programmer module missing. Install an Encryption Module or processor before working on files.")
		return
	var record: Dictionary = programmer_pending_files[index]
	if not _consume_programmer_energy(_get_programmer_file_cost(record)):
		_set_programmer_message("Not enough energy for %s." % _programmer_safe_string(record.get("action", "Decrypt")).to_lower())
		return
	programmer_pending_files.remove_at(index)
	record["state"] = "decrypted"
	if _programmer_safe_string(record.get("action", "Decrypt")) == "Recover":
		record["state"] = "recovered"
	programmer_completed_files.append(record)
	_set_programmer_message("%s complete: %s." % [_programmer_safe_string(record.get("action", "Decrypt")), _programmer_safe_string(record.get("display_name", file_id))])
	update_box_status()
	_refresh_programmer_menu()

func _on_programmer_move_file_pressed(file_id: String) -> void:
	var index: int = _programmer_find_record_index(programmer_completed_files, file_id)
	if index < 0:
		_set_programmer_message("Completed file is no longer available.")
		_refresh_programmer_menu()
		return
	var record: Dictionary = programmer_completed_files[index]
	if bipob == null or not bipob.has_method("store_digital_record"):
		_set_programmer_message("Digital storage is unavailable; file remains completed here.")
		return
	bipob.call("store_digital_record", file_id, _programmer_safe_string(record.get("display_name", file_id)), "Recovered by Programmer menu.")
	programmer_completed_files.remove_at(index)
	_set_programmer_message("Moved to storage: %s." % _programmer_safe_string(record.get("display_name", file_id)))
	update_box_status()
	_refresh_programmer_menu()

func _on_programmer_bipob_action_pressed(bipob_id: String) -> void:
	var index: int = _programmer_find_record_index(programmer_pending_bipobs, bipob_id)
	if index < 0:
		_set_programmer_message("Bipob is no longer available.")
		_refresh_programmer_menu()
		return
	if not _has_programmer_module():
		_set_programmer_message("Programmer module missing. Install an Encryption Module or processor before reprogramming.")
		return
	var record: Dictionary = programmer_pending_bipobs[index]
	if not _consume_programmer_energy(_get_programmer_bipob_cost(record)):
		_set_programmer_message("Not enough energy to reprogram bipob.")
		return
	programmer_pending_bipobs.remove_at(index)
	record["state"] = "reprogrammed"
	programmer_reprogrammed_bipobs.append(record)
	_set_programmer_message("Reprogrammed: %s." % _programmer_safe_string(record.get("type", record.get("name", bipob_id))))
	update_box_status()
	_refresh_programmer_menu()

func _on_programmer_take_bipob_pressed(bipob_id: String) -> void:
	var index: int = _programmer_find_record_index(programmer_reprogrammed_bipobs, bipob_id)
	if index < 0:
		_set_programmer_message("Reprogrammed bipob is no longer available.")
		_refresh_programmer_menu()
		return
	var record: Dictionary = programmer_reprogrammed_bipobs[index]
	_programmer_add_bipob_to_box(record)
	programmer_reprogrammed_bipobs.remove_at(index)
	_set_programmer_message("Moved to Box: %s." % _programmer_safe_string(record.get("type", record.get("name", bipob_id))))
	update_box_status()
	_refresh_programmer_menu()

func _programmer_add_bipob_to_box(record: Dictionary) -> void:
	var bipob_id: String = _programmer_safe_string(record.get("profile_id", record.get("id", ""))).strip_edges()
	if bipob_id.is_empty():
		bipob_id = "found_bipob_%d" % tasks_available_bipobs.size()
	for existing in tasks_available_bipobs:
		if _programmer_safe_string(existing.get("id", "")).strip_edges() == bipob_id:
			return
	tasks_available_bipobs.append({"id": bipob_id, "name": _programmer_safe_string(record.get("type", record.get("name", "Bipob")))})

func _on_programmer_back_pressed() -> void:
	if programmer_menu_root != null and is_instance_valid(programmer_menu_root):
		programmer_menu_root.queue_free()
		programmer_menu_root = null
	show_center_screen()

func _has_programmer_module() -> bool:
	if bipob == null:
		return false
	for module_id in ["encryption_module_v1", "processor_v1", "processor_v2", "cpu_v1", "gpu_v1"]:
		if bipob.has_method("has_module_id_anywhere") and bool(bipob.call("has_module_id_anywhere", module_id)):
			return true
		if bipob.has_method("has_installed_external_module_id") and bool(bipob.call("has_installed_external_module_id", module_id)):
			return true
	return false

func _consume_programmer_energy(cost: int) -> bool:
	var safe_cost: int = maxi(0, cost)
	if safe_cost <= 0:
		return true
	if bipob == null or not _object_has_property(bipob, "energy"):
		return true
	var current_energy: int = int(bipob.get("energy"))
	if current_energy < safe_cost:
		return false
	bipob.set("energy", current_energy - safe_cost)
	if bipob.has_signal("status_changed"):
		bipob.emit_signal("status_changed")
	return true

func _get_programmer_file_cost(file_record: Dictionary) -> int:
	return maxi(0, _safe_int(file_record.get("programmer_cost", file_record.get("cost", 1)), 1))

func _get_programmer_bipob_cost(bipob_record: Dictionary) -> int:
	return maxi(0, _safe_int(bipob_record.get("programmer_cost", bipob_record.get("cost", 2)), 2))

func _set_programmer_message(message: String) -> void:
	if programmer_message_label != null and is_instance_valid(programmer_message_label):
		programmer_message_label.text = message

func _programmer_safe_string(value: Variant) -> String:
	return _programmer_safe_string_with_depth(value, 0)

func _programmer_safe_string_with_depth(value: Variant, depth: int) -> String:
	if value == null or depth > 2:
		return ""
	var value_type: int = typeof(value)
	if value_type == TYPE_STRING:
		var string_value: String = value
		return string_value
	if value_type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING_NAME, TYPE_NODE_PATH]:
		return str(value)
	if value_type == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		for dictionary_field_name: String in ["id", "profile_id", "name", "display_name"]:
			if dictionary_value.has(dictionary_field_name):
				var dictionary_text: String = _programmer_safe_string_with_depth(dictionary_value.get(dictionary_field_name), depth + 1)
				if not dictionary_text.is_empty():
					return dictionary_text
		return ""
	if value_type == TYPE_OBJECT:
		var object_value: Object = value
		if object_value == null or not is_instance_valid(object_value):
			return ""
		for object_field_name: String in ["id", "profile_id", "name", "display_name"]:
			if _object_has_property(object_value, object_field_name):
				var object_text: String = _programmer_safe_string_with_depth(object_value.get(object_field_name), depth + 1)
				if not object_text.is_empty():
					return object_text
	return ""

func _programmer_as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value).duplicate(true)
	return {}

func _merge_programmer_record(existing: Dictionary, incoming: Dictionary) -> Dictionary:
	var merged: Dictionary = existing.duplicate(true)
	for key_variant in incoming.keys():
		if not merged.has(key_variant) or _programmer_safe_string(merged.get(key_variant, "")).is_empty():
			merged[key_variant] = incoming[key_variant]
	return merged

func _programmer_dictionary_by_id(records: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for record in records:
		var record_id: String = _programmer_safe_string(record.get("id", record.get("profile_id", ""))).strip_edges()
		if not record_id.is_empty():
			result[record_id] = record
	return result

func _programmer_sorted_records(record_map: Dictionary) -> Array[Dictionary]:
	var keys: Array = record_map.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key_variant in keys:
		var record: Dictionary = _programmer_as_dictionary(record_map.get(key_variant, {}))
		if not record.is_empty():
			result.append(record)
	return result

func _programmer_find_record_index(records: Array[Dictionary], record_id: String) -> int:
	var normalized_id: String = record_id.strip_edges()
	if normalized_id.is_empty():
		return -1
	for index in range(records.size()):
		var record: Dictionary = records[index]
		if _programmer_safe_string(record.get("id", record.get("profile_id", ""))).strip_edges() == normalized_id:
			return index
	return -1


func show_repair_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	app_screen_mode = AppScreenMode.REPAIR_PLACEHOLDER
	_hide_all_app_screens()
	if repair_menu_root != null and is_instance_valid(repair_menu_root):
		repair_menu_root.queue_free()
	repair_menu_root = _build_fullscreen_root("RepairMenuRoot")
	add_child(repair_menu_root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe_margin: int = int(_get_safe_margin())
	margin.add_theme_constant_override("margin_left", safe_margin)
	margin.add_theme_constant_override("margin_right", safe_margin)
	margin.add_theme_constant_override("margin_top", safe_margin)
	margin.add_theme_constant_override("margin_bottom", safe_margin)
	repair_menu_root.add_child(margin)
	var panel := PanelContainer.new()
	_apply_panel_style(panel, true)
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var workshop_button := _create_menu_button("Workshop", Callable(), Vector2(180, MENU_BACK_BUTTON_SIZE.y))
	_set_menu_top_button_height(workshop_button)
	workshop_button.disabled = true
	tabs.add_child(workshop_button)
	var service_button := _create_menu_button("Service Center", Callable(self, "_on_repair_service_tab_pressed"), Vector2(180, MENU_BACK_BUTTON_SIZE.y), "primary")
	_set_menu_top_button_height(service_button)
	service_button.tooltip_text = "Current tab"
	tabs.add_child(service_button)
	var tabs_spacer := Control.new()
	tabs_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(tabs_spacer)
	tabs.add_child(_create_menu_button("Back", Callable(self, "_on_repair_back_pressed"), Vector2(120, MENU_TOP_BUTTON_HEIGHT)))
	root.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var rows_vbox := VBoxContainer.new()
	rows_vbox.name = "RepairRowsVBox"
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(rows_vbox)
	_refresh_repair_menu()
	_assert_single_active_major_screen()

func _refresh_repair_menu() -> void:
	if repair_menu_root == null:
		return
	var rows_vbox: VBoxContainer = repair_menu_root.find_child("RepairRowsVBox", true, false)
	if rows_vbox == null:
		return
	for child in rows_vbox.get_children():
		child.queue_free()
	var broken_modules: Array = []
	if bipob.has_method("get_broken_modules_for_repair"):
		broken_modules = bipob.get_broken_modules_for_repair()
	var damaged_bipobs: Array = []
	if bipob.has_method("get_damaged_bipobs_for_repair"):
		damaged_bipobs = bipob.get_damaged_bipobs_for_repair()
	for module in broken_modules:
		rows_vbox.add_child(_create_repair_module_row(module))
	for row in damaged_bipobs:
		rows_vbox.add_child(_create_repair_bipob_row(row))
	if broken_modules.is_empty() and damaged_bipobs.is_empty():
		var empty_state := Label.new()
		empty_state.text = "No damaged Bipops or modules."
		_apply_label_style(empty_state, true, false)
		rows_vbox.add_child(empty_state)

func _create_repair_bipob_card(bipob_data: Dictionary, selected: bool) -> Button:
	var profile_id := String(bipob_data.get("profile_id", ""))
	var current_armor: int = int(bipob_data.get("current_armor", 0))
	var max_armor: int = int(bipob_data.get("max_armor", 0))
	if bipob != null and bipob.has_method("get_bipob_current_armor"):
		current_armor = int(bipob.get_bipob_current_armor(profile_id))
	if bipob != null and bipob.has_method("get_bipob_max_armor"):
		max_armor = int(bipob.get_bipob_max_armor(profile_id))
	var button := Button.new()
	button.custom_minimum_size = REPAIR_BIPOB_CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.36, 0.11, 0.15, 0.95) if current_armor < max_armor else UI_COLOR_PANEL, UI_COLOR_BORDER_DIM))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.55, 0.20, 0.23, 1.0), UI_COLOR_BORDER))
	button.add_theme_stylebox_override("pressed", _make_button_style(UI_COLOR_SELECTED if selected else Color(0.55, 0.20, 0.23, 1.0), UI_COLOR_BORDER))
	button.text = "%s\nArmor: %d / %d" % [String(bipob_data.get("name", "Bipob")), current_armor, max_armor]
	return button

func _create_repair_module_row(module: BipobModule) -> Control:
	var row: BoxContainer = null
	if _is_small_viewport():
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var panel := PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)
	var card := _create_storage_module_card(module, -1, false)
	row.add_child(card)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = bipob.get_module_display_name(module)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(title)
	info.add_child(title)
	var status := Label.new()
	status.text = "Status: %s" % String(module.status)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(status, true, false)
	info.add_child(status)
	row.add_child(info)
	var cost := Label.new()
	cost.text = "Cost: 0"
	_apply_label_style(cost, false, true)
	row.add_child(cost)
	var repair_btn := _create_menu_button("Repair", Callable(self, "_on_repair_module_row_pressed").bind(module), Vector2(120, 38), "primary")
	row.add_child(repair_btn)
	return panel

func _create_repair_bipob_row(bipob_data: Dictionary) -> Control:
	var row: BoxContainer = null
	if _is_small_viewport():
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var panel := PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)
	row.add_child(_create_repair_bipob_card(bipob_data, false))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = String(bipob_data.get("name", "Bipob"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(name_label)
	info.add_child(name_label)
	var profile_id := String(bipob_data.get("profile_id", ""))
	var current_armor: int = int(bipob_data.get("current_armor", 0))
	var max_armor: int = int(bipob_data.get("max_armor", 0))
	if bipob != null and bipob.has_method("get_bipob_current_armor"):
		current_armor = int(bipob.get_bipob_current_armor(profile_id))
	if bipob != null and bipob.has_method("get_bipob_max_armor"):
		max_armor = int(bipob.get_bipob_max_armor(profile_id))
	var armor_label := Label.new()
	armor_label.text = "Armor: %d / %d" % [current_armor, max_armor]
	_apply_label_style(armor_label, true, false)
	info.add_child(armor_label)
	row.add_child(info)
	var cost := Label.new()
	cost.text = "Cost: 0"
	_apply_label_style(cost, false, true)
	row.add_child(cost)
	var repair_btn := _create_menu_button("Repair", Callable(self, "_on_repair_bipob_row_pressed").bind(bipob_data), Vector2(120, 38), "primary")
	row.add_child(repair_btn)
	return panel

func _on_repair_service_tab_pressed() -> void:
	# Active tab placeholder for current screen.
	pass

func _on_repair_module_row_pressed(module: BipobModule) -> void:
	if bipob.has_method("repair_module"):
		bipob.repair_module(module)
	update_box_status()
	_refresh_repair_menu()

func _on_repair_bipob_row_pressed(bipob_data: Dictionary) -> void:
	if bipob.has_method("repair_bipob"):
		bipob.repair_bipob(bipob_data)
	update_box_status()
	_refresh_repair_menu()

func _on_repair_back_pressed() -> void:
	if repair_menu_root != null and is_instance_valid(repair_menu_root):
		repair_menu_root.queue_free()
		repair_menu_root = null
	show_center_screen()

func _on_placeholder_back_pressed() -> void:
	match placeholder_return_screen_mode:
		AppScreenMode.GAMEPLAY:
			_hide_all_app_screens()
			_apply_runtime_hud_layout()
			_set_gameplay_visible(true)
			call_deferred("_attach_runtime_gameplay_view")
			app_screen_mode = AppScreenMode.GAMEPLAY
		AppScreenMode.MAIN_MENU:
			show_main_menu_screen()
		AppScreenMode.CENTER:
			show_center_screen()
		_:
			show_center_screen()
	placeholder_return_screen_mode = AppScreenMode.CENTER

func _on_tasks_tab_pressed(tab_name: String) -> void:
	tasks_current_tab = tab_name
	if tasks_current_tab == "Career" and tasks_selected_career_index < 0:
		tasks_selected_career_index = 0
	_refresh_tasks_content()

func _on_tasks_career_selected(index: int) -> void:
	tasks_selected_career_index = index
	_refresh_tasks_content()

func _on_tasks_start_pressed() -> void:
	if tasks_current_tab == "Dev":
		_on_dev_start_task_test_pressed()
		return
	# TODO(BIB-453): bind each task to a dedicated mission profile when mission registry is ready.
	start_selected_task_mission()

func _build_tasks_dev_content() -> void:
	var card: Button = Button.new()
	card.text = "TASK TEST\nTest room for mechanics and validation checks.\nMission ID: mission_10"
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.custom_minimum_size = Vector2(0, 86)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.disabled = true
	_apply_menu_button_theme(card)
	tasks_list_container.add_child(card)
	if tasks_title_label != null:
		tasks_title_label.text = "Dev Tasks"
	if tasks_difficulty_label != null:
		tasks_difficulty_label.text = "Scope: Developer"
	if tasks_reward_label != null:
		tasks_reward_label.text = "Rewards: Disabled"
	if tasks_main_goal_label != null:
		tasks_main_goal_label.text = "Use this panel to start TASK TEST and run read-only developer validation suites."
	if tasks_extra_goal_label != null:
		tasks_extra_goal_label.text = "- Start TASK TEST mission\n- Run validation suites"
	if tasks_warnings_label != null:
		tasks_warnings_label.text = "Dev-only tools. Validation is read-only."
	if tasks_report_label != null:
		tasks_report_label.text = "TASK TEST does not use Career completion/claim flow."
	if tasks_claim_button != null:
		tasks_claim_button.visible = false
	if tasks_start_button != null:
		tasks_start_button.visible = true
		tasks_start_button.disabled = false
		tasks_start_button.text = "Start TASK TEST"
	if tasks_actions_row != null:
		for child in tasks_actions_row.get_children():
			if child == tasks_start_button or child == tasks_claim_button:
				continue
			child.queue_free()
		var validation_all_button: Button = _create_menu_button("Run Validation: All", Callable(self, "_on_dev_validation_all_pressed"), Vector2(200, 34))
		tasks_actions_row.add_child(validation_all_button)
		var validation_task_test_button: Button = _create_menu_button("Run Validation: Task Test", Callable(self, "_on_dev_validation_task_test_pressed"), Vector2(230, 34))
		tasks_actions_row.add_child(validation_task_test_button)
		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tasks_actions_row.add_child(spacer)
	_set_dev_validation_output("Ready. Select a validation suite to display output.")

func _on_dev_start_task_test_pressed() -> void:
	if bipob == null or not bipob.has_method("start_task_test_session"):
		_set_dev_validation_output("Developer mission start unavailable: BipobController is not ready.")
		return
	bipob.call("start_task_test_session")
	_enter_gameplay_screen_without_starting_mission()

func _on_dev_validation_all_pressed() -> void:
	_set_dev_validation_output(_get_dev_validation_text_for_suite("all"))

func _on_dev_validation_task_test_pressed() -> void:
	_set_dev_validation_output(_get_dev_validation_text_for_suite("task_test"))

func _get_dev_validation_text_for_suite(suite_id: String) -> String:
	if bipob == null or not bipob.has_method("get_developer_validation_suite_text"):
		return "Developer validation unavailable: MissionManager is not ready."
	return String(bipob.call("get_developer_validation_suite_text", suite_id))

func _set_dev_validation_output(text: String) -> void:
	if tasks_dev_output_scroll != null:
		tasks_dev_output_scroll.visible = tasks_current_tab == "Dev"
	if tasks_dev_output_label != null:
		tasks_dev_output_label.visible = tasks_current_tab == "Dev"
		tasks_dev_output_label.text = text

func _on_tasks_claim_reward_pressed() -> void:
	var mission: Dictionary = get_selected_task_mission()
	var mission_id: int = int(mission.get("id", 0))
	if mission_id <= 0:
		return
	_confirm_claim_reward(mission_id)

func _confirm_claim_reward(mission_id: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Claim Reward"
	dialog.dialog_text = "If you claim the reward, this mission can no longer be replayed. Claim reward now?"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		_claim_mission_reward(mission_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(540, 180))

func _claim_mission_reward(mission_id: int) -> void:
	var progress: Dictionary = _get_mission_progress(mission_id)
	progress["completed"] = true
	progress["claimed"] = true
	if String(progress.get("reward_claimed_text", "")).is_empty():
		progress["reward_claimed_text"] = "Reward claimed (TBD)"
	# TODO(BIB-535): hook actual reward grant system.
	mission_progress[mission_id] = progress
	_refresh_tasks_content()

func _on_mission_result_restart_pressed() -> void:
	_deactivate_map_constructor_mode()
	if not _ensure_gameplay_runtime_created():
		return
	var restart_mission_id: int = tasks_selected_mission_id
	if bipob != null:
		restart_mission_id = int(bipob.current_mission_index)
	if bipob != null:
		bipob.current_mission_index = restart_mission_id
		if bipob.has_method("start_mission"):
			bipob.start_mission(restart_mission_id, true)
		elif bipob.has_method("restart_current_mission"):
			bipob.restart_current_mission()
	_enter_gameplay_screen_without_starting_mission()
	call_deferred("_sync_runtime_bipob_visual_state")

func _on_mission_result_center_pressed() -> void:
	if not _can_return_to_center_after_result(last_mission_success):
		show_hint("Beacon Module required")
		return
	show_center_screen()

func _on_mission_result_main_menu_pressed() -> void:
	show_main_menu_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_map_constructor_mode()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		if map_constructor_state.map_constructor_mode_active:
			map_constructor_state.map_constructor_validation_overlay_visible = not map_constructor_state.map_constructor_validation_overlay_visible
			show_hint("Validation Overlay: %s" % ["ON" if map_constructor_state.map_constructor_validation_overlay_visible else "OFF"])
			_refresh_map_constructor_panels()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if map_constructor_state.map_constructor_mode_active:
			_cycle_map_constructor_wall_side()
			_refresh_map_constructor_panels()
		return
	if event is InputEventMouseButton:
		if _handle_runtime_gameplay_mouse_click(event):
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update_map_keyboard_pan(delta)
	_process_map_constructor_edge_scroll(delta)
	_process_runtime_interaction_feedback(delta)
	refresh_object_info_position()


func _process_runtime_interaction_feedback(delta: float) -> void:
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	RuntimeNotifications.process_runtime_notification_timer(self, delta)
	if bipob == null:
		return
	_refresh_runtime_interaction_controls()
	var target_data := _get_runtime_interaction_target_data()
	var target_object: Dictionary = Dictionary(target_data.get("target_object", {}))
	var actions: Array = Array(target_data.get("actions", []))
	var physical_actions: Array[String] = RuntimeInteractionPanel.get_physical_actions(actions)
	var has_interactable := not target_object.is_empty() and not physical_actions.is_empty()
	if has_interactable and not runtime_interaction_mode_active and runtime_action_button != null:
		_apply_selected_pulse(runtime_action_button)
	var has_actions_left := int(bipob.actions_left) > 0
	var manipulator_blocked := has_interactable and _is_runtime_interaction_manipulator_blocked(target_object, physical_actions)
	var pulse_alpha: float = 0.72 + 0.28 * abs(sin(float(Time.get_ticks_msec()) / 170.0))
	if runtime_action_button != null:
		if manipulator_blocked:
			runtime_action_button.modulate = Color(1.0, 0.38, 0.38, 1.0)
		elif has_interactable and has_actions_left and not runtime_interaction_mode_active:
			runtime_action_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			_clear_selected_pulse(runtime_action_button)
	if runtime_end_turn_button != null:
		if bipob != null and int(bipob.actions_left) <= 0:
			runtime_end_turn_button.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)
		else:
			runtime_end_turn_button.modulate = Color.WHITE

# -----------------------------------------------------------------------------
# Map Constructor root
# -----------------------------------------------------------------------------

func _process_map_constructor_edge_scroll(delta: float) -> void:
	if not edge_scroll_enabled or delta <= 0.0:
		return
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	if not map_constructor_state.map_constructor_mode_active:
		return
	if field_runtime == null or not is_instance_valid(field_runtime):
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var window: Window = get_window()
	if window != null and not window.has_focus():
		return
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	var viewport_size: Vector2 = viewport_rect.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	if not viewport_rect.has_point(mouse_pos):
		return
	if _is_mouse_over_map_constructor_ui_panel():
		return
	var scroll_dir: Vector2 = Vector2.ZERO
	if mouse_pos.x <= viewport_rect.position.x + edge_scroll_margin_px:
		scroll_dir.x -= 1.0
	elif mouse_pos.x >= viewport_rect.end.x - edge_scroll_margin_px:
		scroll_dir.x += 1.0
	if mouse_pos.y <= viewport_rect.position.y + edge_scroll_margin_px:
		scroll_dir.y -= 1.0
	elif mouse_pos.y >= viewport_rect.end.y - edge_scroll_margin_px:
		scroll_dir.y += 1.0
	if scroll_dir == Vector2.ZERO:
		return
	_pan_runtime_map(scroll_dir.normalized(), edge_scroll_speed * delta)

func _update_map_keyboard_pan(delta: float) -> void:
	if delta <= 0.0:
		return
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	if field_runtime == null or not is_instance_valid(field_runtime):
		return
	var window: Window = get_window()
	if window != null and not window.has_focus():
		return
	if _is_text_input_focused() or _is_blocking_modal_open():
		return
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if direction == Vector2.ZERO:
		return
	_pan_runtime_map(direction.normalized(), map_camera_scroll_speed * delta)

func _pan_runtime_map(camera_direction: Vector2, distance: float) -> void:
	if camera_direction == Vector2.ZERO or distance <= 0.0:
		return
	if field_runtime == null or not is_instance_valid(field_runtime):
		return
	var field_node: Node2D = field_runtime as Node2D
	if field_node == null:
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var movement: Vector2 = -camera_direction * distance
	var unclamped_position: Vector2 = field_node.position + movement
	field_node.position = _get_clamped_runtime_field_position(unclamped_position, viewport_size)
	_sync_bipob_visual_to_runtime_map_position()

func _sync_bipob_visual_to_runtime_map_position() -> void:
	if bipob == null or field_runtime == null:
		return
	if not is_instance_valid(bipob) or not is_instance_valid(field_runtime):
		return
	if not bipob.has_method("get_visual_world_position_for_grid_cell"):
		return
	var use_iso_visual_position: bool = false
	if bipob.has_method("should_use_isometric_visual_position"):
		use_iso_visual_position = bool(bipob.call("should_use_isometric_visual_position"))
	var visual_position_variant: Variant = bipob.call("get_visual_world_position_for_grid_cell", bipob.grid_position)
	if not (visual_position_variant is Vector2):
		return
	var visual_position: Vector2 = visual_position_variant
	if use_iso_visual_position:
		bipob.position = visual_position
		bipob.z_index = bipob.grid_position.x + bipob.grid_position.y + 10
	else:
		bipob.global_position = field_runtime.global_position + visual_position

func _is_text_input_focused() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	var focused: Control = viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _is_blocking_modal_open() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	for child in viewport.get_children():
		if child is Window and child != get_window() and (child as Window).visible:
			return true
	return _has_visible_blocking_modal_child(self)

func _has_visible_blocking_modal_child(node: Node) -> bool:
	if node == null:
		return false
	for child in node.get_children():
		if child is Popup and (child as Popup).visible:
			return true
		if child is Window and child != get_window() and (child as Window).visible:
			return true
		if _has_visible_blocking_modal_child(child):
			return true
	return false

func _is_mouse_over_map_constructor_ui_panel() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return _is_control_in_map_constructor_panel(hovered, runtime_map_constructor_palette_panel) or _is_control_in_map_constructor_panel(hovered, runtime_map_constructor_inspector_panel) or _is_control_in_map_constructor_panel(hovered, runtime_map_constructor_place_confirm_panel) or _is_control_in_map_constructor_panel(hovered, runtime_map_constructor_overview_hud_panel)

func _is_control_in_map_constructor_panel(control: Control, panel: Control) -> bool:
	if control == null or panel == null or not is_instance_valid(panel):
		return false
	return panel == control or panel.is_ancestor_of(control)

func _get_clamped_runtime_field_position(unclamped_position: Vector2, viewport_size: Vector2) -> Vector2:
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return unclamped_position
	var renderer: RoomVisualRenderer = renderer_node as RoomVisualRenderer
	var map_width: int = field_runtime.get_map_width()
	var map_height: int = field_runtime.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return unclamped_position
	var corners: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(map_width - 1, 0),
		Vector2i(0, map_height - 1),
		Vector2i(map_width - 1, map_height - 1)
	]
	var half_size: Vector2 = renderer.get_iso_tile_half_size()
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	for corner in corners:
		var iso_center: Vector2 = renderer.grid_to_iso(corner)
		min_x = minf(min_x, iso_center.x - half_size.x)
		max_x = maxf(max_x, iso_center.x + half_size.x)
		min_y = minf(min_y, iso_center.y - half_size.y - renderer.iso_wall_height)
		max_y = maxf(max_y, iso_center.y + half_size.y)
	var bounds_margin: float = maxf(map_scroll_bounds_margin_px, 0.0)
	var min_field_x: float = -bounds_margin - max_x
	var max_field_x: float = viewport_size.x + bounds_margin - min_x
	var min_field_y: float = -bounds_margin - max_y
	var max_field_y: float = viewport_size.y + bounds_margin - min_y
	var clamped_x: float = unclamped_position.x
	var clamped_y: float = unclamped_position.y
	if min_field_x <= max_field_x:
		clamped_x = clampf(unclamped_position.x, min_field_x, max_field_x)
	else:
		clamped_x = (min_field_x + max_field_x) * 0.5
	if min_field_y <= max_field_y:
		clamped_y = clampf(unclamped_position.y, min_field_y, max_field_y)
	else:
		clamped_y = (min_field_y + max_field_y) * 0.5
	return Vector2(clamped_x, clamped_y)

func _is_task_test_runtime_active() -> bool:
	return app_screen_mode == AppScreenMode.GAMEPLAY and bipob != null and int(bipob.current_mission_index) == 10

func _toggle_map_constructor_mode() -> void:
	if not _is_task_test_runtime_active():
		return
	if map_constructor_state.map_constructor_mode_active:
		_deactivate_map_constructor_mode()
		show_hint("Map Constructor Mode Off")
		return
	map_constructor_state.map_constructor_mode_active = true
	map_constructor_state.map_constructor_validation_overlay_visible = true
	_request_map_constructor_overlay_refresh()
	if bipob != null:
		bipob.map_constructor_input_blocked = true
	show_hint("Map Constructor Mode")
	MapConstructorScreenRef.set_visible(self, true)
	_refresh_runtime_mission_objective_label()
	_refresh_map_constructor_panels()

func _deactivate_map_constructor_mode() -> void:
	map_constructor_state.map_constructor_mode_active = false
	map_constructor_state.selected_map_constructor_prefab_id = ""
	map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
	map_constructor_state.selected_map_constructor_wall_side = ""
	map_constructor_state.selected_map_constructor_mounting_mode = "stationary"
	map_constructor_state.available_map_constructor_wall_sides.clear()
	map_constructor_state.map_constructor_picker_entity_kind = ""
	map_constructor_state.map_constructor_picker_entity_id = ""
	map_constructor_state.map_constructor_picker_field_name = ""
	map_constructor_state.map_constructor_marker_mode = ""

	if bipob != null:
		bipob.map_constructor_input_blocked = false

	_clear_map_constructor_overview_hud()
	map_constructor_state.map_constructor_overview_hud_visible = false

	MapConstructorScreenRef.clear(self)
	MapConstructorScreenRef.set_visible(self, false)

	_clear_map_constructor_pending_placement()
	_clear_map_constructor_preview_cell()
	_clear_map_constructor_wall_mounted_selection()
	_clear_map_constructor_link_target()
	map_constructor_state.map_constructor_multi_selected_entities.clear()
	_clear_map_constructor_batch_preview_state()
	_refresh_runtime_mission_objective_label()

func _clear_map_constructor_wall_mounted_selection() -> void:
	if field_runtime == null:
		return
	var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer != null and renderer.has_method("clear_selected_wall_mounted_object"):
		renderer.call("clear_selected_wall_mounted_object")

func _set_map_constructor_wall_mounted_selection(anchor_cell: Vector2i, attached_wall_cell: Vector2i, object_id: String) -> void:
	if field_runtime == null:
		return
	var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer != null and renderer.has_method("set_selected_wall_mounted_object"):
		renderer.call("set_selected_wall_mounted_object", anchor_cell, attached_wall_cell, object_id)

func _clear_map_constructor_preview_cell() -> void:
	if field_runtime == null:
		return
	var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer != null and renderer.has_method("set_map_constructor_preview_cell"):
		renderer.call("set_map_constructor_preview_cell", Vector2i(-1, -1))

func _update_map_constructor_preview_for_cell(cell: Vector2i) -> Dictionary:
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("can_place_map_constructor_prefab"):
		return {}
	var check: Dictionary = mission_manager_runtime.call("can_place_map_constructor_prefab", map_constructor_state.selected_map_constructor_prefab_id, cell, map_constructor_state.selected_map_constructor_wall_side, map_constructor_state.selected_map_constructor_mounting_mode)
	map_constructor_state.available_map_constructor_wall_sides.clear()
	for side_variant in _safe_ui_array(check.get("available_wall_sides", [])):
		map_constructor_state.available_map_constructor_wall_sides.append(String(side_variant))
	if map_constructor_state.selected_map_constructor_wall_side.is_empty() and not map_constructor_state.available_map_constructor_wall_sides.is_empty():
		map_constructor_state.selected_map_constructor_wall_side = map_constructor_state.available_map_constructor_wall_sides[0]
	elif not map_constructor_state.selected_map_constructor_wall_side.is_empty() and not map_constructor_state.available_map_constructor_wall_sides.has(map_constructor_state.selected_map_constructor_wall_side):
		if not map_constructor_state.available_map_constructor_wall_sides.is_empty():
			map_constructor_state.selected_map_constructor_wall_side = map_constructor_state.available_map_constructor_wall_sides[0]
		else:
			map_constructor_state.selected_map_constructor_wall_side = ""
	if field_runtime != null:
		var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
		if renderer != null and renderer.has_method("set_map_constructor_wall_mounted_preview") and String(check.get("placement_mode", "")) == "wall_mounted":
			var attached_wall_cell: Vector2i = Vector2i(-1, -1)
			if mission_manager_runtime.has_method("_deserialize_cell_key"):
				attached_wall_cell = _safe_ui_vector2i(mission_manager_runtime.call("_deserialize_cell_key", String(check.get("attached_wall_cell", ""))))
			renderer.call("set_map_constructor_wall_mounted_preview", cell, attached_wall_cell, String(check.get("wall_side", "")), not bool(check.get("ok", false)))
		elif renderer != null and renderer.has_method("set_map_constructor_preview_cell"):
			renderer.call("set_map_constructor_preview_cell", cell)
	return check

func _normalize_map_constructor_wall_side(side_id: String) -> String:
	return MapConstructorFloorWallControls.normalize_wall_side(side_id)

func _get_map_constructor_wall_side_label(side_id: String) -> String:
	return MapConstructorFloorWallControls.get_wall_side_label(side_id)

func _create_map_constructor_wall_side_picker(placement_mode: String) -> Control:
	return MapConstructorFloorWallControls.create_wall_side_picker(self, placement_mode)

func _cycle_map_constructor_wall_side() -> void:
	if map_constructor_state.available_map_constructor_wall_sides.size() <= 1:
		show_hint("Wall side: no alternatives.")
		return
	var current_index: int = map_constructor_state.available_map_constructor_wall_sides.find(map_constructor_state.selected_map_constructor_wall_side)
	if current_index < 0:
		current_index = 0
	map_constructor_state.selected_map_constructor_wall_side = String(map_constructor_state.available_map_constructor_wall_sides[(current_index + 1) % map_constructor_state.available_map_constructor_wall_sides.size()])
	if map_constructor_state.pending_map_constructor_cell.x >= 0 and map_constructor_state.pending_map_constructor_cell.y >= 0:
		_update_map_constructor_preview_for_cell(map_constructor_state.pending_map_constructor_cell)
	show_hint("Wall side: %s" % map_constructor_state.selected_map_constructor_wall_side)


func refresh_object_info_position() -> void:
	RuntimeObjectHudRef.refresh_position(self)

func _refresh_runtime_object_info() -> void:
	RuntimeObjectHudRef.refresh(self)

func _hide_runtime_object_info_hud() -> void:
	RuntimeObjectHudRef.hide(self)

func _clear_runtime_object_info_hud() -> void:
	RuntimeObjectHudRef.clear(self)

func _runtime_object_info_value(object_data: Dictionary, keys: Array[String], fallback: String = "") -> String:
	return RuntimeObjectHudRef.info_value(self, object_data, keys, fallback)

func _runtime_object_info_type_label(object_data: Dictionary) -> String:
	return RuntimeObjectHudRef.info_type_label(self, object_data)

func _runtime_door_type_label(object_data: Dictionary) -> String:
	return RuntimeObjectHudRef.door_type_label(self, object_data)

func _runtime_access_type_label(value: String) -> String:
	return RuntimeObjectHudRef.access_type_label(value)

func _show_runtime_object_info_hud(cell: Vector2i) -> void:
	RuntimeObjectHudRef.show(self, cell)

func _handle_runtime_gameplay_mouse_click(event: InputEventMouseButton) -> bool:
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return false
	if event == null or not event.pressed:
		return false
	if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
		return false
	if event.button_index == MOUSE_BUTTON_RIGHT and map_constructor_state.map_constructor_mode_active:
		_clear_all_map_constructor_selection_state()
		MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)
		return true
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return false
	if field_runtime == null or bipob == null:
		return false
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return false
	var renderer: RoomVisualRenderer = renderer_node
	var local_position: Vector2 = renderer.to_local(event.global_position)
	var cell: Vector2i = renderer.get_cell_at_iso_visual_position(local_position)
	if cell.x < 0 or cell.y < 0:
		return false
	if event.button_index == MOUSE_BUTTON_LEFT:
		_hide_runtime_object_info_hud()
		if map_constructor_state.map_constructor_mode_active:
			_handle_map_constructor_left_click(cell)
		else:
			bipob.handle_grid_cell_left_click(cell)
	else:
		if map_constructor_state.map_constructor_mode_active:
			_clear_all_map_constructor_selection_state()
			MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)
		else:
			bipob.handle_grid_cell_right_click(cell)
			_show_runtime_object_info_hud(cell)
	var action_cell: Vector2i = Vector2i(-1, -1)
	if event.button_index == MOUSE_BUTTON_LEFT and bipob.grid_position.distance_to(cell) <= 1:
		action_cell = cell
	renderer.set_iso_mouse_selection_visuals(bipob.selected_grid_cell, bipob.selected_route_cells, action_cell)
	if map_constructor_state.map_constructor_mode_active and map_constructor_state.map_constructor_pending_place_cell.x < 0:
		renderer.set_map_constructor_preview_cell(map_constructor_state.pending_map_constructor_cell)
	update_status()
	update_diagnostic_status()
	update_box_status()
	call_deferred("_sync_runtime_bipob_visual_state")
	return true

func _handle_map_constructor_left_click(cell: Vector2i) -> void:
	if map_constructor_state.selected_map_constructor_prefab_id.is_empty():
		if map_constructor_state.map_constructor_marker_mode == "start" or map_constructor_state.map_constructor_marker_mode == "exit":
			if mission_manager_runtime == null:
				return
			var marker_result: Dictionary = {}
			if map_constructor_state.map_constructor_marker_mode == "start" and mission_manager_runtime.has_method("set_map_constructor_start_marker"):
				marker_result = mission_manager_runtime.call("set_map_constructor_start_marker", cell)
			elif map_constructor_state.map_constructor_marker_mode == "exit" and mission_manager_runtime.has_method("set_map_constructor_exit_marker"):
				marker_result = mission_manager_runtime.call("set_map_constructor_exit_marker", cell)
			show_hint(String(marker_result.get("message", "Marker set.")))
			map_constructor_state.map_constructor_marker_mode = ""
			_refresh_map_constructor_panels()
			return
		_clear_map_constructor_pending_placement()
		_show_map_constructor_inspector(cell)
		MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)
		return
	_start_map_constructor_pending_placement(map_constructor_state.selected_map_constructor_prefab_id, cell)

func _clear_map_constructor_pending_placement() -> void:
	map_constructor_state.reset_pending_placement()
	if runtime_map_constructor_place_confirm_panel != null and is_instance_valid(runtime_map_constructor_place_confirm_panel):
		runtime_map_constructor_place_confirm_panel.queue_free()
	runtime_map_constructor_place_confirm_panel = null

func _start_map_constructor_pending_placement(prefab_id: String, cell: Vector2i) -> void:
	map_constructor_state.map_constructor_pending_place_prefab_id = prefab_id
	map_constructor_state.map_constructor_pending_place_cell = cell
	map_constructor_state.map_constructor_pending_place_rotation = 0
	map_constructor_state.pending_map_constructor_cell = cell
	var preview_check: Dictionary = _update_map_constructor_preview_for_cell(cell)
	var preview_message: String = String(preview_check.get("message", "Preview: %s at %s" % [prefab_id, str(cell)]))
	if String(preview_check.get("placement_mode", "")) == "wall_mounted":
		preview_message += " Side: %s" % String(preview_check.get("wall_side", ""))
	show_hint(preview_message)
	_show_map_constructor_place_confirm_panel()
	MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)

func _rotate_map_constructor_pending_placement(clockwise: bool) -> void:
	if map_constructor_state.map_constructor_pending_place_cell.x < 0 or map_constructor_state.map_constructor_pending_place_prefab_id.is_empty():
		return
	map_constructor_state.map_constructor_pending_place_rotation = posmod(map_constructor_state.map_constructor_pending_place_rotation + (90 if clockwise else -90), 360)
	_update_map_constructor_preview_for_cell(map_constructor_state.map_constructor_pending_place_cell)
	_show_map_constructor_place_confirm_panel()
	show_hint("Preview rotation: %d°" % map_constructor_state.map_constructor_pending_place_rotation)
	_request_map_constructor_overlay_refresh()

func _confirm_map_constructor_pending_placement() -> void:
	if map_constructor_state.map_constructor_pending_place_prefab_id.is_empty() or map_constructor_state.map_constructor_pending_place_cell.x < 0:
		return
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("place_map_constructor_prefab"):
		return
	var prefab_id: String = map_constructor_state.map_constructor_pending_place_prefab_id
	var place_cell: Vector2i = map_constructor_state.map_constructor_pending_place_cell
	var visual_rotation: int = map_constructor_state.map_constructor_pending_place_rotation
	var result: Dictionary = MapConstructorActions.apply_prefab_placement(self, prefab_id, place_cell, {"wall_side": map_constructor_state.selected_map_constructor_wall_side, "rotation": visual_rotation, "mounting_mode": map_constructor_state.selected_map_constructor_mounting_mode})
	show_hint(String(result.get("message", "Placement done.")))
	if bool(result.get("ok", false)):
		_mark_map_constructor_prefab_recent(prefab_id)
		_clear_map_constructor_pending_placement()
		map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
		_clear_map_constructor_preview_cell()
		MapConstructorRefreshCoordinatorRef.request_field_visual_refresh(self)
		var object_id: String = String(result.get("object_id", ""))
		if not object_id.is_empty():
			var entity_kind: String = "item" if bool(result.get("is_item", false)) else "world_object"
			_show_map_constructor_inspector(place_cell, entity_kind, object_id)
	MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)

func _cancel_map_constructor_pending_placement() -> void:
	_clear_map_constructor_pending_placement()
	map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
	_clear_map_constructor_preview_cell()
	MapConstructorRefreshCoordinatorRef.refresh_panels_and_overlay(self)
	show_hint("Placement cancelled.")

func _show_map_constructor_place_confirm_panel() -> void:
	if runtime_hud_root == null or not is_instance_valid(runtime_hud_root):
		_ensure_runtime_hud_root()
	if runtime_map_constructor_place_confirm_panel != null and is_instance_valid(runtime_map_constructor_place_confirm_panel):
		runtime_map_constructor_place_confirm_panel.queue_free()
	runtime_map_constructor_place_confirm_panel = null
	if map_constructor_state.map_constructor_pending_place_cell.x < 0 or map_constructor_state.map_constructor_pending_place_prefab_id.is_empty() or field_runtime == null:
		return
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return
	var renderer: RoomVisualRenderer = renderer_node
	var panel := PanelContainer.new()
	panel.z_index = Z_MAP_CONSTRUCTOR_UI + 4
	panel.z_as_relative = false
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_ACCENT, 1, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	for spec in [
		{"label":"↺ Left", "tip":"Rotate preview counter-clockwise", "action":"left"},
		{"label":"↻ Right", "tip":"Rotate preview clockwise", "action":"right"},
		{"label":"Place", "tip":"Confirm placement", "action":"place"},
		{"label":"Cancel", "tip":"Cancel pending placement", "action":"cancel"}
	]:
		var button := Button.new()
		button.text = String(spec.get("label", ""))
		button.tooltip_text = String(spec.get("tip", ""))
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var action_id: String = String(spec.get("action", ""))
		button.pressed.connect(func() -> void:
			match action_id:
				"left":
					_rotate_map_constructor_pending_placement(false)
				"right":
					_rotate_map_constructor_pending_placement(true)
				"place":
					_confirm_map_constructor_pending_placement()
				"cancel":
					_cancel_map_constructor_pending_placement()
		)
		row.add_child(button)
	runtime_hud_root.add_child(panel)
	runtime_map_constructor_place_confirm_panel = panel
	var world_pos: Vector2 = renderer.to_global(renderer.grid_to_iso(map_constructor_state.map_constructor_pending_place_cell)) + Vector2(-120.0, 38.0)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.reset_size()
	var panel_size: Vector2 = panel.get_combined_minimum_size()
	panel.position = Vector2(clampf(world_pos.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0)), clampf(world_pos.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 8.0)))

func _clear_all_map_constructor_selection_state() -> void:
	map_constructor_state.selected_map_constructor_prefab_id = ""
	map_constructor_state.selected_map_constructor_entity_kind = ""
	map_constructor_state.selected_map_constructor_entity_id = ""
	map_constructor_state.selected_map_constructor_entity_cell = Vector2i(-1, -1)
	map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
	map_constructor_state.selected_map_constructor_wall_side = ""
	map_constructor_state.available_map_constructor_wall_sides.clear()
	map_constructor_state.map_constructor_picker_entity_kind = ""
	map_constructor_state.map_constructor_picker_entity_id = ""
	map_constructor_state.map_constructor_picker_field_name = ""
	map_constructor_state.map_constructor_marker_mode = ""
	map_constructor_state.map_constructor_selected_issue_id = ""
	map_constructor_state.map_constructor_cleanup_preview.clear()
	map_constructor_state.map_constructor_cleanup_pending_apply_key = ""
	map_constructor_state.map_constructor_autofix_preview.clear()
	map_constructor_state.map_constructor_autofix_pending_apply_key = ""
	map_constructor_state.map_constructor_batch_preview.clear()
	map_constructor_state.map_constructor_batch_pending_apply_operation = ""
	map_constructor_state.map_constructor_batch_pending_apply_key = ""
	map_constructor_state.map_constructor_multi_selected_entities.clear()
	_clear_map_constructor_pending_placement()
	_clear_map_constructor_preview_cell()
	_clear_map_constructor_wall_mounted_selection()
	_clear_map_constructor_link_target()
	_clear_map_constructor_browser_selection()
	_clear_map_constructor_batch_preview_state()
	MapConstructorInspectorRef.clear(self)

func _map_constructor_prefab_matches_filters(entry: Dictionary) -> bool:
	return MapConstructorObjectPalette.prefab_matches_filters(self, entry)

func _map_constructor_prefab_matches_category_filter(prefab_id: String, category_text: String, category_filter: String) -> bool:
	return MapConstructorObjectPalette.prefab_matches_category_filter(self, prefab_id, category_text, category_filter)

func _get_map_constructor_prefab_group_name(entry: Dictionary) -> String:
	return MapConstructorObjectPalette.get_prefab_group_name(self, entry)

func _mark_map_constructor_prefab_recent(prefab_id: String) -> void:
	MapConstructorObjectPalette.mark_prefab_recent(self, prefab_id)

func _select_map_constructor_prefab(prefab_id: String) -> void:
	MapConstructorObjectPalette.select_prefab(self, prefab_id)

func _get_map_constructor_variant_string_list(value: Variant) -> Array[String]:
	return MapConstructorObjectPalette.get_variant_string_list(self, value)

func _format_map_constructor_variant_list(value: Variant, separator: String = ", ") -> String:
	return MapConstructorObjectPalette.format_variant_list(self, value, separator)

func _get_map_constructor_prefab_placeability(entry: Dictionary) -> Dictionary:
	return MapConstructorObjectPalette.get_prefab_placeability(entry)

func _get_map_constructor_prefab_preview_kind(entry: Dictionary) -> String:
	return MapConstructorObjectPalette.get_prefab_preview_kind(self, entry)

func _get_map_constructor_prefab_preview_symbol(preview_kind: String) -> String:
	return MapConstructorObjectPalette.get_prefab_preview_symbol(preview_kind)

func _get_map_constructor_prefab_preview_label(preview_kind: String) -> String:
	return MapConstructorObjectPalette.get_prefab_preview_label(preview_kind)

func _get_map_constructor_prefab_preview_color(preview_kind: String) -> Color:
	return MapConstructorObjectPalette.get_prefab_preview_color(preview_kind)

func _format_map_constructor_prefab_placeability(entry: Dictionary) -> Dictionary:
	return MapConstructorObjectPalette.format_prefab_placeability(self, entry)

func _create_map_constructor_prefab_preview(entry: Dictionary) -> Control:
	return MapConstructorObjectPalette.create_prefab_preview(self, entry)

func _create_map_constructor_prefab_card(entry: Dictionary) -> Button:
	return MapConstructorObjectPalette.create_prefab_tile(self, entry)

func _build_map_constructor_object_palette(parent: VBoxContainer) -> void:
	MapConstructorObjectPalette.build_object_palette(self, parent)

func _build_map_constructor_placed_object_rows() -> Array[Dictionary]:
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_placed_object_rows"):
		return []
	return mission_manager_runtime.call("get_map_constructor_placed_object_rows")

func _map_constructor_placed_row_matches_search(row: Dictionary) -> bool:
	var search_text: String = map_constructor_state.map_constructor_placed_search_text.strip_edges().to_lower()
	if search_text.is_empty():
		return true
	var cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
	var anchor_cell: Vector2i = _safe_ui_vector2i(row.get("anchor_floor_cell", Vector2i(-1, -1)))
	var haystack: String = "%s %s %s %s %s %d %d %d %d" % [
		String(row.get("id", "")).to_lower(),
		String(row.get("entity_kind", "")).to_lower(),
		String(row.get("type_or_prefab", "")).to_lower(),
		String(row.get("category_or_placement", "")).to_lower(),
		String(row.get("wall_side", "")).to_lower(),
		cell.x, cell.y, anchor_cell.x, anchor_cell.y
	]
	return haystack.find(search_text) >= 0

func _clear_map_constructor_browser_selection() -> void:
	map_constructor_state.selected_map_constructor_entity_kind = ""
	map_constructor_state.selected_map_constructor_entity_id = ""
	map_constructor_state.selected_map_constructor_entity_cell = Vector2i(-1, -1)

func _focus_map_constructor_cell(cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0:
		return
	show_hint("Selected object at (%d, %d)." % [cell.x, cell.y])

func _map_constructor_history_matches_filter(action_type: String) -> bool:
	var action: String = action_type.to_lower()
	match map_constructor_state.map_constructor_change_history_filter:
		"Placement":
			return action in ["place", "duplicate"]
		"Edit":
			return action in ["move", "delete", "property_update", "link_update", "side_change"]
		"Cleanup":
			return action in ["cleanup", "cleanup_undo"]
		"Auto-fix":
			return action in ["autofix", "autofix_undo"]
		"Patch":
			return action in ["patch_apply", "patch_rollback"]
		"Reset":
			return action == "reset"
		_:
			return true

func _jump_to_map_constructor_history_row(row: Dictionary) -> void:
	var entity_id: String = String(row.get("entity_id", "")).strip_edges()
	if not entity_id.is_empty() and mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		var world_entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", "world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			var world_cell: Vector2i = _safe_ui_vector2i(world_entity.get("cell", Vector2i(-1, -1)))
			_show_map_constructor_inspector(world_cell, "world_object", entity_id)
			_focus_map_constructor_cell(world_cell)
			return
		var item_entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", "item", entity_id)
		if bool(item_entity.get("ok", false)):
			var item_cell: Vector2i = _safe_ui_vector2i(item_entity.get("cell", Vector2i(-1, -1)))
			_show_map_constructor_inspector(item_cell, "item", entity_id)
			_focus_map_constructor_cell(item_cell)
			return
	var cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
	if cell.x >= 0 and cell.y >= 0:
		_show_map_constructor_inspector(cell)
		_focus_map_constructor_cell(cell)

func _map_constructor_overview_symbol_for_cell(cell_row: Dictionary) -> String:
	if bool(cell_row.get("has_selected", false)):
		return "*"
	if bool(cell_row.get("has_validation_issue", false)):
		return "!"
	if bool(cell_row.get("has_warning", false)):
		return "?"
	if bool(cell_row.get("has_expected_invalid", false)):
		return "X"
	if map_constructor_state.map_constructor_overview_show_wall_mounted and bool(cell_row.get("has_wall_mounted", false)):
		return "W"
	if map_constructor_state.map_constructor_overview_show_items and bool(cell_row.get("has_item", false)):
		return "I"
	if map_constructor_state.map_constructor_overview_show_power and bool(cell_row.get("has_power", false)):
		return "P"
	if bool(cell_row.get("has_terminal", false)):
		return "T"
	if bool(cell_row.get("has_door", false)):
		return "D"
	var tile_kind: String = String(cell_row.get("tile_kind", "unknown"))
	if tile_kind == "wall":
		return "#"
	if tile_kind == "floor":
		return "."
	return " "

func _map_constructor_overview_marker_matches_filter(marker: Dictionary) -> bool:
	var kind: String = String(marker.get("kind", ""))
	var status: String = String(marker.get("status", ""))
	match map_constructor_state.map_constructor_overview_filter:
		"Issues":
			return kind == "validation_issue" or kind == "warning"
		"Errors":
			return status == "error"
		"Warnings":
			return status == "warning"
		"Expected Invalid":
			return kind == "expected_invalid"
		"Objects":
			return kind == "object"
		"Items":
			return kind == "item"
		"Power":
			return kind == "power"
		"Terminals":
			return kind == "terminal"
		"Doors":
			return kind == "door"
		"Wall-mounted":
			return kind == "wall_mounted"
		"History":
			return kind == "history"
		"Selected":
			return kind == "selected"
		_:
			return true

func _select_map_constructor_entity_from_browser(row: Dictionary) -> void:
	var entity_kind: String = String(row.get("entity_kind", ""))
	var entity_id: String = String(row.get("id", ""))
	var row_cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
	var row_anchor_floor_cell: Vector2i = _safe_ui_vector2i(row.get("anchor_floor_cell", Vector2i(-1, -1)))
	var row_attached_wall_cell: Vector2i = _safe_ui_vector2i(row.get("attached_wall_cell", Vector2i(-1, -1)))
	var row_placement_mode: String = String(row.get("placement_mode", ""))
	var row_wall_side: String = String(row.get("wall_side", ""))
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		return
	var entity_info: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		_clear_map_constructor_browser_selection()
		return
	var focus_cell: Vector2i = row_cell
	if row_placement_mode == "wall_mounted":
		if row_anchor_floor_cell.x >= 0 and row_anchor_floor_cell.y >= 0:
			focus_cell = row_anchor_floor_cell
		elif row_attached_wall_cell.x >= 0 and row_attached_wall_cell.y >= 0 and not row_wall_side.is_empty():
			focus_cell = row_cell
	if focus_cell.x < 0 or focus_cell.y < 0:
		focus_cell = row_cell
	_clear_map_constructor_link_target()
	map_constructor_state.selected_map_constructor_entity_kind = entity_kind
	map_constructor_state.selected_map_constructor_entity_id = entity_id
	map_constructor_state.selected_map_constructor_entity_cell = focus_cell
	map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
	_clear_map_constructor_pending_placement()
	_clear_map_constructor_preview_cell()
	_show_map_constructor_inspector(focus_cell, entity_kind, entity_id)
	_focus_map_constructor_cell(focus_cell)
	_request_map_constructor_overlay_refresh()

func _apply_map_constructor_cleanup_action(cleanup_type: String, options: Dictionary = {}, apply_now: bool = false) -> void:
	if mission_manager_runtime == null:
		return
	if not apply_now:
		map_constructor_state.map_constructor_cleanup_preview = mission_manager_runtime.call("get_map_constructor_cleanup_preview", cleanup_type, options)
		map_constructor_state.map_constructor_cleanup_pending_apply_key = "%s|%s" % [cleanup_type, JSON.stringify(options)]
		show_hint(String(map_constructor_state.map_constructor_cleanup_preview.get("message", "Preview ready.")))
		_refresh_map_constructor_panels()
		return
	var apply_result: Dictionary = mission_manager_runtime.call("apply_map_constructor_cleanup", cleanup_type, options)
	show_hint(String(apply_result.get("message", "Cleanup applied.")))
	map_constructor_state.map_constructor_cleanup_pending_apply_key = ""
	map_constructor_state.map_constructor_cleanup_preview.clear()
	_clear_map_constructor_preview_cell()
	_clear_map_constructor_wall_mounted_selection()
	_clear_map_constructor_link_target()
	_show_map_constructor_inspector(Vector2i(-1, -1))
	MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)

func _apply_map_constructor_autofix_action(fix_type: String, options: Dictionary = {}, apply_now: bool = false) -> void:
	if mission_manager_runtime == null:
		return
	if not apply_now:
		map_constructor_state.map_constructor_autofix_preview = mission_manager_runtime.call("get_map_constructor_autofix_preview", fix_type, options)
		map_constructor_state.map_constructor_autofix_pending_apply_key = "%s|%s" % [fix_type, JSON.stringify(options)]
		show_hint(String(map_constructor_state.map_constructor_autofix_preview.get("message", "Auto-fix preview ready.")))
		_refresh_map_constructor_panels()
		return
	var apply_result: Dictionary = mission_manager_runtime.call("apply_map_constructor_autofix", fix_type, options)
	show_hint(String(apply_result.get("message", "Auto-fix applied.")))
	map_constructor_state.map_constructor_autofix_pending_apply_key = ""
	map_constructor_state.map_constructor_autofix_preview.clear()
	_clear_map_constructor_preview_cell()
	_clear_map_constructor_wall_mounted_selection()
	_clear_map_constructor_link_target()
	_show_map_constructor_inspector(Vector2i(-1, -1))
	MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)

func _make_map_constructor_multi_row_from_current_selection() -> Dictionary:
	if map_constructor_state.selected_map_constructor_entity_id.is_empty():
		return {}
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		return {}
	var entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", map_constructor_state.selected_map_constructor_entity_kind, map_constructor_state.selected_map_constructor_entity_id)
	if not bool(entity.get("ok", false)):
		return {}
	var data: Dictionary = _safe_ui_dictionary(entity.get("data", {}))
	return {"entity_kind":String(entity.get("entity_kind", map_constructor_state.selected_map_constructor_entity_kind)), "entity_id":String(entity.get("id", map_constructor_state.selected_map_constructor_entity_id)), "cell":_safe_ui_vector2i(entity.get("cell", Vector2i(-1, -1))), "object_type":String(data.get("object_type", data.get("item_type", ""))), "created_by_map_constructor":bool(data.get("created_by_map_constructor", false))}

func _refresh_map_constructor_multi_selection_stale() -> void:
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		map_constructor_state.map_constructor_multi_selected_entities.clear()
		return
	var fresh: Array[Dictionary] = []
	var seen: Dictionary = {}
	for row in map_constructor_state.map_constructor_multi_selected_entities:
		var key: String = "%s|%s" % [String(row.get("entity_kind", "")), String(row.get("entity_id", ""))]
		if seen.has(key):
			continue
		seen[key] = true
		var entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", String(row.get("entity_kind", "")), String(row.get("entity_id", "")))
		if bool(entity.get("ok", false)):
			if String(entity.get("id", "")) == map_constructor_state.selected_map_constructor_entity_id:
				fresh.append(_make_map_constructor_multi_row_from_current_selection())
			else:
				var entity_data: Dictionary = _safe_ui_dictionary(entity.get("data", {}))
				fresh.append({"entity_kind":String(entity.get("entity_kind", "")), "entity_id":String(entity.get("id", "")), "cell":_safe_ui_vector2i(entity.get("cell", Vector2i(-1, -1))), "object_type":String(entity_data.get("object_type", entity_data.get("item_type", ""))), "created_by_map_constructor":bool(entity_data.get("created_by_map_constructor", false))})
	map_constructor_state.map_constructor_multi_selected_entities = fresh


func _build_map_constructor_batch_operation_key(operation_type: String) -> String:
	var selected_keys: Array[String] = []
	for row in map_constructor_state.map_constructor_multi_selected_entities:
		selected_keys.append("%s|%s" % [String(row.get("entity_kind", "")), String(row.get("entity_id", ""))])
	selected_keys.sort()
	return "%s|%s|%d|%d|%s" % [operation_type, ",".join(selected_keys), map_constructor_state.map_constructor_batch_offset_x, map_constructor_state.map_constructor_batch_offset_y, map_constructor_state.map_constructor_batch_power_network_id.strip_edges()]

func _clear_map_constructor_batch_preview_state() -> void:
	map_constructor_state.map_constructor_batch_preview.clear()
	map_constructor_state.map_constructor_batch_pending_apply_operation = ""
	map_constructor_state.map_constructor_batch_pending_apply_key = ""

func _add_map_constructor_multi_row_if_missing(row: Dictionary) -> void:
	if row.is_empty():
		return
	if not bool(row.get("created_by_map_constructor", false)):
		return
	var key: String = "%s|%s" % [String(row.get("entity_kind", "")), String(row.get("entity_id", ""))]
	for existing in map_constructor_state.map_constructor_multi_selected_entities:
		if "%s|%s" % [String(existing.get("entity_kind", "")), String(existing.get("entity_id", ""))] == key:
			return
	map_constructor_state.map_constructor_multi_selected_entities.append(row)

func _add_map_constructor_multi_selection_by_filter(filter_mode: String) -> void:
	for row in _build_map_constructor_placed_object_rows():
		if not bool(row.get("created_by_map_constructor", false)):
			continue
		var entity_kind: String = String(row.get("entity_kind", ""))
		var type_or_prefab: String = String(row.get("type_or_prefab", "")).to_lower()
		var category: String = String(row.get("category_or_placement", "")).to_lower()
		var placement_mode: String = String(row.get("placement_mode", "")).to_lower()
		var allow: bool = false
		match filter_mode:
			"all_constructor":
				allow = true
			"items":
				allow = entity_kind == "item" or category == "items"
			"wall_mounted":
				allow = placement_mode == "wall_mounted" or category == "wall-mounted"
			"doors":
				allow = type_or_prefab.find("door") >= 0 or category == "doors"
			"terminals":
				allow = type_or_prefab.find("terminal") >= 0 or category == "terminals"
			"power":
				allow = MAP_CONSTRUCTOR_POWER_PREFAB_IDS.has(type_or_prefab) or category == "power"
			"control":
				allow = MAP_CONSTRUCTOR_CONTROL_PREFAB_IDS.has(type_or_prefab) or category == "control"
		if not allow:
			continue
		_add_map_constructor_multi_row_if_missing({"entity_kind":entity_kind, "entity_id":String(row.get("id", "")), "cell":_safe_ui_vector2i(row.get("cell", Vector2i(-1, -1))), "object_type":type_or_prefab, "created_by_map_constructor":true})
	_refresh_map_constructor_multi_selection_stale()

func _remember_map_constructor_palette_scroll() -> void:
	MapConstructorTabs.remember_palette_scroll(self)

func _find_map_constructor_palette_scroll(root: Node) -> ScrollContainer:
	return MapConstructorTabs.find_palette_scroll(root)

func _restore_map_constructor_palette_scroll_deferred(scroll: ScrollContainer, tab_name: String) -> void:
	MapConstructorTabs.restore_palette_scroll_deferred(self, scroll, tab_name)

func _restore_map_constructor_palette_scroll(scroll: ScrollContainer, tab_name: String) -> void:
	MapConstructorTabs.restore_palette_scroll(self, scroll, tab_name)

func _set_map_constructor_active_tab(tab_name: String) -> void:
	MapConstructorTabs.set_active_tab(self, tab_name)


func _add_map_constructor_section_header(parent: VBoxContainer, title: String) -> void:
	var header_panel: PanelContainer = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 6))
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	header_panel.add_child(title_label)
	parent.add_child(header_panel)


func _make_map_constructor_action_row() -> HFlowContainer:
	var row: HFlowContainer = HFlowContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	return row

func _make_map_constructor_action_button(label_text: String, tooltip: String = "") -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.tooltip_text = tooltip if not tooltip.is_empty() else label_text
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(120, 30)
	return button

func _add_map_constructor_tab_header(parent: VBoxContainer, available_width: float) -> void:
	MapConstructorTabs.add_tab_header(self, parent, available_width)


func _add_map_constructor_controls_hint(parent: VBoxContainer) -> void:
	var local_hint_label: Label = Label.new()
	local_hint_label.text = "LMB — select/place/preview   RMB — clear selection   WASD / arrows — pan map"
	local_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_hint_label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	local_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(local_hint_label)

func _refresh_map_constructor_panels() -> void:
	MapConstructorScreenRef.refresh(self)
	_refresh_map_constructor_overview_hud()


func _toggle_map_constructor_overview_hud() -> void:
	if map_constructor_state.map_constructor_overview_hud_visible:
		_hide_map_constructor_overview_hud()
		return
	_show_map_constructor_overview_hud()

func _show_map_constructor_overview_hud() -> void:
	if not map_constructor_state.map_constructor_mode_active or not _is_task_test_runtime_active():
		return
	map_constructor_state.map_constructor_overview_hud_visible = true
	_refresh_map_constructor_panels()

func _hide_map_constructor_overview_hud() -> void:
	map_constructor_state.map_constructor_overview_hud_visible = false
	_clear_map_constructor_overview_hud()
	_refresh_map_constructor_panels()

func _clear_map_constructor_overview_hud() -> void:
	if runtime_map_constructor_overview_hud_panel != null and is_instance_valid(runtime_map_constructor_overview_hud_panel):
		runtime_map_constructor_overview_hud_panel.queue_free()
	runtime_map_constructor_overview_hud_panel = null
	runtime_map_constructor_overview_hud_scroll = null

func _get_map_constructor_overview_hud_rect() -> Rect2:
	var safe_margin: float = 12.0
	var viewport: Vector2 = _get_viewport_size()
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root) and runtime_hud_root.size.x > 0.0 and runtime_hud_root.size.y > 0.0:
		viewport = Vector2(minf(viewport.x, runtime_hud_root.size.x), minf(viewport.y, runtime_hud_root.size.y))
	viewport.x = maxf(viewport.x, safe_margin * 2.0 + 1.0)
	viewport.y = maxf(viewport.y, safe_margin * 2.0 + 1.0)
	var palette_rect: Rect2 = _get_map_constructor_palette_rect()
	var max_bottom: float = maxf(safe_margin + 1.0, viewport.y - _get_runtime_bottom_panel_height() - safe_margin)
	var available_left_width: float = maxf(1.0, palette_rect.position.x - safe_margin * 2.0)
	var available_height: float = maxf(1.0, max_bottom - safe_margin)
	var desired_width: float = clampf(viewport.x * 0.32, 320.0, 420.0)
	var desired_height: float = clampf(viewport.y * 0.42, 260.0, 360.0)
	var width: float = minf(desired_width, maxf(1.0, viewport.x - safe_margin * 2.0))
	if available_left_width >= 260.0:
		width = minf(width, available_left_width)
	var height: float = minf(desired_height, available_height)
	var x: float = safe_margin
	if x + width > palette_rect.position.x - safe_margin and available_left_width >= 260.0:
		width = maxf(1.0, palette_rect.position.x - safe_margin * 2.0)
	var max_x: float = maxf(safe_margin, viewport.x - width - safe_margin)
	return Rect2(Vector2(clampf(x, safe_margin, max_x), safe_margin), Vector2(width, maxf(1.0, height)))

func _refresh_map_constructor_overview_hud() -> void:
	if not map_constructor_state.map_constructor_mode_active or not map_constructor_state.map_constructor_overview_hud_visible or not _is_task_test_runtime_active():
		_clear_map_constructor_overview_hud()
		return
	if runtime_hud_root == null or not is_instance_valid(runtime_hud_root):
		_ensure_runtime_hud_root()
	if runtime_map_constructor_overview_hud_panel == null or not is_instance_valid(runtime_map_constructor_overview_hud_panel):
		var panel: PanelContainer = PanelContainer.new()
		panel.name = "MapConstructorOverviewHudPanel"
		panel.z_index = Z_MAP_CONSTRUCTOR_UI + 2
		panel.z_as_relative = false
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER, 1, 8))
		runtime_hud_root.add_child(panel)
		runtime_map_constructor_overview_hud_panel = panel
	var rect: Rect2 = _get_map_constructor_overview_hud_rect()
	runtime_map_constructor_overview_hud_panel.position = rect.position
	runtime_map_constructor_overview_hud_panel.custom_minimum_size = rect.size
	runtime_map_constructor_overview_hud_panel.size = rect.size
	for child in runtime_map_constructor_overview_hud_panel.get_children():
		runtime_map_constructor_overview_hud_panel.remove_child(child)
		child.queue_free()
	var margin_box: MarginContainer = MarginContainer.new()
	margin_box.add_theme_constant_override("margin_left", 8)
	margin_box.add_theme_constant_override("margin_right", 8)
	margin_box.add_theme_constant_override("margin_top", 8)
	margin_box.add_theme_constant_override("margin_bottom", 8)
	margin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	runtime_map_constructor_overview_hud_panel.add_child(margin_box)
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	margin_box.add_child(root)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(title_row)
	var title_label: Label = Label.new()
	title_label.text = "Map Overview"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	title_row.add_child(title_label)
	var hide_button: Button = _make_map_constructor_action_button("×")
	hide_button.tooltip_text = "Hide overview"
	hide_button.pressed.connect(func() -> void: _hide_map_constructor_overview_hud())
	title_row.add_child(hide_button)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.clip_contents = true
	root.add_child(scroll)
	runtime_map_constructor_overview_hud_scroll = scroll
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	scroll.add_child(content)
	_add_map_constructor_overview_hud_content(content)

func _add_map_constructor_overview_hud_content(list: VBoxContainer) -> void:
	var overview_data: Dictionary = {}
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_overview_data"):
		overview_data = mission_manager_runtime.call("get_map_constructor_overview_data", {"include_validation":map_constructor_state.map_constructor_overview_show_issues, "include_history":map_constructor_state.map_constructor_overview_show_history, "include_power":map_constructor_state.map_constructor_overview_show_power, "include_items":map_constructor_state.map_constructor_overview_show_items, "include_wall_mounted":map_constructor_state.map_constructor_overview_show_wall_mounted, "selected_entities":map_constructor_state.map_constructor_multi_selected_entities, "selected_entity_id":map_constructor_state.selected_map_constructor_entity_id, "selected_entity_kind":map_constructor_state.selected_map_constructor_entity_kind, "max_history_markers":20})
	var ov_summary: Dictionary = _safe_ui_dictionary(overview_data.get("summary", {}))
	var sum_label: Label = Label.new()
	sum_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum_label.text = "size=%dx%d objects=%d items=%d issues=%d warnings=%d expected=%d" % [int(ov_summary.get("width", 0)), int(ov_summary.get("height", 0)), int(ov_summary.get("object_count", 0)), int(ov_summary.get("item_count", 0)), int(ov_summary.get("error_count", 0)), int(ov_summary.get("warning_count", 0)), int(ov_summary.get("expected_invalid_count", 0))]
	list.add_child(sum_label)
	var legend_label: Label = Label.new()
	legend_label.text = ". floor # wall D door T terminal P power I item W wall-mounted ! error ? warning * selected X expected-invalid"
	legend_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(legend_label)
	var jump_row: HFlowContainer = _make_map_constructor_action_row()
	for cfg in [{"label":"Refresh Overview","kind":"refresh"},{"label":"Jump to Selected","kind":"selected"},{"label":"Jump to First Error","kind":"validation_issue"},{"label":"Jump to First Warning","kind":"warning"},{"label":"Jump to First Expected Invalid","kind":"expected_invalid"},{"label":"Jump to Last Change","kind":"history"}]:
		var b: Button = _make_map_constructor_action_button(String(cfg.get("label", "Jump")))
		b.pressed.connect(func() -> void:
			if String(cfg.get("kind", "")) == "refresh":
				_refresh_map_constructor_overview_hud()
				return
			var marker_rows: Array = _safe_ui_array(overview_data.get("markers", []))
			if String(cfg.get("kind", "")) == "history":
				marker_rows.reverse()
			for marker_variant in marker_rows:
				var marker: Dictionary = _safe_ui_dictionary(marker_variant)
				var mk: String = String(marker.get("kind", ""))
				if String(cfg.get("kind", "")) == "selected" and mk != "selected":
					continue
				if String(cfg.get("kind", "")) != "selected" and mk != String(cfg.get("kind", "")):
					continue
				_jump_to_map_constructor_history_row(marker)
				return
		)
		jump_row.add_child(b)
	list.add_child(jump_row)
	var map_size: Vector2i = _safe_ui_vector2i(overview_data.get("map_size", Vector2i.ZERO))
	if map_size.x > 80 or map_size.y > 80:
		var large_label: Label = Label.new()
		large_label.text = "Map is large; showing marker overview only."
		list.add_child(large_label)
	else:
		var rows: Dictionary = {}
		for cell_variant in _safe_ui_array(overview_data.get("cells", [])):
			var cell_row: Dictionary = _safe_ui_dictionary(cell_variant)
			var cell: Vector2i = _safe_ui_vector2i(cell_row.get("cell", Vector2i(-1, -1)))
			var y: int = cell.y
			if not rows.has(y):
				rows[y] = []
			rows[y].append(cell_row)
		for y in range(map_size.y):
			var row_box: HBoxContainer = HBoxContainer.new()
			row_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			for x in range(map_size.x):
				var symbol: String = " "
				for cell_row_variant in _safe_ui_array(rows.get(y, [])):
					var cr: Dictionary = _safe_ui_dictionary(cell_row_variant)
					if _safe_ui_vector2i(cr.get("cell", Vector2i(-1, -1))).x == x:
						symbol = _map_constructor_overview_symbol_for_cell(cr)
						break
				var cell_btn: Button = Button.new()
				cell_btn.text = symbol
				cell_btn.custom_minimum_size = Vector2(18, 18)
				var c: Vector2i = Vector2i(x, y)
				cell_btn.pressed.connect(func() -> void:
					var opened_entity: bool = false
					if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_editable_entity_at_cell"):
						var editable_res: Dictionary = mission_manager_runtime.call("get_map_constructor_editable_entity_at_cell", c)
						if bool(editable_res.get("ok", false)):
							_show_map_constructor_inspector(c, String(editable_res.get("entity_kind", "")), String(editable_res.get("entity_id", "")))
							opened_entity = true
					_focus_map_constructor_cell(c)
					if not opened_entity:
						_show_map_constructor_inspector(c)
				)
				row_box.add_child(cell_btn)
			list.add_child(row_box)
	var markers_title: Label = Label.new()
	markers_title.text = "Overview Markers"
	list.add_child(markers_title)
	var shown_markers: int = 0
	for marker_variant in _safe_ui_array(overview_data.get("markers", [])):
		var marker: Dictionary = _safe_ui_dictionary(marker_variant)
		if not _map_constructor_overview_marker_matches_filter(marker):
			continue
		var line: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.text = "%s | %s | %s | %s" % [String(marker.get("status", "info")), String(marker.get("kind", "")), String(marker.get("label", "")), str(marker.get("cell", Vector2i(-1, -1)))]
		line.add_child(lbl)
		var jump: Button = _make_map_constructor_action_button("Jump")
		jump.pressed.connect(func() -> void: _jump_to_map_constructor_history_row(marker))
		line.add_child(jump)
		list.add_child(line)
		shown_markers += 1
		if shown_markers >= 30:
			break

func _build_map_constructor_warnings_tab(list: VBoxContainer) -> void:
	var readiness_title: Label = Label.new()
	readiness_title.text = "Mission Readiness"
	list.add_child(readiness_title)
	var visual_assets_title: Label = Label.new()
	visual_assets_title.text = "Visual Assets"
	list.add_child(visual_assets_title)
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_visual_texture_asset_catalog"):
		var visual_catalog: Dictionary = mission_manager_runtime.call("get_visual_texture_asset_catalog")
		var visual_assets: Array = _safe_ui_array(visual_catalog.get("assets", []))
		var missing_optional_count: int = 0
		for row_variant in visual_assets:
			var row: Dictionary = _safe_ui_dictionary(row_variant)
			if mission_manager_runtime.has_method("resolve_visual_texture_asset"):
				var resolved: Dictionary = mission_manager_runtime.call("resolve_visual_texture_asset", String(row.get("id", "")))
				if bool(resolved.get("ok", false)) and not bool(resolved.get("has_texture", false)) and bool(row.get("is_optional", true)):
					missing_optional_count += 1
		var visual_summary_label: Label = Label.new()
		visual_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		visual_summary_label.text = "assets=%d missing_optional=%d" % [visual_assets.size(), missing_optional_count]
		list.add_child(visual_summary_label)
		var selected_texture_asset_id: String = ""
		if not map_constructor_state.selected_map_constructor_entity_id.is_empty() and mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
			var entity_data: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", map_constructor_state.selected_map_constructor_entity_kind, map_constructor_state.selected_map_constructor_entity_id)
			var selected_payload: Dictionary = _safe_ui_dictionary(entity_data.get("data", {}))
			selected_texture_asset_id = String(selected_payload.get("texture_asset_id", ""))
		var selected_asset_label: Label = Label.new()
		selected_asset_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		selected_asset_label.text = "selected.texture_asset_id=%s" % (selected_texture_asset_id if not selected_texture_asset_id.is_empty() else "none")
		list.add_child(selected_asset_label)
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_mission_readiness_report"):
		var readiness: Dictionary = mission_manager_runtime.call("get_map_constructor_mission_readiness_report")
		var readiness_status: String = String(readiness.get("status", "unknown"))
		var constructor_status_label: Label = Label.new()
		constructor_status_label.text = "Mission Readiness: %s" % ["PLAYABLE" if readiness_status == "playable" else ("BLOCKED" if readiness_status == "blocked" else "WARNINGS")]
		list.add_child(constructor_status_label)
		var summary_label: Label = Label.new()
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_label.text = "blocking=%d warnings=%d expected-invalid=%d info=%d" % [int(readiness.get("blocking_count", 0)), int(readiness.get("warning_count", 0)), int(readiness.get("expected_invalid_count", 0)), int(readiness.get("info_count", 0))]
		list.add_child(summary_label)
		var action_by_issue: Dictionary = {}
		for rec_variant in _safe_ui_array(readiness.get("recommended_actions", [])):
			var rec: Dictionary = _safe_ui_dictionary(rec_variant)
			var tid: String = String(rec.get("target_issue_id", ""))
			if tid.is_empty() or action_by_issue.has(tid):
				continue
			action_by_issue[tid] = rec
		for check_variant in _safe_ui_array(readiness.get("checks", [])):
			var check: Dictionary = _safe_ui_dictionary(check_variant)
			var check_status: String = String(check.get("status", "info"))
			var icon: String = "ℹ"
			if check_status == "pass":
				icon = "✅"
			elif check_status == "fail":
				icon = "❌"
			elif check_status == "warning":
				icon = "⚠"
			elif check_status == "expected_invalid":
				icon = "🧪"
			var check_label: Label = Label.new()
			check_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var line: String = "%s %s: %s (count=%d)" % [icon, String(check.get("label", "Check")), String(check.get("message", "")), int(check.get("count", 0))]
			if not String(check.get("entity_id", "")).is_empty():
				line += " | id=%s" % String(check.get("entity_id", ""))
			var c: Vector2i = _safe_ui_vector2i(check.get("cell", Vector2i(-1, -1)))
			if c.x >= 0 and c.y >= 0:
				line += " | c=%s" % str(c)
			check_label.text = line
			list.add_child(check_label)
			var issue_id: String = String(check.get("issue_id", ""))
			if issue_id.is_empty():
				continue
			var action_row: HFlowContainer = _make_map_constructor_action_row()
			var jump_button: Button = _make_map_constructor_action_button("Jump")
			jump_button.pressed.connect(func() -> void:
				_focus_map_constructor_readiness_issue_by_id(issue_id)
			)
			action_row.add_child(jump_button)
			if action_by_issue.has(issue_id):
				var rec: Dictionary = _safe_ui_dictionary(action_by_issue[issue_id])
				_add_map_constructor_readiness_action_buttons(action_row, rec)
			list.add_child(action_row)
		var expected_section: Label = Label.new()
		expected_section.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var expected_ids: Array[String] = []
		for issue_variant in _safe_ui_array(readiness.get("expected_invalid_issues", [])):
			if expected_ids.size() >= 10:
				break
			var issue_data: Dictionary = _safe_ui_dictionary(issue_variant)
			expected_ids.append(String(issue_data.get("id", issue_data.get("entity_id", ""))))
		expected_section.text = "Expected Invalid Cases (%d): %s\nThese are intentional TASK TEST broken cases and do not block readiness." % [int(readiness.get("expected_invalid_count", 0)), ", ".join(expected_ids)]
		list.add_child(expected_section)
	var issues_title: Label = Label.new()
	issues_title.text = "Validation Issues"
	list.add_child(issues_title)
	var issues_filter_option: OptionButton = OptionButton.new()
	for filter_name in MAP_CONSTRUCTOR_ISSUE_FILTER_OPTIONS:
		issues_filter_option.add_item(filter_name)
	var selected_filter_index: int = MAP_CONSTRUCTOR_ISSUE_FILTER_OPTIONS.find(map_constructor_state.map_constructor_issue_filter)
	if selected_filter_index < 0:
		selected_filter_index = 0
		map_constructor_state.map_constructor_issue_filter = "All"
	issues_filter_option.select(selected_filter_index)
	issues_filter_option.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < MAP_CONSTRUCTOR_ISSUE_FILTER_OPTIONS.size():
			map_constructor_state.map_constructor_issue_filter = MAP_CONSTRUCTOR_ISSUE_FILTER_OPTIONS[index]
			_refresh_map_constructor_panels()
	)
	list.add_child(issues_filter_option)
	var constructor_issues: Array[Dictionary] = []
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_validation_issues"):
		constructor_issues = mission_manager_runtime.call("get_map_constructor_validation_issues")
	var issue_errors: int = 0
	var issue_warnings: int = 0
	var issue_info: int = 0
	var issue_id_exists: bool = false
	for issue_row in constructor_issues:
		var issue_severity: String = String(issue_row.get("severity", "info")).to_lower()
		if issue_severity == "error":
			issue_errors += 1
		elif issue_severity == "warning":
			issue_warnings += 1
		else:
			issue_info += 1
		if String(issue_row.get("id", "")) == map_constructor_state.map_constructor_selected_issue_id:
			issue_id_exists = true
	if not issue_id_exists:
		map_constructor_state.map_constructor_selected_issue_id = ""
	var issue_counts_label: Label = Label.new()
	issue_counts_label.text = "Errors: %d Warnings: %d Info: %d" % [issue_errors, issue_warnings, issue_info]
	list.add_child(issue_counts_label)
	for issue_row in constructor_issues:
		if not _map_constructor_issue_matches_filter(issue_row):
			continue
		var issue_id: String = String(issue_row.get("id", ""))
		var issue_severity: String = String(issue_row.get("severity", "info")).to_upper()
		var issue_message: String = String(issue_row.get("message", "Validation issue"))
		var issue_cell: Vector2i = _safe_ui_vector2i(issue_row.get("cell", Vector2i(-1, -1)))
		var issue_entity_id: String = String(issue_row.get("entity_id", ""))
		var issue_text: String = "%s%s: %s" % ["▶ " if issue_id == map_constructor_state.map_constructor_selected_issue_id else "", issue_severity, issue_message]
		if not issue_entity_id.is_empty():
			issue_text += " | id=%s" % issue_entity_id
		if issue_cell.x >= 0 and issue_cell.y >= 0:
			issue_text += " | c=%s" % str(issue_cell)
		var issue_button: Button = Button.new()
		issue_button.text = issue_text
		issue_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		issue_button.pressed.connect(func() -> void:
			map_constructor_state.map_constructor_selected_issue_id = issue_id
			_focus_map_constructor_issue(issue_row)
			_refresh_map_constructor_panels()
		)
		list.add_child(issue_button)
		if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_issue_autofix_options"):
			var fix_options: Array = mission_manager_runtime.call("get_map_constructor_issue_autofix_options", issue_row)
			if not fix_options.is_empty():
				for option_row in fix_options:
					var fix_option: Dictionary = _safe_ui_dictionary(option_row)
					var ftype: String = String(fix_option.get("fix_type", ""))
					var foptions: Dictionary = _safe_ui_dictionary(fix_option.get("options", {}))
					var flabel: String = String(fix_option.get("label", "Fix"))
					var fkey: String = "%s|%s" % [ftype, JSON.stringify(foptions)]
					var issue_fix_row: HFlowContainer = _make_map_constructor_action_row()
					var preview_btn: Button = _make_map_constructor_action_button("Preview: %s" % flabel)
					var apply_btn: Button = _make_map_constructor_action_button("Apply: %s" % flabel)
					preview_btn.pressed.connect(func() -> void:
						_apply_map_constructor_autofix_action(ftype, foptions, false)
					)
					apply_btn.disabled = map_constructor_state.map_constructor_autofix_pending_apply_key != fkey
					apply_btn.pressed.connect(func() -> void:
						_apply_map_constructor_autofix_action(ftype, foptions, true)
					)
					issue_fix_row.add_child(preview_btn)
					issue_fix_row.add_child(apply_btn)
					list.add_child(issue_fix_row)
	var audit_label: Label = Label.new()
	audit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audit_label.text = "Audit: unavailable"
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_audit_summary"):
		var audit_summary: Dictionary = mission_manager_runtime.call("get_map_constructor_audit_summary")
		var audit_status: String = "WARN"
		if bool(audit_summary.get("ok", false)):
			audit_status = "OK"
		audit_label.text = "Audit: %s m=%d i=%d r=%d d=%d" % [
			audit_status,
			int(audit_summary.get("missing_coverage_count", 0)),
			int(audit_summary.get("invalid_links_count", 0)),
			int(audit_summary.get("runtime_warnings_count", 0)),
			int(audit_summary.get("duplicate_cell_warnings_count", 0))
		]
	list.add_child(audit_label)
	var overlay_summary_label: Label = Label.new()
	overlay_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_summary_label.text = "Validation: unavailable"
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_validation_overlay"):
		var overlay_data: Dictionary = mission_manager_runtime.call("get_map_constructor_validation_overlay")
		var overlay_summary: Dictionary = _safe_ui_dictionary(overlay_data.get("summary", {}))
		var error_count: int = int(overlay_summary.get("error_count", 0))
		var warning_count: int = int(overlay_summary.get("warning_count", 0))
		var valid_count: int = int(overlay_summary.get("valid_count", 0))
		if error_count <= 0 and warning_count <= 0:
			overlay_summary_label.text = "Validation: OK"
		else:
			overlay_summary_label.text = "Validation: errors=%d warnings=%d valid=%d" % [error_count, warning_count, valid_count]
	list.add_child(overlay_summary_label)
	var overlay_toggle_button: Button = _make_map_constructor_action_button("Validation Overlay: %s" % ["ON" if map_constructor_state.map_constructor_validation_overlay_visible else "OFF"])
	overlay_toggle_button.pressed.connect(func() -> void:
		map_constructor_state.map_constructor_validation_overlay_visible = not map_constructor_state.map_constructor_validation_overlay_visible
		_refresh_map_constructor_panels()
	)
	list.add_child(overlay_toggle_button)
	var overlay_section_title: Label = Label.new()
	overlay_section_title.text = "Overlay"
	list.add_child(overlay_section_title)
	for row_variant in [
		{"key":"show_preview", "label":"Show Placement Preview"},
		{"key":"show_validation", "label":"Show Validation Markers"},
		{"key":"show_links", "label":"Show Links"},
		{"key":"show_power", "label":"Show Power Networks"},
		{"key":"show_wall_side_arrows", "label":"Show Wall-side Arrows"},
		{"key":"show_multi_select", "label":"Show Multi-select"}
	]:
		var row: Dictionary = _safe_ui_dictionary(row_variant)
		var toggle: CheckBox = CheckBox.new()
		toggle.text = String(row.get("label", ""))
		var pref_key: String = String(row.get("key", ""))
		toggle.button_pressed = bool(map_constructor_state.map_constructor_overlay_visibility.get(pref_key, true))
		toggle.toggled.connect(func(enabled: bool) -> void:
			map_constructor_state.map_constructor_overlay_visibility[pref_key] = enabled
			_request_map_constructor_overlay_refresh()
		)
		list.add_child(toggle)
	var reset_overlay_button: Button = _make_map_constructor_action_button("Reset Overlay Visibility")
	reset_overlay_button.pressed.connect(func() -> void:
		map_constructor_state.map_constructor_overlay_visibility = {"show_preview": true, "show_validation": true, "show_links": true, "show_power": true, "show_wall_side_arrows": true, "show_multi_select": true}
		_request_map_constructor_overlay_refresh()
		_refresh_map_constructor_panels()
	)
	list.add_child(reset_overlay_button)

func _build_map_constructor_map_settings_tab(list: VBoxContainer) -> void:
	var constructor_sections_title: Label = Label.new()
	constructor_sections_title.text = "Map Constructor Milestone Tools"
	list.add_child(constructor_sections_title)
	var anchor_cell: Vector2i = map_constructor_state.pending_map_constructor_cell if map_constructor_state.pending_map_constructor_cell.x >= 0 else map_constructor_state.selected_map_constructor_entity_cell
	var kit_options: Dictionary = {"allow_overwrite": false}
	var template_options: Dictionary = {"rotation": map_constructor_state.map_constructor_template_rotation, "mirror_x": map_constructor_state.map_constructor_template_mirror_x, "mirror_y": map_constructor_state.map_constructor_template_mirror_y, "allow_overwrite": false}
	var current_kit_key: String = "%s|%s|%s" % [map_constructor_state.map_constructor_selected_kit_id, str(anchor_cell), JSON.stringify(kit_options)]
	var current_template_key: String = "%s|%s|%s" % [map_constructor_state.map_constructor_selected_template_id, str(anchor_cell), JSON.stringify(template_options)]
	var kit_data: Dictionary = mission_manager_runtime.call("get_map_constructor_prefab_kits") if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_prefab_kits") else {}
	var template_data: Dictionary = mission_manager_runtime.call("get_map_constructor_room_templates") if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_room_templates") else {}
	var kit_rows: Array = _safe_ui_array(kit_data.get("kits", []))
	var template_rows: Array = _safe_ui_array(template_data.get("templates", []))
	var selected_kit_exists: bool = false
	for kit_row_variant in kit_rows:
		if String(_safe_ui_dictionary(kit_row_variant).get("id", "")) == map_constructor_state.map_constructor_selected_kit_id:
			selected_kit_exists = true
			break
	if (map_constructor_state.map_constructor_selected_kit_id.is_empty() or not selected_kit_exists) and not kit_rows.is_empty():
		map_constructor_state.map_constructor_selected_kit_id = String(_safe_ui_dictionary(kit_rows[0]).get("id", ""))
	var selected_template_exists: bool = false
	for template_row_variant in template_rows:
		if String(_safe_ui_dictionary(template_row_variant).get("id", "")) == map_constructor_state.map_constructor_selected_template_id:
			selected_template_exists = true
			break
	if (map_constructor_state.map_constructor_selected_template_id.is_empty() or not selected_template_exists) and not template_rows.is_empty():
		map_constructor_state.map_constructor_selected_template_id = String(_safe_ui_dictionary(template_rows[0]).get("id", ""))
	if map_constructor_state.map_constructor_kit_pending_apply_key != current_kit_key:
		map_constructor_state.map_constructor_kit_preview_can_apply = false
	if map_constructor_state.map_constructor_template_pending_apply_key != current_template_key:
		map_constructor_state.map_constructor_template_preview_can_apply = false
	var kit_select: OptionButton = OptionButton.new()
	for row_variant in kit_rows:
		var row: Dictionary = _safe_ui_dictionary(row_variant)
		kit_select.add_item(String(row.get("display_name", row.get("id", ""))))
		kit_select.set_item_metadata(kit_select.item_count - 1, String(row.get("id", "")))
	for idx in range(kit_select.item_count):
		if String(kit_select.get_item_metadata(idx)) == map_constructor_state.map_constructor_selected_kit_id:
			kit_select.select(idx)
			break
	kit_select.item_selected.connect(func(index: int) -> void:
		map_constructor_state.map_constructor_selected_kit_id = String(kit_select.get_item_metadata(index))
		map_constructor_state.map_constructor_kit_preview_can_apply = false
		map_constructor_state.map_constructor_kit_pending_apply_key = ""
		_refresh_map_constructor_panels()
	)
	list.add_child(kit_select)
	var selected_kit_info: Label = Label.new()
	selected_kit_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for row_variant in kit_rows:
		var row: Dictionary = _safe_ui_dictionary(row_variant)
		if String(row.get("id", "")) == map_constructor_state.map_constructor_selected_kit_id:
			selected_kit_info.text = "Kit: %s\n%s\nTags: %s\nWarnings: %s" % [String(row.get("display_name", "")), String(row.get("description", "")), ", ".join(PackedStringArray(_safe_ui_array(row.get("tags", [])))), String(row.get("warning", "none"))]
	list.add_child(selected_kit_info)
	var quick_kits_button: Button = _make_map_constructor_action_button("Preview Kit")
	quick_kits_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("preview_map_constructor_prefab_kit"):
			return
		if map_constructor_state.map_constructor_selected_kit_id.is_empty():
			return
		map_constructor_state.map_constructor_kit_preview = mission_manager_runtime.call("preview_map_constructor_prefab_kit", map_constructor_state.map_constructor_selected_kit_id, anchor_cell, kit_options)
		map_constructor_state.map_constructor_kit_preview_can_apply = bool(map_constructor_state.map_constructor_kit_preview.get("can_apply", false))
		map_constructor_state.map_constructor_kit_pending_apply_key = "%s|%s|%s" % [map_constructor_state.map_constructor_selected_kit_id, str(anchor_cell), JSON.stringify(kit_options)] if map_constructor_state.map_constructor_kit_preview_can_apply else ""
		_refresh_map_constructor_panels()
	)
	list.add_child(quick_kits_button)
	var apply_kit_button: Button = _make_map_constructor_action_button("Apply Kit")
	apply_kit_button.disabled = map_constructor_state.map_constructor_selected_kit_id.is_empty() or not map_constructor_state.map_constructor_kit_preview_can_apply or map_constructor_state.map_constructor_kit_pending_apply_key != current_kit_key
	apply_kit_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("apply_map_constructor_prefab_kit"):
			return
		var result: Dictionary = mission_manager_runtime.call("apply_map_constructor_prefab_kit", map_constructor_state.map_constructor_selected_kit_id, anchor_cell, kit_options)
		show_hint(String(result.get("message", "Kit applied.")))
		map_constructor_state.map_constructor_kit_preview = {}
		map_constructor_state.map_constructor_kit_preview_can_apply = false
		map_constructor_state.map_constructor_kit_pending_apply_key = ""
		MapConstructorRefreshCoordinatorRef.refresh_panels_browser_then_field(self)
	)
	list.add_child(apply_kit_button)
	var undo_kit_button: Button = _make_map_constructor_action_button("Undo Last Kit")
	undo_kit_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("undo_last_map_constructor_prefab_kit"):
			return
		var undo_result: Dictionary = mission_manager_runtime.call("undo_last_map_constructor_prefab_kit")
		show_hint(String(undo_result.get("message", "Kit undo completed.")))
		map_constructor_state.map_constructor_kit_preview = {}
		map_constructor_state.map_constructor_kit_preview_can_apply = false
		map_constructor_state.map_constructor_kit_pending_apply_key = ""
		MapConstructorRefreshCoordinatorRef.refresh_panels_browser_then_field(self)
	)
	list.add_child(undo_kit_button)
	var template_select: OptionButton = OptionButton.new()
	for row_variant in template_rows:
		var row: Dictionary = _safe_ui_dictionary(row_variant)
		template_select.add_item(String(row.get("display_name", row.get("id", ""))))
		template_select.set_item_metadata(template_select.item_count - 1, String(row.get("id", "")))
	for idx in range(template_select.item_count):
		if String(template_select.get_item_metadata(idx)) == map_constructor_state.map_constructor_selected_template_id:
			template_select.select(idx)
			break
	template_select.item_selected.connect(func(index: int) -> void:
		map_constructor_state.map_constructor_selected_template_id = String(template_select.get_item_metadata(index))
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		_refresh_map_constructor_panels()
	)
	list.add_child(template_select)
	var template_info: Label = Label.new()
	template_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for row_variant in template_rows:
		var row: Dictionary = _safe_ui_dictionary(row_variant)
		if String(row.get("id", "")) == map_constructor_state.map_constructor_selected_template_id:
			template_info.text = "Template: %s\n%s\nsize=%s\nTags: %s\nWarnings: %s" % [String(row.get("display_name", "")), String(row.get("description", "")), str(row.get("size", Vector2i.ZERO)), ", ".join(PackedStringArray(_safe_ui_array(row.get("tags", [])))), String(row.get("warning", "none"))]
	list.add_child(template_info)
	var template_transform_row: HFlowContainer = _make_map_constructor_action_row()
	var rotation_label: Label = Label.new()
	rotation_label.text = "Rotation"
	template_transform_row.add_child(rotation_label)
	var rotation_select: OptionButton = OptionButton.new()
	for rotation_option in [0, 90, 180, 270]:
		rotation_select.add_item("%d" % rotation_option)
	for rotation_index in range(rotation_select.item_count):
		if int(rotation_select.get_item_text(rotation_index)) == map_constructor_state.map_constructor_template_rotation:
			rotation_select.select(rotation_index)
			break
	rotation_select.item_selected.connect(func(index: int) -> void:
		map_constructor_state.map_constructor_template_rotation = int(rotation_select.get_item_text(index))
		map_constructor_state.map_constructor_template_preview = {}
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		_refresh_map_constructor_panels()
	)
	template_transform_row.add_child(rotation_select)
	var mirror_x_check: CheckBox = CheckBox.new()
	mirror_x_check.text = "Mirror X"
	mirror_x_check.button_pressed = map_constructor_state.map_constructor_template_mirror_x
	mirror_x_check.toggled.connect(func(enabled: bool) -> void:
		map_constructor_state.map_constructor_template_mirror_x = enabled
		map_constructor_state.map_constructor_template_preview = {}
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		_refresh_map_constructor_panels()
	)
	template_transform_row.add_child(mirror_x_check)
	var mirror_y_check: CheckBox = CheckBox.new()
	mirror_y_check.text = "Mirror Y"
	mirror_y_check.button_pressed = map_constructor_state.map_constructor_template_mirror_y
	mirror_y_check.toggled.connect(func(enabled: bool) -> void:
		map_constructor_state.map_constructor_template_mirror_y = enabled
		map_constructor_state.map_constructor_template_preview = {}
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		_refresh_map_constructor_panels()
	)
	template_transform_row.add_child(mirror_y_check)
	list.add_child(template_transform_row)
	var template_preview_button: Button = _make_map_constructor_action_button("Preview Template")
	template_preview_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("preview_map_constructor_room_template"):
			return
		if map_constructor_state.map_constructor_selected_template_id.is_empty():
			return
		map_constructor_state.map_constructor_template_preview = mission_manager_runtime.call("preview_map_constructor_room_template", map_constructor_state.map_constructor_selected_template_id, anchor_cell, template_options)
		map_constructor_state.map_constructor_template_preview_can_apply = bool(map_constructor_state.map_constructor_template_preview.get("can_apply", false))
		map_constructor_state.map_constructor_template_pending_apply_key = "%s|%s|%s" % [map_constructor_state.map_constructor_selected_template_id, str(anchor_cell), JSON.stringify(template_options)] if map_constructor_state.map_constructor_template_preview_can_apply else ""
		_refresh_map_constructor_panels()
	)
	list.add_child(template_preview_button)
	var apply_template_button: Button = _make_map_constructor_action_button("Apply Template")
	apply_template_button.disabled = map_constructor_state.map_constructor_selected_template_id.is_empty() or not map_constructor_state.map_constructor_template_preview_can_apply or map_constructor_state.map_constructor_template_pending_apply_key != current_template_key
	apply_template_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("apply_map_constructor_room_template"):
			return
		var apply_result: Dictionary = mission_manager_runtime.call("apply_map_constructor_room_template", map_constructor_state.map_constructor_selected_template_id, anchor_cell, template_options)
		show_hint(String(apply_result.get("message", "Template applied.")))
		map_constructor_state.map_constructor_template_preview = {}
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		MapConstructorRefreshCoordinatorRef.refresh_panels_browser_then_field(self)
	)
	list.add_child(apply_template_button)
	var undo_template_button: Button = _make_map_constructor_action_button("Undo Last Template")
	undo_template_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("undo_last_map_constructor_room_template"):
			return
		var undo_result: Dictionary = mission_manager_runtime.call("undo_last_map_constructor_room_template")
		show_hint(String(undo_result.get("message", "Template undo completed.")))
		map_constructor_state.map_constructor_template_preview = {}
		map_constructor_state.map_constructor_template_preview_can_apply = false
		map_constructor_state.map_constructor_template_pending_apply_key = ""
		MapConstructorRefreshCoordinatorRef.refresh_panels_browser_then_field(self)
	)
	list.add_child(undo_template_button)
	for preview_bundle in [{"title":"Kit Preview","data":map_constructor_state.map_constructor_kit_preview},{"title":"Template Preview","data":map_constructor_state.map_constructor_template_preview}]:
		var preview_data: Dictionary = _safe_ui_dictionary(preview_bundle.get("data", {}))
		if preview_data.is_empty():
			continue
		var summary_lines: Array[String] = []
		var affected_rows: Array = _safe_ui_array(preview_data.get("affected", []))
		var conflict_rows: Array = _safe_ui_array(preview_data.get("conflicts", []))
		var warning_rows: Array = _safe_ui_array(preview_data.get("warnings", []))
		summary_lines.append("%s: affected=%d conflicts=%d warnings=%d" % [String(preview_bundle.get("title", "")), affected_rows.size(), conflict_rows.size(), warning_rows.size()])
		for index in range(mini(10, affected_rows.size())):
			summary_lines.append("- affected: %s" % JSON.stringify(affected_rows[index]))
		for index in range(mini(10, conflict_rows.size())):
			summary_lines.append("- conflict: %s" % JSON.stringify(conflict_rows[index]))
		for index in range(mini(10, warning_rows.size())):
			summary_lines.append("- warning: %s" % String(warning_rows[index]))
		var summary_label: Label = Label.new()
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_label.text = "\n".join(summary_lines)
		list.add_child(summary_label)
	var overlay_mode_option: OptionButton = OptionButton.new()
	for overlay_name in ["None", "Selection", "Multi-select", "Validation Issues", "Expected Invalid", "Power Network", "Links", "Wall-mounted Sides"]:
		overlay_mode_option.add_item(overlay_name)
	var overlay_idx: int = maxi(0, ["None", "Selection", "Multi-select", "Validation Issues", "Expected Invalid", "Power Network", "Links", "Wall-mounted Sides"].find(map_constructor_state.map_constructor_overlay_mode))
	overlay_mode_option.select(overlay_idx)
	overlay_mode_option.item_selected.connect(func(index: int) -> void:
		map_constructor_state.map_constructor_overlay_mode = overlay_mode_option.get_item_text(index)
		_request_map_constructor_overlay_refresh()
		show_hint("Overlay data ready; renderer overlay refreshed.")
	)
	list.add_child(overlay_mode_option)
	var room_preset_title: Label = Label.new()
	room_preset_title.text = "Room Visual Presets"
	list.add_child(room_preset_title)
	var preset_catalog: Dictionary = mission_manager_runtime.call("get_room_visual_preset_catalog") if mission_manager_runtime != null and mission_manager_runtime.has_method("get_room_visual_preset_catalog") else {}
	var preset_rows: Array = _safe_ui_array(preset_catalog.get("presets", []))
	var preset_select: OptionButton = OptionButton.new()
	for preset_row_variant in preset_rows:
		var preset_row: Dictionary = _safe_ui_dictionary(preset_row_variant)
		preset_select.add_item(String(preset_row.get("display_name", preset_row.get("id", ""))))
		preset_select.set_item_metadata(preset_select.item_count - 1, String(preset_row.get("id", "")))
	if map_constructor_state.selected_room_visual_preset_id.is_empty() and not preset_rows.is_empty():
		map_constructor_state.selected_room_visual_preset_id = String(_safe_ui_dictionary(preset_rows[0]).get("id", ""))
	for preset_index in range(preset_select.item_count):
		if String(preset_select.get_item_metadata(preset_index)) == map_constructor_state.selected_room_visual_preset_id:
			preset_select.select(preset_index)
			break
	preset_select.item_selected.connect(func(index: int) -> void:
		map_constructor_state.selected_room_visual_preset_id = String(preset_select.get_item_metadata(index))
		map_constructor_state.room_visual_preset_preview.clear()
		_refresh_map_constructor_panels()
	)
	list.add_child(preset_select)
	var preset_info_label: Label = Label.new()
	preset_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for preset_row_variant in preset_rows:
		var preset_row: Dictionary = _safe_ui_dictionary(preset_row_variant)
		if String(preset_row.get("id", "")) == map_constructor_state.selected_room_visual_preset_id:
			preset_info_label.text = String(preset_row.get("description", ""))
	list.add_child(preset_info_label)
	var preview_preset_button: Button = _make_map_constructor_action_button("Preview Preset")
	preview_preset_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("preview_room_visual_preset"):
			return
		map_constructor_state.room_visual_preset_preview = mission_manager_runtime.call("preview_room_visual_preset", map_constructor_state.selected_room_visual_preset_id, {"scope":"task_test_room", "include_walls":true, "include_doors":true, "include_terminals":true})
		show_hint(String(map_constructor_state.room_visual_preset_preview.get("message", "Preview ready.")))
		_refresh_map_constructor_panels()
	)
	list.add_child(preview_preset_button)
	var apply_preset_button: Button = _make_map_constructor_action_button("Apply Preset")
	apply_preset_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("apply_room_visual_preset"):
			return
		var apply_preset_result: Dictionary = mission_manager_runtime.call("apply_room_visual_preset", map_constructor_state.selected_room_visual_preset_id, {"scope":"task_test_room", "include_walls":true, "include_doors":true, "include_terminals":true})
		show_hint(String(apply_preset_result.get("message", "Preset applied.")))
		if bool(apply_preset_result.get("ok", false)) and mission_manager_runtime.has_method("preview_room_visual_preset"):
			map_constructor_state.room_visual_preset_preview = mission_manager_runtime.call("preview_room_visual_preset", map_constructor_state.selected_room_visual_preset_id, {"scope":"task_test_room", "include_walls":true, "include_doors":true, "include_terminals":true})
		else:
			map_constructor_state.room_visual_preset_preview.clear()
		MapConstructorRefreshCoordinatorRef.refresh_panels_overlay_then_field(self)
	)
	list.add_child(apply_preset_button)
	var clear_preset_button: Button = _make_map_constructor_action_button("Clear Preset Overrides")
	clear_preset_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("clear_room_visual_preset_overrides"):
			return
		var clear_preset_result: Dictionary = mission_manager_runtime.call("clear_room_visual_preset_overrides", {})
		show_hint(String(clear_preset_result.get("message", "Preset overrides cleared.")))
		map_constructor_state.room_visual_preset_preview.clear()
		MapConstructorRefreshCoordinatorRef.refresh_panels_overlay_then_field(self)
	)
	list.add_child(clear_preset_button)
	if not map_constructor_state.room_visual_preset_preview.is_empty():
		var room_preview_summary: Dictionary = _safe_ui_dictionary(map_constructor_state.room_visual_preset_preview.get("summary", {}))
		var room_preview_label: Label = Label.new()
		room_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		room_preview_label.text = "Preset Preview: walls=%d doors=%d terminals=%d can_apply=%s\n%s" % [int(room_preview_summary.get("affected_walls", 0)), int(room_preview_summary.get("affected_doors", 0)), int(room_preview_summary.get("affected_terminals", 0)), str(bool(map_constructor_state.room_visual_preset_preview.get("can_apply", false))), String(map_constructor_state.room_visual_preset_preview.get("message", ""))]
		list.add_child(room_preview_label)
	var room_design_notes_button: Button = _make_map_constructor_action_button("Generate Design Notes")
	room_design_notes_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("export_map_constructor_design_notes"):
			return
		var notes_res: Dictionary = mission_manager_runtime.call("export_map_constructor_design_notes", {})
		map_constructor_state.map_constructor_design_notes_text = String(notes_res.get("text", ""))
		_refresh_map_constructor_panels()
	)
	list.add_child(room_design_notes_button)
	var notes_edit: TextEdit = TextEdit.new()
	notes_edit.custom_minimum_size = Vector2(0, 120)
	notes_edit.text = map_constructor_state.map_constructor_design_notes_text
	list.add_child(notes_edit)
	var pipeline_button: Button = _make_map_constructor_action_button("Build Promotion Package")
	pipeline_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_production_pipeline_report"):
			return
		map_constructor_state.map_constructor_pipeline_report = mission_manager_runtime.call("get_map_constructor_production_pipeline_report", {})
		_refresh_map_constructor_panels()
	)
	list.add_child(pipeline_button)
	var refresh_package_button: Button = _make_map_constructor_action_button("Refresh Package")
	refresh_package_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_production_pipeline_report"):
			return
		map_constructor_state.map_constructor_pipeline_report = mission_manager_runtime.call("get_map_constructor_production_pipeline_report", {})
		_refresh_map_constructor_panels()
	)
	list.add_child(refresh_package_button)
	if not map_constructor_state.map_constructor_pipeline_report.is_empty():
		var pipeline_status: String = String(map_constructor_state.map_constructor_pipeline_report.get("status", "unknown"))
		var pipeline_message: String = String(map_constructor_state.map_constructor_pipeline_report.get("message", ""))
		var pipeline_lines: Array[String] = ["Pipeline status: %s" % pipeline_status, pipeline_message]
		var checks: Array = _safe_ui_array(map_constructor_state.map_constructor_pipeline_report.get("checks", []))
		for check_index in range(mini(12, checks.size())):
			var check_row: Dictionary = _safe_ui_dictionary(checks[check_index])
			var check_line: String = "- %s [%s]" % [String(check_row.get("label", "")), String(check_row.get("status", ""))]
			var check_message: String = String(check_row.get("message", "")).strip_edges()
			if not check_message.is_empty():
				check_line += " — %s" % check_message
			pipeline_lines.append(check_line)
		var promotion_package: Dictionary = _safe_ui_dictionary(map_constructor_state.map_constructor_pipeline_report.get("promotion_package", {}))
		var package_warnings: Array = _safe_ui_array(promotion_package.get("warnings", []))
		pipeline_lines.append("Warning summary: count=%d" % package_warnings.size())
		for warning_index in range(mini(5, package_warnings.size())):
			pipeline_lines.append("  • %s" % String(package_warnings[warning_index]))
		var manual_steps: Array = _safe_ui_array(promotion_package.get("manual_steps", []))
		if not manual_steps.is_empty():
			pipeline_lines.append("Manual steps:")
			for manual_step in manual_steps:
				pipeline_lines.append("  - %s" % String(manual_step))
		var pipeline_label: Label = Label.new()
		pipeline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pipeline_label.text = "\n".join(pipeline_lines)
		list.add_child(pipeline_label)
	var refresh_audit_button: Button = _make_map_constructor_action_button("Refresh Audit")
	refresh_audit_button.pressed.connect(func() -> void:
		_refresh_map_constructor_panels()
	)
	list.add_child(refresh_audit_button)
	var cleanup_title: Label = Label.new()
	cleanup_title.text = "Cleanup Tools"
	list.add_child(cleanup_title)
	var multi_title: Label = Label.new()
	multi_title.text = "Multi-select / Batch Tools"
	list.add_child(multi_title)
	_refresh_map_constructor_multi_selection_stale()
	var selected_ids: Array[String] = []
	for selected_row in map_constructor_state.map_constructor_multi_selected_entities:
		selected_ids.append(String(selected_row.get("entity_id", "")))
	var multi_info: Label = Label.new()
	multi_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	multi_info.text = "Selected: %d\n%s" % [map_constructor_state.map_constructor_multi_selected_entities.size(), ", ".join(selected_ids.slice(0, mini(10, selected_ids.size())))]
	list.add_child(multi_info)
	var select_actions: HFlowContainer = _make_map_constructor_action_row()
	var add_current: Button = _make_map_constructor_action_button("Add Current Selection")
	add_current.pressed.connect(func() -> void:
		_add_map_constructor_multi_row_if_missing(_make_map_constructor_multi_row_from_current_selection())
		_refresh_map_constructor_multi_selection_stale()
		_refresh_map_constructor_panels()
	)
	var remove_current: Button = _make_map_constructor_action_button("Remove Current Selection")
	remove_current.pressed.connect(func() -> void:
		var keep: Array[Dictionary] = []
		for row in map_constructor_state.map_constructor_multi_selected_entities:
			if String(row.get("entity_kind", "")) == map_constructor_state.selected_map_constructor_entity_kind and String(row.get("entity_id", "")) == map_constructor_state.selected_map_constructor_entity_id:
				continue
			keep.append(row)
		map_constructor_state.map_constructor_multi_selected_entities = keep
		_refresh_map_constructor_multi_selection_stale()
		_refresh_map_constructor_panels()
	)
	var clear_multi: Button = _make_map_constructor_action_button("Clear Multi-select")
	clear_multi.pressed.connect(func() -> void: map_constructor_state.map_constructor_multi_selected_entities.clear(); _clear_map_constructor_batch_preview_state(); _refresh_map_constructor_panels())
	select_actions.add_child(add_current); select_actions.add_child(remove_current); select_actions.add_child(clear_multi); list.add_child(select_actions)
	var quick_select: HFlowContainer = _make_map_constructor_action_row()
	for quick in [{"label":"All Constructor","mode":"all_constructor"},{"label":"All Items","mode":"items"},{"label":"Wall-mounted","mode":"wall_mounted"},{"label":"Doors","mode":"doors"},{"label":"Terminals","mode":"terminals"},{"label":"Power","mode":"power"},{"label":"Control","mode":"control"}]:
		var select_button: Button = _make_map_constructor_action_button("Select %s" % String(quick.get("label", "")))
		select_button.pressed.connect(func() -> void:
			_add_map_constructor_multi_selection_by_filter(String(quick.get("mode", "")))
			_refresh_map_constructor_panels()
		)
		quick_select.add_child(select_button)
	list.add_child(quick_select)
	var offset_row: HFlowContainer = _make_map_constructor_action_row()
	var ox: SpinBox = SpinBox.new(); ox.min_value = -100; ox.max_value = 100; ox.step = 1; ox.value = map_constructor_state.map_constructor_batch_offset_x; ox.value_changed.connect(func(v: float) -> void: map_constructor_state.map_constructor_batch_offset_x = int(v))
	var oy: SpinBox = SpinBox.new(); oy.min_value = -100; oy.max_value = 100; oy.step = 1; oy.value = map_constructor_state.map_constructor_batch_offset_y; oy.value_changed.connect(func(v: float) -> void: map_constructor_state.map_constructor_batch_offset_y = int(v))
	var pn: LineEdit = LineEdit.new(); pn.text = map_constructor_state.map_constructor_batch_power_network_id; pn.placeholder_text = "Power network id"; pn.text_changed.connect(func(t: String) -> void: map_constructor_state.map_constructor_batch_power_network_id = t)
	offset_row.add_child(Label.new()); offset_row.get_child(0).set("text", "Offset X/Y:")
	offset_row.add_child(ox); offset_row.add_child(oy); offset_row.add_child(pn); list.add_child(offset_row)
	var batch_buttons: HFlowContainer = _make_map_constructor_action_row()
	for op in [{"label":"Preview Move","op":"move_selected"},{"label":"Apply Move","op":"move_selected","apply":true},{"label":"Preview Duplicate","op":"duplicate_selected"},{"label":"Apply Duplicate","op":"duplicate_selected","apply":true},{"label":"Preview Delete","op":"delete_selected"},{"label":"Apply Delete","op":"delete_selected","apply":true},{"label":"Preview Assign Power","op":"assign_power_network"},{"label":"Apply Assign Power","op":"assign_power_network","apply":true},{"label":"Preview Clear Broken Refs","op":"clear_broken_references"},{"label":"Apply Clear Broken Refs","op":"clear_broken_references","apply":true}]:
		var b: Button = _make_map_constructor_action_button(String(op.get("label", "")))
		var apply_mode: bool = bool(op.get("apply", false))
		var current_key: String = _build_map_constructor_batch_operation_key(String(op.get("op", "")))
		if apply_mode:
			b.disabled = map_constructor_state.map_constructor_batch_pending_apply_operation != String(op.get("op", "")) or map_constructor_state.map_constructor_batch_pending_apply_key != current_key
		b.pressed.connect(func() -> void:
			if mission_manager_runtime == null:
				return
			var options: Dictionary = {"offset":Vector2i(map_constructor_state.map_constructor_batch_offset_x, map_constructor_state.map_constructor_batch_offset_y), "power_network_id":map_constructor_state.map_constructor_batch_power_network_id}
			var op_name: String = String(op.get("op", ""))
			if not apply_mode:
				map_constructor_state.map_constructor_batch_preview = mission_manager_runtime.call("preview_map_constructor_batch_operation", op_name, map_constructor_state.map_constructor_multi_selected_entities, options)
				if bool(map_constructor_state.map_constructor_batch_preview.get("can_apply", false)):
					map_constructor_state.map_constructor_batch_pending_apply_operation = op_name
					map_constructor_state.map_constructor_batch_pending_apply_key = _build_map_constructor_batch_operation_key(op_name)
				else:
					map_constructor_state.map_constructor_batch_pending_apply_operation = ""
					map_constructor_state.map_constructor_batch_pending_apply_key = ""
				show_hint(String(map_constructor_state.map_constructor_batch_preview.get("message", "Preview ready.")))
			else:
				var apply_result: Dictionary = mission_manager_runtime.call("apply_map_constructor_batch_operation", op_name, map_constructor_state.map_constructor_multi_selected_entities, options)
				show_hint(String(apply_result.get("message", "Batch applied.")))
				_refresh_map_constructor_multi_selection_stale()
				if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_entity_by_id") and not map_constructor_state.selected_map_constructor_entity_id.is_empty():
					var selected_entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", map_constructor_state.selected_map_constructor_entity_kind, map_constructor_state.selected_map_constructor_entity_id)
					if not bool(selected_entity.get("ok", false)):
						_show_map_constructor_inspector(Vector2i(-1, -1))
				_clear_map_constructor_batch_preview_state()
				MapConstructorRefreshCoordinatorRef.request_field_visual_refresh(self)
			_refresh_map_constructor_panels()
		)
		batch_buttons.add_child(b)
	list.add_child(batch_buttons)
	var undo_batch_button: Button = _make_map_constructor_action_button("Undo Last Batch")
	undo_batch_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("undo_last_map_constructor_batch_operation"):
			return
		var undo_result: Dictionary = mission_manager_runtime.call("undo_last_map_constructor_batch_operation")
		show_hint(String(undo_result.get("message", "Undo done.")))
		_refresh_map_constructor_multi_selection_stale()
		if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_entity_by_id") and not map_constructor_state.selected_map_constructor_entity_id.is_empty():
			var selected_entity: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", map_constructor_state.selected_map_constructor_entity_kind, map_constructor_state.selected_map_constructor_entity_id)
			if not bool(selected_entity.get("ok", false)):
				_show_map_constructor_inspector(Vector2i(-1, -1))
		_clear_map_constructor_batch_preview_state()
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	list.add_child(undo_batch_button)
	if not map_constructor_state.map_constructor_batch_preview.is_empty():
		var preview_lines: Array[String] = []
		preview_lines.append("Batch Preview: %s" % String(map_constructor_state.map_constructor_batch_preview.get("operation_type", "")))
		preview_lines.append("affected=%d warnings=%d conflicts=%d" % [int(map_constructor_state.map_constructor_batch_preview.get("affected_count", 0)), _safe_ui_array(map_constructor_state.map_constructor_batch_preview.get("warnings", [])).size(), _safe_ui_array(map_constructor_state.map_constructor_batch_preview.get("conflicts", [])).size()])
		var affected_rows: Array = _safe_ui_array(map_constructor_state.map_constructor_batch_preview.get("affected", []))
		for i in range(mini(10, affected_rows.size())):
			var affected_row: Dictionary = _safe_ui_dictionary(affected_rows[i])
			preview_lines.append("- %s %s from=%s to=%s fields=%s" % [String(affected_row.get("entity_id", "")), String(affected_row.get("operation", "")), str(affected_row.get("from_cell", Vector2i(-1, -1))), str(affected_row.get("to_cell", Vector2i(-1, -1))), JSON.stringify(affected_row.get("field_changes", []))])
		var warn_rows: Array = _safe_ui_array(map_constructor_state.map_constructor_batch_preview.get("warnings", []))
		var conflict_rows: Array = _safe_ui_array(map_constructor_state.map_constructor_batch_preview.get("conflicts", []))
		for i in range(mini(5, warn_rows.size())):
			preview_lines.append("warning: %s" % String(warn_rows[i]))
		for i in range(mini(5, conflict_rows.size())):
			preview_lines.append("conflict: %s" % JSON.stringify(conflict_rows[i]))
		var preview_summary: Label = Label.new()
		preview_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_summary.text = "\n".join(preview_lines)
		list.add_child(preview_summary)
	var cleanup_actions: Array[Dictionary] = [
		{"label":"Items","cleanup_type":"items","options":{}},
		{"label":"Wall-mounted","cleanup_type":"wall_mounted","options":{}},
		{"label":"Doors","cleanup_type":"type_group","options":{"type_group":"door"}},
		{"label":"Terminals","cleanup_type":"type_group","options":{"type_group":"terminal"}},
		{"label":"Power","cleanup_type":"type_group","options":{"type_group":"power"}},
		{"label":"Control","cleanup_type":"type_group","options":{"type_group":"control"}},
		{"label":"Invalid References","cleanup_type":"invalid_references","options":{}},
		{"label":"All Constructor Objects","cleanup_type":"all_constructor_objects","options":{}}
	]
	for action in cleanup_actions:
		var action_row: HFlowContainer = _make_map_constructor_action_row()
		var ctype: String = String(action.get("cleanup_type", ""))
		var coptions: Dictionary = _safe_ui_dictionary(action.get("options", {}))
		var preview_button: Button = _make_map_constructor_action_button("Preview %s" % String(action.get("label", "")))
		preview_button.pressed.connect(func() -> void:
			_apply_map_constructor_cleanup_action(ctype, coptions, false)
		)
		var apply_label: String = "Delete %s" % String(action.get("label", ""))
		if ctype == "invalid_references":
			apply_label = "Clean Invalid References"
		var apply_button: Button = _make_map_constructor_action_button(apply_label)
		var apply_key: String = "%s|%s" % [ctype, JSON.stringify(coptions)]
		apply_button.disabled = map_constructor_state.map_constructor_cleanup_pending_apply_key != apply_key
		apply_button.pressed.connect(func() -> void:
			_apply_map_constructor_cleanup_action(ctype, coptions, true)
		)
		action_row.add_child(preview_button)
		action_row.add_child(apply_button)
		list.add_child(action_row)
	var reset_row: HFlowContainer = _make_map_constructor_action_row()
	var reset_preview_button: Button = _make_map_constructor_action_button("Preview Reset Runtime Map")
	reset_preview_button.pressed.connect(func() -> void:
		_apply_map_constructor_cleanup_action("reset_runtime_map", {}, false)
	)
	var reset_apply_button: Button = _make_map_constructor_action_button("Apply Reset Runtime Map")
	var reset_apply_key: String = "reset_runtime_map|{}"
	reset_apply_button.disabled = map_constructor_state.map_constructor_cleanup_pending_apply_key != reset_apply_key
	reset_apply_button.pressed.connect(func() -> void:
		_apply_map_constructor_cleanup_action("reset_runtime_map", {}, true)
	)
	reset_row.add_child(reset_preview_button)
	reset_row.add_child(reset_apply_button)
	list.add_child(reset_row)
	var undo_button: Button = _make_map_constructor_action_button("Undo Last Cleanup")
	undo_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("undo_last_map_constructor_cleanup"):
			return
		var undo_result: Dictionary = mission_manager_runtime.call("undo_last_map_constructor_cleanup")
		show_hint(String(undo_result.get("message", "Undo done.")))
		map_constructor_state.map_constructor_cleanup_pending_apply_key = ""
		map_constructor_state.map_constructor_cleanup_preview.clear()
		_clear_map_constructor_preview_cell()
		_clear_map_constructor_wall_mounted_selection()
		_clear_map_constructor_link_target()
		_show_map_constructor_inspector(Vector2i(-1, -1))
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	list.add_child(undo_button)
	var autofix_title: Label = Label.new()
	autofix_title.text = "Auto-fix Tools"
	list.add_child(autofix_title)
	var autofix_actions: Array[Dictionary] = [
		{"label":"Broken References","fix_type":"clear_all_broken_references","options":{}},
		{"label":"Wall-mounted Attachments","fix_type":"repair_all_wall_mounted_attachments","options":{}}
	]
	for action in autofix_actions:
		var action_row: HFlowContainer = _make_map_constructor_action_row()
		var ftype: String = String(action.get("fix_type", ""))
		var foptions: Dictionary = _safe_ui_dictionary(action.get("options", {}))
		var preview_button: Button = _make_map_constructor_action_button("Preview %s" % String(action.get("label", "")))
		preview_button.pressed.connect(func() -> void:
			_apply_map_constructor_autofix_action(ftype, foptions, false)
		)
		var apply_button: Button = _make_map_constructor_action_button("Apply %s" % String(action.get("label", "")))
		apply_button.disabled = map_constructor_state.map_constructor_autofix_pending_apply_key != "%s|%s" % [ftype, JSON.stringify(foptions)]
		apply_button.pressed.connect(func() -> void:
			_apply_map_constructor_autofix_action(ftype, foptions, true)
		)
		action_row.add_child(preview_button)
		action_row.add_child(apply_button)
		list.add_child(action_row)
	var power_network_id_edit: LineEdit = LineEdit.new()
	power_network_id_edit.placeholder_text = "Power network id"
	power_network_id_edit.text = map_constructor_state.map_constructor_new_power_network_id
	power_network_id_edit.text_changed.connect(func(new_text: String) -> void:
		map_constructor_state.map_constructor_new_power_network_id = new_text
	)
	list.add_child(power_network_id_edit)
	var selected_object_id: String = map_constructor_state.selected_map_constructor_entity_id if map_constructor_state.selected_map_constructor_entity_kind == "world_object" else ""
	var selected_object_hint: Label = Label.new()
	selected_object_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_object_hint.text = "Select an object first." if selected_object_id.is_empty() else "Selected object: %s" % selected_object_id
	list.add_child(selected_object_hint)
	var power_assign_options: Dictionary = {"entity_kind":"world_object","entity_id":selected_object_id,"new_power_network_id":map_constructor_state.map_constructor_new_power_network_id.strip_edges()}
	var power_assign_key: String = "assign_power_network|%s" % JSON.stringify(power_assign_options)
	var power_assign_row: HFlowContainer = _make_map_constructor_action_row()
	var power_preview_button: Button = _make_map_constructor_action_button("Preview Assign Power Network")
	power_preview_button.disabled = selected_object_id.is_empty()
	power_preview_button.pressed.connect(func() -> void:
		if selected_object_id.is_empty():
			show_hint("Select an object first.")
			return
		_apply_map_constructor_autofix_action("assign_power_network", power_assign_options, false)
	)
	var power_apply_button: Button = _make_map_constructor_action_button("Apply Assign Power Network")
	power_apply_button.disabled = map_constructor_state.map_constructor_autofix_pending_apply_key != power_assign_key or int(map_constructor_state.map_constructor_autofix_preview.get("affected_count", 0)) <= 0
	power_apply_button.pressed.connect(func() -> void:
		_apply_map_constructor_autofix_action("assign_power_network", power_assign_options, true)
	)
	power_assign_row.add_child(power_preview_button)
	power_assign_row.add_child(power_apply_button)
	list.add_child(power_assign_row)
	var autofix_undo_button: Button = _make_map_constructor_action_button("Undo Last Auto-fix")
	autofix_undo_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("undo_last_map_constructor_autofix"):
			return
		var undo_result: Dictionary = mission_manager_runtime.call("undo_last_map_constructor_autofix")
		show_hint(String(undo_result.get("message", "Undo done.")))
		map_constructor_state.map_constructor_autofix_pending_apply_key = ""
		map_constructor_state.map_constructor_autofix_preview.clear()
		_clear_map_constructor_preview_cell()
		_clear_map_constructor_wall_mounted_selection()
		_clear_map_constructor_link_target()
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	list.add_child(autofix_undo_button)
	if not map_constructor_state.map_constructor_cleanup_preview.is_empty():
		var preview_label: Label = Label.new()
		var affected_count: int = int(map_constructor_state.map_constructor_cleanup_preview.get("affected_count", 0))
		var preview_ids: Array[String] = []
		for row in _safe_ui_array(map_constructor_state.map_constructor_cleanup_preview.get("affected_objects", [])):
			if preview_ids.size() >= 10:
				break
			preview_ids.append(String(_safe_ui_dictionary(row).get("id", "")))
		var preview_ids_text: String = ""
		for i in range(preview_ids.size()):
			if i > 0:
				preview_ids_text += ", "
			preview_ids_text += preview_ids[i]
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_label.text = "Cleanup preview: %d affected\n%s" % [affected_count, preview_ids_text]
		list.add_child(preview_label)
	if not map_constructor_state.map_constructor_autofix_preview.is_empty():
		var autofix_preview_label := Label.new()
		autofix_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lines: Array[String] = []
		for row in _safe_ui_array(map_constructor_state.map_constructor_autofix_preview.get("affected_fixes", [])):
			if lines.size() >= 10:
				break
			lines.append(String(_safe_ui_dictionary(row).get("description", "")))
		autofix_preview_label.text = "Auto-fix preview: %d affected\n%s" % [int(map_constructor_state.map_constructor_autofix_preview.get("affected_count", 0)), "\n".join(lines)]
		list.add_child(autofix_preview_label)
	var patch_title: Label = Label.new()
	patch_title.text = "Patch Tools"
	list.add_child(patch_title)
	var patch_json_edit: TextEdit = TextEdit.new()
	patch_json_edit.custom_minimum_size = Vector2(0, 160)
	patch_json_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	patch_json_edit.text = map_constructor_state.map_constructor_patch_json_text
	patch_json_edit.text_changed.connect(func() -> void:
		map_constructor_state.map_constructor_patch_json_text = patch_json_edit.text
	)
	list.add_child(patch_json_edit)
	var patch_actions: HFlowContainer = _make_map_constructor_action_row()
	var export_patch_button: Button = _make_map_constructor_action_button("Export Current Patch")
	export_patch_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("export_map_constructor_runtime_patch"):
			return
		var export_res: Dictionary = mission_manager_runtime.call("export_map_constructor_runtime_patch")
		map_constructor_state.map_constructor_patch_json_text = String(export_res.get("json", ""))
		patch_json_edit.text = map_constructor_state.map_constructor_patch_json_text
		show_hint(String(export_res.get("message", "Export done.")))
		_refresh_map_constructor_panels()
	)
	var preview_patch_button: Button = _make_map_constructor_action_button("Parse/Preview Patch")
	preview_patch_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("parse_map_constructor_patch_json"):
			return
		var parsed_res: Dictionary = mission_manager_runtime.call("parse_map_constructor_patch_json", map_constructor_state.map_constructor_patch_json_text)
		map_constructor_state.map_constructor_patch_parsed = parsed_res
		map_constructor_state.map_constructor_patch_preview.clear()
		map_constructor_state.map_constructor_patch_pending_apply = false
		if bool(parsed_res.get("ok", false)) and mission_manager_runtime.has_method("preview_apply_map_constructor_patch"):
			var preview_res: Dictionary = mission_manager_runtime.call("preview_apply_map_constructor_patch", _safe_ui_dictionary(parsed_res.get("patch", {})))
			map_constructor_state.map_constructor_patch_preview = preview_res
			map_constructor_state.map_constructor_patch_pending_apply = bool(preview_res.get("ok", false)) and bool(preview_res.get("can_apply", false))
		show_hint(String(parsed_res.get("message", "Patch parsed.")))
		_refresh_map_constructor_panels()
	)
	var apply_patch_button: Button = _make_map_constructor_action_button("Apply Patch")
	apply_patch_button.disabled = not map_constructor_state.map_constructor_patch_pending_apply
	apply_patch_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("apply_map_constructor_patch"):
			return
		var apply_res: Dictionary = mission_manager_runtime.call("apply_map_constructor_patch", _safe_ui_dictionary(map_constructor_state.map_constructor_patch_parsed.get("patch", {})), {})
		show_hint(String(apply_res.get("message", "Patch applied.")))
		map_constructor_state.map_constructor_patch_pending_apply = false
		MapConstructorRefreshCoordinatorRef.refresh_field_then_panels(self)
	)
	var rollback_patch_button: Button = _make_map_constructor_action_button("Rollback Last Patch")
	rollback_patch_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("rollback_last_map_constructor_patch"):
			return
		var rollback_res: Dictionary = mission_manager_runtime.call("rollback_last_map_constructor_patch")
		show_hint(String(rollback_res.get("message", "Rollback done.")))
		_clear_map_constructor_preview_cell()
		_clear_map_constructor_wall_mounted_selection()
		_clear_map_constructor_link_target()
		_show_map_constructor_inspector(Vector2i(-1, -1))
		map_constructor_state.map_constructor_patch_pending_apply = false
		map_constructor_state.map_constructor_patch_preview.clear()
		map_constructor_state.map_constructor_patch_parsed.clear()
		MapConstructorRefreshCoordinatorRef.refresh_field_then_panels(self)
	)
	patch_actions.add_child(export_patch_button)
	patch_actions.add_child(preview_patch_button)
	patch_actions.add_child(apply_patch_button)
	patch_actions.add_child(rollback_patch_button)
	list.add_child(patch_actions)
	var history_title: Label = Label.new()
	history_title.text = "Change History"
	list.add_child(history_title)
	var history_result: Dictionary = {}
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_change_history"):
		history_result = mission_manager_runtime.call("get_map_constructor_change_history", 200)
	var history_total_label: Label = Label.new()
	history_total_label.text = "Total: %d" % int(history_result.get("total_count", 0))
	list.add_child(history_total_label)
	var history_filter: OptionButton = OptionButton.new()
	for opt in MAP_CONSTRUCTOR_HISTORY_FILTER_OPTIONS:
		history_filter.add_item(opt)
	var history_filter_index: int = MAP_CONSTRUCTOR_HISTORY_FILTER_OPTIONS.find(map_constructor_state.map_constructor_change_history_filter)
	if history_filter_index < 0:
		history_filter_index = 0
		map_constructor_state.map_constructor_change_history_filter = "All"
	history_filter.select(history_filter_index)
	history_filter.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < MAP_CONSTRUCTOR_HISTORY_FILTER_OPTIONS.size():
			map_constructor_state.map_constructor_change_history_filter = MAP_CONSTRUCTOR_HISTORY_FILTER_OPTIONS[index]
			_refresh_map_constructor_panels()
	)
	list.add_child(history_filter)
	var history_buttons: HFlowContainer = _make_map_constructor_action_row()
	var history_clear_button: Button = _make_map_constructor_action_button("Clear History")
	history_clear_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("clear_map_constructor_change_history"):
			return
		var clear_result: Dictionary = mission_manager_runtime.call("clear_map_constructor_change_history")
		show_hint(String(clear_result.get("message", "History cleared.")))
		_refresh_map_constructor_panels()
	)
	var history_refresh_button: Button = _make_map_constructor_action_button("Refresh History")
	history_refresh_button.pressed.connect(func() -> void:
		_refresh_map_constructor_panels()
	)
	history_buttons.add_child(history_clear_button)
	history_buttons.add_child(history_refresh_button)
	list.add_child(history_buttons)
	var history_rows: Array = _safe_ui_array(history_result.get("history", []))
	var shown_count: int = 0
	for i in range(history_rows.size() - 1, -1, -1):
		var row: Dictionary = _safe_ui_dictionary(history_rows[i])
		var action_type: String = String(row.get("action_type", "unknown"))
		if not _map_constructor_history_matches_filter(action_type):
			continue
		var row_text: String = "#%d [%s] %s" % [int(row.get("seq", 0)), action_type, String(row.get("summary", ""))]
		var row_entity_id: String = String(row.get("entity_id", ""))
		if not row_entity_id.is_empty():
			row_text += " | id=%s" % row_entity_id
		var row_cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
		if row_cell.x >= 0 and row_cell.y >= 0:
			row_text += " | c=(%d,%d)" % [row_cell.x, row_cell.y]
		var history_row_line: HBoxContainer = HBoxContainer.new()
		var history_row_label: Label = Label.new()
		history_row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		history_row_label.clip_text = true
		history_row_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		history_row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		history_row_label.text = row_text
		history_row_line.add_child(history_row_label)
		if not row_entity_id.is_empty() or (row_cell.x >= 0 and row_cell.y >= 0):
			var jump_btn: Button = _make_map_constructor_action_button("Jump")
			jump_btn.pressed.connect(func() -> void:
				_jump_to_map_constructor_history_row(row)
			)
			history_row_line.add_child(jump_btn)
		list.add_child(history_row_line)
		shown_count += 1
		if shown_count >= 30:
			break
	var overview_title: Label = Label.new()
	overview_title.text = "Minimap / Overview"
	list.add_child(overview_title)
	var overview_button_row: HFlowContainer = _make_map_constructor_action_row()
	var overview_hud_button: Button = _make_map_constructor_action_button("Hide Overview" if map_constructor_state.map_constructor_overview_hud_visible else "Show Overview")
	overview_hud_button.pressed.connect(func() -> void:
		_toggle_map_constructor_overview_hud()
	)
	overview_button_row.add_child(overview_hud_button)
	var refresh_overview_button: Button = _make_map_constructor_action_button("Refresh Overview")
	refresh_overview_button.pressed.connect(func() -> void:
		_refresh_map_constructor_overview_hud()
	)
	overview_button_row.add_child(refresh_overview_button)
	list.add_child(overview_button_row)
	var overview_filter: OptionButton = OptionButton.new()
	for opt in MAP_CONSTRUCTOR_OVERVIEW_FILTER_OPTIONS:
		overview_filter.add_item(opt)
	var overview_filter_idx: int = MAP_CONSTRUCTOR_OVERVIEW_FILTER_OPTIONS.find(map_constructor_state.map_constructor_overview_filter)
	if overview_filter_idx < 0:
		overview_filter_idx = 0
		map_constructor_state.map_constructor_overview_filter = "All"
	overview_filter.select(overview_filter_idx)
	overview_filter.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < MAP_CONSTRUCTOR_OVERVIEW_FILTER_OPTIONS.size():
			map_constructor_state.map_constructor_overview_filter = MAP_CONSTRUCTOR_OVERVIEW_FILTER_OPTIONS[index]
			_refresh_map_constructor_panels()
	)
	list.add_child(overview_filter)
	var overview_toggle_row_a: HFlowContainer = _make_map_constructor_action_row()
	var overview_show_issues: CheckButton = CheckButton.new()
	overview_show_issues.text = "Show Issues"
	overview_show_issues.button_pressed = map_constructor_state.map_constructor_overview_show_issues
	overview_show_issues.toggled.connect(func(pressed: bool) -> void:
		map_constructor_state.map_constructor_overview_show_issues = pressed
		_refresh_map_constructor_panels()
	)
	overview_toggle_row_a.add_child(overview_show_issues)
	var overview_show_power: CheckButton = CheckButton.new()
	overview_show_power.text = "Show Power"
	overview_show_power.button_pressed = map_constructor_state.map_constructor_overview_show_power
	overview_show_power.toggled.connect(func(pressed: bool) -> void:
		map_constructor_state.map_constructor_overview_show_power = pressed
		_refresh_map_constructor_panels()
	)
	overview_toggle_row_a.add_child(overview_show_power)
	var overview_show_items: CheckButton = CheckButton.new()
	overview_show_items.text = "Show Items"
	overview_show_items.button_pressed = map_constructor_state.map_constructor_overview_show_items
	overview_show_items.toggled.connect(func(pressed: bool) -> void:
		map_constructor_state.map_constructor_overview_show_items = pressed
		_refresh_map_constructor_panels()
	)
	overview_toggle_row_a.add_child(overview_show_items)
	list.add_child(overview_toggle_row_a)
	var overview_toggle_row_b: HFlowContainer = _make_map_constructor_action_row()
	var overview_show_wall_mounted: CheckButton = CheckButton.new()
	overview_show_wall_mounted.text = "Show Wall-mounted"
	overview_show_wall_mounted.button_pressed = map_constructor_state.map_constructor_overview_show_wall_mounted
	overview_show_wall_mounted.toggled.connect(func(pressed: bool) -> void:
		map_constructor_state.map_constructor_overview_show_wall_mounted = pressed
		_refresh_map_constructor_panels()
	)
	overview_toggle_row_b.add_child(overview_show_wall_mounted)
	var overview_show_history: CheckButton = CheckButton.new()
	overview_show_history.text = "Show History"
	overview_show_history.button_pressed = map_constructor_state.map_constructor_overview_show_history
	overview_show_history.toggled.connect(func(pressed: bool) -> void:
		map_constructor_state.map_constructor_overview_show_history = pressed
		_refresh_map_constructor_panels()
	)
	overview_toggle_row_b.add_child(overview_show_history)
	list.add_child(overview_toggle_row_b)
	_add_map_constructor_section_header(list, "CONSTRUCTOR PRESETS")
	var preset_name_edit: LineEdit = LineEdit.new()
	preset_name_edit.placeholder_text = "Preset name"
	preset_name_edit.text = map_constructor_state.map_constructor_preset_name
	preset_name_edit.text_changed.connect(func(new_text: String) -> void:
		map_constructor_state.map_constructor_preset_name = new_text
	)
	list.add_child(preset_name_edit)
	if mission_manager_runtime != null and mission_manager_runtime.has_method("list_map_constructor_presets"):
		map_constructor_state.map_constructor_preset_entries = mission_manager_runtime.call("list_map_constructor_presets")
	if map_constructor_state.map_constructor_selected_preset_name.is_empty() and not map_constructor_state.map_constructor_preset_entries.is_empty():
		map_constructor_state.map_constructor_selected_preset_name = String(map_constructor_state.map_constructor_preset_entries[0].get("name", ""))
	var constructor_preset_select: OptionButton = OptionButton.new()
	for i in range(map_constructor_state.map_constructor_preset_entries.size()):
		var entry: Dictionary = map_constructor_state.map_constructor_preset_entries[i]
		var preset_name: String = String(entry.get("name", ""))
		constructor_preset_select.add_item(preset_name)
		if preset_name == map_constructor_state.map_constructor_selected_preset_name:
			constructor_preset_select.select(i)
	constructor_preset_select.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < map_constructor_state.map_constructor_preset_entries.size():
			map_constructor_state.map_constructor_selected_preset_name = String(map_constructor_state.map_constructor_preset_entries[index].get("name", ""))
	)
	list.add_child(constructor_preset_select)
	var preset_actions: HFlowContainer = _make_map_constructor_action_row()
	list.add_child(preset_actions)
	var save_preset_button: Button = _make_map_constructor_action_button("Save")
	save_preset_button.pressed.connect(func() -> void:
		if not map_constructor_state.map_constructor_mode_active or mission_manager_runtime == null or not mission_manager_runtime.has_method("save_map_constructor_preset"):
			show_hint("Preset save unavailable.")
			return
		var save_result: Dictionary = mission_manager_runtime.call("save_map_constructor_preset", map_constructor_state.map_constructor_preset_name)
		show_hint(String(save_result.get("message", "Preset save done.")))
		map_constructor_state.map_constructor_selected_preset_name = String(save_result.get("preset_name", map_constructor_state.map_constructor_selected_preset_name))
		_show_map_constructor_inspector(map_constructor_state.pending_map_constructor_cell)
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	preset_actions.add_child(save_preset_button)
	var load_preset_button: Button = _make_map_constructor_action_button("Load selected")
	load_preset_button.pressed.connect(func() -> void:
		if not map_constructor_state.map_constructor_mode_active or map_constructor_state.map_constructor_selected_preset_name.is_empty() or mission_manager_runtime == null or not mission_manager_runtime.has_method("load_map_constructor_preset"):
			show_hint("Preset load unavailable.")
			return
		var load_result: Dictionary = mission_manager_runtime.call("load_map_constructor_preset", map_constructor_state.map_constructor_selected_preset_name)
		show_hint(String(load_result.get("message", "Preset load done.")))
		if bool(load_result.get("ok", false)):
			map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
			_clear_map_constructor_preview_cell()
			_clear_map_constructor_wall_mounted_selection()
		_show_map_constructor_inspector(Vector2i(-1, -1))
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	preset_actions.add_child(load_preset_button)
	var delete_preset_button: Button = _make_map_constructor_action_button("Delete selected")
	delete_preset_button.pressed.connect(func() -> void:
		if not map_constructor_state.map_constructor_mode_active or map_constructor_state.map_constructor_selected_preset_name.is_empty() or mission_manager_runtime == null or not mission_manager_runtime.has_method("delete_map_constructor_preset"):
			show_hint("Preset delete unavailable.")
			return
		var delete_result: Dictionary = mission_manager_runtime.call("delete_map_constructor_preset", map_constructor_state.map_constructor_selected_preset_name)
		show_hint(String(delete_result.get("message", "Preset delete done.")))
		map_constructor_state.map_constructor_selected_preset_name = ""
		_show_map_constructor_inspector(map_constructor_state.pending_map_constructor_cell)
		MapConstructorRefreshCoordinatorRef.refresh_panels_then_field(self)
	)
	preset_actions.add_child(delete_preset_button)
	var refresh_preset_button: Button = _make_map_constructor_action_button("Refresh list")
	refresh_preset_button.pressed.connect(func() -> void:
		_refresh_map_constructor_panels()
	)
	list.add_child(refresh_preset_button)

	_add_map_constructor_section_header(list, "MISSION PATCH EXPORT")
	var patch_name_edit: LineEdit = LineEdit.new()
	patch_name_edit.placeholder_text = "Patch name"
	patch_name_edit.text = map_constructor_state.map_constructor_patch_name
	patch_name_edit.text_changed.connect(func(new_text: String) -> void:
		map_constructor_state.map_constructor_patch_name = new_text
	)
	list.add_child(patch_name_edit)
	if mission_manager_runtime != null and mission_manager_runtime.has_method("list_map_constructor_mission_patches"):
		map_constructor_state.map_constructor_patch_entries = mission_manager_runtime.call("list_map_constructor_mission_patches")
	if map_constructor_state.map_constructor_selected_patch_name.is_empty() and not map_constructor_state.map_constructor_patch_entries.is_empty():
		map_constructor_state.map_constructor_selected_patch_name = String(map_constructor_state.map_constructor_patch_entries[0].get("name", ""))
	var patch_select: OptionButton = OptionButton.new()
	for i in range(map_constructor_state.map_constructor_patch_entries.size()):
		var patch_entry: Dictionary = map_constructor_state.map_constructor_patch_entries[i]
		var patch_name_value: String = String(patch_entry.get("name", ""))
		patch_select.add_item(patch_name_value)
		if patch_name_value == map_constructor_state.map_constructor_selected_patch_name:
			patch_select.select(i)
	patch_select.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < map_constructor_state.map_constructor_patch_entries.size():
			map_constructor_state.map_constructor_selected_patch_name = String(map_constructor_state.map_constructor_patch_entries[index].get("name", ""))
	)
	list.add_child(patch_select)
	var mission_patch_actions: HFlowContainer = _make_map_constructor_action_row()
	list.add_child(mission_patch_actions)
	var mission_patch_export_button: Button = _make_map_constructor_action_button("Export current")
	mission_patch_export_button.pressed.connect(func() -> void:
		if not map_constructor_state.map_constructor_mode_active or mission_manager_runtime == null or not mission_manager_runtime.has_method("export_map_constructor_mission_patch"):
			show_hint("Mission patch export unavailable.")
			return
		var export_result: Dictionary = mission_manager_runtime.call("export_map_constructor_mission_patch", map_constructor_state.map_constructor_patch_name)
		show_hint(String(export_result.get("message", "Mission patch export done.")))
		map_constructor_state.map_constructor_selected_patch_name = String(export_result.get("patch_name", map_constructor_state.map_constructor_selected_patch_name))
		_refresh_map_constructor_panels()
	)
	mission_patch_actions.add_child(mission_patch_export_button)
	var refresh_patch_button: Button = _make_map_constructor_action_button("Refresh patches")
	refresh_patch_button.pressed.connect(func() -> void:
		_refresh_map_constructor_panels()
	)
	mission_patch_actions.add_child(refresh_patch_button)
	var delete_patch_button: Button = _make_map_constructor_action_button("Delete patch")
	delete_patch_button.pressed.connect(func() -> void:
		if not map_constructor_state.map_constructor_mode_active or map_constructor_state.map_constructor_selected_patch_name.is_empty() or mission_manager_runtime == null or not mission_manager_runtime.has_method("delete_map_constructor_mission_patch"):
			show_hint("Mission patch delete unavailable.")
			return
		var delete_patch_result: Dictionary = mission_manager_runtime.call("delete_map_constructor_mission_patch", map_constructor_state.map_constructor_selected_patch_name)
		show_hint(String(delete_patch_result.get("message", "Mission patch delete done.")))
		map_constructor_state.map_constructor_selected_patch_name = ""
		_refresh_map_constructor_panels()
	)
	mission_patch_actions.add_child(delete_patch_button)
	_add_map_constructor_section_header(list, "MAP GEOMETRY")
	var geometry_size_row: HFlowContainer = _make_map_constructor_action_row()
	list.add_child(geometry_size_row)
	var width_label: Label = Label.new()
	width_label.text = "Width:"
	geometry_size_row.add_child(width_label)
	var width_edit: LineEdit = LineEdit.new()
	width_edit.placeholder_text = "Width >= 6"
	width_edit.text = map_constructor_state.map_constructor_geometry_width_text
	width_edit.custom_minimum_size = Vector2(88, 0)
	width_edit.text_changed.connect(func(new_text: String) -> void:
		map_constructor_state.map_constructor_geometry_width_text = new_text
	)
	geometry_size_row.add_child(width_edit)
	var height_label: Label = Label.new()
	height_label.text = "Height:"
	geometry_size_row.add_child(height_label)
	var height_edit: LineEdit = LineEdit.new()
	height_edit.placeholder_text = "Height >= 6"
	height_edit.text = map_constructor_state.map_constructor_geometry_height_text
	height_edit.custom_minimum_size = Vector2(88, 0)
	height_edit.text_changed.connect(func(new_text: String) -> void:
		map_constructor_state.map_constructor_geometry_height_text = new_text
	)
	geometry_size_row.add_child(height_edit)
	var create_map_button: Button = _make_map_constructor_action_button("Apply Geometry")
	create_map_button.pressed.connect(func() -> void:
		if mission_manager_runtime == null or not mission_manager_runtime.has_method("create_map_constructor_empty_map"):
			show_hint("Map create unavailable.")
			return
		var build_result: Dictionary = mission_manager_runtime.call("create_map_constructor_empty_map", int(map_constructor_state.map_constructor_geometry_width_text), int(map_constructor_state.map_constructor_geometry_height_text))
		show_hint(String(build_result.get("message", "Map created.")))
		map_constructor_state.selected_map_constructor_prefab_id = ""
		map_constructor_state.map_constructor_marker_mode = ""
		map_constructor_state.pending_map_constructor_cell = Vector2i(-1, -1)
		_refresh_map_constructor_panels()
	)
	list.add_child(create_map_button)
	var marker_button_row: HFlowContainer = _make_map_constructor_action_row()
	list.add_child(marker_button_row)
	var set_start_button: Button = _make_map_constructor_action_button("Set Start")
	set_start_button.pressed.connect(func() -> void:
		map_constructor_state.selected_map_constructor_prefab_id = ""
		map_constructor_state.map_constructor_marker_mode = "start"
		show_hint("Click boundary cell to set start marker.")
	)
	marker_button_row.add_child(set_start_button)
	var set_exit_button: Button = _make_map_constructor_action_button("Set Exit")
	set_exit_button.pressed.connect(func() -> void:
		map_constructor_state.selected_map_constructor_prefab_id = ""
		map_constructor_state.map_constructor_marker_mode = "exit"
		show_hint("Click boundary cell to set exit marker.")
	)
	marker_button_row.add_child(set_exit_button)
	var marker_clear_row: HFlowContainer = _make_map_constructor_action_row()
	list.add_child(marker_clear_row)
	var clear_start_button: Button = _make_map_constructor_action_button("Clear Start")
	clear_start_button.pressed.connect(func() -> void:
		if mission_manager_runtime != null and mission_manager_runtime.has_method("clear_map_constructor_start_marker"):
			var clear_start_result: Dictionary = mission_manager_runtime.call("clear_map_constructor_start_marker")
			show_hint(String(clear_start_result.get("message", "Start marker cleared.")))
			_refresh_map_constructor_panels()
	)
	marker_clear_row.add_child(clear_start_button)
	var clear_exit_button: Button = _make_map_constructor_action_button("Clear Exit")
	clear_exit_button.pressed.connect(func() -> void:
		if mission_manager_runtime != null and mission_manager_runtime.has_method("clear_map_constructor_exit_marker"):
			var clear_exit_result: Dictionary = mission_manager_runtime.call("clear_map_constructor_exit_marker")
			show_hint(String(clear_exit_result.get("message", "Exit marker cleared.")))
			_refresh_map_constructor_panels()
	)
	marker_clear_row.add_child(clear_exit_button)
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_mission_markers"):
		var markers: Dictionary = mission_manager_runtime.call("get_map_constructor_mission_markers")
		var marker_status_label: Label = Label.new()
		var start_text: String = "-"
		var exit_text: String = "-"
		var start_marker: Dictionary = _safe_ui_dictionary(markers.get("start", {}))
		var exit_marker: Dictionary = _safe_ui_dictionary(markers.get("exit", {}))
		if not start_marker.is_empty():
			start_text = str(start_marker.get("cell", "-"))
		if not exit_marker.is_empty():
			exit_text = str(exit_marker.get("cell", "-"))
		marker_status_label.text = "Start: %s | Exit: %s" % [start_text, exit_text]
		list.add_child(marker_status_label)

func _ensure_map_constructor_validation_overlay() -> void:
	if runtime_map_constructor_validation_overlay_control == null or not is_instance_valid(runtime_map_constructor_validation_overlay_control):
		runtime_map_constructor_validation_overlay_control = ConstructorValidationOverlayControl.new(self)
		runtime_map_constructor_validation_overlay_control.z_index = Z_RUNTIME_WORLD_OVERLAY
		runtime_map_constructor_validation_overlay_control.z_as_relative = false
		runtime_hud_root.add_child(runtime_map_constructor_validation_overlay_control)


# -----------------------------------------------------------------------------
# Map Constructor inspector: safe UI helpers
# -----------------------------------------------------------------------------

func _safe_ui_string(value: Variant, fallback: String = "") -> String:
	return MapConstructorUiSafe.safe_string(value, fallback)

func _safe_ui_dictionary(value: Variant) -> Dictionary:
	return MapConstructorUiSafe.safe_dictionary(value)

func _safe_ui_array(value: Variant) -> Array:
	return MapConstructorUiSafe.safe_array(value)

func _safe_ui_vector2i(value: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	return MapConstructorUiSafe.safe_vector2i(value, fallback)



# -----------------------------------------------------------------------------
# Map Constructor inspector: floor/wall controls
# -----------------------------------------------------------------------------

func _compose_map_constructor_floor_visual_id(material_id: String, coating_id: String) -> String:
	return MapConstructorFloorWallControls.compose_floor_visual_id(material_id, coating_id)

func _parse_map_constructor_floor_visual_id(visual_id: String) -> Dictionary:
	return MapConstructorFloorWallControls.parse_floor_visual_id(visual_id)

# -----------------------------------------------------------------------------
# Map Constructor inspector: property controls
# -----------------------------------------------------------------------------

func _add_map_constructor_description_editor(section: VBoxContainer, data: Dictionary, entity_kind: String, entity_id: String) -> void:
	MapConstructorPropertyControlsRef.add_map_constructor_description_editor(self, section, data, entity_kind, entity_id)

func _create_map_constructor_description_block(data: Dictionary, entity_kind: String, entity_id: String) -> Control:
	return MapConstructorPropertyControlsRef.create_map_constructor_description_block(self, data, entity_kind, entity_id)

func _create_inspector_section(title: String) -> VBoxContainer:
	return MapConstructorPropertyControlsRef.create_inspector_section(self, title)

func _create_property_row(label_text: String, control: Control) -> HBoxContainer:
	return MapConstructorPropertyControlsRef.create_property_row(self, label_text, control, true)

func _add_text_property(section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	MapConstructorPropertyControlsRef.add_text_property(self, section, label, entity_kind, entity_id, field_name, current_value)

func _add_bool_property(section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant) -> void:
	MapConstructorPropertyControlsRef.add_bool_property(self, section, label, entity_kind, entity_id, field_name, current_value)

func _add_archetype_schema_properties(section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> bool:
	return MapConstructorPropertyControlsRef.add_archetype_schema_properties(self, section, entity_kind, entity_id, data)

func _add_preset_buttons(section: VBoxContainer, entity_kind: String, entity_id: String) -> void:
	MapConstructorPropertyControlsRef.add_preset_buttons(self, section, entity_kind, entity_id)

# -----------------------------------------------------------------------------
# Map Constructor inspector: link controls
# -----------------------------------------------------------------------------

func _add_link_picker(section: VBoxContainer, entity_kind: String, entity_id: String, link_type: String, title: String) -> void:
	MapConstructorLinkControlsRef.add_link_picker(self, section, entity_kind, entity_id, link_type, title)

func _apply_map_constructor_property_updates(entity_kind: String, entity_id: String, updates: Dictionary, fallback_message: String = "Updated.") -> void:
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("update_map_constructor_entity_properties"):
		return
	var result: Dictionary = MapConstructorPropertyUpdateServiceRef.apply_property_updates(mission_manager_runtime, entity_kind, entity_id, updates, fallback_message)
	show_hint(_safe_ui_string(result.get("message", fallback_message), fallback_message))
	MapConstructorRefreshCoordinatorRef.refresh_selected_entity_mutation(self)

func _apply_map_constructor_property_preset(entity_kind: String, entity_id: String, preset_id: String) -> void:
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("apply_map_constructor_property_preset"):
		return
	var result: Dictionary = MapConstructorPropertyUpdateServiceRef.apply_property_preset(mission_manager_runtime, entity_kind, entity_id, preset_id)
	show_hint(String(result.get("message", "Preset applied.")))
	MapConstructorRefreshCoordinatorRef.refresh_selected_entity_mutation(self)

func _add_enum_property(section: VBoxContainer, label: String, entity_kind: String, entity_id: String, field_name: String, current_value: Variant, options: Array[Dictionary]) -> void:
	MapConstructorPropertyControlsRef.add_enum_property(self, section, label, entity_kind, entity_id, field_name, current_value, options)

func _add_map_constructor_active_settings(parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary, type_group: String) -> void:
	if not (type_group in ["door", "terminal", "power", "control"]):
		return
	var section: VBoxContainer = parent
	var power_mode: String = _safe_ui_string(data.get("power_mode", "external" if bool(data.get("requires_external_power", false)) else "internal")).to_lower()
	var power_options: Array[Dictionary] = [{"label":"Internal", "value":"internal"}, {"label":"External", "value":"external"}]
	if type_group in ["power", "control"]:
		power_options.push_front({"label":"Non", "value":"none"})
	_add_enum_property(section, "Power type", entity_kind, entity_id, "power_mode", power_mode, power_options)
	MapConstructorLinkControlsRef.add_active_settings_power_link(self, section, entity_kind, entity_id, power_mode)
	var control_mode: String = _safe_ui_string(data.get("control_mode", "external" if bool(data.get("requires_external_control", false)) else "internal")).to_lower()
	var control_options: Array[Dictionary] = [{"label":"Internal", "value":"internal"}, {"label":"External", "value":"external"}]
	if type_group in ["power", "control"]:
		control_options.push_front({"label":"Non", "value":"none"})
	_add_enum_property(section, "Control type", entity_kind, entity_id, "control_mode", control_mode, control_options)
	MapConstructorLinkControlsRef.add_active_settings_control_link(self, section, entity_kind, entity_id, control_mode)
	if type_group == "door":
		var state_note: Label = Label.new()
		state_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		state_note.text = "Door states: Open, Closed, Locked, Jammed, Damaged (stored as open/closed/locked/jammed/damaged)."
		section.add_child(state_note)
		_add_enum_property(section, "Door state", entity_kind, entity_id, "state", data.get("state", "closed"), [{"label":"Open", "value":"open"}, {"label":"Closed", "value":"closed"}, {"label":"Locked", "value":"locked"}, {"label":"Jammed", "value":"jammed"}, {"label":"Damaged", "value":"damaged"}])
		var is_closed_label := Label.new()
		is_closed_label.text = str(bool(data.get("is_closed", String(data.get("state", "closed")) in ["closed", "locked", "jammed", "damaged"])))
		section.add_child(_create_property_row("is_closed", is_closed_label))
		var access_type: String = _safe_ui_string(data.get("access_type", data.get("lock_type", "none"))).to_lower()
		_add_enum_property(section, "Key/access type", entity_kind, entity_id, "access_type", access_type, [{"label":"Mechanical key", "value":"mechanical_key"}, {"label":"Digital key", "value":"digital_key"}, {"label":"Access code", "value":"access_code"}, {"label":"Terminal access", "value":"terminal_access"}, {"label":"No key", "value":"none"}])
		MapConstructorLinkControlsRef.add_door_access_link_controls(self, section, entity_kind, entity_id, data, access_type)

# -----------------------------------------------------------------------------
# Map Constructor inspector: validation display
# -----------------------------------------------------------------------------

func _add_validation_entries(section: VBoxContainer, title: String, entries: Array) -> void:
	MapConstructorValidationView.add_validation_entries(self, section, title, entries)

func _get_map_constructor_key_entity_by_id(key_id: String) -> Dictionary:
	return MapConstructorLinkControlsRef.get_map_constructor_key_entity_by_id(self, key_id)

func _restore_map_constructor_inspector_scroll_deferred(scroll: ScrollContainer, scroll_value: int) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	await get_tree().process_frame
	if scroll != null and is_instance_valid(scroll):
		scroll.scroll_vertical = scroll_value

func _is_map_constructor_key_item(data: Dictionary, type_group: String) -> bool:
	return MapConstructorLinkControlsRef.is_map_constructor_key_item(self, data, type_group)

func _add_key_door_link_section(parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	MapConstructorLinkControlsRef.add_key_door_link_section(self, parent, entity_kind, entity_id, data)

func _add_door_linked_key_section(parent: VBoxContainer, entity_id: String, data: Dictionary) -> void:
	MapConstructorLinkControlsRef.add_door_linked_key_section(self, parent, entity_id, data)

func _add_door_required_key_picker(parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	MapConstructorLinkControlsRef.add_door_required_key_picker(self, parent, entity_kind, entity_id, data)

func _add_map_constructor_object_link_sections(link_section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary, type_group: String) -> void:
	MapConstructorLinkControlsRef.add_map_constructor_object_link_sections(self, link_section, entity_kind, entity_id, data, type_group)

# -----------------------------------------------------------------------------
# Map Constructor inspector root
# -----------------------------------------------------------------------------

func _show_map_constructor_inspector(cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> void:
	MapConstructorInspectorRef.refresh(self, cell, preferred_entity_kind, preferred_entity_id)

func _resolve_wall_material_target_for_selection(entity_info: Dictionary, data: Dictionary, fallback_cell: Vector2i) -> Dictionary:
	return MapConstructorFloorWallControls.resolve_wall_material_target_for_selection(self, entity_info, data, fallback_cell)
func _set_map_constructor_link_target(cell: Vector2i, object_id: String) -> void:
	if field_runtime == null:
		return
	var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer != null and renderer.has_method("set_map_constructor_link_target"):
		renderer.call("set_map_constructor_link_target", cell, object_id)

func _clear_map_constructor_link_target() -> void:
	if field_runtime == null:
		return
	var renderer: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer != null and renderer.has_method("clear_map_constructor_link_target"):
		renderer.call("clear_map_constructor_link_target")

func _map_constructor_issue_matches_filter(issue: Dictionary) -> bool:
	var filter_name: String = map_constructor_state.map_constructor_issue_filter
	if filter_name == "All":
		return true
	var severity: String = String(issue.get("severity", "info")).to_lower()
	if filter_name == "Errors":
		return severity == "error"
	if filter_name == "Warnings":
		return severity == "warning"
	if filter_name == "Info":
		return severity == "info"
	return true

func _focus_map_constructor_issue(issue: Dictionary) -> void:
	var issue_cell: Vector2i = _safe_ui_vector2i(issue.get("cell", Vector2i(-1, -1)))
	var entity_kind: String = String(issue.get("entity_kind", ""))
	var entity_id: String = String(issue.get("entity_id", ""))
	var target_cell: Vector2i = issue_cell
	if mission_manager_runtime != null and not entity_kind.is_empty() and not entity_id.is_empty() and mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		var entity_info: Dictionary = mission_manager_runtime.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
		if bool(entity_info.get("ok", false)):
			target_cell = _safe_ui_vector2i(entity_info.get("cell", issue_cell))
			if String(entity_info.get("placement_mode", "")).to_lower() == "wall_mounted":
				var anchor_floor_cell: Vector2i = _safe_ui_vector2i(entity_info.get("anchor_floor_cell", Vector2i(-1, -1)))
				if anchor_floor_cell.x >= 0 and anchor_floor_cell.y >= 0:
					target_cell = anchor_floor_cell
			map_constructor_state.selected_map_constructor_entity_kind = entity_kind
			map_constructor_state.selected_map_constructor_entity_id = entity_id
			map_constructor_state.selected_map_constructor_entity_cell = target_cell
			if target_cell.x >= 0 and target_cell.y >= 0:
				map_constructor_state.pending_map_constructor_cell = target_cell
				_update_map_constructor_preview_for_cell(target_cell)
				_show_map_constructor_inspector(target_cell, entity_kind, entity_id)
				_focus_map_constructor_cell(target_cell)
			elif issue_cell.x >= 0 and issue_cell.y >= 0:
				map_constructor_state.pending_map_constructor_cell = issue_cell
				_update_map_constructor_preview_for_cell(issue_cell)
				_show_map_constructor_inspector(issue_cell, entity_kind, entity_id)
				_focus_map_constructor_cell(issue_cell)
			MapConstructorRefreshCoordinatorRef.request_field_visual_refresh(self)
		else:
			_clear_map_constructor_browser_selection()
			if issue_cell.x >= 0 and issue_cell.y >= 0:
				map_constructor_state.pending_map_constructor_cell = issue_cell
				_update_map_constructor_preview_for_cell(issue_cell)
				_focus_map_constructor_cell(issue_cell)
				_show_map_constructor_inspector(issue_cell)
	elif issue_cell.x >= 0 and issue_cell.y >= 0:
		map_constructor_state.pending_map_constructor_cell = issue_cell
		_update_map_constructor_preview_for_cell(issue_cell)
		_focus_map_constructor_cell(issue_cell)
		_show_map_constructor_inspector(issue_cell)
	show_hint(String(issue.get("message", "Validation issue selected.")))

func _focus_map_constructor_readiness_issue_by_id(issue_id: String) -> void:
	if issue_id.is_empty() or mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_validation_issues"):
		return
	var constructor_issues: Array = mission_manager_runtime.call("get_map_constructor_validation_issues")
	for issue_variant in constructor_issues:
		var issue: Dictionary = _safe_ui_dictionary(issue_variant)
		if String(issue.get("id", "")) != issue_id:
			continue
		map_constructor_state.map_constructor_selected_issue_id = issue_id
		_focus_map_constructor_issue(issue)
		_refresh_map_constructor_panels()
		return

func _add_map_constructor_readiness_action_buttons(action_row: HFlowContainer, recommendation: Dictionary) -> void:
	var action_type: String = String(recommendation.get("action_type", "none"))
	if action_type == "autofix":
		var ftype: String = String(recommendation.get("fix_type", ""))
		var foptions: Dictionary = _safe_ui_dictionary(recommendation.get("options", {}))
		var fkey: String = "%s|%s" % [ftype, JSON.stringify(foptions)]
		var preview_btn: Button = _make_map_constructor_action_button("Preview Fix")
		preview_btn.pressed.connect(func() -> void: _apply_map_constructor_autofix_action(ftype, foptions, false))
		var apply_btn: Button = _make_map_constructor_action_button("Apply Fix")
		apply_btn.disabled = map_constructor_state.map_constructor_autofix_pending_apply_key != fkey
		apply_btn.pressed.connect(func() -> void: _apply_map_constructor_autofix_action(ftype, foptions, true))
		action_row.add_child(preview_btn); action_row.add_child(apply_btn)
	elif action_type == "cleanup":
		var ctype: String = String(recommendation.get("cleanup_type", ""))
		var coptions: Dictionary = _safe_ui_dictionary(recommendation.get("options", {}))
		var ckey: String = "%s|%s" % [ctype, JSON.stringify(coptions)]
		var preview_btn: Button = _make_map_constructor_action_button("Preview Cleanup")
		preview_btn.pressed.connect(func() -> void: _apply_map_constructor_cleanup_action(ctype, coptions, false))
		var apply_btn: Button = _make_map_constructor_action_button("Apply Cleanup")
		apply_btn.disabled = map_constructor_state.map_constructor_cleanup_pending_apply_key != ckey
		apply_btn.pressed.connect(func() -> void: _apply_map_constructor_cleanup_action(ctype, coptions, true))
		action_row.add_child(preview_btn); action_row.add_child(apply_btn)

func _on_move_forward_pressed() -> void:
	if map_constructor_state.map_constructor_mode_active:
		return
	bipob.move_forward()
	update_status()

func _on_move_backward_pressed() -> void:
	if map_constructor_state.map_constructor_mode_active:
		return
	bipob.move_backward()
	update_status()

func _on_turn_left_pressed() -> void:
	if map_constructor_state.map_constructor_mode_active or bipob == null:
		return
	bipob.turn_left()
	update_status()

func _on_turn_right_pressed() -> void:
	if map_constructor_state.map_constructor_mode_active or bipob == null:
		return
	bipob.turn_right()
	update_status()


func _get_runtime_interaction_target_data() -> Dictionary:
	return RuntimeInteractionPanel.get_target_data(self)

func _get_runtime_action_view_model() -> Dictionary:
	var target_data: Dictionary = _get_runtime_interaction_target_data()
	return _safe_ui_dictionary(target_data.get("action_view_model", {}))

func _runtime_action_requires_manipulator(action_id: String, target_object: Dictionary) -> bool:
	return RuntimeInteractionPanel.action_requires_manipulator(action_id, target_object)

func _is_runtime_interaction_manipulator_blocked(target_object: Dictionary, actions: Array) -> bool:
	return RuntimeInteractionPanel.is_manipulator_blocked(self, target_object, actions)

func _refresh_runtime_interaction_controls() -> void:
	RuntimeInteractionPresenterRef.refresh(self)

func _enter_runtime_interaction_mode() -> void:
	RuntimeInteractionPanel.enter_mode(self)

func _exit_runtime_interaction_mode() -> void:
	RuntimeInteractionPanel.exit_mode(self)

func _on_runtime_interaction_action_pressed(action_id: String) -> void:
	RuntimeInteractionPresenterRef.on_runtime_action_pressed(self, action_id)

func _on_interact_pressed() -> void:
	RuntimeInteractionPresenterRef.on_action_pressed(self)


func _on_connect_pressed() -> void:
	RuntimeInteractionPresenterRef.on_connect_pressed(self)

func _on_heavy_claw_pressed() -> void:
	RuntimeInteractionPresenterRef.on_heavy_claw_pressed(self)

func _on_use_selected_world_action_pressed() -> void:
	RuntimeInteractionPresenterRef.on_use_selected_world_action_pressed(self)

func _on_world_action_button_pressed(action_id: String) -> void:
	RuntimeInteractionPresenterRef.on_world_action_button_pressed(self, action_id)

func _get_runtime_world_action_target_id(target_object: Dictionary, fallback_name: String) -> String:
	var raw_id: Variant = target_object.get("id", "")
	if not str(raw_id).is_empty():
		return str(raw_id)

	var raw_position: Variant = target_object.get("position", null)
	if raw_position is Vector2i:
		var cell: Vector2i = raw_position
		return "cell_%d_%d" % [cell.x, cell.y]
	if raw_position is Vector2:
		var vector_position: Vector2 = raw_position
		return "pos_%d_%d" % [int(vector_position.x), int(vector_position.y)]
	if raw_position != null:
		return str(raw_position)

	return fallback_name

func _on_world_action_panel_requested(target_object: Dictionary, actions: Array, selected_action: String) -> void:
	_refresh_runtime_interaction_controls()
	RuntimeInteractionPresenterRef.refresh_world_actions_panel(self, {"target_object": target_object, "actions": actions, "selected_action": selected_action})

func _on_drop_item_button_pressed() -> void:
	if bipob == null or not bipob.has_method("drop_held_item"):
		show_hint("Drop action is unavailable.")
		return
	var manipulator_items: Array = bipob.get_runtime_manipulator_items()
	if selected_manipulator_slot < 0 or selected_manipulator_slot >= bipob.get_available_manipulator_slots():
		show_hint("Manipulator slot is inactive.")
		return
	if selected_manipulator_slot >= manipulator_items.size() or manipulator_items[selected_manipulator_slot] == null:
		show_hint("Manipulator is empty.")
		return
	bipob.drop_held_item()
	update_status()
	update_diagnostic_status()
	update_box_status()
	call_deferred("_sync_runtime_bipob_visual_state")

func _on_rotate_storage_button_pressed() -> void:
	bipob.rotate_physical_storage()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _refresh_runtime_storage_panel() -> void:
	RuntimeStoragePanelRef.refresh(self)


func _get_runtime_display_key_ids(inventory_state: Dictionary) -> Array:
	var display_key_ids: Array = []
	var seen: Dictionary = {}
	var runtime_map: Dictionary = Dictionary(inventory_state.get("world_item_runtime", {}))
	var raw_collected_key_ids: Array = Array(inventory_state.get("collected_key_ids", []))
	for key_value in raw_collected_key_ids:
		var key_id: String = String(key_value).strip_edges()
		if key_id.is_empty() or seen.has(key_id):
			continue
		var item_runtime: Dictionary = Dictionary(runtime_map.get(key_id, {}))
		if not item_runtime.is_empty() and not bool(item_runtime.get("in_inventory", true)):
			continue
		seen[key_id] = true
		display_key_ids.append(key_id)
	if raw_collected_key_ids.is_empty() and display_key_ids.is_empty() and bool(bipob.has_key):
		display_key_ids.append("physical_key")
	return display_key_ids


func _get_runtime_key_display_text(key_id: String, inventory_state: Dictionary = {}) -> String:
	var text := key_id.strip_edges()
	if text.is_empty():
		return "-"
	var runtime_map: Dictionary = Dictionary(inventory_state.get("world_item_runtime", {}))
	var item_runtime: Dictionary = Dictionary(runtime_map.get(text, {}))
	var item_data: Dictionary = Dictionary(item_runtime.get("item_data", {}))
	var display_name: String = String(item_data.get("display_name", "")).strip_edges()
	if not display_name.is_empty():
		return display_name
	var item_data_id: String = String(item_data.get("id", "")).strip_edges()
	if not item_data_id.is_empty():
		return item_data_id
	if text == "physical_key":
		return "Key"
	return text

func _on_storage_take_pressed() -> void:
	bipob.move_pocket_to_manipulator(selected_pocket_slot)
	update_status()

func _on_storage_take_slot_pressed(slot_index: int) -> void:
	selected_pocket_slot = slot_index
	_on_storage_take_pressed()

func _on_storage_store_pressed() -> void:
	bipob.move_manipulator_to_pocket(selected_manipulator_slot)
	update_status()

func _on_storage_load_pressed() -> void:
	bipob.move_digital_storage_to_buffer(selected_digital_slot)
	update_status()

func _on_storage_load_slot_pressed(slot_index: int) -> void:
	selected_digital_slot = slot_index
	_on_storage_load_pressed()

func _on_storage_data_store_pressed() -> void:
	bipob.move_buffer_to_digital_storage()
	update_status()

func _move_runtime_manipulator_to_first_free_pocket() -> Dictionary:
	return _apply_runtime_storage_result(bipob.move_manipulator_to_first_free_pocket(selected_manipulator_slot))

func _move_or_swap_runtime_pocket_slot(slot_index: int) -> Dictionary:
	selected_pocket_slot = slot_index
	return _apply_runtime_storage_result(bipob.move_or_swap_pocket_slot_with_manipulator(slot_index, selected_manipulator_slot))

func _move_runtime_buffer_to_first_free_storage() -> Dictionary:
	return _apply_runtime_storage_result(bipob.move_buffer_to_first_free_storage())

func _move_or_swap_runtime_storage_slot(slot_index: int) -> Dictionary:
	selected_digital_slot = slot_index
	return _apply_runtime_storage_result(bipob.move_or_swap_storage_slot_with_buffer(slot_index))

func _apply_runtime_storage_result(result: Dictionary) -> Dictionary:
	if bool(result.get("ok", false)):
		update_status()
		return result
	var message: String = String(result.get("message", "Storage action is unavailable."))
	if not message.is_empty():
		show_hint(message)
	return result

func _on_scan_device_button_pressed() -> void:
	bipob.scan_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_hack_device_button_pressed() -> void:
	bipob.hack_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_end_turn_pressed() -> void:
	if map_constructor_state.map_constructor_mode_active or bipob == null:
		return
	bipob.end_turn()
	update_status()

func _on_restart_mission_button_pressed() -> void:
	if bipob == null:
		return

	_deactivate_map_constructor_mode()

	# Mission reset action: should not spend field action points or energy as button press.
	bipob.restart_current_mission()
	if box_screen != null and box_screen.visible:
		hide_box_screen()
	else:
		if command_panel != null:
			command_panel.visible = true

	update_status()
	update_diagnostic_status()
	update_box_status()

func _show_game_menu(show_to_center_menu: bool = true) -> void:
	var overlay_root: Control = runtime_menu_overlay if show_to_center_menu else center_menu_overlay
	RuntimeMissionMenuRef.open_overlay(overlay_root)

func _on_return_to_box_button_pressed() -> void:
	show_center_screen()

func _on_runtime_return_to_center_pressed() -> void:
	show_center_screen()

func _on_runtime_settings_pressed() -> void:
	placeholder_return_screen_mode = AppScreenMode.GAMEPLAY
	show_placeholder_screen("Settings")

func _on_runtime_exit_to_main_menu_pressed() -> void:
	show_main_menu_screen()

func update_status() -> void:
	if bipob == null:
		return

	if runtime_energy_label != null:
		runtime_energy_label.text = _get_runtime_energy_text()
	if runtime_actions_label != null and is_instance_valid(runtime_actions_label):
		runtime_actions_label.text = _get_runtime_actions_text()
	_refresh_runtime_mission_objective_label()

	var key_text := "no"
	if bipob.has_key:
		key_text = "yes"

	var info_key_text := "no"
	if bipob.has_info_key:
		info_key_text = "yes"
	var held_text := "empty"
	if bipob.held_module != null:
		held_text = bipob.get_module_display_name(bipob.held_module)
	elif bipob.current_mission_index == 7 and bipob.mission7_is_dragging_cable:
		held_text = "Cable End"
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)

	# Keep runtime panels synchronized even when the legacy status label is absent.
	_refresh_runtime_storage_panel()
	_refresh_runtime_interaction_controls()

	if hud_status_label == null:
		return

	hud_status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s | Hand: %s | Storage: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text,
		held_text,
		storage_text
	]
	hud_status_label.text += " | Carry: %d / %d" % [
		bipob.get_carried_physical_count(),
		bipob.physical_carry_capacity
	]
	var digital_storage_short_text := "empty"
	if bipob.has_method("get_digital_storage_short_text"):
		digital_storage_short_text = str(bipob.get_digital_storage_short_text())
	elif bipob.has_method("get_digital_storage_text"):
		var full_storage_text := str(bipob.get_digital_storage_text())
		if full_storage_text.begins_with("Digital storage: "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage: ")
		elif full_storage_text.begins_with("Digital storage:\n- "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
		elif not full_storage_text.is_empty():
			digital_storage_short_text = full_storage_text
	hud_status_label.text += " | Data: %s" % digital_storage_short_text
	if bipob.has_method("get_mission8_airflow_status_text"):
		var mission8_status := str(bipob.get_mission8_airflow_status_text())
		if not mission8_status.is_empty():
			hud_status_label.text += " | %s" % mission8_status
	if bipob.current_mission_index == 7 and bipob.has_method("get_mission7_cable_status_text"):
		hud_status_label.text += " | %s" % str(bipob.get_mission7_cable_status_text())
	if bipob.has_method("refresh_world_action_panel"):
		bipob.refresh_world_action_panel()


func _format_runtime_display_text(value: Variant) -> String:
	if value == null or typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY]:
		return ""
	var text: String = String(value).strip_edges()
	text = text.replace("Interface", "Connector")
	text = text.replace("interface", "connector")
	text = text.replace("CPU", "Processor")
	text = text.replace("cpu", "processor")
	text = text.replace("mechanical key", "Key-card")
	return text

func _format_runtime_short_message(message: String, fallback_label: String = "") -> String:
	var full_message: String = _format_runtime_display_text(message).strip_edges()
	var normalized: String = full_message.to_lower()
	if normalized.find("scan") >= 0 and normalized.find("first") >= 0:
		return "Scan first"
	if normalized.find("key-card") >= 0:
		return "Key-card required"
	if normalized.find("free manipulator") >= 0:
		return "Free manipulator"
	if normalized.find("cut power") >= 0 or normalized.find("power must be cut") >= 0:
		return "Cut power"
	for capability_name in ["Connector", "Processor", "Manipulator"]:
		var capability_prefix: String = "%s Version " % capability_name
		var prefix_index: int = full_message.findn(capability_prefix)
		if prefix_index >= 0:
			var level_text: String = full_message.substr(prefix_index + capability_prefix.length()).get_slice(" ", 0).trim_suffix(".")
			if not level_text.is_empty():
				return "%s Version %s" % [capability_name, level_text]
	var short_fallback: String = _format_runtime_display_text(fallback_label).strip_edges()
	if not short_fallback.is_empty():
		return short_fallback
	return full_message.trim_suffix(".")

func _format_runtime_requirement_label(requirement_key: String, requirement_value: Variant) -> String:
	match requirement_key:
		"connector_level": return "Connector Lv. %d" % int(requirement_value)
		"processor_level": return "Processor Lv. %d" % int(requirement_value)
		"manipulator_level": return "Manipulator Version %d" % int(requirement_value)
		"scan_level": return "Scan Lv. %d" % int(requirement_value)
		"power_required": return "Power required"
		"power_must_be_cut": return "Power must be cut"
		"free_manipulator_required": return "Free manipulator required"
		"key_card_required": return "Key-card required"
		"digital_key_required": return "Digital key required"
		"access_code_required": return "Access code required"
		"terminal_required": return "Linked terminal required"
		"fuse_required": return "Fuse required"
		"cable_connection_required": return "Cable connection required"
		"repair_required": return "Repair required"
		"required_key_id": return "Key-card: %s" % _format_runtime_display_text(requirement_value)
	var readable_key: String = _format_runtime_display_text(requirement_key.replace("_", " ")).capitalize()
	if typeof(requirement_value) == TYPE_BOOL:
		return readable_key
	return "%s: %s" % [readable_key, _format_runtime_display_text(requirement_value)]

func _format_runtime_requirements(requirements: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for requirement_key_variant in requirements.keys():
		var requirement_key: String = String(requirement_key_variant)
		var requirement_value: Variant = requirements.get(requirement_key_variant)
		if requirement_value == null:
			continue
		if typeof(requirement_value) == TYPE_BOOL and not bool(requirement_value):
			continue
		if typeof(requirement_value) == TYPE_INT and int(requirement_value) <= 0:
			continue
		if typeof(requirement_value) == TYPE_FLOAT and float(requirement_value) <= 0.0:
			continue
		if typeof(requirement_value) == TYPE_STRING and String(requirement_value).strip_edges().is_empty():
			continue
		lines.append(_format_runtime_requirement_label(requirement_key, requirement_value))
	return lines

func _format_runtime_missing(missing: Array) -> Array[String]:
	var lines: Array[String] = []
	for missing_variant in missing:
		if typeof(missing_variant) != TYPE_DICTIONARY:
			continue
		var missing_item: Dictionary = missing_variant
		var label: String = _format_runtime_display_text(missing_item.get("label", "Requirement missing"))
		if not label.is_empty():
			lines.append(label.trim_suffix("."))
	return lines

func _format_runtime_actions(actions: Array, include_reasons: bool) -> Array[String]:
	var lines: Array[String] = []
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = action_variant
		var label: String = _format_runtime_display_text(action.get("label", action.get("id", "Action")))
		var reason: String = _format_runtime_display_text(action.get("reason", action.get("disabled_reason", "")))
		if label.is_empty():
			continue
		if include_reasons and not reason.is_empty():
			lines.append("%s — %s" % [label, reason.trim_suffix(".")])
		else:
			lines.append(label)
	return lines

func _append_runtime_diagnostic_section(lines: Array[String], title: String, items: Array[String], item_prefix: String = "") -> void:
	if items.is_empty():
		return
	lines.append("")
	lines.append("%s:" % title)
	for item in items:
		lines.append("- %s%s" % [item_prefix, item])

func _format_runtime_diagnostic_text(diagnostic: Dictionary, state_flow: Dictionary) -> String:
	if diagnostic.is_empty():
		return "Diagnostic: none"
	var lines: Array[String] = ["Diagnostic:"]
	var target_name: String = _format_runtime_display_text(diagnostic.get("target_name", "Unknown object"))
	lines.append("Target: %s" % target_name)
	var type_parts: Array[String] = []
	for type_key in ["target_group", "target_type"]:
		var type_text: String = _format_runtime_display_text(diagnostic.get(type_key, ""))
		if not type_text.is_empty() and not type_parts.has(type_text):
			type_parts.append(type_text)
	if not type_parts.is_empty():
		lines.append("Type: %s" % " / ".join(type_parts))
	var state_parts: Array[String] = []
	for state_key in ["state", "power_state"]:
		var state_text: String = _format_runtime_display_text(diagnostic.get(state_key, ""))
		if not state_text.is_empty() and not state_parts.has(state_text):
			state_parts.append(state_text)
	if not state_parts.is_empty():
		lines.append("State: %s" % " / ".join(state_parts))
	var is_applicable: bool = bool(state_flow.get("is_applicable", false))
	if not is_applicable:
		return "\n".join(lines)
	var next_message: String = _format_runtime_display_text(state_flow.get("message", ""))
	if not next_message.is_empty():
		lines.append("Next: %s" % next_message)
	var requirements_variant: Variant = diagnostic.get("requirements", {})
	if typeof(requirements_variant) == TYPE_DICTIONARY:
		_append_runtime_diagnostic_section(lines, "Requirements", _format_runtime_requirements(requirements_variant))
	var missing_variant: Variant = diagnostic.get("missing", [])
	if typeof(missing_variant) == TYPE_ARRAY:
		_append_runtime_diagnostic_section(lines, "Missing", _format_runtime_missing(missing_variant))
	var available_actions_variant: Variant = diagnostic.get("available_actions", [])
	if typeof(available_actions_variant) == TYPE_ARRAY:
		_append_runtime_diagnostic_section(lines, "Actions", _format_runtime_actions(available_actions_variant, false), "Available: ")
	var blocked_actions_variant: Variant = diagnostic.get("blocked_actions", [])
	if typeof(blocked_actions_variant) == TYPE_ARRAY:
		_append_runtime_diagnostic_section(lines, "Blocked", _format_runtime_actions(blocked_actions_variant, true))
	var summary: String = _format_runtime_display_text(diagnostic.get("summary", ""))
	if not summary.is_empty():
		lines.append("")
		lines.append("Summary: %s" % summary)
	return "\n".join(lines)

func update_diagnostic_status() -> void:
	if bipob == null or hud_diagnostic_label == null:
		return
	if bipob.has_method("get_facing_device_diagnostic_result"):
		var runtime_diagnostic_variant: Variant = bipob.call("get_facing_device_diagnostic_result")
		if typeof(runtime_diagnostic_variant) == TYPE_DICTIONARY:
			var runtime_diagnostic: Dictionary = runtime_diagnostic_variant
			if not runtime_diagnostic.is_empty():
				var state_flow: Dictionary = {}
				if bipob.has_method("get_facing_device_interaction_state_flow"):
					var state_flow_variant: Variant = bipob.call("get_facing_device_interaction_state_flow")
					if typeof(state_flow_variant) == TYPE_DICTIONARY:
						state_flow = state_flow_variant
				hud_diagnostic_label.text = _format_runtime_diagnostic_text(runtime_diagnostic, state_flow)
				return
	var result = bipob.last_diagnostic_result
	if result == null:
		hud_diagnostic_label.text = "Diagnostic: none"
		return
	var device_name: String = str(result.device_name)
	if device_name.is_empty(): device_name = "unknown"
	var status_text: String = str(result.get_status_text())
	if status_text.is_empty(): status_text = "UNKNOWN"
	var supported_action: String = str(result.supported_action)
	if supported_action.is_empty(): supported_action = "none"
	var reason: String = _format_runtime_display_text(result.reason)
	if reason.is_empty(): reason = "n/a"
	var recommendation: String = _format_runtime_display_text(result.recommendation)
	if recommendation.is_empty(): recommendation = "n/a"
	var estimated_risk: String = str(result.estimated_risk)
	if estimated_risk.is_empty(): estimated_risk = "n/a"
	hud_diagnostic_label.text = "Diagnostic:\nDevice: %s\nStatus: %s\nAction: %s\nReason: %s\nRecommendation: %s\nRisk: %s" % [device_name, status_text, supported_action, reason, recommendation, estimated_risk]


func _section_title(title: String) -> String:
	return "== %s ==" % title

func _subsection_title(title: String) -> String:
	return "-- %s --" % title

func _empty_line(lines: Array[String]) -> void:
	lines.append("")

func _get_internal_view_legend_text() -> String:
	if internal_view_mode == "thermal":
		return "[1-5] base preview heat after normal cooling, [5] critical preview"
	if internal_view_mode == "overlay":
		return "[L] selected liquid, [A] selected duct, [l] liquid path, [a] duct path"
	if internal_view_mode == "thermal_overlay":
		return "[1-5] hypothetical heat, [l/a] overlay, [*] preview, [!] invalid"
	return "[ ] empty, [>] origin, [*] preview, [!] invalid, [B/P/E/I/M/W/H] modules"

func _get_selected_internal_candidate_module() -> BipobModule:
	var module: BipobModule = selected_constructor_module if selected_module_source == "storage" else null
	if module == null:
		return null
	if bipob.is_internal_module(module):
		return module
	return null

func _get_internal_preview_cells_map() -> Dictionary:
	var result: Dictionary = {}
	var module: BipobModule = _get_selected_internal_candidate_module()
	if module == null:
		return result
	var origin: Vector3i = bipob.selected_internal_origin
	var rotation_index: int = bipob.selected_internal_rotation
	var can_place: bool = bipob.can_place_internal_module(module, origin, rotation_index)
	var covered_cells: Array[Vector3i] = bipob.get_internal_module_covered_cells(module, origin, rotation_index)
	for cell in covered_cells:
		var key: String = bipob.get_internal_slot_key(cell)
		result[key] = can_place
	return result

func _get_internal_visual_cell_label(cell: Vector3i, module: BipobModule) -> String:
	if internal_view_mode == "thermal":
		if module == null:
			return ""
		var heat: int = bipob.get_preview_heat_after_cooling_for_internal_module(module)
		return "%d" % heat
	if internal_view_mode == "thermal_overlay":
		if module == null:
			var overlay_marker_empty: String = bipob.get_internal_overlay_marker_for_cell(cell)
			return overlay_marker_empty
		var overlay_heat: int = bipob.get_hypothetical_heat_after_overlay_for_module(module)
		return "%d" % overlay_heat
	if internal_view_mode == "overlay":
		var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
		if not overlay_marker.is_empty():
			return overlay_marker
		if module != null:
			var bg_label: String = "M"
			if bipob.has_method("get_module_visual_short_label"):
				bg_label = bipob.get_module_visual_short_label(module)
			return bg_label.to_lower()
		return ""
	if module != null:
		if bipob.has_method("get_module_visual_short_label"):
			return bipob.get_module_visual_short_label(module)
		return "M"
	return ""

func _get_internal_heat_color(heat: int) -> Color:
	match heat:
		0: return Color(0.050, 0.070, 0.080, 1.0)
		1: return Color(0.080, 0.250, 0.160, 1.0)
		2: return Color(0.200, 0.320, 0.130, 1.0)
		3: return Color(0.450, 0.320, 0.100, 1.0)
		4: return Color(0.650, 0.250, 0.080, 1.0)
		5: return Color(0.750, 0.060, 0.060, 1.0)
		_: return Color(0.050, 0.070, 0.080, 1.0)

func _make_internal_cell_style(cell: Vector3i, module: BipobModule, selected: bool, preview: bool, invalid_preview: bool) -> StyleBoxFlat:
	var bg_color: Color = Color(0.035, 0.050, 0.060, 1.0)
	var border_color: Color = UI_COLOR_BORDER_DIM
	var border_width: int = 1
	if internal_view_mode == "thermal" and module != null:
		var heat: int = bipob.get_preview_heat_after_cooling_for_internal_module(module)
		bg_color = _get_internal_heat_color(heat)
		border_color = bg_color.lightened(0.25)
	elif internal_view_mode == "thermal_overlay" and module != null:
		var overlay_heat: int = bipob.get_hypothetical_heat_after_overlay_for_module(module)
		bg_color = _get_internal_heat_color(overlay_heat)
		border_color = bg_color.lightened(0.25)
	elif internal_view_mode == "overlay":
		var marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
		if not marker.is_empty():
			if marker == "L" or marker == "l" or marker == "q":
				bg_color = Color(0.020, 0.280, 0.330, 1.0)
				border_color = Color(0.050, 0.850, 0.950, 1.0)
			elif marker == "A" or marker == "a" or marker == "d":
				bg_color = Color(0.180, 0.200, 0.220, 1.0)
				border_color = Color(0.650, 0.750, 0.800, 1.0)
		elif module != null and bipob.has_method("get_module_visual_color"):
			var module_color_overlay: Color = bipob.get_module_visual_color(module)
			bg_color = module_color_overlay.darkened(0.75)
			border_color = module_color_overlay.darkened(0.25)
	elif module != null:
		if bipob.has_method("get_module_visual_color"):
			var module_color: Color = bipob.get_module_visual_color(module)
			bg_color = module_color.darkened(0.62)
			border_color = module_color
		else:
			bg_color = Color(0.120, 0.160, 0.180, 1.0)
	if internal_view_mode == "thermal_overlay" and module == null:
		var empty_overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
		if not empty_overlay_marker.is_empty():
			if empty_overlay_marker == "L" or empty_overlay_marker == "l" or empty_overlay_marker == "q":
				bg_color = Color(0.020, 0.230, 0.280, 1.0)
				border_color = Color(0.050, 0.700, 0.850, 1.0)
			elif empty_overlay_marker == "A" or empty_overlay_marker == "a" or empty_overlay_marker == "d":
				bg_color = Color(0.160, 0.180, 0.200, 1.0)
				border_color = Color(0.550, 0.650, 0.700, 1.0)
	if preview:
		bg_color = Color(0.100, 0.230, 0.130, 1.0)
		border_color = UI_COLOR_OK
	if invalid_preview:
		bg_color = Color(0.260, 0.070, 0.070, 1.0)
		border_color = UI_COLOR_DANGER
	if selected:
		border_color = UI_COLOR_SELECTED
		border_width = 2
	return _make_panel_style(bg_color, border_color, border_width, 5)

func _on_internal_visual_cell_pressed(cell: Vector3i) -> void:
	if not bipob.is_internal_cell_in_bounds(cell):
		return
	bipob.selected_internal_origin = cell
	var installed_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	if installed_module != null:
		selected_constructor_module = installed_module
		selected_module_source = "installed_internal"
	update_box_status()

func _make_cell_from_slice_axes(axis_a: String, value_a: int, axis_b: String, value_b: int, fixed_axis: String, fixed_value: int) -> Vector3i:
	var x: int = 0
	var y: int = 0
	var z: int = 0
	match axis_a:
		"x": x = value_a
		"y": y = value_a
		"z": z = value_a
	match axis_b:
		"x": x = value_b
		"y": y = value_b
		"z": z = value_b
	match fixed_axis:
		"x": x = fixed_value
		"y": y = fixed_value
		"z": z = fixed_value
	return Vector3i(x, y, z)

func _create_internal_slice_grid(title_text: String, axis_a: String, axis_b: String, fixed_axis: String, fixed_value: int) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	root.add_child(title)
	var preview_cells: Dictionary = _get_internal_preview_cells_map()
	var volume_size: Vector3i = bipob.get_internal_volume_size()
	var columns: int = volume_size.x if axis_a == "x" else (volume_size.y if axis_a == "y" else volume_size.z)
	var rows: int = volume_size.x if axis_b == "x" else (volume_size.y if axis_b == "y" else volume_size.z)
	var cell_size: Vector2 = _get_constructor_cell_size(columns, rows, _get_internal_grid_available_size(columns, rows))
	var grid_gap: int = _get_constructor_grid_gap(columns, rows)
	var grid: GridContainer = GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", grid_gap)
	grid.add_theme_constant_override("v_separation", grid_gap)
	for b in range(rows):
		for a in range(columns):
			var cell: Vector3i = _make_cell_from_slice_axes(axis_a, a, axis_b, b, fixed_axis, fixed_value)
			var module: BipobModule = bipob.get_internal_module_at_cell(cell)
			var selected: bool = cell == bipob.selected_internal_origin
			var key: String = bipob.get_internal_slot_key(cell)
			var preview: bool = false
			var invalid_preview: bool = false
			if preview_cells.has(key):
				var can_place_preview: bool = bool(preview_cells[key])
				preview = can_place_preview
				invalid_preview = not can_place_preview
			var cell_button: Button = _create_internal_slice_cell_button(
				cell_size,
				_get_internal_visual_cell_label(cell, module) if cell_size.x >= CONSTRUCTOR_SMALL_LABEL_CELL_SIZE else ""
			)
			cell_button.add_theme_stylebox_override("normal", _make_internal_cell_style(cell, module, selected, preview, invalid_preview))
			cell_button.add_theme_stylebox_override("hover", _make_internal_cell_style(cell, module, true, preview, invalid_preview))
			cell_button.add_theme_stylebox_override("pressed", _make_internal_cell_style(cell, module, true, preview, invalid_preview))
			cell_button.pressed.connect(func() -> void: _on_internal_visual_cell_pressed(cell))
			if selected:
				_apply_selected_pulse(cell_button)
			if invalid_preview:
				_apply_invalid_preview_blink(cell_button)
			grid.add_child(cell_button)
	root.add_child(grid)
	panel.add_child(root)
	return panel

func _create_internal_slice_cell_button(cell_size: Vector2, marker_text: String) -> Button:
	var cell_button: Button = Button.new()
	cell_button.custom_minimum_size = cell_size
	cell_button.focus_mode = Control.FOCUS_NONE
	cell_button.text = ""
	var marker_label: Label = Label.new()
	marker_label.text = marker_text
	marker_label.custom_minimum_size = Vector2.ZERO
	marker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marker_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.clip_text = true
	marker_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	marker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	marker_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	marker_label.add_theme_font_size_override("font_size", 11 if cell_size.x >= CONSTRUCTOR_SMALL_LABEL_CELL_SIZE else 8)
	cell_button.add_child(marker_label)
	return cell_button

func _create_internal_cube_preview_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	panel.custom_minimum_size = Vector2(220, 220)
	var root: VBoxContainer = VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	var title: Label = Label.new()
	title.text = "INTERNAL VOLUME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	root.add_child(title)
	var volume_size: Vector3i = bipob.get_internal_volume_size()
	var cube_label: Label = Label.new()
	cube_label.text = "[ INTERNAL CUBE %dx%dx%d ]" % [volume_size.x, volume_size.y, volume_size.z]
	cube_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cube_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(cube_label)
	root.add_child(cube_label)
	var cursor_label: Label = Label.new()
	cursor_label.text = "Cursor: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z]
	cursor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(cursor_label, true, false)
	root.add_child(cursor_label)
	panel.add_child(root)
	return panel

func _get_internal_visual_legend_text() -> String:
	if internal_view_mode == "thermal":
		return "1-5 = Thermal Preview\nYellow border = Cursor\nGreen = valid preview\nRed = invalid preview"
	if internal_view_mode == "thermal_overlay":
		return "1-5 = Thermal+Overlay\nl/a = empty Overlay Path\nBase Thermal unchanged"
	if internal_view_mode == "overlay":
		return "L/A = Overlay Plan\nl/a = Overlay Path\nq/d = Selected Path\nlowercase modules = underneath"
	return "BAT/CPU/FAN/etc = modules\nYellow border = Cursor\nGreen = valid preview\nRed = invalid preview"

func _create_internal_legend_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(180, 80)
	var root: VBoxContainer = VBoxContainer.new()
	var title: Label = Label.new()
	title.text = "LEGEND"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var mode_label: Label = Label.new()
	mode_label.text = "View Mode: %s" % _get_internal_view_mode_display_name()
	_apply_label_style(mode_label)
	root.add_child(mode_label)
	var legend_text: Label = Label.new()
	legend_text.text = _get_internal_visual_legend_text()
	_apply_label_style(legend_text, true, false)
	root.add_child(legend_text)
	panel.add_child(root)
	return panel

func _create_internal_connections_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = "CONNECTIONS"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var lines: Array[String] = ["Connections: Power / Data / Cooling auto-routed"]
	for line in lines:
		var label: Label = Label.new()
		label.text = line
		_apply_label_style(label, true, false)
		root.add_child(label)
	panel.add_child(root)
	return panel

func _create_internal_visual_workspace() -> Control:
	_clamp_internal_selection()
	var workspace: PanelContainer = PanelContainer.new()
	_apply_panel_style(workspace, true)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.custom_minimum_size = Vector2(0, 0)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_create_internal_summary_warnings_row())
	var constructor_row: HBoxContainer = HBoxContainer.new()
	constructor_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	constructor_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	constructor_row.alignment = BoxContainer.ALIGNMENT_CENTER
	constructor_row.add_theme_constant_override("separation", 6)

	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 1.0
	left_column.add_theme_constant_override("separation", 4)
	left_column.add_child(_create_internal_slice_grid("VERTICAL SLICE", "x", "z", "y", bipob.selected_internal_origin.y))
	left_column.add_child(_create_internal_slice_grid("HORIZONTAL SLICE", "x", "y", "z", bipob.selected_internal_origin.z))
	constructor_row.add_child(left_column)

	var volume_preview: Control = _create_internal_volume_placeholder_panel()
	volume_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	volume_preview.size_flags_stretch_ratio = 1.0
	constructor_row.add_child(volume_preview)
	root.add_child(constructor_row)
	workspace.add_child(root)
	return workspace

func _create_internal_summary_warnings_row() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 6)
	var summary_panel: Control = _create_internal_summary_panel()
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_panel.size_flags_stretch_ratio = 1.0
	row.add_child(summary_panel)
	var warnings_panel: Control = _create_internal_missing_required_panel()
	warnings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warnings_panel.size_flags_stretch_ratio = 1.0
	row.add_child(warnings_panel)
	return row

func _create_internal_summary_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(180, 74)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.add_child(_create_internal_info_line("Temperature", _format_signed_temperature(_calculate_internal_temperature_summary())))
	root.add_child(_create_internal_info_line("Actions", str(_calculate_internal_actions())))
	root.add_child(_create_internal_info_line("Hack", str(_calculate_internal_hack_level())))
	root.add_child(_create_internal_info_line("Storage", str(_calculate_internal_storage_capacity())))
	root.add_child(_create_internal_info_line("Energy", _get_internal_energy_display_text()))
	panel.add_child(root)
	return panel

func _create_internal_info_line(label_text: String, value_text: String) -> Control:
	var line: Label = Label.new()
	line.text = "%s: %s" % [label_text, value_text]
	_apply_label_style(line, true, false)
	return line

func _create_internal_missing_required_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(180, 110)
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var warnings: Array[String] = _build_internal_missing_required_warnings()
	var warning_label: Label = Label.new()
	warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.clip_text = true
	warning_label.text = " ".join(warnings)
	_apply_label_style(warning_label, true, false)
	var warning_color: Color = UI_COLOR_DANGER
	if warnings.size() == 1 and warnings.has("Charger"):
		warning_color = UI_COLOR_WARNING
	warning_label.add_theme_color_override("font_color", warning_color)
	root.add_child(warning_label)
	panel.add_child(root)
	return panel

func _get_internal_installed_modules() -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	if bipob == null:
		return modules
	if bipob.has_method("get_unique_internal_modules"):
		modules = bipob.get_unique_internal_modules()
	return modules

func _calculate_internal_actions() -> int:
	var total_actions: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		if String(module.internal_family).to_lower() != "ram":
			continue
		total_actions += maxi(int(module.action_capacity), 0)
	return total_actions

func _calculate_internal_hack_level() -> int:
	var highest_hack: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		if String(module.internal_family).to_lower() != "cpu":
			continue
		highest_hack = maxi(highest_hack, int(module.hack_value))
	return highest_hack

func _calculate_internal_storage_capacity() -> int:
	var total_slots: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		if String(module.internal_family).to_lower() != "storage":
			continue
		total_slots += maxi(int(module.digital_storage_slots), 0)
	return total_slots

func _calculate_internal_energy_totals() -> Dictionary:
	var total_energy: int = 0
	var total_charge: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		if String(module.internal_family).to_lower() != "battery":
			continue
		total_energy += maxi(int(module.energy_capacity), 0)
		total_charge += clampi(int(module.current_charge), 0, maxi(int(module.energy_capacity), 0))
	return {"current": total_charge, "max": total_energy}

func _get_internal_energy_display_text() -> String:
	var totals: Dictionary = _calculate_internal_energy_totals()
	var max_energy: int = int(totals.get("max", 0))
	if max_energy <= 0:
		return "-"
	return "%d / %d" % [int(totals.get("current", 0)), max_energy]

func bipob_has_charger(_bipob: Variant = null) -> bool:
	var modules: Array = []

	if _bipob == null:
		modules = _get_internal_installed_modules()
	elif typeof(_bipob) == TYPE_STRING:
		return _profile_has_charger(String(_bipob))
	elif typeof(_bipob) == TYPE_DICTIONARY:
		var data: Dictionary = _bipob
		if data.has("has_charger"):
			return bool(data.get("has_charger", false))
		if data.has("id"):
			return _profile_has_charger(String(data.get("id", "")))
		modules = _get_internal_installed_modules()
	else:
		modules = _get_internal_installed_modules()

	for module in modules:
		if module == null:
			continue
		if module.id == "charger_v1":
			return true

	return false

func _profile_has_charger(profile_id: String) -> bool:
	if profile_id == active_bipob_profile_id:
		return bipob_has_charger()
	if not constructor_profiles.has(profile_id):
		return false
	var profile_data: Dictionary = constructor_profiles[profile_id]
	for record_variant in profile_data.get("installed_modules", []):
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		if String(record.get("id", "")) == "charger_v1":
			return true
	for module_id in profile_data.get("installed_ids", []):
		if String(module_id) == "charger_v1":
			return true
	return false

func _get_profile_energy_summary(profile_id: String) -> Dictionary:
	if profile_id == active_bipob_profile_id:
		return _calculate_internal_energy_totals()
	if not constructor_profiles.has(profile_id):
		return {"current": 0, "max": 0}
	var current_charge: int = 0
	var max_capacity: int = 0
	var profile_data: Dictionary = constructor_profiles[profile_id]
	for record_variant in profile_data.get("placed_internal", []):
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var module: BipobModule = record.get("module", null)
		if module == null:
			continue
		if String(module.internal_family).to_lower() != "battery":
			continue
		var cap: int = maxi(int(module.energy_capacity), 0)
		max_capacity += cap
		current_charge += clampi(int(module.current_charge), 0, cap)
	return {"current": current_charge, "max": max_capacity}

func _calculate_internal_temperature_summary() -> int:
	var total_temperature: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		total_temperature += int(module.heat_value)
		total_temperature += int(module.cooling_value)
	# TODO temperature stacking:
	# - Overheat stacks by adjacency.
	# - If several hot modules touch the same module, their overheat pressure can combine.
	# - Cooling modules apply cooling to nearby cells.
	# - Cooler + Radiator may stack when both affect the same hot module.
	# - Cooling lines can transfer cooling from a cooling source to remote modules.
	# - Final Temperature should be calculated per-module first, then the summary shows the worst positive temperature or total balance depending on design decision.
	return total_temperature


func _format_signed_temperature(value: int) -> String:
	if value > 0:
		return "+%d" % value
	if value < 0:
		return "%d" % value
	return "0"

func _build_internal_missing_required_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var family_set: Dictionary = {}
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		var family_id: String = String(module.internal_family).to_lower()
		if not family_id.is_empty():
			family_set[family_id] = true
	if not family_set.has("cpu"):
		warnings.append("CPU")
	if not family_set.has("gpu"):
		warnings.append("GPU")
	if not family_set.has("ram"):
		warnings.append("RAM")
	if not family_set.has("battery"):
		warnings.append("Battery")
	if not family_set.has("storage"):
		warnings.append("Storage")
	if not family_set.has("cooling"):
		warnings.append("Cooling")
	if not bipob.has_internal_interface():
		warnings.append("Internal Interface")
	if bipob.has_method("get_internal_connected_module_count") and bipob.has_method("get_internal_interface_port_capacity"):
		var internal_connected_count: int = bipob.get_internal_connected_module_count()
		var internal_port_capacity: int = bipob.get_internal_interface_port_capacity()
		if internal_connected_count > internal_port_capacity and not warnings.has("Internal Interface"):
			warnings.append("Internal Interface")
	if not bipob.has_external_interface_bridge():
		warnings.append("External Interface")
	if bipob.has_method("is_power_port_overloaded") and bipob.is_power_port_overloaded():
		if not warnings.has("Power Block"):
			warnings.append("Power Block")
	if not bipob_has_charger() and not warnings.has("Charger"):
		warnings.append("Charger")
	return warnings


func _create_internal_volume_placeholder_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_dark_panel_style(panel)
	panel.custom_minimum_size = Vector2(190, 150)
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 3)
	var title: Label = Label.new()
	title.text = "VOLUME PREVIEW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	root.add_child(title)
	var draw_host := InternalIsoPreviewControl.new(self)
	draw_host.name = "InternalIsoPreview"
	draw_host.custom_minimum_size = Vector2(184, 124)
	draw_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(draw_host)
	panel.add_child(root)
	return panel

func _get_internal_preview_volume_size() -> Vector3i:
	if bipob != null and bipob.has_method("get_internal_volume_size"):
		var size: Vector3i = bipob.get_internal_volume_size()
		if size.x > 0 and size.y > 0 and size.z > 0:
			return size
	return Vector3i(3, 3, 4)

func _draw_internal_isometric_preview(control: Control) -> void:
	if control == null:
		return
	var volume_size: Vector3i = _get_internal_preview_volume_size()
	var rect: Rect2 = control.get_rect()
	if rect.size.x <= 8.0 or rect.size.y <= 8.0:
		return
	var origin: Vector2 = rect.size * 0.5
	var cell_w: float = minf((rect.size.x - 26.0) / float(maxi(volume_size.x + volume_size.y, 1)) * 2.0, 30.0)
	var cell_h: float = cell_w
	var cell_z: float = minf((rect.size.y - 24.0) / float(maxi(volume_size.z, 1)), cell_w * 0.52)
	cell_w = maxf(cell_w, 9.0)
	cell_h = maxf(cell_h, 9.0)
	cell_z = maxf(cell_z, 7.0)
	var iso_corners: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(float(volume_size.x), 0.0, 0.0),
		Vector3(0.0, float(volume_size.y), 0.0),
		Vector3(float(volume_size.x), float(volume_size.y), 0.0),
		Vector3(0.0, 0.0, float(volume_size.z)),
		Vector3(float(volume_size.x), 0.0, float(volume_size.z)),
		Vector3(0.0, float(volume_size.y), float(volume_size.z)),
		Vector3(float(volume_size.x), float(volume_size.y), float(volume_size.z))
	]
	var min_point: Vector2 = _internal_iso_project(origin, iso_corners[0], cell_w, cell_h, cell_z)
	var max_point: Vector2 = min_point
	for corner in iso_corners:
		var p: Vector2 = _internal_iso_project(origin, corner, cell_w, cell_h, cell_z)
		min_point.x = minf(min_point.x, p.x)
		min_point.y = minf(min_point.y, p.y)
		max_point.x = maxf(max_point.x, p.x)
		max_point.y = maxf(max_point.y, p.y)
	var iso_center: Vector2 = (min_point + max_point) * 0.5
	var target_center: Vector2 = rect.size * 0.5
	origin += target_center - iso_center
	var outer_edge: Color = Color(0.25, 0.95, 1.0, 0.75)
	var inner_grid: Color = Color(0.20, 0.75, 0.90, 0.28)
	var face_fill: Color = Color(0.04, 0.10, 0.13, 0.18)

	_draw_internal_iso_grid_lines(control, volume_size, origin, cell_w, cell_h, cell_z, inner_grid)
	_draw_internal_iso_volume_faces(control, volume_size, origin, cell_w, cell_h, cell_z, face_fill)
	_draw_internal_isometric_module_projections(control, volume_size, origin, cell_w, cell_h, cell_z)
	_draw_internal_isometric_cursor_projection(control, volume_size, origin, cell_w, cell_h, cell_z)
	_draw_internal_iso_outer_edges(control, volume_size, origin, cell_w, cell_h, cell_z, outer_edge)

func _internal_iso_project(origin: Vector2, p: Vector3, cell_w: float, cell_h: float, cell_z: float) -> Vector2:
	var screen_x: float = origin.x + (p.x - p.y) * cell_w * 0.5
	var screen_y: float = origin.y + (p.x + p.y) * cell_h * 0.25 - p.z * cell_z
	return Vector2(screen_x, screen_y)

func _get_internal_iso_display_z(z: int, volume_size: Vector3i) -> int:
	return (volume_size.z - 1) - z

func _draw_internal_iso_grid_lines(control: Control, volume_size: Vector3i, origin: Vector2, cell_w: float, cell_h: float, cell_z: float, line_color: Color) -> void:
	for x in range(volume_size.x + 1):
		for y in range(volume_size.y + 1):
			var top_point: Vector2 = _internal_iso_project(origin, Vector3(x, y, float(volume_size.z)), cell_w, cell_h, cell_z)
			var bottom_point: Vector2 = _internal_iso_project(origin, Vector3(x, y, 0.0), cell_w, cell_h, cell_z)
			control.draw_line(top_point, bottom_point, line_color, 1.0)
	for z in range(volume_size.z + 1):
		for y in range(volume_size.y + 1):
			var start_x: Vector2 = _internal_iso_project(origin, Vector3(0.0, y, z), cell_w, cell_h, cell_z)
			var end_x: Vector2 = _internal_iso_project(origin, Vector3(float(volume_size.x), y, z), cell_w, cell_h, cell_z)
			control.draw_line(start_x, end_x, line_color, 1.0)
		for x in range(volume_size.x + 1):
			var start_y: Vector2 = _internal_iso_project(origin, Vector3(x, 0.0, z), cell_w, cell_h, cell_z)
			var end_y: Vector2 = _internal_iso_project(origin, Vector3(x, float(volume_size.y), z), cell_w, cell_h, cell_z)
			control.draw_line(start_y, end_y, line_color, 1.0)

func _draw_internal_iso_volume_faces(control: Control, volume_size: Vector3i, origin: Vector2, cell_w: float, cell_h: float, cell_z: float, fill_color: Color) -> void:
	var top_face: PackedVector2Array = PackedVector2Array([
		_internal_iso_project(origin, Vector3(0.0, 0.0, float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), float(volume_size.y), float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(0.0, float(volume_size.y), float(volume_size.z)), cell_w, cell_h, cell_z)
	])
	var front_face: PackedVector2Array = PackedVector2Array([
		_internal_iso_project(origin, Vector3(0.0, 0.0, 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(0.0, 0.0, float(volume_size.z)), cell_w, cell_h, cell_z)
	])
	var right_face: PackedVector2Array = PackedVector2Array([
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), float(volume_size.y), 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), float(volume_size.y), float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, float(volume_size.z)), cell_w, cell_h, cell_z)
	])
	control.draw_colored_polygon(top_face, fill_color)
	control.draw_colored_polygon(front_face, fill_color)
	control.draw_colored_polygon(right_face, fill_color)

func _draw_internal_iso_outer_edges(control: Control, volume_size: Vector3i, origin: Vector2, cell_w: float, cell_h: float, cell_z: float, edge_color: Color) -> void:
	var corners: Array[Vector2] = [
		_internal_iso_project(origin, Vector3(0.0, 0.0, 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(0.0, float(volume_size.y), 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), float(volume_size.y), 0.0), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(0.0, 0.0, float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), 0.0, float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(0.0, float(volume_size.y), float(volume_size.z)), cell_w, cell_h, cell_z),
		_internal_iso_project(origin, Vector3(float(volume_size.x), float(volume_size.y), float(volume_size.z)), cell_w, cell_h, cell_z)
	]
	var edges: Array = [[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
	for edge in edges:
		control.draw_line(corners[edge[0]], corners[edge[1]], edge_color, 1.5)

func _draw_internal_isometric_module_projections(control: Control, volume_size: Vector3i, origin: Vector2, cell_w: float, cell_h: float, cell_z: float) -> void:
	if bipob == null:
		return
	var modules: Array = []
	for record_variant in bipob.placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var module: BipobModule = record.get("module", null)
		if module == null:
			continue
		var origin_cell: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		var covered_cells: Array[Vector3i] = bipob.get_internal_module_covered_cells(module, origin_cell, rotation_index)
		if covered_cells.is_empty():
			continue
		modules.append({"module":module, "cells":covered_cells, "sort":origin_cell.x + origin_cell.y + origin_cell.z})
	modules.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sort", 0)) < int(b.get("sort", 0)))
	for item in modules:
		var covered_cells: Array[Vector3i] = item.get("cells", [])
		var module: BipobModule = item.get("module", null)
		if covered_cells.is_empty() or module == null:
			continue
		var min_x: int = covered_cells[0].x
		var max_x: int = covered_cells[0].x
		var min_y: int = covered_cells[0].y
		var max_y: int = covered_cells[0].y
		var min_z: int = covered_cells[0].z
		var max_z: int = covered_cells[0].z
		for cell in covered_cells:
			min_x = mini(min_x, cell.x); max_x = maxi(max_x, cell.x)
			min_y = mini(min_y, cell.y); max_y = maxi(max_y, cell.y)
			min_z = mini(min_z, cell.z); max_z = maxi(max_z, cell.z)
		var iso_min_z: int = _get_internal_iso_display_z(max_z, volume_size)
		var iso_max_z_exclusive: int = _get_internal_iso_display_z(min_z, volume_size) + 1
		var col: Color = bipob.get_module_visual_color(module) if bipob.has_method("get_module_visual_color") else Color(0.30, 0.60, 0.90, 1.0)
		_draw_internal_iso_cuboid(control, origin, cell_w, cell_h, cell_z, Vector3(min_x, min_y, iso_min_z), Vector3(max_x + 1, max_y + 1, iso_max_z_exclusive), Color(col.r, col.g, col.b, 0.45), col)

func _draw_internal_isometric_cursor_projection(control: Control, volume_size: Vector3i, origin: Vector2, cell_w: float, cell_h: float, cell_z: float) -> void:
	if bipob == null:
		return
	var c: Vector3i = bipob.selected_internal_origin
	var iso_z: int = _get_internal_iso_display_z(c.z, volume_size)
	var selected_outline: Color = Color(1.0, 0.90, 0.30, 0.85)
	_draw_internal_iso_cuboid_edges(control, origin, cell_w, cell_h, cell_z, Vector3(c.x, c.y, iso_z), Vector3(c.x + 1, c.y + 1, iso_z + 1), selected_outline, 1.8)

func _draw_internal_iso_cuboid(control: Control, origin: Vector2, cell_w: float, cell_h: float, cell_z: float, min_cell: Vector3, max_cell: Vector3, fill_col: Color, edge_col: Color) -> void:
	var corners: Dictionary = _internal_iso_cuboid_corners(origin, cell_w, cell_h, cell_z, min_cell, max_cell)
	var top: PackedVector2Array = PackedVector2Array([corners["011"], corners["111"], corners["101"], corners["001"]])
	var front: PackedVector2Array = PackedVector2Array([corners["000"], corners["100"], corners["101"], corners["001"]])
	var right: PackedVector2Array = PackedVector2Array([corners["100"], corners["110"], corners["111"], corners["101"]])
	control.draw_colored_polygon(top, Color(fill_col.r, fill_col.g, fill_col.b, fill_col.a * 0.92))
	control.draw_colored_polygon(front, fill_col)
	control.draw_colored_polygon(right, Color(fill_col.r, fill_col.g, fill_col.b, fill_col.a * 0.86))
	_draw_internal_iso_cuboid_edges(control, origin, cell_w, cell_h, cell_z, min_cell, max_cell, Color(edge_col.r, edge_col.g, edge_col.b, 0.85), 1.2)

func _draw_internal_iso_cuboid_edges(control: Control, origin: Vector2, cell_w: float, cell_h: float, cell_z: float, min_cell: Vector3, max_cell: Vector3, edge_color: Color, width: float) -> void:
	var corners: Dictionary = _internal_iso_cuboid_corners(origin, cell_w, cell_h, cell_z, min_cell, max_cell)
	var edges: Array = [["000","100"],["000","010"],["100","110"],["010","110"],["001","101"],["001","011"],["101","111"],["011","111"],["000","001"],["100","101"],["010","011"],["110","111"]]
	for edge in edges:
		control.draw_line(corners[edge[0]], corners[edge[1]], edge_color, width)

func _internal_iso_cuboid_corners(origin: Vector2, cell_w: float, cell_h: float, cell_z: float, min_cell: Vector3, max_cell: Vector3) -> Dictionary:
	return {
		"000": _internal_iso_project(origin, Vector3(min_cell.x, min_cell.y, min_cell.z), cell_w, cell_h, cell_z),
		"100": _internal_iso_project(origin, Vector3(max_cell.x, min_cell.y, min_cell.z), cell_w, cell_h, cell_z),
		"010": _internal_iso_project(origin, Vector3(min_cell.x, max_cell.y, min_cell.z), cell_w, cell_h, cell_z),
		"110": _internal_iso_project(origin, Vector3(max_cell.x, max_cell.y, min_cell.z), cell_w, cell_h, cell_z),
		"001": _internal_iso_project(origin, Vector3(min_cell.x, min_cell.y, max_cell.z), cell_w, cell_h, cell_z),
		"101": _internal_iso_project(origin, Vector3(max_cell.x, min_cell.y, max_cell.z), cell_w, cell_h, cell_z),
		"011": _internal_iso_project(origin, Vector3(min_cell.x, max_cell.y, max_cell.z), cell_w, cell_h, cell_z),
		"111": _internal_iso_project(origin, Vector3(max_cell.x, max_cell.y, max_cell.z), cell_w, cell_h, cell_z)
	}

func get_box_internal_menu_text() -> String:
	_clamp_internal_selection()
	sync_selected_box_storage_index_from_filter()
	var selected_module: BipobModule = _get_selected_internal_module()
	var preview_cells: Array[Vector3i] = []
	var preview_cells_map: Dictionary = {}
	var reason: String = "No internal module selected."
	var can_place: bool = false
	var placement_size: Vector3i = Vector3i.ZERO
	var base_size: Vector3i = Vector3i.ZERO
	var selected_cell_module: BipobModule = bipob.get_internal_module_at_cell(bipob.selected_internal_origin)
	var selected_module_id: String = ""
	var is_overlay_module: bool = false
	if selected_module != null:
		selected_module_id = selected_module.id
		is_overlay_module = selected_module_id == "water_tube_v1" or selected_module_id == "air_duct_v1"
		base_size = bipob.get_internal_module_base_size(selected_module)
		placement_size = bipob.get_rotated_internal_size(selected_module, bipob.selected_internal_rotation)
		preview_cells = bipob.get_internal_module_covered_cells(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		for cell in preview_cells:
			preview_cells_map[bipob.get_internal_slot_key(cell)] = true
		reason = bipob.get_internal_module_placement_error(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		can_place = reason.is_empty()
	if can_place:
		reason = "OK"

	var lines: Array[String] = []
	lines.append("CONSTRUCTOR LAYOUT")
	lines.append("TOP BAR: External Modules | Internal Modules | Available Bipobs")
	lines.append("MAIN ROW: Internal Workspace | Components in Box Storage | Connections")
	lines.append("BOTTOM BAR: Constructor Status | Selected Module")
	lines.append("")
	lines.append("INTERNAL MODULES")
	lines.append("VERTICAL SLICE | HORIZONTAL SLICE | INTERNAL VOLUME")
	lines.append("LEGEND: Power Channels / Cooling Channels / Data Buses / Empty Cell")
	lines.append("CONNECTIONS: POWER, NETWORK / DATA, COOLING")
	lines.append("")
	var volume_size: Vector3i = bipob.get_internal_volume_size()
	var overlay_count: int = bipob.internal_overlay_paths.size()
	lines.append(_section_title("Internal Constructor"))
	lines.append("View mode: %s" % _get_internal_view_mode_display_name())
	lines.append("Filter: %s" % get_current_constructor_filter().capitalize())
	lines.append("Cursor: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
	lines.append("Internal Volume: %d×%d×%d" % [volume_size.x, volume_size.y, volume_size.z])
	lines.append("Right panel groups: Selection / Position / Module / View / Overlay Plan")
	_empty_line(lines)

	lines.append(_section_title("Selected Module"))
	if selected_module == null:
		lines.append("Selected: none")
		lines.append("Hint: No module matches current filter.")
	else:
		lines.append("Selected: %s" % bipob.get_module_display_name(selected_module))
		var box_count: int = bipob.get_box_module_count_by_id(selected_module.id)
		var overlay_available: int = 0
		lines.append("Availability: box %d / overlay %d / total %d" % [box_count, overlay_available, box_count + overlay_available])
		lines.append("Placement: %s" % selected_module.placement_type)
		if selected_module.placement_type != "internal" and not is_overlay_module:
			lines.append("Hint: Cannot place in internal volume.")
		elif is_overlay_module:
			lines.append("Hint: Use Overlay Plan actions, not Place Internal.")
		lines.append("Category: %s" % bipob.get_module_category(selected_module))
		lines.append("Size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
		lines.append("Role: %s" % _get_module_role_text(selected_module))
		lines.append(_get_module_heat_text(selected_module))
		lines.append("Cooling: %s %d" % [selected_module.cooling_type, selected_module.cooling_power])
		lines.append("Air Intake: %s" % ("required" if selected_module.requires_air_intake else "not required"))
	_empty_line(lines)

	lines.append(_section_title("Placement"))
	lines.append("Origin: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
	lines.append("Rotation: %d" % bipob.selected_internal_rotation)
	lines.append("Base size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
	lines.append("Rotated size: %d×%d×%d" % [placement_size.x, placement_size.y, placement_size.z])
	if is_overlay_module:
		lines.append("Overlay path module: use Commit Plan.")
	else:
		lines.append("Valid: %s" % get_yes_no(can_place))
		lines.append("Reason: %s" % reason)
	lines.append("Selected cell: %s" % ("empty" if selected_cell_module == null else "occupied by %s" % bipob.get_module_display_name(selected_cell_module)))
	_empty_line(lines)

	lines.append(_section_title("Status"))
	lines.append("Power: %s" % ("available" if bipob.is_virtual_power_available() else "unavailable"))
	lines.append("Internal Data: %s" % ("available" if bipob.is_internal_data_network_available() else "unavailable"))
	lines.append("External Data: %s" % ("available" if bipob.is_external_data_network_available() else "unavailable"))
	lines.append("Air Intake: %s" % get_air_intake_status_text())
	lines.append("Warnings: %d" % bipob.get_constructor_warning_lines().size())
	lines.append(bipob.get_constructor_planning_checkpoint_compact_text())
	var highest_heat: int = 0
	var critical_count: int = 0
	if bipob.has_method("get_highest_internal_preview_heat"):
		highest_heat = bipob.get_highest_internal_preview_heat()
	if bipob.has_method("get_critical_internal_preview_count"):
		critical_count = bipob.get_critical_internal_preview_count()
	var thermal_status: String = "ok"
	if critical_count > 0 or highest_heat >= 5:
		thermal_status = "critical preview"
	elif highest_heat >= 4:
		thermal_status = "warning"
	lines.append("Thermal: %s" % thermal_status)
	var consistency_issue_count: int = bipob.get_constructor_consistency_issue_lines().size()
	lines.append("Consistency: %s" % ("OK" if consistency_issue_count <= 0 else "%d issue(s)" % consistency_issue_count))
	_empty_line(lines)

	lines.append(_section_title("Views"))
	lines.append("Legend: %s" % _get_internal_view_legend_text())
	lines.append("Front view — X/Y at Z=%d" % bipob.selected_internal_origin.z)
	lines.append(_build_internal_axis_header("x", volume_size.x))
	for y in range(volume_size.y):
		var front_row: Array[String] = []
		for x in range(volume_size.x):
			var front_cell: Vector3i = Vector3i(x, y, bipob.selected_internal_origin.z)
			front_row.append(_get_internal_cell_marker(front_cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(front_row)])
	_empty_line(lines)
	lines.append("Vertical slice — Z/Y at X=%d" % bipob.selected_internal_origin.x)
	lines.append(_build_internal_axis_header("z", volume_size.z))
	for y in range(volume_size.y):
		var vertical_row: Array[String] = []
		for z in range(volume_size.z):
			var vertical_cell: Vector3i = Vector3i(bipob.selected_internal_origin.x, y, z)
			vertical_row.append(_get_internal_cell_marker(vertical_cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(vertical_row)])
	_empty_line(lines)
	lines.append("Horizontal slice — X/Z at Y=%d" % bipob.selected_internal_origin.y)
	lines.append(_build_internal_axis_header("x", volume_size.x))
	for z in range(volume_size.z):
		var horizontal_row: Array[String] = []
		for x in range(volume_size.x):
			var horizontal_cell: Vector3i = Vector3i(x, bipob.selected_internal_origin.y, z)
			horizontal_row.append(_get_internal_cell_marker(horizontal_cell, preview_cells_map, can_place))
		lines.append("z%d %s" % [z, " ".join(horizontal_row)])
	_empty_line(lines)

	lines.append(_section_title("Overlay Plan"))
	lines.append("Overlay Type: %s" % bipob.selected_overlay_path_type)
	lines.append("Overlay Cells: %d" % bipob.selected_overlay_cells.size())
	lines.append(str(bipob.get_selected_overlay_plan_short_text()))
	lines.append(str(bipob.get_overlay_connectivity_compact_text()))
	lines.append(str(bipob.get_overlay_endpoint_compact_text()))
	var required_overlay_module_id: String = bipob.get_selected_overlay_module_id()
	lines.append("Required module: %s" % required_overlay_module_id)
	lines.append("Available in box: %d" % bipob.get_box_module_count_by_id(required_overlay_module_id))
	_empty_line(lines)

	lines.append(_section_title("Selected Overlay Path"))
	if overlay_count <= 0:
		lines.append("Selected Overlay Path: none")
	else:
		bipob.clamp_selected_overlay_path_index()
		var selected_overlay_record: Dictionary = bipob.get_selected_overlay_path_record()
		lines.append("Selected path: %d / %d" % [bipob.selected_overlay_path_index + 1, overlay_count])
		lines.append("ID: %s" % str(selected_overlay_record.get("id", "overlay_%d" % (bipob.selected_overlay_path_index + 1))))
		lines.append("Overlay Type: %s" % str(selected_overlay_record.get("path_type", "unknown")))
		var selected_overlay_cells: Array = selected_overlay_record.get("cells", [])
		lines.append("Cells: %d" % selected_overlay_cells.size())
		lines.append("Connected: %s" % ("yes" if bool(selected_overlay_record.get("connected", false)) else "no"))
		lines.append("Components: %d" % int(selected_overlay_record.get("component_count", 0)))
		lines.append("Endpoints: %d" % int(selected_overlay_record.get("endpoint_count", 0)))
		lines.append("Suitability: %s" % str(selected_overlay_record.get("suitability", "unknown")))
	_empty_line(lines)

	lines.append(_section_title("Thermal Preview"))
	lines.append("Highest heat: %d / %d" % [highest_heat, bipob.THERMAL_CRITICAL_HEAT])
	lines.append("Critical preview: %d" % critical_count)
	lines.append(str(bipob.get_damage_planning_compact_text()))
	lines.append(str(bipob.get_repair_planning_compact_reference_text()))
	lines.append("Overlay Thermal: %s" % str(bipob.get_overlay_thermal_contribution_compact_text()))
	lines.append("Overlay Diff: %s" % str(bipob.get_overlay_thermal_contribution_diff_summary_text()))
	lines.append("Thermal Rules: heat 1-5, critical 5, overlay hypothetical")
	lines.append("Base thermal remains unchanged.")
	_empty_line(lines)

	lines.append(_section_title("Placed Internal Modules"))
	if bipob.placed_internal_modules.is_empty():
		lines.append("none")
	else:
		var display_limit: int = mini(8, bipob.placed_internal_modules.size())
		for i in range(display_limit):
			var record: Dictionary = bipob.placed_internal_modules[i]
			var placed_module: BipobModule = record.get("module", null)
			if placed_module == null:
				continue
			var origin: Vector3i = record.get("origin", Vector3i.ZERO)
			var rotation_index: int = int(record.get("rotation", 0))
			var size: Vector3i = bipob.get_rotated_internal_size(placed_module, rotation_index)
			lines.append("- %s at %d,%d,%d size %d×%d×%d rot %d" % [bipob.get_module_display_name(placed_module), origin.x, origin.y, origin.z, size.x, size.y, size.z, rotation_index])
		if bipob.placed_internal_modules.size() > display_limit:
			lines.append("...and %d more" % (bipob.placed_internal_modules.size() - display_limit))

	return "\n".join(lines)

func _move_internal_cursor(dx: int, dy: int, dz: int) -> void:
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x + dx, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y + dy, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z + dz, 0, v.z - 1)
	update_box_status()

func _on_prev_internal_box_pressed() -> void:
	_on_prev_box_pressed()

func _on_next_internal_box_pressed() -> void:
	_on_next_box_pressed()

func _on_prev_constructor_filter_pressed() -> void:
	var filter_index: int = _get_active_filter_index() - 1
	if filter_index < 0:
		filter_index = CONSTRUCTOR_FILTERS.size() - 1
	_set_active_filter_index(filter_index)
	_clear_box_module_selection_if_invalid_for_current_context()
	update_box_status()

func _on_next_constructor_filter_pressed() -> void:
	var filter_index: int = _get_active_filter_index() + 1
	if filter_index >= CONSTRUCTOR_FILTERS.size():
		filter_index = 0
	_set_active_filter_index(filter_index)
	_clear_box_module_selection_if_invalid_for_current_context()
	update_box_status()

func _on_internal_x_minus_pressed() -> void: _move_internal_cursor(-1, 0, 0)
func _on_internal_x_plus_pressed() -> void: _move_internal_cursor(1, 0, 0)
func _on_internal_y_minus_pressed() -> void: _move_internal_cursor(0, -1, 0)
func _on_internal_y_plus_pressed() -> void: _move_internal_cursor(0, 1, 0)
func _on_internal_z_minus_pressed() -> void: _move_internal_cursor(0, 0, -1)
func _on_internal_z_plus_pressed() -> void: _move_internal_cursor(0, 0, 1)
func _on_rotate_internal_pressed() -> void:
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation + 1, 3)
	update_box_status()
func _on_place_internal_pressed() -> void:
	var selected_module: BipobModule = get_selected_grouped_module()
	if selected_module == null:
		show_hint("No module matches current filter.")
		return
	if bipob.get_box_module_count_by_id(selected_module.id) <= 0:
		show_hint("No available copy in Box Storage.")
		return
	sync_selected_box_storage_index_from_grouped_selection()
	if selected_box_storage_index < 0:
		show_hint("No available copy in Box Storage.")
		return
	if bipob.place_internal_module(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation):
		update_box_status()
func _on_remove_internal_pressed() -> void:
	if bipob.remove_internal_module(bipob.selected_internal_origin):
		if selected_module_source == "installed_internal":
			selected_constructor_module = null
			selected_module_source = "none"
		update_box_status()

func _on_toggle_internal_view_pressed() -> void:
	if internal_view_mode == "modules":
		internal_view_mode = "thermal"
	elif internal_view_mode == "thermal":
		internal_view_mode = "overlay"
	elif internal_view_mode == "overlay":
		internal_view_mode = "thermal_overlay"
	else:
		internal_view_mode = "modules"
	update_box_status()
func _on_reset_internal_cursor_pressed() -> void:
	bipob.selected_internal_origin = Vector3i.ZERO
	bipob.selected_internal_rotation = 0
	update_box_status()


func _on_overlay_type_pressed() -> void:
	bipob.selected_overlay_path_type = "duct" if bipob.selected_overlay_path_type == "liquid" else "liquid"
	update_box_status()

func _on_toggle_overlay_cell_pressed() -> void:
	bipob.toggle_selected_overlay_cell(bipob.selected_internal_origin)
	update_box_status()

func _on_extend_overlay_pos_x_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+x")
	if not ok:
		show_hint("Cannot extend overlay +X.")
	update_box_status()

func _on_extend_overlay_neg_x_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-x")
	if not ok:
		show_hint("Cannot extend overlay -X.")
	update_box_status()

func _on_extend_overlay_pos_y_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+y")
	if not ok:
		show_hint("Cannot extend overlay +Y.")
	update_box_status()

func _on_extend_overlay_neg_y_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-y")
	if not ok:
		show_hint("Cannot extend overlay -Y.")
	update_box_status()

func _on_extend_overlay_pos_z_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+z")
	if not ok:
		show_hint("Cannot extend overlay +Z.")
	update_box_status()

func _on_extend_overlay_neg_z_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-z")
	if not ok:
		show_hint("Cannot extend overlay -Z.")
	update_box_status()

func _on_undo_overlay_cell_pressed() -> void:
	var ok: bool = bipob.undo_selected_overlay_cell()
	if not ok:
		show_hint("No overlay cell to undo.")
	update_box_status()

func _on_commit_overlay_pressed() -> void:
	if bipob.commit_selected_overlay_path():
		update_box_status()
		return
	if bipob.get_selected_overlay_module_id() == "air_duct_v1":
		show_hint("No Air Duct V1 in Box Storage.")
	else:
		show_hint("No Water Tube V1 in Box Storage.")
	update_box_status()

func _on_clear_plan_pressed() -> void:
	if _is_constructor_external_mode() and bipob.has_method("clear_external_modules_for_profile"):
		bipob.clear_external_modules_for_profile(active_bipob_profile_id)
		selected_constructor_module = null
		selected_module_source = "none"
		selected_install_record = {}
		update_box_status()
		return
	if _is_constructor_internal_mode() and bipob.has_method("clear_internal_modules_for_profile"):
		bipob.clear_internal_modules_for_profile(active_bipob_profile_id)
		update_box_status()
		return
	bipob.clear_selected_overlay_cells()
	update_box_status()

func _on_clear_overlay_pressed() -> void:
	_on_clear_plan_pressed()

func _on_overlay_check_pressed() -> void:
	if _safe_has_bipob_method("get_overlay_connectivity_preview_text"):
		_show_constructor_reference_text("OVERLAY CHECK", str(bipob.get_overlay_connectivity_preview_text()))
	else:
		_show_constructor_reference_text("OVERLAY CHECK", "Overlay connectivity helper is unavailable.")

func _on_overlay_endpoints_pressed() -> void:
	if _safe_has_bipob_method("get_overlay_endpoint_preview_text"):
		_show_constructor_reference_text("ENDPOINTS", str(bipob.get_overlay_endpoint_preview_text()))
	else:
		_show_constructor_reference_text("ENDPOINTS", "Overlay endpoint helper is unavailable.")

func _on_overlay_thermal_pressed() -> void:
	if _safe_has_bipob_method("get_overlay_thermal_contribution_preview_text"):
		_show_constructor_reference_text("OVERLAY THERMAL", str(bipob.get_overlay_thermal_contribution_preview_text()))
	else:
		_show_constructor_reference_text("OVERLAY THERMAL", "Overlay thermal helper is unavailable.")

func _on_thermal_rules_pressed() -> void:
	if _safe_has_bipob_method("get_thermal_rules_reference_text"):
		_show_constructor_reference_text("THERMAL RULES", str(bipob.get_thermal_rules_reference_text()))
	else:
		_show_constructor_reference_text("THERMAL RULES", "Thermal rules helper is unavailable.")

func _on_damage_plan_pressed() -> void:
	if _safe_has_bipob_method("get_damage_planning_preview_text"):
		_show_constructor_reference_text("DAMAGE PLAN", str(bipob.get_damage_planning_preview_text()))
	else:
		_show_constructor_reference_text("DAMAGE PLAN", "Damage planning helper is unavailable.")

func _on_repair_rules_pressed() -> void:
	if _safe_has_bipob_method("get_repair_planning_reference_text"):
		_show_constructor_reference_text("REPAIR RULES", str(bipob.get_repair_planning_reference_text()))
	else:
		_show_constructor_reference_text("REPAIR RULES", "Repair rules helper is unavailable.")

func _on_overlay_diff_pressed() -> void:
	if _safe_has_bipob_method("get_overlay_heat_diff_summary_text"):
		_show_constructor_reference_text("OVERLAY DIFF", str(bipob.get_overlay_heat_diff_summary_text(false)))
	else:
		_show_constructor_reference_text("OVERLAY DIFF", "Overlay diff helper is unavailable.")



func _normalize_text(value: String) -> String:
	return value.to_lower().strip_edges()

func _count_internal_family(family: String) -> int:
	var total: int = 0
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		var f := _normalize_text(String(module.internal_family))
		if family == "battery" and (f == "battery" or module.id.begins_with("battery_")):
			total += 1
		elif f == family:
			total += 1
	return total

func _has_internal_family(family: String) -> bool:
	return _count_internal_family(family) > 0

func _place_first_internal_family(family: String) -> void:
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if not _is_ready_module(module) or not bipob.is_internal_module(module):
			continue
		var f := _normalize_text(String(module.internal_family))
		var n := _normalize_text(module.get_display_name())
		if family == "storage" and not (f == "storage" or n.contains("hard drive")):
			continue
		elif family == "cooler" and not n.contains("cooler"):
			continue
		elif family == "radiator" and not n.contains("radiator"):
			continue
		elif family == "power" and not (f == "power" or n.contains("power block")):
			continue
		elif family == "charger" and not (module.id == "charger_v1" or n.contains("charger")):
			continue
		elif family in ["battery","cpu","ram","gpu","internal_interface","external_interface"] and f != family and not (family=="battery" and module.id.begins_with("battery_")):
			continue
		for z in range(_get_internal_preview_volume_size().z):
			for y in range(_get_internal_preview_volume_size().y):
				for x in range(_get_internal_preview_volume_size().x):
					var pos := Vector3i(x,y,z)
					if bipob.place_internal_module(module, pos, 0) or bipob.place_internal_module(module, pos, 1):
						return
		return

func _place_external_group_if_missing(group: String, preferred_sides: Array[String]) -> void:
	if _has_external_group(group):
		return
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if not _is_ready_module(module) or not bipob.is_external_module(module):
			continue
		if not _module_matches_external_group(module, group):
			continue
		for side in preferred_sides:
			var size: Vector2i = bipob.get_external_side_size(side)
			for y in range(size.y):
				for x in range(size.x):
					if bipob.place_external_module_from_box_storage(i, side, Vector2i(x,y)):
						return

func _has_external_group(group: String) -> bool:
	for record in bipob.placed_external_modules:
		var module: BipobModule = record.get("module", null)
		if module != null and _module_matches_external_group(module, group):
			return true
	return false

func _module_matches_external_group(module: BipobModule, group: String) -> bool:
	var c := _normalize_text(module.category)
	var n := _normalize_text(module.get_display_name())
	if group == "gear": return c in ["gear","gears"] or n.contains("gear") or n.contains("chassis")
	if group == "sensor": return c.contains("sensor") or n.contains("visor")
	if group == "interface": return c.contains("interface") or n.contains("wired interface") or n.contains("connector")
	if group == "manipulator": return c in ["manipulator","manipulators"] or n.contains("manipulator") or n.contains("arm")
	return false

func _is_ready_module(module: BipobModule) -> bool:
	if bipob == null or not is_instance_valid(bipob):
		return false
	if module == null:
		return false
	if bipob.has_method("is_module_broken") and bipob.is_module_broken(module):
		return false
	if bipob.has_method("is_module_unknown") and bipob.is_module_unknown(module):
		return false
	return true

func _is_internal_interface_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if bipob == null or not is_instance_valid(bipob) or not bipob.has_method("is_internal_module") or not bipob.is_internal_module(module):
		return false
	var id: String = String(module.id).to_lower()
	var module_name: String = String(module.get_display_name()).to_lower()
	var family: String = String(module.internal_family).to_lower()
	return id.contains("internal_interface") or module_name.contains("internal interface") or family in ["internal_interface", "internal interface"]

func _is_external_interface_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if bipob == null or not is_instance_valid(bipob) or not bipob.has_method("is_internal_module") or not bipob.is_internal_module(module):
		return false
	var id: String = String(module.id).to_lower()
	var module_name: String = String(module.get_display_name()).to_lower()
	var family: String = String(module.internal_family).to_lower()
	if module_name.contains("wired interface") or module_name.contains("optical interface") or module_name.contains("wireless interface"):
		return false
	return id.contains("external_interface") or module_name.contains("external interface") or family in ["external_interface", "external interface"]

func _is_power_block_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if bipob == null or not is_instance_valid(bipob) or not bipob.has_method("is_internal_module") or not bipob.is_internal_module(module):
		return false
	var id: String = String(module.id).to_lower()
	var module_name: String = String(module.get_display_name()).to_lower()
	var family: String = String(module.internal_family).to_lower()
	return id.contains("power_block") or module_name.contains("power block") or family in ["power_block", "power block", "power"]

func _has_installed_internal_group(group_id: String) -> bool:
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		if _module_matches_internal_auto_group(module, group_id):
			return true
	return false

func _find_available_internal_module_by_group(group_id: String) -> BipobModule:
	if bipob == null or not is_instance_valid(bipob) or not bipob.has_method("is_internal_module"):
		return null
	for module in bipob.box_storage:
		if not _is_ready_module(module) or not bipob.is_internal_module(module):
			continue
		if _module_matches_internal_auto_group(module, group_id):
			return module
	return null

func _try_place_internal_module_for_group(group_id: String, warn_name: String = "") -> bool:
	var module: BipobModule = _find_available_internal_module_by_group(group_id)
	if module == null:
		return false
	var size: Vector3i = _get_internal_preview_volume_size()
	if size.x <= 0 or size.y <= 0 or size.z <= 0:
		if not warn_name.is_empty():
			show_hint("Auto-configuration failed: invalid internal volume for %s" % warn_name)
		return false
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var pos := Vector3i(x, y, z)
				if bipob.place_internal_module(module, pos, 0) or bipob.place_internal_module(module, pos, 1):
					return true
	if not warn_name.is_empty():
		show_hint("Auto-configuration failed: no valid space for %s" % warn_name)
	return false

func _on_auto_configure_pressed() -> void:
	if bipob == null or not is_instance_valid(bipob):
		_report_auto_configuration_failure("no active Bipob selected")
		return
	if _is_constructor_internal_mode():
		_auto_configure_internal()
	else:
		_auto_configure_external()
	update_box_status()

func _get_internal_auto_config_targets() -> Array[Dictionary]:
	return [
		{"id":"battery","count":2,"label":"Battery"},
		{"id":"power_block","count":1,"label":"Power Block"},
		{"id":"processor","count":1,"label":"Processor"},
		{"id":"memory","count":1,"label":"Memory"},
		{"id":"gpu","count":1,"label":"GPU"},
		{"id":"storage","count":1,"label":"Storage"},
		{"id":"internal_interface","count":1,"label":"Internal Interface"},
		{"id":"external_interface","count":1,"label":"External Interface"},
		{"id":"cooler","count":1,"label":"Cooler"},
		{"id":"radiator","count":1,"label":"Radiator"},
		{"id":"charger","count":1,"label":"Charger"}
	]

func _report_auto_configuration_failure(reason: String) -> void:
	var safe_reason: String = reason.strip_edges()
	if safe_reason.is_empty():
		safe_reason = "unknown reason"
	var message: String = "Auto-configuration failed: %s" % safe_reason
	print("_auto_configure_internal: " + message)
	show_hint(message)

func _report_auto_configuration_success() -> void:
	print("_auto_configure_internal: Auto-configuration applied.")
	show_hint("Auto-configuration applied.")

func _module_matches_internal_auto_group(module: BipobModule, group_id: String) -> bool:
	if module == null:
		return false
	var normalized_group: String = _normalize_text(group_id)
	var module_id: String = _normalize_text(String(module.id))
	var family: String = _normalize_text(String(module.internal_family))
	var display_name: String = _normalize_text(module.get_display_name())
	match normalized_group:
		"power_block":
			return module_id.contains("power_block") or display_name.contains("power block") or family in ["power_block", "power block", "power"]
		"internal_interface":
			return module_id.contains("internal_interface") or display_name.contains("internal interface") or family in ["internal_interface", "internal interface"]
		"external_interface":
			if display_name.contains("wired interface") or display_name.contains("optical interface") or display_name.contains("wireless interface"):
				return false
			return module_id.contains("external_interface") or display_name.contains("external interface") or family in ["external_interface", "external interface"]
		"storage":
			return family == "storage" or display_name.contains("hard drive")
		"processor":
			return family in ["cpu", "processor"]
		"memory":
			return family in ["ram", "memory"]
		"gpu":
			return family == "gpu"
		"cooler":
			return family == "cooler" or display_name.contains("cooler")
		"radiator":
			return family == "radiator" or display_name.contains("radiator")
		"charger":
			return family == "charger" or display_name.contains("charger") or module_id == "charger_v1"
		"battery":
			return family == "battery" or module_id.begins_with("battery_")
		_:
			return family == normalized_group

func _internal_auto_group_count(modules: Array[BipobModule], group_id: String) -> int:
	var total: int = 0
	for module in modules:
		if module != null and _module_matches_internal_auto_group(module, group_id):
			total += 1
	return total

func _get_internal_auto_module_size(module: BipobModule, rotation_index: int) -> Vector3i:
	if module == null:
		return Vector3i.ZERO
	var base_size := Vector3i(maxi(int(module.size_x), 1), maxi(int(module.size_y), 1), maxi(int(module.size_z), 1))
	match posmod(rotation_index, 3):
		1:
			return Vector3i(base_size.z, base_size.y, base_size.x)
		2:
			return Vector3i(base_size.x, base_size.z, base_size.y)
		_:
			return base_size

func _get_internal_auto_module_cells(module: BipobModule, origin: Vector3i, rotation_index: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var module_size: Vector3i = _get_internal_auto_module_size(module, rotation_index)
	if module_size.x <= 0 or module_size.y <= 0 or module_size.z <= 0:
		return cells
	for z in range(module_size.z):
		for y in range(module_size.y):
			for x in range(module_size.x):
				cells.append(origin + Vector3i(x, y, z))
	return cells

func _is_internal_auto_cell_in_bounds(cell: Vector3i, volume_size: Vector3i) -> bool:
	return (
		cell.x >= 0 and cell.y >= 0 and cell.z >= 0
		and cell.x < volume_size.x and cell.y < volume_size.y and cell.z < volume_size.z
	)

func _can_place_internal_auto_module(module: BipobModule, origin: Vector3i, rotation_index: int, volume_size: Vector3i, occupancy: Dictionary) -> bool:
	var cells: Array[Vector3i] = _get_internal_auto_module_cells(module, origin, rotation_index)
	if cells.is_empty():
		return false
	for cell in cells:
		if not _is_internal_auto_cell_in_bounds(cell, volume_size):
			return false
		var key: String = "%d:%d:%d" % [cell.x, cell.y, cell.z]
		if occupancy.has(key):
			return false
	return true

func _reserve_internal_auto_module(module: BipobModule, origin: Vector3i, rotation_index: int, occupancy: Dictionary) -> void:
	for cell in _get_internal_auto_module_cells(module, origin, rotation_index):
		var key: String = "%d:%d:%d" % [cell.x, cell.y, cell.z]
		occupancy[key] = module

func _build_internal_auto_occupancy(volume_size: Vector3i) -> Dictionary:
	var occupancy: Dictionary = {}
	if bipob == null or not is_instance_valid(bipob):
		return occupancy
	for record_variant in bipob.placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var module: BipobModule = record.get("module", null)
		if module == null:
			continue
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		for cell in _get_internal_auto_module_cells(module, origin, rotation_index):
			if not _is_internal_auto_cell_in_bounds(cell, volume_size):
				continue
			var key: String = "%d:%d:%d" % [cell.x, cell.y, cell.z]
			occupancy[key] = module
	return occupancy

func _find_internal_auto_candidate(group_id: String, available_modules: Array[BipobModule], used_modules: Array[BipobModule]) -> BipobModule:
	if bipob == null or not is_instance_valid(bipob) or not bipob.has_method("is_internal_module"):
		return null
	for module in available_modules:
		if module == null or used_modules.has(module):
			continue
		if not _is_ready_module(module):
			continue
		if not bipob.is_internal_module(module):
			continue
		if _module_matches_internal_auto_group(module, group_id):
			return module
	return null

func _find_internal_auto_placement(module: BipobModule, volume_size: Vector3i, occupancy: Dictionary) -> Dictionary:
	if module == null:
		return {}
	var rotations: Array[int] = [0, 1]
	if bool(module.internal_rotatable):
		rotations = [0, 1, 2]
	for z in range(volume_size.z):
		for y in range(volume_size.y):
			for x in range(volume_size.x):
				var origin := Vector3i(x, y, z)
				for rotation_index in rotations:
					if _can_place_internal_auto_module(module, origin, rotation_index, volume_size, occupancy):
						return {"origin": origin, "rotation": rotation_index}
	return {}

func _validate_internal_auto_configuration_plan() -> Dictionary:
	if bipob == null or not is_instance_valid(bipob):
		return {"ok": false, "reason": "no active Bipob selected"}
	for method_name in ["is_internal_module", "can_place_internal_module", "place_internal_module"]:
		if not bipob.has_method(method_name):
			return {"ok": false, "reason": "Bipob is missing %s()" % method_name}
	var volume_size: Vector3i = _get_internal_preview_volume_size()
	if volume_size.x <= 0 or volume_size.y <= 0 or volume_size.z <= 0:
		return {"ok": false, "reason": "invalid internal volume"}
	var installed_modules: Array[BipobModule] = _get_internal_installed_modules()
	var available_modules: Array[BipobModule] = []
	for module in bipob.box_storage:
		if module == null:
			continue
		if not _is_ready_module(module):
			continue
		if not bipob.is_internal_module(module):
			continue
		available_modules.append(module)
	var occupancy: Dictionary = _build_internal_auto_occupancy(volume_size)
	var used_modules: Array[BipobModule] = []
	var planned_modules: Array[BipobModule] = installed_modules.duplicate()
	var plan: Array[Dictionary] = []
	for target in _get_internal_auto_config_targets():
		var group_id: String = String(target.get("id", "")).strip_edges()
		var target_count: int = maxi(int(target.get("count", 1)), 0)
		var label: String = String(target.get("label", group_id))
		if group_id.is_empty():
			return {"ok": false, "reason": "internal auto-config target has no group id"}
		var current_count: int = _internal_auto_group_count(planned_modules, group_id)
		while current_count < target_count:
			var candidate: BipobModule = _find_internal_auto_candidate(group_id, available_modules, used_modules)
			if candidate == null:
				return {"ok": false, "reason": "missing %s in Box Storage" % label}
			var module_id: String = String(candidate.id).strip_edges()
			if module_id.is_empty():
				return {"ok": false, "reason": "%s module has no module id" % label}
			if used_modules.has(candidate) or installed_modules.has(candidate):
				return {"ok": false, "reason": "duplicate %s module selection" % label}
			if not bipob.is_internal_module(candidate):
				return {"ok": false, "reason": "%s is not an internal module" % candidate.get_display_name()}
			if not _module_matches_internal_auto_group(candidate, group_id):
				return {"ok": false, "reason": "%s does not match %s" % [candidate.get_display_name(), label]}
			var placement: Dictionary = _find_internal_auto_placement(candidate, volume_size, occupancy)
			if placement.is_empty():
				return {"ok": false, "reason": "no valid internal slot for %s" % label}
			var origin: Vector3i = placement.get("origin", Vector3i.ZERO)
			var rotation_index: int = int(placement.get("rotation", 0))
			if not _can_place_internal_auto_module(candidate, origin, rotation_index, volume_size, occupancy):
				return {"ok": false, "reason": "invalid planned slot for %s" % label}
			_reserve_internal_auto_module(candidate, origin, rotation_index, occupancy)
			used_modules.append(candidate)
			planned_modules.append(candidate)
			plan.append({"module": candidate, "origin": origin, "rotation": rotation_index, "label": label})
			current_count += 1
	return {"ok": true, "plan": plan}

func _create_internal_auto_config_snapshot() -> Dictionary:
	if bipob == null or not is_instance_valid(bipob):
		return {}
	return {
		"box_storage": bipob.box_storage.duplicate(),
		"placed_internal_modules": bipob.placed_internal_modules.duplicate(true),
		"internal_modules_by_cell": bipob.internal_modules_by_cell.duplicate(true)
	}

func _restore_internal_auto_config_snapshot(snapshot: Dictionary) -> void:
	if bipob == null or not is_instance_valid(bipob) or snapshot.is_empty():
		return
	bipob.box_storage.clear()
	for module in snapshot.get("box_storage", []):
		bipob.box_storage.append(module)
	bipob.placed_internal_modules.clear()
	for record in snapshot.get("placed_internal_modules", []):
		if typeof(record) == TYPE_DICTIONARY:
			bipob.placed_internal_modules.append(record)
	bipob.internal_modules_by_cell.clear()
	var saved_cells: Dictionary = snapshot.get("internal_modules_by_cell", {})
	for key in saved_cells.keys():
		bipob.internal_modules_by_cell[key] = saved_cells[key]
	if bipob.has_signal("status_changed"):
		bipob.status_changed.emit()

func _auto_configure_internal() -> void:
	var validation: Dictionary = _validate_internal_auto_configuration_plan()
	if not bool(validation.get("ok", false)):
		_report_auto_configuration_failure(String(validation.get("reason", "unknown reason")))
		return
	var plan: Array[Dictionary] = []
	var plan_variant: Variant = validation.get("plan", [])
	if typeof(plan_variant) == TYPE_ARRAY:
		for step_variant in plan_variant:
			if typeof(step_variant) == TYPE_DICTIONARY:
				plan.append(step_variant)
	var snapshot: Dictionary = _create_internal_auto_config_snapshot()
	for step in plan:
		var module: BipobModule = step.get("module", null)
		var label: String = String(step.get("label", "module"))
		var origin: Vector3i = step.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(step.get("rotation", 0))
		if module == null:
			_restore_internal_auto_config_snapshot(snapshot)
			_report_auto_configuration_failure("planned %s module was missing before apply" % label)
			return
		if not bipob.can_place_internal_module(module, origin, rotation_index):
			_restore_internal_auto_config_snapshot(snapshot)
			_report_auto_configuration_failure("planned slot for %s became invalid" % label)
			return
		if not bipob.place_internal_module(module, origin, rotation_index):
			_restore_internal_auto_config_snapshot(snapshot)
			_report_auto_configuration_failure("could not apply %s" % label)
			return
	_report_auto_configuration_success()

func _auto_configure_external() -> void:
	_place_external_group_if_missing("gear", ["bottom"])
	_place_external_group_if_missing("sensor", ["top"])
	_place_external_group_if_missing("interface", ["front"])
	_place_external_group_if_missing("manipulator", ["left","right","front","back"])

func _on_constructor_final_audit_pressed() -> void:
	if _safe_has_bipob_method("get_constructor_final_audit_text"):
		_show_constructor_reference_text("FINAL AUDIT", str(bipob.get_constructor_final_audit_text()))
	else:
		_show_constructor_reference_text("FINAL AUDIT", "Final Audit helper is unavailable.")

func _on_constructor_ui_smoke_check_pressed() -> void:
	_show_constructor_reference_text("UI SMOKE CHECK", _get_constructor_ui_smoke_check_text())

func _on_prev_overlay_pressed() -> void:
	bipob.select_prev_overlay_path()
	update_box_status()

func _on_next_overlay_pressed() -> void:
	bipob.select_next_overlay_path()
	update_box_status()

func _on_remove_selected_overlay_pressed() -> void:
	var removed: bool = bipob.remove_selected_overlay_path()
	if not removed:
		show_hint("No overlay path selected.")
	update_box_status()


func _draw_map_constructor_validation_overlay(control: Control) -> void:
	if not map_constructor_state.map_constructor_mode_active or not map_constructor_state.map_constructor_validation_overlay_visible:
		return
	if mission_manager_runtime == null or not mission_manager_runtime.has_method("get_map_constructor_validation_overlay"):
		return
	if field_runtime == null:
		return
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return
	var renderer: RoomVisualRenderer = renderer_node
	var overlay: Dictionary = mission_manager_runtime.call("get_map_constructor_validation_overlay")
	var cells: Dictionary = _safe_ui_dictionary(overlay.get("cells", {}))
	for cell_variant in cells.keys():
		var cell: Vector2i = _safe_ui_vector2i(cell_variant)
		var row: Dictionary = _safe_ui_dictionary(cells[cell_variant])
		var severity: String = String(row.get("severity", "none"))
		if severity == "none":
			continue
		var color: Color = Color(0, 0, 0, 0)
		if severity == "error":
			color = Color(0.95, 0.2, 0.2, 0.35)
		elif severity == "warning":
			color = Color(0.95, 0.7, 0.2, 0.35)
		elif severity == "valid":
			color = Color(0.2, 0.9, 0.4, 0.30)
		else:
			continue
		var world_center: Vector2 = renderer.to_global(renderer.grid_to_iso(cell))
		control.draw_circle(world_center, 10.0, color)
		control.draw_arc(world_center, 11.0, 0.0, TAU, 14, Color(color.r, color.g, color.b, 0.9), 2.0)


func _sync_map_constructor_overlay_visuals() -> void:
	if field_runtime == null:
		return
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return
	var renderer: RoomVisualRenderer = renderer_node
	renderer.set_map_constructor_overlay_preferences(map_constructor_state.map_constructor_overlay_visibility)
	var overlay_data: Dictionary = {
		"selected": {"cell": map_constructor_state.selected_map_constructor_entity_cell, "wall_side": map_constructor_state.selected_map_constructor_wall_side},
		"hover": {"cell": map_constructor_state.pending_map_constructor_cell},
		"preview": {"mode": "destructive" if not map_constructor_state.map_constructor_cleanup_preview.is_empty() else "place", "wall_side": map_constructor_state.selected_map_constructor_wall_side},
		"validation": [],
		"links": _build_map_constructor_overlay_links(),
		"power": _build_map_constructor_overlay_power(),
		"multi_select": map_constructor_state.map_constructor_multi_selected_entities
	}
	if not map_constructor_state.room_visual_preset_preview.is_empty():
		overlay_data["room_visual_preview"] = {
			"walls": _safe_ui_array(map_constructor_state.room_visual_preset_preview.get("affected_walls", [])).duplicate(true),
			"doors": _safe_ui_array(map_constructor_state.room_visual_preset_preview.get("affected_doors", [])).duplicate(true),
			"terminals": _safe_ui_array(map_constructor_state.room_visual_preset_preview.get("affected_terminals", [])).duplicate(true),
			"floors": _safe_ui_array(map_constructor_state.room_visual_preset_preview.get("affected_floors", [])).duplicate(true)
		}
	if mission_manager_runtime != null and mission_manager_runtime.has_method("get_map_constructor_validation_issues"):
		overlay_data["validation"] = _safe_ui_array(mission_manager_runtime.call("get_map_constructor_validation_issues"))
	renderer.set_map_constructor_overlay_data(overlay_data)

func _build_map_constructor_overlay_links() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rows: Array[Dictionary] = _build_map_constructor_placed_object_rows()
	if rows.is_empty():
		return result
	var id_to_cell: Dictionary = {}
	for row in rows:
		var row_id: String = String(row.get("id", "")).strip_edges()
		if row_id.is_empty():
			continue
		id_to_cell[row_id] = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
	for row in rows:
		var source_id: String = String(row.get("id", "")).strip_edges()
		var source_cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
		if source_id.is_empty() or source_cell.x < 0 or source_cell.y < 0:
			continue
		for field_name in ["control_source_id", "linked_terminal_id", "controller_id", "target_door_id", "target_platform_id", "linked_object_id", "target_object_id", "linked_door_id", "required_key_id"]:
			var target_id: String = String(row.get(field_name, "")).strip_edges()
			if target_id.is_empty():
				continue
			var target_cell: Vector2i = _safe_ui_vector2i(id_to_cell.get(target_id, Vector2i(-1, -1)))
			var broken: bool = target_cell.x < 0 or target_cell.y < 0
			var safe_target: Vector2i = target_cell
			if broken:
				safe_target = source_cell
			result.append({
				"from_cell": source_cell,
				"to_cell": safe_target,
				"broken": broken,
				"kind": "link",
				"source_id": source_id,
				"target_id": target_id
			})
	return result

func _build_map_constructor_overlay_power() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rows: Array[Dictionary] = _build_map_constructor_placed_object_rows()
	if rows.is_empty():
		return result
	var network_nodes: Dictionary = {}
	for row in rows:
		var network_id: String = String(row.get("power_network_id", "")).strip_edges()
		if network_id.is_empty():
			continue
		var row_cell: Vector2i = _safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
		if row_cell.x < 0 or row_cell.y < 0:
			continue
		if not network_nodes.has(network_id):
			network_nodes[network_id] = []
		var powered_flag: bool = bool(row.get("is_powered", row.get("powered", false)))
		var requires_power: bool = bool(row.get("requires_power", false))
		var nodes_for_network: Array = network_nodes.get(network_id, [])
		nodes_for_network.append({"id": String(row.get("id", "")), "cell": row_cell, "requires_power": requires_power, "powered": powered_flag})
		network_nodes[network_id] = nodes_for_network
	for network_id_variant in network_nodes.keys():
		var network_id_key: String = String(network_id_variant)
		var nodes: Array = _safe_ui_array(network_nodes[network_id_variant])
		if nodes.size() < 2:
			continue
		var selected_id: String = map_constructor_state.selected_map_constructor_entity_id.strip_edges()
		var selected_cell: Vector2i = Vector2i(-1, -1)
		var selected_is_in_network: bool = false
		for node_variant in nodes:
			var node: Dictionary = _safe_ui_dictionary(node_variant)
			if String(node.get("id", "")) == selected_id:
				selected_is_in_network = true
				selected_cell = _safe_ui_vector2i(node.get("cell", Vector2i(-1, -1)))
				break
		if selected_is_in_network and selected_cell.x >= 0 and selected_cell.y >= 0:
			for node_variant in nodes:
				var node: Dictionary = _safe_ui_dictionary(node_variant)
				var node_id: String = String(node.get("id", ""))
				if node_id == selected_id:
					continue
				var to_cell: Vector2i = _safe_ui_vector2i(node.get("cell", Vector2i(-1, -1)))
				if to_cell.x < 0 or to_cell.y < 0:
					continue
				result.append({"from_cell": selected_cell, "to_cell": to_cell, "network_id": network_id_key, "broken": false})
		else:
			for node_index in range(nodes.size() - 1):
				var from_node: Dictionary = _safe_ui_dictionary(nodes[node_index])
				var to_node: Dictionary = _safe_ui_dictionary(nodes[node_index + 1])
				var from_cell: Vector2i = _safe_ui_vector2i(from_node.get("cell", Vector2i(-1, -1)))
				var to_cell: Vector2i = _safe_ui_vector2i(to_node.get("cell", Vector2i(-1, -1)))
				if from_cell.x < 0 or to_cell.x < 0:
					continue
				result.append({"from_cell": from_cell, "to_cell": to_cell, "network_id": network_id_key, "broken": false})
	return result

func _refresh_map_constructor_browser() -> void:
	_refresh_map_constructor_panels()
	_request_map_constructor_overlay_refresh()

func _request_map_constructor_overlay_refresh() -> void:
	_sync_map_constructor_overlay_visuals()
	MapConstructorRefreshCoordinatorRef.request_field_visual_refresh(self)
