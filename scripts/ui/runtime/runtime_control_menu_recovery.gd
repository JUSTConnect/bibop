extends Node
class_name RuntimeControlMenuRecoveryService

const FALLBACK_PANEL_NAME := "RuntimeControlMenuFallbackPanel"
const CHECK_INTERVAL := 0.35
const PANEL_Z_INDEX := 72

var _ui_ref: Object = null
var _check_timer: float = 0.0

func _ready() -> void:
	if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if _ui_ref == null or not is_instance_valid(_ui_ref):
		return
	_ensure_control_menu(_ui_ref)


func _on_node_added(node: Node) -> void:
	if node == null:
		return
	if _looks_like_game_ui(node):
		_ui_ref = node
		call_deferred("_ensure_control_menu", node)


func _looks_like_game_ui(node: Node) -> bool:
	return node != null and node.has_method("_apply_runtime_hud_layout") and node.has_method("_get_runtime_margin") and _has_property(node, "runtime_hud_root")


func _ensure_control_menu(ui: Object) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	if not _is_gameplay(ui):
		return
	var hud_root: Control = _get_property(ui, "runtime_hud_root") as Control
	if hud_root == null or not is_instance_valid(hud_root):
		return
	var existing_normal: Control = _find_normal_controls_panel(hud_root)
	if existing_normal != null and is_instance_valid(existing_normal) and existing_normal.visible:
		var existing_fallback: Node = hud_root.get_node_or_null(FALLBACK_PANEL_NAME)
		if existing_fallback != null and is_instance_valid(existing_fallback):
			existing_fallback.queue_free()
		return
	var fallback: Control = hud_root.get_node_or_null(FALLBACK_PANEL_NAME) as Control
	if fallback == null or not is_instance_valid(fallback):
		fallback = _build_fallback_panel(ui)
		hud_root.add_child(fallback)
	else:
		fallback.visible = true
	_layout_fallback(ui, fallback)


func _find_normal_controls_panel(hud_root: Control) -> Control:
	var bottom_left: Node = hud_root.get_node_or_null("RuntimeBottomLeft")
	if bottom_left != null:
		var panel: Control = bottom_left.get_node_or_null("RuntimeControlsPanel") as Control
		if panel != null:
			return panel
	return hud_root.find_child("RuntimeControlsPanel", true, false) as Control


func _build_fallback_panel(ui: Object) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = FALLBACK_PANEL_NAME
	panel.z_index = PANEL_Z_INDEX
	panel.z_as_relative = false
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.custom_minimum_size = Vector2(520, 74)
	panel.add_theme_stylebox_override("panel", _make_style(_ui_color(ui, "UI_COLOR_PANEL", Color(0.075, 0.090, 0.115, 0.96)), _ui_color(ui, "UI_COLOR_BORDER", Color(0.220, 0.480, 0.620, 0.85))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "RuntimeControlMenuFallbackRow"
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var bridge: Object = _ensure_bridge(ui)
	var turn_left: Button = _make_button(ui, "L", Callable(bridge, "on_turn_left_pressed") if bridge != null else Callable(ui, "_on_turn_left_pressed"))
	var turn_right: Button = _make_button(ui, "R", Callable(bridge, "on_turn_right_pressed") if bridge != null else Callable(ui, "_on_turn_right_pressed"))
	var act: Button = _make_button(ui, "Act", Callable(bridge, "on_action_pressed") if bridge != null else Callable(ui, "_on_interact_pressed"))
	var connect: Button = _make_button(ui, "Connect", Callable(bridge, "on_connect_pressed") if bridge != null else Callable(ui, "_on_connect_pressed"))
	var claw: Button = _make_button(ui, "Claw", Callable(bridge, "on_heavy_claw_pressed") if bridge != null else Callable(ui, "_on_heavy_claw_pressed"))
	var cut: Button = _make_button(ui, "Cut", Callable(bridge, "on_cut_pressed") if bridge != null else Callable(ui, "_on_runtime_cut_pressed"))
	var end_turn: Button = _make_button(ui, "End", Callable(bridge, "on_end_turn_pressed") if bridge != null else Callable(ui, "_on_end_turn_pressed"))

	for button in [turn_left, turn_right, act, connect, claw, cut, end_turn]:
		row.add_child(button)

	_set_property_if_exists(ui, "runtime_turn_left_button", turn_left)
	_set_property_if_exists(ui, "runtime_turn_right_button", turn_right)
	_set_property_if_exists(ui, "runtime_action_button", act)
	_set_property_if_exists(ui, "runtime_connect_button", connect)
	_set_property_if_exists(ui, "runtime_heavy_claw_button", claw)
	_set_property_if_exists(ui, "runtime_cut_button", cut)
	_set_property_if_exists(ui, "runtime_end_turn_button", end_turn)
	return panel


func _layout_fallback(ui: Object, panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var margin: float = 12.0
	if ui != null and is_instance_valid(ui) and ui.has_method("_get_runtime_margin"):
		margin = float(ui.call("_get_runtime_margin"))
	var viewport: Vector2 = panel.get_viewport_rect().size
	var width: float = minf(560.0, maxf(viewport.x - 420.0, 360.0))
	var height: float = 82.0
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = margin
	panel.offset_right = margin + width
	panel.offset_top = -margin - height
	panel.offset_bottom = -margin
	panel.visible = true


func _make_button(ui: Object, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(68, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_TEXT", Color(0.82, 0.90, 0.92, 1.0)))
	button.add_theme_stylebox_override("normal", _make_style(_ui_color(ui, "UI_COLOR_PANEL_DARK", Color(0.045, 0.055, 0.075, 0.98)), _ui_color(ui, "UI_COLOR_BORDER_DIM", Color(0.120, 0.220, 0.280, 0.75))))
	button.add_theme_stylebox_override("hover", _make_style(_ui_color(ui, "UI_COLOR_PANEL", Color(0.075, 0.090, 0.115, 0.96)), _ui_color(ui, "UI_COLOR_ACCENT", Color(0.200, 0.760, 0.950, 1.0))))
	if callback.is_valid():
		button.pressed.connect(callback)
	else:
		button.disabled = true
	return button


func _ensure_bridge(ui: Object) -> Object:
	if ui == null or not is_instance_valid(ui):
		return null
	if ui.has_method("_ensure_runtime_action_panel_bridge"):
		ui.call("_ensure_runtime_action_panel_bridge")
	var bridge: Object = _get_property(ui, "runtime_action_panel_bridge") as Object
	return bridge


func _is_gameplay(ui: Object) -> bool:
	if ui == null or not is_instance_valid(ui) or not _has_property(ui, "app_screen_mode"):
		return false
	var mode_text: String = str(_get_property(ui, "app_screen_mode"))
	if mode_text == "2":
		return true
	return mode_text.to_lower().contains("gameplay")


func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _ui_color(target: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_property(target, property_name)
	return value if value is Color else fallback


func _get_property(target: Object, property_name: String) -> Variant:
	if target == null or not _has_property(target, property_name):
		return null
	return target.get(property_name)


func _set_property_if_exists(target: Object, property_name: String, value: Variant) -> void:
	if target != null and _has_property(target, property_name):
		target.set(property_name, value)


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false
