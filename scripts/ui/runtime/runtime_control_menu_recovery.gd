extends Node
class_name RuntimeControlMenuRecoveryService

const CHECK_INTERVAL := 0.35
const PANEL_Z_INDEX := 66
const MIN_CONTROL_WIDTH := 360.0
const MAX_CONTROL_WIDTH := 620.0
const DEFAULT_CONTROL_HEIGHT := 104.0

var _ui_ref: Object = null
var _check_timer: float = 0.0

func _ready() -> void:
	call_deferred("_find_existing_game_ui")
	if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if _ui_ref == null or not is_instance_valid(_ui_ref):
		_find_existing_game_ui()
	if _ui_ref != null and is_instance_valid(_ui_ref):
		_ensure_runtime_controls(_ui_ref)


func _on_node_added(node: Node) -> void:
	if node != null and _looks_like_game_ui(node):
		_ui_ref = node
		call_deferred("_ensure_runtime_controls", node)


func _find_existing_game_ui() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	var found: Node = _find_game_ui_limited(get_tree().current_scene, 3)
	if found == null:
		found = _find_game_ui_limited(get_tree().root, 4)
	if found != null:
		_ui_ref = found
		_ensure_runtime_controls(found)


func _find_game_ui_limited(node: Node, depth: int) -> Node:
	if node == null or depth < 0:
		return null
	if _looks_like_game_ui(node):
		return node
	for child in node.get_children():
		var found: Node = _find_game_ui_limited(child, depth - 1)
		if found != null:
			return found
	return null


func _looks_like_game_ui(node: Node) -> bool:
	return node != null and node.has_method("_apply_runtime_hud_layout") and node.has_method("_create_runtime_controls_panel") and _has_property(node, "runtime_hud_root") and _has_property(node, "command_panel")


func _ensure_runtime_controls(ui: Object) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	_hide_legacy_command_panel(ui)
	if not _should_show_runtime_controls(ui):
		return
	var hud_root: Control = _get_property(ui, "runtime_hud_root") as Control
	if hud_root == null or not is_instance_valid(hud_root):
		return
	var bottom_left: VBoxContainer = hud_root.get_node_or_null("RuntimeBottomLeft") as VBoxContainer
	if bottom_left == null or not is_instance_valid(bottom_left):
		bottom_left = VBoxContainer.new()
		bottom_left.name = "RuntimeBottomLeft"
		bottom_left.add_theme_constant_override("separation", 4)
		hud_root.add_child(bottom_left)
	var controls_panel: Control = bottom_left.get_node_or_null("RuntimeControlsPanel") as Control
	if controls_panel == null or not is_instance_valid(controls_panel):
		controls_panel = ui.call("_create_runtime_controls_panel") as Control
		if controls_panel == null:
			return
		bottom_left.add_child(controls_panel)
	bottom_left.visible = true
	bottom_left.z_index = PANEL_Z_INDEX
	bottom_left.z_as_relative = false
	bottom_left.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_panel.visible = true
	controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var base_row: Control = _get_property(ui, "runtime_base_controls_grid") as Control
	if base_row == null or not is_instance_valid(base_row):
		base_row = controls_panel.find_child("RuntimeBaseControlRow", true, false) as Control
	if base_row != null and is_instance_valid(base_row):
		base_row.visible = true
		base_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_refresh_runtime_controls(ui)
	_layout_bottom_left(ui, bottom_left, controls_panel)


func _layout_bottom_left(ui: Object, bottom_left: Control, controls_panel: Control) -> void:
	var margin: float = _call_float(ui, "_get_runtime_margin", 12.0)
	var viewport: Vector2 = _call_vector2(ui, "_get_viewport_size", bottom_left.get_viewport_rect().size)
	var reserved_right: float = 0.0
	var storage_panel: Control = _get_property(ui, "runtime_storage_panel") as Control
	if storage_panel != null and is_instance_valid(storage_panel) and storage_panel.visible:
		reserved_right = maxf(0.0, storage_panel.size.x + margin * 2.0)
	if reserved_right <= 0.0:
		reserved_right = 400.0
	var available_width: float = maxf(viewport.x - reserved_right - margin * 2.0, MIN_CONTROL_WIDTH)
	var width: float = clampf(available_width, MIN_CONTROL_WIDTH, MAX_CONTROL_WIDTH)
	var height: float = maxf(DEFAULT_CONTROL_HEIGHT, controls_panel.get_combined_minimum_size().y + 40.0)
	bottom_left.anchor_left = 0.0
	bottom_left.anchor_right = 0.0
	bottom_left.anchor_top = 1.0
	bottom_left.anchor_bottom = 1.0
	bottom_left.offset_left = margin
	bottom_left.offset_right = margin + width
	bottom_left.offset_bottom = -margin
	bottom_left.offset_top = -margin - height
	bottom_left.custom_minimum_size = Vector2(width, height)
	controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_panel.custom_minimum_size = Vector2(width, maxf(88.0, height - 36.0))
	if bottom_left.get_parent() != null:
		bottom_left.get_parent().move_child(bottom_left, bottom_left.get_parent().get_child_count() - 1)


func _refresh_runtime_controls(ui: Object) -> void:
	var bridge: Object = _get_property(ui, "runtime_action_panel_bridge") as Object
	if bridge != null and is_instance_valid(bridge) and bridge.has_method("refresh_controls"):
		bridge.call("refresh_controls")
		return
	var controls_panel: Control = _get_property(ui, "runtime_base_controls_grid") as Control
	if controls_panel != null:
		controls_panel.visible = true


func _hide_legacy_command_panel(ui: Object) -> void:
	var command_panel: Control = _get_property(ui, "command_panel") as Control
	if command_panel != null and is_instance_valid(command_panel):
		command_panel.visible = false
		command_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _should_show_runtime_controls(ui: Object) -> bool:
	var bipob: Object = _get_property(ui, "bipob") as Object
	if bipob == null or not is_instance_valid(bipob):
		return false
	var hud_root: Control = _get_property(ui, "runtime_hud_root") as Control
	if hud_root == null or not is_instance_valid(hud_root) or not hud_root.visible:
		return false
	var map_state: Object = _get_property(ui, "map_constructor_state") as Object
	if map_state != null and is_instance_valid(map_state) and bool(map_state.get("map_constructor_mode_active")):
		return false
	return true


func _call_float(target: Object, method_name: String, fallback: float) -> float:
	if target != null and is_instance_valid(target) and target.has_method(method_name):
		return float(target.call(method_name))
	return fallback


func _call_vector2(target: Object, method_name: String, fallback: Vector2) -> Vector2:
	if target != null and is_instance_valid(target) and target.has_method(method_name):
		var value: Variant = target.call(method_name)
		if value is Vector2:
			return value
	return fallback


func _get_property(target: Object, property_name: String) -> Variant:
	if target == null or not _has_property(target, property_name):
		return null
	return target.get(property_name)


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false
