extends Node
class_name RuntimeCommandPanelRecoveryService

const CHECK_INTERVAL := 0.35
const PANEL_Z_INDEX := 72

var _ui_ref: Object = null
var _check_timer: float = 0.0

func _ready() -> void:
	call_deferred("_find_game_ui")
	if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if _ui_ref == null or not is_instance_valid(_ui_ref):
		_find_game_ui()
	if _ui_ref != null and is_instance_valid(_ui_ref):
		_update_command_panel(_ui_ref)


func _on_node_added(node: Node) -> void:
	if _is_game_ui(node):
		_ui_ref = node
		call_deferred("_update_command_panel", node)


func _find_game_ui() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	var found: Node = _find_game_ui_limited(get_tree().current_scene, 3)
	if found == null:
		found = _find_game_ui_limited(get_tree().root, 4)
	if found != null:
		_ui_ref = found
		_update_command_panel(found)


func _find_game_ui_limited(node: Node, depth: int) -> Node:
	if node == null or depth < 0:
		return null
	if _is_game_ui(node):
		return node
	for child in node.get_children():
		var found: Node = _find_game_ui_limited(child, depth - 1)
		if found != null:
			return found
	return null


func _is_game_ui(node: Node) -> bool:
	return node != null and _has_property(node, "command_panel") and _has_property(node, "bipob") and _has_property(node, "map_constructor_state")


func _update_command_panel(ui: Object) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	var panel: Control = _get_property(ui, "command_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var should_show: bool = _should_show_panel(ui)
	panel.visible = should_show
	if not should_show:
		return
	panel.z_index = PANEL_Z_INDEX
	panel.z_as_relative = false
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -302.0
	panel.offset_right = -82.0
	panel.offset_top = 80.0
	panel.offset_bottom = 420.0
	for child in panel.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button != null and is_instance_valid(button):
			button.visible = true
			button.mouse_filter = Control.MOUSE_FILTER_STOP


func _should_show_panel(ui: Object) -> bool:
	var bipob: Object = _get_property(ui, "bipob") as Object
	if bipob == null or not is_instance_valid(bipob):
		return false
	var map_state: Object = _get_property(ui, "map_constructor_state") as Object
	if map_state != null and is_instance_valid(map_state):
		if bool(map_state.get("map_constructor_mode_active")):
			return false
	return true


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
