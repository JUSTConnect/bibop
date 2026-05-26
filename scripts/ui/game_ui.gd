extends CanvasLayer
class_name GameUI

const GameUITextHelpersRef = preload("res://scripts/ui/game_ui_text_helpers.gd")


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

var bipob: BipobController = null
var field_runtime: GridManager = null
const FIELD_SCENE_PATH: String = "res://scenes/field/Field.tscn"
const BIPOB_SCENE_PATH: String = "res://scenes/bipob/Bipob.tscn"

@onready var mission_label: Label = $MissionLabel
@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

var diagnostic_label: Label
var runtime_mission_field_host: Control
var runtime_hud_root: Control = null
var runtime_bipob_switcher_panel: PanelContainer = null
var runtime_selected_mission_bipob_index: int = 0
var runtime_mission_bipob_cards: Array[Button] = []

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
var runtime_manipulator_content_label: Label
var runtime_pocket_slots: Array[Button] = []
var runtime_digital_slots: Array[Button] = []
var runtime_pocket_take_buttons: Array[Button] = []
var runtime_digital_load_buttons: Array[Button] = []
var runtime_buffer_content_label: Label
var runtime_pocket_title_label: Label
var runtime_digital_title_label: Label
var runtime_digital_store_title_label: Label
var runtime_energy_label: Label
var runtime_actions_label: Label
var runtime_world_actions_panel: PanelContainer = null
var runtime_world_actions_target_label: Label = null
var runtime_world_actions_state_label: Label = null
var runtime_world_actions_behavior_label: Label = null
var runtime_world_actions_list: VBoxContainer = null
var runtime_world_actions_no_actions_label: Label = null
var runtime_world_actions_selected_button: Button = null
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
var charging_active_tab: String = "supercharger"
var tasks_validation_label: Label
var tasks_start_button: Button
var tasks_claim_button: Button
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

const STORAGE_CARD_MIN_SIZE: Vector2 = Vector2(84, 56)
const MENU_TOP_BUTTON_HEIGHT := 56
const BOX_TOP_BUTTON_HEIGHT := 56.0
const MENU_BACK_BUTTON_SIZE: Vector2 = Vector2(120, 56)
const REPAIR_BIPOB_CARD_SIZE: Vector2 = Vector2(120, 56)
const STORAGE_CARD_ICON_SIZE: Vector2 = Vector2(26, 26)
const SELECTED_MODULE_ICON_SIZE: Vector2 = Vector2(68, 64)
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
	if not bipob.status_changed.is_connected(update_status):
		bipob.status_changed.connect(update_status)
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
		field_runtime.queue_free()
		field_runtime = null
		return false
	_initialize_runtime_profiles_if_needed()
	_connect_bipob_runtime_signals_once()
	_set_gameplay_visible(false)
	return true

func _destroy_gameplay_runtime() -> void:
	if bipob != null and is_instance_valid(bipob):
		bipob.queue_free()
	if field_runtime != null and is_instance_valid(field_runtime):
		field_runtime.queue_free()
	bipob = null
	field_runtime = null

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
	meta_label.text = "UNK\nTBD" if _is_module_unknown(module) else "%s\n%s" % [label_text, _get_module_card_size_text(module)]
	meta_label.add_theme_color_override("font_color", UI_COLOR_TEXT_DIM)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.clip_text = true

	title_box.add_child(name_label)
	title_box.add_child(meta_label)
	top_row.add_child(title_box)
	root.add_child(top_row)

	button.add_child(root)
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
	control.modulate.a = UI_ANIM_PULSE_ALPHA_HIGH
	var tween: Tween = _create_ui_tween(control)
	if tween == null:
		return
	tween.set_loops()
	tween.tween_property(control, "modulate:a", UI_ANIM_PULSE_ALPHA_LOW, UI_ANIM_MEDIUM)
	tween.tween_property(control, "modulate:a", UI_ANIM_PULSE_ALPHA_HIGH, UI_ANIM_MEDIUM)

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
	if status_label != null:
		_apply_label_style(status_label)
	if hint_label != null:
		_apply_label_style(hint_label, true)
	if diagnostic_label != null:
		_apply_label_style(diagnostic_label, true)
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
	if ids.is_empty():
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
		return
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module != null and module.id == module_id:
			selected_box_storage_index = i
			return
	selected_box_storage_index = -1


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
	var icon: Control = _create_module_icon_control(module, SELECTED_MODULE_ICON_SIZE)
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
		root.add_child(_create_external_footprint_preview(module))
	elif bipob.is_internal_module(module):
		root.add_child(_create_internal_volume_preview(module))
	elif bipob.is_internal_overlay_module(module):
		root.add_child(_create_overlay_module_preview(module))
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

	cell.custom_minimum_size = EXTERNAL_SLOT_CELL_SIZE
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

	if selected_module == null and selected_box_storage_index >= 0 and selected_box_storage_index < bipob.box_storage.size():
		selected_module = bipob.box_storage[selected_box_storage_index]

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
			var reserved_for_pocket: bool = bipob.is_external_cell_reserved_for_pocket(side_id, cell) if bipob.has_method("is_external_cell_reserved_for_pocket") else false

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


func _get_external_side_panel_size(side_id: String) -> Vector2:
	match side_id:
		"top":
			return Vector2(180.0, 96.0) if _is_juggernaut_profile() else Vector2(170.0, 95.0)
		"left", "right":
			return Vector2(160.0, 138.0) if _is_juggernaut_profile() else Vector2(150.0, 140.0)
		"front", "bottom", "back":
			return Vector2(155.0, 112.0) if _is_juggernaut_profile() else Vector2(145.0, 125.0)
		_:
			return Vector2(180.0, 150.0)


func _get_external_adaptive_cell_size(side_id: String) -> Vector2:
	if bipob == null:
		return Vector2(18, 18)
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var largest_side: int = maxi(side_size.x, side_size.y)
	var cell: float = 19.0
	if largest_side >= 7:
		cell = 15.0
	elif largest_side >= 5:
		cell = 17.0
	return Vector2(cell, cell)


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
	if context == "internal" or (module != null and module.placement_type.begins_with("internal")):
		return _create_internal_footprint_size_preview(module, context)
	return _create_external_flat_size_preview(module)


func _create_external_flat_size_preview(module: BipobModule) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(84, 64)
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER_DIM, 1, 4))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var footprint_size := Vector2i(maxi(1, module.external_width), maxi(1, module.external_height))
	var preview_columns: int = maxi(4, footprint_size.x)
	var preview_rows: int = maxi(4, footprint_size.y)
	var grid := GridContainer.new()
	grid.columns = preview_columns
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	for y in range(preview_rows):
		for x in range(preview_columns):
			var c := ColorRect.new()
			c.custom_minimum_size = SELECTED_MODULE_PREVIEW_CELL_SIZE
			var is_filled: bool = x < footprint_size.x and y < footprint_size.y
			c.color = Color(0.35, 0.75, 0.95, 0.45) if is_filled else Color(0.2, 0.24, 0.3, 0.35)
			grid.add_child(c)
	root.add_child(grid)
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
	var footprint_size := Vector2i(maxi(1, internal_size.x), maxi(1, internal_size.y))
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
		return panel
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(192, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 4)
	var previews := HBoxContainer.new()
	previews.add_theme_constant_override("separation", 6)
	previews.add_child(_create_module_icon_control(module, SELECTED_MODULE_ICON_SIZE))
	previews.add_child(_create_selected_module_size_preview(module, context))
	left.add_child(previews)
	var name_label := Label.new(); name_label.text = _get_module_title_for_selected_info(module); _apply_label_style(name_label); left.add_child(name_label)
	var type_label := Label.new(); type_label.text = "Type: %s" % _get_module_type_text(module); _apply_label_style(type_label, true, false); left.add_child(type_label)
	var version_label := Label.new(); version_label.text = "Version: V%d" % maxi(1, int(module.module_version)); _apply_label_style(version_label, true, false); left.add_child(version_label)
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
	return 48.0


func _get_runtime_bottom_panel_height() -> float:
	return 150.0


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
	runtime_hud_root.z_index = 50
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
	var selected_data: Dictionary = mission_bipobs[clamped_index]
	var profile_id: String = str(selected_data.get("id", "")).strip_edges()
	if not profile_id.is_empty() and profile_id != active_bipob_profile_id:
		_save_active_bipob_profile()
		_load_bipob_profile(profile_id)
	_refresh_active_mission_bipob_hud()


func _refresh_active_mission_bipob_hud() -> void:
	update_status()
	_update_runtime_bipob_switch_card_styles()


func _on_bipob_switch_card_pressed(index: int) -> void:
	_set_active_mission_bipob(index)


func _update_runtime_bipob_switch_card_styles() -> void:
	for i in range(runtime_mission_bipob_cards.size()):
		var card: Button = runtime_mission_bipob_cards[i]
		if card == null:
			continue
		var is_active: bool = i == runtime_selected_mission_bipob_index
		card.button_pressed = is_active
		card.modulate = Color(1, 1, 1, 1) if is_active else Color(0.78, 0.82, 0.88, 1.0)


func _create_bipob_switcher_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RuntimeBipobSwitcher"
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	margin.add_child(root)
	var title := Label.new()
	title.text = "BIPOB"
	root.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	root.add_child(row)
	runtime_mission_bipob_cards.clear()
	var mission_bipobs: Array[Dictionary] = _get_mission_bipobs()
	for i in range(mission_bipobs.size()):
		var bipob_data: Dictionary = mission_bipobs[i]
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(72, 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _get_mission_bipob_display_name(bipob_data, i)
		button.pressed.connect(_on_bipob_switch_card_pressed.bind(i))
		runtime_mission_bipob_cards.append(button)
		row.add_child(button)
	_update_runtime_bipob_switch_card_styles()
	return panel


func _apply_runtime_hud_layout() -> void:
	var root: Control = _ensure_runtime_hud_root()
	root.visible = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		child.queue_free()

	if status_label != null:
		status_label.visible = false
	if hint_label != null:
		hint_label.visible = false
	if diagnostic_label != null:
		diagnostic_label.visible = false

	var margin: float = _get_runtime_margin()
	var top_panel_height: float = _get_runtime_top_panel_height()
	var bottom_area_height: float = _get_runtime_bottom_panel_height()
	var sidebar_width: float = _get_runtime_sidebar_width_adaptive()
	var viewport: Vector2 = _get_viewport_size()
	var stats_height: float = 34.0
	var bottom_y: float = viewport.y - bottom_area_height - margin

	var objective_panel := PanelContainer.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.position = Vector2(margin, margin)
	objective_panel.size = Vector2(maxf(viewport.x - sidebar_width - margin * 3.0, 200.0), top_panel_height)
	objective_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL_DARK, UI_COLOR_BORDER, 1, 8))
	root.add_child(objective_panel)
	var objective_margin := MarginContainer.new()
	objective_margin.add_theme_constant_override("margin_left", 10)
	objective_margin.add_theme_constant_override("margin_right", 10)
	objective_margin.add_theme_constant_override("margin_top", 6)
	objective_margin.add_theme_constant_override("margin_bottom", 6)
	objective_panel.add_child(objective_margin)
	mission_goal_value_label = Label.new()
	mission_goal_value_label.name = "RuntimeObjectiveLabel"
	mission_goal_value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	mission_goal_value_label.clip_text = true
	mission_goal_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission_goal_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_goal_value_label.text = "Mission 1: pick up the key, open the door, reach the exit."
	objective_margin.add_child(mission_goal_value_label)

	var right_x: float = viewport.x - sidebar_width - margin
	var switcher_height: float = 0.0
	if _has_multiple_mission_bipobs():
		runtime_bipob_switcher_panel = _create_bipob_switcher_panel()
		runtime_bipob_switcher_panel.position = Vector2(right_x, margin)
		runtime_bipob_switcher_panel.size = Vector2(sidebar_width, 76)
		switcher_height = runtime_bipob_switcher_panel.size.y + 6.0
		root.add_child(runtime_bipob_switcher_panel)
	else:
		runtime_bipob_switcher_panel = null

	runtime_storage_panel = _create_runtime_storage_panel()
	runtime_storage_panel.position = Vector2(right_x, margin + switcher_height)
	runtime_storage_panel.size = Vector2(sidebar_width, top_panel_height)
	root.add_child(runtime_storage_panel)

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
	bottom_left_vbox.size = Vector2(maxf(viewport.x - sidebar_width - margin * 3.0, 200.0), bottom_area_height)
	bottom_left_vbox.add_theme_constant_override("separation", 4)
	root.add_child(bottom_left_vbox)

	var stats_strip := _create_runtime_stats_strip()
	bottom_left_vbox.add_child(stats_strip)

	var controls_panel := _create_runtime_controls_panel()
	controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_panel.custom_minimum_size = Vector2(0, maxf(bottom_area_height - stats_height - 4.0, 88.0))
	controls_panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	bottom_left_vbox.add_child(controls_panel)

	var mission_panel: PanelContainer = _create_runtime_mission_panel()
	mission_panel.position = Vector2(right_x, bottom_y)
	mission_panel.size = Vector2(sidebar_width, bottom_area_height)
	root.add_child(mission_panel)
	var world_actions_panel: PanelContainer = _create_runtime_world_actions_panel()
	var wa_top: float = margin + switcher_height + top_panel_height + 8.0
	var mission_reserved: float = bottom_area_height + 8.0
	var available_wa_height: float = maxf((viewport.y - margin) - wa_top - mission_reserved, 92.0)
	world_actions_panel.position = Vector2(right_x, wa_top)
	world_actions_panel.size = Vector2(sidebar_width, available_wa_height)
	root.add_child(world_actions_panel)
	runtime_world_actions_panel = world_actions_panel


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
	var panel := PanelContainer.new()
	panel.name = "RuntimeControlsPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 110)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	margin.add_child(grid)

	var ordered_buttons: Array[Control] = []

	if move_forward_button != null:
		move_forward_button.text = "Forward [W]"
		ordered_buttons.append(move_forward_button)

	if turn_left_button != null:
		turn_left_button.text = "Turn Left [A]"
		ordered_buttons.append(turn_left_button)

	if interact_button != null:
		interact_button.text = "Action [E]"
		ordered_buttons.append(interact_button)

	if turn_right_button != null:
		turn_right_button.text = "Turn Right [D]"
		ordered_buttons.append(turn_right_button)

	if move_backward_button != null:
		move_backward_button.text = "Backward [S]"
		ordered_buttons.append(move_backward_button)

	if scan_device_button != null:
		scan_device_button.text = "Scan Device"
		ordered_buttons.append(scan_device_button)

	if hack_device_button != null:
		hack_device_button.text = "Hack Device"
		ordered_buttons.append(hack_device_button)

	if end_turn_button != null:
		end_turn_button.text = "End Turn [Space]"
		ordered_buttons.append(end_turn_button)

	for button in ordered_buttons:
		if button == null:
			continue
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_safe_reparent_control(button, grid)

	return panel


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
	var panel := PanelContainer.new()
	panel.name = "StoragePanel"
	panel.add_theme_stylebox_override("panel", _make_panel_style(UI_COLOR_PANEL, UI_COLOR_BORDER, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	margin.add_child(root)
	var things_title := Label.new()
	things_title.text = "THINGS"
	root.add_child(things_title)
	runtime_pocket_slots.clear()
	runtime_digital_slots.clear()
	runtime_pocket_take_buttons.clear()
	runtime_digital_load_buttons.clear()
	runtime_key_slots.clear()
	root.add_child(_create_runtime_storage_dual_action_header("MANIPULATOR", "DROP", Callable(self, "_on_storage_store_pressed"), "POCKET", Callable(self, "_on_storage_take_pressed")))
	runtime_manipulator_content_label = Label.new()
	runtime_manipulator_content_label.text = "Empty"
	root.add_child(runtime_manipulator_content_label)
	runtime_pocket_title_label = Label.new()
	runtime_pocket_title_label.text = "POCKET 1/4"
	root.add_child(runtime_pocket_title_label)
	var pocket_row := HBoxContainer.new()
	pocket_row.add_theme_constant_override("separation", 4)
	root.add_child(pocket_row)
	for i in range(4):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var b := _create_storage_slot("Empty", i == 0, Vector2(46, 26))
		b.pressed.connect(func() -> void: selected_pocket_slot = i; _refresh_runtime_storage_panel())
		col.add_child(b)
		runtime_pocket_slots.append(b)
		var take_button := _create_runtime_slot_action_button("TAKE", Callable(self, "_on_storage_take_slot_pressed").bind(i))
		col.add_child(take_button)
		runtime_pocket_take_buttons.append(take_button)
		pocket_row.add_child(col)
	var keys_row := HBoxContainer.new()
	keys_row.add_theme_constant_override("separation", 4)
	root.add_child(keys_row)
	for i in range(6):
		var key_slot := _create_storage_key_slot(true)
		keys_row.add_child(key_slot)
		runtime_key_slots.append(key_slot)
	runtime_digital_title_label = Label.new()
	runtime_digital_title_label.text = "BUFFER"
	root.add_child(_create_runtime_storage_section_header("", "STORE", Callable(self, "_on_storage_data_store_pressed"), runtime_digital_title_label))
	runtime_buffer_content_label = Label.new()
	runtime_buffer_content_label.text = "Empty"
	root.add_child(runtime_buffer_content_label)
	runtime_digital_store_title_label = Label.new()
	runtime_digital_store_title_label.text = "STORE 1/4"
	root.add_child(runtime_digital_store_title_label)
	var digital_row := HBoxContainer.new()
	digital_row.add_theme_constant_override("separation", 4)
	root.add_child(digital_row)
	for i in range(4):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var b := _create_storage_slot("Empty", i == 0, Vector2(46, 26))
		b.pressed.connect(func() -> void: selected_digital_slot = i; _refresh_runtime_storage_panel())
		col.add_child(b)
		runtime_digital_slots.append(b)
		var load_button := _create_runtime_slot_action_button("LOAD", Callable(self, "_on_storage_load_slot_pressed").bind(i))
		col.add_child(load_button)
		runtime_digital_load_buttons.append(load_button)
		digital_row.add_child(col)
	_refresh_runtime_storage_panel()
	return panel

func _create_runtime_storage_dual_action_header(title: String, first_action_text: String, first_action_callable: Callable, second_action_text: String, second_action_callable: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = title
	row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var first_button := Button.new()
	first_button.text = first_action_text
	first_button.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(first_button, "normal", first_action_callable.is_valid())
	first_button.disabled = not first_action_callable.is_valid()
	if first_action_callable.is_valid():
		first_button.pressed.connect(first_action_callable)
	row.add_child(first_button)
	var second_button := Button.new()
	second_button.text = second_action_text
	second_button.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(second_button, "normal", second_action_callable.is_valid())
	second_button.disabled = not second_action_callable.is_valid()
	if second_action_callable.is_valid():
		second_button.pressed.connect(second_action_callable)
	row.add_child(second_button)
	return row

func _create_runtime_slot_action_button(text: String, action_callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(46, 22)
	button.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(button, "normal", action_callable.is_valid())
	button.disabled = not action_callable.is_valid()
	if action_callable.is_valid():
		button.pressed.connect(action_callable)
	return button

func _create_runtime_storage_section_header(title: String, action_text: String, action_callable: Callable, title_label: Label = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := title_label if title_label != null else Label.new()
	if title_label == null:
		label.text = title
	row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var button := Button.new()
	button.text = action_text
	button.focus_mode = Control.FOCUS_NONE
	_apply_action_button_style(button, "normal", action_callable.is_valid())
	button.disabled = not action_callable.is_valid()
	if action_callable.is_valid():
		button.pressed.connect(action_callable)
	row.add_child(button)
	return row

func _create_storage_slot(text: String, enabled: bool, min_size: Vector2 = Vector2(54, 34)) -> Button:
	var slot := Button.new()
	slot.text = text
	slot.focus_mode = Control.FOCUS_NONE
	slot.custom_minimum_size = min_size
	slot.disabled = not enabled
	slot.modulate = Color.WHITE if enabled else UI_COLOR_DISABLED
	return slot

func _create_storage_key_slot(enabled: bool) -> Control:
	var key_slot := PanelContainer.new()
	key_slot.custom_minimum_size = Vector2(24, 24)
	key_slot.add_theme_stylebox_override("panel", _make_panel_style(Color(0.090, 0.110, 0.145, 1.0), UI_COLOR_BORDER_DIM, 1, 4))
	key_slot.modulate = Color.WHITE if enabled else UI_COLOR_DISABLED
	return key_slot

func _ready() -> void:
	if hint_label != null:
		hint_label.text = "Mission 1: pick up the key, open the door, reach the exit."

	diagnostic_label = Label.new()
	diagnostic_label.name = "DiagnosticLabel"
	diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_label.custom_minimum_size = Vector2(700, 140)
	diagnostic_label.text = "Diagnostic: none"
	add_child(diagnostic_label)

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
	if move_backward_button != null:
		move_backward_button.focus_mode = Control.FOCUS_NONE
	if turn_left_button != null:
		turn_left_button.focus_mode = Control.FOCUS_NONE
	if turn_right_button != null:
		turn_right_button.focus_mode = Control.FOCUS_NONE
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
	if status_label != null:
		status_label.visible = false
		status_label.text = ""
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
	if status_label != null:
		status_label.visible = false
	if hint_label != null:
		hint_label.visible = false
	if diagnostic_label != null:
		diagnostic_label.visible = false
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
	var roots := {"main": main_menu_root, "center": center_menu_root, "tasks": tasks_menu_root, "box": box_menu_root, "charging": charging_menu_root, "repair": repair_menu_root, "hud": runtime_hud_root}
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
		AppScreenMode.GAMEPLAY:
			start_gameplay_from_center()
		AppScreenMode.MISSION_RESULT:
			show_mission_result_screen(bool(payload.get("success", false)), int(payload.get("mission_index", -1)))
		AppScreenMode.RESEARCH_PLACEHOLDER:
			show_placeholder_screen("Исследования")
		AppScreenMode.SHOP_PLACEHOLDER:
			show_placeholder_screen("Магазин")
		AppScreenMode.SETTINGS_PLACEHOLDER:
			show_placeholder_screen("Настройки")
		AppScreenMode.ABOUT_PLACEHOLDER:
			show_placeholder_screen("О нас")
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
	show_hint("Бипоб заряжен.")
	update_status()

func _on_charge_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.charge_to_full()
	start_mission_warning_acknowledged = false
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_install_module_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	_on_install_selected_box_module_pressed()

func clamp_box_selection_indexes() -> void:
	if bipob == null:
		selected_installed_module_index = 0
		selected_box_storage_index = 0
		return

	if bipob.installed_modules.is_empty():
		selected_installed_module_index = 0
	else:
		selected_installed_module_index = clampi(selected_installed_module_index, 0, bipob.installed_modules.size() - 1)

	if bipob.box_storage.is_empty():
		selected_box_storage_index = 0
	else:
		selected_box_storage_index = clampi(selected_box_storage_index, 0, bipob.box_storage.size() - 1)
	var filtered_indices: Array[int] = get_current_filtered_box_storage_indices()
	if filtered_indices.is_empty():
		selected_filtered_box_index = 0
	else:
		if selected_box_storage_index in filtered_indices:
			selected_filtered_box_index = filtered_indices.find(selected_box_storage_index)
		else:
			selected_filtered_box_index = clampi(selected_filtered_box_index, 0, filtered_indices.size() - 1)
			selected_box_storage_index = filtered_indices[selected_filtered_box_index]

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
	selected_grouped_module_index = posmod(selected_grouped_module_index - 1, grouped_ids.size())
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
	selected_grouped_module_index = posmod(selected_grouped_module_index + 1, grouped_ids.size())
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
		"visor_v1", "visor_v2":
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
	show_mission_result_screen(true)

func _on_mission_failed() -> void:
	should_advance_mission_on_start = false
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
		var warning_limit := mini(2, warnings.size())
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
	box_menu_mode = BoxMenuMode.EXTERNAL
	selected_grouped_module_index = 0
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_external_selection()
	update_box_status()
	rebuild_box_action_buttons()


func set_box_menu_mode_internal() -> void:
	box_menu_mode = BoxMenuMode.INTERNAL
	if get_current_constructor_filter() in ["gear", "visor_radar", "tool", "manipulator", "armor", "weapon"]:
		internal_filter_index = CONSTRUCTOR_FILTERS.find("all")
	selected_grouped_module_index = 0
	sync_selected_box_storage_index_from_grouped_selection()
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
	if hint_label != null:
		hint_label.text = message


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

	vbox.add_child(_create_menu_button("Играть", Callable(self, "_on_main_play_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("Настройки", Callable(self, "_on_main_settings_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("О нас", Callable(self, "_on_main_about_pressed"), Vector2(180, 36)))
	vbox.add_child(_create_menu_button("Выйти из игры", Callable(self, "_on_exit_game_pressed"), Vector2(180, 36), "danger"))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer)

	var social := Label.new()
	social.text = "Соцсети"
	_apply_label_style(social, true, false)
	social.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(social)

	var version := Label.new()
	version.text = "версия"
	_apply_label_style(version, true, false)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)

func _build_center_menu_layout() -> void:
	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_panel_style(background, true)
	center_menu_root.add_child(background)

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
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var top_row := HFlowContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top_row)
	top_row.add_child(_create_menu_button("TSK", Callable(self, "_on_center_tasks_pressed"), Vector2(170, 36)))
	top_row.add_child(_create_menu_button("Constructor", Callable(self, "_on_center_constructor_pressed"), Vector2(170, 36)))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var top_right := VBoxContainer.new()
	top_right.add_theme_constant_override("separation", 8)
	top_right.add_child(_create_menu_button("Выйти в главное меню", Callable(self, "_on_center_main_menu_pressed"), Vector2(220, 36)))
	top_right.add_child(_create_menu_button("Настройки", Callable(self, "_on_center_settings_pressed"), Vector2(190, 36)))
	top_row.add_child(top_right)

	var middle_row := HBoxContainer.new()
	middle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(middle_row)
	var middle_spacer := Control.new()
	middle_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_row.add_child(middle_spacer)
	middle_row.add_child(_create_menu_button("Магазин", Callable(self, "_on_center_shop_pressed"), Vector2(170, 56)))

	var bottom_grid := GridContainer.new()
	bottom_grid.columns = 4
	bottom_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_grid.add_theme_constant_override("h_separation", 10)
	bottom_grid.add_theme_constant_override("v_separation", 10)
	root.add_child(bottom_grid)
	bottom_grid.add_child(_create_menu_button("Box", Callable(self, "_on_center_box_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(_create_menu_button("Shop", Callable(self, "_on_center_shop_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(_create_menu_button("Зарядка", Callable(self, "_on_center_charge_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(_create_menu_button("Исследования", Callable(self, "_on_center_research_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(_create_menu_button("Ремонт", Callable(self, "_on_center_repair_pressed"), Vector2(150, 54)))

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
	show_placeholder_screen("Настройки")
func _on_main_about_pressed() -> void:
	show_placeholder_screen("О нас")
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
func _on_center_shop_pressed() -> void:
	navigate_to_screen(AppScreenMode.SHOP_PLACEHOLDER)
func _on_center_settings_pressed() -> void:
	navigate_to_screen(AppScreenMode.SETTINGS_PLACEHOLDER)
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
	if bipob == null or not bipob.has_method("start_dev_task_test_mission"):
		_set_dev_validation_output("Developer mission start unavailable: BipobController is not ready.")
		return
	bipob.call("start_dev_task_test_mission")
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
	start_gameplay_from_center()

func _on_mission_result_center_pressed() -> void:
	if not _can_return_to_center_after_result(last_mission_success):
		show_hint("Beacon Module required")
		return
	show_center_screen()

func _on_mission_result_main_menu_pressed() -> void:
	show_main_menu_screen()

func _on_move_forward_pressed() -> void:
	bipob.move_forward()
	update_status()

func _on_move_backward_pressed() -> void:
	bipob.move_backward()
	update_status()

func _on_turn_left_pressed() -> void:
	bipob.turn_left()
	update_status()

func _on_turn_right_pressed() -> void:
	bipob.turn_right()
	update_status()

func _on_interact_pressed() -> void:
	bipob.interact()
	update_status()

func _on_use_selected_world_action_pressed() -> void:
	if bipob == null:
		return
	bipob.interact()
	update_status()

func _on_world_action_button_pressed(action_id: String) -> void:
	if bipob == null:
		return
	bipob.set_selected_world_action(action_id)

func _on_world_action_panel_requested(target_object: Dictionary, actions: Array, selected_action: String) -> void:
	if runtime_world_actions_panel == null:
		return
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		runtime_world_actions_panel.visible = false
		return
	if target_object.is_empty():
		runtime_world_actions_panel.visible = false
		return
	runtime_world_actions_panel.visible = true
	var scan_level := int(target_object.get("scan_level", 0))
	var object_group := String(target_object.get("object_group", "object"))
	var generic := object_group.capitalize()
	if object_group == "threat" and scan_level <= 0:
		generic = "Unknown movement"
	var object_name := generic if scan_level <= 0 else String(target_object.get("display_name", generic))
	runtime_world_actions_target_label.text = object_name
	runtime_world_actions_state_label.text = "State: %s" % String(target_object.get("state", "unknown"))
	if object_group == "threat":
		runtime_world_actions_behavior_label.visible = true
		runtime_world_actions_behavior_label.text = "Behavior: %s" % String(target_object.get("behavior_state", "idle"))
	else:
		runtime_world_actions_behavior_label.visible = false
	var action_ids: Array[String] = []
	for action_variant in actions:
		var action_id: String = String(action_variant)
		if action_id.is_empty():
			continue
		action_ids.append(action_id)
	var target_id: String = String(target_object.get("id", target_object.get("position", object_name)))
	var actions_key := "|".join(action_ids)
	var state_key := "%s|%s|%s" % [String(target_object.get("state", "")), String(target_object.get("behavior_state", "")), String(target_object.get("scan_level", 0))]
	var only_selection_change: bool = target_id == last_world_action_target_id and actions_key == last_world_action_actions_key and state_key == last_world_action_state_key
	if only_selection_change and runtime_world_actions_list.get_child_count() > 0:
		for child_node in runtime_world_actions_list.get_children():
			if child_node is Button:
				var btn: Button = child_node
				btn.button_pressed = String(btn.get_meta("action_id", "")) == selected_action
		last_world_action_selected = selected_action
		return
	for child in runtime_world_actions_list.get_children():
		child.queue_free()
	runtime_world_actions_selected_button = null
	if action_ids.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No available actions"
		runtime_world_actions_list.add_child(empty_label)
		return
	var added: Dictionary = {}
	for action_id in action_ids:
		if added.has(action_id):
			continue
		added[action_id] = true
		var action_button := Button.new()
		action_button.text = bipob.get_world_action_display_label(action_id, target_object)
		action_button.toggle_mode = true
		action_button.button_pressed = action_id == selected_action
		action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_button.set_meta("action_id", action_id)
		action_button.pressed.connect(_on_world_action_button_pressed.bind(action_id))
		runtime_world_actions_list.add_child(action_button)
		if action_button.button_pressed:
			runtime_world_actions_selected_button = action_button
	last_world_action_target_id = target_id
	last_world_action_actions_key = actions_key
	last_world_action_selected = selected_action
	last_world_action_state_key = state_key

func _on_drop_item_button_pressed() -> void:
	bipob.drop_held_item()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_rotate_storage_button_pressed() -> void:
	bipob.rotate_physical_storage()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _refresh_runtime_storage_panel() -> void:
	if bipob == null or runtime_storage_panel == null:
		return
	var man_items: Array = bipob.get_manipulator_items()
	var manipulator_item = man_items[0] if not man_items.is_empty() else null
	if runtime_manipulator_content_label != null:
		runtime_manipulator_content_label.text = bipob.get_module_display_name(manipulator_item) if manipulator_item != null else "Empty"
	var available_pocket: int = int(bipob.get_available_pocket_slots())
	runtime_pocket_title_label.text = "POCKET %d/%d" % [available_pocket, bipob.get_max_pocket_slots()]
	var pocket_items: Array = bipob.get_pocket_items()
	for i in range(runtime_pocket_slots.size()):
		var slot := runtime_pocket_slots[i]
		var enabled: bool = i < available_pocket
		slot.disabled = not enabled
		slot.modulate = Color.WHITE if enabled else UI_COLOR_DISABLED
		var item = pocket_items[i] if i < pocket_items.size() else null
		slot.text = bipob.get_module_display_name(item) if item != null else "Empty"
		if i < runtime_pocket_take_buttons.size():
			var take_button := runtime_pocket_take_buttons[i]
			take_button.disabled = not enabled
			take_button.visible = enabled
	var digital_available: int = 1
	runtime_digital_store_title_label.text = "STORE %d/%d" % [digital_available, runtime_digital_slots.size()]
	for i in range(runtime_digital_slots.size()):
		var dslot := runtime_digital_slots[i]
		var denabled: bool = i < digital_available
		dslot.disabled = not denabled
		dslot.modulate = Color.WHITE if denabled else UI_COLOR_DISABLED
		dslot.text = "Empty"
		if i < runtime_digital_load_buttons.size():
			var load_button := runtime_digital_load_buttons[i]
			load_button.disabled = not denabled
			load_button.visible = denabled
	if runtime_buffer_content_label != null:
		runtime_buffer_content_label.text = "Empty"

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
	show_hint("No digital data selected.")

func _on_storage_load_slot_pressed(slot_index: int) -> void:
	selected_digital_slot = slot_index
	_on_storage_load_pressed()

func _on_storage_data_store_pressed() -> void:
	show_hint("Buffer is empty.")

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
	bipob.end_turn()
	update_status()

func _on_restart_mission_button_pressed() -> void:
	if bipob == null:
		return

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
	if runtime_actions_label != null:
		runtime_actions_label.text = _get_runtime_actions_text()

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

	if status_label == null:
		return

	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s | Hand: %s | Storage: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text,
		held_text,
		storage_text
	]
	status_label.text += " | Carry: %d / %d" % [
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
	status_label.text += " | Data: %s" % digital_storage_short_text
	if bipob.has_method("get_mission8_airflow_status_text"):
		var mission8_status := str(bipob.get_mission8_airflow_status_text())
		if not mission8_status.is_empty():
			status_label.text += " | %s" % mission8_status
	if bipob.current_mission_index == 7 and bipob.has_method("get_mission7_cable_status_text"):
		status_label.text += " | %s" % str(bipob.get_mission7_cable_status_text())
	_refresh_runtime_storage_panel()
	if bipob.has_method("refresh_world_action_panel"):
		bipob.refresh_world_action_panel()


func update_diagnostic_status() -> void:
	if bipob == null:
		return

	if diagnostic_label == null:
		return

	var result = bipob.last_diagnostic_result
	if result == null:
		diagnostic_label.text = "Diagnostic: none"
		return

	var device_name: String = str(result.device_name)

	if device_name.is_empty():
		device_name = "unknown"

	var status_text: String = str(result.get_status_text())

	if status_text.is_empty():
		status_text = "UNKNOWN"

	var supported_action: String = str(result.supported_action)
	if supported_action.is_empty():
		supported_action = "none"

	var reason: String = str(result.reason)
	if reason.is_empty():
		reason = "n/a"

	var recommendation: String = str(result.recommendation)
	if recommendation.is_empty():
		recommendation = "n/a"

	var estimated_risk: String = str(result.estimated_risk)
	if estimated_risk.is_empty():
		estimated_risk = "n/a"

	diagnostic_label.text = "Diagnostic:\nDevice: %s\nStatus: %s\nAction: %s\nReason: %s\nRecommendation: %s\nRisk: %s" % [
		device_name,
		status_text,
		supported_action,
		reason,
		recommendation,
		estimated_risk
	]


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
		if selected_box_storage_index < 0:
			return null
		if selected_box_storage_index >= bipob.box_storage.size():
			return null
		module = bipob.box_storage[selected_box_storage_index]
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
	clamp_box_selection_indexes()
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, maxi(get_filtered_grouped_module_ids().size() - 1, 0))
	sync_selected_box_storage_index_from_grouped_selection()
	update_box_status()

func _on_next_constructor_filter_pressed() -> void:
	var filter_index: int = _get_active_filter_index() + 1
	if filter_index >= CONSTRUCTOR_FILTERS.size():
		filter_index = 0
	_set_active_filter_index(filter_index)
	clamp_box_selection_indexes()
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, maxi(get_filtered_grouped_module_ids().size() - 1, 0))
	sync_selected_box_storage_index_from_grouped_selection()
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
	return module != null and not bipob.is_module_broken(module) and not bipob.is_module_unknown(module)

func _is_internal_interface_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if not bipob.is_internal_module(module):
		return false
	var id: String = String(module.id).to_lower()
	var module_name: String = String(module.get_display_name()).to_lower()
	var family: String = String(module.internal_family).to_lower()
	return id.contains("internal_interface") or module_name.contains("internal interface") or family in ["internal_interface", "internal interface"]

func _is_external_interface_module(module: BipobModule) -> bool:
	if module == null:
		return false
	if not bipob.is_internal_module(module):
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
	if not bipob.is_internal_module(module):
		return false
	var id: String = String(module.id).to_lower()
	var module_name: String = String(module.get_display_name()).to_lower()
	var family: String = String(module.internal_family).to_lower()
	return id.contains("power_block") or module_name.contains("power block") or family in ["power_block", "power block", "power"]

func _has_installed_internal_group(group_id: String) -> bool:
	for module in _get_internal_installed_modules():
		if module == null:
			continue
		match group_id:
			"power_block":
				if _is_power_block_module(module):
					return true
			"internal_interface":
				if _is_internal_interface_module(module):
					return true
			"external_interface":
				if _is_external_interface_module(module):
					return true
			_:
				if _normalize_text(String(module.internal_family)) == group_id:
					return true
	return false

func _find_available_internal_module_by_group(group_id: String) -> BipobModule:
	for module in bipob.box_storage:
		if not _is_ready_module(module) or not bipob.is_internal_module(module):
			continue
		match group_id:
			"power_block":
				if _is_power_block_module(module):
					return module
			"internal_interface":
				if _is_internal_interface_module(module):
					return module
			"external_interface":
				if _is_external_interface_module(module):
					return module
			_:
				var family: String = _normalize_text(String(module.internal_family))
				var display_name: String = _normalize_text(module.get_display_name())
				if group_id == "storage" and (family == "storage" or display_name.contains("hard drive")):
					return module
				if group_id == "processor" and family in ["cpu","processor"]:
					return module
				if group_id == "memory" and family in ["ram","memory"]:
					return module
				if group_id == "gpu" and family == "gpu":
					return module
				if group_id == "cooler" and (family == "cooler" or display_name.contains("cooler")):
					return module
				if group_id == "radiator" and (family == "radiator" or display_name.contains("radiator")):
					return module
				if group_id == "charger" and (family == "charger" or display_name.contains("charger") or module.id == "charger_v1"):
					return module
				if group_id == "battery" and (family == "battery" or String(module.id).begins_with("battery_")):
					return module
	return null

func _try_place_internal_module_for_group(group_id: String, warn_name: String = "") -> bool:
	var module: BipobModule = _find_available_internal_module_by_group(group_id)
	if module == null:
		return false
	var size: Vector3i = _get_internal_preview_volume_size()
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var pos := Vector3i(x, y, z)
				if bipob.place_internal_module(module, pos, 0) or bipob.place_internal_module(module, pos, 1):
					return true
	if not warn_name.is_empty():
		show_hint("Auto Configure: no valid space for %s" % warn_name)
	return false

func _on_auto_configure_pressed() -> void:
	if _is_constructor_internal_mode():
		_auto_configure_internal()
	else:
		_auto_configure_external()
	update_box_status()

func _auto_configure_internal() -> void:
	var target_groups: Array[Dictionary] = [
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
	for target in target_groups:
		var group_id: String = String(target.get("id", ""))
		var target_count: int = int(target.get("count", 1))
		var label: String = String(target.get("label", group_id))
		while true:
			if group_id == "battery":
				if _count_internal_family("battery") >= target_count:
					break
			elif _has_installed_internal_group(group_id):
				break
			if not _try_place_internal_module_for_group(group_id, label):
				break

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
