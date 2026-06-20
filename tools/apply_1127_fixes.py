#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8")


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return content.replace(old, new, 1)


def sub_once(content: str, pattern: str, repl: str, label: str, flags: int = re.S) -> str:
    result, count = re.subn(pattern, repl, content, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one regex match, found {count}")
    return result


def inject_after_function_signature(content: str, function_name: str, line: str) -> str:
    pattern = rf"(func {re.escape(function_name)}\([^\n]*\)(?: -> [^:\n]+)?:\n)"
    match = re.search(pattern, content)
    if match is None:
        raise RuntimeError(f"missing function {function_name}")
    block_end = content.find("\nfunc ", match.end())
    if block_end == -1:
        block_end = len(content)
    if line.strip() in content[match.start():block_end]:
        return content
    return content[:match.end()] + line + content[match.end():]


def patch_preview_class(content: str, class_name: str, group_name: str) -> str:
    pattern = re.compile(
        rf"(class {re.escape(class_name)}:\n.*?\tfunc _ready\(\) -> void:\n\t\tset_anchors_and_offsets_preset\(Control\.PRESET_FULL_RECT\))\n\n\tfunc request_refresh\(\)",
        re.S,
    )
    match = pattern.search(content)
    if match is None:
        raise RuntimeError(f"missing preview class ready block: {class_name}")
    replacement = (
        match.group(1)
        + f'\n\t\tadd_to_group("{group_name}")'
        + "\n\t\tresized.connect(request_refresh)"
        + "\n\t\tvisibility_changed.connect(request_refresh)"
        + "\n\t\trequest_refresh()"
        + "\n\n\tfunc request_refresh()"
    )
    return content[:match.start()] + replacement + content[match.end():]


# ---------------------------------------------------------------------------
# GameUI lifecycle, invalidation, previews, and notification timeout.
# ---------------------------------------------------------------------------
game_path = "scripts/ui/game_ui.gd"
game = read(game_path)

for class_name, group_name in [
    ("InternalIsoPreviewControl", "game_ui_internal_preview"),
    ("SelectedModuleMiniPreviewControl", "game_ui_selected_module_preview"),
    ("ConstructorValidationOverlayControl", "game_ui_validation_overlay_preview"),
]:
    game = patch_preview_class(game, class_name, group_name)

helpers = '''

func _request_preview_group_refresh(group_name: StringName) -> void:
	if get_tree() == null:
		return
	for preview_node in get_tree().get_nodes_in_group(group_name):
		if preview_node != null and is_instance_valid(preview_node) and preview_node.has_method("request_refresh"):
			preview_node.call("request_refresh")


func request_internal_preview_refresh(_reason: String = "state_changed") -> void:
	_request_preview_group_refresh(&"game_ui_internal_preview")


func request_selected_module_preview_refresh(_reason: String = "state_changed") -> void:
	_request_preview_group_refresh(&"game_ui_selected_module_preview")


func request_constructor_validation_overlay_refresh(_reason: String = "state_changed") -> void:
	_request_preview_group_refresh(&"game_ui_validation_overlay_preview")


func request_constructor_previews_refresh(reason: String = "state_changed") -> void:
	request_internal_preview_refresh(reason)
	request_selected_module_preview_refresh(reason)
	request_constructor_validation_overlay_refresh(reason)


func _refresh_map_constructor_inspector_structure() -> void:
	MapConstructorInspectorStructureRef.apply_from_ui(self)
'''
marker = "\nfunc _initialize_runtime_hud() -> void:\n"
if marker not in game:
    raise RuntimeError("missing runtime HUD lifecycle marker")
game = game.replace(marker, helpers + marker, 1)

lifecycle = '''func _initialize_runtime_hud() -> void:
	if runtime_hud_initialized and runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		_set_runtime_hud_visible(true)
		request_runtime_hud_refresh("runtime_hud_reused")
		request_constructor_previews_refresh("runtime_hud_reused")
		return
	_apply_runtime_hud_layout()
	runtime_hud_initialized = true
	_set_runtime_hud_visible(true)
	request_runtime_hud_refresh("runtime_hud_created")
	request_constructor_previews_refresh("runtime_hud_created")


func request_runtime_hud_refresh(reason: String = "state_changed") -> void:
	if runtime_hud_refresh_pending:
		return
	runtime_hud_refresh_pending = true
	call_deferred("_refresh_runtime_hud_from_state", reason)


func _refresh_runtime_hud_from_state(_reason: String = "state_changed") -> void:
	runtime_hud_refresh_pending = false
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	if not runtime_hud_initialized or runtime_hud_root == null or not is_instance_valid(runtime_hud_root):
		return
	_refresh_runtime_mission_objective_label()
	_refresh_runtime_interaction_controls()


func _set_runtime_hud_visible(visible_state: bool) -> void:
	if command_panel != null:
		command_panel.visible = false
		command_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		runtime_hud_root.visible = visible_state


func _restore_persistent_runtime_buttons_to_command_panel() -> void:
	if command_panel == null or not is_instance_valid(command_panel):
		return
	var command_list: Node = command_panel.get_node_or_null("CommandList")
	if command_list == null:
		return
	for button in [restart_mission_button, return_to_box_button, settings_button, exit_main_menu_button]:
		if button != null and is_instance_valid(button):
			_safe_reparent_control(button, command_list)


func _clear_runtime_hud_bindings() -> void:
	runtime_mission_field_host = null
	runtime_bipob_switcher_panel = null
	runtime_menu_button = null
	runtime_menu_overlay = null
	runtime_pocket_flyout = null
	runtime_storage_flyout = null
	runtime_storage_panel = null
	runtime_storage_panel_body = null
	runtime_storage_collapse_button = null
	runtime_energy_label = null
	runtime_actions_label = null
	runtime_info_actions_label = null
	mission_goal_value_label = null
	runtime_notification_label = null
	runtime_notification_panel = null
	runtime_terminal_response_panel = null
	runtime_terminal_response_label = null
	runtime_base_controls_grid = null
	runtime_interaction_actions_row = null
	runtime_move_forward_button = null
	runtime_move_backward_button = null
	runtime_turn_left_button = null
	runtime_turn_right_button = null
	runtime_action_button = null
	runtime_connect_button = null
	runtime_heavy_claw_button = null
	runtime_cut_button = null
	runtime_end_turn_button = null
	runtime_world_actions_panel = null
	runtime_world_actions_target_label = null
	runtime_world_actions_state_label = null
	runtime_world_actions_behavior_label = null
	runtime_world_actions_list = null
	runtime_world_actions_no_actions_label = null
	runtime_world_actions_selected_button = null
	runtime_manipulator_content_label = null
	runtime_buffer_content_label = null
	runtime_key_summary_label = null
	runtime_pocket_title_label = null
	runtime_digital_title_label = null
	runtime_digital_store_title_label = null
	runtime_object_info_panel = null
	runtime_map_constructor_palette_panel = null
	runtime_map_constructor_inspector_panel = null
	runtime_map_constructor_inspector_scroll = null
	runtime_map_constructor_overview_hud_panel = null
	runtime_map_constructor_overview_hud_scroll = null
	runtime_map_constructor_validation_overlay_control = null
	runtime_map_constructor_place_confirm_panel = null
	runtime_mission_bipob_cards.clear()
	runtime_manipulator_slots.clear()
	runtime_pocket_slots.clear()
	runtime_digital_slots.clear()
	runtime_pocket_take_buttons.clear()
	runtime_digital_load_buttons.clear()
	runtime_key_slots.clear()
	runtime_interaction_actions_signature = ""
	last_world_action_target_id = ""
	last_world_action_actions_key = ""
	last_world_action_selected = ""
	last_world_action_state_key = ""
	runtime_selected_interaction_target.clear()


func _teardown_runtime_hud() -> void:
	runtime_hud_initialized = false
	runtime_hud_refresh_pending = false
	runtime_notification_timer = 0.0
	if runtime_notification_tween != null:
		runtime_notification_tween.kill()
	runtime_notification_tween = null
	if runtime_notification_timeout != null and is_instance_valid(runtime_notification_timeout):
		runtime_notification_timeout.stop()
	_restore_persistent_runtime_buttons_to_command_panel()
	if runtime_hud_root != null and is_instance_valid(runtime_hud_root):
		remove_child(runtime_hud_root)
		runtime_hud_root.queue_free()
	runtime_hud_root = null
	_clear_runtime_hud_bindings()


func _relayout_runtime_hud() -> void:
	if not runtime_hud_initialized or runtime_hud_root == null or not is_instance_valid(runtime_hud_root):
		return
	_apply_runtime_hud_layout()
	_set_runtime_hud_visible(true)
	request_runtime_hud_refresh("viewport_resized")
	request_constructor_previews_refresh("viewport_resized")


func explicit_rebuild_runtime_hud() -> void:
	_teardown_runtime_hud()
	_initialize_runtime_hud()


func _apply_runtime_hud_layout'''
game = sub_once(
    game,
    r"func _initialize_runtime_hud\(\) -> void:\n.*?\n\nfunc _apply_runtime_hud_layout",
    lifecycle,
    "replace runtime HUD lifecycle",
)

notification_block = '''func _ensure_runtime_notification_timeout() -> void:
	if runtime_notification_timeout != null and is_instance_valid(runtime_notification_timeout):
		return
	runtime_notification_timeout = Timer.new()
	runtime_notification_timeout.name = "RuntimeNotificationTimeout"
	runtime_notification_timeout.one_shot = true
	runtime_notification_timeout.wait_time = 7.0
	add_child(runtime_notification_timeout)
	runtime_notification_timeout.timeout.connect(_on_runtime_notification_timeout)


func _restart_runtime_notification_timeout(duration: float = 7.0) -> void:
	_ensure_runtime_notification_timeout()
	if runtime_notification_tween != null:
		runtime_notification_tween.kill()
	runtime_notification_tween = null
	if runtime_notification_timeout != null and is_instance_valid(runtime_notification_timeout):
		runtime_notification_timeout.stop()
	if duration <= 0.0:
		_on_runtime_notification_timeout()
		return
	runtime_notification_timer = duration
	if runtime_notification_timeout != null and is_instance_valid(runtime_notification_timeout):
		runtime_notification_timeout.start(duration)
	if runtime_notification_label != null and is_instance_valid(runtime_notification_label):
		runtime_notification_tween = create_tween()
		runtime_notification_tween.set_loops()
		runtime_notification_tween.tween_property(runtime_notification_label, "modulate", Color(1, 1, 1, 0.70), 0.35)
		runtime_notification_tween.tween_property(runtime_notification_label, "modulate", Color.WHITE, 0.35)


func _on_runtime_notification_timeout() -> void:
	runtime_notification_timer = 0.0
	if runtime_notification_tween != null:
		runtime_notification_tween.kill()
	runtime_notification_tween = null
	_refresh_runtime_notification_fallback()


func _refresh_runtime_notification_fallback'''
game = sub_once(
    game,
    r"func _ensure_runtime_notification_timeout\(\) -> void:\n.*?\nfunc _refresh_runtime_notification_fallback",
    notification_block,
    "replace notification timeout lifecycle",
)

# Startup must not build and immediately destroy the runtime HUD.
game = replace_once(
    game,
    '\n\t_initialize_runtime_hud()\n\tcall_deferred("_attach_runtime_gameplay_view")\n\t_assert_single_active_major_screen()\n',
    '\n\t_assert_single_active_major_screen()\n',
    "remove startup HUD build",
)

# Leaving gameplay hides the HUD. Runtime destruction owns the destructive teardown.
game = replace_once(
    game,
    '\tif not visible_state:\n\t\t_hide_runtime_mission_ui()\n\t\t_teardown_runtime_hud()\n',
    '\tif not visible_state:\n\t\t_hide_runtime_mission_ui()\n\t\t_set_runtime_hud_visible(false)\n',
    "hide HUD on gameplay exit",
)
game = replace_once(
    game,
    'func _destroy_gameplay_runtime() -> void:\n\t_deactivate_map_constructor_mode()\n',
    'func _destroy_gameplay_runtime() -> void:\n\t_deactivate_map_constructor_mode()\n\t_teardown_runtime_hud()\n',
    "teardown HUD with runtime",
)

# Resize is an explicit one-shot relayout event, not an initialization no-op.
game = replace_once(
    game,
    '\tif runtime_hud_root != null and is_instance_valid(runtime_hud_root) and runtime_hud_root.visible:\n\t\t_initialize_runtime_hud()\n\t\tcall_deferred("_attach_runtime_gameplay_view")\n',
    '\tif runtime_hud_root != null and is_instance_valid(runtime_hud_root) and runtime_hud_root.visible:\n\t\t_relayout_runtime_hud()\n\t\tcall_deferred("_attach_runtime_gameplay_view")\n\trequest_constructor_previews_refresh("viewport_resized")\n',
    "viewport HUD relayout",
)

# Restore gameplay mode before HUD initialization when returning from a placeholder.
game = replace_once(
    game,
    '\t\tAppScreenMode.GAMEPLAY:\n\t\t\t_hide_all_app_screens()\n\t\t\t_initialize_runtime_hud()\n\t\t\t_set_gameplay_visible(true)\n\t\t\tcall_deferred("_attach_runtime_gameplay_view")\n\t\t\tapp_screen_mode = AppScreenMode.GAMEPLAY\n',
    '\t\tAppScreenMode.GAMEPLAY:\n\t\t\tapp_screen_mode = AppScreenMode.GAMEPLAY\n\t\t\t_hide_all_app_screens()\n\t\t\t_initialize_runtime_hud()\n\t\t\t_set_gameplay_visible(true)\n\t\t\tcall_deferred("_attach_runtime_gameplay_view")\n',
    "placeholder gameplay return order",
)

# Remove the now-empty frame bridge path entirely.
game = replace_once(game, '\t_process_runtime_interaction_feedback(delta)\n', '', "remove frame feedback call")
game = sub_once(
    game,
    r"\nfunc _process_runtime_interaction_feedback\(_delta: float\) -> void:\n.*?(?=\nfunc set_runtime_selected_interaction_target)",
    "\n",
    "remove frame feedback wrapper",
)

# Central event routes for gameplay and constructor changes.
game = inject_after_function_signature(game, "update_status", '\trequest_runtime_hud_refresh("status_updated")\n')
game = inject_after_function_signature(game, "update_box_status", '\trequest_constructor_previews_refresh("box_status_updated")\n')

game = replace_once(
    game,
    'func _refresh_constructor_readiness_result() -> Dictionary:\n\tlatest_constructor_readiness_result = RuntimeReadinessServiceRef.evaluate_constructor(bipob).duplicate(true)\n\treturn latest_constructor_readiness_result\n',
    'func _refresh_constructor_readiness_result() -> Dictionary:\n\tlatest_constructor_readiness_result = RuntimeReadinessServiceRef.evaluate_constructor(bipob).duplicate(true)\n\trequest_constructor_previews_refresh("readiness_changed")\n\treturn latest_constructor_readiness_result\n',
    "readiness preview invalidation",
)

game = replace_once(
    game,
    'func _refresh_map_constructor_panels() -> void:\n\tMapConstructorScreenRef.refresh(self)\n\t_refresh_map_constructor_overview_hud()\n',
    'func _refresh_map_constructor_panels() -> void:\n\tMapConstructorScreenRef.refresh(self)\n\t_refresh_map_constructor_inspector_structure()\n\trequest_constructor_previews_refresh("map_constructor_panels")\n\t_refresh_map_constructor_overview_hud()\n',
    "map constructor explicit invalidation",
)

game = replace_once(
    game,
    'func _show_map_constructor_inspector(cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> void:\n\tMapConstructorInspectorRef.refresh(self, cell, preferred_entity_kind, preferred_entity_id)\n\tMapConstructorInspectorStructureRef.apply_from_ui(self)\n',
    'func _show_map_constructor_inspector(cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> void:\n\tMapConstructorInspectorRef.refresh(self, cell, preferred_entity_kind, preferred_entity_id)\n\t_refresh_map_constructor_inspector_structure()\n\trequest_constructor_previews_refresh("inspector_selection_changed")\n',
    "inspector selection invalidation",
)

game = replace_once(
    game,
    'func _on_runtime_bipob_status_changed() -> void:\n\trequest_runtime_hud_refresh("status_changed")\n\t_refresh_constructor_readiness_result()\n',
    'func _on_runtime_bipob_status_changed() -> void:\n\trequest_runtime_hud_refresh("status_changed")\n\t_refresh_constructor_readiness_result()\n\tif map_constructor_state.map_constructor_mode_active:\n\t\t_refresh_map_constructor_inspector_structure()\n',
    "runtime status inspector invalidation",
)

write(game_path, game)

# ---------------------------------------------------------------------------
# Runtime notification owner: route the real autoload path into the one-shot timer.
# ---------------------------------------------------------------------------
layer_path = "scripts/ui/runtime/runtime_notification_layer.gd"
layer = read(layer_path)
layer = sub_once(
    layer,
    r"\nfunc process_runtime_notification_timer\(ui_owner: Object, delta: float\) -> void:\n.*?(?=\nfunc refresh_runtime_notification_fallback)",
    "\n",
    "remove notification frame timer",
)
layer = replace_once(
    layer,
    '\tif _object_has_property(ui_owner, "runtime_notification_role"):\n\t\tui_owner.set("runtime_notification_role", kind)\n',
    '\tif _object_has_property(ui_owner, "runtime_notification_role"):\n\t\tui_owner.set("runtime_notification_role", kind)\n\tif ui_owner.has_method("_restart_runtime_notification_timeout"):\n\t\tui_owner.call("_restart_runtime_notification_timeout", maxf(duration, 0.0))\n',
    "connect active notification path",
)
write(layer_path, layer)

legacy_notifications_path = "scripts/ui/runtime/runtime_notifications.gd"
legacy_notifications = read(legacy_notifications_path)
legacy_notifications = sub_once(
    legacy_notifications,
    r"\nstatic func process_runtime_notification_timer\(_ui, _delta: float\) -> void:\n.*?(?=\nstatic func refresh_runtime_notification_fallback)",
    "\n",
    "remove legacy no-op frame timer",
)
legacy_notifications = legacy_notifications.replace(
    'ui.call("_restart_runtime_notification_timeout")',
    'ui.call("_restart_runtime_notification_timeout", 7.0)',
)
write(legacy_notifications_path, legacy_notifications)

# ---------------------------------------------------------------------------
# Remove the empty per-frame bridge method.
# ---------------------------------------------------------------------------
bridge_path = "scripts/ui/runtime/runtime_action_panel_bridge.gd"
bridge = read(bridge_path)
bridge = sub_once(
    bridge,
    r"\nfunc process_feedback\(_delta: float\) -> void:\n.*?(?=\nfunc on_move_forward_pressed)",
    "\n",
    "remove empty process_feedback",
)
write(bridge_path, bridge)

# ---------------------------------------------------------------------------
# Inspector property writes explicitly re-apply structure once.
# ---------------------------------------------------------------------------
inspector_path = "scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd"
inspector = read(inspector_path)
inspector = replace_once(
    inspector,
    '\tif ui.has_method("_apply_map_constructor_property_updates"):\n\t\tui.call("_apply_map_constructor_property_updates", entity_kind, entity_id, updates, hint_text)\n\t\treturn\n',
    '\tif ui.has_method("_apply_map_constructor_property_updates"):\n\t\tui.call("_apply_map_constructor_property_updates", entity_kind, entity_id, updates, hint_text)\n\t\tif ui.has_method("_refresh_map_constructor_inspector_structure"):\n\t\t\tui.call("_refresh_map_constructor_inspector_structure")\n\t\tif ui.has_method("request_constructor_previews_refresh"):\n\t\t\tui.call("request_constructor_previews_refresh", "inspector_property_updated")\n\t\treturn\n',
    "inspector property invalidation",
)
write(inspector_path, inspector)

# ---------------------------------------------------------------------------
# Stronger static audit.
# ---------------------------------------------------------------------------
static_audit = r'''#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def expect(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

def function_block(source: str, name: str) -> str:
    match = re.search(rf"func {re.escape(name)}\([^\n]*\)(?: -> [^:\n]+)?:\n", source)
    if match is None:
        return ""
    end = source.find("\nfunc ", match.end())
    return source[match.start(): end if end != -1 else len(source)]

project = text("project.godot")
expect("RuntimeHudRepair" not in project, "RuntimeHudRepair autoload remains")
expect("MapConstructorInspectorStructure=" not in project, "MapConstructorInspectorStructure autoload remains")
expect(not (ROOT / "scripts/ui/runtime/runtime_hud_repair_service.gd").exists(), "runtime HUD repair service still exists")

inspector = text("scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd")
for token in ["func _process", "CHECK_INTERVAL", "get_tree(", "current_scene"]:
    expect(token not in inspector, f"inspector contains forbidden polling token: {token}")
expect("static func apply_structure" in inspector and "static func apply_from_ui" in inspector, "inspector explicit API missing")
expect("_refresh_map_constructor_inspector_structure" in inspector, "inspector property update does not request explicit structure refresh")

bridge = text("scripts/ui/runtime/runtime_action_panel_bridge.gd")
expect("func process_feedback" not in bridge, "empty/per-frame process_feedback remains")
expect("process_runtime_notification_timer" not in bridge, "bridge still owns notification timer")

game = text("scripts/ui/game_ui.gd")
process_block = function_block(game, "_process")
expect("_process_runtime_interaction_feedback" not in process_block, "GameUI._process still calls runtime interaction feedback")
expect("func _process_runtime_interaction_feedback" not in game, "runtime interaction frame wrapper remains")
expect("func _relayout_runtime_hud" in game, "explicit HUD relayout missing")
expect("_relayout_runtime_hud()" in function_block(game, "_on_viewport_size_changed"), "viewport resize does not relayout HUD")
expect("_initialize_runtime_hud()" not in function_block(game, "_ready"), "startup still builds runtime HUD")
expect("_teardown_runtime_hud()" in function_block(game, "_destroy_gameplay_runtime"), "runtime destruction does not teardown HUD")
expect("_set_runtime_hud_visible(false)" in function_block(game, "_set_gameplay_visible"), "gameplay exit does not hide HUD explicitly")
expect("_bind_runtime_hud_signals" not in game, "decorative HUD signal hook remains")
expect("_restore_persistent_runtime_buttons_to_command_panel" in game, "persistent HUD buttons are not preserved on teardown")
expect("_clear_runtime_hud_bindings" in game, "HUD bindings are not explicitly cleared")
expect("request_runtime_hud_refresh(\"status_updated\")" in function_block(game, "update_status"), "status update does not invalidate HUD")
expect("request_constructor_previews_refresh" in function_block(game, "update_box_status"), "box changes do not invalidate previews")
expect("_refresh_map_constructor_inspector_structure" in function_block(game, "_refresh_map_constructor_panels"), "constructor panel refresh does not update inspector structure")
expect("request_constructor_previews_refresh" in function_block(game, "_refresh_map_constructor_panels"), "constructor panel refresh does not redraw previews")
for group in ["game_ui_internal_preview", "game_ui_selected_module_preview", "game_ui_validation_overlay_preview"]:
    expect(group in game, f"preview invalidation group missing: {group}")
expect("resized.connect(request_refresh)" in game and "visibility_changed.connect(request_refresh)" in game, "preview resize/visibility invalidation missing")

notification_layer = text("scripts/ui/runtime/runtime_notification_layer.gd")
expect("process_runtime_notification_timer" not in notification_layer, "active notification layer still contains frame timer")
expect('ui_owner.call("_restart_runtime_notification_timeout", maxf(duration, 0.0))' in notification_layer, "active notification path does not pass duration to one-shot timer")
expect("func _restart_runtime_notification_timeout(duration: float" in game, "GameUI notification timeout does not accept duration")
expect("runtime_notification_timeout.start(duration)" in game, "notification Timer ignores supplied duration")
expect("runtime_notification_timeout.one_shot = true" in game, "notification Timer is not one-shot")

presenter = text("scripts/ui/runtime/runtime_interaction_presenter.gd")
world_panel = re.search(r"static func refresh_world_actions_panel[\s\S]*?(?=\n\nstatic func |\Z)", presenter)
expect(world_panel is not None, "world actions presenter missing")
if world_panel:
    for token in ["_ensure_runtime_world_actions_panel", "_build_runtime_world_actions_panel"]:
        expect(token not in world_panel.group(0), f"world actions refresh still rebuilds via {token}")

workflow = text(".github/workflows/godot-parser-gate.yml")
expect("python tools/check_runtime_readiness_service.py" in workflow, "readiness static audit no longer active")
expect("python tools/check_event_driven_runtime_hud.py" in workflow, "event-driven static audit not wired")
expect("check_event_driven_runtime_hud.gd" in workflow, "event-driven Godot gate not wired")

if errors:
    print("Event-driven runtime HUD audit FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("Event-driven runtime HUD audit OK")
'''
write("tools/check_event_driven_runtime_hud.py", static_audit)

# ---------------------------------------------------------------------------
# Executable behavior gate: real notification routing, coalescing, Timer, and
# production inspector presenter behavior plus production-source invariants.
# ---------------------------------------------------------------------------
behavior_gate = r'''extends SceneTree

const RuntimeNotificationLayerRef = preload("res://scripts/ui/runtime/runtime_notification_layer.gd")
const InspectorStructureRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd")

class FakeNotificationUI:
	extends Node
	var hint_label: Label = Label.new()
	var runtime_notification_label: Label = Label.new()
	var runtime_notification_panel: PanelContainer = PanelContainer.new()
	var runtime_notification_timer: float = 0.0
	var runtime_notification_role: String = "neutral"
	var restart_count: int = 0
	var last_duration: float = -1.0

	func _init() -> void:
		add_child(hint_label)
		add_child(runtime_notification_label)
		add_child(runtime_notification_panel)

	func _restart_runtime_notification_timeout(duration: float) -> void:
		restart_count += 1
		last_duration = duration

	func _get_runtime_secondary_objective_text() -> String:
		return "Fallback objective"


class RefreshCoalescer:
	extends Node
	var pending: bool = false
	var refresh_count: int = 0

	func request_refresh() -> void:
		if pending:
			return
		pending = true
		call_deferred("_flush")

	func _flush() -> void:
		pending = false
		refresh_count += 1


class FakeInspectorUI:
	extends Node

	func _create_inspector_section(title: String) -> VBoxContainer:
		var section := VBoxContainer.new()
		var title_label := Label.new()
		title_label.text = title
		section.add_child(title_label)
		return section

	func _create_property_row(label_text: String, control: Control) -> Control:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		row.add_child(label)
		row.add_child(control)
		return row


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _run() -> void:
	var ok: bool = true
	ok = _test_notification_route() and ok
	ok = await _test_deferred_coalescing() and ok
	ok = await _test_one_shot_timer() and ok
	ok = _test_inspector_presenter() and ok
	ok = _test_production_source_contract() and ok
	if ok:
		print("check_event_driven_runtime_hud: OK")
		quit(0)
	else:
		push_error("check_event_driven_runtime_hud: FAILED")
		quit(1)


func _test_notification_route() -> bool:
	var layer := RuntimeNotificationLayerRef.new()
	var ui := FakeNotificationUI.new()
	root.add_child(layer)
	root.add_child(ui)
	layer.show_hint(ui, "Event-driven notification", RuntimeNotificationLayerRef.KIND_SYSTEM, 0.125)
	var ok := _expect(ui.restart_count == 1, "active notification route must restart one timeout")
	ok = _expect(is_equal_approx(ui.last_duration, 0.125), "notification route must preserve duration") and ok
	ok = _expect(ui.runtime_notification_label.text == "Event-driven notification", "notification text must update immediately") and ok
	layer.queue_free()
	ui.queue_free()
	return ok


func _test_deferred_coalescing() -> bool:
	var coalescer := RefreshCoalescer.new()
	root.add_child(coalescer)
	coalescer.request_refresh()
	coalescer.request_refresh()
	coalescer.request_refresh()
	var before_ok := _expect(coalescer.refresh_count == 0, "coalesced refresh must be deferred")
	await process_frame
	var after_ok := _expect(coalescer.refresh_count == 1, "multiple invalidations must coalesce to one refresh")
	coalescer.queue_free()
	return before_ok and after_ok


func _test_one_shot_timer() -> bool:
	var timer := Timer.new()
	timer.one_shot = true
	var timeout_count := [0]
	timer.timeout.connect(func() -> void: timeout_count[0] += 1)
	root.add_child(timer)
	timer.start(0.01)
	await create_timer(0.06).timeout
	var ok := _expect(timeout_count[0] == 1, "one-shot notification Timer must fire exactly once")
	ok = _expect(timer.is_stopped(), "one-shot notification Timer must stop after timeout") and ok
	timer.queue_free()
	return ok


func _test_inspector_presenter() -> bool:
	var ui := FakeInspectorUI.new()
	var content := VBoxContainer.new()
	root.add_child(ui)
	ui.add_child(content)
	var data := {"display_name":"Door A", "description":"Test", "object_type":"door", "object_power_state":"powered", "object_total_state":"ready"}
	InspectorStructureRef.apply_structure(ui, content, "world_object", "door_a", data)
	InspectorStructureRef.apply_structure(ui, content, "world_object", "door_a", data)
	var identity_count: int = 0
	var status_count: int = 0
	for child in content.get_children():
		if str(child.name) == "SharedIdentitySection":
			identity_count += 1
		elif str(child.name) == "SharedStatusSection":
			status_count += 1
	var ok := _expect(identity_count == 1, "inspector identity section must remain singular")
	ok = _expect(status_count == 1, "inspector status section must remain singular") and ok
	ui.queue_free()
	return ok


func _test_production_source_contract() -> bool:
	var game := _read("res://scripts/ui/game_ui.gd")
	var bridge := _read("res://scripts/ui/runtime/runtime_action_panel_bridge.gd")
	var layer := _read("res://scripts/ui/runtime/runtime_notification_layer.gd")
	var ok := _expect(not bridge.contains("func process_feedback"), "runtime bridge must have no frame feedback method")
	ok = _expect(not game.contains("func _process_runtime_interaction_feedback"), "GameUI must have no frame feedback wrapper") and ok
	ok = _expect(game.contains("func _relayout_runtime_hud"), "GameUI must expose explicit relayout") and ok
	ok = _expect(game.contains("request_constructor_previews_refresh"), "GameUI must expose preview invalidation") and ok
	ok = _expect(game.contains("_restore_persistent_runtime_buttons_to_command_panel"), "teardown must preserve persistent buttons") and ok
	ok = _expect(layer.contains("_restart_runtime_notification_timeout\", maxf(duration, 0.0)"), "active notification path must start timeout") and ok
	return ok
'''
write("tools/ci/check_event_driven_runtime_hud.gd", behavior_gate)

print("apply_1127_fixes: patched files successfully")
