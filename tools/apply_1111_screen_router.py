#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GAME_PATH = ROOT / "scripts/ui/game_ui.gd"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one match, found {count}")
    return content.replace(old, new, 1)


def sub_once(content: str, pattern: str, repl: str, label: str, flags: int = re.S) -> str:
    result, count = re.subn(pattern, repl, content, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"{label}: expected one regex match, found {count}")
    return result


game = read(GAME_PATH)

# Preload and state.
game = replace_once(
    game,
    'const RuntimeReadinessServiceRef = preload("res://scripts/game/runtime_readiness_service.gd")\n',
    'const RuntimeReadinessServiceRef = preload("res://scripts/game/runtime_readiness_service.gd")\nconst ScreenRouterRef = preload("res://scripts/ui/navigation/screen_router.gd")\n',
    "ScreenRouter preload",
)
game = replace_once(
    game,
    'var app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU\n',
    'var app_screen_mode: AppScreenMode = AppScreenMode.MAIN_MENU\nvar screen_router: ScreenRouter = null\n',
    "ScreenRouter state",
)

router_block = r'''func _setup_screen_router() -> void:
	if screen_router != null:
		return
	screen_router = ScreenRouterRef.new(self)
	screen_router.register_screen(ScreenRouterRef.SCREEN_MAIN_MENU, Callable(self, "_screen_factory_main_menu"), Callable(self, "_screen_enter_main_menu"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_CENTER, Callable(self, "_screen_factory_center"), Callable(self, "_screen_enter_center"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_TASKS, Callable(self, "_screen_factory_tasks"), Callable(self, "_screen_enter_tasks"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_GAMEPLAY, Callable(self, "_screen_factory_gameplay"), Callable(self, "_screen_enter_gameplay"), Callable(self, "_screen_exit_gameplay"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_BOX_CONSTRUCTOR, Callable(self, "_screen_factory_box"), Callable(self, "_screen_enter_box"), Callable(self, "_screen_exit_box"), Callable(self, "_screen_cleanup_box"), false)
	screen_router.register_screen(ScreenRouterRef.SCREEN_MISSION_CONSTRUCTOR, Callable(self, "_screen_factory_mission_constructor"), Callable(self, "_screen_enter_mission_constructor"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_MISSION_RESULT, Callable(self, "_screen_factory_mission_result"), Callable(self, "_screen_enter_mission_result"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_PLACEHOLDER, Callable(self, "_screen_factory_placeholder"), Callable(self, "_screen_enter_placeholder"))
	screen_router.register_screen(ScreenRouterRef.SCREEN_CHARGING, Callable(self, "_screen_factory_charging"), Callable(self, "_screen_enter_charging"), Callable(), Callable(self, "_screen_cleanup_charging"), false)
	screen_router.register_screen(ScreenRouterRef.SCREEN_REPAIR, Callable(self, "_screen_factory_repair"), Callable(self, "_screen_enter_repair"), Callable(), Callable(self, "_screen_cleanup_repair"), false)
	screen_router.register_screen(ScreenRouterRef.SCREEN_PROGRAMMER, Callable(self, "_screen_factory_programmer"), Callable(self, "_screen_enter_programmer"), Callable(), Callable(self, "_screen_cleanup_programmer"), false)


func _screen_router_restore_focus(screen_id: StringName, screen: Control, preferred_focus: Variant = null) -> void:
	if screen_router == null or screen_router.get_active_screen_id() != screen_id:
		return
	var target: Control = screen_router.resolve_focus_target(screen_id, screen, preferred_focus)
	if target != null and is_instance_valid(target):
		target.grab_focus()


func _navigate_back_or_center() -> void:
	if screen_router != null and screen_router.back():
		return
	show_center_screen()


func _clear_screen_root(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()


func _screen_factory_main_menu() -> Control:
	main_menu_root = _build_fullscreen_root("MainMenuRoot")
	_build_main_menu_layout()
	return main_menu_root


func _screen_factory_center() -> Control:
	center_menu_root = _build_fullscreen_root("CenterMenuRoot")
	_build_center_menu_layout()
	return center_menu_root


func _screen_factory_tasks() -> Control:
	tasks_menu_root = _build_fullscreen_root("TasksMenuRoot")
	_build_tasks_menu_layout()
	return tasks_menu_root


func _screen_factory_gameplay() -> Control:
	_initialize_runtime_hud()
	return runtime_hud_root


func _screen_factory_box() -> Control:
	box_menu_root = _build_fullscreen_root("BoxMenuRoot")
	return box_menu_root


func _screen_factory_mission_constructor() -> Control:
	mission_constructor_root = _build_fullscreen_root("MissionConstructorRoot")
	return mission_constructor_root


func _screen_factory_mission_result() -> Control:
	mission_result_root = _build_fullscreen_root("MissionResultRoot")
	return mission_result_root


func _screen_factory_placeholder() -> Control:
	placeholder_menu_root = _build_fullscreen_root("PlaceholderMenuRoot")
	_build_placeholder_layout()
	return placeholder_menu_root


func _screen_factory_charging() -> Control:
	charging_menu_root = _build_fullscreen_root("ChargingMenuRoot")
	return charging_menu_root


func _screen_factory_repair() -> Control:
	repair_menu_root = _build_fullscreen_root("RepairMenuRoot")
	return repair_menu_root


func _screen_factory_programmer() -> Control:
	programmer_menu_root = _build_fullscreen_root("ProgrammerMenuRoot")
	return programmer_menu_root


func _screen_enter_main_menu(_screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	_deactivate_map_constructor_mode()
	app_screen_mode = AppScreenMode.MAIN_MENU
	box_opened_from_center = false
	_hide_runtime_mission_ui()
	_set_gameplay_visible(false)
	_destroy_gameplay_runtime()
	_assert_single_active_major_screen()


func _screen_enter_center(_screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	_deactivate_map_constructor_mode()
	app_screen_mode = AppScreenMode.CENTER
	_hide_runtime_mission_ui()
	_set_gameplay_visible(false)
	CenterScreenRef.refresh(self)
	_assert_single_active_major_screen()


func _screen_enter_tasks(_screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.TASKS
	_set_gameplay_visible(false)
	_refresh_tasks_content()
	_assert_single_active_major_screen()


func _screen_enter_gameplay(_screen: Control, payload: Dictionary, repeated: bool) -> void:
	app_screen_mode = AppScreenMode.GAMEPLAY
	box_opened_from_center = false
	if not repeated and not bool(payload.get("preserve_profile", false)):
		_set_active_mission_bipob(0)
	_initialize_runtime_hud()
	_set_gameplay_visible(true)
	if bool(payload.get("start_mission", false)):
		_on_start_mission_button_pressed()
	call_deferred("_attach_runtime_gameplay_view")
	update_status()
	update_diagnostic_status()
	update_box_status()
	_assert_single_active_major_screen()


func _screen_exit_gameplay(_screen: Control, _payload: Dictionary) -> void:
	_hide_runtime_mission_ui()
	_set_gameplay_visible(false)


func _screen_enter_box(screen: Control, payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.BOX_CONSTRUCTOR
	box_opened_from_center = bool(payload.get("opened_from_center", false))
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_build_box_menu_layout()
	start_mission_warning_acknowledged = false
	if bool(payload.get("force_external", false)):
		box_menu_mode = BoxMenuMode.EXTERNAL
	update_box_status()
	_assert_single_active_major_screen()


func _screen_exit_box(_screen: Control, _payload: Dictionary) -> void:
	if bipob != null:
		_save_active_bipob_profile()


func _screen_enter_mission_constructor(screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.MISSION_CONSTRUCTOR
	box_opened_from_center = false
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_build_mission_constructor_screen()
	_assert_single_active_major_screen()


func _screen_enter_mission_result(screen: Control, payload: Dictionary, _repeated: bool) -> void:
	_deactivate_map_constructor_mode()
	app_screen_mode = AppScreenMode.MISSION_RESULT
	_hide_runtime_mission_ui()
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_present_mission_result(payload)
	_assert_single_active_major_screen()


func _screen_enter_placeholder(_screen: Control, payload: Dictionary, _repeated: bool) -> void:
	var mode_value: int = int(payload.get("mode", AppScreenMode.SETTINGS_PLACEHOLDER))
	app_screen_mode = mode_value as AppScreenMode
	_set_gameplay_visible(false)
	if placeholder_title_label != null:
		placeholder_title_label.text = str(payload.get("title", "Settings"))
	if placeholder_body_label != null:
		placeholder_body_label.text = str(payload.get("body", "This section will be added later."))
	_assert_single_active_major_screen()


func _screen_enter_charging(screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.CHARGING_MENU
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_build_charging_menu_layout()
	_assert_single_active_major_screen()


func _screen_enter_repair(screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.REPAIR_PLACEHOLDER
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_build_repair_menu_layout()
	_assert_single_active_major_screen()


func _screen_enter_programmer(screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	app_screen_mode = AppScreenMode.PROGRAMMER_MENU
	_set_gameplay_visible(false)
	_clear_screen_root(screen)
	_build_programmer_menu_layout()
	_assert_single_active_major_screen()


func _screen_cleanup_box(_screen: Control) -> void:
	box_menu_root = null
	box_top_bar_root = null
	box_constructor_content_root = null
	box_content_label = null
	right_button_panel = null


func _screen_cleanup_charging(_screen: Control) -> void:
	charging_menu_root = null


func _screen_cleanup_repair(_screen: Control) -> void:
	repair_menu_root = null


func _screen_cleanup_programmer(_screen: Control) -> void:
	programmer_menu_root = null
	programmer_message_label = null
'''

game = sub_once(
    game,
    r"func _create_app_menu_roots\(\) -> void:\n.*?(?=\nfunc _build_fullscreen_root)",
    router_block + "\n",
    "replace eager root creation",
)

navigation = r'''func navigate_to_screen(target_screen: AppScreenMode, payload: Dictionary = {}) -> void:
	match target_screen:
		AppScreenMode.MAIN_MENU:
			show_main_menu_screen()
		AppScreenMode.CENTER:
			show_center_screen()
		AppScreenMode.TASKS:
			show_tasks_screen()
		AppScreenMode.GAMEPLAY:
			start_gameplay_from_center()
		AppScreenMode.BOX_CONSTRUCTOR:
			show_box_constructor_from_center()
		AppScreenMode.MISSION_CONSTRUCTOR:
			show_mission_constructor_screen()
		AppScreenMode.MISSION_RESULT:
			show_mission_result_screen(bool(payload.get("success", false)), int(payload.get("mission_index", -1)))
		AppScreenMode.CHARGING_MENU:
			show_charging_menu()
		AppScreenMode.REPAIR_PLACEHOLDER:
			show_repair_menu()
		AppScreenMode.PROGRAMMER_MENU:
			show_programmer_menu()
		AppScreenMode.RESEARCH_PLACEHOLDER:
			show_placeholder_screen("Research", "This section will be added later.", AppScreenMode.RESEARCH_PLACEHOLDER)
		AppScreenMode.SHOP_PLACEHOLDER:
			show_placeholder_screen("Shop", "This section will be added later.", AppScreenMode.SHOP_PLACEHOLDER)
		AppScreenMode.SETTINGS_PLACEHOLDER:
			show_placeholder_screen("Settings", "This section will be added later.", AppScreenMode.SETTINGS_PLACEHOLDER)
		AppScreenMode.ABOUT_PLACEHOLDER:
			show_placeholder_screen("About", "This section will be added later.", AppScreenMode.ABOUT_PLACEHOLDER)
		_:
			show_center_screen()
'''

game = sub_once(
    game,
    r"func navigate_to_screen\(target_screen: AppScreenMode, payload: Dictionary = \{\}\) -> void:\n.*?(?=\nfunc _assert_single_active_major_screen)",
    navigation + "\n",
    "replace navigation dispatcher",
)

show_block = r'''func show_main_menu_screen() -> void:
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_MAIN_MENU)


func show_center_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_CENTER)


func show_tasks_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_TASKS)


func show_placeholder_screen(
	title_text: String,
	body_text: String = "This section will be added later.",
	placeholder_mode: AppScreenMode = AppScreenMode.SETTINGS_PLACEHOLDER
) -> void:
	previous_app_screen_mode = app_screen_mode
	placeholder_return_screen_mode = previous_app_screen_mode
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_PLACEHOLDER, {
		"title": title_text,
		"body": body_text,
		"mode": int(placeholder_mode),
	})


func start_gameplay_from_center() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_GAMEPLAY, {"start_mission": true})


func _enter_gameplay_screen_without_starting_mission() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_GAMEPLAY, {"start_mission": false})
'''

game = sub_once(
    game,
    r"func show_main_menu_screen\(\) -> void:\n.*?(?=\nfunc _get_active_runtime_task_mission_ids)",
    show_block + "\n",
    "replace core show methods",
)

result_block = r'''func show_box_constructor_from_center() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_BOX_CONSTRUCTOR, {"opened_from_center": true, "force_external": true})


func show_mission_constructor_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Mission constructor unavailable: gameplay runtime failed to load.")
		show_main_menu_screen()
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_MISSION_CONSTRUCTOR)


func _clear_children(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		child.queue_free()


func show_mission_result_screen(success: bool, mission_index: int = -1) -> void:
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_MISSION_RESULT, {"success": success, "mission_index": mission_index})


func _present_mission_result(payload: Dictionary) -> void:
	var success: bool = bool(payload.get("success", false))
	var mission_index: int = int(payload.get("mission_index", -1))
	last_mission_success = success
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
		progress["extra_goals"] = {"find_key": "TBD", "open_door": "TBD"}
		if str(progress.get("reward_claimed_text", "")).is_empty():
			progress["reward_claimed_text"] = "TBD"
		mission_progress[result_mission_id] = progress
	var layout: Control = _create_mission_result_layout(result_data)
	mission_result_root.add_child(layout)
'''

game = sub_once(
    game,
    r"func show_box_constructor_from_center\(\) -> void:\n.*?(?=\nfunc _refresh_tasks_content)",
    result_block + "\n",
    "replace constructor/result navigation",
)

# Builders now receive their registered root instead of creating top-level roots themselves.
game = replace_once(
    game,
    '''func _build_box_menu_layout() -> void:
	if box_menu_root != null and is_instance_valid(box_menu_root):
		box_menu_root.queue_free()
	box_menu_root = _build_fullscreen_root("BoxMenuRoot")
	add_child(box_menu_root)
''',
    '''func _build_box_menu_layout() -> void:
	if box_menu_root == null or not is_instance_valid(box_menu_root):
		return
''',
    "box root factory ownership",
)

game = sub_once(
    game,
    r"func show_charging_menu\(\) -> void:\n.*?(?=\nfunc _build_charging_menu_layout)",
    '''func show_charging_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_CHARGING)

''',
    "charging wrapper",
)

game = sub_once(
    game,
    r'''func show_programmer_menu\(\) -> void:\n\tif not _ensure_gameplay_runtime_created\(\):.*?\tadd_child\(programmer_menu_root\)\n''',
    '''func show_programmer_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_PROGRAMMER)


func _build_programmer_menu_layout() -> void:
	if programmer_menu_root == null or not is_instance_valid(programmer_menu_root):
		return
''',
    "programmer wrapper and builder",
)
game = game.replace('\t_refresh_programmer_menu()\n\t_assert_single_active_major_screen()\n\nfunc _refresh_programmer_menu', '\t_refresh_programmer_menu()\n\nfunc _refresh_programmer_menu', 1)

game = sub_once(
    game,
    r'''func show_repair_menu\(\) -> void:\n\tif not _ensure_gameplay_runtime_created\(\):.*?\tadd_child\(repair_menu_root\)\n''',
    '''func show_repair_menu() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.push(ScreenRouterRef.SCREEN_REPAIR)


func _build_repair_menu_layout() -> void:
	if repair_menu_root == null or not is_instance_valid(repair_menu_root):
		return
''',
    "repair wrapper and builder",
)
game = game.replace('\t_refresh_repair_menu()\n\t_assert_single_active_major_screen()\n\nfunc _refresh_repair_menu', '\t_refresh_repair_menu()\n\nfunc _refresh_repair_menu', 1)

box_nav = r'''func show_box_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		show_hint("Gameplay runtime is unavailable.")
		return
	_setup_screen_router()
	screen_router.replace(ScreenRouterRef.SCREEN_BOX_CONSTRUCTOR, {"opened_from_center": false})


func hide_box_screen() -> void:
	if not _ensure_gameplay_runtime_created():
		return
	_setup_screen_router()
	screen_router.reset(ScreenRouterRef.SCREEN_GAMEPLAY, {"start_mission": false, "preserve_profile": true})
'''

game = sub_once(
    game,
    r"func show_box_screen\(\) -> void:\n.*?(?=\nfunc update_box_status)",
    box_nav + "\n",
    "box navigation wrappers",
)

# Back behavior and top-level buttons.
game = sub_once(
    game,
    r"func _on_box_back_pressed\(\) -> void:\n.*?(?=\nfunc update_box_button_visibility)",
    '''func _on_box_back_pressed() -> void:
	if bipob != null:
		_save_active_bipob_profile()
	_navigate_back_or_center()

''',
    "box back",
)
game = sub_once(
    game,
    r"func _on_programmer_back_pressed\(\) -> void:\n.*?(?=\nfunc _has_programmer_module)",
    '''func _on_programmer_back_pressed() -> void:
	_navigate_back_or_center()

''',
    "programmer back",
)
game = sub_once(
    game,
    r"func _on_repair_back_pressed\(\) -> void:\n.*?(?=\nfunc _on_placeholder_back_pressed)",
    '''func _on_repair_back_pressed() -> void:
	_navigate_back_or_center()

''',
    "repair back",
)
game = sub_once(
    game,
    r"func _on_placeholder_back_pressed\(\) -> void:\n.*?\tplaceholder_return_screen_mode = AppScreenMode.CENTER\n",
    '''func _on_placeholder_back_pressed() -> void:
	if screen_router != null and screen_router.back():
		placeholder_return_screen_mode = AppScreenMode.CENTER
		return
	match placeholder_return_screen_mode:
		AppScreenMode.GAMEPLAY:
			_enter_gameplay_screen_without_starting_mission()
		AppScreenMode.MAIN_MENU:
			show_main_menu_screen()
		_:
			show_center_screen()
	placeholder_return_screen_mode = AppScreenMode.CENTER
''',
    "placeholder back",
)

# Top-level back buttons use router history.
game = game.replace('Callable(self, "show_center_screen")', 'Callable(self, "_navigate_back_or_center")')

# Ready creates only the router; screen roots are lazy factories.
game = replace_once(game, '\t_create_app_menu_roots()\n', '\t_setup_screen_router()\n', "ready router setup")

# Energy refresh must refresh the active gameplay route, not hide all screens manually.
game = replace_once(
    game,
    '''func _setup_mission_field_hud() -> void:
	# Keep mission gameplay HUD in sync after screen hierarchy/runtime refreshes.
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	_hide_all_app_screens()
	_initialize_runtime_hud()
	_set_gameplay_visible(true)
	call_deferred("_attach_runtime_gameplay_view")
''',
    '''func _setup_mission_field_hud() -> void:
	if app_screen_mode != AppScreenMode.GAMEPLAY:
		return
	_setup_screen_router()
	screen_router.refresh_active({"refresh_only": true, "preserve_profile": true})
''',
    "gameplay refresh route",
)

# Box restart detection should use the canonical screen mode, not the hidden legacy node.
game = replace_once(
    game,
    '\tif box_screen != null and box_screen.visible:\n\t\thide_box_screen()\n',
    '\tif app_screen_mode == AppScreenMode.BOX_CONSTRUCTOR:\n\t\thide_box_screen()\n',
    "box restart route",
)

# Top-level transitions no longer own a global hide-all helper.
game = sub_once(
    game,
    r"\nfunc _hide_all_app_screens\(\) -> void:\n.*?(?=\nfunc _hide_runtime_mission_ui)",
    "\n",
    "remove hide-all screen loop",
)
game = game.replace('\t_hide_all_app_screens()\n', '')
if "_hide_all_app_screens" in game:
    raise RuntimeError("legacy hide-all screen path remains")

write(GAME_PATH, game)

# Static architecture audit.
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


def function_at(source: str, position: int) -> str:
    matches = list(re.finditer(r"^func ([A-Za-z0-9_]+)\(", source[:position], re.M))
    return matches[-1].group(1) if matches else ""


router = text("scripts/ui/navigation/screen_router.gd")
for token in ["register_screen", "func reset", "func replace", "func push", "func back", "resolve_focus_target", "_cleanup_instance"]:
    expect(token in router, f"ScreenRouter contract missing: {token}")
expect("get_tree().current_scene" not in router, "ScreenRouter must not scan current_scene")
expect("service locator" not in router.lower(), "ScreenRouter contains unrelated service-locator behavior")

game = text("scripts/ui/game_ui.gd")
expect('preload("res://scripts/ui/navigation/screen_router.gd")' in game, "GameUI does not preload ScreenRouter")
expect("func _setup_screen_router" in game, "GameUI does not register screen factories")
expect("func _create_app_menu_roots" not in game, "eager app-menu root creation remains")
expect("_hide_all_app_screens" not in game, "legacy hide-all screen loop remains")
expect("screen_router.back()" in game, "router back-stack is not used")

for screen_id in [
    "SCREEN_MAIN_MENU", "SCREEN_CENTER", "SCREEN_TASKS", "SCREEN_GAMEPLAY",
    "SCREEN_BOX_CONSTRUCTOR", "SCREEN_MISSION_CONSTRUCTOR", "SCREEN_MISSION_RESULT",
    "SCREEN_PLACEHOLDER", "SCREEN_CHARGING", "SCREEN_REPAIR", "SCREEN_PROGRAMMER",
]:
    expect(screen_id in game, f"screen is not registered/routed: {screen_id}")

for match in re.finditer(r"_build_fullscreen_root\(", game):
    function_name = function_at(game, match.start())
    expect(function_name.startswith("_screen_factory_") or function_name == "_build_fullscreen_root", f"direct top-level root creation outside factory: {function_name}")

for match in re.finditer(r"^\s*app_screen_mode\s*=", game, re.M):
    function_name = function_at(game, match.start())
    expect(function_name.startswith("_screen_enter_"), f"app_screen_mode changed outside screen enter hook: {function_name}")

for public_name in [
    "show_main_menu_screen", "show_center_screen", "show_tasks_screen", "show_placeholder_screen",
    "start_gameplay_from_center", "show_box_constructor_from_center", "show_mission_constructor_screen",
    "show_mission_result_screen", "show_charging_menu", "show_repair_menu", "show_programmer_menu",
    "show_box_screen", "hide_box_screen",
]:
    block_match = re.search(rf"func {public_name}\([^\n]*\)(?: -> [^:\n]+)?:\n([\s\S]*?)(?=\nfunc |\Z)", game)
    expect(block_match is not None, f"missing public navigation wrapper: {public_name}")
    if block_match:
        block = block_match.group(0)
        for forbidden in ["_build_fullscreen_root", "add_child(", "queue_free()", ".visible = true", ".visible = false"]:
            expect(forbidden not in block, f"navigation wrapper {public_name} still mutates screen tree via {forbidden}")

expect(not (ROOT / "tools/apply_1111_screen_router.py").exists(), "one-shot ScreenRouter patch helper remains")
expect(not (ROOT / ".github/workflows/apply-1111-screen-router.yml").exists(), "one-shot ScreenRouter workflow remains")

workflow = text(".github/workflows/godot-parser-gate.yml")
expect("python tools/check_screen_router.py" in workflow, "ScreenRouter static audit is not wired")
expect("check_screen_router.gd" in workflow, "ScreenRouter behavior gate is not wired")

if errors:
    print("ScreenRouter audit FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("ScreenRouter audit OK")
'''
write(ROOT / "tools/check_screen_router.py", static_audit)

# Executable router behavior contract.
behavior = r'''extends SceneTree

const ScreenRouterRef = preload("res://scripts/ui/navigation/screen_router.gd")

class RouterHost:
	extends Control
	var router: ScreenRouter

	func _screen_router_restore_focus(screen_id: StringName, screen: Control, preferred_focus: Variant = null) -> void:
		if router == null or router.get_active_screen_id() != screen_id:
			return
		var target: Control = router.resolve_focus_target(screen_id, screen, preferred_focus)
		if target != null:
			target.grab_focus()


var host: RouterHost
var router: ScreenRouter
var factory_counts: Dictionary = {}
var enter_counts: Dictionary = {}
var cleanup_counts: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _make_screen(screen_id: StringName) -> Control:
	factory_counts[screen_id] = int(factory_counts.get(screen_id, 0)) + 1
	var root := Control.new()
	root.name = String(screen_id)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var button := Button.new()
	button.name = "FocusButton"
	button.text = String(screen_id)
	button.focus_mode = Control.FOCUS_ALL
	root.add_child(button)
	return root


func _on_enter(screen_id: StringName, _screen: Control, _payload: Dictionary, _repeated: bool) -> void:
	enter_counts[screen_id] = int(enter_counts.get(screen_id, 0)) + 1


func _on_cleanup(screen_id: StringName, _screen: Control) -> void:
	cleanup_counts[screen_id] = int(cleanup_counts.get(screen_id, 0)) + 1


func _register(screen_id: StringName, cache: bool = true) -> void:
	router.register_screen(
		screen_id,
		Callable(self, "_make_screen").bind(screen_id),
		Callable(self, "_on_enter").bind(screen_id),
		Callable(),
		Callable(self, "_on_cleanup").bind(screen_id),
		cache
	)


func _run() -> void:
	host = RouterHost.new()
	root.add_child(host)
	router = ScreenRouterRef.new(host)
	host.router = router
	_register(&"a", true)
	_register(&"b", false)
	_register(&"c", true)

	var ok := _expect(router.reset(&"a", {"value": 1}), "reset(A) must succeed")
	await process_frame
	var a_root: Control = router.get_screen(&"a")
	ok = _expect(router.get_active_screen_id() == &"a" and a_root != null and a_root.visible, "A must be active and visible") and ok
	ok = _expect(int(factory_counts.get(&"a", 0)) == 1, "A factory must run once") and ok

	var a_button: Button = a_root.get_node("FocusButton") as Button
	a_button.grab_focus()
	await process_frame
	ok = _expect(router.replace(&"a", {"value": 2}), "repeated open(A) must succeed") and ok
	await process_frame
	ok = _expect(router.get_screen(&"a") == a_root, "repeated open must reuse cached instance") and ok
	ok = _expect(int(factory_counts.get(&"a", 0)) == 1 and int(enter_counts.get(&"a", 0)) == 2, "repeated open must not duplicate root") and ok

	ok = _expect(router.push(&"b"), "push(B) must succeed") and ok
	await process_frame
	var b_root: Control = router.get_screen(&"b")
	ok = _expect(router.get_back_stack_size() == 1, "push must create one back-stack entry") and ok
	ok = _expect(not a_root.visible and b_root != null and b_root.visible, "push must hide A and show B") and ok

	ok = _expect(router.back(), "back() must return to A") and ok
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"a" and a_root.visible, "back must restore A") and ok
	ok = _expect(router.get_screen(&"b") == null, "transient B must be removed from router instances") and ok
	ok = _expect(int(cleanup_counts.get(&"b", 0)) == 1, "transient B cleanup must run once") and ok
	ok = _expect(host.get_viewport().gui_get_focus_owner() == a_button, "back must restore previous focus") and ok

	ok = _expect(router.replace(&"c"), "replace(C) must succeed") and ok
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"c" and router.get_back_stack_size() == 0, "replace must not add history") and ok
	var previous_active := router.get_active_screen_id()
	ok = _expect(not router.replace(&"missing"), "invalid screen ID must fail") and ok
	ok = _expect(router.get_active_screen_id() == previous_active and router.get_last_error() == "invalid_screen_id", "invalid transition must preserve active screen") and ok

	router.cleanup_all()
	await process_frame
	ok = _expect(router.get_active_screen_id() == &"" and router.get_screen(&"a") == null and router.get_screen(&"c") == null, "cleanup_all must clear instances and active ID") and ok

	if ok:
		print("check_screen_router: OK")
		quit(0)
	else:
		push_error("check_screen_router: FAILED")
		quit(1)
'''
write(ROOT / "tools/ci/check_screen_router.gd", behavior)

# Wire both gates next to the other architecture checks.
workflow_path = ROOT / ".github/workflows/godot-parser-gate.yml"
workflow = read(workflow_path)
workflow = workflow.replace(
    "          python tools/check_event_driven_runtime_hud.py\n",
    "          python tools/check_event_driven_runtime_hud.py\n          python tools/check_screen_router.py\n",
    1,
)
workflow = workflow.replace(
    "          godot --headless --path . --script res://tools/ci/check_event_driven_runtime_hud.gd\n",
    "          godot --headless --path . --script res://tools/ci/check_event_driven_runtime_hud.gd\n          godot --headless --path . --script res://tools/ci/check_screen_router.gd\n",
    1,
)
write(workflow_path, workflow)

print("apply_1111_screen_router: migration applied")
