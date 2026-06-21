#!/usr/bin/env python3
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


def function_block(source: str, name: str) -> str:
    start = re.search(rf"^func {re.escape(name)}\(", source, re.M)
    if start is None:
        return ""
    end = source.find("\nfunc ", start.end())
    return source[start.start(): end if end != -1 else len(source)]


router = text("scripts/ui/navigation/screen_router.gd")
for token in ["register_screen", "func reset", "func replace", "func push", "func back", "set_active_payload", "resolve_focus_target", "_cleanup_instance"]:
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

for match in re.finditer(r"(?<!func )_build_fullscreen_root\(", game):
    function_name = function_at(game, match.start())
    expect(function_name.startswith("_screen_factory_"), f"direct top-level root creation outside factory: {function_name}")

for match in re.finditer(r"^\s*app_screen_mode\s*=", game, re.M):
    function_name = function_at(game, match.start())
    expect(function_name.startswith("_screen_enter_"), f"app_screen_mode changed outside screen enter hook: {function_name}")

for public_name in [
    "show_main_menu_screen", "show_center_screen", "show_tasks_screen", "show_placeholder_screen",
    "start_gameplay_from_center", "show_box_constructor_from_center", "show_mission_constructor_screen",
    "show_mission_result_screen", "show_charging_menu", "show_repair_menu", "show_programmer_menu",
    "show_box_screen", "hide_box_screen",
]:
    block = function_block(game, public_name)
    expect(bool(block), f"missing public navigation wrapper: {public_name}")
    if block:
        for forbidden in ["_build_fullscreen_root", "add_child(", "queue_free()", ".visible = true", ".visible = false"]:
            expect(forbidden not in block, f"navigation wrapper {public_name} still mutates screen tree via {forbidden}")

expect(not (ROOT / "tools/apply_1111_screen_router.py").exists(), "one-shot ScreenRouter patch helper remains")
expect(not (ROOT / ".github/workflows/apply-1111-screen-router.yml").exists(), "one-shot ScreenRouter workflow remains")

workflow = text(".github/workflows/godot-parser-gate.yml")
expect("tools/check_screen_router.py" in workflow, "ScreenRouter static audit is not wired")
expect("check_screen_router.gd" in workflow, "ScreenRouter behavior gate is not wired")

if errors:
    print("ScreenRouter audit FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("ScreenRouter audit OK")
