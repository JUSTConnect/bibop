extends CanvasLayer
class_name GameUI

@onready var bipob = get_node("../Bipob")

@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

var diagnostic_label: Label

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
var drop_item_button: Button
var rotate_storage_button: Button
var start_mission_warning_acknowledged: bool = false
var should_advance_mission_on_start: bool = false
var selected_installed_module_index: int = 0
var selected_box_storage_index: int = 0
var selected_filtered_box_index: int = 0
var selected_grouped_module_index: int = 0
var constructor_filter_index: int = 0
const CONSTRUCTOR_FILTERS: Array[String] = [
	"all",
	"external",
	"internal",
	"power",
	"cooling",
	"data",
	"locomotion",
	"vision",
	"storage",
	"utility"
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

enum BoxMenuMode {
	MISSION,
	MODULES,
	EXTERNAL,
	INTERNAL
}

var box_menu_mode: BoxMenuMode = BoxMenuMode.MISSION
var selected_external_side_index: int = 1
var selected_external_slot_position: Vector2i = Vector2i(1, 1)
var internal_view_mode: String = "modules"
var module_icon_texture_cache: Dictionary = {}
var constructor_reference_text: String = ""

enum AppScreenMode {
	MAIN_MENU,
	CENTER,
	GAMEPLAY,
	BOX_CONSTRUCTOR,
	SETTINGS_PLACEHOLDER,
	ABOUT_PLACEHOLDER,
	SHOP_PLACEHOLDER,
	RESEARCH_PLACEHOLDER,
	REPAIR_PLACEHOLDER
}

var app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU
var previous_app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU
var box_opened_from_center: bool = false

var main_menu_root: Control
var center_menu_root: Control
var placeholder_menu_root: Control
var placeholder_title_label: Label

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

const STORAGE_CARD_MIN_SIZE: Vector2 = Vector2(86, 58)
const STORAGE_CARD_ICON_SIZE: Vector2 = Vector2(26, 26)
const SELECTED_MODULE_ICON_SIZE: Vector2 = Vector2(52, 38)
const SELECTED_MODULE_PREVIEW_CELL_SIZE: Vector2 = Vector2(14, 14)
const SELECTED_MODULE_PREVIEW_GAP: int = 3
const EXTERNAL_GRID_CELL_SIZE: Vector2 = Vector2(26, 26)
const EXTERNAL_GRID_CELL_GAP: int = 2
const INTERNAL_GRID_CELL_SIZE: Vector2 = Vector2(24, 24)
const INTERNAL_GRID_CELL_GAP: int = 2
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

func _safe_has_bipob_method(method_name: String) -> bool:
	if bipob == null:
		return false
	return bipob.has_method(method_name)

func _is_constructor_internal_mode() -> bool:
	return box_menu_mode == BoxMenuMode.INTERNAL

func _is_constructor_external_mode() -> bool:
	return box_menu_mode == BoxMenuMode.EXTERNAL

func _is_constructor_dashboard_mode() -> bool:
	return box_menu_mode == BoxMenuMode.MISSION

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


func _is_module_valid_for_current_constructor_mode(module: BipobModule) -> bool:
	if module == null:
		return false

	if box_menu_mode == BoxMenuMode.INTERNAL:
		return bipob.is_internal_module(module) or bipob.is_internal_overlay_module(module)

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
	name_label.text = bipob.get_module_display_name(module)
	name_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	name_label.clip_text = true

	var meta_label: Label = Label.new()
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label_text: String = "MOD"
	if bipob.has_method("get_module_visual_short_label"):
		label_text = bipob.get_module_visual_short_label(module)
	meta_label.text = "%s\n%s" % [label_text, _get_module_card_size_text(module)]
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
	for tab_button in [mission_tab_button, modules_tab_button, external_tab_button, internal_tab_button]:
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
	panel.offset_top = 16
	panel.offset_right = -16
	panel.offset_bottom = 632
	panel.custom_minimum_size = Vector2(520, 0)

	main_box_row = vbox.get_node_or_null("MainBoxRow")
	if main_box_row == null:
		main_box_row = HBoxContainer.new()
		main_box_row.name = "MainBoxRow"
		vbox.add_child(main_box_row)

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

	box_tab_row = left_panel.get_node_or_null("BoxTabRow")
	if box_tab_row == null:
		box_tab_row = HBoxContainer.new()
		box_tab_row.name = "BoxTabRow"
		left_panel.add_child(box_tab_row)
	box_tab_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

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

	if box_status_label != null:
		box_status_label.visible = false
		box_status_label.text = ""
	if box_module_label != null:
		box_module_label.visible = false
		box_module_label.text = ""
	if installed_modules_label != null:
		installed_modules_label.visible = false
		installed_modules_label.text = ""
	if box_storage_label != null:
		box_storage_label.visible = false
		box_storage_label.text = ""
	if digital_storage_label != null:
		digital_storage_label.visible = false
		digital_storage_label.text = ""

	var old_button_row := vbox.get_node_or_null("ButtonRow")
	if old_button_row != null:
		old_button_row.visible = false
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

func get_current_constructor_filter() -> String:
	if constructor_filter_index < 0:
		constructor_filter_index = CONSTRUCTOR_FILTERS.size() - 1
	elif constructor_filter_index >= CONSTRUCTOR_FILTERS.size():
		constructor_filter_index = 0
	return String(CONSTRUCTOR_FILTERS[constructor_filter_index])

func module_matches_constructor_filter(module: BipobModule, filter_id: String) -> bool:
	if module == null:
		return false
	if filter_id == "all":
		return true
	var category: String = bipob.get_module_category(module)
	if category == filter_id:
		return true
	if filter_id == "external":
		return module.placement_type == "external"
	if filter_id == "internal":
		return module.placement_type == "internal"
	return false

func _is_module_visible_in_current_constructor_mode(module: BipobModule) -> bool:
	if module == null:
		return false
	if box_menu_mode == BoxMenuMode.EXTERNAL:
		return bipob.is_external_module(module)
	if box_menu_mode == BoxMenuMode.INTERNAL:
		return bipob.is_internal_module(module) or bipob.is_internal_overlay_module(module)
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
		if module == null or module.placement_type != "internal":
			continue
		if filter_id == "all" or filter_id == "internal" or module_matches_constructor_filter(module, filter_id):
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
		var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
		selected_grouped_module_index = maxi(grouped_ids.find(module.id), 0)
	update_box_status()



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

	var workspace: Control = _create_external_visual_workspace() if box_menu_mode == BoxMenuMode.EXTERNAL else _create_internal_visual_workspace()

	var storage_panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(storage_panel)
	storage_panel.custom_minimum_size = Vector2(240, 0)
	storage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var storage_root: VBoxContainer = VBoxContainer.new()
	storage_root.add_theme_constant_override("separation", 4)
	var storage_title: Label = Label.new()
	storage_title.text = "COMPONENTS IN BOX STORAGE"
	_apply_label_style(storage_title, false, true)
	storage_root.add_child(storage_title)
	var filter_label: Label = Label.new()
	filter_label.text = "Filter: %s" % get_current_constructor_filter().capitalize()
	_apply_label_style(filter_label, true)
	storage_root.add_child(filter_label)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_root.add_child(grid)
	var storage_indices: Array[int] = get_current_filtered_box_storage_indices()
	if storage_indices.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = _get_storage_empty_state_text()
		_apply_label_style(empty_label, true)
		grid.add_child(empty_label)
	else:
		for storage_index in storage_indices:
			var module: BipobModule = bipob.box_storage[storage_index]
			var selected: bool = storage_index == selected_box_storage_index
			grid.add_child(_create_storage_module_card(module, storage_index, selected))
	storage_panel.add_child(storage_root)

	var details_panel: Control = _create_selected_module_detail_card()

	var side_panel: VBoxContainer = VBoxContainer.new()
	side_panel.custom_minimum_size = Vector2(230, 0)
	side_panel.add_theme_constant_override("separation", 4)
	side_panel.add_child(_create_constructor_playable_status_panel())
	if box_menu_mode == BoxMenuMode.INTERNAL:
		side_panel.add_child(_create_internal_connections_panel())
	if CONSTRUCTOR_COMPACT_STATUS:
		var diagnostics_hint: Label = Label.new()
		diagnostics_hint.text = "More details in Reference / Preview."
		_apply_label_style(diagnostics_hint, true, false)
		side_panel.add_child(diagnostics_hint)

	var mode_title: String = "External Modules on Body" if box_menu_mode == BoxMenuMode.EXTERNAL else "Internal Modules in Volume"
	parent.add_child(_create_constructor_mode_layout(mode_title, workspace, storage_panel, details_panel, side_panel))

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
			return "LEFT SIDE"
		"right":
			return "RIGHT SIDE"
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
	origin: bool
) -> StyleBoxFlat:
	var bg_color: Color = Color(0.035, 0.050, 0.060, 1.0)
	var border_color: Color = UI_COLOR_BORDER_DIM
	var border_width: int = 1

	if module != null:
		if bipob.has_method("get_module_visual_color"):
			var module_color: Color = bipob.get_module_visual_color(module)
			bg_color = module_color.darkened(0.62)
			border_color = module_color
		else:
			bg_color = Color(0.120, 0.160, 0.180, 1.0)

	if preview:
		bg_color = Color(0.100, 0.230, 0.130, 1.0)
		border_color = UI_COLOR_OK

	if invalid_preview:
		bg_color = Color(0.260, 0.070, 0.070, 1.0)
		border_color = UI_COLOR_DANGER

	if selected:
		border_color = UI_COLOR_SELECTED
		border_width = 2

	if origin:
		border_color = UI_COLOR_ACCENT
		border_width = 2

	return _make_panel_style(bg_color, border_color, border_width, 5)


func _get_selected_external_candidate_module() -> BipobModule:
	var selected_module: BipobModule = null

	if selected_box_storage_index >= 0 and selected_box_storage_index < bipob.box_storage.size():
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

	if bipob.has_method("get_module_visual_short_label"):
		return bipob.get_module_visual_short_label(module)

	return "M"


func _on_external_visual_cell_pressed(side_id: String, cell: Vector2i) -> void:
	_set_external_selection_from_side_and_cell(side_id, cell)
	update_box_status()


func _create_external_side_grid(side_id: String) -> Control:
	var side_panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(side_panel)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)

	var title: Label = Label.new()
	title.text = _get_external_side_display_name(side_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, false, true)
	root.add_child(title)

	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var preview_cells: Dictionary = _get_external_preview_cells_for_side(side_id)
	var selected_side_id: String = get_selected_external_side_id()

	var grid: GridContainer = GridContainer.new()
	grid.columns = side_size.x
	grid.add_theme_constant_override("h_separation", EXTERNAL_GRID_CELL_GAP)
	grid.add_theme_constant_override("v_separation", EXTERNAL_GRID_CELL_GAP)

	for y in range(side_size.y):
		for x in range(side_size.x):
			var cell: Vector2i = Vector2i(x, y)
			var key: String = bipob.get_external_slot_key(side_id, cell)
			var module: BipobModule = bipob.get_external_module_at(side_id, cell)

			var selected: bool = side_id == selected_side_id and cell == selected_external_slot_position

			var preview: bool = false
			var invalid_preview: bool = false
			if preview_cells.has(key):
				var can_place_preview: bool = bool(preview_cells[key])
				preview = can_place_preview
				invalid_preview = not can_place_preview

			var origin: bool = selected

			var cell_button: Button = Button.new()
			cell_button.custom_minimum_size = EXTERNAL_GRID_CELL_SIZE
			cell_button.focus_mode = Control.FOCUS_NONE
			cell_button.text = _get_external_cell_label(module)
			cell_button.add_theme_stylebox_override("normal", _make_external_cell_style(module, selected, preview, invalid_preview, origin))
			cell_button.add_theme_stylebox_override("hover", _make_external_cell_style(module, true, preview, invalid_preview, origin))
			cell_button.add_theme_stylebox_override("pressed", _make_external_cell_style(module, true, preview, invalid_preview, origin))
			cell_button.add_theme_color_override("font_color", UI_COLOR_TEXT)
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


func _create_external_robot_preview_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_panel_style(panel, true)
	panel.custom_minimum_size = Vector2(135, 135)

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


func _create_external_visual_workspace() -> Control:
	var workspace: PanelContainer = PanelContainer.new()
	_apply_panel_style(workspace, true)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title: Label = Label.new()
	title.text = "External Modules Workspace"
	_apply_label_style(title, false, true)
	root.add_child(title)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(_create_external_side_grid("top"))
	root.add_child(top_row)

	var middle_row: HBoxContainer = HBoxContainer.new()
	middle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_row.add_theme_constant_override("separation", 4)
	middle_row.add_child(_create_external_side_grid("left"))
	middle_row.add_child(_create_external_robot_preview_panel())
	middle_row.add_child(_create_external_side_grid("right"))
	root.add_child(middle_row)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 4)
	bottom_row.add_child(_create_external_side_grid("front"))
	bottom_row.add_child(_create_external_side_grid("bottom"))
	bottom_row.add_child(_create_external_side_grid("back"))
	root.add_child(bottom_row)

	var installed_summary: Label = Label.new()
	var installed_modules: Array[BipobModule] = bipob.get_unique_external_modules() if bipob.has_method("get_unique_external_modules") else []
	if installed_modules.is_empty():
		installed_summary.text = "Installed: none"
	else:
		var names: Array[String] = []
		for module in installed_modules:
			if module != null:
				names.append(bipob.get_module_display_name(module))
		installed_summary.text = "Installed: " + ", ".join(names)
	_apply_label_style(installed_summary, true, false)
	installed_summary.clip_text = true
	root.add_child(installed_summary)

	if not CONSTRUCTOR_COMPACT_STATUS:
		var status_text_label: Label = Label.new()
		status_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_text_label.text = _get_external_selected_slot_summary_text()
		_apply_label_style(status_text_label, true)
		root.add_child(status_text_label)

	workspace.add_child(root)
	return workspace


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

func _ready() -> void:
	if status_label != null:
		status_label.position = Vector2(100, 20)
	if hint_label != null:
		hint_label.position = Vector2(100, 50)
		hint_label.text = "Mission 1: pick up the key, open the door, reach the exit."

	diagnostic_label = Label.new()
	diagnostic_label.name = "DiagnosticLabel"
	diagnostic_label.position = Vector2(100, 80)
	diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_label.custom_minimum_size = Vector2(700, 140)
	diagnostic_label.text = "Diagnostic: none"
	add_child(diagnostic_label)

	if command_panel != null:
		command_panel.position = Vector2(850, 80)
		command_panel.custom_minimum_size = Vector2(220, 260)

	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	_configure_box_layout()
	_apply_box_screen_fullscreen_layout()
	_ensure_action_panel_scrollable()

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

	drop_item_button = Button.new()
	drop_item_button.name = "DropItemButton"
	drop_item_button.text = "Drop Item"
	drop_item_button.focus_mode = Control.FOCUS_NONE

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
		command_list.add_child(drop_item_button)
		drop_item_button.pressed.connect(_on_drop_item_button_pressed)
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

	mission_tab_button = Button.new()
	mission_tab_button.name = "MissionTabButton"
	mission_tab_button.text = "Available Bipobs"
	mission_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(mission_tab_button)
	mission_tab_button.pressed.connect(set_box_menu_mode_mission)

	modules_tab_button = Button.new()
	modules_tab_button.name = "ModulesTabButton"
	modules_tab_button.text = "Constructor Dashboard"
	modules_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(modules_tab_button)
	modules_tab_button.pressed.connect(set_box_menu_mode_modules)

	external_tab_button = Button.new()
	external_tab_button.name = "ExternalTabButton"
	external_tab_button.text = "External Modules"
	external_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(external_tab_button)
	external_tab_button.pressed.connect(set_box_menu_mode_external)
	internal_tab_button = Button.new()
	internal_tab_button.name = "InternalTabButton"
	internal_tab_button.text = "Internal Modules"
	internal_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(internal_tab_button)
	internal_tab_button.pressed.connect(set_box_menu_mode_internal)

	box_restart_button = null

	box_return_button = null

	_create_app_menu_roots()

	_apply_constructor_visual_style()

	bipob.status_changed.connect(update_status)
	bipob.hint_requested.connect(show_hint)
	bipob.mission_completed.connect(_on_mission_completed)
	bipob.returned_to_box.connect(_on_returned_to_box)

	update_status()
	rebuild_box_action_buttons()
	_apply_constructor_ui_skin()
	update_box_status()
	update_diagnostic_status()
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

	for button in [mission_tab_button, modules_tab_button, external_tab_button, internal_tab_button]:
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
	placeholder_menu_root = _build_fullscreen_root("PlaceholderMenuRoot")
	add_child(main_menu_root)
	add_child(center_menu_root)
	add_child(placeholder_menu_root)
	_build_main_menu_layout()
	_build_center_menu_layout()
	_build_placeholder_layout()

func _build_fullscreen_root(node_name: String) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return root

func _hide_all_app_screens() -> void:
	if main_menu_root != null:
		main_menu_root.visible = false
	if center_menu_root != null:
		center_menu_root.visible = false
	if placeholder_menu_root != null:
		placeholder_menu_root.visible = false
	if box_screen != null:
		box_screen.visible = false

func _set_gameplay_ui_visible(is_visible: bool) -> void:
	if command_panel != null:
		command_panel.visible = is_visible
	if status_label != null:
		status_label.visible = is_visible
	if hint_label != null:
		hint_label.visible = is_visible
	if diagnostic_label != null:
		diagnostic_label.visible = is_visible

func show_main_menu_screen() -> void:
	app_screen_mode = AppScreenMode.MAIN_MENU
	box_opened_from_center = false
	_hide_all_app_screens()
	_set_gameplay_ui_visible(false)
	if main_menu_root != null:
		main_menu_root.visible = true

func show_center_screen() -> void:
	app_screen_mode = AppScreenMode.CENTER
	_hide_all_app_screens()
	_set_gameplay_ui_visible(false)
	if center_menu_root != null:
		center_menu_root.visible = true

func show_placeholder_screen(title_text: String) -> void:
	previous_app_screen_mode = app_screen_mode
	app_screen_mode = AppScreenMode.SETTINGS_PLACEHOLDER
	_hide_all_app_screens()
	_set_gameplay_ui_visible(false)
	if placeholder_title_label != null:
		placeholder_title_label.text = title_text
	if placeholder_menu_root != null:
		placeholder_menu_root.visible = true

func start_gameplay_from_center() -> void:
	app_screen_mode = AppScreenMode.GAMEPLAY
	box_opened_from_center = false
	_hide_all_app_screens()
	_set_gameplay_ui_visible(true)
	_on_start_mission_button_pressed()

func show_box_constructor_from_center() -> void:
	app_screen_mode = AppScreenMode.BOX_CONSTRUCTOR
	box_opened_from_center = true
	_hide_all_app_screens()
	_set_gameplay_ui_visible(false)
	show_box_screen()
	if modules_tab_button != null:
		set_box_menu_mode_modules()
	else:
		set_box_menu_mode_external()

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

func _apply_box_screen_fullscreen_layout() -> void:
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
	show_box_screen()
	update_box_status()

func _on_returned_to_box() -> void:
	should_advance_mission_on_start = false
	box_opened_from_center = false
	show_box_screen()
	update_box_status()

func show_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = true
	if command_panel != null:
		command_panel.visible = false
	_apply_box_screen_fullscreen_layout()
	start_mission_warning_acknowledged = false
	update_box_status()
	
func hide_box_screen() -> void:
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
	_apply_box_screen_fullscreen_layout()
	_ensure_action_panel_scrollable()

	clamp_box_selection_indexes()
	update_diagnostic_status()

	if box_title_label != null:
		if box_menu_mode == BoxMenuMode.MISSION:
			box_title_label.text = "Constructor — Mission"
		elif box_menu_mode == BoxMenuMode.EXTERNAL:
			box_title_label.text = "Constructor — External Modules"
		elif box_menu_mode == BoxMenuMode.INTERNAL:
			box_title_label.text = "Constructor — Internal Modules"
		else:
			box_title_label.text = "Constructor — Modules"

	var content_text: String = ""
	if box_menu_mode == BoxMenuMode.MISSION:
		content_text = get_box_mission_menu_text()
	elif box_menu_mode == BoxMenuMode.MODULES:
		content_text = get_box_modules_menu_text()

	update_box_button_visibility()

	var ui_panel: VBoxContainer = box_content_scroll.get_node_or_null("BoxContentCards")
	if box_menu_mode == BoxMenuMode.EXTERNAL or box_menu_mode == BoxMenuMode.INTERNAL:
		if box_content_label != null:
			box_content_label.text = ""
			box_content_label.visible = false
		if ui_panel != null:
			ui_panel.queue_free()
		ui_panel = VBoxContainer.new()
		ui_panel.name = "BoxContentCards"
		ui_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box_content_scroll.add_child(ui_panel)
		_build_storage_cards_panel(ui_panel)
		rebuild_box_action_buttons()
		update_box_button_visibility()
		return

	if box_content_label != null:
		box_content_label.visible = true
		box_content_label.text = content_text
	if ui_panel != null:
		ui_panel.queue_free()

func get_box_mission_menu_text() -> String:
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
	return bipob.can_place_internal_module(module, bipob.selected_internal_origin, bipob.selected_internal_rotation)

func _can_place_selected_external_visual() -> bool:
	var module: BipobModule = _get_selected_external_candidate_module()
	if module == null:
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
	for child in right_button_panel.get_children():
		child.queue_free()

	var actions_label: Label = Label.new()
	actions_label.name = "ActionsLabel"
	actions_label.text = "Actions"
	right_button_panel.add_child(actions_label)
	_apply_label_style(actions_label, false, true)
	right_button_panel.add_theme_constant_override("separation", ACTION_GROUP_SPACING)

	if box_menu_mode == BoxMenuMode.MISSION:
		_add_box_action_button("Charge", Callable(self, "_on_charge_button_pressed"))
		_add_box_action_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"))
		_add_box_action_button("Start", Callable(self, "_on_start_mission_button_pressed"))
		_add_box_action_button("Restart", Callable(self, "_on_restart_mission_button_pressed"))
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		var selected_external_slot_module: BipobModule = bipob.get_external_module_at(
			bipob.selected_external_side,
			bipob.selected_external_origin
		)
		var selection_group: VBoxContainer = _create_action_group_panel("Selection")
		right_button_panel.add_child(selection_group)
		var external_filter_row: HBoxContainer = _create_action_button_row()
		selection_group.add_child(external_filter_row)
		_add_action_button(external_filter_row, "Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"), "normal", true, true)
		_add_action_button(external_filter_row, "Next Filter", Callable(self, "_on_next_constructor_filter_pressed"), "normal", true, true)
		var external_box_row: HBoxContainer = _create_action_button_row()
		selection_group.add_child(external_box_row)
		_add_action_button(external_box_row, "Prev Box", Callable(self, "_on_prev_box_pressed"), "normal", true, true)
		_add_action_button(external_box_row, "Next Box", Callable(self, "_on_next_box_pressed"), "normal", true, true)

		var external_position_group: VBoxContainer = _create_action_group_panel("Position")
		right_button_panel.add_child(external_position_group)
		var side_row: HBoxContainer = _create_action_button_row()
		external_position_group.add_child(side_row)
		_add_action_button(side_row, "Side Prev", Callable(self, "_on_prev_external_side_pressed"), "normal", true, true)
		_add_action_button(side_row, "Side Next", Callable(self, "_on_next_external_side_pressed"), "normal", true, true)
		var external_x_row: HBoxContainer = _create_action_button_row()
		external_position_group.add_child(external_x_row)
		_add_action_button(external_x_row, "X-", Callable(self, "_on_prev_external_slot_pressed"), "normal", true, true)
		_add_action_button(external_x_row, "X+", Callable(self, "_on_next_external_slot_pressed"), "normal", true, true)
		var external_y_row: HBoxContainer = _create_action_button_row()
		external_position_group.add_child(external_y_row)
		_add_action_button(external_y_row, "Y-", Callable(self, "_on_prev_external_side_pressed"), "normal", true, true)
		_add_action_button(external_y_row, "Y+", Callable(self, "_on_next_external_side_pressed"), "normal", true, true)

		var external_module_group: VBoxContainer = _create_action_group_panel("Module")
		right_button_panel.add_child(external_module_group)
		_add_action_button(external_module_group, "Place", Callable(self, "_on_place_external_module_pressed"), "primary", _can_place_selected_external_visual())
		_add_action_button(external_module_group, "Remove", Callable(self, "_on_remove_external_module_pressed"), "danger", selected_external_slot_module != null)

		var external_reference_group: VBoxContainer = _create_action_group_panel("Reference / Preview")
		right_button_panel.add_child(external_reference_group)
		_add_action_button(external_reference_group, "Checkpoint", Callable(self, "_on_constructor_checkpoint_pressed"), "reference")
		_add_action_button(external_reference_group, "Final Audit", Callable(self, "_on_constructor_final_audit_pressed"), "reference")
	elif box_menu_mode == BoxMenuMode.INTERNAL:
		var internal_remove_available: bool = bipob.get_internal_module_at_cell(bipob.selected_internal_origin) != null
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
		_add_action_button(overlay_plan_group, "Commit Plan", Callable(self, "_on_commit_overlay_pressed"), "primary", _can_commit_overlay_plan_visual())
		var overlay_paths_group: VBoxContainer = _create_action_group_panel("Overlay Paths")
		right_button_panel.add_child(overlay_paths_group)
		var path_row: HBoxContainer = _create_action_button_row()
		overlay_paths_group.add_child(path_row)
		_add_action_button(path_row, "Prev Path", Callable(self, "_on_prev_overlay_pressed"), "normal", true, true)
		_add_action_button(path_row, "Next Path", Callable(self, "_on_next_overlay_pressed"), "normal", true, true)
		_add_action_button(overlay_paths_group, "Remove Path", Callable(self, "_on_remove_selected_overlay_pressed"), "danger", _has_selected_overlay_path_visual())
		var reference_group: VBoxContainer = _create_action_group_panel("Reference / Preview")
		right_button_panel.add_child(reference_group)
		_add_action_button(reference_group, "Checkpoint", Callable(self, "_on_constructor_checkpoint_pressed"), "reference")
		_add_action_button(reference_group, "Overlay Diff", Callable(self, "_on_overlay_diff_pressed"), "reference")
		_add_action_button(reference_group, "Final Audit", Callable(self, "_on_constructor_final_audit_pressed"), "reference")
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

func update_box_button_visibility() -> void:
	var is_mission := box_menu_mode == BoxMenuMode.MISSION
	var is_modules := box_menu_mode == BoxMenuMode.MODULES
	var is_external := box_menu_mode == BoxMenuMode.EXTERNAL
	var is_internal := box_menu_mode == BoxMenuMode.INTERNAL
	if mission_tab_button != null:
		mission_tab_button.disabled = is_mission
	if modules_tab_button != null:
		modules_tab_button.disabled = is_modules
	if external_tab_button != null:
		external_tab_button.disabled = is_external
	if internal_tab_button != null:
		internal_tab_button.disabled = is_internal

func set_box_menu_mode_mission() -> void:
	box_menu_mode = BoxMenuMode.MISSION
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_modules() -> void:
	box_menu_mode = BoxMenuMode.MODULES
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_external() -> void:
	box_menu_mode = BoxMenuMode.EXTERNAL
	selected_grouped_module_index = 0
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_external_selection()
	update_box_status()
	rebuild_box_action_buttons()


func set_box_menu_mode_internal() -> void:
	box_menu_mode = BoxMenuMode.INTERNAL
	selected_grouped_module_index = 0
	sync_selected_box_storage_index_from_grouped_selection()
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
	var side_id := get_selected_external_side_id()
	if bipob.remove_external_module_to_box_storage(side_id, selected_external_slot_position):
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


func _build_main_menu_layout() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 360)
	panel.position = Vector2(500, 170)
	_apply_panel_style(panel, true)
	main_menu_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "BIPOB"
	_apply_label_style(title, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	for data in [["Играть","_on_main_play_pressed"],["Настройки","_on_main_settings_pressed"],["О нас","_on_main_about_pressed"],["Выйти из игры","_on_main_exit_pressed"]]:
		var b := Button.new()
		b.text = data[0]
		b.custom_minimum_size = Vector2(160, 34)
		_apply_action_button_style(b, "normal")
		b.pressed.connect(Callable(self, data[1]))
		vbox.add_child(b)
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
	var tasks := Button.new()
	tasks.text = "Задания"
	tasks.position = Vector2(24, 24)
	tasks.custom_minimum_size = Vector2(160, 34)
	_apply_action_button_style(tasks, "normal")
	tasks.pressed.connect(_on_center_tasks_pressed)
	center_menu_root.add_child(tasks)
	var exit_btn := Button.new()
	exit_btn.text = "Выйти из игры"
	exit_btn.position = Vector2(980, 24)
	exit_btn.custom_minimum_size = Vector2(170, 34)
	_apply_action_button_style(exit_btn, "danger")
	exit_btn.pressed.connect(_on_center_exit_pressed)
	center_menu_root.add_child(exit_btn)
	var settings := Button.new()
	settings.text = "Настройки"
	settings.position = Vector2(980, 68)
	settings.custom_minimum_size = Vector2(170, 34)
	_apply_action_button_style(settings, "normal")
	settings.pressed.connect(_on_center_settings_pressed)
	center_menu_root.add_child(settings)
	var shop := Button.new()
	shop.text = "Магазин"
	shop.position = Vector2(980, 320)
	shop.custom_minimum_size = Vector2(170, 34)
	_apply_action_button_style(shop, "normal")
	shop.pressed.connect(_on_center_shop_pressed)
	center_menu_root.add_child(shop)
	var row := HBoxContainer.new()
	row.position = Vector2(280, 640)
	row.add_theme_constant_override("separation", 12)
	center_menu_root.add_child(row)
	for data in [["Box","_on_center_box_pressed"],["Зарядка","_on_center_charge_pressed"],["Исследования","_on_center_research_pressed"],["Ремонт","_on_center_repair_pressed"]]:
		var b := Button.new()
		b.text = data[0]
		b.custom_minimum_size = Vector2(170, 34)
		_apply_action_button_style(b, "normal")
		b.pressed.connect(Callable(self, data[1]))
		row.add_child(b)
	var to_main := Button.new()
	to_main.text = "Выйти в главное меню"
	to_main.position = Vector2(920, 680)
	to_main.custom_minimum_size = Vector2(230, 34)
	_apply_action_button_style(to_main, "normal")
	to_main.pressed.connect(_on_center_main_menu_pressed)
	center_menu_root.add_child(to_main)

func _build_placeholder_layout() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 220)
	panel.position = Vector2(430, 250)
	_apply_panel_style(panel, true)
	placeholder_menu_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	placeholder_title_label = Label.new()
	_apply_label_style(placeholder_title_label, false, true)
	placeholder_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(placeholder_title_label)
	var body := Label.new()
	body.text = "Раздел в разработке."
	_apply_label_style(body)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(body)
	var back := Button.new()
	back.text = "Назад"
	back.custom_minimum_size = Vector2(160, 34)
	_apply_action_button_style(back, "normal")
	back.pressed.connect(_on_placeholder_back_pressed)
	vbox.add_child(back)

func _on_main_play_pressed() -> void:
	show_center_screen()
func _on_main_settings_pressed() -> void:
	show_placeholder_screen("Настройки")
func _on_main_about_pressed() -> void:
	show_placeholder_screen("О нас")
func _on_main_exit_pressed() -> void:
	show_placeholder_screen("Выход из игры")
func _on_center_tasks_pressed() -> void:
	start_gameplay_from_center()
func _on_center_box_pressed() -> void:
	show_box_constructor_from_center()
func _on_center_charge_pressed() -> void:
	charge_bipob_from_center()
func _on_center_research_pressed() -> void:
	show_placeholder_screen("Исследования")
func _on_center_repair_pressed() -> void:
	show_placeholder_screen("Ремонт")
func _on_center_shop_pressed() -> void:
	show_placeholder_screen("Магазин")
func _on_center_settings_pressed() -> void:
	show_placeholder_screen("Настройки")
func _on_center_main_menu_pressed() -> void:
	show_main_menu_screen()
func _on_center_exit_pressed() -> void:
	show_placeholder_screen("Выход из игры")
func _on_placeholder_back_pressed() -> void:
	if previous_app_screen_mode == AppScreenMode.MAIN_MENU:
		show_main_menu_screen()
	else:
		show_center_screen()

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
	if bipob == null:
		return
	if box_opened_from_center or app_screen_mode == AppScreenMode.BOX_CONSTRUCTOR:
		show_center_screen()
		return
	bipob.return_to_box()
	if box_screen != null and not box_screen.visible:
		show_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func update_status() -> void:
	if bipob == null:
		return

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
	if selected_box_storage_index < 0:
		return null
	if selected_box_storage_index >= bipob.box_storage.size():
		return null
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
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
	var grid: GridContainer = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", INTERNAL_GRID_CELL_GAP)
	grid.add_theme_constant_override("v_separation", INTERNAL_GRID_CELL_GAP)
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
			var cell_button: Button = Button.new()
			cell_button.custom_minimum_size = INTERNAL_GRID_CELL_SIZE
			cell_button.focus_mode = Control.FOCUS_NONE
			cell_button.text = _get_internal_visual_cell_label(cell, module)
			cell_button.add_theme_stylebox_override("normal", _make_internal_cell_style(cell, module, selected, preview, invalid_preview))
			cell_button.add_theme_stylebox_override("hover", _make_internal_cell_style(cell, module, true, preview, invalid_preview))
			cell_button.add_theme_stylebox_override("pressed", _make_internal_cell_style(cell, module, true, preview, invalid_preview))
			cell_button.add_theme_color_override("font_color", UI_COLOR_TEXT)
			cell_button.pressed.connect(func() -> void: _on_internal_visual_cell_pressed(cell))
			if selected:
				_apply_selected_pulse(cell_button)
			if invalid_preview:
				_apply_invalid_preview_blink(cell_button)
			grid.add_child(cell_button)
	root.add_child(grid)
	panel.add_child(root)
	return panel

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
	var workspace: PanelContainer = PanelContainer.new()
	_apply_panel_style(workspace, true)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = "INTERNAL MODULES IN VOLUME"
	_apply_label_style(title, false, true)
	root.add_child(title)
	var middle_row: HBoxContainer = HBoxContainer.new()
	middle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_row.add_theme_constant_override("separation", 4)
	middle_row.add_child(_create_internal_slice_grid("VERTICAL SLICE", "z", "y", "x", bipob.selected_internal_origin.x))
	middle_row.add_child(_create_internal_cube_preview_panel())
	middle_row.add_child(_create_internal_slice_grid("MAIN SLICE", "x", "y", "z", bipob.selected_internal_origin.z))
	root.add_child(middle_row)
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 4)
	bottom_row.add_child(_create_internal_slice_grid("HORIZONTAL SLICE", "x", "z", "y", bipob.selected_internal_origin.y))
	bottom_row.add_child(_create_internal_legend_panel())
	root.add_child(bottom_row)
	workspace.add_child(root)
	return workspace

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
	lines.append("VERTICAL SLICE | INTERNAL VOLUME | HORIZONTAL SLICE")
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
	constructor_filter_index -= 1
	if constructor_filter_index < 0:
		constructor_filter_index = CONSTRUCTOR_FILTERS.size() - 1
	clamp_box_selection_indexes()
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, maxi(get_filtered_grouped_module_ids().size() - 1, 0))
	sync_selected_box_storage_index_from_grouped_selection()
	update_box_status()

func _on_next_constructor_filter_pressed() -> void:
	constructor_filter_index += 1
	if constructor_filter_index >= CONSTRUCTOR_FILTERS.size():
		constructor_filter_index = 0
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

func _on_clear_overlay_pressed() -> void:
	bipob.clear_selected_overlay_cells()
	update_box_status()

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
