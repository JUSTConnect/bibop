extends Node
class_name RuntimeHudRepairService

const CHECK_INTERVAL := 0.35
const REBUILD_COOLDOWN_MS := 1200

var _check_timer: float = 0.0
var _last_rebuild_msec: int = 0

func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	var ui: Object = _get_game_ui()
	if ui == null or not is_instance_valid(ui):
		return
	if not _is_runtime_gameplay(ui):
		_hide_legacy_command_panel(ui)
		return
	_repair_runtime_hud(ui)


func _get_game_ui() -> Object:
	if get_tree() == null:
		return null
	var scene: Node = get_tree().current_scene
	if scene != null:
		var direct_ui: Node = scene.get_node_or_null("UI")
		if _looks_like_game_ui(direct_ui):
			return direct_ui
		if _looks_like_game_ui(scene):
			return scene
	var root: Window = get_tree().root
	if root != null:
		var main_ui: Node = root.get_node_or_null("Main/UI")
		if _looks_like_game_ui(main_ui):
			return main_ui
	return null


func _looks_like_game_ui(node: Object) -> bool:
	return node != null and node.has_method("_apply_runtime_hud_layout") and node.has_method("_create_runtime_controls_panel") and _has_property(node, "runtime_hud_root") and _has_property(node, "bipob") and _has_property(node, "command_panel")


func _is_runtime_gameplay(ui: Object) -> bool:
	var bipob: Object = _get_property(ui, "bipob") as Object
	if bipob == null or not is_instance_valid(bipob):
		return false
	var field_runtime: Object = _get_property(ui, "field_runtime") as Object
	if field_runtime == null or not is_instance_valid(field_runtime):
		return false
	var map_state: Object = _get_property(ui, "map_constructor_state") as Object
	if map_state != null and is_instance_valid(map_state) and bool(map_state.get("map_constructor_mode_active")):
		return false
	return true


func _repair_runtime_hud(ui: Object) -> void:
	_hide_legacy_command_panel(ui)
	var hud_root: Control = _get_property(ui, "runtime_hud_root") as Control
	if hud_root == null or not is_instance_valid(hud_root) or not hud_root.visible:
		_request_runtime_hud_rebuild(ui)
		return
	var bottom_left: Control = hud_root.get_node_or_null("RuntimeBottomLeft") as Control
	var controls_panel: Control = null
	var stats_strip: Control = null
	if bottom_left != null and is_instance_valid(bottom_left):
		controls_panel = bottom_left.get_node_or_null("RuntimeControlsPanel") as Control
		stats_strip = bottom_left.get_node_or_null("RuntimeStatsStrip") as Control
	var energy_label: Label = _get_property(ui, "runtime_energy_label") as Label
	var actions_label: Label = _get_property(ui, "runtime_actions_label") as Label
	var base_controls: Control = _get_property(ui, "runtime_base_controls_grid") as Control
	var needs_rebuild: bool = bottom_left == null or not is_instance_valid(bottom_left) or controls_panel == null or not is_instance_valid(controls_panel) or stats_strip == null or not is_instance_valid(stats_strip) or energy_label == null or not is_instance_valid(energy_label) or actions_label == null or not is_instance_valid(actions_label) or base_controls == null or not is_instance_valid(base_controls)
	if needs_rebuild:
		_request_runtime_hud_rebuild(ui)
		return
	bottom_left.visible = true
	stats_strip.visible = true
	controls_panel.visible = true
	base_controls.visible = true
	bottom_left.mouse_filter = Control.MOUSE_FILTER_PASS
	stats_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	base_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	_show_runtime_buttons(ui)
	if ui.has_method("_refresh_runtime_mission_objective_label"):
		ui.call("_refresh_runtime_mission_objective_label")
	var bridge: Object = _get_property(ui, "runtime_action_panel_bridge") as Object
	if bridge != null and is_instance_valid(bridge) and bridge.has_method("refresh_controls"):
		bridge.call("refresh_controls")


func _request_runtime_hud_rebuild(ui: Object) -> void:
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_rebuild_msec < REBUILD_COOLDOWN_MS:
		return
	_last_rebuild_msec = now_msec
	if ui.has_method("_apply_runtime_hud_layout"):
		ui.call("_apply_runtime_hud_layout")
	if ui.has_method("_set_gameplay_visible"):
		ui.call("_set_gameplay_visible", true)
	if ui.has_method("_attach_runtime_gameplay_view"):
		ui.call_deferred("_attach_runtime_gameplay_view")
	if ui.has_method("_refresh_runtime_mission_objective_label"):
		ui.call_deferred("_refresh_runtime_mission_objective_label")
	if ui.has_method("_refresh_runtime_interaction_controls"):
		ui.call_deferred("_refresh_runtime_interaction_controls")


func _show_runtime_buttons(ui: Object) -> void:
	for property_name in ["runtime_move_forward_button", "runtime_move_backward_button", "runtime_turn_left_button", "runtime_turn_right_button", "runtime_action_button", "runtime_connect_button", "runtime_heavy_claw_button", "runtime_cut_button", "runtime_end_turn_button"]:
		var button: Button = _get_property(ui, property_name) as Button
		if button != null and is_instance_valid(button):
			button.visible = true
			button.mouse_filter = Control.MOUSE_FILTER_STOP


func _hide_legacy_command_panel(ui: Object) -> void:
	var command_panel: Control = _get_property(ui, "command_panel") as Control
	if command_panel != null and is_instance_valid(command_panel):
		command_panel.visible = false
		command_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
