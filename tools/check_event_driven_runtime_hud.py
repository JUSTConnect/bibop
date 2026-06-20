#!/usr/bin/env python3
from pathlib import Path
import re
import sys

# Static architecture audit. Runtime behavior is exercised separately by
# tools/ci/check_event_driven_runtime_hud.gd in the Godot parser/load gate.
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
expect(not (ROOT / "tools/apply_1127_fixes.py").exists(), "one-shot PR patch helper remains in repository")
expect(not (ROOT / ".github/workflows/apply-pr-1127-fixes.yml").exists(), "one-shot PR patch workflow remains in repository")

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
